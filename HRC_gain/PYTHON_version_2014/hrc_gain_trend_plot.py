#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################################################
#                                                                                                                                   #
#               hrc_gain_trend_plot.py: create time trend of Gaussian profiles fit on HRC PHA data                                  #
#                                                                                                                                   #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                                                           #
#                                                                                                                                   #
#               last update: May 13, 2014                                                                                           #
#                                                                                                                                   #
#####################################################################################################################################

import os
import sys
import re
import string
import random
import operator
import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

#
#--- reading directory list
#
path = '/data/mta/Script/HRC/Gain/house_keeping/dir_list_py'

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

#
#--- temp writing file name
#

rtail  = int(10000 * random.random())
zspace = '/tmp/zspace' + str(rtail)

#---------------------------------------------------------------------------------------------------
#-- hrc_gain_trend_plot: create time trend of Gaussian profiles fit on HRC PHA data              ---
#---------------------------------------------------------------------------------------------------

def hrc_gain_trend_plot():

    """
    create time trend of Gaussian profiles fit on HRC PHA data. It also create trend along radial distnace for each year
    Input:  none but the data is read from <house_keeping>/fitting_results
    Outut:  time trend plots in <plot_dir> / hrc_i_time_trend.png hrc_s_time_trend.png
            radial_distance plots            hrc_i_radial_dist_year<year>.png
    """

    file = house_keeping + 'fitting_results'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
#
#--- set a few things such as labeling
#
    yMinSets = [0, 0, 20]
    yMaxSets = [250, 250, 100]
    yname    = 'PHA'
    entLabels = ["PHA Median", "PHA Voigt Peak Position", "PHA FWHM"]
#
#--- time trend plots
#
    xmin  = 1999
    ctemp = tcnv.currentTime()          #--- finding this year
    xmax  = end_year =  int(ctemp[0]) + 1
    xname = 'Time (Year)'
#
#--- HRC I
#
    time_i   = []
    dist_i   = []
    med_i    = []
    center_i = []
    width_i  = []
    
    time_s   = []
    dist_s   = []
    med_s    = []
    center_s = []
    width_s  = []
    
    for ent in data:
        if ent[0] == '#':           #--- avoid comments
            continue

        atemp = re.split('\t+', ent)
#
#--- if the width is < 1 or amp is smaller than 5, probably it did not find a correct source position
#
        if float(atemp[12]) < 1:
            continue
        if float(atemp[11]) < 5:
            continue

        fyear = tcnv.sectoFracYear(float(atemp[2]))
        if atemp[3] == 'HRC-I':
            time_i.append(fyear)
            dist_i.append(float(atemp[8]))
            med_i.append(float(atemp[9]))
            center_i.append(float(atemp[10]))
            width_i.append(float(atemp[12]))
        else:
            time_s.append(fyear)
            dist_s.append(float(atemp[8]))
            med_s.append(float(atemp[9]))
            center_s.append(float(atemp[10]))
            width_s.append(float(atemp[12]))

    xSets    = [time_i, time_i, time_i]
    ySets    = [med_i, center_i, width_i]
    dist     = dist_indexing(dist_i)

    plotPanel(xmin, xmax, yMinSets, yMaxSets, xSets, ySets, dist,  xname, yname, entLabels)
    cmd = 'mv out.png ' + web_dir + 'Trend_plots/hrc_i_time_trend.png'
    os.system(cmd)
#
#--- HRC S
#
    xSets    = [time_s, time_s, time_s]
    ySets    = [med_s, center_s, width_s]
    dist     = dist_indexing(dist_s)

    plotPanel(xmin, xmax, yMinSets, yMaxSets, xSets, ySets, dist,  xname, yname, entLabels)
    cmd = 'mv out.png ' + web_dir + 'Trend_plots/hrc_s_time_trend.png'
    os.system(cmd)

#
#--- trend along radial distance
#
    xmin  = 0
    xmax  = 16
    xname = 'Radial Distance(Arcsec)'
#
#--- HRC I
#
    for pyear in range(1999, end_year):
        dist   = []
        med    = []
        center = []
        width  = []
        mark   = []
        pend = pyear + 1
        for j in range(0, len(time_i)):
            if  (time_i[j] >= pyear) and (time_i[j] < pend):
                dist.append(dist_i[j])
                med.append(med_i[j])
                center.append(center_i[j])
                width.append(width_i[j])

        xSets    = [dist, dist, dist]
        ySets    = [med, center, width]
        plotPanel(xmin, xmax, yMinSets, yMaxSets, xSets, ySets, mark,  xname, yname, entLabels, extraNote=pyear)

        outname = web_dir + '/Trend_plots/hrc_i_radial_dist_year' + str(pyear) + '.png'
        cmd     = 'mv out.png ' + outname
        os.system(cmd)
#
#--- HRC S
#
    for pyear in range(1999, end_year):
        dist   = []
        med    = []
        center = []
        width  = []
        mark   = [] 
        pend = pyear + 1
        for j in range(0, len(time_s)):
            if  (time_s[j] >= pyear) and (time_s[j] < pend):
                dist.append(dist_s[j])
                med.append(med_s[j])
                center.append(center_s[j])
                width.append(width_s[j])

        xSets    = [dist, dist, dist]
        ySets    = [med, center, width]
        plotPanel(xmin, xmax, yMinSets, yMaxSets, xSets, ySets, mark,  xname, yname, entLabels, extraNote=pyear)

        outname = web_dir + '/Trend_plots/hrc_s_radial_dist_year' + str(pyear) + '.png'
        cmd     = 'mv out.png ' + outname
        os.system(cmd)


