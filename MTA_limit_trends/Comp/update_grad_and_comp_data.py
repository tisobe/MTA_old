#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################    
#                                                                                   #
#       update_grad_and_comp_data.py: collect grad and comp data for trending       #
#                                                                                   #
#           author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                   #
#           last update: Mar 23, 2018                                               #
#                                                                                   #
#####################################################################################

import os
import sys
import re
import string
import time
import numpy
import astropy.io.fits  as pyfits
import Ska.engarchive.fetch as fetch
import Chandra.Time
import datetime

#
#--- reading directory list
#
path = '/data/mta/Script/MTA_limit_trends/Scripts/house_keeping/dir_list'
f    = open(path, 'r')
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
import convertTimeFormat        as tcnv       #---- contains MTA time conversion routines
import mta_common_functions     as mcf        #---- contains other functions commonly used in MTA scripts
import glimmon_sql_read         as gsr
import envelope_common_function as ecf
import fits_operation           as mfo
import update_database_from_ska as udfs       #---- database update related scripts
#
#--- set a temporary file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)

testfits = data_dir + 'Gradablk/haftbgrd1_data.fits'

#-------------------------------------------------------------------------------------------
#-- update_grad_and_comp_data: collect grad and  comp data for trending                  ---
#-------------------------------------------------------------------------------------------

def update_grad_and_comp_data(date = ''):
    """
    collect grad and  comp data for trending
    input:  date    ---- the data colletion  end date in yyyymmdd format. if not given, yesterday's date is used
    output: fits file data related to grad and comp
    """
#
#--- read group names which need special treatment
#
    sfile = house_keeping + 'mp_process_list'
    glist = ecf.read_file_data(sfile)
#
#--- create msid <---> unit dictionary
#
    [udict, ddict] = ecf.read_unit_list()
#
#--- read mta database
#
    mta_db = ecf.read_mta_database()
#
#--- read mta msid <---> sql msid conversion list
#
    mta_cross = ecf.read_cross_check_table()
#
#--- find date to read the data
#
    if date == '':
        yesterday = datetime.date.today() - datetime.timedelta(1)
        yesterday = str(yesterday).replace('-', '')
        date_list = find_the_last_entry_time(yesterday)

    else:
        date_list = [date]

    for day in date_list:
#
#--- find the names of the fits files of the day of the group
#
        print "Date: " + str(day)
    
        for group in glist:
            print "Group: " + str(group)
            cmd = 'ls /data/mta_www/mp_reports/' + day + '/' + group + '/data/mta*fits* > ' + zspace
            os.system(cmd)
    
            flist = ecf.read_file_data(zspace, remove=1)
#
#--- combined them
#
            flen = len(flist)
    
            if flen == 0:
                continue
    
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
#--- read out the data for the full day
#
            [cols, tbdata] = ecf.read_fits_file('ztemp.fits')
    
            cmd = 'rm -f ztemp.fits out.fits'
            os.system(cmd)
#
#--- get time data in the list form
#
            dtime = list(tbdata.field('time'))
    
            for k in range(1, len(cols)):
#
#--- select col name without ST_ (which is standard dev)
#
                col = cols[k]
                mc  = re.search('ST_', col)
                if mc is not None:
                    continue
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
    
                glim  = get_limit(msid, tchk, mta_db, mta_cross)
#
#--- update database
#
                update_database(msid, group, dtime, data, glim)


#-------------------------------------------------------------------------------------------
#-- get_limit: find the limit lists for the msid                                          --
#-------------------------------------------------------------------------------------------

def get_limit(msid, tchk, mta_db, mta_cross):
    """
    find the limit lists for the msid
    input:  msid        --- msid
            tchk        --- whether temp conversion needed 0: no/1: degc/2: degf/3: pcs
            mta_db      --- a dictionary of mta msid <---> limist
            mta_corss   --- mta msid and sql msid cross check table
    output: glim        --- a list of lists of lmits. innter lists are:
                            [start, stop, yl, yu, rl, ru]
    """

    mchk = mta_cross[msid]
    if mchk == 'mta':
        try:
            glim = mta_db[msid]
        except:
            glim = [[0,  3218831995, -9e6, 9e6, -9e6, 9e6]]

    else:
        try:
            out   = gsr.read_glimmon(mchk, tchk)
#
#--- testing acis temp in C cases
#
            test  = str(mchk[-2] + mchk[-1])
            if test.lower() == 'tc':
                glim = []
                for ent in out:
                    for k in range(2,6):
                        #ent[k] -= 273.15               #--- 03/23/18 check later
                        pass
                glim.append(ent)
            else:
                glim = out

        except:
            glim = [[0,  3218831995, -9e6, 9e6, -9e6, 9e6]]

    return glim


#-------------------------------------------------------------------------------------------
#-- update_database: update/create fits data files of msid                                --
#-------------------------------------------------------------------------------------------

def update_database(msid, group, dtime, data,  glim, pstart=0, pstop=0, step=3600.0):
    """
    update/create fits data files of msid
    input:  msid    --- msid
            pstart  --- starting time in seconds from 1998.1.1; defulat = 0 (find from the data)
            pstop   --- stopping time in seconds from 1998.1.1; defulat = 0 (find from the data)
            step    --- time interval of the short time data set:default 3600.0
    output: <msid>_data.fits, <msid>_short_data.fits
    """
    out_dir = data_dir + group.capitalize() + '/'
