#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################
#                                                                                       #
#       acis_dose_get_data.py: obtain ACIS Evt 1 data for a month and combine them      #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last updated: Apr 11, 2013                                                      #
#                                                                                       #
#########################################################################################

import sys
import os
import string
import re

#
#--- reading directory list
#

path = '/data/mta/Script/Exposure/house_keeping/acis_dir_list'
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
#--- Exposure related funcions shared
#

import exposureFunctions as expf


#-----------------------------------------------------------------------------------------------------------
#-- acis_dose_get_data: extract ACIS evt1 data and create combined image file                            ---
#-----------------------------------------------------------------------------------------------------------

def acis_dose_get_data(startYear='NA', startMonth='NA', stopYear='NA', stopMonth='NA'):

    """
    extract ACIS evt1 data from a month and create combined image file. Input: start year, start month, stop year, stop month
    """

    if startYear == 'NA' or startMonth == 'NA'or stopYear == 'NA' or stopMonth == 'NA':

        startYear  = raw_input('Start Year: ')
        startyear  = int(startYear)
        startMonth = raw_input('Start Month: ')
        startMonth = int(startMonth)

        stopYear   = raw_input('Stop Year: ')
        stopyear   = int(stopYear)
        stopMonth  = raw_input('Stop Month: ')
        stopMonth  = int(stopMonth)
#
#--- start extracting the data for the year/month period
#
    for year in range(startYear, stopYear+1):

        lyear = str(year)
        syear = lyear[2] + lyear[3]

        month_list =  expf.make_month_list(year, startYear, stopYear, startMonth, stopMonth)  #---- create a list of month appropriate for the year

        for month in month_list:

            smonth = str(month)
            if month < 10:
                smonth = '0' + smonth
#
#--- using ar4gl, get file names
#
            ydate1 = tcnv.findYearDate(year, month, 1)

            nextMonth = month + 1
            if nextMonth > 12:
                nyear     = year + 1
                ydate2 = tcnv.findYearDate(nyear, 1, 1)
            else:
                nyear  = year                
                ydate2 = tcnv.findYearDate(year, nextMonth, 1)

            fitsList = mtac.useArc4gl('browse', 'flight', 'acis', 1, 'evt1', year, ydate1, nyear, ydate2)


#
#--- extract each evt1 file, extract the central part, and combine them into a one file
#
            i = 0
            acisCnt = 0

            for file in fitsList:
                m = re.search('fits', file)
                if m is not None:
                        
                    fitsName = mtac.useArc4gl('retrieve','flight', 'acis', 1, 'evt1', filename=file)

                    line = file + '[EVENTS][bin tdetx=2800:5200:1, tdety=1650:4150:1][option type=i4]'

                    ichk =  expf.create_image(line, 'ztemp.fits')               #---  create an image file
#
#--- combined images
#
                    if ichk > 0:
                        expf.combine_image('ztemp.fits', 'total.fits')
                        acisCnt += 1
                
                    cmd = 'rm ' + file
                    os.system(cmd)

#
#--- rename the file
#

            outfile = './ACIS_' + smonth + '_' + lyear + '_full.fits'
            cmd     = 'mv total.fits ' + outfile
            os.system(cmd)
#
#--- trim the extreme values
#
            upper = find_10th(outfile)

            outfile2 = './ACIS_' + smonth + '_' + lyear + '.fits'
            cmd   = 'dmimgthresh infile=' + outfile + ' outfile=' + outfile2 + ' cut="0:' + str(upper) + '" value=0 clobber=yes'
            os.system(cmd)

            cmd   = 'gzip ' + outfile
            os.system(cmd)
            


#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------

def find_10th(fits_file):

    """
    find 10th brightest value    input: fits file
    """
#
#-- make histgram
#
    cmd = ' dmimghist infile=' + fits_file + '  outfile=outfile.fits hist=1::1 strict=yes clobber=yes'
    os.system(cmd)
    os.system('dmlist infile=outfile.fits outfile=./zout opt=data')

    f    = open('./zout', 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    os.system('rm outfile.fits ./zout')
#
#--- read bin # and its count rate
#
    hbin = []
    hcnt = []

    for ent in data:
        try:
            atemp = re.split('\s+|\t+', ent)
            if (len(atemp) > 3) and mtac.chkNumeric(atemp[1])  and mtac.chkNumeric(atemp[2])  and (int(atemp[4]) > 0):
                hbin.append(float(atemp[1]))
                hcnt.append(int(atemp[4]))
        except:
            pass

#
#--- checking 10 th bright position
#
    try:
        j = 0
        for i in  range(len(hbin)-1, 0, -1):
            if j == 9:
                val = i
                break
            else:
                if hcnt[i] > 0:                 #---- only when the value is larger than 0, record as count
                    j += 1

        return hbin[val]
    except:
        return 'I/INDEF'




#--------------------------------------------------------------------------------------------------------

if __name__ == '__main__':
    
    acis_dose_get_data()


