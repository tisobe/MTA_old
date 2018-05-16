#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################################################
#                                                                                                               #
#   createLimitTable.py: create a table of averages over a given intevals from a fits file                      #
#                                                                                                               #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                                               #
#                                                                                                               #
#       last update: Jun 26, 2014                                                                               #
#                                                                                                               #
#################################################################################################################

import sys
import os
import string
import re
import fnmatch
import numpy
import pyfits
import math

#
#--- reading directory list
#

path = '/data/mta/Script/Limit_table/house_keeping/dir_list'
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
import convertTimeFormat    as tcnv
import mta_common_functions as mcf


###############################################################################################################
### createLimitTable: create a table of averages over tspan intevals from a fits file                      ####
###############################################################################################################

def createLimitTable(file, tspan, outloc):

    """
    this function is a control script which call a function creates table of averages over tspan intervals of each column
    and print them out.
    input:  file (fits file)
            tspan: time period which the average is taken. it must be in unit of seconds 
            (3 months: 7889400, 6 month: 15778800)
            outloc: output directory
    output: ascii table of averages and standard deviations
    """
    m1    = re.search('/data/mta4/Deriv/grad', file)
    if m1 is not None:
        outName = createTable2(file, tspan, outloc)
    else:
        outName = createTable(file, tspan, outloc)

    return outName

###############################################################################################################
### createTable: create a table of averages over tspan intevals from a fits file                           ####
###############################################################################################################

def createTable(file, tspan, outloc):

    """
    this function read a fits file and create table of averages over tspan intervals of each column
    and print them out.
    input:  file (fits file)
            tspan: time period which the average is taken. it must be in unit of seconds 
            outloc: output directory
    output: ascii table of averages and standard deviations
    """
#
#--- create an output file and open for writing
#
    outName = makeOutFileName(file)
    outPath = data_dir + outloc + '/' +  outName
    f = open(outPath, 'w')
#
#--- read fits file contents
#
    fdata    = pyfits.open(file)
    fbdata   =  fdata[1].data
    colNames = fdata[1].columns.names            #---- column names
    colLen   = len(colNames)                     #---- column length

#
#--- find "time" column position
#
    tpos = findTimeCol(colNames)

#
#--- print column names
#
    f.write('#time')
    for k in range(0, colLen):
        if k == tpos:
            pass
        else:
            m = re.search('_avg', colNames[k].lower())
            if m is not None:
                temp = colNames[k].lower().replace('_avg','')
            else:
                temp = colNames[k].lower().replace('_av','')

            if temp[0] == '_':
                temp = temp[1:]

#            temp = temp.replace('_', '')
            line = '\t%s\tstd' % (temp)
            f.write(line)

    f.write('\n')
#
#--- check each line until data runs out
#
    tot      = 0.0
    timeSum  = 0                                    #---- time span 
    dataSum  = [0 for x in range(colLen)]           #---- an array to save the sam of the values
    dataSum2 = [0 for x in range(colLen)]           #---- an array to save the sam of the value**2
    tbdata   = fbdata[0]
    dataSave = []
#    begining = tbdata[tpos]                         #---- start time of the interval
    begining = 63071999.0                           #---- start time of the interval Jan 1, 2000

    for tbdata in fbdata:
#
#--- the data occasionally have "NaN", and try:  line = '%6d\t' % (tbdata[tpos]) is a good way to skip the line
#
        if tbdata[tpos] > 63071999.0:
#            line = '%6d\t' % (tbdata[tpos])         

            if timeSum <= tspan:                     #---- time span in seconds, if less than that, keep accumurating
                try:
                    for k in range(0, colLen):
                        dataSum[k]  += tbdata[k]
                        dataSum2[k] += tbdata[k] * tbdata[k]

                    timeSum = tbdata[tpos] - begining
                    dataSave.append(tbdata)
                    tot += 1.0
                except:
                    pass
            else:
#
#--- if the data are accumurated for tspan, compute averate and standard deviation, and print them out
#
                line = '%6d\t' % (tbdata[tpos])
                f.write(line)
     
#
#--- go through again and drop an extreme outlyer
#
                for k in range(0, colLen):
                    if k == tpos:
                        pass
                    else:
                        davg = dataSum[k] / tot
                        dstd = math.sqrt(abs(dataSum2[k] / tot - davg * davg))
                        if dstd == 0:
                            dstd = 1

                        bot  = davg - 3.0 * dstd 
                        top  = davg + 3.0 * dstd 
                        sum1 = 0
                        sum2 = 0
                        scnt = 0
                        for lent in dataSave:
                            try:
                                int(lent[k])
                                if lent[k] > bot and lent[k] < top:
                                    sum1 += lent[k]
                                    sum2 += lent[k] * lent[k]
                                    scnt += 1
                            except:
                                pass
                        if scnt > 0:
                            davg = sum1 / scnt
                            dstd = math.sqrt(abs(sum2 / scnt - davg * davg))

                            line = '%3.4f\t%3.4f\t' % (davg, dstd)
                            f.write(line)
                        else:
                            f.write('na\tna\t')

                f.write("\n")

                tot      = 0.0
                timeSum  = 0
                dataSum  = [0 for x in range(colLen)]
                dataSum2 = [0 for x in range(colLen)]
                begining = tbdata[tpos]
                dataSave = []

    f.close()
    return outName

###############################################################################################################
### createTable2: create a table of averages over tspan intevals from a fits file for grad data            ####
###############################################################################################################

