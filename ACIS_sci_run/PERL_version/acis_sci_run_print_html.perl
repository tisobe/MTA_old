#!/usr/bin/perl

#########################################################################################
#											#
#	acis_sci_run_print_html.perl: print a html page for acis science run web page	#
#											#
#	Author:	Takashi Isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Sep 27, 2012  							#
#											#
#########################################################################################


#######	checking today's date #######


($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}
$month = $umon + 1;

if ($uyear == 1999) {
        $dom = $uyday - 202;
}elsif($uyear >= 2000){
        $dom = $uyday + 163 + 365*($uyear - 2000);
        if($uyear > 2000) {
                $dom++;
        }
        if($uyear > 2004) {
                $dom++;
        }
        if($uyear > 2008) {
                $dom++;
        }
        if($uyear > 2012) {
                $dom++;
        }
        if($uyear > 2016) {
                $dom++;
        }
        if($uyear > 2020) {
                $dom++;
        }
}

#
#--- fix so that the month day start from 1 not from 0
#

$uyday++;

#############################################
#---------- set directries-------------

$dir_list = '/data/mta/Script/ACIS/Acis_sci_run/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

$current_dir  = 'Year'."$uyear";                        #--- seting a current output directory

$http_dir     = 'http://asc.harvard.edu/mta_days/mta_acis_sci_run/';
#
#############################################

###### creating a main page #######

open(OUT, ">$root_dir/science_run.html");

print OUT "<!DOCTYPE html> \n";
print OUT " \n";
print OUT "<html> \n";
print OUT "<head> \n";
print OUT "	   <meta http-equiv='Content-Type' content='text/html; charset=utf-8' /> \n";
print OUT "        <link rel=\"stylesheet\" type=\"text/css\" href=\"http://asc.harvard.edu/mta/REPORTS/Template/mta.css\" /> \n";
print OUT "        <style  type='text/css'>\n";
print OUT "        table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "        td{text-align:center;padding:8px}\n";
print OUT "        </style>\n";


print OUT "        <title> ACIS Science Run</title> \n";
print OUT " \n";
print OUT "        <script> \n";
print OUT "                function WindowOpener(imgname) { \n";
print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=1100,height=800,resize=no\"); \n";
print OUT "                        msgWindow.document.clear(); \n";
print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
print OUT "                        msgWindow.document.write(\"<body bgcolor='white'>\"); \n";
print OUT "                        msgWindow.document.write(\"<img src='./\"+imgname+\"' border =0 ><p></p></body></html>\") \n";
print OUT "                        msgWindow.document.close(); \n";
print OUT "                        msgWindow.focus(); \n";
print OUT "                } \n";
print OUT "        </script> \n";
print OUT " \n";
print OUT "</head> \n";
print OUT "<body  style='background-image:url(\"http://asc.harvard.edu/mta_days/mta_aiming/stars.jpg\")'> \n";


print OUT '<h2 style="text-align:center">ACIS Science Run</h2>',"\n";

print OUT '<h2 style="text-align:center">Updated: ';
print OUT "$uyear-$month-$umday  ";
print OUT "(DOY: $uyday / DOM: $dom)\n ";
print OUT '</h2>';
print OUT "\n";

print OUT '<hr />',"\n";


