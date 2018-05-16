#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################################################
#                                                                                                                       #
#   acis_hist_plot_trend.py: plot acis histgram peak, width, and count rate trends                                      #
#                                                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                                   #
#                                                                                                                       #
#           last update: Apr 14, 2014                                                                                   #
#                                                                                                                       #
#########################################################################################################################

import sys
import os
import string
import re
import getpass
import fnmatch
import numpy
import getopt

#
#--- pylab plotting routine related modules
#
import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

#
#--- read argv
#
try:
    option, remainder = getopt.getopt(sys.argv[1:],'t',['test'])
except getopt.GetoptError as err:
     print str(err)
     sys.exit(2)


pass_test = ''
for opt, arg in option:
    if opt in ('-t', '--test'):
        pass_test = 'test'

#
#--- reading directory list
#

if pass_test == 'test':
    path = '/data/mta/Script/ACIS/Acis_hist/house_keeping/dir_list_test'
else:
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
#--- append path to a private folder
#

mta_dir = '/data/mta/Script/Python_script2.7'               #---- temporary until everything is moved to 2.7

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
#--  peak position y direction plotting range (x2 of pdelta)
#
pdelta = 70
#
#--  peak width y direction plotting range (x2 of wdelta)
#
wdelta = 70
#
#--- count rate y direction plotting range
#
count_ymin = 1.0e-4   
count_ymax = 0.07

#--------------------------------------------------------------------------------------------------------
#-- acis_hist_plot_trend: main function to plot trend of acis histgram data                            --
#--------------------------------------------------------------------------------------------------------

def acis_hist_plot_trend():

    '''
    main function to plot trend of acis histgram data
    input: none, this will read data from data_dir
    output: trend plots outputted in web_dir/Plot_trend/ directory
    '''

#
#--- initialize list
#
    for ccd in (1, 2, 3, 6, 7):
        for loc in ('low', 'high'):

            node0_data = readdata(ccd, 0, loc)
            node1_data = readdata(ccd, 1, loc)
            node2_data = readdata(ccd, 2, loc)
            node3_data = readdata(ccd, 3, loc)
#
#--- plot...
#
            plot_trend(node0_data, node1_data, node2_data, node3_data, ccd, loc)
#
#--- udate web page
#
    update_web_page()

#--------------------------------------------------------------------------------------------------------
#--- readdata: read trend data from database                                                          ---
#--------------------------------------------------------------------------------------------------------

def readdata(ccd, node, loc):

    '''
    read trend data from database
    input: ccd, node, and loc (low or high)
    output: a list of lists: [time, pos1, cnt1, width1, pos2, cnt2, width2, pos3, cnt3, width3]
    '''
#
#--- each frame takes 3.241 sec
#
    sec_per_frame = 3.2412

    file = data_dir + 'ccd' + str(ccd) + '_node' + str(node) + '_' + loc

    time   = []
    pos1   = []
    cnt1   = []
    width1 = []
    pos2   = []
    cnt2   = []
    width2 = []
    pos3   = []
    cnt3   = []
    width3 = []
    perr1  = []
    cerr1  = []
    werr1  = []
    perr2  = []
    cerr2  = []
    werr2  = []
    perr3  = []
    cerr3  = []
    werr3  = []
#
#-- check whether the data file exists... not all CCDs have the histgram data
#
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]

    for ent in data:
        atemp = re.split('\s+|t+', ent)
        btemp = re.split(':', atemp[0])
        ytime = float(btemp[0]) + float(btemp[1]) / 12.0
        duration = float(atemp[20])

        atemp[2]  = float(atemp[2])
        atemp[3]  = float(atemp[3])
        atemp[4]  = float(atemp[4])
        atemp[5]  = float(atemp[5])
        atemp[6]  = float(atemp[6])  * 2.354             #--- changing sigma to FWHM
        atemp[7]  = float(atemp[7])
        atemp[8]  = float(atemp[8])
        atemp[9]  = float(atemp[9])
        atemp[10] = float(atemp[10])
        atemp[11] = float(atemp[11])
        atemp[12] = float(atemp[12]) * 2.354
        atemp[13] = float(atemp[13])
        atemp[14] = float(atemp[14])
        atemp[15] = float(atemp[15])
        atemp[16] = float(atemp[16]) 
        atemp[17] = float(atemp[17])
        atemp[18] = float(atemp[18]) * 2.354
        atemp[19] = float(atemp[19])

        chk = 0
        for i in range(2,20):
            if atemp[i] <= 0:
                chk = 1
                continue
            if atemp[i] > 1e5:
                chk = 1
                continue
        if chk == 1:
            continue

        time.append(ytime)

        pos1.append(atemp[2])
        perr1.append(atemp[3])
        cnt1.append(atemp[4] / duration)
        cerr1.append(atemp[5] / duration)
        width1.append(atemp[6])
        werr1.append(atemp[7])

        pos2.append(atemp[8])
        perr2.append(atemp[9])
        cnt2.append(atemp[10] / duration)
        cerr2.append(atemp[11] / duration)
        width2.append(atemp[12])
        werr2.append(atemp[13])

        pos3.append(atemp[14])
        perr3.append(atemp[15])
        cnt3.append(atemp[16] / duration)
        cerr3.append(atemp[17] / duration)
        width3.append(atemp[18])
        werr3.append(atemp[19])

    out1 = [time, pos1, cnt1, width1, pos2, cnt2, width2, pos3, cnt3, width3]
    out2 = [perr1, cerr1, werr1, perr2, cerr2, werr2, perr3, cerr3, werr3]
    out  = out1 + out2
    return out
        
