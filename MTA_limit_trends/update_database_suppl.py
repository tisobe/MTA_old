#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################    
#                                                                                       #
#   update_database_suppl.py: update/create fits data files fir a given msid_list       #
#                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                   #
#                                                                                       #
#           last update: Mar 18, 2018                                                   #
#                                                                                       #
#########################################################################################

import os
import sys
import re
import string
import time
import numpy
import astropy.io.fits  as pyfits
import Ska.engarchive.fetch as fetch
import Chandra.Time
#
#--- reading directory list
#
path = '/data/mta/Script/MTA_limit_trends/Scripts/house_keeping/dir_list'
f= open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)
#
#--- append path to a private folder
#
sys.path.append(bin_dir)
sys.path.append(mta_dir)
#
#--- import several functions
#
import convertTimeFormat        as tcnv #---- contains MTA time conversion routines
import mta_common_functions     as mcf  #---- contains other functions commonly used in MTA scripts
import glimmon_sql_read         as gsr
import envelope_common_function as ecf
import fits_operation           as mfo
#
#--- set a temporary file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)

sp_limt_case_c = ['1oahat','3faralat','3rctubpt','3tsmxcet', '3tsmxspt', '3tsmydpt', '3tspyfet',\
                  '3tspzdet', '3tspzspt','3ttacs1t', '3ttacs2t', '3ttacs3t', '3ttbrgbt', '3tthrc1t',\
                  '3tthrc2t', '3tthrc3t', '3ttralat', '3ttralct','3ttvalvt', '3btu_bpt']


#------------------------------------------------------------------------------------
#-- run_update_with_ska: extract data from ska database and update the data for the msids in the msid_list 
#------------------------------------------------------------------------------------

def run_update_with_ska(msid, group, msid_sub_list=[], glim=''):
    """
    extract data from ska database and update the data for the msids in the msid_list
    input:  msid            --- a list of msids
            group           --- the group of the msids
            msid_sub_list   --- a list of lists of:
                                [msid, msid_1, msid_2, operand]
                                this is used to compute the first msid from following two
                                msid values with operand (+/-/*)
            glim            --- glim usually found in this function, but you can give it; default: ''
    output: <msid>_data.fits, <msid>_short_data,fits, <msid>_week_data.fits
    """
#
#--- get basic information dict/list
#
    [udict, ddict, mta_db, mta_cross] = ecf.get_basic_info_dict()
#
#--- set starting and stopping data period
#
    test_fits = data_dir + group.capitalize() + '/' + msid + '_data.fits'

    if os.path.isfile(test_fits):
        tstart    = ecf.find_the_last_entry_time(test_fits)
    
        ttemp = time.strftime("%Y:%j:00:00:00", time.gmtime())
        tstop = Chandra.Time.DateTime(ttemp).secs - 86400.0
    
        if tstop < tstart:
            exit(1)
    
        if len(msid_sub_list) != 0:
            [dtime, tdata] = compute_sub_msid(msid, msid_sub_list, tstart, tstop)
        else:
            out     = fetch.MSID(msid, tstart, tstop)
            dtime   = out.times
            tdata   = out.vals
#
#--- get limit data table for the msid
#
        if glim == '':
            try:
                tchk  = ecf.convert_unit_indicator(udict[msid])
            except:
                tchk  = 0
    
            if msid in sp_limt_case_c:
                tchk = 1
    
            glim  = ecf.get_limit(msid, tchk, mta_db, mta_cross)
#
#--- update database
#
        update_database(msid, group, dtime, tdata, glim)

#------------------------------------------------------------------------------------
#-- compute_sub_msid: return computed msid's data                                  --
#------------------------------------------------------------------------------------

