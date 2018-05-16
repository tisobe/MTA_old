#!/usr/bin/env /proj/sot/ska/bin/python

###############################################################################################
#                                                                                             #
#               acis_hst_run_test.py:   runnining acis hist test script                       #
#                                                                                             #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                     #
#                                                                                             #
#               last update: Sept 15, 2014                                                    #
#                                                                                             #
###############################################################################################

import sys
import os
import string
import re
import getpass
import fnmatch
import numpy
import unittest

import random

#
#--- reading directory list
#
path = '/data/mta/Script/ACIS/Acis_hist/house_keeping/dir_list_py'

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

import convertTimeFormat      as tcnv
import mta_common_functions   as mcf
import acis_hist_extract_data as ahed

#-----------------------------------------------------------------------------------------
#-- TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST    ---
#-----------------------------------------------------------------------------------------

class TestFunctions(unittest.TestCase):
    """
    testing functions
    """
#------------------------------------------------------------

    def test_acis_hist_extract_data(self): 
        year = 2012
        month = 12
        out = ahed.acis_hist_extract_data(year, month, comp_test='test')

        test_out = [1452.9225709849709, 42.449043617293398, 51.609088825596601, 357.34525286581425, 19.351044685991486, 27.568468007052722, 1108.7613467924757, 15.231818150975636, 42.799002002367594]

        self.assertEquals(out[0], test_out)

#----------------------------------------------------------------------------------------------------------

if __name__ == '__main__':

    unittest.main()
