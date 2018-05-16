#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################################################
#                                                                                                               #
#   limitTableHtmlGen.py: create html pages to display trend plots under each group                             #
#                                                                                                               #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                           #
#                                                                                                               #
#           last update: Jun 27, 2014                                                                           #
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
import mta_common_functions as mcf

###############################################################################################################
### createGroupHtmlPage: create html pages to display trend plots under each group                          ###
###############################################################################################################

def createGroupHtmlPage():

    """
    create html pages to display trend plots under each group
    input: none, but it will create plot lists from plot_dir
    output: html_dir/limit_trend.html and plot_dir/<gourp name>.html
    """

#
#--- read group names
#
    cmd = 'ls -d ' + plot_dir + '* >' + ztemp
    os.system(cmd)

    f     = open(ztemp, 'r')
    dlist = [line.strip() for line in f.readlines()]
    f.close()
    cmd = 'rm ' + ztemp
    os.system(cmd)

#
#--- create/update the top html page
#
    out_name1 = html_dir +  'limit_trend.html'
    fo = open(out_name1, 'w')

    line = '<!DOCTYPE html>\n<html>\n'
    fo.write(line)
    line = '<head>\n<title>MTA Trending Page</title>\n'
    fo.write(line)
    line  = "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n"
    fo.write(line)
    line = '<link rel="stylesheet" type="text/css" href="/mta/REPORTS/Template/mta_monthly.css" />\n\n'
#    line = '<link rel="stylesheet" type="text/css" href="/data/mta4/www/REPORTS/Template/mta_monthly.css" />\n\n'
    fo.write(line)

    line = '<style  type="text/css">\n'
    fo.write(line)
    line = 'table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n'
    fo.write(line)
    line = 'td{text-align:center;padding:8px}\n'
    fo.write(line)
    line = '</style>\n'
    fo.write(line)

    line = '</head>\n<body>\n\n'
    fo.write(line)
    line = '<h2 style="padding-bottom:20px">MTA Trending</h2>\n\n'
    fo.write(line)

    line = '<p style="padding-bottom:15px">The following pages show three trending plots of MSID values for each subsystem '
    fo.write(line)
    line = 'as they have evolved over the course of the mission.'
    fo.write(line)

    line = 'The left plot is MTA Trends/Derivatives Plot. For more details, please go to <a href="http://cxc.cfa.harvard.edu/mta/DAILY/mta_deriv/">MTA Trends/Derivatives</a> page. '
    fo.write(line)
    line = 'The center plot is MTA Envelope Trending. For more detials, please go to <a href="http://asc.harvard.edu/mta_days/mta_envelope_trend/">MTA Trending: Envelope Trending</a> page. '
    fo.write(line)

    line = 'The right plot is history of upper and lower limits of each msid for monitoring and trending purposes. These limits are, however, not used prior to XXX of 2012. \n'
    fo.write(line)
    line = 'The limits of each MSID are created as following:</p>\n'
    fo.write(line)
    line = '<ul>\n'
    fo.write(line)
    line = '<li>The average and standard deviation of each MSID are computed for 6 month periods for the entire period.</li>\n'
    fo.write(line)
    line = '<li>The standard deviations (but not average) are further smoothed by taking past 2 year moving averages. \n'
    fo.write(line)
    line = '(For example, the value given for January 2003 is the average of the 6 month averages from January 2001 to January 2003.)</li>\n'
    fo.write(line)
    line = '<li><em style="color:yellow">Yellow lines</em> are set at the center value (the average) plus or minus 4 standard deviation aways.</li>\n'
    fo.write(line)
    line = '<li><em style="color:red">Red lines</em> are set at the center value (the average) plus or minus 5 standard deviation aways.</li>\n'
    fo.write(line)
    line = '<li>Most recent 6 month values of each MSID are taken as MTA Limits.</li>\n'
    line = '</ul>'
    fo.write(line)

    line = '<p style="padding-top:10px;padding-bottom:25px">You can find the most recent MTA limit table at <a href="./Data/os_limit_table" target="blank">MTA Limit Table</a></p>.\n'
    fo.write(line)