def compute_sub_msid(msid, msid_sub_list, tstart, tstop):
    """
    return computed msid's data
    input:  msid    --- msid
            msid_sub_list   ---a list of lists of:
                            [msid, msid_1, msid_2, operand]
                            this is used to compute the first msid from following two
                            msid values with operand (+/-/*)
            tstart  --- start time in seconds from 1998.1.1
            tstop   --- stop tim in seconds from 1998.1.1
    output: ttime   --- array of time values
            tdata   --- array of the data values
    """

    chk = 0
    for m in range(0, len(msid_sub_list)):
        if msid == msid_sub_list[m][0]:
            msid_t = msid_sub_list[m][1]
            msid_s = msid_sub_list[m][2]
            opr    = msid_sub_list[m][3]
            chk = 1
            break

    if chk > 0:
        out     = fetch.MSID(msid_t, tstart, tstop)
        tdata_t = out.vals
        ttime   = out.times
        out     = fetch.MSID(msid_s, tstart, tstop)
        tdata_s = out.vals
        if opr == '-':
            tdata   = tdata_t - tdata_s
        elif opr == '*':
            tdata   = tdata_t * tdata_s
        else:
            tdata   = tdata_t + tdata_s
    else:
        try:
            out     = fetch.MSID(msid, tstart, tstop)
            tdata   = out.vals
            ttime   = out.times
        except:
            tdata   = []
            ttime   = []

    return [ttime, tdata]


#------------------------------------------------------------------------------------
#-- run_update_with_archive: extract data using arc5gl and update the data for the msids in the msid_list 
#------------------------------------------------------------------------------------

def run_update_with_archive(msid_list, group,  date_list, detector, level, filetype, tstart, tstop, sub=''):
    """
    extract data using arc5gl and update the data for the msids in the msid_list
    input:  msid_list   --- the name of the list of msids
            group       --- a group name
            date_list   --- a list of date to be processed in the form of <yyyy>:<ddd>
            detector    --- detector name
            level       --- level
            filetype    --- file name
            tstart      --- starting time
            tstop       --- stopping time
            sub         --- subdetector name; defalut "" --- no sub detector
    output: <msid>_data.fits, <msid>_short_data,fits, <msid>_week_data.fits
    """
#
#--- get basic information dict/list
#
    [udict, ddict, mta_db, mta_cross] = ecf.get_basic_info_dict()
#
#--- extract data using arc5gl
#
    [cols, tbdata] = extract_data_arc5gl(detector, level, filetype, tstart, tstop, sub='')
#
#--- get time data in the list form
#
    dtime = list(tbdata.field('time'))

    for col in msid_list:
#
#---- extract data in a list form
#
        data = list(tbdata.field(col))
#
#--- change col name to msid
#
        msid = col.lower()
#
#--- get limit data table for the msid
#
        try:
            tchk  = ecf.convert_unit_indicator(udict[msid])
        except:
            tchk  = 0

        glim  = ecf.get_limit(msid, tchk, mta_db, mta_cross)
#
#--- update database
#
        update_database(msid, group, dtime, data, glim)

#------------------------------------------------------------------------------------
#-- extract_data_arc5gl: extract data using arc5gl                                ---
#------------------------------------------------------------------------------------

def extract_data_arc5gl(detector, level, filetype, tstart, tstop, sub=''):
    """
    extract data using arc5gl
    input:  detector    --- detector name
            level       --- level
            filetype    --- file name
            tstart      --- starting time
            tstop       --- stopping time
            sub         --- subdetector name; defalut "" --- no sub detector
    output: cols        --- a list of col name
            tdata       --- a list of arrays of data
    """

#
#--- extract ephin hk lev 0 fits data
#
    line = 'operation=retrieve\n'
    line = line + 'dataset = flight\n'
    line = line + 'detector = ' + detector + '\n'

    if sub != '':
        line = line + 'subdetector = ' + sub + '\n'

    line = line + 'level = '    + level + '\n'
    line = line + 'filetype = ' + filetype + '\n'
    line = line + 'tstart = '   + str(tstart) + '\n'
    line = line + 'tstop = '    + str(tstop)  + '\n'
    line = line + 'go\n'

    fo = open(zspace, 'w')
    fo.write(line)
    fo.close()

    try:
        cmd = ' /proj/sot/ska/bin/arc5gl  -user isobe -script ' + zspace + '> ztemp_out'
        os.system(cmd)
    except:
        cmd = ' /proj/axaf/simul/bin/arc5gl -user isobe -script ' + zspace + '> ztemp_out'
        os.system(cmd)

    mcf.rm_file(zspace)
