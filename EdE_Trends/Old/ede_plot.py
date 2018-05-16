#!/usr/bin/env /proj/sot/ska/bin/python

#############################################################################################
#                                                                                           #
#           ede_plot.py:    plotting evolution of EdE for ACIS S and HRC S grating obs      #
#                                                                                           #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                           #
#           last update: Jun 18, 2014                                                       #
#                                                                                           #
#############################################################################################

import os
import sys
import re
import string
import math
import random
import operator

import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

#
#--- reading directory list
#
path = '/data/mta/Script/Grating/EdE/house_keeping/dir_list_py'

f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)

#
#--- append a path to a private folder to python directory
#
sys.path.append(bin_dir)
sys.path.append(mta_dir)
#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat    as tcnv
import mta_common_functions as mcf
import robust_linear        as robust

#
#--- temp writing file name
#

rtail  = int(10000 * random.random())
zspace = '/tmp/zspace' + str(rtail)

#---------------------------------------------------------------------------------------------------
#-- ede_plots: plotting time evolution of EdE                                                    ---
#---------------------------------------------------------------------------------------------------

def ede_plots(file):

    """
    plotting time evolution of EdE
    Input:  file    --- a file name of data
    Output: *_plot.png/*_low_res_plot.png --- two plots; one is in 200dpi and another in 40dpi
    """
#
#--- read data
#
    [xdata, ydata, yerror] = read_data(file)
#
#--- set plotting range
#
    [xmin, xmax, ymin, ymax] = set_min_max(ydata)
    ymax = 2100

    xname = 'Time (year)'
    yname = 'EdE'
    label = create_label(file)
    out   = file + '.png'
    out   = out.replace('Data', 'Plots')
    out1  = out.replace('_data.png', '_plot.png')
    out2  = out.replace('_data.png', '_low_res_plot.png')
#
#--- create two figures. One is 200dpi and another for 40dpi. the low res plot is great for the intro page
#
    plot_single_panel(xmin, xmax, ymin, ymax, xdata, ydata, yerror, xname, yname, label, out1, resolution=200)
    plot_single_panel(xmin, xmax, ymin, ymax, xdata, ydata, yerror, xname, yname, label, out2, resolution=40)


#---------------------------------------------------------------------------------------------------
#-- set_min_max: set plotting range                                                              ---
#---------------------------------------------------------------------------------------------------

def set_min_max(ydata):

    """
    set plotting range
    Input:  ydata   ---- ydata
    Output: [xmin, xmax, ymin, ymax]
    """

    xmin  = 1999
    tlist = tcnv.currentTime()
    xmax  = tlist[0] + 1

    ymin  = min(ydata)
    ymax  = max(ydata)
    ydiff = ymax - ymin
    ymin -= 0.1 * ydiff
    ymax += 0.2 * ydiff
    if ymin < 0:
        ymin = 0

    return [xmin, xmax, ymin, ymax]


#---------------------------------------------------------------------------------------------------
#-- create_label: create a label for the plot from the data file                                 ---
#---------------------------------------------------------------------------------------------------

def create_label(file):

    """
    create a label for the plot from the data file
    Input:  file    --- input file name
    Output: out     --- text 
    """

    atemp = re.split('\/', file)
    line  = atemp[len(atemp)-1]
    if line == '':
        line = file

    atemp  = re.split('_', line)
    inst   = atemp[0].upper()
    grat   = atemp[1].upper()
    energy = atemp[2]
    energy = energy[0] + '.' + energy[1] + energy[2] + energy[3]
    
    out   = 'Line: ' + str(energy) + 'keV : ' + inst + '/' +  grat

    return out


#---------------------------------------------------------------------------------------------------
#-- read_data: read data from a given file                                                       ---
#---------------------------------------------------------------------------------------------------

def read_data(file):

    """
    read data from a given file
    Input:  file    --- input file name
    Output: date_list   --- a list of date
            ede_list    --- a list of ede value
            error_list  --- a list of computed ede error
    """

    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    date_list  = []
    ede_list   = []
    error_list = []
    for ent in data:
        atemp = re.split('\s+', ent)
        if mcf.chkNumeric(atemp[0])== False:
            continue

        fwhm = float(atemp[2])
        ferr = float(atemp[3])
        ede  = float(atemp[4])
        dom  = float(atemp[10])
        (year, ydate) = tcnv.DOMtoYdate(dom)
        if tcnv.isLeapYear(year) == 1:
            base = 366
        else:
            base = 365
        fyear = year + ydate/base
        date_list.append(fyear)
        ede_list.append(ede)
#
#--- the error of EdE is computed using FWHM and its error value
#
        error = math.sqrt(ede*ede* ((ferr*ferr) / (fwhm*fwhm)))

        error_list.append(error)


    return [date_list, ede_list, error_list]



#---------------------------------------------------------------------------------------------------
#-- plot_single_panel: plot a single data set on a single panel                                  ---
#---------------------------------------------------------------------------------------------------

def plot_single_panel(xmin, xmax, ymin, ymax, xdata, ydata, yerror, xname, yname, label, outname, resolution=100):

    """
    plot a single data set on a single panel
    Input:  xmin    --- min x
            xmax    --- max x
            ymin    --- min y
            ymax    --- max y
            xdata   --- independent variable
            ydata   --- dependent variable
            yerror  --- error in y axis
            xname   --- x axis label
            ynane   --- y axis label
            label   --- a text to indecate what is plotted
            outname --- the name of output file
            resolution-- the resolution of the plot in dpi
    Output: png plot named <outname>
    """

#
#--- fit line --- use robust method
#
    (sint, slope, serr) = robust.robust_fit(xdata, ydata)
    lslope = '%2.3f' % (round(slope, 3))
#
#--- close everything opened before
#
    plt.close('all')
#
#--- set font size
#
    mpl.rcParams['font.size'] = 12
    props = font_manager.FontProperties(size=9)
#
#--- set plotting range
#
    ax  = plt.subplot(111)
    ax.set_autoscale_on(False)
    ax.set_xbound(xmin,xmax)
    ax.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)
#
#--- plot data
#
    plt.plot(xdata, ydata, color='blue', marker='o', markersize=4.0, lw =0)
#
#--- plot error bar
#
    plt.errorbar(xdata, ydata, yerr=yerror, lw = 0, elinewidth=1)
#
#--- plot fitted line
#
    start = sint + slope * xmin
    stop  = sint + slope * xmax
    plt.plot([xmin, xmax], [start, stop], color='red', lw = 2)
#
#--- label axes
#
    plt.xlabel(xname)
    plt.ylabel(yname)
#
#--- add what is plotted on this plot
#
    xdiff = xmax - xmin
    xpos  = xmin + 0.5 * xdiff
    ydiff = ymax - ymin
    ypos  = ymax - 0.08 * ydiff

    label = label + ': Slope:  ' + str(lslope)

    plt.text(xpos, ypos, label)

#
#--- set the size of the plotting area in inch (width: 10.0in, height 2.08in x number of panels)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 5.0)
#
#--- save the plot in png format
#
    plt.savefig(outname, format='png', dpi=resolution)

#--------------------------------------------------------------------

#
#--- pylab plotting routine related modules
#

from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

if __name__ == '__main__':

    cmd  = 'ls /data/mta_www/mta_grat/EdE_trend/EdE_Data/*_data > ' + zspace
    os.system(cmd)

    f    = open(zspace, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    for file in data:
        ede_plots(file)


