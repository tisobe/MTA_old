#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################
#                                                                                                   #
#       hrc_gain_fit_voigt.py: extract hrc evt2 files and fit a normal distribution on pha values   #
#                                                                                                   #
#           author: t. isobe(tisobe@cfa.harvard.edu)                                                #
#                                                                                                   #
#           Last Update:    Mar 07, 2017                                                            #
#                                                                                                   #
#####################################################################################################

import os
import sys
import re
import string
import random
import math
import time
import numpy
import astropy.io.fits  as pyfits
from datetime import datetime

#
#--- reading directory list
#
path = '/data/aschrc6/wilton/isobe/Project8/ArLac/Scripts2/house_keeping/dir_list_py'

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
import mta_common_functions     as mcf
import hrc_gain_fit_voigt       as hgfv  
import hrc_gain_trend_plot      as hgtp
#
#--- temp writing file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)
#
#--- AR Lac position
#
ra  = 332.179975
dec = 45.7422544

#---------------------------------------------------------------------------------------------------
#-- hrc_gain_run: extract hrc evt2 file, find the brightest object and create pha distribution     -
#---------------------------------------------------------------------------------------------------

def  hrc_gain_run(c_input):

    """
    extract hrc evt2 file, find the brightest object and create pha distribution
    this is a control script

    Input:  c_inut      --- if it is obsid, use it as a input
                            otherwise, a list of new candidates will be create based database
    Output: <header>_pha.dat    --- pha distribution data
            <header>_gfit.png   --- a plot of pha data
            fitting_results     --- a table of fitted results
    """
#
#--- if an obsid is provided, analyize that, else get new obsids from databases
#
    if mcf.chkNumeric(c_input):
        candidate_list = [c_input]
    elif isinstance(c_input, list):
        candidate_list = c_input
    else:
        candidate_list = get_arlac_list()
#
#--- run the main script only when candidates exist
#
    if len(candidate_list) > 0:

        hgfv.hrc_gain_fit_voigt(candidate_list)
        hgtp.hrc_gain_trend_plot()

#---------------------------------------------------------------------------------------------------
#-- get_arlac_list: check whether we have new calibration Ar Lac observations                    ---
#---------------------------------------------------------------------------------------------------

def get_arlac_list():
    """
    check whether we have new calibration Ar Lac observations and if so, the list of all 
    observed calibration Ar Lac list
        Note: Ar Lac ion shield scripts must be run first before this one is run

    input: none, but read from iron sheild data and from <house_keeping>
    output: data    ---- empty list or a list of all calibration Ar Lac obsids
    """
#
#--- use hrc lists from ion shield health 
#
    ifile1 = main_dir + 'Scripts/house_keeping/hrc_i_list'
    data1  = read_data(ifile1)

    ifile2 = main_dir + 'Scripts/house_keeping/hrc_s_list'
    data2  = read_data(ifile2)

    data   = data1 + data2
#
#--- read lists from the last time the scripts were run
#
    ifile3 = house_keeping + 'hrc_i_list'
    data3  = read_data(ifile3)

    ifile4 = house_keeping + 'hrc_s_list'
    data4  = read_data(ifile4)

    odata = data3 + data4

    if set(data) == set(odata):
        data  = []
#
#--- if these are new data sets, update the local lists
#
    else:
        cmd = 'cp -f ' + ifile1 + ' ' + ifile3
        os.system(cmd)
        cmd = 'cp -f ' + ifile2 + ' ' + ifile4
        os.system(cmd)

    return data

#-----------------------------------------------------------------------------------------
#-- read_data: read data file                                                           --
#-----------------------------------------------------------------------------------------

def read_data(infile, remove=0):

    try:
        f    = open(infile, 'r')
        data = [line.strip() for line in f.readlines()]
        f.close()
    except:
        data = []

    if remove == 1:
        mcf.rm_file(infile)

    return data


#--------------------------------------------------------------------

if __name__ == '__main__':
#
#--- you can give an obsid of ar lac as an argument
#
    if len(sys.argv) >= 2:
        c_input = sys.argv[1]
        c_input.strip()
    else:
        c_input = ""

    hrc_gain_run(c_input)