#
#--- check each group
#
    line = '<h2 style="padding-bottom:20px">MTA Trending Plots</h2>\n\n'
    fo.write(line)

    line = '<p>The following table lists three trend plots of each msid in the named groups. To see the plots, '
    fo.write(line)
    line = 'please click the group name. It will open the trend plot page of the group.</p> '
    fo.write(line)

    line = '<p>The top panel of the trending plot shows thedata and its trend and the bottom panel shows the deviation. '
    fo.write(line)
    line = 'If you click the plot, you can enlarge the plot.</p> ' 
    fo.write(line)

    line = '<p>A green line of the envelope plot is a moving average of the data and blue lines are estimated outer limits of the data range. '
    fo.write(line)
    line = 'If the data points are  colored in magenda, the data points are in yellow limits, and if they are in red, they are in red limits.</p>'
    fo.write(line)

    line = '<p style="padding-bottom:40px">In each limit  plot, the blue line indicates the (moving) average of the value of the msid, the yellow lines indicate lower and '
    fo.write(line)
    line = 'upper yellow limits, and red lines indicate lower and upper red limits. '
    fo.write(line)
    line = 'Note that if the plotting range of the limit plot is smaller than 1, it plots with fractinal value and shows the base '
    fo.write(line)
    line = 'value to add to convert back the original range.\n\n'
    fo.write(line)


    line ='<div><table border=1>\n'
    fo.write(line)

    ecnt = 0
    for group in dlist:
        m1 = re.search('.html', group)                  #---- ignore the name ends with "html"
        if m1 is None:
            temp  = re.split(plot_dir, group)
            gname = temp[1]
#
#--- create indivisual html pages
#
#            out_name1 =  group + '.html'
            out_name1 =  './Plots/' + gname + '.html'           #----   THIS IS THE LIVE ONE !!!!!!
###            out_name1 =  './Plots_test/' + gname + '.html'
    
            if ecnt == 0:
                fo.write('<tr>\n')

            line = '<td><a href="' + out_name1 + '">' + gname + '</a></td>\n'       #--- add line to the top html page
            fo.write(line)
#
#--- 4 entries per raw
#
            if ecnt > 2:
                ecnt = 0
                line = '</tr>\n'
                fo.write(line)
            else:
                ecnt += 1
#
#--- creating a html page for each group
#
            out_name2 = html_dir + out_name1
            fo2 = open(out_name2, 'w')
    
            line = '<!DOCTYPE html>\n<html>\n<head>\n<title>' + gname + '</title>\n'
            line = line + "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n"
            line = line + '<link rel="stylesheet" type="text/css" href="http://asc.harvard.edu/mta/REPORTS/Template/mta.css" />\n'
            line = line + '<script>\n'
            line = line + 'function WindowOpener(imgname) {\n'
            line = line + '    msgWindow = open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=720,height=550,resize=no");\n'
            line = line + '    msgWindow.document.clear();\n'
            line = line + '    msgWindow.document.write("<html><title>Trend plot:   "+imgname+"</title>");\n'
            line = line + '    msgWindow.document.write("<body bgcolor=\'black\'>");\n'
            line = line + '    msgWindow.document.write("<img src=\'http://cxc.cfa.harvard.edu/mta/DAILY/mta_deriv/"+imgname+"\' border=0 width=720 height=550><P></body></html>")\n'
            line = line + '    msgWindow.document.close();\n'
            line = line + '    msgWindow.focus();\n'
            line = line + '}\n'
            line = line + 'function WindowOpener2(imgname) {\n'
            line = line + '    msgWindow = open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=720,height=570,resize=no");\n'
            line = line + '    msgWindow.document.clear();\n'
            line = line + '    msgWindow.document.write("<html><title>Envelope plot:   "+imgname+"</title>");\n'
            line = line + '    msgWindow.document.write("<body bgcolor=\'black\'>");\n'
            line = line + '    msgWindow.document.write("<img src=\'http://cxc.cfa.harvard.edu/mta_days/mta_envelope_trend/Full_range/"+imgname+"\' border=0 width=720 height=550><P></body></html>")\n'
            line = line + '    msgWindow.document.close();\n'
            line = line + '    msgWindow.focus();\n'
            line = line + '}\n'
            line = line + '</script>\n'

            line = line + '</head>\n<body>\n\n'
            fo2.write(line)
            line = '<h2> Group: ' + gname  + '</h2>\n\n'
            fo2.write(line)
            line = '<a href="http://cxc.cfa.harvard.edu/mta_days/mta_limit_table/"><strong>Back To The Main Page</strong></a><br /><br />'
            fo2.write(line)

            line = '<h3 style="padding-top:15px;padding-bottom:15px">Data Table: <a href="' + data_dir + gname + '">' + gname + '</a></h3>\n\n'
#
#--- find out plot names
#
            cmd  = 'ls ' + group + '/* >' + ztemp 
            os.system(cmd)
            f     = open(ztemp, 'r')
            plist = [line.strip() for line in f.readlines()]
            f.close()
            cmd = 'rm ' + ztemp
            os.system(cmd)
    
