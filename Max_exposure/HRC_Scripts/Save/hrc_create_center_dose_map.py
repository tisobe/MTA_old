#!/usr/local/bin/python2.6

#########################################################################################
#                                                                                       #
#       hrc_create_dose_map.py: a master script to create center HRC dose map           #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last update: June20, 2012                                                       #
#                                                                                       #
#########################################################################################

import sys
import os
import string
import re

#
#--- reading directory list
#

path = '/data/mta/Script/Exposure/house_keeping2/hrc_dir_list'
f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)

#
#--- append path to a privte folder
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
import hrc_dose_get_data as getdata
import hrc_does_extract_stat_data_month as hstat
import hrc_dose_plot_exposure_stat as eplot
import hrc_dose_make_data_html as mkhtml

#---------------------------------------------------------------------------------------------------------
#--- hrc_create_dose_map: extract data, create a center part map/statistics, driving script            ---
#---------------------------------------------------------------------------------------------------------

def hrc_create_dose_map(year = 'NA', mon = 'NA'):

    'extract data, create a center part map/statistics, driving script. if year and month are given, computer for that year/month. Otherwise one month before the current month'


#
#--- if year and mon are not provided, check a month before the current month
#
    if year == 'NA':
        [year, mon, day, hours, min, sec, weekday, yday, dst] = tcnv.currentTime('Local')

        lyear = year
        lmon  = mon -1
        if lmon < 1:
            lmon = 12
            lyear -= 1
    else:
        lyear = year
        lmon  = mon
#
#--- ectract data
#
#    getdata.hrc_dose_get_data(lyear, lmon, lyear, lmon)
#
#--- compute stat
#
#    hstat.hrc_dose_extract_stat_data_month(lyear, lmon, cum_dir, mon_dir, data_out)
#
#--- plot data
#
    eplot.hrc_dose_plot_exposure_stat(data_out, plot_dir)
        
#
#--- create html pages
#
#    mkhtml.hrc_dose_make_data_html(data_out, data_out)


#--------------------------------------------------------------------------------------------------------

if __name__ == '__main__':
    
    hrc_create_dose_map()