#--------------------------------------------------------------------------------------------------------
#-- convert_ytime: change time fromat from in second from 1.1.1998 to time in unit of fractional year  --
#--------------------------------------------------------------------------------------------------------

def convert_ytime(time):

    '''
    change time fromat from in second from 1.1.1998 to time in unit of fractional year
    input time in: seconds from 1.1.1998
    output time in : fractional year, e.g., 2011.1213
    '''

    atime = tcnv.convertCtimeToYdate(time)
    btemp = re.split(':', atime)
    year  = float(btemp[0])
    ydate = float(btemp[1])
    hour  = float(btemp[2])
    mins  = float(btemp[3])
    sec   = float(btemp[4])

    chk   = 4.0 * int(0.25 * year)
    if chk == year:
        base = 366.0
    else:
        base = 365.0

    ydate  = ydate + (hour/24.0 + mins/1440.0 + sec/86400.0)
    frac   = ydate/base

    ytime  = year + frac

    return ytime
    
#--------------------------------------------------------------------------------------------------------
#--- plot_trend: plotting the indivisual trend plot                                                   ---
#--------------------------------------------------------------------------------------------------------

def plot_trend(node_0_data, node_1_data, node_2_data, node_3_data, ccd, loc):
    '''
     plotting the indivisual trend plot 
     input: lists of time, pos, cnt, width for each node: node_0_data, node_1_data, node_2_data, node_3_data
            ccd and loc (low and high)
    output: a trend plot in web_dir/Plot_trend/
    '''

    [n0_time, n0_pos1, n0_cnt1, n0_width1, n0_pos2, n0_cnt2, n0_width2, n0_pos3, n0_cnt3, n0_width3] = node_0_data[:10]
    [n1_time, n1_pos1, n1_cnt1, n1_width1, n1_pos2, n1_cnt2, n1_width2, n1_pos3, n1_cnt3, n1_width3] = node_1_data[:10]
    [n2_time, n2_pos1, n2_cnt1, n2_width1, n2_pos2, n2_cnt2, n2_width2, n2_pos3, n2_cnt3, n2_width3] = node_2_data[:10]
    [n3_time, n3_pos1, n3_cnt1, n3_width1, n3_pos2, n3_cnt2, n3_width2, n3_pos3, n3_cnt3, n3_width3] = node_3_data[:10]
    
    [n0_perr1, n0_cerr1, n0_werr1, n0_perr2, n0_cerr2, n0_werr2, n0_perr3, n0_cerr3, n0_werr3]       = node_0_data[10:]
    [n1_perr1, n1_cerr1, n1_werr1, n1_perr2, n1_cerr2, n1_werr2, n1_perr3, n1_cerr3, n1_werr3]       = node_1_data[10:]
    [n2_perr1, n2_cerr1, n2_werr1, n2_perr2, n2_cerr2, n2_werr2, n2_perr3, n2_cerr3, n2_werr3]       = node_2_data[10:]
    [n3_perr1, n3_cerr1, n3_werr1, n3_perr2, n3_cerr2, n3_werr2, n3_perr3, n3_cerr3, n3_werr3]       = node_3_data[10:]


#
#-- find today date to set x axis range
#
    [year, mon, day, hours, mins, sec, weekday, yday, dst] = tcnv.currentTime()
    if pass_test == 'test':
        xmin = 2012
        xmax = 2013
    else:
        xmin = 2000
        xmax = int(year) + 1
#
#--- if the year is more than a half past, add another a year to the x axis plotting range
#
    if yday > 180:
        xmax += 1


    xdiff = xmax - xmin
    xtext = xmin + 0.1 * xdiff

#
#------------------- plotting peak position trend ------------------------------
#

#
#---- setting a few parameters for plotting
#
    plt.close('all')
    mpl.rcParams['font.size'] =12 
    props = font_manager.FontProperties(size=12)
    plt.subplots_adjust(hspace=0.08)