#
#--- make sure that the sub directory exists
#
    if not os.path.isdir(out_dir):
        cmd = 'mkdir ' + out_dir
        os.system(cmd)

    mc = re.search('tc', msid[-2:])
    if mc is not None:
        msidl = msid[:-1]
    else:
        msidl = msid

    cols  = ['time', msidl, 'med', 'std', 'min', 'max', 'ylower', 'yupper', 'rlower', 'rupper', 'dcount',\
             'ylimlower', 'ylimupper', 'rlimlower', 'rlimupper']

    fits  = out_dir + msidl + '_data.fits'
    fits2 = out_dir + msidl + '_short_data.fits'
    fits3 = out_dir + msidl + '_week_data.fits'
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
    if os.path.isfile(fits):
#
#--- extract data from archive one day at a time
#
        [week_p, short_p, long_p] = process_day_data(msid, dtime, data, glim, step=step)
#
#--- add to the data to the long term fits file
#
        ecf.update_fits_file(fits,  cols, long_p)
#
#--- remove the older data from the short term fits file, then append the new data
#
        try:
            udfs.remove_old_data(fits2, cols, mago)
            ecf.update_fits_file(fits2, cols, short_p)
        except:
            pass
#
#--- remove the older data from the week long data fits file, then append the new data
#
        udfs.remove_old_data(fits3, cols, mago2)
        ecf.update_fits_file(fits3, cols, week_p)
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
        [week_p, short_p, long_p] = process_day_data(msid, dtime, data, glim, step=step)
        try:
            ecf.create_fits_file(fits, cols, long_p)
        except:
            pass
#
#--- short term data
#
        mago    = stop - 31536000.0                              #--- a year ago
        short_d =  udfs.cut_the_data(short_p, mago)
        try:
            ecf.create_fits_file(fits2, cols, short_d)
        except:
            pass

#
#--- week long data
#
        mago   = stop - 604800.0
        mago    = 0.0
        week_d =  udfs.cut_the_data(week_p, mago)

        try:
            ecf.create_fits_file(fits3, cols, week_p)
        except:
            pass

#-------------------------------------------------------------------------------------------
#-- process_day_data: extract data from the archive and compute the stats           ---
#-------------------------------------------------------------------------------------------

def process_day_data(msid, time, data, glim, step = 3600.0):
    """
    extract data from the archive and compute the stats
    input:  msid    --- msid of the data
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
        vlimits = udfs.find_violation_range(glim, ftime)
#
#--- get the violation rate of the entier period
#
        [ylow, yupper, rlow, rupper, tcnt] = udfs.find_violation_rate(data, vlimits)

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
                        vlimits = udfs.find_violation_range(glim, stime)
                        [yl, yu, rl, ru, tot] = udfs.find_violation_rate(sdata, vlimits)
     
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
                    vlimits = udfs.find_violation_range(glim, stime)
                    [yl, yu, rl, ru, tot] = udfs.find_violation_rate(rdata, vlimits)
    
                        
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
                vlimits = udfs.find_violation_range(glim, stime)
                [yl, yu, rl, ru, tot] = udfs.find_violation_rate(rdata, vlimits)
    
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
                vlimits = udfs.find_violation_range(glim, stime)
                [yl, yu, rl, ru, tot] = udfs.find_violation_rate(rdata, vlimits)
    
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
#-- find_the_last_entry_time: find the last logged time                                   --
#-------------------------------------------------------------------------------------------

def find_the_last_entry_time(yesterday):
    """
    find the last entry date and then make a list of dates up to yesterday
    input:  yesterday   --- date of yesterday in the format of yyyymmdd
    output: otime       --- a list of date in the format of yyyymmdd
    """
#
#--- find the last entry date from the "testfits" file
#
    f = pyfits.open(testfits)
    data = f[1].data
    f.close()
#
#--- find the last time logged and changed to a python standard time insecods
#
    ltime = numpy.max(data['time'])  + 883630800.0
#
#--- find the time of the start of the day
#
    ct    = time.strftime('%Y%m%d', time.gmtime(ltime))
    year  = int(ct[0:4])
    mon   = int(ct[4:6])
    day   = int(ct[6:8])
    dt    = datetime.datetime(year, mon, day)
    ltime = time.mktime(dt.timetuple())
#
#--- set starting day to the next day
#
    ltime = ltime + 86400.0
#
#--- convert yesterday to seconds
#
    yesterday = str(yesterday)
    year  = int(yesterday[0:4])
    mon   = int(yesterday[4:6])
    day   = int(yesterday[6:8])
    dt    = datetime.datetime(year, mon, day)
    stime = time.mktime(dt.timetuple())

    ctime = [ltime]
    while ltime < stime:
        ltime += 86400.0
        ctime.append(ltime)
#
#--- convert the list to yyyymmdd format
#
    otime = []
    for ent in ctime:
        oday =  time.strftime('%Y%m%d', time.gmtime(ent))
        otime.append(oday)

    return otime


#-------------------------------------------------------------------------------------------

if __name__ == "__main__":

    if len(sys.argv) > 1:
            date = sys.argv[1]
            date.strip()
            update_grad_and_comp_data(date)
    else:
        update_grad_and_comp_data()

