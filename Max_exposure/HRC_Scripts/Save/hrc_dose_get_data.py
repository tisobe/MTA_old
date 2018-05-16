#!/usr/local/bin/python2.6

#########################################################################################
#                                                                                       #
#       hrc_dose_get_data.py: obtain HRC Evt1 data for a month and create               #
#                                cumulative data fits file                              #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last updated: May 14, 2012                                                      #
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

#---------------------------------------------------------------------------------------------------------
#--- hrc_dose_get_data: extract HRC evt1 data fro a month and create cumulative data fits file          --
#---------------------------------------------------------------------------------------------------------

def hrc_dose_get_data(startYear, startMonth, stopYear, stopMonth):

    'extract HRC evt1 data fro a month and create cumulative data fits file. Input: start year, start month, stop year, stop month'

#
#--- checking a depository directory. if there is, clean up. if not crate.
#

    chk = expf.chkFile('./', 'Save')
    if chk == 1:
        chk = expf.chkFile('./Save', 'fits')
        if chk == 1:
            os.system('rm ./Save/*')
    else:
        os.system('mkdir ./Save')

#
#--- fill up the month list
#
    month_list1 = []
    month_list2 = []
    month_list3 = []

    chk = 0                             #--- this chk will be used to monitor whether the period completes in a year or not

    if startYear == stopYear:
#
#--- the period is in the same year
#

        month_list1 = range(startMonth, stopMonth+1)
        chk = 1

    else:
#
#--- if the period is over two or more years, we need to set three sets of month list
#
        month_list1 = range(startMonth, 13)
        month_list2 = range(1,13)
        month_list3 = range(1,stopMonth+1)

    for year in range(startYear, stopYear+1):
        lyear = str(year)
        syear = lyear[2] + lyear[3]

#
#--- choose a month list for the specific year
#
        if chk > 0:                        #--- for the case, the list finishes in the same year
            month_list = month_list1
        else:
            if year == startYear:
                month_list = month_list1
            elif year == stopYear:
                month_list = month_list3
            else:
                month_list = month_list2
#
#--- start extracting the data for the year/month period
#
        for month in month_list:
            smonth = str(month)
            if month < 10:
                smonth = '0' + smonth

            outfile_i = './HRCI_' + smonth + '_' + lyear + '.fits'
            outfile_s = './HRCS_' + smonth + '_' + lyear + '.fits'

#
#--- using ar4gl, get file names
#
            ydate1 = tcnv.findYearDate(year, month, 1)

            nextMonth = month + 1
            if nextMonth > 12:
                lyear     = year + 1
                ydate2 = tcnv.findYearDate(lyear, 1, 1)
            else:
                lyear  = year                
                ydate2 = tcnv.findYearDate(year, nextMonth, 1)

            fitsList = expf.useArc4gl('browse', 'flight', 'hrc', 1, 'evt1', year, ydate1, lyear, ydate2)

#
#--- extract each evt1 file, extract the central part, and combine them into a one file
#
            hrciCnt = 0                                 #--- counters for how many hrc-i and hrc-s are extracted
            hrcsCnt = 0

            for file in fitsList:

                [fitsName] = expf.useArc4gl('retrieve','flight', 'hrc', 1, 'evt1', filename=file)

                detector = whichHRC(fitsName)           #--- checking which HRC (S or I)

                if detector == 'HRC-S':
                    line = fitsName + '[EVENTS][bin rawx=0:4095:1, rawy=22528:26623:1][status=xxxxxx00xxxxxxxxx000x000xx00xxxx][option type=i4 mem=80]'
                else:
                    line = fitsName + '[EVENTS][bin rawx=6144:10239:1, rawy=6144:10239:1][status=xxxxxx00xxxxxxxxx000x000xx00xxxx][option type=i4 mem=80]'
                
#
#--- create image file
#
                cmd  = 'dmcopy "' + line + '" out.fits option=image clobber=yes'
                os.system(cmd)
 
                cmd  = 'dmstat out.fits centroid=no > stest'
                os.system(cmd)
#
#--- if there is actually data, condense the iamge so that it won't take too much space
#
                f = open('stest', 'r')
                sdata = [line.strip() for line in f.readlines()]
                f.close()
                os.system('rm stest')

                val = 'NA'
                for lent in sdata:
                    m = re.search('mean', lent)
                    if m is not None:
                        atemp = re.split('\s+|\t+', lent)
                        val = atemp[1]
                        break
                        
                if val != 'NA' and float(val) > 0:
                    line = 'out.fits[opt type=i4,null=-99]'
                    cmd  = 'dmcopy infile="' +line + '" outfile=ztemp.fits clobber=yes'
                    os.system(cmd)