#
#--- Al K alpha
#
    paramsinitial_p = (360, -0.03) 
    n0_result_2p = fit_line(paramsinitial_p, n0_time, n0_pos2, n0_perr2, 'linear')
    n1_result_2p = fit_line(paramsinitial_p, n1_time, n1_pos2, n1_perr2, 'linear')
    n2_result_2p = fit_line(paramsinitial_p, n2_time, n2_pos2, n2_perr2, 'linear')
    n3_result_2p = fit_line(paramsinitial_p, n3_time, n3_pos2, n3_perr2, 'linear')

    [ymin , ymax, avg] = set_min_max(n0_pos2, n1_pos2, n2_pos2, n3_pos2)
    ymin = int(avg - pdelta)
    ymax = int(avg + pdelta)

    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax1 = plt.subplot(3,1,1)

    plt.text(xtext, ytext, 'Al K-alpha')

    led1 = plot_panel(ax1, xmin, xmax, ymin, ymax, n0_time, n0_pos2, n0_perr2, n0_result_2p,   'linear', 'blue', 's')
    led2 = plot_panel(ax1, xmin, xmax, ymin, ymax, n1_time, n1_pos2, n1_perr2, n1_result_2p,   'linear', 'red', 'x')
    led3 = plot_panel(ax1, xmin, xmax, ymin, ymax, n2_time, n2_pos2, n2_perr2, n2_result_2p,   'linear', 'green','^')
    led4 = plot_panel(ax1, xmin, xmax, ymin, ymax, n3_time, n3_pos2, n3_perr2, n3_result_2p,   'linear', '#99FF00', 'o')

    legend([led1,led2,led3,led4], ['Node0', 'Node1', 'Node2', 'Node3'], loc=1, ncol=4, borderaxespad=0.)


#
#--- Ti K alpha
#
    paramsinitial_p = (980, -0.03) 
    n0_result_3p = fit_line(paramsinitial_p, n0_time, n0_pos3, n0_perr3, 'linear')
    n1_result_3p = fit_line(paramsinitial_p, n1_time, n1_pos3, n1_perr3, 'linear')
    n2_result_3p = fit_line(paramsinitial_p, n2_time, n2_pos3, n2_perr3, 'linear')
    n3_result_3p = fit_line(paramsinitial_p, n3_time, n3_pos3, n3_perr3, 'linear')

    [ymin , ymax,avg] = set_min_max(n0_pos3, n1_pos3, n2_pos3, n3_pos3)
    ymin = int(avg - pdelta)
    ymax = int(avg + pdelta)

    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax2 = plt.subplot(3,1,2)

    plt.text(xtext, ytext, 'Ti K-alpha')

    plot_panel(ax2, xmin, xmax, ymin, ymax, n0_time, n0_pos3, n0_perr3, n0_result_3p,   'linear', 'blue', 's')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n1_time, n1_pos3, n1_perr3, n1_result_3p,   'linear', 'red', 'x')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n2_time, n2_pos3, n2_perr3, n2_result_3p,   'linear', 'green','^')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n3_time, n3_pos3, n3_perr3, n3_result_3p,   'linear', '#99FF00', 'o')

    ax2.set_ylabel("ADU")
#
#---- Mn K alpha
#
    paramsinitial_p = (1300, -0.03) 
    n0_result_1p = fit_line(paramsinitial_p, n0_time, n0_pos1, n0_perr1, 'linear')
    n1_result_1p = fit_line(paramsinitial_p, n1_time, n1_pos1, n1_perr1, 'linear')
    n2_result_1p = fit_line(paramsinitial_p, n2_time, n2_pos1, n2_perr1, 'linear')
    n3_result_1p = fit_line(paramsinitial_p, n3_time, n3_pos1, n3_perr1, 'linear')

    [ymin , ymax, avg] = set_min_max(n0_pos1, n1_pos1, n2_pos1, n3_pos1)
    ymin = int(avg - pdelta)
    ymax = int(avg + pdelta)
    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax3 = plt.subplot(3,1,3)
    plt.text(xtext, ytext, 'Mn K-alpha')

    plot_panel(ax3, xmin, xmax, ymin, ymax, n0_time, n0_pos1, n0_perr1, n0_result_1p,   'linear', 'blue', 's')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n1_time, n1_pos1, n1_perr1, n1_result_1p,   'linear', 'red', 'x')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n2_time, n2_pos1, n2_perr1, n2_result_1p,   'linear', 'green','^')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n3_time, n3_pos1, n3_perr1, n3_result_1p,   'linear', '#99FF00','o')


#
#--- label x axis
#
    xlabel("Time (Year)")
#
#---- plot x axis tick label only at the third panel
#
    for ax in ax1, ax2, ax3:
        if ax != ax3:
            for label in ax.get_xticklabels():
                label.set_visible(False)
        else:
            pass
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(15.0, 10.0)
#
#--- save the plot in png format
#
    out_name = web_dir + 'Plot_trend/CCD' + str(ccd) + '/peak_position_' + loc + '_trend.png'
    plt.savefig(out_name, format='png', dpi=100)

    plt.close('all')


