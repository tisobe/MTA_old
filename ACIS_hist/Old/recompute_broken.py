#!/usr/bin/env /fido/ska/censka/bin/python

#########################################################################################################################################
#                                                                                                                                       #
#   acis_hist_extract_data.py: extract acis histgram data and estimates Mn, Al, and Ti K-alpha line parameters                          #
#                                                                                                                                       #
#                       author: t. isobe (tisobe@cfa.harvard.edu)                                                                       #
#                                                                                                                                       #
#                       last update: Apr 11, 2013                                                                                       #
#                                                                                                                                       #
#########################################################################################################################################

import sys
import os
import string
import re
import getpass
import fnmatch
import numpy

#
#--- pylab plotting routine related modules
#

from pylab import *
#import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines


#
#--- reading directory list
#

path = '/data/mta/Script/ACIS/Acis_hist/house_keeping/dir_list_py'
f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)

#
#--- add an extra dir name
#
dir_name = data_dir + 'Dist_data/'

#
#--- append path to a private folder
#

sys.path.append(mta_dir)
sys.path.append(bin_dir)

#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat as tcnv
#
#--- mta common functions
#
import mta_common_functions as mtac
#
#--- least sq fitting routine (see http://www.astro.rug.nl/software/kapteyn/kmpfittutorial.html)
#
from kapteyn import kmpfit

#
#--- read a couple of other parameters
#

ifile = bdata_dir + '.hakama'
f    = open(ifile, 'r')
data = [line.strip() for line in f.readlines()]
f.close()
hakama = data[0]
hakama.strip()

ifile = bdata_dir + '.dare'
f    = open(ifile, 'r')
data = [line.strip() for line in f.readlines()]
f.close()
dare = data[0]
dare.strip()

#--------------------------------------------------------------------------------------------------------
#---- acis_hist_extract_data: extract acis histgram data                                               --
#--------------------------------------------------------------------------------------------------------

def acis_hist_extract_data(year, month):

#
#--- define extracting period in seconds from 1.1.1998
#
    end_year  = year
    end_month = month + 1
    if end_month > 12:
        end_month = 1
        end_year += 1

    ydate = tcnv.findYearDate(year, month, 1)
    period_start = tcnv.convertDateToCTime(year, ydate)
    ydate = tcnv.findYearDate(end_year, end_month, 1)
    period_end   = tcnv.convertDateToCTime(end_year, ydate)
#
#--- extract sim position information
#
    twoarray = extract_sim_position(year, period_start, period_end)

    sim_time = twoarray[0]
    sim_pos  = twoarray[1]

#
#----extract acis hist data from archive using arc4gl
#

    prep_for_arc4gl()

    data_list = use_arc4gl_acis_hist(year, month, end_year, end_month)
#
#--- go though each extracted acis hist data
#
    for file in data_list:
#
#---- isolate id of the file
#
        atemp = re.split('\/', file)
        btemp = re.split('\.fits', atemp[len(atemp) -1])
        name  = btemp[0]
#
#--- extract head info
#
        ccd_info = extract_head_info(file)
        [fep, ccd, node, pblock, tstart, tstop, expcount, date_obs, date_end] = ccd_info

#
#--- extract hist data
#
        hist_data = extract_hist_data(file)

#
#--- find average sim position
#
        sim_info = find_sim_position(sim_time, sim_pos, tstart, tstop)
        [sim_avg, sim_min, sim_max] = sim_info

#
#--- open info file 
#
        info_file = dir_name + 'CCD' + ccd + '/info_file'
        wrt = open(info_file, 'a')

#
#--- for the case that the sim is at the external calibration source position
#

        if (sim_min > -100800 and sim_min < -98400) and (sim_max > -100800 and sim_max < -98400):

#
#--- ccd raws are between 801 and 1001
#

            if int(pblock) == 2334740:
                print file
                peak_info = find_peaks(hist_data)

                line = name + ': source: high\n'
                wrt.write(line)

                print_sim_data(peak_info, sim_info, ccd_info, 'high', web_dir, name)
                plot_fit(hist_data, peak_info, name, ccd, node, 'high')
