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
import operator
import math
import numpy
import astropy.io.fits  as pyfits
import unittest

#
#--- from ska
#
from Ska.Shell import getenv, bash

ascdsenv = getenv('source /home/ascds/.ascrc -r release', shell='tcsh')
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
import convertTimeFormat          as tcnv       #---- contains MTA time conversion routines
import mta_common_functions       as mcf        #---- contains other functions commonly used in MTA scripts
import hrc_gain_find_ar_lac       as arlist     #---- get AR Lac candidate list
import fit_voigt_profile          as voigt

from scipy.special import wofz
from kapteyn import kmpfit
ln2 = numpy.log(2)

#
#--- temp writing file name
#
rtail  = int(10000 * random.random())       #---- put a romdom # tail so that it won't mix up with other scripts space
zspace = '/tmp/zspace' + str(rtail)
#
#--- a couple of things needed
#
dare   = mcf.get_val('.dare',   dir = bdata_dir, lst=1)
hakama = mcf.get_val('.hakama', dir = bdata_dir, lst=1)

working_dir = exc_dir + '/Working_dir/'

#
#--- AR Lac position
#
ra  = 332.179975
dec = 45.7422544

#---------------------------------------------------------------------------------------------------
#--- hrc_gain_fit_voigt:  extract hrc evt2 file and create pha distribution                      ---
#---------------------------------------------------------------------------------------------------

def  hrc_gain_fit_voigt(candidate_list):

    """
    extract hrc evt2 file, find the brightest object and create pha distribution
    Input:  candidate_list      --- if it is obsid, use it as a input
                            otherwise, a list of new candidates will be create based database
    Output: <header>_pha.dat    --- pha distribution data
            <header>_gfit.png   --- a plot of pha data
            fitting_results     --- a table of fitted results
    """
#
#--- keep the results in save_line
#
    save_line = ''
#
#--- if an obsid is provided, analyize that, else get new obsids from databases
#
    if len(candidate_list) > 0:
        for obsid in candidate_list:
            file = extract_hrc_evt2(obsid)
            if file == 'na':
                continue
#
#--- get a file name header for the later use
#
            temp  = re.split('N', file)
            hname = temp[0]
#
#--- extract information from the fits file header
#
            [obsid, detnam, date_obs, date_end, tstart, tstop, ra_pnt, dec_pnt,  ra_nom, dec_nom, roll_pnt, foc_len, defocus, sim_x, sim_y, sim_z]  = find_header_info(file)
#
#--- find the diffrence between real AR Lac position and nominal postion so that we can determin how much area we should include 
#
            ra_diff  = abs(ra - ra_nom) * 60.0
            dec_diff = abs(dec - dec_nom) * 60.0
            rad_diff = math.sqrt(ra_diff * ra_diff + dec_diff * dec_diff)

            if rad_diff < 10.0:
                fit_rad = 60.0
            else:
                fit_rad = 200.0
#
#--- find a location of the brightest object (assume it is AR Lac) in sky coordinates
#
            [x, y] = find_center(file)
#
#--- extract pha values in the given area
#
            pha = extract_pha(file, x, y, fit_rad)
#
#--- create pha count distribution
#
            pmax = max(pha) + 1
            pha_bin  = [x for x in range(0, pmax)]
            pha_hist = [0 for x in range(0, pmax)]

            for ent in pha:
                pha_hist[ent] += 1
#
#--- print out the distirbution results
#
            outfile = data_dir + hname + '_pha.dat'
            fo = open(outfile, 'w')
            for i in range(0, pmax):
                line = str(pha_bin[i]) + '\t' + str(pha_hist[i]) + '\n'
                fo.write(line)
            fo.close()
#
#--- gzip file 
#
            cmd = 'gzip ' + outfile
            os.system(cmd)
#
#--- find median point
#
            med  = find_med(pha_hist)
#
#--- fit a voigt distribution on the data
#
            [center, width, amp, alphaD, alphaL, I, a_back, b_back] = voigt.fit_voigt_profile(pha_bin, pha_hist, type='voigt', plot_title=file)
#
#--- rename a plotting file
#            
            outfile = plot_dir + hname + '_gfit.png'
            cmd     = 'mv out.png ' + outfile
            os.system(cmd)

            line    = str(obsid) + '\t' + date_obs + '\t' + str(tstart) + '\t' + detnam + '\t' + str(ra_pnt) + '\t' + str(dec_pnt) + '\t\t'
            line    = line + str(round(ra_diff,3)) + '\t' + str(round(dec_diff, 3))  + '\t' + str(round(rad_diff,3)) +  '\t' + str(med) + '\t\t'
            line    = line + str(round(center, 3)) + '\t' + str(round(amp, 3)) + '\t' + str(round(width, 3)) + '\t'
            line    = line + str(roll_pnt) + '\t' + str(foc_len) + '\t' + str(defocus) + '\t'
            line    = line + str(sim_x) + '\t' + str(sim_y) + '\t' + str(sim_z) + '\t'
            line    = line + str(round(alphaD,4)) + '\t' + str(round(alphaL,4)) + '\t' + str(round(center,3)) + '\t' + str(round(I,2)) + '\t' + str(round(a_back,2)) + '\t' + str(round(b_back,2)) + '\n'

            save_line = save_line + line
