#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################################
#                                                                                                                   #
#               update_solor_wind_data.py: update soloar wind data                                                  #
#                                                                                                                   #
#                   author: t. isobe (tisobe@cfa.harvard.edu)                                                       #
#                                                                                                                   #
#                    Last update: Dec 11, 2014                                                                      #
#                                                                                                                   #
#       http://www.swpc.noaa.gov/wingkp/wingkp_list.txt (USAF 15-minute Wing Kp Geomagnetic Activity Index)         #
#                                                                                                                   #
#                           1-hour         1-hour                    4-hour         4-hour                          #
# UT Date   Time         Predicted Time  Predicted  Lead-time     Predicted Time  Predicted  Lead-time   USAF Est.  #
# YR MO DA  HHMM   S     YR MO DA  HHMM    Index    in Minutes    YR MO DA  HHMM    Index    in Minutes     Kp      #
#                                                                                                                   #
# Units: Predicted Index 0-9 in Kp units                                                                            #
# Status(S): 0 = nominal solar wind input data,                                                                     #
#            1 = data are good but required an extrapolation                                                        #
#            2 = data are bad: incomplete ACE speed data                                                            #
#            3 = data are bad: solar wind speed input errors; model output likely unreliable                        #
#            4 = missing Wing Kp data                                                                               #
# Solar Wind Source: ACE Satellite.  Wing Kp data provided by USAF AFWA.                                            #
# The value -1 in the report indicates bad data (data status 2 and 3) or missing data (data status 4).              #
#                                                                                                                   #
#####################################################################################################################


import os
import sys
import re
import string
import random
import operator
import math
import numpy
import unittest
import urllib2
 
path = '/data/mta/Script/Ephem/house_keeping/dir_list_py'

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

#
#--- temp writing file name
#
rtail  = int(10000 * random.random())       #---- put a romdom # tail so that it won't mix up with other scripts space
zspace = '/tmp/zspace' + str(rtail)


#-------------------------------------------------------------------------------------------
#-- wingkp_data: update the soloar wind data by getting data from noaa site              ---
#-------------------------------------------------------------------------------------------

def wingkp_data():
    """
    update the soloar wind data by getting data from noaa site
    input:  none, but read from <dataflie>
    output: updated <datafile>
    """

#
#--- define a ccouple of file names
#
    datafile = data_dir + '/solar_wind_data.txt'
#    url      = 'http://www.swpc.noaa.gov/wingkp/wingkp_list.txt'
    url      = 'http://services.swpc.noaa.gov/text/wing-kp.txt'
#
#--- read the last line of the current data
#--- and find the last entry date
#
    cmd      = 'tail -n 1 ' + datafile
    line     = os.popen(cmd).read()
    atemp    = re.split('\s+', line)
    tstamp   = atemp[0] + atemp[1] + atemp[2] + atemp[3]
    tstamp   = float(tstamp)
#
#--- read the data from given url
#
    newdata  = download_web_page(url)
#
#--- append the new data part to the data
#
    fo = open(datafile, 'a')
    for ent in newdata:
        if ent == '':
            continue
        if ent[0] == '#' or ent[0] == ':':
            continue
#
#--- make sure that the line start from numeric entry (year, such as 2014)
#
        try:
            atemp = re.split('\s+', ent)
            chk   = float(atemp[0])
        except:
            continue

        time  = atemp[0] + atemp[1] + atemp[2] + atemp[3]
        time  = float(time)

        if time > tstamp:
            line = ent + '\n'
            fo.write(line)

    fo.close()


#-------------------------------------------------------------------------------------------
#-- download_web_page: download the web page and create a list of each line              ---
#-------------------------------------------------------------------------------------------

def download_web_page(url):

    """
    download the web page and create a list of each line
    input:  url     --- url of the page
    output: html    --- a list of each line
    """

    web  = urllib2.urlopen(url)
    data = web.read()
    html = re.split('\n+', data)
    f.close()

    return html


#-------------------------------------------------------------------------------------------

if __name__ == "__main__":

     wingkp_data()