#
#--- ccd raws are between 21 and 221
#
            if int(pblock) == 2342932:
                print file
                peak_info = find_peaks(hist_data)

                line = name + ': source: low\n'
                wrt.write(line)
    
                print_sim_data(peak_info, sim_info, ccd_info, 'low', web_dir, name)
                plot_fit(hist_data, peak_info, name, ccd, node, 'low')

        cmd = 'rm ' + file
        os.system(cmd)

        wrt.close()


#--------------------------------------------------------------------------------------------------------
#--- extract_sim_position: find sim position from comprehensive_data_summary                          ---
#--------------------------------------------------------------------------------------------------------

def extract_sim_position(year, period_start, period_end):

    """
    extract sim position information from comprehensive_data_summary data file
        input: year (in form of 2012), period_start, period_end in seconds from 1.1.1998
        output: time (seconds from 1.1.1998) sim_position
    """

    sim_time = []
    sim_pos  = []

    file = mj_dir + str(year) + '/comprehensive_data_summary' + str(year)
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    for ent in data:
        m = re.search(str(year), ent)
        if m is not None:
            atemp = re.split('\s+|\t+', ent)

            tinsec = tcnv.axTimeMTA(atemp[0])
    

            if tinsec >= period_start and tinsec < period_end:
                sim_time.append(float(tinsec))
                sim_pos.append(float(atemp[1]))

    twoarray = []
    twoarray.append(sim_time)
    twoarray.append(sim_pos)

    return twoarray


#--------------------------------------------------------------------------------------------------------
#-- prep_output_dir: check whether required directories exist and if not create them                   --
#--------------------------------------------------------------------------------------------------------

def prep_output_dir(year, month):

    """
    THIS IS NOT USED IN THIS SCRIPT (NOV 15, 2012)
    check whether required directories exist and if not create them
    input: year and month
    output: output directories
    """

    lmon = str(int(month))
    if int(month) < 10:
        lmon = '0' + lmon

    dir_name = data_dir + 'Data_' + str(year) + '_' + lmon
#
#--- check whether the directory is already created
#
    chk = mtac.chkFile(dir_name)
    if chk == 0:
        cmd = 'mkdir ' + dir_name
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD0'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD1'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD2'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD3'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD4'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD5'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD6'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD7'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD8'
        os.system(cmd)
        cmd = 'mkdir ' + dir_name + '/CCD9'
        os.system(cmd)

    return dir_name

#--------------------------------------------------------------------------------------------------------
#--- prep_for_arc4gl: prepare a directory for arc4gl output                                           ---
#--------------------------------------------------------------------------------------------------------

def prep_for_arc4gl():

    cmd = 'ls ' + exc_dir +  '> ' + exc_dir + 'ztest'
    os.system(cmd)
    file =  exc_dir + "ztest"
    f    = open(file, 'r')
    data = f.read()
    f.close()
    cmd = 'rm ' + exc_dir + 'ztest'
    os.system(cmd)

    m    = re.search('Temp_dir', data)
    if m is not None:

        cmd = 'ls ' + exc_dir + 'Temp_dir/* > ' + exc_dir + 'ztest'
        os.system(cmd)
        file = exc_dir  + "ztest"
        f    = open(file, 'r')
        data = f.read()
        f.close()
        cmd = 'rm ' + exc_dir + 'ztest'
        os.system(cmd)

        m = re.search('fits',data)
        if m is not None:
            cmd = 'rm ' + exc_dir + 'Temp_dir/*.fits*'
####            os.system(cmd)
    else:
        cmd = 'mkdir ' + exc_dir + 'Temp_dir'
        os.system(cmd)



#--------------------------------------------------------------------------------------------------------
#--- use_arc4gl_acis_hist: using arc4gl to extract acis hist data                                     ---
#--------------------------------------------------------------------------------------------------------

def use_arc4gl_acis_hist(year, month, end_year, end_month):

    '''
    using arc4gl, extreact acis hist data
    input: year, month, end_year, end_month (the last two are in sec from 1.1.1998)
    output: acis hist data in fits files saved in exc_dir/Temp_dir
    '''

