#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################
#                                                                                                   #
#       hrc_gain_fit_gaus.py: extract hrc evt2 files and fit a normal distribution on pha values    #
#                                                                                                   #
#           author: t. isobe(tisobe@cfa.harvard.edu)                                                #
#                                                                                                   #
#           Last Update:    May 14, 2014                                                            #
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

import matplotlib as mpl

if __name__ == '__main__':
        mpl.use('Agg')

#
#--- from ska
#
from Ska.Shell import getenv, bash

ascdsenv = getenv('source /home/ascds/.ascrc -r release', shell='tcsh')
#
#--- check whether this is a test case
#
if len(sys.argv) == 2:
    if sys.argv[1] == 'test':   #---- test case
        c_input = 'test'
    elif sys.argv[1] == 'live': #---- automated read in
        c_input = 'live'
    else:
        c_input = sys.argv[1].strip() #---- input data name
else:
    c_input = 'live'
#
#--- reading directory list
#
if c_input == 'test' or c_input == 'test2':
    path = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_py_test'
else:
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

from kapteyn import kmpfit

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
#--- hrc_gain_fit_gaus:  extract hrc evt2 file and create pha distribution                       ---
#---------------------------------------------------------------------------------------------------

def  hrc_gain_fit_gaus(c_input):

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
#--- find median point
#
            med  = find_med(pha_hist)
#
#--- fit a normal distribution on the data
#
            [amp, center, width] = fit_gauss(pha_bin, pha_hist)
#
#--- print out the fitting result
#
            outfile = house_keeping + 'fitting_results'

            copied_file = outfile + '~'
            cmd = 'cp ' + outfile + ' ' + copied_file
            os.system(cmd)

            fo      = open(outfile, 'a')
            line    = str(obsid) + '\t' + date_obs + '\t' + str(tstart) + '\t' + detnam + '\t' + str(ra_pnt) + '\t' + str(dec_pnt) + '\t\t'
            line    = line + str(round(ra_diff,3)) + '\t' + str(round(dec_diff, 3))  + '\t' + str(round(rad_diff,3)) +  '\t' + str(med) + '\t\t'
            line    = line + str(round(center, 3)) + '\t' + str(round(amp, 3)) + '\t' + str(round(width, 3)) + '\t'
            line    = line + str(roll_pnt) + '\t' + str(foc_len) + '\t' + str(defocus) + '\t'
            line    = line + str(sim_x) + '\t' + str(sim_y) + '\t' + str(sim_z) + '\n'
            fo.write(line)
            fo.close()
#
#--- plot the data
#
            outfile = plot_dir + hname + '_gfit.png'
            plot_gauss(pha_bin, pha_hist, amp, center, width, file, outfile)
#
#--- remove the evt2 file
#
            mcf.rm_file(file)

#---------------------------------------------------------------------------------------------------
#-- find_med: find median point of pha postion                                                   ---
#---------------------------------------------------------------------------------------------------

def find_med(x):

    """
    find median point of pha postion
    Input:       x ---  a list of pha counts
    OUtput:     position of the estimated median
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


#---------------------------------------------------------------------------------------------------
#-- fit_gauss: fitting a normal distribution on a given data                                     ---
#---------------------------------------------------------------------------------------------------

def fit_gauss(x, y):

    """
    fitting a normal distribution on a given data
    Input:  x   --- a list of the bin
            y   --- a list of the count
    Output: amp --- amp of the a normal distribution
            cent--- center of the normal distribution
            width--- width of the normal distribution

    """
    nx = numpy.array(x)
    ny = numpy.array(y)
    ne = numpy.ones(len(ny))
#
#--- we need to give an initial guess
#
    ymax = numpy.max(ny)
    med  = find_med(y)
    p0 = [ymax, med, 10, 0]

    fitobj = kmpfit.Fitter(residuals=residualsG, data=(nx,ny,ne))
    fitobj.fit(params0=p0)
    [amp, cent, width, floor] = fitobj.params

    return [amp, cent, width]

#---------------------------------------------------------------------------------------------------
#-- plot_gauss: plotting a fitted result on the data                                             ---
#---------------------------------------------------------------------------------------------------

def plot_gauss(x, y, amp, center, width, name, outfile):

    """
    plotting a fitted result on the data
    Input:      x   ---- a list of bin value
                y   ---- a list of phas
                amp ---- amp of the normal distribution
                center ---- center of the normal distribution
                width  ---- width of the normal distribution
                name   ---- title of the plot
                outfile --- out put file name
    Output:     outfile in <plot_dir>
    """
#
#--- set plotting range
#
    xmin = min(x)
    xmax = max(x) + 1
    ymin = 0
    ymax = int(1.1 * max(y))
#
#--- create Gaussian distribution
#
    p    = (amp, center, width, 0)
    est_v = []
    est_list = []
    for v in range(0, xmax):
        est = funcG(p, v)
        est_v.append(v)
        est_list.append(est)
#
#--- clean up the plotting device
#
    plt.close('all')
#
#---- set a few parameters
#
    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=9)
    
    plt.axis([xmin, xmax, ymin, ymax])
    plt.xlabel('PHA', size=9)
    plt.ylabel('Counts', size=9)
    plt.title(name, size=9)
#
#--- set information text postion and content
#
    tx  = 0.5 * xmax
    ty  = 0.9 * ymax
    line = 'Amp: ' + str(round(amp,2)) + '   Center: ' + str(round(center,2)) + '   Width: ' + str(round(width,2))
    plt.text(tx, ty, line)
#
#--- actual plotting
#
    p, = plt.plot(x, y, marker='.', markersize=4.0, lw = 0)
    p, = plt.plot(est_v, est_list, marker= '', lw=3)
#
#--- set the size of the plotting area in inch (width: 10.0in, height 2.08in x number of panels)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 5.0)
#
#--- save the plot in png format
#
    plt.savefig(outfile, format='png', dpi=100)


#----------------------------------------------------------------------------------
#-- funcG: Model function is a gaussian                                         ---
#----------------------------------------------------------------------------------

def funcG(p, x):
    """
    Model function is a gaussian
    Input:  p   --- (A, mu, sigma, zerolev) 
    x  
    Output: estimated y values
    """
    A, mu, sigma, zerolev = p
    return( A * numpy.exp(-(x-mu)*(x-mu)/(2*sigma*sigma)) + zerolev )

#----------------------------------------------------------------------------------
#-- residualsG: Return weighted residuals of Gauss  ---
#----------------------------------------------------------------------------------

def residualsG(p, data):

    """
    Return weighted residuals of Gauss
    Input:  p --- parameter list (A, mu, sigma, zerolev) see above
    x, y --- data
    Output:  array of residuals
    """
    
    x, y, err = data
    return (y-funcG(p,x)) / err

#--------------------------------------------------------------------

#
#--- pylab plotting routine related modules
#

from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines


if __name__ == '__main__':
#
#--- if this is a test case, prepare the test output directory
#
    hrc_gain_fit_gaus(c_input)

