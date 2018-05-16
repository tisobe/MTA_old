#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################    
#                                                                                   #
#       update_graddata_from_comm.py: update grad related data using mp data        #
#           author: t. isobe (tisobe@cfa.harvard.edu)                               #
#                                                                                   #
#           last update: Feb 15, 2018                                               #
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
#
#--- a list of grad related group names
#
ifile      = house_keeping + 'grad_list'
grad_entry = ecf.read_file_data(ifile)

out_dir    =  deposit_dir + 'Grad_save/'

#-------------------------------------------------------------------------------------------
#-- update_graddata_from_comm: update grad related data using mp data                             
#-------------------------------------------------------------------------------------------

def update_graddata_from_comm():
    """
    update grad related data using mp data
    input: none but read from /data/mta_www/mp_reports and <house_keeping>/<grad_group>_past
    output: <out_dir>/<grad msid>_full_data.fits
    """
    for grad_group in grad_entry:
#
#--- read the last set of the input data and find the last entry 
#
        past = house_keeping + grad_group + '_past'
        past = ecf.read_file_data(past)

        last = past[-1]
#
#--- find today's data entry
#
        cmd  = 'ls /data/mta_www/mp_reports/*/' + grad_group + '/data/mta*fits* >' + zspace
        os.system(cmd)
        current = ecf.read_file_data(zspace)

        cmd  = 'mv '+  zspace + ' ' +  house_keeping + grad_group + '_past'
        os.system(cmd)
#
#--- find the data which are not read
#
        new_fits = []
        chk      = 0
        for ent in current:
            if chk == 0:
                if ent == last:
                    chk = 1
                continue
            new_fits.append(ent)
#
#--- uppend the data to the local fits data files
#
        for fits in new_fits:
            [cols, tbdata] = ecf.read_fits_file(fits)

            time  = tbdata['time']

            for col in cols:
#
#--- ignore columns with "ST_" (standard dev) and time
#
                if col.lower() == 'time':
                    continue

                mc = re.search('st_', col.lower())
                if mc is not None:
                    continue

                mdata = tbdata[col]
                cdata = [time, mdata]
                ocols = ['time', col.lower()]

                ofits = out_dir + col.lower()+ '_full_data.fits'
                if os.path.isfile(ofits):
                    update_fits_file(ofits, ocols, cdata)
                else:
                    create_fits_file(ofits, ocols, cdata)

        
#-------------------------------------------------------------------------------------------
#-- update_fits_file: update fits file                                                    --
#-------------------------------------------------------------------------------------------

def update_fits_file(fits, cols, cdata):
    """
    update fits file
    input:  fits    --- fits file name
            cols    --- a list of column names
            cdata   --- a list of lists of data values
    output: updated fits file
    """

    f     = pyfits.open(fits)
    data  = f[1].data
    f.close()

    udata = []
    chk   = 0
    for k in range(0, len(cols)):
        try:
            nlist   = list(data[cols[k]]) + list(cdata[k])
            udata.append(numpy.array(nlist))
        except:
            chk = 1
            pass

    if chk == 0:
        try:
            create_fits_file(fits, cols, udata)
        except:
            pass

#-------------------------------------------------------------------------------------------
#-- create_fits_file: create a new fits file for a given data set                         --
#-------------------------------------------------------------------------------------------

def create_fits_file(fits, cols, cdata):
    """
    create a new fits file for a given data set
    input:  fits    --- fits file name
            cols    --- a list of column names
            cdata   --- a list of lists of data values
    output: newly created fits file "fits"
    """
    dlist = []
    for k in range(0, len(cols)):
        aent = numpy.array(cdata[k])
        dcol = pyfits.Column(name=cols[k], format='F', array=aent)
        dlist.append(dcol)

    dcols = pyfits.ColDefs(dlist)
    tbhdu = pyfits.BinTableHDU.from_columns(dcols)

    mcf.rm_file(fits)
    tbhdu.writeto(fits)


#-------------------------------------------------------------------------------------------

if __name__ == "__main__":

    update_graddata_from_comm()