print OUT '<p>',"\n";
print OUT 'Data plotted here are taken from psi processing log ',"\n";
print OUT "(<a href='http://acis.mit.edu/acs'>http://acis.mit.edu/acs</a>). There are three plots in \n";
print OUT 'each FEP mode:',"\n";
print OUT '</p>';
#print OUT '<p>';
print OUT "<table style='border-width:0px;padding-left:60px'> \n";
print OUT '<tr><td>Top:</td><td style="text-align:left"> evnets per second for each science run</td></tr>',"\n";
print OUT '<tr><td>Middle:</td><td style="text-align:left"> numbers of errors reported by psi per ksec for each science run</td></tr>',"\n";
print OUT '<tr><td>Bottom:</td><td style="text-align:left"> Percentage of exposures dropped for each science run</td></tr>',"\n";
print OUT '</table>',"\n";
#print OUT '</p>',"\n";
print OUT '<p>';
print OUT "For more  details, plese go to <a href='http://acis.mit.edu/acs'>mit web site</a>. \n";
print OUT '</p>';


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr><td> \n";
print OUT '<h2> Plots by FEP Mode </h2>',"\n";
print OUT "</td><td> \n";
print OUT "<h2>Data</h2> \n";
print OUT "</td></tr> \n";
print OUT "<tr><td> \n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr>',"\n";
print OUT '<th>This Year</th>',"\n";
print OUT "<td><a href=\"javascript:WindowOpener('Year$uyear/te3_3_out.gif')\"> TE 3X3 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('Year$uyear/te5_5_out.gif')\"> TE 5X5 </a></td> \n";
#print OUT "<td><a href=\"javascript:WindowOpener('Year$uyear/te_raw_out.gif')\"> TE Raw </a></td> \n";
print OUT "<td>  --- </td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('Year$uyear/cc3_3_out.gif')\"> CC 3X3 </a></td> \n";
print OUT '</tr>',"\n";
print OUT '<tr><th>Entire Period</th>',"\n";
print OUT "<td><a href=\"javascript:WindowOpener('Long_term/long_term_te3_3.gif')\"> TE 3X3 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('Long_term/long_term_te5_5.gif')\"> TE 5X5 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('Long_term/long_term_te_raw.gif')\"> TE Raw </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('Long_term/long_term_cc3_3.gif')\"> CC 3X3 </a></td> \n";
print OUT '</tr></table>',"\n";

print OUT "</td><td>\n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/data',"$uyear",' target="_blank">DATA Plotted (ASCII format)</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/drop_',"$uyear".' target="_blank">Te3x3 DATA with Dropped Rate &gt; 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/drop_5x5_',"$uyear".' target="_blank">Te5x5 DATA with Dropped Rate &gt; 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_event_',"$uyear".' target="_blank">Te3x3 DATA with Event Rate &gt; 180 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_event5x5_',"$uyear".' target="_blank">Te5x5 DATA with Event Rate &gt; 56 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_error_',"$uyear".' target="_blank">Te3x3 DATA with Error # &gt; 1 cnt/ksec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_error5x5_',"$uyear".' target="_blank">Te5x5 DATA with Error # > &gt; cnt/ksec</a></td></tr>',"\n";
print OUT '</table>',"\n";

print OUT "</td></tr> \n";
print OUT "</table> \n";

print OUT '<br>',"\n";
print OUT '<hr />',"\n";

print OUT '<h2>Plots/Data for Each Year </h2>',"\n";
print OUT "<table style='border-width:0px'> \n";
print OUT "<tr> \n";
$j = 0;
for($iyear = 1999; $iyear <= $uyear; $iyear++){
	print OUT "<td> ";
	print OUT '<a href=',"$http_dir",'/Year';
	print OUT "$iyear",'/science_run',"$iyear".'.html><strong>Year ',"$iyear",'</strong></a><br>';
	print OUT "</td> \n";
	if($j == 5){
		$j = 0;
		print OUT "</tr><tr>\n";
	}else{
		$j++;
	}
}
print OUT "</tr></table> \n";
print OUT "<p> \n";
print OUT '<strong><a href=',"$http_dir",'Long_term/science_long_term.html>Entire Period</a></strong>',"\n";
print OUT "</p> \n";

print OUT '<hr />',"\n";
print OUT "<p>\n  <em><strong>\n";
print OUT "If you have any questions about this page, please contact <a href='mailto:swolk\@head.cfa.harvard.edu'>swolk\@head.cfa.harvard.edu</a>\n";
print OUT "</strong></em>\n </p>\n";


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr> \n";
print OUT "<th style='width:10%;text-align:center'>Go to: </th> \n";
print OUT "<th style='width:30%;text-align:center'> \n";
print OUT '<a href=http://acis.mit.edu/asc>Acis Science Run, MIT site</a>',"\n";
print OUT "</th> \n";
#print OUT "<th style='width:30%;text-align:center'> \n";
#print OUT '<a href=http://asc.harvard.edu/mta_days/mta_acis_sci_run/science_run.html>Main Page</a>',"\n";
#print OUT "</th> \n";
print OUT "<th style='width:30%;text-aling:center'> \n";
print OUT '<a href=http://asc.harvard.edu/mta/sot.html>SOT page</a>';
print OUT "</th> \n";
print OUT "</table> \n";
#print OUT "</p> \n";
close(OUT);


