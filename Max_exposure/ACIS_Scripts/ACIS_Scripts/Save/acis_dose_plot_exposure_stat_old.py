#!/usr/local/bin/python2.6

#########################################################################################
#                                                                                       #
#       acis_dose_plot_exposure_stat.py:  plotting trendings of avg, min, 10th bright,  #
#                                       and max counts of each quadrant of I2, I3,      #
#                                       S2, and S3.                                     #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last update: Jun 27, 2012                                                       #
#                                                                                       #
#########################################################################################


import sys
import os
import string
import re
import copy

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

path = '/data/mta/Script/Exposure/house_keeping2/acis_dir_list'
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

#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat as tcnv

#
#--- Exposure related funcions shared
#

import exposureFunctions as expf

#------------------------------------------------------------------------------------------------------------------------
#--- acis_dose_plot_exposure_stat: read hrc database, and plot history of exposure                                     ---
#------------------------------------------------------------------------------------------------------------------------

def acis_dose_plot_exposure_stat(indir = 'NA', outdir = 'NA', indir2 = 'NA', outdir2 = 'NA', clean = 'NA'):

    'read acis database, and plot history of exposure. input: data directory path, output directory path '
#
#--- setting indir and outdir if not given
#
    if indir   == 'NA':
        indir   = data_out

    if outdir  == 'NA':
        outdir  = plot_dir
#
#--- clean up the data sets before reading
#
    if clean != 'NA':
        expf.clean_data(indir)

#
#--- start plotting data
#
    for ccd in ('i_2', 'i_3', 's_2', 's_3'):
        for sec in range(0, 4):

            inst = ccd + '_n_' + str(sec)


            date     = []
            year     = []
            month    = []
            mean_acc = []
            std_acc  = []
            min_acc  = []
            min_apos = []
            max_acc  = []
            max_apos = []
            m10_acc  = []
            m10_apos = []
            mean_dff = []
            std_dff  = []
            min_dff  = []
            min_dpos = []
            max_dff  = []
            max_dpos = []
            m10_dff  = []
            m10_dpos = []
        
            expf.readExpData(indir, inst, date, year,month,mean_acc,std_acc,min_acc,min_apos,  max_acc,max_apos,m10_acc, \
                      m10_apos,mean_dff,std_dff,min_dff, min_dpos,max_dff,max_dpos,m10_dff,m10_dpos)

#
#--- plot data
#
            plot_acis_dose(date, mean_dff, max_dff, m10_dff,  mean_acc, max_acc, m10_acc)

#
#--- move to the plot directory
#
            outfile = inst + '.gif'
            cmd = 'convert acis.png ' + plot_dir +  outfile
            os.system(cmd)
            os.system('rm acis.png')


#------------------------------------------------------------------------------------------------------------------------
#--- plot_acis_dose: plot 6 panels of hrc quantities.                                                                   --
#------------------------------------------------------------------------------------------------------------------------

def plot_acis_dose(date, dmean, dmax,d10, amean, amax, a10):

    'plot 6 panels of acis quantities. Input: date, diff, mean, max, 10th bright, acc, mean, max, 10th bright'

    plt.close('all')

#
#---- set a few parameters
#

    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=6)
    plt.subplots_adjust(hspace=0.05)
    plt.subplots_adjust(wspace=0.12)

#
#--- mean
#
    ax1 = plt.subplot(3,2,1)
    plot_panel(date, dmean, 'Average', ax1)
#
#--- mean cumulative
#
    ax2 = plt.subplot(3,2,2)
    plot_panel(date, amean, 'Average Cumulative', ax2)
#
#--- max
#
    ax3 = plt.subplot(3,2,3)
    plot_panel(date, dmax, 'Maximum', ax3)
#
#--- max cumulative
#
    ax4 = plt.subplot(3,2,4)
    plot_panel(date, amax, 'Maximum Cumulative', ax4)
#
#--- 10th brightest
#
    ax5 = plt.subplot(3,2,5)
    plot_panel(date, d10 , '10th Brightest', ax5)
#
#--- 10th brightest cumulative
#
    ax6 = plt.subplot(3,2,6)
    plot_panel(date, a10, '10th Brightest Cumulative', ax6)


#
#--- plot x axis tick label only at the bottom ones
#
    for ax in ax1, ax2, ax3, ax4, ax5, ax6:
        if ax != ax5 and ax != ax6:
            for label in ax.get_xticklabels():
                label.set_visible(False)
        else:
            pass

#
#--- putting axis names
#
        ax3.set_ylabel('Counts per Pixel')
        ax5.set_xlabel('Year')
        ax6.set_xlabel('Year')
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#   
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 8.0)
#
#--- save the plot in png format
#   
    plt.savefig('acis.png', format='png', dpi=100)

    plt.close('all')



#------------------------------------------------------------------------------------------------------------------------
#---   plot_panel: plotting each panel for a given "ax"                                                               ---
#------------------------------------------------------------------------------------------------------------------------

def plot_panel(x, y, label, ax, ymin = 'NA', ymax = 'NA'):

    'plotting each panel for a given "ax". Input: x, y, label, ax (designation of the plot), ymin ="NA" ymax = "NA". '

#
#--- x axis setting: here we assume that x is already sorted
#
    xmin = x[0]
    xmax = x[len(x) -1]
    diff = xmax - xmin
    xmin = xmin - 0.05 * diff
    xmax = xmax + 0.05 * diff
    xbot = xmin + 0.05 * diff
#
#--- y axis setting
#
    tymin = 1e8
    tymax = 1e-8
    for i in range(0, len(y)):
        if y[i] > tymax: 
            tymax = y[i]
        if y[i] < tymin:
            tymin = y[i]

    if ymin == 'NA':
        ymin = tymin

    if ymax == 'NA':
        ymax = tymax

#
#--- for the case,  ymin == ymax, 
#
    if ymin == ymax:
        ymax += 1

    diff = ymax - ymin
    ymin = ymin - 0.01 * diff

    if ymin < 0:
        ymin = 0

    ymax = ymax + 0.01 * diff
    ytop = ymax - 0.12 * diff

#
#--- setting panel 
#

    ax.set_autoscale_on(False)         #---- these three may not be needed for the new pylab, but 
    ax.set_xbound(xmin,xmax)           #---- they are necessary for the older version to set

    ax.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)

#
#--- plot line
#
    plt.plot(x, y, color='blue',   lw=1, marker='+', markersize=1.5)

    plt.text(xbot, ytop, label)







#--------------------------------------------------------------------------------------------------------

if __name__ == '__main__':

    acis_dose_plot_exposure_stat()
