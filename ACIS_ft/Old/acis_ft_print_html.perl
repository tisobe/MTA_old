#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_ft_print_html.perl: printing html pages					#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Apr. 15, 2013							#
#											#
#########################################################################################

#
#--- check whether this is a test
#
$comp_test = $ARGV[0];
chomp $comp_test;

#######################################################################################
#
#---- diretory setting
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
    }
close(FH);
#######################################################################################

#
#--- find today's date
#
if($comp_test =~ /test/i){
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= (0, 0, 0, 24, 1, 113, 1, 56, 0);
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
}

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}
$month = $umon + 1;
#$uyday++;

if ($uyear == 1999) {
        $dom = $uyday - 202 + 1;
}elsif($uyear >= 2000){
        $dom = $uyday + 163 + 1 + 365*($uyear - 2000);
#
#---- add an extra day after a leap year
#
	$add_date += int(0.25 * ($year - 1997));
	$dom += $add_date;
}
#
#--- the main focal plane temperature html page
#
open(OUT, ">$web_dir/main_fp_temp.html");

$utoday = $uyday + 1;

print OUT "<!DOCTYPE html>\n";
print OUT " \n";
print OUT "<html> \n";
print OUT "<head> \n";
print OUT "        <meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT "        <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css\" /> \n";
print OUT "        <style  type='text/css'>\n";
print OUT "        table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "        td{text-align:center;padding:8px}\n";
print OUT "        </style>\n";

print OUT "        <title> ACIS Focal Plane Temperature Plots </title> \n";
print OUT " \n";
print OUT "        <script> \n";
print OUT "                function WindowOpener(imgname) { \n";
print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=660,height=560,resize=no\"); \n";
print OUT "                        msgWindow.document.clear(); \n";
print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
print OUT "                        msgWindow.document.write(\"<body bgcolor='black'>\"); \n";
print OUT "                        msgWindow.document.write(\"<img src='./Figs/\"+imgname+\"' border =0 ><p></p></body></html>\") \n";
print OUT "                        msgWindow.document.close(); \n";
print OUT "                        msgWindow.focus(); \n";
print OUT "                } \n";
print OUT "        </script> \n";
print OUT " \n";
print OUT "</head> \n";
print OUT "<body> \n";
print OUT "<h1>ACIS Focal Plane Temperature</h1> \n";
print OUT " \n";
print OUT "<h3 style='text-align:right'>Updated: $uyear-$month-$umday (DOY: $utoday / DOM: $dom)</h3> \n";
print OUT " \n";
print OUT "<hr /> \n";
print OUT " \n";
print OUT "<img src=\"./Figs/month_plot.gif\" width=\"500\" height=\"400\" style=\"text-align:center;display:block;margin-left:auto;margin-right:auto;padding-top:20px;padding-bottom:30px\" alt='Month long Focal Plane Temperature Plot'> \n";
print OUT " \n";
print OUT "<table  style='border-width:0px'> \n";
print OUT "<tr> \n";
print OUT "<th>&#160;</th><th>Focal Plane Temp</th><th colspan=2>(Focal Plane Temp - Cold Radiator)</th><th>Data</th> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>Entire Mission</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('fp_temp.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('entire_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('entire_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/long_term_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>Past 3 Months</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month3_plot.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month3_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month3_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/month_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>Past Month</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month_plot.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('month_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/month_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>Past Week</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('week_plot.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('week_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('week_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/week_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>Last 3 Days</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day3_plot.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day3_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day3_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/week_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "<tr> \n";
print OUT "<th>One Day</th> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day_plot.gif')\">Temp Plot</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day_side_a.gif')\">Side A</a></td> \n";
print OUT "<td><a href=\"javascript:WindowOpener('day_side_b.gif')\">Side B</a></td> \n";
print OUT "<td><a href=\"./Data/week_data\" target=\"_blank\">Data</a></td> \n";
print OUT "</tr> \n";
print OUT "</table> \n";
print OUT " \n";
print OUT " \n";
print OUT "<p style=\"padding-top:30px;color=yellow;font-size:90%\"><em> \n";
 print OUT "<strong>Note:</strong> Due to instrumental problems, the focal temperature values taken between dates 2005:259.5 and 2005:289.5 are not reliable. \n";
print OUT "</em> </p> \n";
print OUT " \n";
print OUT "<hr /> \n";
print OUT "<p> \n";
print OUT "If you have any questions about this page, please contact \n";
print OUT "<a href=\"mailto:swolk\@head.cfa.harvard.edu\">swolk\@head.chfa.harvard.edu</a> \n";
print OUT "</p> \n";
print OUT "</body> \n";
print OUT "</html> \n";


close(OUT);

