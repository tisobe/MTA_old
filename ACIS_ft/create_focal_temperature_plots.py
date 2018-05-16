#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################
#                                                                                       #
#       create_focal_temperature_plots.py: create focal plane temperature plot          #
#                                                                                       #
#               author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                       #
#               last update: May 09, 2018                                               #
#                                                                                       #
#########################################################################################

import sys
import os
import string
import re
import numpy
import getopt
import time
import Chandra.Time
import unittest

#
#--- interactive plotting module
#
import mpld3
from mpld3 import plugins, utils


import matplotlib as mpl
from matplotlib import gridspec

mpl.use('Agg')

from pylab import *
import matplotlib.pyplot       as plt

from matplotlib import gridspec


#
#--- reading directory list
#
path = '/data/mta/Script/ACIS/Focal/Script/house_keeping/dir_list'

f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var   = atemp[1].strip()
    line  = atemp[0].strip()
    exec "%s = %s" %(var, line)
#
#--- append path to a private folder
#
sys.path.append(mta_dir)
sys.path.append(bin_dir)

import mta_common_functions     as mcf
import convertTimeFormat        as tcnv
#
#--- temp writing file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)

d_in_sec = 86400.0

#-------------------------------------------------------------------------------
#-- create_focal_temperature_plots: create focal plane temperature plots      --
#-------------------------------------------------------------------------------

def create_focal_temperature_plots():
    """
    create focal plane temperature plots
    input:  none but read from <data_dir>
    output: <plot_dir>*.png
    """
    xlab1 = "Time (Day of Year)"
    xlab2 = "Time (Year)"
    ylab1 = "Focal Temp (C)"
    ylab2 = "Temp (C)"

#
#--- find current time
#
    stday = time.strftime("%Y:%j:%H:%M:%S", time.gmtime())
    today = Chandra.Time.DateTime(stday).secs
    atemp = re.split(':', stday)
    year  = int(atemp[0])
    nyear = year + 1
#
#--- week long plot
#
    ifile  = data_dir + 'full_focal_plane_data_' + str(year)
    cut    = today   - 8 * d_in_sec
    start  = int(change_ctime_to_ydate(cut)[1])
    stop   = int(change_ctime_to_ydate(today)[1])
    [x, y, rta, rtb] = select_data(ifile, cut, today)
    ymin   = -120
    ymax   = -105
    xlab3  = "Time (Day of Year" + str(year) + ")"
    plot_data(x, y, rta, rtb, start, stop, ymin, ymax, xlab3, ylab1,  "focal_week_long.png")

#
#--- one year long plot
#
    cut    = 0
    ifile  = data_dir + 'focal_plane_data_5min_avg_' +  str(year)
    [x, y, rta, rtb] = select_data(ifile, cut, today)
    ymin   = -120
    ymax   = -105
    outplt = 'focal_1year_long_' + str(year) +'.png'
    plot_data(x, y, rta, rtb, 0, 366, ymin, ymax, xlab1, ylab1, outplt, width=25, height=2.5)

#
#--- full range plot
#
    ifile  = data_dir + 'long_term_max_data'
    cut    = 0.0
    [x, y, rta, rtb] = select_data(ifile, cut, today, yd=0)
    ymin   = -120
    ymax   = -105
    plot_data(x, y, rta, rtb, 2000, nyear, ymin, ymax, xlab2, ylab1, "focal_full_range.png")

#-------------------------------------------------------------------------------
#-- create_interactive_plot: create an interactive plot segment for a html page 
#-------------------------------------------------------------------------------

def create_interactive_plot(start, stop, binsize):
    """
    create an interactive plot segment for a html page
    input:  start   --- start time
            stop    --- stop time
            format is either chandra time, <yyyy>:<ddd>:<hh>:<mm>, or <yyyy>-<mm>-<dd>T<hh>:<mm>:<ss>
            binsize --- bin size in seconds
    output: pout    --- interactive plot segment of a html page
    """
#
#--- get data; the data could be over 2 years; so we need to handle slightly differently
#
    [x, y, rta, rtb] = select_data_over_data_files(start, stop, binsize)
    xmin   = x[0]
    xmax   = x[-1]
    xdiff  = xmax - xmin
    xmin  -= 0.05 * xdiff
    xmax  += 0.05 * xdiff
    ymin   = -120
    ymax   = -105
