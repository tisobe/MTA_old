#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################################
#                                                                                                       #
#       compute_xmm_stat_plot_for_report.py: read xmm data, compute statistics and plot the data        #
#                                                                                                       #
#           author: t. isobe    (tisobe@cfa.harvard.edu)                                                #
#                                                                                                       #
#           last update:    May 27, 2015                                                                #
#                                                                                                       #
#########################################################################################################

import os
import sys
import re
import string
import random
import operator
import math
import numpy
import unittest


import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

from pylab import *
import matplotlib.pyplot       as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines        as lines


path = '/data/mta/Script/Interrupt/house_keeping/dir_list'

f= open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)
#
#--- append  pathes to private folders to a python directory
#
sys.path.append(bin_dir)
sys.path.append(mta_dir)
#
#--- import several functions
#
import convertTimeFormat          as tcnv       #---- contains MTA time conversion routines
import mta_common_functions       as mcf        #---- contains other functions commonly used in

#---------------------------------------------------------------------------------------------------
#-- read_xmm_and_process: read xmm data, compute statistics and plot the data                   ----
#---------------------------------------------------------------------------------------------------

def read_xmm_and_process(selected):
    """
    read xmm data, compute statistics and plot the data for radiation interruption periods
    input:  selected    --- the name of the interruption period. if this is "all", the
                            script recomputes for the entire period
    output: <yyyymmdd>_xmm.txt  --- data file
            <yyyymmdd>_xmm_stat --- statistics file
            <yyyymmdd>_xmm.png  --- plot
            <yyyymmdd>_xmm_pt2.png  --- second plot, if the period is longer than the first plot
    """
#
#--- read interruption time period
#
    [period, interrupt_start, interrupt_stop] = read_interrupt()
#
#--- if a specific period is selected, choose one entry. otherwise, reprocess all
#
    if selected != 'all':
        for i in range(0, len(period)):
            if period[i] == selected:
                period = [selected]
                start  = interrupt_start[i]
                stop   = interrupt_stop[i]
                interrupt_start = [start]
                interrupt_stop  = [stop]
                break
    else:
        pass
