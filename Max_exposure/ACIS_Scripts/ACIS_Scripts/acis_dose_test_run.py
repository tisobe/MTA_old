#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################
#                                                                                       #
#       acis_dose_test_run.py: this script check whether ska shell works correctly      #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last updated: May 21, 2015                                                      #
#                                                                                       #
#########################################################################################

import sys
import os
import string
import re

#
#--- from ska
#
from Ska.Shell import getenv, bash
ascdsenv  = getenv('source /home/ascds/.ascrc -r release', shell='tcsh')

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

#
#--- a couple of things needed
#
dare   = mtac.get_val('.dare',   dir = bindata_dir, lst=1)
hakama = mtac.get_val('.hakama', dir = bindata_dir, lst=1)


#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------

def acis_dose_test_run():

    """
    test ska shell access
    """

    start = '05/07/15,00:00:00'
    stop  = '05/15/15,00:00:00'

    line = 'operation=browse\n'
    line = line + 'dataset=flight\n'
    line = line + 'detector=acis\n'
    line = line + 'level=1\n'
    line = line + 'filetype=evt1\n'
    line = line + 'tstart=' + start + '\n'
    line = line + 'tstop=' +  stop  + '\n'
    line = line + 'go\n'
    f    = open('./zspace', 'w')
    f.write(line)
    f.close()

    cmd1 = "/usr/bin/env PERL5LIB="
    cmd2 =  ' echo ' +  hakama + ' |arc4gl -U' + dare + ' -Sarcocc -i./zspace > ./zout'
    cmd  = cmd1 + cmd2
    bash(cmd,  env=ascdsenv)
    mtac.rm_file('./zspace')

    f    = open('./zout', 'r')
    fitsList = [line.strip() for line in f.readlines()]
    f.close()
    mtac.rm_file('./zout')

    for ent in fitsList:
        print ent


#--------------------------------------------------------------------------------------------------------

if __name__ == '__main__':
    
    acis_dose_test_run()