#
#--- create a table with plots:  three column format
#
##            line = '<table style="padding-top:30px;border-width:0px;border-spacing:10px">\n'
            line = '<table style="border-width:0px">\n'
            fo2.write(line)
    
            j = 0
            tot = len(plist)
            for ent in plist:

                m2 = re.search('png', ent)
                if m2 is not None:
                    temp  = re.split(group, ent)
                    pname = temp[1]
#
#--- trending plot 
#
                    oname = pname.replace('/', '')
                    oname = oname.replace('.png', '_avgA.gif')
                    try:
                        n = int(oname[0])
                        oname = '_' + oname
                    except:
                        pass

                    ptitle = oname.replace('_avgA.gif', '')
                    ptitle = ptitle.upper()
                    line = '<tr><th style="font-size:140%;text-align:left" colspan=3>' + ptitle + '</th></tr>\n'
                    fo2.write(line)
                    line = '<tr><th>Trending Plot</th><th>Envelope Plot</th><th>Limit Plot</tr>\n'
                    fo2.write(line)
#
#--- envelope plot
#
                    ename = pname.replace('/', '')
                    ename = ename.replace('.png', '_plot.gif')
                    if ename[0] == '_':
                        ename = ename[1:]

                    pdir  = gname.upper()
                    try:
                        n = int(pdir[len(pdir)-1])
                        pdir = pdir[:-1]
                    except:
                        pass
                            
                    m1 = re.search('2A', pdir);
                    m2 = re.search('2B', pdir);
                    if m1 is not None or m2 is not None:
                        pdir = 'SPCELECA'

                    jline = '<a href="javascript:WindowOpener(\'' + oname + '\')">'

                    line = '<tr><td style="text-align:center">'

                    ftest = mcf.chkFile('/data/mta4/www/DAILY/mta_deriv/',oname)

                    if ftest > 0:
                        line = line + jline + '<img src="http://cxc.cfa.harvard.edu/mta/DAILY/mta_deriv/' + oname + '" alt="' + oname + '"  style="width:450px" ></a><br />\n' 
                        line = line + jline + '<strong style="padding-right:10px">Enlarge Trend Plot</strong></a>\n</td>\n'
                    else:
                        line = line + '<td style="background-color:black"><img src="http://cxc.cfa.harvard.edu/mta_days/mta_limit_table/no_data.png" alt="no data"  style="width:500px"></td>\n'

                    ftest = mcf.chkFile('/data/mta/www/mta_envelope_trend/Full_range/', pdir)
                    if ftest > 0:
                        line = line + '<td><img src="http://cxc.cfa.harvard.edu/mta_days/mta_envelope_trend/Full_range/' + pdir + '/Plots/'  + ename + '"  alt="' + ename + '" style="width:500px"></td>\n'
                    else:
                        line = line + '<td style="background-color:black"><img src="http://cxc.cfa.harvard.edu/mta_days/mta_limit_table/no_data.png" alt="no data" style="width:500px"></td>\n'

                    line = line + '<td><img src="./' + gname + '/' + pname + '" alt ="' + pname + '" style="width:500px"></td></tr>\n'
                    
                    fo2.write(line)
     
            line = '</table>\n'
            fo2.write(line)
            line = '<a href="http://cxc.cfa.harvard.edu/mta_days/mta_limit_table/" style="padding-top:20px"><strong>Back To The Main Page</strong></a><br /><br />'
            fo2.write(line)
            line = '</body>\n</html>\n'
            fo2.write(line)
     
            fo2.close()

    if ecnt == 0:
        line = '</table></div>\n</div>\n<div style="padding-top:20px;padding-bottom:10px">\n<hr />\n</div>\n'
        fo.write(line)
    else:
        for k in range(ecnt, 4):
            line = '<td>&#160;</td>'
            fo.write(line)

        line = '</tr>\n</table></div>\n<div style="padding-top:20px;padding-bottom:10px">\n<hr />\n</div>\n'
        fo.write(line)

#
#--- Today's date 
#
    dtime = tcnv.currentTime('Display')

    line = 'Last Update: ' + dtime
    fo.write(line)
    line = '<p style="padding-top:10px">If you have any questions about this page, please contact <a href="mailto:isobe@head.cfa.harvard.edu">isobe@head.cfa.harvard.edu</a>.</p>'
    fo.write(line)

    line = '</body>\n</html>\n'
    fo.write(line)
    fo.close()



#----------------------------------------------------------------------------------------------------------------------

if __name__ == "__main__":

    createGroupHtmlPage()