#
#--- print out fitting results
#
    out_name = web_dir + 'Plot_trend/ccd' + str(ccd) + '_' + str(loc) + '_fitting_data'
    fout     = open(out_name, 'w')

    line = 'CCD' + str(ccd) + ': Line Center Position Mn K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'mn', 0, n0_result_1p)
    print_out_fit_result(fout, loc, 'mn', 1, n1_result_1p)
    print_out_fit_result(fout, loc, 'mn', 2, n2_result_1p)
    print_out_fit_result(fout, loc, 'mn', 3, n3_result_1p)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Line Center Position Al K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'al', 0, n0_result_2p)
    print_out_fit_result(fout, loc, 'al', 1, n1_result_2p)
    print_out_fit_result(fout, loc, 'al', 2, n2_result_2p)
    print_out_fit_result(fout, loc, 'al', 3, n3_result_2p)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Line Center Position Ti K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'ti', 0, n0_result_3p)
    print_out_fit_result(fout, loc, 'ti', 1, n1_result_3p)
    print_out_fit_result(fout, loc, 'ti', 2, n2_result_3p)
    print_out_fit_result(fout, loc, 'ti', 3, n3_result_3p)

    fout.write('\n\n')

    fout.write('#---------------------------------------------------------------------\n')
    fout.write('#---------------------------------------------------------------------\n')
#
#------------------- plotting peak width trend ------------------------------
#

#
#---- setting a few parameters for plotting
#
    plt.close('all')
    mpl.rcParams['font.size'] =12 
    props = font_manager.FontProperties(size=12)
    plt.subplots_adjust(hspace=0.08)

#
#--- Al K alpha
#
    paramsinitial_w = (20, -0.03) 
    n0_result_2w = fit_line(paramsinitial_w, n0_time, n0_width2, n0_werr2, 'linear')
    n1_result_2w = fit_line(paramsinitial_w, n1_time, n1_width2, n1_werr2, 'linear')
    n2_result_2w = fit_line(paramsinitial_w, n2_time, n2_width2, n2_werr2, 'linear')
    n3_result_2w = fit_line(paramsinitial_w, n3_time, n3_width2, n3_werr2, 'linear')

    [ymin , ymax, avg] = set_min_max(n0_width2, n1_width2, n2_width2, n3_width2)
    ymax = int(avg + wdelta)
    ymin = int(avg - wdelta)
    if ymin < 0:
        ymax -= ymin
        ymin = 0

    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax1 = plt.subplot(3,1,1)

    plt.text(xtext, ytext, 'Al K-alpha')

    led1 = plot_panel(ax1, xmin, xmax, ymin, ymax, n0_time, n0_width2, n0_werr2, n0_result_2w, 'linear', 'blue', 's')
    led2 = plot_panel(ax1, xmin, xmax, ymin, ymax, n1_time, n1_width2, n1_werr2, n1_result_2w, 'linear', 'red', 'x')
    led3 = plot_panel(ax1, xmin, xmax, ymin, ymax, n2_time, n2_width2, n2_werr2, n2_result_2w, 'linear', 'green', '^')
    led4 = plot_panel(ax1, xmin, xmax, ymin, ymax, n3_time, n3_width2, n3_werr2, n3_result_2w, 'linear', '#99FF00', 'o')

    legend([led1,led2,led3,led4], ['Node0', 'Node1', 'Node2', 'Node3'], loc=1, ncol=4, borderaxespad=0.)

#
#--- Ti K alpha
#
    paramsinitial_w = (30, -0.03) 
    n0_result_3w = fit_line(paramsinitial_w, n0_time, n0_width3, n0_werr3, 'linear')
    n1_result_3w = fit_line(paramsinitial_w, n1_time, n1_width3, n1_werr3, 'linear')
    n2_result_3w = fit_line(paramsinitial_w, n2_time, n2_width3, n2_werr3, 'linear')
    n3_result_3w = fit_line(paramsinitial_w, n3_time, n3_width3, n3_werr3, 'linear')

    [ymin , ymax, avg] = set_min_max(n0_width3, n1_width3, n2_width1, n3_width3)
    ymax = int(avg + wdelta)
    ymin = int(avg - wdelta)
    if ymin < 0:
        ymax -= ymin
        ymin = 0

    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax2 = plt.subplot(3,1,2)

    plt.text(xtext, ytext, 'Ti K-alpha')

    plot_panel(ax2, xmin, xmax, ymin, ymax, n0_time, n0_width3, n0_werr3, n0_result_3w, 'linear', 'blue', 's')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n1_time, n1_width3, n1_werr3, n1_result_3w, 'linear', 'red', 'x')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n2_time, n2_width3, n2_werr3, n2_result_3w, 'linear', 'green', '^')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n3_time, n3_width3, n3_werr3, n3_result_3w, 'linear', '#99FF00', 'o')

    ax2.set_ylabel("ADU")