#
#--- for HRC S
#
                    if detector == 'HRC-S':
                        if hrcsCnt == 0:
                            os.system('mv ztemp.fits total_s.fits')
                        else:
                            cmd = 'dmimgcalc infile=ztemp.fits infile2=total_s.fits outfile=mtemp.fits operation=add  clobber=yes'
                            os.system(cmd)
                            os.system('rm ztemp.fits')
                            os.system('mv mtemp.fits total_s.fits')
    
                        hrcsCnt += 1
#
#--- for HRC I
#
                    else:
                        if hrciCnt == 0:
                            os.system('mv ztemp.fits total_i.fits')
                        else:
                            cmd = 'dmimgcalc infile=ztemp.fits infile2=total_i.fits outfile=mtemp.fits operation=add  clobber=yes'
                            os.system(cmd)
                            os.system('rm ztemp.fits')
                            os.system('mv mtemp.fits total_i.fits')
    
                        hrciCnt += 1

                cmd = 'rm out.fits ' + fitsName
                os.system(cmd)
#
#--- move the file to a depository 
#
            if hrcsCnt > 0:
                cmd = 'mv total_s.fits ./Save/' + outfile_s
                os.system(cmd)

            if hrciCnt > 0:
                cmd = 'mv total_i.fits ./Save/' + outfile_i
                os.system(cmd)

            os.system('gzip ./Save/HRC*fits')
            cmd = 'mv   ./Save/HRC*fits.gz ' + web_dir + '/Month_hrc/'
            os.system(cmd)
#
#---- create cumulative hrc data
#
            createCumulative(year, month)

#-----------------------------------------------------------------------------------------------------
#--- createCumulative: create cumulative hrc data                                                   --
#-----------------------------------------------------------------------------------------------------

def createCumulative(year, month):

    'create cumulative hrc data for a given year and month'

#
#--- find the previous period
#
    pyear = year
    pmonth = month -1

    if pmonth < 1:
        pmonth = 12
        pyear -= 1

    syear  = str(year)
    smonth = str(month)

    if month < 10:
        smonth = '0' + smonth

    spyear  = str(pyear)
    spmonth = str(pmonth)

    if pmonth < 10:
        spmonth = '0' + spmonth


    for inst in ('HRCI', 'HRCS'):
#
#--- set file names
#
        hrc   = inst + '_'         + smonth  + '_' + syear  + '.fits.gz'
        chrc  = inst + '_08_1999_' + spmonth + '_' + spyear + '.fits'
        chrc2 = inst + '_08_1999_' + smonth  + '_' + syear  + '.fits'
#
#--- check whether the monthly hrc data exist 
#
        cmd  = 'ls ' + web_dir + '/Month_hrc/*gz > ./ztemp'
        os.system(cmd)
        data = open('./ztemp').read()
        os.system('rm ./ztemp')

        m = re.search(hrc, data)
        if m is not None:
#
#---- if the monthly file exists, reduce the size of the file before combine it into a cumulative data
#
            line = web_dir + '/Month_hrc/' + hrc + '[opt type=i4,null=-99]'
            cmd  = 'dmcopy infile="' + line + '"  outfile=ztemp.fits clobber="yes"'
            os.system(cmd)
    
            cmd  = 'dmimgcalc infile=' + web_dir + 'Cumulative_hrc/' + chrc + ' infile2=ztemp.fits outfile =' + chrc2 + ' operation=add clobber=yes'
            os.system(cmd)
            os.system('rm ./ztemp.fits')

            cmd  = 'gzip ' + chrc2
            os.system(cmd)

            cmd  = 'mv ' + chrc2 + '.gz ' + web_dir + 'Cumulative_hrc/.'
            os.system(cmd)
        else:
#
#--- if the monthly fie does not exist, just copy the last month's cumulative data
#
            cmd = 'cp ' + web_dir + 'Cumulative_hrc/' + chrc + ' '  + web_dir + 'Cumulative_hrc/'  + chrc2
            os.system(cmd)



    


#-----------------------------------------------------------------------------------------------------
#--- whichHRC: determine HRC I or HRC S observation from HRC event file                            ---
#-----------------------------------------------------------------------------------------------------

def whichHRC(file):

    'determine HRC I or HRC S observation from HRC event file; input: HRC event file'

    detector = findEntry(file, 'DETNAM')

    return detector

#-----------------------------------------------------------------------------------------------------
#---findEntry: find a value corresponding to a given marker                                         --
#-----------------------------------------------------------------------------------------------------

def findEntry(file, term):

    'find a value corresponding to a given marker in a fits file: input: file name, marker. the file must be an output of dmlist opt=data.'

    val = 'NA'
    cmd = 'dmlist infile=' + file + ' opt=head > zout'
    os.system(cmd)
    f    = open('zout', 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    os.system('rm zout')

    for ent in data:
        m = re.search(term, ent)
        if m is not None:
            atemp = re.split('\s+|\t+', ent)
            val   = atemp[2]
            val.strip()
            break

    return val


#--------------------------------------------------------------------------------------------------------

if __name__ == '__main__':
    
    hrc_dose_get_data(2012,4,2012,4)

