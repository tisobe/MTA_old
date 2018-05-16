#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################
#                                                                                       #
#   create_full_focal_plane_data.py: create/update full resolution focal plane data     #
#                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                   #
#                                                                                       #
#           last update: May 16, 2018                                                   #
#                                                                                       #
#########################################################################################

import sys
import os
import string
import re
import numpy
import getopt
import time
import Chandra.Time
import Ska.engarchive.fetch as fetch
import unittest
#
#--- reading directory list
#
path = '/data/mta/Script/ACIS/Focal/Script/house_keeping/dir_list'

f= open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var   = atemp[1].strip()
    line  = atemp[0].strip()

    exec "%s = %s" %(var, line)
#
#--- append path to a private folder
#
sys.path.append(mta_dir)
sys.path.append(bin_dir)

import mta_common_functions as mcf
import convertTimeFormat    as tcnv
#
#--- temp writing file name
#
rtail  = int(time.time())
zspace = '/tmp/zspace' + str(rtail)

#-------------------------------------------------------------------------------
#-- create_full_focal_plane_data: create/update full resolution focal plane data
#-------------------------------------------------------------------------------

def create_full_focal_plane_data():
    """
    create/update full resolution focal plane data
    input:   none, but read from <short_term>/data_*
    output: <data_dir>/full_focal_plane_data
    """
#
#--- read already processed data file names
#
    rfile = house_keeping + 'prev_short_files'
    try:
        rlist = read_file_data(rfile)
        cmd   = 'mv ' +  rfile + ' ' + rfile + '~'
        os.system(cmd)

    except:
        rlist = []
#
#--- read currently available data file names
#
    cmd = 'ls /data/mta/Script/ACIS/Focal/Short_term/data_* > ' + rfile
    #cmd = 'ls ' + short_term + '/data_* > ' + rfile
    os.system(cmd)

    flist = read_file_data(rfile)
#
#--- find un-processed data file names
#
    flist = list(numpy.setdiff1d(flist, rlist))

    start  = 0
    for ifile in flist:
        print "INPUT: " + ifile
#
#---- checking whether the year change occues in this file
#
        [year, chg] = find_year_change(ifile)
        data        = read_file_data(ifile)
#
#--- select unique data
#
        tdict       = {}
        for ent in data:
            atemp = re.split('\s+', ent)
            if len(atemp) < 4:
                continue

            try:
                tdict[atemp[0]] = [atemp[1], atemp[2]]
            except:
                continue

        temp1 = []
        temp2 = []
        for key in tdict.keys():
            [val1, val2] = tdict[key]
#
#--- convert time into Chandra time
#
            try:
                ctime = ptime_to_ctime(year, val1, chg)
            except:
                continue

            if ctime < start:
                continue

            temp1.append(ctime)
            temp2.append(float(val2))
#
#--- sorting lists with time order
#
        if len(temp1) == 0:
            continue

        temp1, temp2 = zip(*sorted(zip(temp1, temp2)))
        temp1 = list(temp1)
        temp2 = list(temp2)
#
#--- keep the last entry to mark the starting point to the next round
#
        start = temp1[-1]
#
#--- find cold plate temperatures
#
        [crat, crbt] = find_cold_plates(temp1)
        
        line = ''
        for k in range(0, len(temp1)):
#
#---- if the focal temp is warmer than -20C or colder than -273, something wrong with the data: drop it
#
            if temp2[k] > -20:
                continue
            elif temp2[k] < -273:
                continue
            elif crat[k] == 999.0:
                continue

            line = line +  "%d\t%4.3f\t%4.3f\t%4.3f\n" % (temp1[k], temp2[k], crat[k], crbt[k])

        outfile  = data_dir + 'full_focal_plane_data_' + str(year)

        if os.path.isfile(outfile):
            fo = open(outfile, 'a')
        else:
            fo = open(outfile, 'w')

        fo.write(line)
        fo.close()

#-------------------------------------------------------------------------------
#-- find_cold_plates: create cold plate temperature data lists corresponding to the given time list
#-------------------------------------------------------------------------------

def find_cold_plates(t_list):
    """
    create cold plate temperature data lists corresponding to the given time list
    input:  t_list  --- a list of time
    output: crat    --- a list of temperature of plate A
            crbt    --- a list of temperature of plate B
    """
#
#--- set data time interval
#
    start = t_list[0]
    stop  = t_list[-1]
#
#--- cold plate A
#
    out   = fetch.MSID('1crat', start, stop)
    tlist = out.times
    alist = out.vals
#
#--- cold plate B
#
    out   = fetch.MSID('1crbt', start, stop)
    blist = out.vals
#
#--- make sure that data have the same numbers of entries
#
    alen  = len(alist)
    blen  = len(blist)
    if alen < blen:
        blist = blist[:alen]
    elif alen > blen:
        for k in range(blen, alen):
            blist.append(blist[-1])
#
#--- find the cold plate temperatures correpond to the given time
#
    crat = []
    crbt = []
    for tent in t_list:
#
#-- take +/- 10 seconds 
#
        begin = tent - 30
        end   = tent + 30

        m     = 0
        chk   = 0
        for k in range(m, alen):
            if (tlist[k] >= begin) and (tlist[k] <= end):
                crat.append(float(alist[k]) - 273.15)
                crbt.append(float(blist[k]) - 273.15)
                m = k - 10
                if m < 0:
                    m = 0
                chk = 1
                break
        if chk == 0:
            crat.append(999.0)
            crbt.append(999.0)

    return [crat, crbt]

#-------------------------------------------------------------------------------
#-- find_year_change: find year of the data and whether the year change occures in this file
#-------------------------------------------------------------------------------

def find_year_change(ifile):
    """
    find year of the data and whether the year change occures in this file
    input:  ifile   --- input file name
                        assume that the ifile has a form of : .../Short_term/data_2017_365_2059_001_0241"
    output: year    --- year of the data
            chk     --- whether the year change occures in this file; 1: yes/ 0: no
    """
    atemp = re.split('\/', ifile)
    btemp = re.split('_', atemp[-1])
    year  = int(float(btemp[1]))

    day1  = int(float(btemp[2]))
    day2  = int(float(btemp[4]))
    if day2 < day1:
        chk = 1
    else: 
        chk = 0

    return [year, chk]

#-------------------------------------------------------------------------------
#-- ptime_to_ctime: convert focal plate time to chandra time                  --
#-------------------------------------------------------------------------------

def ptime_to_ctime(year, atime, chg):
    """
    convert focal plate time to chandra time
    input:  year    --- year of the data
            atime   --- data time in focal data time format:.e.g., 115:1677.850000
            chg     --- indicator that telling that year is changed (if 1)
    output: ctime   --- time in seconds from 1998.1.1
    """
    btemp = re.split(':', atime)
    day   = int(float(btemp[0]))
#
#--- the year changed during this data; so change the year to the next year
#
    if chg > 0:
        if day == 1:
            year += 1

    fday  = float(btemp[1])
    
    fday /= 86400.0
    tmp   = fday * 24.0
    hh    = int(tmp)
    tmp   = (tmp - hh) * 60.0
    mm    = int(tmp)
    ss    = int((tmp - mm) * 60.0)
    
#
#--- add leading zeros
#
    day   = add_leading_zero(day, 3)
    hh    = add_leading_zero(hh,  2)
    mm    = add_leading_zero(mm,  2)
    ss    = add_leading_zero(ss,  2)
    
    yday  = str(year) + ':' + str(day) + ':' + str(hh) + ':' + str(mm) + ':' + str(ss)
    try:
        ctime = Chandra.Time.DateTime(yday).secs
    except:
        ctime = 999.0
    
    return ctime

#-------------------------------------------------------------------------------
#-- add_leading_zero: add leading zero if needed                              --
#-------------------------------------------------------------------------------

def add_leading_zero(val, num):
    """
    add leading zero if needed
    input:  val --- value to modified
    num --- how many digit we need
    output: sval--- adjust val in string
    """
#
#--- how many digit the "val" already has
#
    tval = str(int(val))
    bst  = len(tval)
#
#--- add the leading zero as needed
#
    sval = str(val)
    for k in range(bst, num):
        sval = '0' + sval

    return sval

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

def read_file_data(infile, remove=0):

    f    = open(infile, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    if remove == 1:
        mcf.rm_file(infile)

    return data

#-------------------------------------------------------------------------------
#-- TEST   TEST   TEST   TEST   TEST   TEST   TEST   TEST   TEST   TEST   TEST -
#-------------------------------------------------------------------------------

class TestFunctions(unittest.TestCase):
    """
    testing functions
    """
#-------------------------------------------------------------------------------

    def test_find_cold_plates(self):
        t_list = [638025960, 638243227, 637326500, 638572802]

        testa = [-123.14513244628904, -125.53862609863279, 999.0, -125.53862609863279]
        testb = [-123.14513244628904, -125.53862609863279, 999.0, -123.14513244628904]

        [crat, crbt] = find_cold_plates(t_list)

        self.assertEquals(testa, crat)
        self.assertEquals(testb, crbt)

#        print str(crat)
#        print str(crbt)
#
#        out   = fetch.MSID('1crat', '2018:001:00:00:00', '2018:001:00:10:00')
#        fo    = open('ztest', 'w')
#        data  = out.vals
#        tt    = out.times
#        for k in range(0, len(data)):
#            line = str(tt[k]) + '<-->' + str(data[k]) + '\n'
#            fo.write(line)
#        fo.close()

#-------------------------------------------------------------------------------

    def test_find_year_change(self):

        ifile = '/data/mta/Script/ACIS/Focal/Short_term/data_2017_365_2059_001_0241'

        [year, chg] = find_year_change(ifile)

        self.assertEquals(2017, year)
        self.assertEquals(1,    chg)

#-------------------------------------------------------------------------------

#    def test_add_leading_zero(self):
#
#        out = add_leading_zero(10.121, 2)
#        print out




#-------------------------------------------------------------------------------

if __name__ == "__main__":

    create_full_focal_plane_data()
    #unittest.main()