#
#--- find the names of the fits files of the day of the group
#
    try:
        flist = ecf.read_file_data('ztemp_out', remove=1)
        flist = flist[1:]
    except:
        print "\t\tNo data"
        #continue
        return [[], []]

    if len(flist) < 1:
        print "\t\tNo data"
        #continue
        return [[], []]
#
#--- combined them
#
    flen = len(flist)

    if flen == 0:
        #continue
        return [[], []]

    elif flen == 1:
        cmd = 'cp ' + flist[0] + ' ./ztemp.fits'
        os.system(cmd)

    else:
        mfo.appendFitsTable(flist[0], flist[1], 'ztemp.fits')
        if flen > 2:
            for k in range(2, flen):
                mfo.appendFitsTable('ztemp.fits', flist[k], 'out.fits')
                cmd = 'mv out.fits ztemp.fits'
                os.system(cmd)
#
#--- remove indivisual fits files
#

    for ent in flist:
        cmd = 'rm -rf ' + ent 
        os.system(cmd)
#
#--- return data
#
    [cols, tbdata] = ecf.read_fits_file('ztemp.fits')
    
    cmd = 'rm -f ztemp.fits out.fits'
    os.system(cmd)

    return [cols, tbdata]


#-------------------------------------------------------------------------------------------
#-- update_database: update/create fits data files of msid                                --
#-------------------------------------------------------------------------------------------

def update_database(msid, group, dtime, data,  glim, pstart=0, pstop=0, step=3600.0):
    """
    update/create fits data files of msid
    input:  msid    --- msid
            group   --- group name
            dtime   --- array of time
            data    --- array of data
            glim    --- g limit data
            pstart  --- starting time in seconds from 1998.1.1; defulat = 0 (find from the data)
            pstop   --- stopping time in seconds from 1998.1.1; defulat = 0 (find from the data)
            step    --- time interval of the short time data set:default 3600.0
    output: <msid>_data.fits, <msid>_short_data.fits
    """

    cols  = ['time', msid, 'med', 'std', 'min', 'max', 'ylower', 'yupper', 'rlower', 'rupper', 'dcount',\
             'ylimlower', 'ylimupper', 'rlimlower', 'rlimupper']

    out_dir = data_dir + group + '/'
#
#--- make sure that the sub directory exists
#
    if not os.path.isdir(out_dir):
        cmd = 'mkdir ' + out_dir
        os.system(cmd)

    fits  = out_dir + msid + '_data.fits'
    fits2 = out_dir + msid + '_short_data.fits'
    fits3 = out_dir + msid + '_week_data.fits'
#
#-- if the starting time and stopping time are given, use them. 
#-- otherwise find from the data for the starting time and today's date -1 for the stopping time
#
    if pstart == 0:
        stday = time.strftime("%Y:%j:00:00:00", time.gmtime())
        stday = Chandra.Time.DateTime(stday).secs - 86400.0     #--- set the ending to the day before
    else:
        stday = pstop 

    mago  = stday - 31536000.0                              #--- a year ago
    mago2 = stday - 604800.0                                #--- a week ago
#
#--- if the fits files already exist, append the data  --------------------
#
    wline = ""

    if os.path.isfile(fits):
#
#--- extract data from archive one day at a time
#
        [week_p, short_p, long_p] = process_day_data(msid, dtime, data, glim)
#    
#--- add to the data to the long term fits file
#
        ecf.update_fits_file(fits,  cols, long_p)
#
#--- remove the older data from the short term fits file, then append the new data
#
        try:
            remove_old_data(fits2, cols, mago)
            ecf.update_fits_file(fits2, cols, short_p)
        except:
            try:
                ecf.create_fits_file(fits2, cols, short_p)
            except:
                wline = wline + "Fail: short term: " + fits2 + '\n'

#--- remove the older data from the week long data fits file, then append the new data
#
        try:
            remove_old_data(fits3, cols, mago2)
            ecf.update_fits_file(fits3, cols, week_p)
        except:
            try:
                ecf.create_fits_file(fits3, cols, week_p)
            except:
                wline = wline + "Fail: week term: " + fits3 + '\n'