#
#---- Mn K alpha
#
#
#--- set initial guess for the line fitting
#
    paramsinitial_w = (40, -0.03) 
    n0_result_1w = fit_line(paramsinitial_w, n0_time, n0_width1, n0_werr1, 'linear')
    n1_result_1w = fit_line(paramsinitial_w, n1_time, n1_width1, n1_werr1, 'linear')
    n2_result_1w = fit_line(paramsinitial_w, n2_time, n2_width1, n2_werr1, 'linear')
    n3_result_1w = fit_line(paramsinitial_w, n3_time, n3_width1, n3_werr1, 'linear')
#
#--- set y plotting range
#
    [ymin , ymax, avg] = set_min_max(n0_width1, n1_width1, n2_width1, n3_width1)
    ymax = int(avg + wdelta)
    ymin = int(avg - wdelta)
    if ymin < 0:
        ymax -= ymin
        ymin = 0
    
    ydiff = ymax - ymin
    ytext = ymax - 0.1 * ydiff

    ax3 = plt.subplot(3,1,3)

    plt.text(xtext, ytext, 'Mn K-alpha')

    plot_panel(ax3, xmin, xmax, ymin, ymax, n0_time, n0_width1, n0_werr1, n0_result_1w, 'linear', 'blue', 's')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n1_time, n1_width1, n1_werr1, n1_result_1w, 'linear', 'red', 'x')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n2_time, n2_width1, n2_werr1, n2_result_1w, 'linear', 'green', '^')
    plot_panel(ax3, xmin, xmax, ymin, ymax, n3_time, n3_width1, n3_werr1, n3_result_1w, 'linear', '#99FF00','o')

#
#--- label x axis
#
    xlabel("Time (Year)")
#
#---- plot x axis tick label only at the third panel
#
    for ax in ax1, ax2, ax3:
        if ax != ax3:
            for label in ax.get_xticklabels():
                label.set_visible(False)
        else:
            pass
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(15.0, 10.0)
#
#--- save the plot in png format
#
    out_name = web_dir + 'Plot_trend/CCD' + str(ccd) + '/peak_width_' + loc + '_trend.png'
    plt.savefig(out_name, format='png', dpi=100)

    plt.close('all')

