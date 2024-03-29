#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################################
#                                                                                               #
#       hrc_dose_create_image.py: convert hrc fits files to png image files                     #
#                                                                                               #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                               #
#                                                                                               #
#       last update: Apr 11, 2013                                                               #
#                                                                                               #
#################################################################################################

import sys
import os
import string
import re
import getpass
import socket
import fnmatch 


#
#--- reading directory list
#

path = '/data/mta/Script/Exposure/house_keeping/hrc_dir_list'
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
sys.path.append(mta_dir)

#
#--- this convert fits files to image files
#

import mta_convert_fits_to_image_ciao as mtaimg

#
#--- check whose account, and set a path to temp location
#

user = getpass.getuser()
user = user.strip()

#
#---- find host machine name
#

machine = socket.gethostname()
machine = machine.strip()

#
#--- set temp directory/file
#
tempdir = '/tmp/' + user + '/'
tempout = tempdir + 'ztemp'

#
#--- directory containin plotting related scripts
#
pbin_dir =  '/home/ascds/DS.release/otsbin/'

#----------------------------------------------------------------------------------------------------------------
#---  create_hrc_maps: create HRC image maps for given year and month                                        ----
#----------------------------------------------------------------------------------------------------------------

def create_hrc_maps(year= 'NA', month= 'NA', comp_test = 'NA'):

    """
     create HRC image maps for given year and month 
    """

    if year == 'NA' or month == 'NA':

        year  = raw_input('Year: ')
        year  = int(year)
        month = raw_input('Month: ')
        month = int(month)

#
#--- images for the center part
#

    if comp_test == 'test':
        hrc_dose_conv_to_png(test_mon_dir_hrc, test_img_dir, year, month)
        hrc_dose_conv_to_png(test_cum_dir_hrc, test_img_dir, year, month)
    else:
        hrc_dose_conv_to_png(mon_dir_hrc, img_dir, year, month)
        hrc_dose_conv_to_png(cum_dir_hrc, img_dir, year, month)

#
#--- image for sections for full images
#
    if comp_test == 'test':
        hrc_dose_conv_to_png(test_mon_dir_hrc_full, test_mon_dir_hrc_full, year, month)
        hrc_dose_conv_to_png(test_cum_dir_hrc_full, test_cum_dir_hrc_full, year, month)
    else:
        hrc_dose_conv_to_png(mon_dir_hrc_full, full_images, year, month)
        hrc_dose_conv_to_png(cum_dir_hrc_full, full_images, year, month)


#----------------------------------------------------------------------------------------------------------------
#--- hrc_dose_conv_to_png: prepare to convet fits files into png images                                       ---
#----------------------------------------------------------------------------------------------------------------

def hrc_dose_conv_to_png(indir, outdir, year, month):

    """
    prepare to convet fits files into png images, input: indir, outdir, year, month
    """

    syear = str(year)
    smon  = str(month)
    if month < 10:
        smon = '0' + smon

    hname =  'HRC*' + smon + '_' + syear + '*.fits*'

    for file in os.listdir(indir):

        if fnmatch.fnmatch(file, hname):

            btemp   = re.split('\.fits', file)
            out     = btemp[0]
            outfile = outdir + out

            file_p  = indir + file

            mtaimg.mta_convert_fits_to_image(file_p, outfile, 'log', '125x125', 'heat', 'png')
        else:
            pass


#--------------------------------------------------------------------------------------------

if __name__ == '__main__':

    create_hrc_maps()