#
#--- if the fits files do not exist, create new ones ----------------------
#
    else:
        if pstart == 0:
            start = 48988799                    #--- 1999:203:00:00:00
            stop  = stday
        else:
            start = pstart
            stop  = pstop
#
#--- one day step; a long term data
#
        [week_p, short_p, long_p] = process_day_data(msid, dtime, data, glim)
        try:
            ecf.create_fits_file(fits, cols, long_p)
        except:
            wline = wline + "Fail: long term: " + fits + '\n'
#
#--- short term data
#
        mago    = stop - 31536000.0                              #--- a year ago
        short_d =  cut_the_data(short_p, mago)
        try:
            ecf.create_fits_file(fits2, cols, short_d)
        except:
            wline = wline + "Fail: short term: " + fits2 + '\n'
#
#
#--- week long data
#
        mago   = stop - 604800.0
        week_d =  cut_the_data(week_p, mago)

        try:
            ecf.create_fits_file(fits3, cols, week_d)
        except:
            wline = wline + "Fail: week term: " + fits3 + '\n'

    return wline

#-------------------------------------------------------------------------------------------
#-- process_day_data: extract data from the archive and compute the stats           ---
#-------------------------------------------------------------------------------------------

def process_day_data(msid, time, data, glim, step = 3600.0):
    """
    extract data from the archive and compute the stats
    input:  msid    --- msid of the data
            time    --- array of time
            data    --- array of data
            glim    --- a list of limit tables
            step    --- interval of the data. defalut: 3600 sec
    output: a list of two lists which contain:
            week_p:
                wtime   --- a list of time in sec from 1998.1.1
                wdata   --- a list of the  mean of each interval
                wmed    --- a list of the median of each interval
                wstd    --- a list of the std of each interval
                wmin    --- a list of the min of each interval
                wmax    --- a list of the max of each interval
                wyl     --- a list of the rate of yellow lower violation
                wyu     --- a list of the rate of yellow upper violation
                wrl     --- a list of the rate of red lower violation
                wru     --- a list of the rate of red upper violation
                wcnt    --- a list of the total data counts
                wyl     --- a list of the lower yellow limits
                wyu     --- a list of the upper yellow limits
                wrl     --- a list of the lower red limits
                wru     --- a list of the upper red limits
            short_p:
                btime   --- a list of time in sec from 1998.1.1
                bdata   --- a list of the  mean of each interval
                bmed    --- a list of the median of each interval
                bstd    --- a list of the std of each interval
                bmin    --- a list of the min of each interval
                bmax    --- a list of the max of each interval
                byl     --- a list of the rate of yellow lower violation
                byu     --- a list of the rate of yellow upper violation
                brl     --- a list of the rate of red lower violation
                bru     --- a list of the rate of red upper violation
                bcnt    --- a list of the total data counts
                byl     --- a list of the lower yellow limits
                byu     --- a list of the upper yellow limits
                brl     --- a list of the lower red limits
                bru     --- a list of the upper red limits
            long_p:
                    --- all in one element list form
                ftime   --- a mid time of the entier extracted data period
                fdata   --- the mean of the entire extracted data 
                fstd    --- the std of the entire extracted data
                fmin    --- the min of the entire extracte data
                fmax    --- the max of the entire extracte data
                ylow    --- the reate of yellow lower violation
                yupper  --- the reate of yellow upper violation
                rlow    --- the reate of red lower violation
                rupper  --- the reate of red upper violation
                tcnt    --- the total counts of the data
                ylow    --- the lower yellow limit
                yup     --- the upper yellow limit
                rlow    --- the lower red limit
                rup     --- the upper red limit
    """
#
#--- week long data 5 min step
#
    wtime = []
    wdata = []
    wmed  = []
    wstd  = []
    wmin  = []
    wmax  = []
    wyl   = []
    wyu   = []
    wrl   = []
    wru   = []
    wcnt  = []
    step2 = 300
    wstart= time[0] - 10.0      #---- set the starting time to 10 sec before the first entry