#
#--- remove the evt2 file
#
            mcf.rm_file(file)
#
#--- if there is any new data, print it out
#
    if save_line != '':
#
#--- print out the fitting result
#
#        outfile = house_keeping + 'fitting_results'

        copied_file = outfile + '~'
        cmd = 'cp ' + outfile + ' ' + copied_file
        os.system(cmd)
    
        fo = open(outfile, 'a')
        fo.write(save_line)
        fo.close()

#---------------------------------------------------------------------------------------------------
#-- find_med: find median point of pha postion                                                   ---
#---------------------------------------------------------------------------------------------------

def find_med(x):

    """
    find median point of pha postion
    Input:   x ---  a list of pha counts
    OUtput: position of the estimated median
    """
    
    total = 0
    for ent in x:
        total += ent
    
    half = int(0.5 * total)
    sum =  0
    for i in range(0, len(x)):
        sum += x[i]
        if sum > half:
            pos = i
            break
    
    return i - 1


#---------------------------------------------------------------------------------------------------
#--- extract_hrc_evt2: extract hrc evt2 file                                                     ---
#---------------------------------------------------------------------------------------------------

def extract_hrc_evt2(obsid):

    """
    extract hrc evt2 file 
    Input: obsid    --- obsid of the data
    Output: hrcf<obsid>*evt2.fits.gz
            file name if the data is extracted. if not 'na'
    """
#
#--- write  required arc4gl command
#
    line = 'operation=retrieve\n'
    line = line + 'dataset=flight\n'
    line = line + 'detector=hrc\n'
    line = line + 'level=2\n'
    line = line + 'filetype=evt2\n'
    line = line + 'obsid=' + str(obsid) + '\n'
    line = line + 'go\n'
    f    = open(zspace, 'w')
    f.write(line)
    f.close()

    cmd1 = "/usr/bin/env PERL5LIB="
    cmd2 =  ' echo ' +  hakama + ' |arc4gl -U' + dare + ' -Sarcocc -i' + zspace
    cmd  = cmd1 + cmd2

#
#--- run arc4gl
#
    bash(cmd,  env=ascdsenv)
    mcf.rm_file(zspace)