#
#--- create the interactive plot
#

    xlab1 = "Time (Day of Year)"
    ylab2 = "Temp (C)"
    pout   = plot_data(x, y, rta, rtb, xmin, xmax, ymin, ymax, xlab1, ylab2,  "", inter=1)

    return pout

#-------------------------------------------------------------------------------
#-- select_data_over_data_files: select data with possibility of over several data files
#-------------------------------------------------------------------------------

def select_data_over_data_files(start, stop, binsize):
    """
    select data with possibility of over several data files
    input:  start   --- start time
            stop    --- stop time
            format is either chandra time, <yyyy>:<ddd>:<hh>:<mm>, or <yyyy>-<mm>-<dd>T<hh>:<mm>:<ss>
            binsize --- bin size in seconds
    output: x       --- a list of time
            y       --- a list of focal temp
            rta     --- a list of 1crat
            rtb     --- a list of 1crbt
    """

    [year1, start] = check_time_format(start)
    [year2, stop]  = check_time_format(stop)

    x   = []
    y   = []
    rta = []
    rtb = []
    chk = 0
    for year in range(year1, year2+1):
        ifile = data_dir + 'full_focal_plane_data_' + str(year)
        data  = read_file_data(ifile)
        for ent in data:
            atemp = re.split('\s+', ent)
            atime = float(atemp[0])
            if atime < start:
                continue
            if atime > stop:
                break

            x.append(float(atemp[0]))
            y.append(float(atemp[1]))
            rta.append(float(atemp[2]))
            rtb.append(float(atemp[3]))
    
    if binsize == 0:

        x = convert_to_ydate_list(x)

        return [x, y, rta, rtb]

    else:
#
#--- binning of the data
#
        hbin  = int(0.5 * binsize)

        xa    = []
        ya    = []
        raa   = []
        rab   = []
    
        yt    = []
        rxa   = []
        rxb   = []
        begin = x[0]
        end   = begin + binsize
        for k in range(0, len(x)):
            if (x[k] >= begin) and (x[k] < end):
                yt.append(y[k])
                rxa.append(rta[k])
                rxb.append(rtb[k])
            else:
                xa.append(begin + hbin)
                ya.append(numpy.average(yt))
                raa.append(numpy.average(rxa))
                rab.append(numpy.average(rxb))

                yt    = [y[k]]
                rxa   = [rta[k]]
                rxb   = [rtb[k]]
                begin = end
                end   = begin + binsize
    
        if len(yt) > 0:
            xa.append(int(0.5 * (begin + x[-1])))
            ya.append(numpy.average(yt))
            raa.append(numpy.average(rxa))
            rab.append(numpy.average(rxb))
    
        xa = convert_to_ydate_list(xa)

        return [xa, ya, raa, rab]


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

def convert_to_ydate_list(x):

    nx = []
    byear = ''
    for val in x:
        cdata = change_ctime_to_ydate(val)
        if byear == '':
            byear = cdata[0]
            if tcnv.isLeapYear(byear) == 1:
                base = 366
            else:
                base = 365
        if cdata[0] > byear:
            nx.append(cdata[1] + base)
        else:
            nx.append(cdata[1])

    return nx

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

def adjust_year_date(byear, x):

    if tcnv.isLeapYear(byear) == 1:
        base = 366
    else:
        base = 365

    nx = []
    for ent in x:
        if ent[0] != byear:
            val = float(ent[1]) + base
            nx.append(val)
        else:
            nx.append(float(ent[1]))

    return nx

#-------------------------------------------------------------------------------
#-- check_time_format: return time in Chandra time                            --
#-------------------------------------------------------------------------------

def check_time_format(intime):
    """
    return time in Chandra time
    input:  intime  --- time in <yyyy>:<ddd>:<hh>:<mm>:<ss> or <yyyy>-<mm>-<dd>T<hh>:<mm>:<ss> or chandra time
    output: yeaer   --- the year
            time in chandra time (seconds from 1998.1.1)
    """
    
    mc1 = re.search('-', intime)
    mc2 = re.search(':', intime)
#
#--- it is already chandra format
#
    if mcf.chkNumeric(intime):
        out   = Chandra.Time.DateTime(intime).date
        atemp = re.split(':', out)
        year  = int(atemp[0])
        return [year, int(float(intime))]