#
#--- print out fitting data
#

    fout.write('\n')
    line = 'CCD' + str(ccd) + ': Line Width Mn K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'mn', 0, n0_result_1w)
    print_out_fit_result(fout, loc, 'mn', 1, n1_result_1w)
    print_out_fit_result(fout, loc, 'mn', 2, n2_result_1w)
    print_out_fit_result(fout, loc, 'mn', 3, n3_result_1w)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Line Width  Al K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'al', 0, n0_result_2w)
    print_out_fit_result(fout, loc, 'al', 1, n1_result_2w)
    print_out_fit_result(fout, loc, 'al', 2, n2_result_2w)
    print_out_fit_result(fout, loc, 'al', 3, n3_result_2w)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Line Width Ti K-alpha  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = int + slope * Time (in year)\n')
    fout.write('node    rows        element     intersect   slope\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'ti', 0, n0_result_3w)
    print_out_fit_result(fout, loc, 'ti', 1, n1_result_3w)
    print_out_fit_result(fout, loc, 'ti', 2, n2_result_3w)
    print_out_fit_result(fout, loc, 'ti', 3, n3_result_3w)

    fout.write('\n\n')

    fout.write('#---------------------------------------------------------------------\n')
    fout.write('#---------------------------------------------------------------------\n')

#
#------------------- plotting count rate trend ------------------------------
#

#
#---- setting a few parameters for plotting
#
    plt.close('all')
    mpl.rcParams['font.size'] =12 
    props = font_manager.FontProperties(size=12)
    plt.subplots_adjust(hspace=0.08)
#
#--- setting plotting range
#
    ymin = count_ymin
    ymax = count_ymax

    ydiff = ymax - ymin
    ytext = ymax - 0.4 * ydiff
#
#--- moving the origin to 2000 to 0
#
    n0_t    = map(lambda x: x-2000, n0_time)
    n1_t    = map(lambda x: x-2000, n1_time)
    n2_t    = map(lambda x: x-2000, n2_time)
    n3_t    = map(lambda x: x-2000, n3_time)
#
#---- Al K alpha
#
    ln0_cnt = map(lambda x: log(x), n0_cnt2)
    ln1_cnt = map(lambda x: log(x), n1_cnt2)
    ln2_cnt = map(lambda x: log(x), n2_cnt2)
    ln3_cnt = map(lambda x: log(x), n3_cnt2)

    ln0_err = numpy.ones(len(ln0_cnt))
    ln1_err = numpy.ones(len(ln1_cnt))
    ln2_err = numpy.ones(len(ln2_cnt))
    ln3_err = numpy.ones(len(ln3_cnt))

    paramsinitial_c = (-3.0,   -0.05)
    n0_result_2c = fit_line(paramsinitial_c, n0_t, ln0_cnt, ln0_err, 'linear')
    n1_result_2c = fit_line(paramsinitial_c, n1_t, ln1_cnt, ln1_err, 'linear')
    n2_result_2c = fit_line(paramsinitial_c, n2_t, ln2_cnt, ln2_err, 'linear')
    n3_result_2c = fit_line(paramsinitial_c, n3_t, ln3_cnt, ln3_err, 'linear')

    a1, a2 = n0_result_2c
    n0_result_2c = [exp(a1), -1.0 * a2]
    a1, a2 = n1_result_2c
    n1_result_2c = [exp(a1), -1.0 * a2]
    a1, a2 = n2_result_2c
    n2_result_2c = [exp(a1), -1.0 * a2]
    a1, a2 = n3_result_2c
    n3_result_2c = [exp(a1), -1.0 * a2]
 
    ax1 = plt.subplot(3,1,1)

    plt.text(xtext, ytext, 'Al K-alpha')

    led1 = plot_panel(ax1, xmin, xmax,  ymin, ymax, n0_t, n0_cnt2, n0_cerr2, n0_result_2c,   'exp',   'blue', 's')
    led2 = plot_panel(ax1, xmin, xmax,  ymin, ymax, n1_t, n1_cnt2, n1_cerr2, n1_result_2c,   'exp',   'red', 'x')
    led3 = plot_panel(ax1, xmin, xmax,  ymin, ymax, n2_t, n2_cnt2, n2_cerr2, n2_result_2c,   'exp',   'green', '^')
    led4 = plot_panel(ax1, xmin, xmax,  ymin, ymax, n3_t, n3_cnt2, n3_cerr2, n3_result_2c,   'exp',   '#99FF00', 'o')

    legend([led1,led2,led3,led4], ['Node0', 'Node1', 'Node2', 'Node3'], loc=1, ncol=4, borderaxespad=0.)

#
#---- Ti K alpha
#

    ln0_cnt = map(lambda x: log(x), n0_cnt3)
    ln1_cnt = map(lambda x: log(x), n1_cnt3)
    ln2_cnt = map(lambda x: log(x), n2_cnt3)
    ln3_cnt = map(lambda x: log(x), n3_cnt3)

    paramsinitial_c = (-3.0,   -0.05)
    n0_result_3c = fit_line(paramsinitial_c, n0_t, ln0_cnt, ln0_err, 'linear')
    n1_result_3c = fit_line(paramsinitial_c, n1_t, ln1_cnt, ln1_err, 'linear')
    n2_result_3c = fit_line(paramsinitial_c, n2_t, ln2_cnt, ln2_err, 'linear')
    n3_result_3c = fit_line(paramsinitial_c, n3_t, ln3_cnt, ln3_err, 'linear')

    a1, a2 = n0_result_3c
    n0_result_3c = [exp(a1), -1.0 * a2]
    a1, a2 = n1_result_3c
    n1_result_3c = [exp(a1), -1.0 * a2]
    a1, a2 = n2_result_3c
    n2_result_3c = [exp(a1), -1.0 * a2]
    a1, a2 = n3_result_3c
    n3_result_3c = [exp(a1), -1.0 * a2]
 
    ax2 = plt.subplot(3,1,2)

    plt.text(xtext, ytext, 'Ti K-alpha')

    plot_panel(ax2, xmin, xmax, ymin, ymax, n0_t, n0_cnt3, n0_cerr3, n0_result_3c,   'exp',   'blue','s')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n1_t, n1_cnt3, n1_cerr3, n1_result_3c,   'exp',   'red', 'x')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n2_t, n2_cnt3, n2_cerr3, n2_result_3c,   'exp',   'green','^')
    plot_panel(ax2, xmin, xmax, ymin, ymax, n3_t, n3_cnt3, n3_cerr3, n3_result_3c,   'exp',   '#99FF00','o')

    ax2.set_ylabel("Log(Counts/Sec)")
#
#---- Mn K alpha
#

#
#--- take log of y value so that we can use linear fit
#
    ln0_cnt = map(lambda x: log(x), n0_cnt1)
    ln1_cnt = map(lambda x: log(x), n1_cnt1)
    ln2_cnt = map(lambda x: log(x), n2_cnt1)
    ln3_cnt = map(lambda x: log(x), n3_cnt1)