#
#--- read modified xmm data. original data has too many invisible characters
#
    cmd  = 'perl ' + bin_dir + 'clean_up_xmm_data.perl > ./xmm_data_modified'
    os.system(cmd)
    f    = open('./xmm_data_modified', 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    cmd  = 'rm ./xmm_data_modified'
    os.system(cmd)

    time_list  = []
    col2_list  = []
    col3_list  = []
    col4_list  = []
    col5_list  = []
    col6_list  = []
    col7_list  = []
    col8_list  = []
    

    imax = len(interrupt_stop)
#
#--- clean up the data farther
#
    for ent in data:
        atemp = re.split('\s+', ent)
        if len(atemp) > 7:

            try:
                for k in range(0, 8):
                    val = str(atemp[k].strip())
                    atemp[k] = float(val)
    

                time = float(atemp[0])
                col2 = float(atemp[1])
                col3 = float(atemp[2])
                col4 = float(atemp[3])
                col5 = float(atemp[4])
                col6 = float(atemp[5])
                col7 = float(atemp[6])
                col8 = float(atemp[7])

                time_list.append(time)
                col2_list.append(col2)
                col3_list.append(col3)
                col4_list.append(col4)
                col5_list.append(col5)
                col6_list.append(col6)
                col7_list.append(col7)
                col8_list.append(col8)
            except:
                continue

    dlen = len(time_list)
#    fo = open('./xmm_stat', 'w')
    chk    = 0
    for i in range(0, len(period)):
        time_save = []
        col2_save = [] 
        col3_save = [] 
        col4_save = [] 
        col5_save = [] 
        col6_save = [] 
        col7_save = [] 
        col8_save = [] 

        chk       = 0
        chk2      = 0
        extend    = 0
#
#--- set data collection period. sometime the end of the interruption is much longer
#--- than the regular finishing time; if that is the case, extend the data colleciton period
#
        start = interrupt_start[i]- 2.0 * 86400.0
        stop  = interrupt_start[i]+ 3.0 * 86400.0

        if stop < interrupt_stop[i]:
            start2 = interrupt_start[i] + 3.0 * 86400.0
            stop   = start2  + 5.0 * 86400.0
            extend = 1

        for j in range(0, dlen):
            if (time_list[j] >= start) and (time_list[j] <= stop):
                time_save.append(time_list[j])
                col2_save.append(col2_list[j])
                col3_save.append(col3_list[j])
                col4_save.append(col4_list[j])
                col5_save.append(col5_list[j])
                col6_save.append(col6_list[j])
                col7_save.append(col7_list[j])
                col8_save.append(col8_list[j])
                chk2 = 1
            #elif  (time_list[j] > stop and chk2 > 0) :
            elif time_list[j] > stop:
                break

        if len(col2_save) > 0:

                    print "Period: " + period[i]
#
#--- compute statistics
#

                    interrupt_pos = find_interruption_pos_index(time_save, interrupt_start[i])

                    line = '          Avg                    Max             Time        Min             Time        Value at Interruption Started\n'

                    line = line + '-' * 95 + '\n'
                    line = line + 'LE-0:  ' 
                    line = line + find_stat(col2_save, time_save, interrupt_pos)
             
                    line = line + 'LE-1:  ' 
                    line = line + find_stat(col3_save, time_save, interrupt_pos)
             
                    line = line + 'LE-2:  ' 
                    line = line + find_stat(col4_save, time_save, interrupt_pos)
             
                    line = line + 'HES-0: ' 
                    line = line + find_stat(col5_save, time_save, interrupt_pos)
             
                    line = line + 'HES-1: ' 
                    line = line + find_stat(col6_save, time_save, interrupt_pos)
             
                    line = line + 'HES-2: ' 
                    line = line + find_stat(col7_save, time_save, interrupt_pos)
    
                    line = line + 'HES-C: ' 
                    line = line + find_stat(col8_save, time_save, interrupt_pos)

                    stat_name = stat_dir + period[i] + '_xmm_stat'
                    fo2 = open(stat_name, 'w')
                    fo2.write(line)
                    fo2.close()

                    lineh = 'Period: ' + period[i] + '\t' + "Start: " +  str(interrupt_start[i]) + '\t'  + "Stop: " +  str(interrupt_stop[i]) + '\n'
                    lineh = lineh + '-------------------------------------------------------------\n'

                    line  = lineh + line
    
                    line = line + '-' * 95 + '\n'
                    line = line + '-' * 95 + '\n'
#                    fo.write(line)
                    chk = 1
#
#--- print out the data
#
                    print_data(period[i], time_save, col2_save, col3_save, col4_save, col5_save, col6_save, col7_save, col8_save)
#
#--- plot the data
#
                    plot_data(period[i], interrupt_start[i], interrupt_stop[i], time_save, col2_save, col3_save, col4_save, col5_save, col6_save, col7_save, col8_save)
#
#--- if the interruption period is longer than interrupt_start + 3 days, create the second plot
#
                    if extend > 0:
                        plot_data(period[i], start2, interrupt_stop[i], time_save, col2_save, col3_save, col4_save, col5_save, col6_save, col7_save, col8_save, part2='part2')

                    break
        elif time_list[j] < interrupt_start[i]:
                continue

        if chk > 0:
            continue
#    fo.close()

#---------------------------------------------------------------------------------------------------
#-- read_interrupt: read the list of period, interruption start and end                           --
#---------------------------------------------------------------------------------------------------

def read_interrupt():
    """
    read the list of period, interruption start and end 
    input:  all_data    --- the list of period, interruption start and end
    output: [period, interrupt_start, interrupt_stop], but time is in seconds from 1998.1.1
    """
#
#--- read data
#
    #file = house_keeping + '/all_data'
    file = house_keeping + '/atemp'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    data.reverse()

    period          = []
    interrupt_start = []
    interrupt_stop  = []
#
#--- convert the date in yyyy:mm:hh:ss to seconds from 1998.1.1
#
    for ent in data:
        atemp = re.split('\s+', ent)
        btemp = re.split(':', atemp[1])
        start = tcnv.convertDateToTime2(int(btemp[0]), int(btemp[1]), int(btemp[2]), int(btemp[3]), int(btemp[4]), 0)
        btemp = re.split(':', atemp[2])
        stop  = tcnv.convertDateToTime2(int(btemp[0]), int(btemp[1]), int(btemp[2]), int(btemp[3]), int(btemp[4]), 0)
#
#--- save the list again
#
        period.append(atemp[0])
        interrupt_start.append(float(start))
        interrupt_stop.append(float(stop))

    return [period, interrupt_start, interrupt_stop]


#---------------------------------------------------------------------------------------------------
#-- find_interruption_pos_index: find the index of the time given                                ---
#---------------------------------------------------------------------------------------------------

def find_interruption_pos_index(time, interrupt_start):
    """
    find the index of the time given
    input:  time    --- time in seconds from 1998.1.1
            interrupt_start --- the list of the interruption starting time in seconds from 1998.8.1.1
    output: pos     --- index in the list
    """

    pos = 0
    for i in range(0, len(time)):
        if time[i] == interrupt_start:
            pos = i
            break

    return pos

#---------------------------------------------------------------------------------------------------
#-- find_stat: compute statistics and return a formatted line                                    ---
#---------------------------------------------------------------------------------------------------

def find_stat(list, time, interrupt_pos):
    """
    compute statistics and return a formatted line
    input:  list            --- data list
            time            --- time list
            interrupt_pos   --- position index where the interruption started
    output  formated data line: avg +/- std, max /max position, min/min position, 
            the value at the interruption started
    """

    try:
#
#--- find min, max and their postion in time
#
        amin  = min(list)
        amax  = max(list)
        minind= list.index(amin)
        maxind= list.index(amax)
        minp  = conv_to_ydate(time[minind])
        maxp  = conv_to_ydate(time[maxind])
#
#--- average and std
#
        a     = numpy.array(list)
        avg   = numpy.mean(a)
        std   = numpy.std(a)
#
#--- format them
#
        amin  = '%2.3e' % amin
        amax  = '%2.3e' % amax
        avg   = '%2.3e' % avg
        std   = '%2.3e' % std
        minp  = round(minp, 3)
        maxp  = round(maxp, 3)
        intp  = '%2.3e' % list[interrupt_pos]

        line  = str(avg) + ' +/- ' +  str(std)  + '\t'
        line  = line + str(amax)                + '\t'
        line  = line + adjust_digit(maxp, 6, 3) + '\t\t'
        line  = line + str(amin)                + '\t'
        line  = line + adjust_digit(minp, 6, 3) + '\t'
        line  = line + adjust_digit(intp, 6, 3) + '\n'
    
        return line
    except:
#
#--- if the statistics failed, just return "zero's"
#
        return '0 +/- 0, 0, 0, 0, 0, 0\n'


#---------------------------------------------------------------------------------------------------
#-- adjust_digit: padding the digit for nice printout                                            ---
#---------------------------------------------------------------------------------------------------
    
def adjust_digit(val, f1, f2):
    """
    padding the digit for nice printout
    input:  val     --- the float value
            f1      --- value indicates how many white spaces lead to the value
            f2      --- value indicates how many '0' trail to the value
    output: sout    --- padded string
    """
    sval = str(val)
    atemp = re.split('\.', sval)
    top   = atemp[0]
    bot   = atemp[1]
    for i in range(len(top), f1+1):
        top = ' ' + top

    for i in range(len(bot), f2):
        bot = bot + '0'

    sout = top + '.' + bot
    return sout


#---------------------------------------------------------------------------------------------------
#-- conv_to_ydate: convert seconds from 1998.1.1. to ydate. year part is drropped                 --
#---------------------------------------------------------------------------------------------------

def conv_to_ydate(time):
    """
    convert seconds from 1998.1.1. to ydate. year part is drropped
    input:  time    --- time in seconds from 1998.1.1
            day     --- ydate (no year part)
    """

    tmp    = tcnv.convertCtimeToYdate(time)
    atemp  = re.split(':', tmp)
    day    = float(atemp[1])
    hrs    = float(atemp[2])
    mins   = float(atemp[3])
    day   += hrs / 24 + mins / 1440

    return day

#---------------------------------------------------------------------------------------------------
#-- plot_data: plot xmm data                                                                     ---
#---------------------------------------------------------------------------------------------------

def plot_data(period, start, stop, time, le0, le1, le2, hes0, hes1, hes2, hesc, part2=''):
    """
    plot xmm data
    input:  period  --- the name of the interruption period
            start   --- interruption starting time
            stop    --- interruttion ending time
            le0, le1, le2, hes0, hes1, hes2, hesc --- xmm data
            part2   --- indicator of the second pamel. if it is NOT "", it will create the second plot
                        for the extended period
    output: <yyyymmdd>_xmm.png (and possibly <yyyymmdd>_xmm_pt2.png)
    """
#
#--- find radiation periods in of the period
#
    [rad_start, rad_stop] = get_rad_zone(period)
#
#--- set basic plotting parameters
#
    fsize      = 9
    lsize      = 1
    psize      = 2.0
    resolution = 100
    colorList  = ('blue', 'red', 'green', 'aqua', 'fuchsia','lime', 'maroon', 'black', 'olive', 'yellow')
    markerList = ('o',    '*',     '+',   '^',    's',    'D',       '1',      '2',     '3',      '4')
#
#--- convert start and stop time into ydate
#
    ystart = conv_to_ydate(start)
    ystop  = conv_to_ydate(stop)

    ytime  = []
    for ent in time:
        day = conv_to_ydate(ent)
        ytime.append(day)
#
#--- set plotting period; if there are two plots for this period, second one start from where
#--- the first plot ended
#
    if part2 == '':
        xmin  = ystart - 2.0
        xmax  = ystart + 3.0
    else:
        xmin  = ystart
        xmax  = ystart + 5.0

#
#--- find min and max of data and set y plotting range
#
    ymin  = min(le0)
    for  dset in (le1, le2, hes0, hes1, hes2, hesc):
        tmax = min(dset)
        if ymin < ymin:
            ymin = tmin

    ymin *= 0.01

    ymax  = max(le0)
    for  dset in (le1, le2, hes0, hes1, hes2, hesc):
        tmax = max(dset)
        if tmax > ymax:
            ymax = tmax

    ymax *= 1.1
#
#--- set where to put the text
#
    xdiff = xmax - xmin
    ydiff = ymax - ymin 
    xtext = ystart + 0.01 * xdiff
    ytext = (ymax - 0.8   * ydiff)
#
#--- clean the plotting 'memory'
#
    plt.close('all')

    mpl.rcParams['font.size'] = fsize
    props = font_manager.FontProperties(size=9)
    plt.subplots_adjust(hspace=0.08)
#
#--- first panel
#
    ax1 = plt.subplot(211)
    ax1.set_autoscale_on(False)  
    ax1.set_xbound(xmin,xmax)
    ax1.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax1.set_ylim(ymin=ymin, ymax=ymax, auto=False)
    
    p1 =  plt.semilogy(ytime, le0,  color=colorList[0], lw =lsize , marker=markerList[0], markersize=psize, label='LE-0')
    p2 =  plt.semilogy(ytime, le1,  color=colorList[1], lw =lsize , marker=markerList[1], markersize=psize, label='LE-1')
    p3 =  plt.semilogy(ytime, le2,  color=colorList[2], lw =lsize , marker=markerList[2], markersize=psize, label='LE-2')

    if part2 == '':
        plt.text(xtext, ytext, r'Interruption', color='red')
#
#--- plot radiation zone markers
#
    for i in range(0, len(rad_start)):
        plt.plot([rad_start[i], rad_stop[i]], [ymin ,ymin], color='red', lw='6')
#
#--- plot interruption start/stop markers
#
    if part2 == '':
        plt.plot([ystart, ystart], [ymin, ymax], color='red', lw='3')
        plt.plot([ystop,   ystop], [ymin, ymax], color='red', lw='3')
    else:
        plt.plot([ystop,   ystop], [ymin, ymax], color='red', lw='3')
#
#--- add legend
#
    ax1.legend(['LE-0', 'LE-1', 'LE-2'])

    ax1.set_ylabel('Counts/Sec',      size=fsize)
#
#--- second panel
#
    ax2 = plt.subplot(212)
    ax2.set_autoscale_on(False)  
    ax2.set_xbound(xmin,xmax)
    ax2.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax2.set_ylim(ymin=ymin, ymax=ymax, auto=False)
    
    p4 =  plt.semilogy(ytime, hes0, color=colorList[3], lw =lsize , marker=markerList[3], markersize=psize, label='HES-0')
    p5 =  plt.semilogy(ytime, hes1, color=colorList[4], lw =lsize , marker=markerList[4], markersize=psize, label='HES-1')
    p6 =  plt.semilogy(ytime, hes2, color=colorList[5], lw =lsize , marker=markerList[5], markersize=psize, label='HES-2')
    p7 =  plt.semilogy(ytime, hesc, color=colorList[6], lw =lsize , marker=markerList[6], markersize=psize, label='HES-C')

    if part2 == '':
        plt.text(xtext, ytext, r'Interruption', color='red')
#
#--- radiation zone
#
    for i in range(0, len(rad_start)):
        plt.plot([rad_start[i], rad_stop[i]], [ymin ,ymin], color='red', lw='6')
#
#--- interruption period
#
    if part2 == '':
        plt.plot([ystart, ystart], [ymin, ymax], color='red', lw='3')
        plt.plot([ystop,  ystop],  [ymin, ymax], color='red', lw='3')
    else:
        plt.plot([ystop,  ystop],  [ymin, ymax], color='red', lw='3')
#
#--- add legend
#
    ax2.legend(['HES-0','HES-1', 'HES-2', 'HES-C'])

    ax2.set_xlabel('Time (Day Of Year)', size=fsize)
    ax2.set_ylabel('Counts/Sec',      size=fsize)
#
#--- x axis ticks are only shown in the bottom panel
#
    for ax in ax1, ax2:
        if ax != ax2:
            for label in ax.get_xticklabels():
                label.set_visible(False)
        else:
            pass
#
#-- save the plot
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 5.0)
 
    if part2 == '':
        outname = xmm_dir + str(period) + '_xmm.png'
    else:
        outname = xmm_dir + str(period) + '_xmm_pt2.png'

    plt.savefig(outname, format='png', dpi=resolution)


