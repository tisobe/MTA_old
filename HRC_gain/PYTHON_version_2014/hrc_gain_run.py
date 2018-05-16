#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################
#                                                                                                   #
#       hrc_gain_fit_voigt.py: extract hrc evt2 files and fit a normal distribution on pha values   #
#                                                                                                   #
#           author: t. isobe(tisobe@cfa.harvard.edu)                                                #
#                                                                                                   #
#           Last Update:    Sep 25, 2014                                                            #
#                                                                                                   #
#####################################################################################################

import os
import sys
import re
import string
import random
#
#--- reading directory list
#
path = '/data/mta/Script/HRC/Gain/house_keeping/dir_list_py'

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
import mta_common_functions       as mcf
import hrc_gain_find_ar_lac       as arlist
import hrc_gain_fit_voigt         as hgfv  
#
#--- temp writing file name
#
rtail  = int(10000 * random.random())       #---- put a romdom # tail so that it won't mix up with other scripts space
zspace = '/tmp/zspace' + str(rtail)
#
#--- AR Lac position
#
ra  = 332.179975
dec = 45.7422544

#---------------------------------------------------------------------------------------------------
#--- hrc_gain_fit_gaus:  extract hrc evt2 file and create pha distribution                       ---
#---------------------------------------------------------------------------------------------------

def  hrc_gain_run(c_input):

    """
    extract hrc evt2 file, find the brightest object and create pha distribution
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
    else:
        candidate_list = arlist.hrc_gain_find_ar_lac()
#
#--- run the main script only when candidates exist
#
    if len(candidate_list) > 0:

        hgfv.hrc_gain_fit_voigt(candidate_list)

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