def createTable2(file, tspan, outloc):

    """
    this function read a fits file and create table of averages over tspan intervals of each column
    and print them out. Since gradablk.fits uses DOM for date, we need to handle differently.
    input:  file (fits file)
            tspan: time period which the average is taken. it must be in unit of seconds 
            outloc: output directory
    output: ascii table of averages and standard deviations
    """
#
#--- convert time span into the unit of day
#
    tdspan = tspan / 86400
#
#--- create an output file and open for writing
#
    outName = makeOutFileName(file)
    outPath = data_dir + outloc + '/' +  outName
    f = open(outPath, 'w')
#
#--- read fits file contents
#
    fdata    = pyfits.open(file)
    fbdata   =  fdata[1].data
    colNames = fdata[1].columns.names            #---- column names
    colLen   = len(colNames)                     #---- column length

#
#--- find "time" column position
#
    tpos = findTimeCol(colNames)

#
#--- print column names
#
    f.write('#time')
    for k in range(0, colLen):
        if k == tpos:
            pass
        else:
            temp = colNames[k].lower()
            m1   = re.search('dev', temp)
            if m1 is not None:
                f.write('\tstd')
            else:
                temp = colNames[k].lower().replace('_avg','')
                line = '\t%s' % (temp)
                f.write(line)

    f.write('\n')
#
#--- check each line until data runs out
#
    tot      = 0.0
    timeSum  = 0                                    #---- time span 
    dataSum  = [0 for x in range(colLen)]           #---- an array to save the sam of the values
    dataSum2 = [0 for x in range(colLen)]           #---- an array to save the sam of the values
    tbdata   = fbdata[0]
    dataSave = []
#    begining = tbdata[tpos]                        #---- start time of the interval
    begining = 366                                  #---- start time of the interval Jan 1, 2000

    for tbdata in fbdata:
#
#--- the data occasionally have "NaN", and try:  line = '%6d\t' % (tbdata[tpos]) is a good way to skip the line
#
        try:
            if tbdata[tpos] > 365.0:
                stime = tbdata[tpos] * 86400                #---- a day in second
                line = '%6d\t' % (stime)         

                if timeSum <=  tdspan:                     #---- time sapn in day, if less than that, keep accumurating
                    for k in range(0, colLen):
                            if tbdata[k] != -99.0:
                                dataSum[k]  += tbdata[k]
                                dataSum2[k] += tbdata[k] * tbdata[k]
     
                    timeSum = tbdata[tpos] - begining
                    dataSave.append(tbdata)
                    if tbdata[k] != -99.0:
                        tot += 1.0
                else:
#
#--- if the data are accumurated for tspan, compute averate and standard deviation, and print them out
#
                    stime = tbdata[tpos] * 86400 
                    line = '%6d\t' % (stime)
                    f.write(line)
     
                    for k in range(0, colLen):
                        if k == tpos:
                            pass
                        else:
                            davg = dataSum[k] / tot
                            dstd = math.sqrt(abs(dataSum2[k] / tot - davg * davg))

                            bot = davg - 3.0 * dstd
                            top = davg + 3.0 * dstd
                            sum1 = 0
                            sum2 = 0
                            scnt = 0
                            for lent in dataSave:
                                try:
                                    int(lent[k])
                                    if int(lent[k]) != -99 and lent[k] > bot and lent[k] < top:
                                        sum1 += lent[k]
                                        sum2 += lent[k] * lent[k]
                                        scnt += 1

                                except:
                                    pass
                            if scnt > 0:
                                davg = sum1/scnt
                                line = '%3.4f\t' % (davg)
                                f.write(line)
                            else:
                                f.write('na\tna\t')
    
                    f.write("\n")
    
                    tot      = 0.0
                    timeSum  = 0
                    dataSum  = [0 for x in range(colLen)]
                    dataSum2 = [0 for x in range(colLen)]
                    begining = tbdata[tpos]
                    dataSave = []
        except:
            pass


    f.close()
    return outName

###############################################################################################################
### makeOutFileName: isolate msid category from fits file name                                              ###
###############################################################################################################

def makeOutFileName(file):

    """
    isolate msid category from fits file name.
    example: /mta/.../aciseleca.fits to aciseleca
    input:  fits file name (with a full path)
    output: name
    """
#
#--- create an output file
#
    m1    = re.search('\/', file)
    if m1 is not None:
        atemp = re.split('\/', file)
        btemp = atemp[len(atemp)-1]
    else:
        btemp = file

    m1    = re.search('fits.gz', btemp)
    m2    = re.search('fits',    btemp)

    if m1 is not None:
        ctemp = re.split('\.fits.gz', btemp)
        return ctemp[0]
    elif m2 is not None:
        ctemp = re.split('\.fits',    btemp)
        return ctemp[0]
    else:
        return btemp


###############################################################################################################
### findTimeCol: find time column position                                                                 ####
###############################################################################################################

def findTimeCol(colNames):

    """
    find time column position 
    input:  a list of column Names
    output: a position of time columumn in int
    """

#
#--- find "time" column position
#
    tpos = 0
    for nam in colNames:
        if nam.lower() == 'time':
            break

        tpos += 1

    return tpos

#---------------------------------------------------------------------------------------------

if __name__ == "__main__":

    f = open('/data/mta/Script/Limit_table/house_keeping/data_list', 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    file = raw_input('Fits File Name: ')
    createLimitTable(file, 15778800, 'Data/')
