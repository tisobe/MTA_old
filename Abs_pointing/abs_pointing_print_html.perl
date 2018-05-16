#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	print_html.perl: print a html page for coordinate accuracy web		#
#										#
#	Author:	Takashi Isobe (tisobe@cfa.harvard.edu)				#
#										#
#	Sep 20, 2000:	First version						#
#	Mar 22, 2006:	a new directory system					#
#	Jun 24, 2010:   format updated						#
#	Mar 16, 2011:	directry path updated					#
#	Aug 01, 2012:	move to linux						#
#	Feb 26, 2013:	test function added					#
#   Mar 28, 2013:   web pass changed                    #
#   Apr 16, 2013:   linux related update                    #
#										#
#################################################################################
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;


###################################################################
#
#---- setting directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

###################################################################


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
        if($uyear > 20012) {
                $dom++;
        }
}


###### creating a main page #######

open(OUT, ">$web_dir/aiming_page.html");

print OUT "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"> \n";
print OUT " \n";
print OUT "<html> \n";
print OUT "<head> \n";
print OUT "        <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css\" /> \n";
print OUT "        <title>Celestial Location Monitoring</title> \n";
print OUT " \n";
print OUT "        <script language=\"JavaScript\"> \n";
print OUT "                function WindowOpener(imgname) { \n";
print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=820,height=620,resize=no\"); \n";
print OUT "                        msgWindow.document.clear(); \n";
print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
print OUT "                        msgWindow.document.write(\"<body bgcolor='white'>\"); \n";
print OUT "                        msgWindow.document.write(\"<img src='./Fig_save/\"+imgname+\"' border=0 width=800 height=600 ><p></p></body></html>\") \n";
print OUT "                        msgWindow.document.close(); \n";
print OUT "                        msgWindow.focus(); \n";
print OUT "                } \n";
print OUT "        </script> \n";
print OUT " \n";
print OUT "</head> \n";
print OUT "<body  style='background-image:url(\"./Fig_save/stars.jpg\")'> \n";



print OUT '<h2  style="text-align:center;padding-bottom:10px">ACIS-S and HRC Celestial Location Monitoring </h2>',"\n";

print OUT '<hr />',"\n";
print OUT '<h3> PLOTS </h3>',"\n";
print OUT '<p>',"\n";
print OUT 'The following plots are the differences between coordinates obtained';
print OUT ' from Chandra observations and those obtained from existing catalogs';
print OUT ' vs time in day of mission.',"\n";
print OUT '</p>',"\n";
print OUT '<p>',"\n";
print OUT 'The following steps are taken to generate these plots',"\n";
print OUT '</p>',"\n";
print OUT "<br /> \n";
print OUT '<p>',"\n";
print OUT '<ul style="color:#90EE90">',"\n";
print OUT '<li style="line-height:120%"> All observations with grating are selected from a recent observation list';
print OUT 'None grating observations with known point sources (e.g., previously observed objects)';
print OUT 'are also added to the list.<br /></li>';
print OUT "<br /> \n";
print OUT '<li style="line-height:120%"> Find coordinates for each observation from SIMBAD. If the coordinates information is ';
print OUT 'given at three decimal accuracy, we use the observation. Otherwise';
print OUT ' it is dropped from the further process. ';
print OUT 'These coordinates are converted into detector coordinates.<br /></li>';
print OUT "<br /> \n";
print OUT '<li style="line-height:120%"> Using a cell detect function, find source positions in detector coordinates.<br /></li>';
print OUT "<br /> \n";
print OUT '<li style="line-height:120%"> Assuming the br /ightest object is the targeted source (this is true most of';
print OUT ' the time, because all observations are grating observations),';
print OUT ' compare those to the coordinates from the SIMBAD.<br /></li>';
print OUT "<br /> \n";
print OUT '<li style="line-height:120%"> Convert the differences into arc sec, and plot the results.</li>';
print OUT '</ul>',"\n";
print OUT '</p>',"\n";


print OUT "<table border=0 cellpadding=5 cellspacing=4 style='padding-left:40px'> \n";
print OUT '<tr><th width=30%> Click to See the Plot </th><th width=30%>Data (ASCII)</th></tr>',"\n";
print OUT "<tr><td><a href=\"javascript:WindowOpener('acis_point_err.gif')\"> ACIS S Plot</a></td> \n";
print OUT '<td><a href=./Data/acis_s_data target="_blank" >ACIS S Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT "<tr><td><a href=\"javascript:WindowOpener('hrc_s_point_err.gif')\"> HRC S Plot</a></td> \n";
print OUT '<td><a href=./Data/hrc_s_data target="_blank">HRC S Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT "<tr><td><a href=\"javascript:WindowOpener('hrc_i_point_err.gif')\"> HRC I  Plot</a></td> \n";
print OUT '<td><a href=./Data/hrc_i_data target="_blank">HRC I Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '</table>',"\n";

print OUT '<hr />',"\n";
print OUT '<!--',"\n";
print OUT "<h3 >Memo</h3>\n";
print OUT "<p style='padding-bottom:40px'> \n";
print OUT '<a href=http://icxc.harvard.edu/cal/drift/drift4.html>';
print OUT 'Maxim Markevitch (maxim@head-cfa.harvard.edu) Study (password required)';
print OUT '</a>',"\n";
print OUT "</p> \n";
print OUT '<hr />',"\n";
print OUT '-->',"\n";
print OUT '<a href=https://cxc.cfa.harvard.edu/mta/sot.html>Back to SOT page</a>';
print OUT "<div style='float:right;padding-left:100px'>Last Update: $uyear-$month-$umday</div>\n";
close(OUT);