#---------------------------------------------------------------------------------------------------
#-- dist_indexing: convert radial distance interval into index                                   ---
#---------------------------------------------------------------------------------------------------

def dist_indexing(dist):

    """
    convert radial distance interval into index
            dist < 5      ---> 0
            5< dist < 10 ----> 1
            10 < dist    ----> 2
    """
    dist_index = []
    for ent in dist:
        if ent < 5.0:
            dist_index.append(0)
        elif ent >= 10:
            dist_index.append(2)
        else:
            dist_index.append(1)

    return dist_index

#---------------------------------------------------------------------------------------------------
#--- plotPanel: plots multiple data in separate panels                                           ---
#---------------------------------------------------------------------------------------------------

def plotPanel(xmin, xmax, yMinSets, yMaxSets, xSets, ySets, dist,  xname, yname, entLabels, extraNote=''):

    """
    This function plots multiple data in separate panels
    Input:  xmin, xmax, ymin, ymax: plotting area
            yMinSets: a list of ymin 
            yMaxSets: a list of ymax
            xSets: a list of lists containing x-axis data
            ySets: a list of lists containing y-axis data
            dist:     category of the data, if the content is < 1, we don't categorize the data
            xname:    x axis name
            yname:    y axis name
            entLabels: a list of the names of each data
            extraNote: an extra Note you want to add

    Output: a png plot: out.png
    """
#
#--- set line color list
#
    colorList = ('blue', 'green', 'red', 'aqua', 'lime', 'fuchsia', 'maroon', 'black', 'yellow', 'olive')
#
#--- clean up the plotting device
#
    plt.close('all')
#
#---- set a few parameters
#
    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=9)
    plt.subplots_adjust(hspace=0.08)

    tot = len(entLabels)
#
#--- start plotting each data
#
    for i in range(0, len(entLabels)):
        axNam = 'ax' + str(i)
#
#--- setting the panel position
#
        j = i + 1
        if i == 0:
            line = str(tot) + '1' + str(j)
        else:
            line = str(tot) + '1' + str(j) + ', sharex=ax0'
            line = str(tot) + '1' + str(j)

        exec "%s = plt.subplot(%s)"       % (axNam, line)
        exec "%s.set_autoscale_on(False)" % (axNam)      #---- these three may not be needed for the new pylab, but 
        exec "%s.set_xbound(xmin,xmax)"   % (axNam)      #---- they are necessary for the older version to set

        exec "%s.set_xlim(xmin=xmin, xmax=xmax, auto=False)" % (axNam)
        exec "%s.set_ylim(ymin=yMinSets[i], ymax=yMaxSets[i], auto=False)" % (axNam)

        xdata  = xSets[i]
        ydata  = ySets[i]
        
        if len(dist) < 1:
#
#--- this is the case which we want to plot for each year along radial distance
#
            plt.plot(xdata,ydata, color=colorList[2], marker='o', markersize=3.0, lw =0)

            if i == 0:
                tx = xmax - 0.25 * (xmax-xmin)
                ty = yMaxSets[i] - 0.15 * (yMaxSets[i] - yMinSets[i])
                line = "Year " + str(extraNote)
                plt.text(tx,ty, line,size=12)
        else:
#
#--- this is the case that we want to separate data into three radial distance bins
#
            x1 = []
            x2 = []
            x3 = []
            y1 = []
            y2 = []
            y3 = []
            for k in range(0, len(dist)):
                if dist[k] == 0:
                    x1.append(xdata[k]-0.10)
                    y1.append(ydata[k])
                elif dist[k] == 1:
                    x2.append(xdata[k])
                    y2.append(ydata[k])
                else:
                    x3.append(xdata[k]+0.10)
                    y3.append(ydata[k])
#
#---- data plotting, add the label only on the first panel
#
            if i ==0:
                plt.plot(x1, y1, color=colorList[0], marker='+', markersize=4.0, lw =0, label='Distance < 5')
                plt.plot(x2, y2, color=colorList[2], marker='^', markersize=3.0, lw =0, label='5 < Distance < 10')
                plt.plot(x3, y3, color=colorList[1], marker='o', markersize=3.0, lw =0, label='10< Distance')
#
#--- add legend
#
                legend(loc='upper right', ncol=3)
            else:
                if i == 1:
                    ylabel(yname)

                plt.plot(x1, y1, color=colorList[0], marker='+', markersize=4.0, lw =0)
                plt.plot(x2, y2, color=colorList[2], marker='^', markersize=3.0, lw =0)
                plt.plot(x3, y3, color=colorList[1], marker='o', markersize=3.0, lw =0)

#
#--- name the panel
#
        tx = xmin + 0.05 * (xmax-xmin)
        ty = yMaxSets[i] - 0.15 * (yMaxSets[i] - yMinSets[i])
        plt.text(tx,ty, entLabels[i],size=12)
#
#--- add x ticks label only on the last panel
#
    for i in range(0, tot):
        ax = 'ax' + str(i)

        if i != tot-1: 
            exec "line = %s.get_xticklabels()" % (ax)
            for label in  line:
                label.set_visible(False)
        else:
            pass

    xlabel(xname)

#
#--- set the size of the plotting area in inch (width: 10.0in, height 2.08in x number of panels)
#
    fig = matplotlib.pyplot.gcf()
    height = (2.00 + 0.08) * tot
    fig.set_size_inches(10.0, height)
#
#--- save the plot in png format
#
    plt.savefig('out.png', format='png', dpi=100)


#--------------------------------------------------------------------

#
#--- pylab plotting routine related modules
#

from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

if __name__ == '__main__':
    hrc_gain_trend_plot()