#
#--- time in <yyyy>-<mm>-<dd>T<hh>:<mm>:<ss>
#
    elif mc1 is not None:
        mc2 = re.search('T', intime)
        if mc2 is not None:
            atemp = re.split('T', intime)
            btemp = re.split('-', atemp[0])
            year  = int(float(btemp[0]))
            mon   = int(float(btemp[1]))
            day   = int(float(btemp[2]))
            ctemp = re.split(':', atemp[1])
            hrs   = ctemp[0]
            mins  = ctemp[1]
            secs  = ctemp[2]
     
        else:
            btemp = re.split('-', intime)
            year  = int(float(btemp[0]))
            mon   = int(float(btemp[1]))
            day   = int(float(btemp[2]))
            hrs   = '00'
            mins  = '00'
            secs  = '00'
    
        yday = datetime.date(year, mon, day).timetuple().tm_yday
     
        cyday = str(yday)
        if yday < 10:
            cyday = '00' + cyday
        elif yday < 100:
            cyday = '0' + cyday
    
        ytime = btemp[0] + ':' + cyday + ':' + hrs + ':' + mins + ':' + secs

        return [year, Chandra.Time.DateTime(ytime).secs]
#
#--- time in <yyyy>:<ddd>:<hh>:<mm>:<ss>
#
    elif mc2 is not None:

        atemp = re.split(':', intime)
        year  = int(atemp[0])
        return [year, Chandra.Time.DateTime(intime).secs]


#-------------------------------------------------------------------------------
#-- select_data: select data in the range and change the time format           -
#-------------------------------------------------------------------------------

def select_data(ifile, start, stop, yd=1):
    """
    select data in the range and change the time format
    input:  ifile   --- data file name
            cut     --- the data cut time in seconds from 1998.1.1
            yd      --- indicator to create fractional year (0) or ydate (1)
    output  xdata   --- a list of time data
            ydata   --- a list of temperature data
            radata  --- a list of 1crat data
            rbdata  --- a list of 1crbt data
    """

    data  = read_file_data(ifile)
    xdata  = []
    ydata  = []
    radata = []
    rbdata = []
    for ent in data:
        atemp = re.split('\s+', ent)
        atime = float(atemp[0])
        if atime < start:
            continue
        if atime > stop:
            break

        xdata.append(atime)
        fval  = float(atemp[1])
        ydata.append(fval)

        test  = float(atemp[2])
        if test > -110:
            test = -125
        diff = fval - test
        radata.append(diff)

        test  = float(atemp[3])
        if test > -110:
            test = -125
        diff = fval - test
        rbdata.append(diff)

    xdata = convert_date_list(xdata, yd=yd)

    return [xdata, ydata, radata, rbdata]


#-------------------------------------------------------------------------------
#-- plot_data: plot the data                                                  --
#-------------------------------------------------------------------------------

def plot_data(x, y0, y1, y2, xmin, xmax, ymin, ymax,  xname, yname, outname, width=4, height=3, inter=0):
    """
    plot the data
    input:  x       --- a list of x data
            y       --- a list of y data
            xmin    --- a min of the x plotting range
            xmax    --- a max of the x plotting range
            ymin    --- a min of the y plotting range
            ymax    --- a max of the y plotting range
            xname   --- x axis label
            yname   --- y axis label
            outname --- output file name
            width   --- width of the plot in inches
            height  --- height of the plot in inches
            inter   --- indicator to create an interactive page (if > 0)
    output: outname --- a png file
    """
#
#--- close everything opened before starting a new one
#
    plt.close('all')
#
#---- set parameters
#
    mpl.rcParams['font.size'] = 5
    xpos = xmin + 0.05 * (xmax - xmin)
    mks  = 0.5
    mkt  = '.'
    if inter > 0:
        mks = 4.0
        mkt = '*'
#
#--- set plotting range
#
    fig = plt.figure()
    gs  = gridspec.GridSpec(3, 1, height_ratios=[3,1,1])