#
#--- write a command file
#
    tfile = exc_dir + 'Temp_dir/input_line'
    f  = open(tfile, 'w')
    f.write("operation=retrieve\n")
    f.write("dataset=flight\n")
    f.write("detector=acis\n")
    f.write("level=0\n")
    f.write("filetype=histogr\n")

    lmon = str(int(month))
    if month < 10:
        lmon = '0' + lmon
    lyear = str(year)
    line = 'tstart=' + lmon + '/01/' + lyear[2] + lyear[3] + ',00:00:00\n'
    f.write(line)

    lmon = str(int(end_month))
    if month < 10:
        lmon = '0' + lmon
    lyear = str(end_year)
    line = 'tstop=' + lmon + '/01/' + lyear[2] + lyear[3] + ',00:00:00\n'
    f.write(line)
    f.write("go\n")
    f.close()
#
#--- run arc4gl
#
    cmd = 'cd ' + exc_dir + '/Temp_dir; echo ' + hakama + '| arc4gl -U' + dare + ' -Sarcocc -i./input_line'
#    os.system(cmd)
    cmd = 'rm ' +  tfile
    os.system(cmd)
#
#--- make a list of extracted fits files
#
    cmd = 'ls ' + exc_dir + 'Temp_dir/*fits.* > ' + exc_dir + 'ztemp'
    os.system(cmd)
    file =  exc_dir + 'ztemp'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    cmd = 'rm ' + exc_dir + 'ztemp'
    os.system(cmd)

    return data


#--------------------------------------------------------------------------------------------------------
#--- extract_head_info: extract information from fits head descriptions                               ---
#--------------------------------------------------------------------------------------------------------

def extract_head_info(file):

    '''
    extreact information about the data from the fits file
    input: fits file name
    output: head_info =[fep, ccd, node, pblock, tstart, tstop, expcount, date_obs, date_end]
    '''
#
#--- check whether the temp file exists. if so, remove it
#
    cfile = exc_dir + 'zout'
    chk = mtac.chkFile(cfile)
    if chk > 0:
        cmd = 'rm ' + exc_dir + 'zout'
        os.system(cmd)
#
#--- extract head information using dmlist
#
    cmd = 'dmlist infile=' + file + ' outfile = ' + exc_dir + 'zout opt=head'
    os.system(cmd)
    file = exc_dir + 'zout'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    cmd = 'rm ' + exc_dir + 'zout'
    os.system(cmd)
    
#
#--- find needed information
#
    for ent in data:
        line = re.split('\s+|\t+', ent)

        m1 = re.search("FEP_ID", ent)
        m2 = re.search("CCD_ID", ent)
        m3 = re.search("NODE_ID", ent)
        m4 = re.search("PBLOCK", ent)
        m5 = re.search("TSTART", ent)
        m6 = re.search("TSTOP", ent)
        m7 = re.search("BEP", ent)
        m8 = re.search("EXPCOUNT", ent)
        m9 = re.search("DATE-OBS", ent)
        m10= re.search("DATE-END", ent)

        if m1 is not None:
            fep = line[2]
        elif m2 is not None:
            ccd = line[2]
        elif m3 is not None:
            node = line[2]
        elif m4 is not None:
            pblock = int(line[2])
        elif m5 is not None and m7 is None:
            tstart = float(line[2])
        elif m6 is not None and m7 is None:
            tstop  = float(line[2])
        elif m8 is not None:
            expcount = line[2]
        elif m9 is not None:
            date_obs = line[2]
        elif m10 is not None:
            date_end = line[2]
#
#--- return the info
#
    head_info =[fep, ccd, node, pblock, tstart, tstop, expcount, date_obs, date_end]

    return head_info


#--------------------------------------------------------------------------------------------------------
#---  extract_hist_data: extracting acis hist data from fits file                                     ---
#--------------------------------------------------------------------------------------------------------

def extract_hist_data(file):

    '''
    extracting acis hist data from fits file 
    input: fits file name
    output: one cloumn histgram data

    '''


#
#--- check whether the temp file exists. if so, remove it
#
    cfile = exc_dir + 'zout'
    chk = mtac.chkFile(cfile)
    if chk > 0:
        cmd = 'rm ' + exc_dir + 'zout'
        os.system(cmd)
