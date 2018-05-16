#!/usr/bin/env /proj/sot/ska/bin/python

#############################################################################################################################
#                                                                                                                           #
#               hrc_gain_make_table.py: create a html display table of fitting resutls                                      #
#                                                                                                                           #
#               author: t. isobe  (tisobe@cfa.harvard.edu)                                                                  #
#                                                                                                                           #
#               Last Update: May 14, 2014                                                                                   #
#                                                                                                                           #
#############################################################################################################################

import os
import sys
import re
import string
import random
import operator
import numpy
from astropy.table import Table
from Ska.DBI import DBI

comp_test = 'live'
#
#--- reading directory list
#
if comp_test == 'test' or comp_test == 'test2':
    path = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_py_test'
else:
    path = '/data/mta/Script/HRC/Gain/house_keeping/dir_list_py'

f    = open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)

#
#--- append a path to a private folder to python directory
#
sys.path.append(bin_dir)
sys.path.append(mta_dir)
#
#--- converTimeFormat contains MTA time conversion routines
#
import convertTimeFormat    as tcnv
import mta_common_functions as mcf

#
#--- temp writing file name
#

rtail  = int(10000 * random.random())
zspace = '/tmp/zspace' + str(rtail)

#---------------------------------------------------------------------------------------------------
#-- hrc_gain_make_table: create a html display table of fitting resutls                          ---
#---------------------------------------------------------------------------------------------------

def hrc_gain_make_table():

    """
    create a html display table of fitting resutls 
    Input:   none but read from <web_dir>/fitting_resuts
    Outpu   <web_dir>/fitting_results.html
    """

    file = house_keeping + 'fitting_results'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()

    outfile = web_dir + 'fitting_results.html'
    fo      = open(outfile, 'w')

    line = '<!DOCTYPE html>\n'
    line = line + '<html>\n'
    line = line + '<head>\n'
    line = line + '<title> HRC Trending</title>\n'
    line = line + '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n'
    line = line + '<style  type="text/css">\n'
    line = line + 'table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n'
    line = line + 'a:link {color:#00CCFF;}\n'
    line = line + 'a:visited {color:yellow;}\n'
    line = line + '</style>\n'
    line = line + '\n'
    line = line + '<script language="JavaScript">\n'
    line = line + '    function MyWindowOpener(imgname) {\n'
    line = line + '        msgWindow=open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=yes,status=no,width=900,height=500,resize=yes");\n'
    line = line + '        msgWindow.document.close();\n'
    line = line + '        msgWindow.document.write("<html><head><title>Gain plot:"+imgname+"</title></head>");\n'
    line = line + '        msgWindow.document.write("<body bgcolor=\'white\'>");\n'
#    line = line + '        msgWindow.document.write("<img src=\'/mta_days/mta_hrc/Trending/Gain/Plots/"+imgname+"\' border=0 width=800 height=400></body></html>");\n'
    line = line + '        msgWindow.document.write("<img src=\'./Plots/"+imgname+"\' border=0 width=800 height=400></body></html>");\n'
    line = line + '        msgWindow.focus();\n'
    line = line + '    }\n'
    line = line + '</script>\n'
    line = line + '</head>\n'
    line = line + '<body style="color:#FFFFFF;background-color:#000000">\n\n\n'
    line = line + '<h3>HRC Gain Fitting Results</h3>\n'

    fo.write(line)


    line = '<table border=1>\n'
    line = line + '<th>Obsid</th><th>Date</th><th>Detector</th><th>RA Pointing</th><th>Dec Pointing</th>'
    line = line + '<th>RA Offset</th><th>Dec Offset</th><th>Radial Offset</th>'
    line = line + '<th>Median</th><th>Center</th><th>Amp</th><th>FWHM</th>'
    line = line + '</tr>\n'
    fo.write(line)

    for ent in data:
        if ent[0] == '#':
            continue 

        cell = re.split('\s+', ent)

        if len(cell[0]) < 4:
            obsid = '00' + cell[0]
        elif len(cell[0]) < 5:
            obsid = '0' + cell[0]
        else:
            obsid = cell[0]

        rad_dff = float(cell[8])
        if rad_dff < 5:
            color = '#00FF00'
        elif rad_dff >= 10:
            color = '#FF0066'
        else:
            color = '#FF66FF'

        hfile = 'hrcf' + obsid + '_gfit.png'
        line = '<tr><th><a  href="javascript:MyWindowOpener(\'' + hfile + '\')">' + cell[0] + '</a></th>'
        line = line + '<td>' + cell[1] + '</td>'                                    #--- date
        line = line + '<td>' + cell[3] + '</td>'                                    #--- detnam
        line = line + '<td>' + cell[4] + '</td>'                                    #--- ra_pnt
        line = line + '<td>' + cell[5] + '</td>'                                    #--- dec_pnt
        line = line + '<td>' + cell[6] + '</td>'                                    #--- ra_dff
        line = line + '<td>' + cell[7] + '</td>'                                    #--- dec_dff
        line = line + '<td style="color:' + color + '">' + cell[8] + '</td>'        #--- rad_dff
        line = line + '<td>' + cell[9] + '</td>'                                    #--- median
        line = line + '<td>' + cell[10] + '</td>'                                   #--- center
        line = line + '<td>' + cell[11] + '</td>'                                   #--- amp
        line = line + '<td>' + cell[12] + '</td>'                                   #--- width
        line = line + '</tr>\n'
        fo.write(line)

    line = '</table>\n'
    line = line + '</body>\n'
    line = line + '</html>\n'
    fo.write(line)

    fo.close()
    
#--------------------------------------------------------------------

if __name__ == '__main__':
    hrc_gain_make_table()