#--- plot data
#
    ax0 = plt.subplot(gs[0])
    ax0.set_xbound(xmin, xmax)
    ax0.set_ybound(-120, -100)
    ax0.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax0.set_ylim(ymin=-120, ymax=-100, auto=False)
    ax0.text(xpos, -103, "Focal", fontsize=6)

    line0 = ax0.plot(x, y0, color='r', marker=mkt, markersize=mks, lw=0, label='Focal')
    plt.ylabel("Temp (C)", position=(0.1, 0.1))

    ax1 = plt.subplot(gs[1])
    ax1.set_xbound(xmin, xmax)
    ax1.set_ybound(3, 13)
    ax1.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax1.set_ylim(ymin=3, ymax=13, auto=False)
    ax1.text(xpos, 11, "(Focal - 1CRAT)", fontsize=6)

    line1 = ax1.plot(x, y1, color='b', marker=mkt, markersize=mks, lw=0, label='Focal - 1CRAT')

    ax2 = plt.subplot(gs[2])
    ax2.set_xbound(xmin, xmax)
    ax2.set_ybound(3, 13)
    ax2.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax2.set_ylim(ymin=3, ymax=13, auto=False)
    ax2.text(xpos, 11, "(Focal - 1CRBT)", fontsize=6)

    line2 = ax2.plot(x, y2, color='g', marker=mkt, markersize=mks, lw=0, label='Focal - 1CRBT')

    plt.subplots_adjust(hspace=0.08)

    plt.xlabel(xname)

    line = ax0.get_xticklabels()
    for label in line:
        label.set_visible(False)

    line = ax1.get_xticklabels()
    for label in line:
        label.set_visible(False)
#
#--- create a standard plot file (png)
#
    if inter == 0:
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5 in)
#
        fig = matplotlib.pyplot.gcf()
        fig.set_size_inches(width, height)
#
#--- save the plot in png format
#
        plt.savefig('ztemp.png', format='png', dpi=200)
#
#--- close the plot
#
        plt.close('all')

        cmd = 'convert ./ztemp.png -trim ' + plot_dir +  outname
        os.system(cmd)
        mcf.rm_file('ztemp.png')
#
#--- create an interactive page
#
    else:
        pout =  mpld3.fig_to_html(fig)

        plt.close('all')
        return pout

#-------------------------------------------------------------------------------
#-- set_plotting_range: find min/max of x and y axes and set plotting ranges  --
#-------------------------------------------------------------------------------

def set_plotting_range(x, y):
    """
    find min/max of x and y axes and set plotting ranges
    input:  x   --- a list of x data
            y   --- a list of y data
    output: [xmin, xmax, ymin, ymax]
    """
    
    xmin = int(min(x))
    xmax = int(max(x))
    [xmin, xmax] = range_expand(xmin, xmax)
    
    ymin = int(min(y))
    ymax = int(max(y))
    [ymin, ymax] = range_expand(ymin, ymax)

    return [xmin, xmax, ymin, ymax]

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

def range_expand(amin, amax):

    diff  = amax - amin
    amax += 0.1 * diff
    amax  = int(amax)

    amin -= 0.1 * diff
    amin  = int(amin)

    return [amin, amax]

#-------------------------------------------------------------------------------
#-- convert_date_list: convert date format in the list to either fractional year or ydate
#-------------------------------------------------------------------------------

def convert_date_list(list, yd=1):
    """
    convert date format in the list to either fractional year or ydate
    input:  list    --- a list of date
            yd      --- indicator to create fractional year (0) or ydate (1)
    output: save    --- a list of date in the new format
    """

    save = []
    for ent in list:
        date = change_ctime_to_ydate(ent, yd=yd)
        save.append(date)

    return save

#-------------------------------------------------------------------------------
#-- change_ctime_to_ydate: convert chandra time into fractional year or ydate --
#-------------------------------------------------------------------------------

def change_ctime_to_ydate(cdate, yd=1):
    """
    convert chandra time into fractional year or ydate
    input:  cdate   --- chandra time
            yd      --- indicator to create fractional year (0) or ydate (1)
    output: year    --- the year of the date
            date    --- if yd==0, date in fractional year, otherwise, in ydate
    """

    date  = Chandra.Time.DateTime(cdate).date
    atemp = re.split(':', date)
    year  = float(atemp[0])
    date  = float(atemp[1])
    hh    = float(atemp[2])
    mm    = float(atemp[3])
    ss    = float(atemp[4])
    date += (hh + mm / 60.0 + ss / 3600.0) /24.0

    if yd == 1:
        return [year, date]
    else:
        if tcnv.isLeapYear(year) == 1:
            base = 366
        else:
            base = 365

        date = year + date /base

        return [year, date]

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

def read_file_data(infile, remove=0):

    f    = open(infile, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    if remove == 1:
        mcf.rm_file(infile)

    return data

#-------------------------------------------------------------------------------

if __name__ == "__main__":

    create_focal_temperature_plots()