#
#--- extract data
#
    cmd = 'dmlist "' + file + '[cols counts]" outfile = ' + exc_dir + 'zout  opt=data'
    os.system(cmd)

    file = exc_dir + 'zout'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    cmd = 'rm ' + exc_dir + 'zout'
    os.system(cmd)

    hist_data = []
    for ent in data:
        atemp = re.split('\s+|\t+', ent)
        if mtac.chkNumeric(atemp[0]):
            hist_data.append(float(atemp[1]))

    return hist_data


#--------------------------------------------------------------------------------------------------------
#-- find_sim_postion: for a given time find where the sim is located                                   --
#--------------------------------------------------------------------------------------------------------

def find_sim_position(sim_time, sim_pos, tstart, tstop):

    '''
        for a given time find where the sim is located
            input: sim_time: list of time data
                   sim_pos:  list of sim position
                   tstart:   interval start time
                   tstop:    interval stop time
            output:  a list of estimated (averaged) sim position, smallest and largest sim positions

        HRC-I    +127.0 mm    -51700 - -49300 motor steps
        HRC-S    +250.1 mm    -100800 - -98400 motor steps
        ACIS-S   -190.1 mm   72000-77000 motor steps
        ACIS-I   -233.6 mm   92000-95000 motor steps
        HRC-S, you would expect the external calibration source.
        HRC-I, you would expect only background.  When the sim position is
    '''

    sim_avg = 0
    sum   = 0
    smin  =  1000000
    smax  = -1000000
    tcnt  = 0

    tstart = float(tstart)
    tstop  = float(tstop)

    for istep in range(0, len(sim_time)):
        stime = sim_time[istep]
        if stime > tstart and stime <= tstop:
            sum += sim_pos[istep]
            if sim_pos[istep] < smin:
                smin = sim_pos[istep]

            if sim_pos[istep] > smax:
                smax = sim_pos[istep]

            tcnt += 1

        elif stime > tstop:
            if tcnt == 0:
#
#--- for the case there is no data corrected at the end of the file...
#
                sim_avg = 0.5 * (sim_pos[istep-1] + sim_pos[istep])
                if sim_pos[istep -1] == sim_pos[istep]:
                    smin = sim_avg
                    smax = sim_avg

                elif sim_pos[istep -1] > sim_pos[istep]:
                    smin = sim_pos[istep]
                    smax = sim_pos[istep-1]
                else:
                    smin = sim_pos[istep-1]
                    smax = sim_pos[istep]
                break;

    if tcnt > 0:
        sim_avg = sum / tcnt
    
    if sim_avg == 0:
        smin  = 0
        smax  = 0

    sim_return = [sim_avg, smin, smax]

    return sim_return


#--------------------------------------------------------------------------------------------------------
#-- print_sim_data: print out sim position data                                                       ---
#--------------------------------------------------------------------------------------------------------

def print_sim_data(peak_info, sim_pos_info, ccd_info, loc, web_dir, name):

    '''
    print out sim poisition data
    input: peak_info:    peak1, cnt1, width1, peak2, cnt2, width2, peak3, cnt3, width3
           sim_pos_info: sim_avg, sim_min, sim_max
           ccd_info:     fep, ccd, node, pblock, tstart, tstop, expcount, date_obs, date_end
           loc: location of data collected region usually high or low
    output: web_dir/Results/CCD<ccd>/node<node>_loc
    '''
    [peak1, cnt1, width1, peak2, cnt2, width2, peak3, cnt3, width3]       = peak_info
    [sim_avg, sim_min, sim_max]                                           = sim_pos_info
    [fep, ccd, node, pblock, tstart, tstop, expcount, date_obs, date_end] = ccd_info

    out_dir = data_dir + 'Results/CCD' + str(ccd) + '/node' + str(node) + '_' + loc
    f = open(out_dir, 'a')
    line = str(tstart) + '\t'
    f.write(line)
    line = str(tstop) + '\t'
    f.write(line)
    line = str(expcount) + '\t'
    f.write(line)
    line = str(fep) + '\t'
    f.write(line)

    line = '%6d\t' % (int(sim_avg))
    line = line + '%6d\t' %(int(sim_min))
    line = line + '%6d\t' %(int(sim_max))
    line = line + '%6d\t' %(int(peak1))
    line = line + '%6d\t' %(int(cnt1))
    line = line + '%6d\t' %(int(width1))
    line = line + '%6d\t' %(int(peak2))
    line = line + '%6d\t' %(int(cnt2))
    line = line + '%6d\t' %(int(width2))
    line = line + '%6d\t' %(int(peak3))
    line = line + '%6d\t' %(int(cnt3))
    line = line + '%6d\t' %(int(width3))
    f.write(line)
    line = name + '\n'
    f.write(line)
    f.close()
    