#---------------------------------------------------------------------------------------------------
#-- print_data: print out extracted data for the period                                          ---
#---------------------------------------------------------------------------------------------------
    
def print_data(period, time, col2, col3, col4, col5, col6, col7, col8):
    """
    print out extracted data for the period
    input:  period  --- the name of the period
            lists of data in time, col2, col3, col4, col5, col6, col7, col8
    output: <yyyymmdd>_xmm.txt in data directory
    """

    file = data_dir + str(period) +  '_xmm.txt'
    fo   = open(file, 'w')

    for i in range(0, len(time)):
        line = str(time) + '\t'
        line = line + str(col2) +  '\t'
        line = line + str(col3) +  '\t'
        line = line + str(col4) +  '\t'
        line = line + str(col5) +  '\t'
        line = line + str(col6) +  '\t'
        line = line + str(col7) +  '\t'
        line = line + str(col8) +  '\n'

        fo.write(line)

    fo.close()

#---------------------------------------------------------------------------------------------------
#-- get_rad_zone: read rad_zone_list                                                              --
#---------------------------------------------------------------------------------------------------

def get_rad_zone(period):
    """
    read rad_zone_list
    input:  period  --- the period name of the interruption
    output: rad_zone    --- a list of lists of radiation zone start time and stop time
    """

    file = house_keeping + 'rad_zone_list'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    rad_zone = ''
    for ent in data:
        atemp = re.split('\s+', ent)
        if atemp[0] == period:
            rad_zone = atemp[1]
            break
    
    if rad_zone == '':
        return [0, 0]
    else:
#
#--- if there are values, convert them into ydate (no year part kept)
#
        start_list = []
        stop_list  = []
        atemp = re.split(':', rad_zone)
        for line in atemp:
            atemp = re.split('\(', line)
            btemp = re.split('\)', atemp[1])
            ent   = re.split('\,', btemp[0])
            temp   = tcnv.DOMtoYdate(float(ent[0]))
            start_list.append(temp[1])

            temp   = tcnv.DOMtoYdate(float(ent[1]))
            stop_list.append(temp[1])

        rad_zone = [start_list, stop_list]
    
    return rad_zone

#---------------------------------------------------------------------------------------------------

if __name__ == '__main__':

#
#--- a period name (e.g. 2061206) is given, the script computes only for that period
#--- otherwise, it will recompute the entire period
#
    if len(sys.argv) == 2:
        if mcf.chkNumeric(sys.argv[1]):
            period = sys.argv[1]
        else:
            period = 'all'
    else:
        period = 'all'

    read_xmm_and_process(period)