#
#--- set initial guess for the line fitting
#
    paramsinitial_c = (-3.0,   -0.05)
    n0_result_1c = fit_line(paramsinitial_c, n0_t, ln0_cnt, ln0_err, 'linear')
    n1_result_1c = fit_line(paramsinitial_c, n1_t, ln1_cnt, ln1_err, 'linear')
    n2_result_1c = fit_line(paramsinitial_c, n2_t, ln2_cnt, ln2_err, 'linear')
    n3_result_1c = fit_line(paramsinitial_c, n3_t, ln3_cnt, ln3_err, 'linear')

    a1, a2 = n0_result_1c
    n0_result_1c = [exp(a1), -1.0 * a2]
    a1, a2 = n1_result_1c
    n1_result_1c = [exp(a1), -1.0 * a2]
    a1, a2 = n2_result_1c
    n2_result_1c = [exp(a1), -1.0 * a2]
    a1, a2 = n3_result_1c
    n3_result_1c = [exp(a1), -1.0 * a2]

    ax3 = plt.subplot(3,1,3)

    plt.text(xtext, ytext, 'Mn K-alpha')

    plot_panel(ax3, xmin, xmax,  ymin, ymax, n0_t, n0_cnt1, n0_cerr1, n0_result_1c,   'exp',   'blue', 's')
    plot_panel(ax3, xmin, xmax,  ymin, ymax, n1_t, n1_cnt1, n1_cerr1, n1_result_1c,   'exp',   'red', 'x')
    plot_panel(ax3, xmin, xmax,  ymin, ymax, n2_t, n2_cnt1, n2_cerr1, n2_result_1c,   'exp',   'green', '^')
    plot_panel(ax3, xmin, xmax,  ymin, ymax, n3_t, n3_cnt1, n3_cerr1, n3_result_1c,   'exp',   '#99FF00', 'o')


#
#--- label x axis
#
    xlabel("Time (Year)")
#
#---- plot x axis tick label only at the third panel
#
    for ax in ax1, ax2, ax3:
        if ax != ax3:
            for label in ax.get_xticklabels():
                label.set_visible(False)
        else:
            pass
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(15.0, 10.0)
#
#--- save the plot in png format
#
    out_name = web_dir + 'Plot_trend/CCD' + str(ccd) + '/count_rate_' + loc + '_trend.png'
    plt.savefig(out_name, format='png', dpi=100)

    plt.close('all')