#
#--- one year long data 1 hr step
#
    btime = []
    bdata = []
    bmed  = []
    bstd  = []
    bmin  = []
    bmax  = []
    byl   = []
    byu   = []
    brl   = []
    bru   = []
    bcnt  = []

    wsave = []
    vsave = []
#
#--- extract data from archive
#
    try:
        data  = numpy.array(data)
        dtime = numpy.array(time)
        mask  = ~(numpy.isnan(data))
        data  = data[mask]
        dtime = dtime[mask]
#
#--- there are glitch values much larger than the real value; remove them
#
        mask  = [data < 9e6]
        data  = data[mask]
        dtime = dtime[mask]
#
#--- get stat for the entire period
#
        ftime   = dtime.mean()
        fdata   = data.mean()
        fmed    = numpy.median(data)
        fstd    = data.std()
        fmin    = data.min()
        fmax    = data.max()
#
#--- find the violation limits of that time
#
        vlimits = find_violation_range(glim, ftime)
#
#--- get the violation rate of the entier period
#
        [ylow, yupper, rlow, rupper, tcnt] = find_violation_rate(data, vlimits)

        long_p  = [[ftime], [fdata], [fmed], [fstd], [fmin], [fmax]]
        long_p  = long_p + [[ylow], [yupper], [rlow], [rupper], [tcnt]]
        long_p  = long_p + [[vlimits[0]], [vlimits[1]], [vlimits[2]], [vlimits[3]]]
#
#--- if asked, devide the data into a smaller period (step size)
#
        if step != 0:
            spos  = 0
            spos2 = 0
            chk   = 1
            chk2  = 2
            send  = dtime[spos]  + step
            send2 = dtime[spos2] + step2

            for k in range(0, len(dtime)):

                if dtime[k] > wstart:
                    if dtime[k] < send2:
                        chk2 = 0
                    else:
                        sdata = data[spos2:k]
                        avg   = sdata.mean()
                        med   = numpy.median(sdata)
                        sig   = sdata.std()
                        amin  = sdata.min()
                        amax  = sdata.max()
                        stime = dtime[spos2 + int(0.5 * (k-spos2))]
                        vlimits = find_violation_range(glim, stime)
                        [yl, yu, rl, ru, tot] = find_violation_rate(sdata, vlimits)
     
                        wtime.append(stime)
                        wdata.append(avg)
                        wmed.append(med)
                        wstd.append(sig)
                        wmin.append(amin)
                        wmax.append(amax)
                        wyl.append(yl)
                        wyu.append(yu)
                        wrl.append(rl)
                        wru.append(ru)
                        wcnt.append(tot)
                        wsave.append(vlimits)
     
                        spos2 = k
                        send2 = dtime[k] + step2
                        chk2  = 1
                else:
                    send2 = dtime[spos2] + step2



                if dtime[k] < send:
                    chk = 0
                else:
                    rdata = data[spos:k]
                    avg   = rdata.mean()
                    med   = numpy.median(rdata)
                    sig   = rdata.std()
                    amin  = rdata.min()
                    amax  = rdata.max()
                    stime = dtime[spos + int(0.5 * (k-spos))]
                    vlimits = find_violation_range(glim, stime)
                    [yl, yu, rl, ru, tot] = find_violation_rate(rdata, vlimits)
    
                        
                    btime.append(stime)
                    bdata.append(avg)
                    bmed.append(med)
                    bstd.append(sig)
                    bmin.append(amin)
                    bmax.append(amax)
                    byl.append(yl)
                    byu.append(yu)
                    brl.append(rl)
                    bru.append(ru)
                    bcnt.append(tot)
                    vsave.append(vlimits)
    
                    spos = k
                    send = dtime[k] + step
                    chk  = 1