#######################################################################################
#######------- a similar page as above but for specifically for Year $uyear directory
#######################################################################################

$h_name = "$root_dir/".'Year'."$uyear".'/science_run'."$uyear".'.html';

open(OUT, ">$h_name");

print OUT "<!DOCTYPE html> \n";
print OUT " \n";
print OUT "<html>\n";
print OUT "<head> \n";
print OUT "        <meta http-equiv='Content-Type' content='text/html; charset=utf-8' /> \n";
print OUT '        <link rel="stylesheet" type="text/css" href="http://asc.harvard.edu/mta/REPORTS/Template/mta.css" />', " \n";
print OUT "        <style  type='text/css'> \n";
print OUT "        table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate} \n";
print OUT "        td{text-align:center;padding:8px} \n";
print OUT "        </style> \n";
print OUT "        <title>Science Run Year: $uyear </title> \n";

print OUT " \n";
print OUT "        <script> \n";
print OUT "                function WindowOpener(imgname) { \n";
print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=1100,height=800,resize=no\"); \n";
print OUT "                        msgWindow.document.clear(); \n";
print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
print OUT "                        msgWindow.document.write(\"<body bgcolor='white'>\"); \n";
print OUT "                        msgWindow.document.write(\"<img src='./\"+imgname+\"' border =0 ><p></p></body></html>\") \n";
print OUT "                        msgWindow.document.close(); \n";
print OUT "                        msgWindow.focus(); \n";
print OUT "                } \n";
print OUT "        </script> \n";
print OUT " \n";
print OUT "</head> \n";
print OUT "<body style='background-image:url(\"http://asc.harvard.edu/mta_days/mta_aiming/stars.jpg\")'> \n";


print OUT '<h2 style="text-align:center">ACIS Science Run: Year', " $uyear", '</h2>',"\n";

print OUT '<h2 style="text-align:center">Updated: ';
print OUT "$uyear-$month-$umday  ";
print OUT "(DOY: $uyday / DOM: $dom)\n ";
print OUT '</h2>';
print OUT "\n";

print OUT '<hr />',"\n";


print OUT '<p>Data plotted here are taken from psi processing log ',"\n";
print OUT "(<a href='http://acis.mit.edu/acs'>http://acis.mit.edu/acs</a>). There are three plots in \n";
print OUT 'each FEP mode:',"\n";
print OUT '</p>';
#print OUT '<p>';
print OUT "<table style='border-width:0px;padding-left:60px'> \n";
print OUT '<tr><td>Top:</td><td style="text-align:left"> evnets per second for each science run</td></tr>',"\n";
print OUT '<tr><td>Middle:</td><td style="text-align:left"> numbers of errors reported by psi per ksec for each science run</td></tr>',"\n";
print OUT '<tr><td>Bottom:</td><td style="text-align:left"> Percentage of exposures dropped for each science run</td></tr>',"\n";
print OUT '</table>',"\n";
#print OUT '</p>';
print OUT '<p>';
print OUT "For more  details, plese go to <a href='http://acis.mit.edu/acs'>mit web site</a>. \n";
print OUT '</p>';


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr><td> \n";
print OUT '<h2> Plots by FEP Mode </h2>',"\n";
print OUT "</td><td> \n";
print OUT "<h2>Data</h2> \n";
print OUT "</td></tr> \n";
print OUT "<tr><td> \n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr>',"\n";
print OUT '<th>This Year</th>',"\n";
print OUT "<td><a href=\"javascript:WindowOpener('te3_3_out.gif')\"> TE 3X3 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('te5_5_out.gif')\"> TE 5X5 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('te_raw_out.gif')\"> TE Raw </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('cc3_3_out.gif')\"> CC 3X3 </a></td> \n";
print OUT '</tr>',"\n";
print OUT '</table>',"\n";

