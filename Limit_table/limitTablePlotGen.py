#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################################
#                                                                                                                   #
#   plotMsidLimits.py: read trend data for a given group and create plots for each msid                             #
#                                                                                                                   #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                               #
#                                                                                                                   #
#           last update: Jun 27, 2014                                                                               #
#                                                                                                                   #
#####################################################################################################################

import sys
import os
import string
import re
import copy
import random

#
#--- define a temp file name
#

ztemp = '/tmp/ztemp' + str(random.randint(0,10000))

#
#--- pylab plotting routine related modules
#

from pylab import *
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

#
#--- reading directory list
#

path = '/data/mta/Script/Limit_table/house_keeping/dir_list'
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

sys.path.append(mta_dir)
sys.path.append(bin_dir)

#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat as tcnv


####################################################################################################################
####  msidLimitPlot:  read trend data for a given group and create plots for each msid                          ####
####################################################################################################################

def msidLimitPlot(file, out_path):

    """
    read trend data for a given group and create plots for each msid
    input:    file: data file name (full data path required)
              out_path: a directory path where all plots are saved
    output:   plots in png format.
    """

#
#--- read data
#
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

#
#--- find msid names (column names)
#
    colEnt = re.split('\s+|\t+', data[0])
    colLen  = len(colEnt)
    colName = []
#
#--- header is in the form of <msid> std <msid> ste ...  so need skip std part
#
    for ent in colEnt:
        m = re.search('_dev', ent)
        if ent != 'std' and ent != '#time' and (m is None):
            colName.append(ent)
#
#-- read and save the data
#
    time    = []
    for k in range(0, int(colLen/2)+1):
        exec("avg%d = []" % (k))
        exec("sig%d = []" % (k))

    total = 0
    for line in data:
        if total == 0:
            total += 1
        else:
            atemp    = re.split('\s+|\t+', line)

            try:
                yearDate = convertToYearDate(float(atemp[0]))
                time.append(yearDate)

                for k in range(1, colLen):
                    k2 = int(k/2)
                    if k % 2 == 0:
                        k2 -= 1
                        exec("sig%d.append(float(atemp[%d]))" % (k2, k))
                    else:
                        exec("avg%d.append(float(atemp[%d]))" % (k2, k))

                total += 1
            except:
                pass

#
#--- create a trend plot for each msid
#

    for k in range(0, int(colLen/2)):
       col = colName[k]
       exec("davg = avg%d" % (k))
       exec("dsig = sig%d" % (k))

       clnavg = []
       clnsig = []
       clntime= []
       for i in range(0, len(davg)):
            try: 
                tst = int(davg[i])
                tst = int(dsig[i])
                clnavg.append(davg[i])
                clnsig.append(dsig[i])
                clntime.append(time[i])
            except:
                pass

       plotPanel(col, clntime, clnavg, clnsig, out_path)

####################################################################################################################
#### plotPanel: plotting each panel                                                                             ####
####################################################################################################################

def plotPanel(col, time, davg, dsig, out_path):

    """
    plot a trend of yellow/red min/max limits.
    input;   col: name of the data set
             time: time data in fractional year date
             davg: a set of 6 months average data
             dsig: standard deviation of each 6 month period
             out_path:  a locaiton of plot deposit

    output:  a plot in png format: out_pth/<col>.png

    """

#
#--- clean up the data
#
    ctime = []
    cavg  = []
    csig  = []
    for i in range(0, len(time)):
        try:                                                #---- testing the values are not NaN
            test = '%6d' % (time[i])
            test = '%6d' % (davg[i])
            test = '%6d' % (dsig[i])
            ctime.append(time[i])
            cavg.append(davg[i])
            csig.append(dsig[i])
        except:
            pass

#
#--- for the case there is no data
#
    length = len(ctime)
    if length < 5:
        name = out_path + '/' + col + '.png'
        cmd  = 'cp ' +  house_keeping + 'no_data.png ' + name
        os.system(cmd)

        return
#
#--- normal plotting case
#

#
#--- set x axis plotting limits
#
    temp   = ctime
    temp.sort(key=float)
#    xmin   = temp[0]
#    xmax   = temp[length-1]
    xmin   = 2000.0
    [tyear, tmon, tday, thours, tmin, tsec, tweekday, tyday, tdst] = tcnv.currentTime()
    if tyday < 183:
        xmax   = float(tyear)
    else:
        xmax   = tyear + 0.5

    xdiff  = xmax - xmin
    xmin  -= 0.1 * xdiff
    xmax  += 0.1 * xdiff
    xdiff  = xmax - xmin
    xbot   = xmin + 0.05 * xdiff
#
#--- make a moving average of standard deviation
#

    step  = 4                                   #---- this makes two year moving average
    msig  = makeMovingAvg(csig, step)
    mavg  = makeMovingAvg(cavg, step)

