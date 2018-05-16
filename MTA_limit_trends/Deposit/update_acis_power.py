#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################    
#                                                                                   #
#           update_acis_power.py: update acis electric power data                   #
#                                                                                   #
#           author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                   #
#           last update: Mar 06, 2018                                               #
#                                                                                   #
#####################################################################################

import os
import sys
import re
import string
import time
import numpy
import astropy.io.fits  as pyfits
import Ska.engarchive.fetch as fetch
import Chandra.Time
import datetime

#
#--- reading directory list
#
path = '/data/mta/Script/MTA_limit_trends/Scripts/house_keeping/dir_list'
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
sys.path.append(mta_dir)
#
#--- import several functions
#
import convertTimeFormat        as tcnv       #---- contains MTA time conversion routines
import mta_common_functions     as mcf        #---- contains other functions commonly used in MTA scripts
import glimmon_sql_read         as gsr
import envelope_common_function as ecf
import fits_operation           as mfo
#
#--- set a temporary file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)

#-------------------------------------------------------------------------------------------
#-- update_acis_power: update acis electric pwer data                                    ---
#-------------------------------------------------------------------------------------------

def update_acis_power():
    """
    update acis electric pwer data
    input:  none
    output: <out_dir>/1dppwra_full_data_<year>.fits, <out_dir>/1dppwrb_full_data_<year>fits
    """
    t_file  = '1dppwra_full_data_*.fits*'
    out_dir = deposit_dir + 'Comp_save/Compacispwr/'

    [tstart, tstop, year] = ecf.find_data_collecting_period(out_dir, t_file)
#
#--- update the data
#
    get_data(tstart, tstop, year, out_dir)
#
#--- zip the fits file from the last year at the beginning of the year
#
    ecf.check_zip_possible(out_dir)


#-------------------------------------------------------------------------------------------
#-- get_data: update acis electric pwer data for a gvien period                           --
#-------------------------------------------------------------------------------------------

def get_data(start, stop, year, out_dir):
    """
    update acis electric pwer data for a gvien period
    input:  start   --- starting time in seconds from 1998.1.1
            stop    --- stopping time in seconds from 1998.1.1
            year    --- year of the data extracted
            out_dir --- output directory
    output: <out_dir>/1dppwra_full_data_<year>.fits, <out_dir>/1dppwrb_full_data_<year>fits
    """

    print str(start) + '<-->' + str(stop)

    for msid in ['1dppwra', '1dppwrb']:

        if msid == '1dppwra':
            msid_v = '1dp28avo'
            msid_a = '1dpicacu'
        else:
            msid_v = '1dp28bvo'
            msid_a = '1dpicbcu'

        out   = fetch.MSID(msid_v, start, stop)
        tdat1 = out.vals
        ttime = out.times
        out   = fetch.MSID(msid_a, start, stop)
        tdat2 = out.vals

        tlen1 = len(tdat1)
        tlen2 = len(tdat2)
        if tlen1 == 0 or tlen2 == 0:
            continue


        if tlen1 > tlen2:
            diff = tlen1 - tlen2
            for k in range(0, diff):
                tdat2 = numpy.append(tdat2, tadt2[-1])
        elif tlen1 < tlen2:
            diff = tlen2 - tlen1
            for k in range(0, diff):
                tdat1 = numpy.append(tdat1, tadt1[-1])

        ocols = ['time', msid]
        cdata = [ttime, tdat1 * tdat2]
           
        ofits = out_dir + msid + '_full_data_' + str(year) +'.fits'
        if os.path.isfile(ofits):
            ecf.update_fits_file(ofits, ocols, cdata)
        else:
            ecf.create_fits_file(ofits, ocols, cdata)


#-------------------------------------------------------------------------------------------

if __name__ == "__main__":

    update_acis_power()