#--------------------------------------------------------------------------------------------------------
#--find_peaks: find 3 peaks from data                                                                 ---
#--------------------------------------------------------------------------------------------------------

def find_peaks(hist_data):

    '''
    find three peaks (mn, al, ti) and fit a gaussian profile
    input: hist_data: distribution data
    output: peak, counts, and width of each peak

    '''

    max       = -999
    xmax      = 0;
    cnt       = 0
    xdata     = []
    ydata     = []
#
#--- save data in the arrays and find the max count postion
#
    for ent in hist_data:
        if cnt > 2500:
            break

        xdata.append(cnt)
        ydata.append(ent)

        if max < ent:
            xmax = cnt
            max  = ent

        cnt += 1

#
#--- Mn peak
#
        try:
            [pos1, count1, width1] =  kmp_wrap(xmax, max, 200, xdata, ydata, cnt)
        except:
            [pos1, count1, width1] = [-999,-999,-999]
#
#--- Al peak
#
        try:
            [pos2, count2, width2] =  kmp_wrap(0.25 * xmax, 0.5 * max, 50, xdata, ydata, cnt)
        except:
            [pos1, count1, width1] = [-999,-999,-999]
#
#---- Ti peak
#
        try:
            [pos3, count3, width3] =  kmp_wrap(0.765 * xmax, 0.5 * max, 100,  xdata, ydata, cnt)
        except:
            [pos1, count1, width1] = [-999,-999,-999]


    return [pos1, count1, width1, pos2, count2, width2, pos3, count3, width3]



#--------------------------------------------------------------------------------------------------------
#-- kmp_wrap: a wrapper to use kmfit routine                                                         ----
#--------------------------------------------------------------------------------------------------------

def kmp_wrap(center, max_cnt,  drange, xdata, ydata, dcnt):

    '''
    a wrapper function to use kmpfit
    input: center: gaussian center position
           max_cnt: gaussinan peak count
           drange:  width of the data collecting area center +/- drange
           xdata:  full sim position data
           ydata:  full sim count data
           dcnt:   number of data points
    output: [center position, count rate, width of the peak]

    '''

    xval = []
    yval = []
    chk  = 0
    
    rmin = int(center - drange)
    rmax = int(center + drange)

    for i in range(0, dcnt):
       if xdata[i] >= rmin and xdata[i] <= rmax:
           xval.append(xdata[i])
           yval.append(ydata[i])
           chk += 1
#
#--- kmpfit, least squares fitting from kapteyn package
#
    if chk > 0 and max_cnt > 0:
        paramsinitial = (center, max_cnt, 10)
        fitobj = kmpfit.Fitter(residuals = residuals, data=(xval, yval))
        fitobj.fit(params0 = paramsinitial)

        [pos, count, width] = fitobj.params

    else:
        pos   = -999
        count = -999
        width = -999

    return [pos, count, width]



#--------------------------------------------------------------------------------------------------------
#-- residuals: compute residuals for Gaussian profile----------------------------------------------------
#--------------------------------------------------------------------------------------------------------

def residuals(param, data):

    '''
    compute residuals for Gaussian profile
    input: param =  (peak, count, width), data = (x, y)
    output: res --- residual
    '''

    x, y       = data
    peak, counts, width  = param

    z = (x - peak) / (width/2.354)
    res = y - counts * exp(-1.0 * (z * z)/2.0)
    return res


#--------------------------------------------------------------------------------------------------------
#--- plot_fit: using pyplot, make a distribution plot                                                 ---
#--------------------------------------------------------------------------------------------------------