#
#--- print out fitting data
#

    fout.write('\n')
    line = 'CCD' + str(ccd) + ': Count Rate Mn K-alpha (set Year 2000 to 0)  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = const1 * exp*(-1 * const2 *Time (in year))\n')
    fout.write('node    rows        element     const1   const2\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'mn', 0, n0_result_1c)
    print_out_fit_result(fout, loc, 'mn', 1, n1_result_1c)
    print_out_fit_result(fout, loc, 'mn', 2, n2_result_1c)
    print_out_fit_result(fout, loc, 'mn', 3, n3_result_1c)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Count Rate  Al K-alpha (set Year 2000 to 0)\n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = const1 * exp*(-1 * const2 *Time (in year))\n')
    fout.write('node    rows        element     const1   const2\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'al', 0, n0_result_2c)
    print_out_fit_result(fout, loc, 'al', 1, n1_result_2c)
    print_out_fit_result(fout, loc, 'al', 2, n2_result_2c)
    print_out_fit_result(fout, loc, 'al', 3, n3_result_2c)

    fout.write('\n\n')

    line = 'CCD' + str(ccd) + ': Count Rate Ti K-alpha (set Year 2000 to 0)  \n'
    fout.write(line)
    fout.write('#\n')
    fout.write('y = const1 * exp*(-1 * const2 *Time (in year))\n')
    fout.write('node    rows        element     const1   const2\n')
    fout.write('#---------------------------------------------------------------------\n')
    
    print_out_fit_result(fout, loc, 'ti', 0, n0_result_3c)
    print_out_fit_result(fout, loc, 'ti', 1, n1_result_3c)
    print_out_fit_result(fout, loc, 'ti', 2, n2_result_3c)
    print_out_fit_result(fout, loc, 'ti', 3, n3_result_3c)

    fout.write('\n\n')

    fout.close()

#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------

def set_min_max(p1, p2, p3, p4):

    merged_list = p1 + p2 + p3 + p4
    sorted_list = sorted(merged_list)
    clipped_list = sorted_list[5:len(sorted_list)-5]
    avg  = mean(clipped_list)
    stdp = std(clipped_list)
    maxp = avg + 3.0 * stdp
    minp = avg - 3.0 * stdp
    diff = maxp - minp
    maxp = int(maxp + 0.1 * diff) 
    minp = int(minp - 0.1 * diff) 
    if minp < 0:
        minp = 0

    return [minp, maxp, avg]

#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

def plot_panel(ax, xmin, xmax, ymin, ymax, x, y, err, param, type, color, fmt):
#
#--- setting params
#
    ax.set_autoscale_on(False)         #---- these three may not be needed for the new pylab, but 
    ax.set_xbound(xmin,xmax)           #---- they are necessary for the older version to set

    ax.set_xlim(xmin=int(xmin), xmax=int(xmax), auto=False)
    ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)

    if type == 'linear':
        l_ind, = plt.plot(x, y, color=color, lw=0, marker=fmt, markersize=4.0)
        errorbar(x, y, yerr=err, color=color,  markersize=4.0, fmt=fmt)
    else:
        xs   = map(lambda x: x+2000.0,  x)
        l_ind, = plt.semilogy(xs, y, color=color, lw=0, marker=fmt, markersize=4.0)
        ax.set_yscale("log", nonposy='clip')
        errorbar(x, y, yerr=err, color=color,  markersize=4.0, fmt=fmt)
#
#--- model 
#
    if type == 'linear':
        [xval, yval] = fit_model(param, xmin, xmax, type)
    else:
        [xval, yval] = fit_model(param, xmin-2000, xmax-2000, type)
        xval = map(lambda x: x+2000.0,  xval)


#
#--- plotting model
#
    if type == 'exp':
        ax.set_yscale("log", nonposy='clip')

    plt.plot(xval, yval,  color=color,  lw=1)

    return l_ind


#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

def fit_model(param, xmin, xmax, type):
    xval = []
    yval = []
    step = (xmax - xmin)/ 100.0
    for i in range(1, 100):
        xpos = xmin + step * i
        xval.append(xpos)

        if type == 'linear':
            yest = linear_fit(param, xpos)
            yval.append(yest)
        else:
            yest = exp_fit(param, xpos)
            yval.append(yest)

    return [xval, yval]



#--------------------------------------------------------------------------------------------------------
#----fit_line: kmpfit calling function to fit the lines on data                                       ---
#--------------------------------------------------------------------------------------------------------
    
def fit_line(paramsinit, x, y, err, type):

    '''
    kmpfit calling function to fit the lines on data
    input: paramsinit: initial guess for the parameters
           x, y: data
           type: linear or exp:
    output: two parameters (a, b) are returned
    '''

    sx = []
    sy = []
    se = []
    avg  = mean(y)
    stdp = std(y)
    bot  = avg - 3.0 * stdp
    top  = avg + 3.0 * stdp
    i    = 0
    for val in y:
        if (val >= bot) and (val <= top):
            sx.append(x[i])
            sy.append(y[i])
            se.append(err[i])
        i += 1
#
#--- make sure that the arrays are numpyed
#
    d = numpy.array(sx)
    v = numpy.array(sy)
    e = numpy.array(se)

    if type == 'linear':
#
#--- linear fit
#
        fitobj = kmpfit.Fitter(residuals=linear_res, data=(d, v, e))
        fitobj.fit(params0 = paramsinit)
    else:
#
#--- exp fit
#
        fitobj = kmpfit.Fitter(residuals=exp_res, data=(d, v, e))
        fitobj.fit(params0 = paramsinit)

    return fitobj.params
    

#--------------------------------------------------------------------------------------------------------
#---linear_fit: linear model fit                                                                      ---
#--------------------------------------------------------------------------------------------------------

def linear_fit(param, x):

    '''
    linear model fit
    input: param: (a,b)
    x     independent val
    ouptput: estimate
    '''

    a, b = param

    return (a + b * x)

#--------------------------------------------------------------------------------------------------------
#-- linear_res: linear model resitual                                                                 ---
#--------------------------------------------------------------------------------------------------------

def linear_res(param, data):

    '''
     linear model resitual
     input: param (a, b)
            data  (x, y)
     output: residual
    '''

    a, b    = param
    x, y, e = data

    res =  y - (a + b * x)
    return res

#--------------------------------------------------------------------------------------------------------
#-- exp_fit: exponential model                                                                        ---
#--------------------------------------------------------------------------------------------------------

def exp_fit(param, x):

    '''
    exponential model
    input: param (a, b)
           x      independent variable
    output: estimate
    '''
    
    a, b = param

    return  (a * exp(-1.0 * b * x))

#--------------------------------------------------------------------------------------------------------
#-- exp_res: exponential model residual                                                                --
#--------------------------------------------------------------------------------------------------------

def exp_res(param, data):

    '''
    exponential model residual
    input param(a, b)
          data (x, y)
    output: residual
    '''

    a, b    = param
    x, y, e = data

    res = y - (a * exp(-1.0 * b * x))
    return res


#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

def print_out_fit_result(fout, loc, elm, node, fit_results):

    if loc == 'low':
        lpos = '21- 221'
    else:
        lpos = '801 - 1001'

    a1, a2 = fit_results
    b1 = '%.4f' % float(a1)
    b2 = '%.4f' % float(a2)
    line = str(node) + '\t\t' + lpos + '\t\t\t' + elm + '\t\t' + str(b1) + '\t' + str(b2) + '\n'
    fout.write(line)


#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

def update_web_page():

    ldate = tcnv.currentTime('Display')

    path = house_keeping + 'acis_hist_main.html'
    data = open(path, 'r').read()
    data = data.replace("#DATE#", ldate)
    
    outfile = web_dir + 'acis_hist_main.html'
    fout = open(outfile, 'w')
    fout.write(data)
    fout.close();

#--------------------------------------------------------------------------------------------------------

from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

if __name__ == '__main__':

    acis_hist_plot_trend()