print OUT "</td><td>\n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/data',"$uyear",' target="_blank">DATA Plotted (ASCII format)</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/drop_',"$uyear".' target="_blank">Te3x3 DATA with Dropped Rate > 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/drop_5x5_',"$uyear".' target="_blank">Te5x5 DATA with Dropped Rate > 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_event_',"$uyear".' target="_blank">Te3x3 DATA with Event Rate > 180 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_event5x5_',"$uyear".' target="_blank">Te5x5 DATA with Event Rate > 56 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_error_',"$uyear".' target="_blank">Te3x3 DATA with Error # > 1 cnt/ksec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/$current_dir",'/high_error5x5_',"$uyear".' target="_blank">Te5x5 DATA with Error # > 1 cnt/ksec</a></td></tr>',"\n";
print OUT '</table>',"\n";

print OUT "</td></tr> \n";
print OUT "</table> \n";

print OUT '<br>',"\n";


print OUT '<hr />',"\n";

print OUT "<p>\n  <em><strong>\n";
print OUT "If you have any questions about this page, please contact <a href='mailto:swolk\@head.cfa.harvard.edu'>swolk\@head.cfa.harvard.edu</a>\n";
print OUT "</strong></em>\n </p>\n";


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr> \n";
print OUT "<th style='width:30%;text-align:center'>Go to: </th> \n";
print OUT "<th style='width:30%;text-align:center'> \n";
print OUT '<a href=http://acis.mit.edu/asc>Acis Science Run, MIT site</a>',"\n";
print OUT "</th> \n";
print OUT "<th style='width:30%;text-align:center'> \n";
print OUT '<a href=http://asc.harvard.edu/mta_days/mta_acis_sci_run/science_run.html>Main Page</a>',"\n";
print OUT "</th> \n";
print OUT "<th style='width:30%;text-aling:center'> \n";
print OUT '<a href=http://asc.harvard.edu/mta/sot.html>SOT page</a>';
print OUT "</th> \n";
print OUT "</table> \n";
#print OUT "</p> \n";

close(OUT);


###################################################################################
#######------- a similar page as above but for specifically for Long term directory
###################################################################################

$h_name = "$root_dir".'/Long_term/science_long_term.html';
open(OUT, ">$h_name");

print OUT "<!DOCTYPE html> \n";
print OUT " \n";
print OUT "<html> \n";
print OUT "<head> \n";
print OUT "	   <meta http-equiv='Content-Type' content='text/html; charset=utf-8' /> \n";
print OUT '        <link rel=\"stylesheet\" type=\"text/css\" href=\"http://asc.harvard.edu/mta/REPORTS/Template/mta.css\" />'," \n";
print OUT "        <style  type='text/css'> \n";
print OUT "        table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate} \n";
print OUT "        td{text-align:center;padding:8px} \n";
print OUT "        </style> \n";

print OUT "        <title> ACIS Science Run: Entire Period</title> \n";
print OUT " \n";
print OUT "        <script> \n";
print OUT "                function WindowOpener(imgname) { \n";
print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=1100,height=800,resize=no\"); \n";
print OUT "                        msgWindow.document.clear(); \n";
print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
print OUT "                        msgWindow.document.write(\"<body bgcolor='white'>\"); \n";
print OUT "                        msgWindow.document.write(\"<img src='./\"+imgname+\"' border =0 ><p></p></body></html>\") \n";
print OUT "                        msgWindow.document.close(); \n";
print OUT "                        msgWindow.focus(); \n";
print OUT "                } \n";
print OUT "        </script> \n";
print OUT " \n";
print OUT "</head> \n";
print OUT "<body style='background-image:url(\"http://asc.harvard.edu/mta_days/mta_aiming/stars.jpg\")'> \n";


print OUT '<h2 style="text-align:center">ACIS Science Run: Entire Period</h2>',"\n";

print OUT '<h2 style="text-align:center">Updated: ';
print OUT "$uyear-$month-$umday  ";
print OUT "(DOY: $uyday / DOM: $dom)\n ";
print OUT '</h2>';
print OUT "\n";