#
#--- set yellow/red min/max limits
#
    mtime       = []                            #---- time period adjusted for moving average
    upperYellow = []
    upperRed    = []
    lowerYellow = []
    lowerRed    = []

    smoothavg    = []

#    for k in range(step - 1, len(cavg)):
    for k in range(step, len(cavg)):

        mtime.append(time[k])
        madd = msig[k - step]
#        mbase = mavg[k - step]
        mbase = davg[k]

#        upperYellow.append(cavg[k] + 4.0 * madd)
#        upperRed.append(cavg[k]    + 5.0 * madd)
#        lowerYellow.append(cavg[k] - 4.0 * madd)
#        lowerRed.append(cavg[k]    - 5.0 * madd)
        upperYellow.append(mbase + 4.0 * madd)
        upperRed.append(mbase    + 5.0 * madd)
        lowerYellow.append(mbase - 4.0 * madd)
        lowerRed.append(mbase    - 5.0 * madd)
        smoothavg.append(mbase)

#
#--- set y axis plotting limits
#
    ymin  = min(lowerRed)
    ymax  = max(upperRed)
    ydiff = ymax - ymin

    if ydiff == 0:
        ymin -= 1
        ymax += 1
    else:
        ymin  -= 0.1 * ydiff
        ymax  += 0.1 * ydiff
    ydiff  = ymax - ymin
    ytop   = ymax - 0.12 * ydiff

#
#--- setting a few parameters
#

    plt.close('all')
    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=6)

    ax = plt.subplot(1,1,1)


#
#--- setting panel
#
    ax.set_autoscale_on(False)         #---- these three may not be needed for the new pylab, but 
    ax.set_xbound(xmin,xmax)           #---- they are necessary for the older version to set

    ax.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)

#
#--- plotting
#--- for the average, we don't use the moving average; only limit envelops use moving averages.
#
#    plt.plot(time,  davg,        color='blue',  lw=1, marker='+', markersize=1.5)
    plt.plot(mtime, smoothavg,   color='blue',  lw=1, marker='+', markersize=1.5)
    plt.plot(mtime, upperYellow, color='yellow',lw=1, marker='+', markersize=1.5)
    plt.plot(mtime, lowerYellow, color='yellow',lw=1, marker='+', markersize=1.5)
    plt.plot(mtime, upperRed,    color='red',   lw=1, marker='+', markersize=1.5)
    plt.plot(mtime, lowerRed,    color='red',   lw=1, marker='+', markersize=1.5)

#
#--- naming
#
    plt.text(xbot, ytop, col)

#
#--- axis
#
    ax.set_ylabel(col)
    ax.set_xlabel('Time (Year)')
#
#--- set the size of the plotting area in inch (width: 5.0.in, height 3.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(5.0, 3.0)
#
#--- save the plot in png format
#
    name = out_path + '/' + col + '.png'
    plt.savefig(name, format='png', dpi=100)
    plt.close('all')

#------------------------------------------------------------------------------------------------------------
#-- convertToYearDate: converts date in second from 1988.1.1 into date in fractional year format          ---
#------------------------------------------------------------------------------------------------------------

def convertToYearDate(val):

    """
    convert seconds from 1988,1.1. to date in fractional year e.g, 2012.134
    input:   date in the format of of second from 1988.1.1
    output:  date in a fractional year. 
    """

    ntime = tcnv.convertCtimeToYdate(val)

    btemp = re.split(':', ntime)
    year  = float(btemp[0])
    ydate = float(btemp[1])
    hour  = float(btemp[2])
    mins  = float(btemp[3])

    chk   = int(0.25 * year)
    if chk == year:
        base = 366
    else: 
        base = 365

    yearDate = year + (ydate + hour/24.0 + mins/1440.0) / base

    return yearDate


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

def makeMovingAvg(data, step):

    length = len(data)
    adata = []

    for k in range(step, length):
        sum = 0
        stot = 0
        for j in range(k - step, k):
            try:
                sum += data[j]
                stot += 1
            except:
                pass

        mavg = sum / stot
        adata.append(mavg)

    return adata

#------------------------------------------------------------------------------------------------------------

if __name__ == '__main__':

    file = raw_input("Data File Name: ")

    if file == '' or file.lower() == 'n':

        cmd = 'ls ' + data_dir +'/Data/* >' + ztemp 
        os.system(cmd)
        f   = open(ztemp, 'r')
        dat = [line.strip() for line in f.readlines()]
        f.close()
        cmd = 'rm ' + ztemp
        os.system(cmd)

        data_set = []
        for ent in dat:
            m = re.search('html', ent)
            if m is None:
                data_set.append(ent)
    
        for file in data_set:
            print file
            atemp = re.split('\/', file);
            group = atemp[len(atemp) -1]
            out_dir = plot_dir + group
            msidLimitPlot(file, out_dir)

    else:
        atemp = re.split('\/', file);
        group = atemp[len(atemp) -1]
        out_dir = plot_dir + group 
        msidLimitPlot(file, out_dir)
        