#
#--- check whether there are any left over; if so add it to the data lists
#
            if chk2 == 0:
                rdata = data[spos2:k]
                avg   = rdata.mean()
                med   = numpy.median(rdata)
                sig   = rdata.std()
                amin  = rdata.min()
                amax  = rdata.max()
                stime = dtime[spos2 + int(0.5 * (k-spos2))]
                vlimits = find_violation_range(glim, stime)
                [yl, yu, rl, ru, tot] = find_violation_rate(rdata, vlimits)
    
                wtime.append(dtime[spos2 + int(0.5 * (k-spos2))])
                wdata.append(avg)
                wmed.append(med)
                wstd.append(sig)
                wmin.append(amin)
                wmax.append(amax)
                wyl.append(yl)
                wyu.append(yu)
                wrl.append(rl)
                wru.append(ru)
                wcnt.append(tot)
                wsave.append(vlimits)

            if chk == 0:
                rdata = data[spos:k]
                avg   = rdata.mean()
                med   = numpy.median(rdata)
                sig   = rdata.std()
                amin  = rdata.min()
                amax  = rdata.max()
                stime = dtime[spos + int(0.5 * (k-spos))]
                vlimits = find_violation_range(glim, stime)
                [yl, yu, rl, ru, tot] = find_violation_rate(rdata, vlimits)
    
                btime.append(dtime[spos + int(0.5 * (k-spos))])
                bdata.append(avg)
                bmed.append(med)
                bstd.append(sig)
                bmin.append(amin)
                bmax.append(amax)
                byl.append(yl)
                byu.append(yu)
                brl.append(rl)
                bru.append(ru)
                bcnt.append(tot)
                vsave.append(vlimits)
    except:
        ftime = 0
        fdata = 0
        fmed  = 0
        fstd  = 0
        fmin  = 0
        fmax  = 0
        ylow  = 0
        yupper= 0
        rlow  = 0
        rupper= 0
        tcnt  = 0

        vlimits = [-9.0e9, -9.0e9, 9.0e9, 9.0e9]
        long_p  = [ftime, fdata, fmed, fstd, fmin, fmax, ylow, yupper, rlow, rupper, tcnt]

    week_p  = [wtime, wdata, wmed, wstd, wmin, wmax, wyl, wyu, wrl, wru, wcnt]
    short_p = [btime, bdata, bmed, bstd, bmin, bmax, byl, byu, brl, bru, bcnt]
#
#--- adding limits to the table
#
    vtemp   = [[], [], [], []]
    for k in range(0, len(wsave)):
        for m in range(0, 4):
            vtemp[m].append(wsave[k][m])
    week_p = week_p + vtemp
#
    vtemp   = [[], [], [], []]
    for k in range(0, len(vsave)):
        for m in range(0, 4):
            vtemp[m].append(vsave[k][m])
    short_p = short_p + vtemp

    return [week_p, short_p, long_p]





#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------

def cut_the_data(data, cut):

    pos = 0
    for k in range(0, len(data[0])):
        if data[0][k] < cut:
            continue
        else:
            pos = k
            break

    save = []
    for k in range(0, len(data)):
        save.append(data[k][pos:])

    return save

#-------------------------------------------------------------------------------------------
#-- remove_old_data: remove the data older the cut time                                   --
#-------------------------------------------------------------------------------------------

def remove_old_data(fits, cols, cut):
    """
    remove the data older the cut time
    input:  fits    --- fits file name
            cols    --- a list of column names
            cut     --- cut time in seconds from 1998.1.1
    output: updated fits file
    """

    f     = pyfits.open(fits)
    data  = f[1].data
    f.close()
#
#--- find where the cut time
#
    pos   = 0
    dtime = list(data['time'])
    for k in range(0, len(dtime)):
        if dtime[k] >= cut:
            pos = k
            break
#
#--- remove the data before the cut time
#
    udata = []
    for k in range(0, len(cols)):
        udata.append(list(data[cols[k]][pos:]))

    mcf.rm_file(fits)
    ecf.create_fits_file(fits, cols, udata)


#-------------------------------------------------------------------------------------------
#-- find_violation_range: set violation range                                             --
#-------------------------------------------------------------------------------------------