#
#--- check the data is actually extracted
#
    cmd  = 'ls *'+ str(obsid) + '*evt2.fits.gz >' + zspace
    os.system(cmd)
    f    = open(zspace, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    mcf.rm_file(zspace)

#    data = ['hrcf02451N005_evt2.fits.gz']
    if len(data) > 0:
        os.system('gzip -d *.gz')
        file = data[0]
        file = file.replace('.gz', '')
        return file
    else:
        return 'na'


#---------------------------------------------------------------------------------------------------
#-- find_header_info: find fits file header information                                          ---
#---------------------------------------------------------------------------------------------------

def find_header_info(file):

    """
    find fits file header information
    Input:      file --- input fits file name
    Output:     [obsid, detnam, date_obs, date_end, tstart, tstop, ra_pnt, dec_pnt,  ra_nom, dec_nom, roll_pnt, foc_len, defocus, sim_x, sim_y, sim_z]
    """

    hdr      = pyfits.getheader(file, 1)
    obsid    = hdr['OBS_ID']
    detnam   = hdr['DETNAM']
    date_obs = hdr['DATE-OBS']
    date_end = hdr['DATE-END']
    tstart   = hdr['TSTART']
    tstop    = hdr['TSTOP']
    ra_pnt   = hdr['RA_PNT']
    dec_pnt  = hdr['DEC_PNT']
    roll_pnt = hdr['ROLL_PNT']
    defocus  = hdr['DEFOCUS']
    foc_len  = hdr['FOC_LEN']
    ra_nom   = hdr['RA_NOM']
    dec_nom  = hdr['DEC_NOM']
    sim_x    = hdr['SIM_X']
    sim_y    = hdr['SIM_Y']
    sim_z    = hdr['SIM_Z']

    return [obsid, detnam, date_obs, date_end, tstart, tstop, ra_pnt, dec_pnt,  ra_nom, dec_nom, roll_pnt, foc_len, defocus, sim_x, sim_y, sim_z]

#---------------------------------------------------------------------------------------------------
#--- find_center: find the brightest object position from the given event file                   ---
#---------------------------------------------------------------------------------------------------

def find_center(file):

    """
    find the brightest object position from the given event file
    Input:      file    ---- evnt2 fits file
    Ouput:      xv, yv  ---- sky coordinates of the brightest object
    """

    data = pyfits.getdata(file)
    chipx = data.field('X')
    chipy = data.field('Y')
#
#--- because the array is too large to handle in one swipe, divide it into 8x8 segments
#
    xmin   = min(chipx)
    ymin   = min(chipy)
    xmax   = max(chipx)
    ymax   = max(chipy)
    xstep  = int((xmax-xmin) / 8 )
    ystep  = int((ymax-ymin) / 8 )
#
#--- find  the interval which contains largest samples 
#
    cposx = 0
    cposy = 0
    cmax  = 0
    for i in range (0, 8):
        xstart = xstep * i + xmin
        xstop  = xstart + xstep
        for j in range (0, 8):
            ystart = ystep * j + ymin
            ystop  = ystart + ystep

            mask = (data.field('X') >= xstart) & (data.field('X') < xstop) & (data.field('Y') >= ystart) & (data.field('Y') < ystop)
            temp = data[mask]
            chipx_p = temp.field('X')
            chipy_p = temp.field('Y')
            if len(chipx_p) > cmax:
                cmax = len(chipx_p)
                cposx = i
                cposy = j
#
#--- extract the area of the highest count
#
    xpos_list = []
    ypos_list = []
    maxv_list = []
    xstart = xstep * cposx + xmin
    xstop  = xstart + xstep

    ystart = ystep * cposy + ymin
    ystop  = ystart + ystep

    mask = (data.field('X') >= xstart) & (data.field('X') < xstop) & (data.field('Y') >= ystart) & (data.field('Y') < ystop)
    temp = data[mask]
    chipx_p = temp.field('X')
    chipy_p = temp.field('Y')
#
#--- count up the events. bin to 2x2 so that we get enough count in each bin
#
    xmin = min(chipx_p)
    xmax = max(chipx_p)
    xdim = int(0.5 * (xmax - xmin)) + 1
    ymin = min(chipy_p)
    ymax = max(chipy_p)
    ydim = int(0.5 * (ymax - ymin)) + 1

    cbin = [[0 for y in range(0, ydim)] for x in range(0, xdim)]
    for j in range(0, len(chipy_p)):
        xpos = int(0.5 * (chipx_p[j]-xmin))
        ypos = int(0.5 * (chipy_p[j]-ymin))
        cbin[xpos][ypos] += 1
#
#--- now find max position
#
    vmax = 0
    xx   = 0
    yy   = 0
    for m in range(0, xdim):
        for n in range(0, ydim):
            if cbin[m][n] > vmax:
                vmax = cbin[m][n]
                xx = m
                yy = n
#
#--- take the mddle of the bin as the brightest spot
#
    xv = int(xx * 2.0 + 1.0  + xmin)
    yv = int(yy * 2.0 + 1.0  + ymin)

    return [xv, yv]


#---------------------------------------------------------------------------------------------------
#--- extract_pha: extract pha data for a given area                                             ----
#---------------------------------------------------------------------------------------------------

def extract_pha(file, x, y, range):

    """
    extract pha data for a given area
    Input:  x, y    ---- the center sky coordinates of the area to extract
            range   ---- size of the area +/- x or y
    Outpu:  pha     ---- a list of pha
    """

    xmin = x - range
    xmax = x + range
    ymin = y - range
    ymax = y + range

    data = pyfits.getdata(file)
    mask = (data.field('X') >= xmin) & (data.field('X') < xmax) & (data.field('Y') >= ymin) & (data.field('Y') < ymax)
    area = data[mask]

    pha  = area.field('PHA')
    pha  = map(int, pha)

    return pha

#-----------------------------------------------------------------------------------------
#-- TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST    ---
#-----------------------------------------------------------------------------------------

class TestFunctions(unittest.TestCase):

    """
    testing functions
    """

#------------------------------------------------------------
    def test_find_header_info(self):

        file     = 'hrcf14313N001_evt2.fits'
        results  = find_header_info(file)

        test_results = ['14313', 'HRC-I', '2012-09-27T09:06:31', '2012-09-27T09:31:42', 465123991.90959, 465125502.24717, 332.06915986593, 45.81410073141, 332.06915986593, 45.81410073141, 222.08677687529, 10070.0, 0.0014262644205751, -1.0388663562383, 0.0, 126.98297998999]

        self.assertEquals(results, test_results)

        mcf.rm_file(file)

#------------------------------------------------------------

    def test_find_center(self):

        file     = 'hrcf14313N001_evt2.fits'

        position = find_center(file)

        test_position = [14459, 14428]
        self.assertEquals(position, test_position)

#------------------------------------------------------------

    def test_extract_pha(self):

        file    = 'hrcf14313N001_evt2.fits'
        [x, y]  = [14459, 14428]
        fit_rad = 60

        pha = extract_pha(file, x, y, fit_rad)
        self.assertEquals(max(pha), 229)

#------------------------------------------------------------

    def test_extract_hrc_evt2(self):

        obsid = '14313'

        file  = extract_hrc_evt2(obsid)
        self.assertEquals(file, 'hrcf14313N001_evt2.fits')

#--------------------------------------------------------------------

if __name__ == '__main__':

    unittest.main()


