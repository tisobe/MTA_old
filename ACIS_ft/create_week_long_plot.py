#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################
#                                                                                       #
#       create_week_long_plot.py: create focal plane temperature plot for a week period #
#                                                                                       #
#               author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                       #
#               last update: May 14, 2018                                               #
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
#-- create_week_long_plot: create focal plane temperature plots      --
#-------------------------------------------------------------------------------

def create_week_long_plot(year):
    """
    create focal plane temperature plots
    input:  year   --- the year in which you want to create plot
                        if "", it will create the most recent week only
    output: <plot_dir>*.png
    """
#
#--- week long plot
#
    [year, wlist, blist, elist] = find_week(year)
#
#--- crate plots
#
    for k in range(0, len(wlist)):
        week   = wlist[k]
        start  = blist[k]
        stop   = elist[k]

        create_plot(year, week, start, stop)

#-------------------------------------------------------------------------------
#-- create_plot: create focal plane temperature plots for a given week        --
#-------------------------------------------------------------------------------

def create_plot(year, week, start, stop):
    """
    create focal plane temperature plots for a given week
    input:  year    --- year
            week    --- week #
            start   --- start time in seconds from 1998.1.1
            stop    --- stop time in seconds from 1998.1.1
    output: <plot_dir>*.png
    """

    ifile  = data_dir + 'full_focal_plane_data_' + str(year)
    [x, y, rta, rtb] = select_data(ifile, start, stop)

    xlab1  = "Time (Day of Year)"
    ylab1  = "Focal Temp (C)"
    ymin   = -120
    ymax   = -105

    wstart = week * 7 + 1           #--- the first week start day 1
    wstop  =  wstart + 7

    outdir = plot_dir + 'Year' + str(year) 

    if not os.path.isdir(outdir):
        cmd = 'mkdir ' + outdir
        os.system(cmd)

    outfile = 'Year' + str(year) + '/focal_week_long_' + str(week) + '.png'

    plot_data(x, y, rta, rtb, wstart, wstop, ymin, ymax, xlab1, ylab1,  outfile)

#-------------------------------------------------------------------------------
#-- find_week: create lists of week starting and ending times                 --
#-------------------------------------------------------------------------------

def find_week(year):
    """
    create lists of week starting and ending times
    input:  year    --- the year of which we want to get the lists; if "", it makes for this year
    output: year    --- the year of the data extracted
            wlist   --- a list of week #
            blist   --- a list of week starting time in seconds from 1998.1.1
            elist   --- a list of week ending time in seconds from 1998.1.1
    """
    if year == '':
        stday = time.strftime("%Y:%j:%H:%M:%S", time.gmtime())
        today = Chandra.Time.DateTime(stday).secs
        atemp = re.split(':', stday)
        year  = int(atemp[0])
        yday  = int(atemp[1])
        bweek = int(yday/7)
        eweek = bweek + 1

    else:
        bweek = 0
        eweek = 54

    sdate = str(year) + ':001:00:00:00'
    start = Chandra.Time.DateTime(sdate).secs
    stop  = start + 7 * 86400.0
    wlist = []
    blist = []
    elist = []
    for k in range(0, 54):
        if (k >= bweek) and (k < eweek):
            wlist.append(k)
            blist.append(start)
            elist.append(stop)
        start  =  stop
        stop  += 7 * 86400.0

    return [year, wlist, blist, elist]
        
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
        save.append(date[1])

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

    if len(sys.argv) > 1:
        year = int(sys.argv[1])
    else:
        year = ''
    create_week_long_plot(year)