def find_violation_range(glim, time):
    """
    set violation range
    input:  glim    --- a list of lists of violation set [start, stop, yl, yu, rl, ru]
            time    --- time of the violation check
    output: vlimit  --- a four element list of [yl, yu, rl, ru]
    """

    vlimit = [-9.0e9, -9.0e9, 9.0e9, 9.0e9]

    for lim_set in glim:
        start = float(lim_set[0])
        stop  = float(lim_set[1])
        if (time >= start) and (time < stop):
            vlimit = [lim_set[2], lim_set[3], lim_set[4], lim_set[5]]

    return vlimit

#-------------------------------------------------------------------------------------------
#-- find_violation_rate: find rate of yellow, red violations in both lower and upper limits 
#-------------------------------------------------------------------------------------------

def find_violation_rate(carray, limits):
    """
    find rate of yellow, red violations in both lower and upper limits
    input:  carray  --- numpy array of the data
            limits  --- a list of limit [yellow lower, yellow upper, red lower, red upper]
    output: [yl, yu, rl, ru, tot]:  rate of yellow lower
                                    rate of yellow upper
                                    rate of red lower
                                    rate of red upper
                                    totla number of the data
    """
    tot  = len(carray)
    ftot = float(tot)

    yl  = find_num_of_elements(carray, limits[0], side=0)
    yu  = find_num_of_elements(carray, limits[1], side=1)
    rl  = find_num_of_elements(carray, limits[2], side=0)
    ru  = find_num_of_elements(carray, limits[3], side=1)
    yl -= rl
    yu -= ru

    yl /= ftot
    yu /= ftot
    rl /= ftot
    ru /= ftot

    return [yl, yu, rl, ru, tot]

#-------------------------------------------------------------------------------------------
#-- find_num_of_elements: find the numbers of elements above or lower than limit comparing to the total data #
#-------------------------------------------------------------------------------------------

def find_num_of_elements(carray, lim, side=0):
    """
    find the numbers of elements above or lower than limit comparing to the total data #
    input:  carray  --- numpy array of the data
            lim     --- the limit value
            side    --- lower:0 or upper:1 limit
    output: cnt     --- the numbers of the values beyond the limit
    """
#
#--- assume that the huge limit value means that there is no limit
#
    if abs(lim) > 1e6:
        return 0


    if side == 0:
        out = numpy.where(carray < lim)
    else:
        out = numpy.where(carray > lim)

    try:
        cnt = len(out[0])
    except:
        cnt = 0

    return cnt 

#--------------------------------------------------------------------------------------------------------
#-- get_mta_fits_data: fetch data from mta local database                                              --
#--------------------------------------------------------------------------------------------------------

def get_mta_fits_data(msid, start, stop):
    """
    fetch data from mta local database
    input:  msid    --- msid
            start   --- start time in seconds from 1998.1.1
            stop    --- stop time in seconds from 1998.1.1
    output: time    --- time in second from 1998.1.1 for the given period
            vals    --- vals of msid for the given period
    """
#
#--- find which year(s) the requested period falls
#
    date  = Chandra.Time.DateTime(start)
    byear = int(float(date.year))
    date  = Chandra.Time.DateTime(stop)
    eyear = int(float(date.year))
    
    chk   = 0
    for year in range(byear, eyear+1):
#
#--- find whether the fits data file exists
#
        cmd = 'ls ' + deposit_dir + '*/*/' + msid + '_full_data_' + str(year) + '.fits* > ' + zspace
        os.system(cmd)
     
        out  = ecf.read_file_data(zspace, remove=1)
        fits = out[0]
    
        if not os.path.isfile(fits):
            continue
#
#--- extract the data for the given period
#
        f = pyfits.open(fits)
        data  = f[1].data
        f.close()
        if chk == 0:
            time = data['time']
            vals = data[msid]
            ext  = [(time > start) & (time < stop)]
            time = time[ext]
            vals = vals[ext]
            chk  = 1
        else:
            tmp1 = data['time']
            tmp2 = data[msid]
            ext  = [(tmp1 > start) & (tmp1 < stop)]
            tmp1 = tmp1[ext]
            tmp2 = tmp2[ext]
            time = numpy.append(time, tmp1)
            vals = numpy.append(vals, tmp2)
     
    if chk > 0:
        return [time, vals]
    else:
#
#--- if no data, return False
#
        return False