def plot_fit(hist_data, peak_info, name, ccd, node, loc):

    '''
    usiing pyplot, make a distribution plot
    input: hist_data, peak_info, name, ccd, node, loc
    output: web_dir/Plot_indivisual/CCD<ccd>/<name>_node</node>_loc.png
            data_dir/Dist_data/CCD<ccd>/<name>_node</node>_loc
    '''

    plot_out =  web_dir + 'Plot_indivisual/CCD' + str(ccd) + '/node' + str(node) + '/'+ loc + '/' +  name + '.png'
    data_out =  data_dir + 'Dist_data/CCD' + str(ccd) + '/node' + str(node) + '/' +  loc + '/' + name
    title    =  name + ': CCD' +  str(ccd) + ' Node' + str(node)

    total = len(hist_data)
    if total < 5:
        cmd = 'cp ' + house_keeping + 'no_data.png ' + plot_out
    else:
        xmin = 0
        xmax = 2000
        xtext= 100
        ymin = 0; 
        ymax = 1.1 * max(hist_data)
        ytext= 0.9 * ymax

        xval = []
        hist = []
        yest = []
        f = open(data_out, 'w')
        for i in range(0, 2000):
            xval.append(i)
            hist.append(hist_data[i])
            yest.append(model(i, peak_info))
            line = str(int(hist_data[i])) + '\n'
            f.write(line)
        f.close()

#
#---- setting a few parameters
#
        plt.close('all')
        mpl.rcParams['font.size'] = 9
        props = font_manager.FontProperties(size=6)

        ax = plt.subplot(1,1,1)

#
#--- setting params
#
        ax.set_autoscale_on(False)         #---- these three may not be needed for the new pylab, but 
        ax.set_xbound(xmin,xmax)           #---- they are necessary for the older version to set

        ax.set_xlim(xmin=xmin, xmax=xmax, auto=False)
        ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)

#
#--- plotting data
#
        plt.plot(xval, hist, color='black',  lw=0, marker='+', markersize=1.5)

#
#--- plotting model
#
        plt.plot(xval, yest,  color='blue',  lw=1)

#
#--- naming
#
        plt.text(xtext, ytext, title)

#
#--- axis
#
        ax.set_ylabel("Counts")
        ax.set_xlabel("Channel")
        
#
#--- set the size of the plotting area in inch (width: 5.0.in, height 3.0in)
#
        fig = matplotlib.pyplot.gcf()
        fig.set_size_inches(8.0, 4.0)

#
#--- save the plot in png format
#
        plt.savefig(plot_out, format='png', dpi=100)
        plt.close('all')


#--------------------------------------------------------------------------------------------------------
#--- model: three peak model fitting                                                                  ---
#--------------------------------------------------------------------------------------------------------

def model(x, params):

    '''
    three peak model fitting
    input: x: position
           params: three sets of peak position, peak count, and width of the peak
    output: estimate
    '''

    [pos1, cnt1, width1, pos2, cnt2, width2, pos3, cnt3, width3] = params
    est1 = 0
    est2 = 0
    est3 = 0
    if width1 > 0:
        z = (x - pos1)/(width1/2.354)
        est1 = cnt1 * exp(-1.0 * (z * z)/2.0)
    if width2 > 0:
        z = (x - pos2)/(width2/2.354)
        est2 = cnt2 * exp(-1.0 * (z * z)/2.0)
    if width3 > 0:
        z = (x - pos3)/(width3/2.354)
        est3 = cnt3 * exp(-1.0 * (z * z)/2.0)

    return est1 + est2 + est3

#----------------------------------------------------------------------------------------------------------

if __name__ == '__main__':

#    year = raw_input("Year: ")
#    if year == '' or year == 'NA':
#        [year, month, day, hours, min, sec, weekday, yday, dst] = tcnv.currentTime('Local')
#
#    else:
#        month = raw_input("Month: ")
#        if month == '' or month == 'NA':
#            [year, month, day, hours, min, sec, weekday, yday, dst] = tcnv.currentTime('Local')
#
#
#    year = int(year)
#    month = int(month)
#    print 'Extracting data for ' + str(year) + ' ' + str(month)
#
#-------------------------------------------------------------------------------------------------------
#
#    [year, month, day, hours, min, sec, weekday, yday, dst] = tcnv.currentTime('Local')
#    acis_hist_extract_data(year, month)
#
    acis_hist_extract_data(2000,1)