print OUT '<hr />',"\n";

print OUT '<p>',"\n";
print OUT 'Data plotted here are taken from psi processing log ',"\n";
print OUT "(<a href='http://acis.mit.edu/acs'>http://acis.mit.edu/acs</a>). There are three plots in \n";
print OUT 'each FEP mode:',"\n";
print OUT '</p>';
print OUT '<p>';
print OUT "<table style='border-width:0px;padding-left:60px'> \n";
print OUT '<tr><td>Top:</td><td style="text-align:left"> evnets per second for each science run</td></tr>',"\n";
print OUT '<tr><td>Middle:</td><td style="text-align:left"> numbers of errors reported by psi per ksec for each science run</td></tr>',"\n";
print OUT '<tr><td>Bottom:</td><td style="text-align:left"> Percentage of exposures dropped for each science run</td></tr>',"\n";
print OUT '</table>',"\n";
print OUT '</p>';
print OUT '<p>';
print OUT "For more  details, plese go to <a href='http://acis.mit.edu/acs'>mit web site</a>. \n";
print OUT '</p>';


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr><td> \n";
print OUT '<h2> Plots by FEP Mode </h2>',"\n";
print OUT "</td><td> \n";
print OUT "<h2>Data</h2> \n";
print OUT "</td></tr> \n";
print OUT "<tr><td> \n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr>',"\n";
print OUT '<th>Entire Period</th>',"\n";
print OUT "<td><a href=\"javascript:WindowOpener('long_term_te3_3.gif')\"> TE 3X3 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('long_term_te5_5.gif')\"> TE 5X5 </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('long_term_te_raw.gif')\"> TE Raw </a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('long_term_cc3_3.gif')\"> CC 3X3 </a></td> \n";
print OUT '</tr></table>',"\n";

print OUT "</td><td>\n";


print OUT "<table style='border-width:0px'>\n";
print OUT '<tr><td><a href=',"$http_dir/Long_term",'/data target="_blank">DATA Plotted (ASCII format)</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/drop target="_blank">Te3x3 DATA with Dropped Rate > 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/drop_5x5 target="_blank">Te5x5 DATA with Dropped Rate > 3 %</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/high_event target="_blank">Te3x3 DATA with Event Rate > 180 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/high_event5x5 target="_blank">Te5x5 DATA with Event Rate > 56 cnt/sec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/high_error target="_blank">Te3x3 DATA with Error # > 1 cnt/ksec</a></td></tr>',"\n";

print OUT '<tr><td><a href=',"$http_dir/Long_term",'/high_error5x5 target="_blank">Te5x5 DATA with Error # > 1 cnt/ksec</a></td></tr>',"\n";
print OUT '</table>',"\n";

print OUT "</td></tr> \n";
print OUT "</table> \n";

print OUT '<br>',"\n";


print OUT '<hr />',"\n";
print OUT "<p>\n  <em><strong>\n";
print OUT "If you have any questions about this page, please contact <a href='mailto:swolk\@head.cfa.harvard.edu'>swolk\@head.cfa.harvard.edu</a>\n";
print OUT "</strong></em>\n </p>\n";


print OUT "<table style='border-width:0px'> \n";
print OUT "<tr> \n";
print OUT "<th style='width:10%;text-align:center'>Go to: </th> \n";
print OUT "<th style='width:30%;text-align:center'> \n";
print OUT '<a href=http://acis.mit.edu/asc>Acis Science Run, MIT site</a>',"\n";
print OUT "</th> \n";
print OUT "<th style='width:30%;text-align:center'> \n";
print OUT '<a href=http://asc.harvard.edu/mta_days/mta_acis_sci_run/science_run.html>Main Page</a>',"\n";
print OUT "</th> \n";
print OUT "<th  style='width:30%;text-aling:center'> \n";
print OUT '<a href=http://asc.harvard.edu/mta/sot.html>SOT page</a>';
print OUT "</th> \n";
print OUT "</table> \n";
print OUT "</p> \n";

close(OUT);

