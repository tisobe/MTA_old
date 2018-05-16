#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################################################
#                                                                                                               #
#   extractLimits.py: create limit data table: os_limit_table                                                   #
#                                                                                                               #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                                               #
#                                                                                                               #
#       last update: Jun 27, 2014                                                                               #
#                                                                                                               #
#################################################################################################################

import sys
import os
import string
import re
import copy
import random

#
#--- define a temp file name
#

ztemp = '/tmp/ztemp' + str(random.randint(0,10000))


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
import convertTimeFormat as tcnv

###############################################################################################################
### extractLimit: create a limit data table os_limit_table                                                  ###
###############################################################################################################

def extractLimit(datloc):

    """
    read average and std values of each msid, compute lower and upper limits, and create limit data table
    Input: datloc: the name of the data directory under data_dir
    Output: data_dir/os_limit_table
    """
#
#--- read data set names from data directory
#
    datpass = data_dir + datloc + '/'
    cmd = 'ls ' + datpass +  '* >' +  ztemp
    os.system(cmd)

    f    = open(ztemp, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    cmd = 'rm ' + ztemp
#    os.system(cmd)
#
#--- print header
#
    outfile = data_dir + 'os_limit_table'
    fw   = open(outfile, 'w')
    dtime = tcnv.currentTime('Display')
    line  = '#Last Update: ' + dtime + '\n'
    fw.write(line)
    fw.write('#\t\t\tLower Limit\t\tUpper Limit\t\tGroup\n')
    fw.write('#msid\t\t Red\tYellow\tYellow\tRed\n')
    fw.write('#-------------------------------------------------------\n')

#
#---- start printing limit values
#
    for ent in data:

        print ent
        temp  = re.split(datpass, ent)
        group = temp[1]                                     #---- group ID

        if ent == outfile:                                  #---os_limt_table is in the data directory, too; so ignore it
            pass
        else:
            f     = open(ent, 'r')
            msdat = [line.strip() for line in f.readlines()]
            f.close()
         
            colEnt = re.split('\s+|\t+', msdat[0])
            colLen  = len(colEnt)
            colName = []
#
#--- read msid names
#
            for ent in colEnt:
                if ent != 'std' and ent != '#time':
                    colName.append(ent)

#
#--- read average and std of each msid
#
            lastp = int(colLen/2)
            for k in range(0, lastp+1):
                exec("avg%d = []" % (k))
                exec("sig%d = []" % (k))

            total = 0
            for line in msdat:
                if total == 0:
                    total += 1
                else:
                    atemp    = re.split('\s+|\t+', line)

                    for k in range(1, colLen):
                        k2 = int(k/2)
                        if k % 2 == 0:
                            k2 -= 1
#
#--- the data is occasionally na; if that is the case, use the previous value. if it is the first one, set it to "0"
#
                            try:
                                exec("sig%d.append(float(atemp[%d]))" % (k2, k))
                            except:
                                try:
                                    exec("sig%d.append(sig%d[len(sig%d) -1])" % (k2, k2, k2))
                                except:
                                    exec("sig%d.append(0)" % (k2))
                        else:
                            try:
                                exec("avg%d.append(float(atemp[%d]))" % (k2, k))
                            except:
                                try:
                                    exec("avg%d.append(avg%d[len(avg%d) -1])" % (k2, k2, k2))
                                except:
                                    exec("avg%d.append(0)" % (k2))
                                    

                    total += 1

            total -= 2
            if total > 2:                                   #---- we need at least 4 data points
                fw.write('#\n') 
                for k in range(0, len(colName)):
#
#--- compute limits; as for a deviation, use the average of the past two years
#
                    exec("madd = sig%d[%d] + sig%d[%d] + sig%d[%d] + sig%d[%d]" % (k, total-3, k, total-2, k, total-1, k, total))
                    madd /= 4.0
                    exec("lavg = avg%d[%d]" % (k, total))
    
                    upperYellow = lavg + 4.0 * madd
                    upperRed    = lavg + 5.0 * madd
                    lowerYellow = lavg - 4.0 * madd
                    lowerRed    = lavg - 5.0 * madd
                    if upperYellow == lowerYellow:
                        if lowerYellow == 0:
                            lowerYellow -= 0.01
                            upperYellow += 0.01
                            lowerRed    -= 0.01
                            upperRed    += 0.01
                        else:
                            diff = 0.01 * upperRed
                            lowerYellow -= diff
                            upperYellow += diff
                            lowerRed    -= diff
                            upperRed    += diff
     
                    if len(colName[k]) < 8:
                        line = '%s\t\t%5.3f\t%5.3f\t%5.3f\t%5.3f\t%s\n' % (colName[k], lowerRed, lowerYellow, upperYellow, upperRed, group)
                    else:
                        line = '%s\t%5.3f\t%5.3f\t%5.3f\t%5.3f\t%s\n'   % (colName[k], lowerRed, lowerYellow, upperYellow, upperRed, group)
    
                    fw.write(line)
    
    fw.close()


#----------------------------------------------------------------------------------------------------------------------

if __name__ == "__main__":

    datapass = raw_input("Data Location: ")
    extractLimit(datapass)
