#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	acis_gain_print_html.perl: update acis gain web page					#
#												#
#	author: t. isobe (tiosbe@cfa.harvard.edu)						#
#												#
#	last update: Apr 16, 2013								#
#												#
#################################################################################################
#
#---- html 5 conformed  Oct 16, 2012
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#---- set output directory
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

open(OUT, ">$gain_out/acis_gain.html");

print OUT "<!DOCTYPE html>\n";
print OUT "<html>\n";
print OUT "<head>\n";
print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT '<link rel="stylesheet" type="text/css" href="https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css" /> ', "\n";
print OUT "<style  type='text/css'>\n";
print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "td{text-align:center;padding:8px}\n";
print OUT "a:link {color:#00CCFF;}\n";
print OUT "a:visited {color:yellow;}\n";
print OUT "span.nobr {white-space:nowrap;}\n";
print OUT "</style>\n";

print OUT "<script>\n";
print OUT 'function MyWindowOpener(imgname) {',"\n";
print OUT 'msgWindow=open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no ,width=900,height=850,resize=yes");',"\n";
print OUT 'msgWindow.document.close();',"\n";
print OUT 'msgWindow.document.write("<HTML><TITLE>ACIS Histgram:   "+imgname+"</TITLE>");',"\n";
print OUT 'msgWindow.document.write("<BODY BGCOLOR=white>");',"\n";
print OUT 'msgWindow.document.write("<IMG SRC=',"'",'/mta_days/mta_acis_gain/"+imgname+"',"'",' BORDER=0 WIDTH=800 HEIGHT=800><P></BODY></HTML>");',"\n";
print OUT 'msgWindow.focus();',"\n";
print OUT '}',"\n";
print OUT "</script>\n";

print OUT '<title> ACIS Gain Plots </title>',"\n";
print OUT "</head>\n";
print OUT "<body>\n";

print OUT '<h2 style="text-align:center;margin-left:auto;margin-right:auto">ACIS Gain Plots</h2>',"\n";
print OUT "<p>\n";
print OUT 'ACIS gains were computed with following steps',"\n";
print OUT '(see C. Grant memo:<a href="http://space.mit.edu/~cgrant/gain/index.html">ACIS Gain @ -120 C</a> for more',"\n";
print OUT 'discussion ):',"\n";
print OUT "</p>\n";

print OUT '<ul>',"\n";
print OUT '<li> All ACIS calibration event 1 files were extracted from Achieve, except squeegee files.</li>',"\n";
print OUT '<li> Each data was compared with focal temperature, and only parts with focal temperature lower than -119.7 C',"\n";
print OUT '     before May 2006, and -119.0 C after May 2006, ',"\n";
print OUT '     were extracted out. (See a list of data used:<a href="./acis_gain_obs_list.html">Input List</a>).</li>',"\n";
print OUT '<li> From these data, only ccdy &le; 20 (first 20 raw of a CCD) and grade 0, 2, 3, 4, and 6 were extracted.</li>',"\n";
print OUT '<li> A pulse height distribution was created from this data, and fit Lorentzian profiles to Al K-alpha (1486.7 eV),',"\n";
print OUT '     Ti K-alpha (4510.84 eV), and Mn K-alpha (5898.75 eV) to find peak postions in ADU.</li>',"\n";
print OUT '<li> A straight line was fit between three peak position in ADU and eV, and a slope (Gain ADU/eV), and',"\n";
print OUT '     an intercept (Offset ADU) were found.</li>',"\n";
print OUT '</ul>',"\n";
print OUT "<p>\n";
print OUT ' For a gain plot, an x axis is in unit of year, and a y axis is in ADU/eV, the range for the y axis is 0.01 for',"\n";
print OUT '     all the plots so that we can compare the general trend among the plots. Similarly for offset plots,',"\n";
print OUT '     a y axis is in ADU, and the range for the y axis is 18 for all the plots. The slopes are either ADU/eV per year,',"\n";
print OUT '     or ADU per year. Two slopes are fit on each data: before  year 2006 and after year 2006, except CCDs 5 and 7. ',"\n";
print OUT '     For the latter, the boundary is set at year 2007.', "\n";
print OUT "</p>\n";
print OUT "<p style='padding-bottom:20px'>\n";
print OUT '     Data entries are: Date, Obsid, starting time in seconds from 1998 Jan 1, end time in seconds from 1998 Jan 1,',"\n";
print OUT '     Mn K-alpha position in ADU, Al K-alpha in ADU, Ti K-alpha in ADU, slopes (ADU/eV), errors for the slopes,',"\n";
print OUT '     intercepts (ADU), and errors for the intercepts.',"\n";
print OUT '</p>',"\n";
print OUT '<table border=1 style="text-align:center;margin-left:auto;margin-right;auto">',"\n";
print OUT '<tr>',"\n";
print OUT '        <th>CCD</th>',"\n";
print OUT '	<th>Plots </th>',"\n";
print OUT '	<th colspan=4>Data</th>',"\n";
print OUT '	</tr><tr>',"\n";
print OUT '	<th>&#160;</th>',"\n";
print OUT '	<th>&#160;</th>',"\n";
print OUT '        <th>Node 0</th>',"\n";
print OUT '        <th>Node 1</th>',"\n";
print OUT '        <th>Node 2</th>',"\n";
print OUT '        <th>Node 3</th>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 0</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd0.gif',"'",')">CCD 0 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd0_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd0_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd0_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd0_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 1</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd1.gif',"'",')">CCD 1 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd1_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd1_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd1_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd1_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 2</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd2.gif',"'",')">CCD 2 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd2_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd2_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd2_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd2_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 3</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd3.gif',"'",')">CCD 3 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd3_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd3_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd3_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd3_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 4</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd4.gif',"'",')">CCD 4 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd4_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd4_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd4_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd4_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 5</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd5.gif',"'",')">CCD 5 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd5_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd5_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd5_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd5_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 6</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd6.gif',"'",')">CCD 6 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd6_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd6_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd6_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd6_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 7</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd7.gif',"'",')">CCD 7 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd7_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd7_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd7_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd7_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 8</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd8.gif',"'",')">CCD 8 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd8_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd8_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd8_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd8_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr><th>CCD 9</th>',"\n";
print OUT '<td><a href="javascript:MyWindowOpener(',"'",'./Plots/gain_plot_ccd9.gif',"'",')">CCD 9 Plot</a></td>',"\n";
print OUT '<td><a href="./Data/ccd9_0">Node 0 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd9_1">Node 1 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd9_2">Node 2 Data</a></td>',"\n";
print OUT '<td><a href="./Data/ccd9_3">Node 3 Data</a></td>',"\n";
print OUT '</tr>',"\n";
print OUT '</table>',"\n";
print OUT "\n";
print OUT "<hr />\n";
#
#----  update the html page
#
($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year  = 1900   + $uyear;
$month = $umon  + 1;

$line = "<strong style='padding-top:10px;padding-bottom:10px' > Last Update: $month/$umday/$year</strong>";
print OUT "$line\n";

print OUT "</body>\n";
print OUT "</html>\n";



###########################################################
# data list html page
###########################################################


@data = ();
open(FH, "$gain_out/gain_obs_list");
while(<FH>){
	chomp $_;
	push(@data, $_);
}
close(FH);

$first = shift(@data);
@new = ("$first");
OUTER:
foreach $ent (@data){
	foreach $comp (@new){
		if($ent eq $comp){
			next OUTER;
		}
	}
	push(@new, $ent);
}
@temp = sort @new;
open(OUT, ">$gain_out/gain_obs_list");
foreach $ent (@new){
	print OUT "$ent\n";
}
close(OUT);

open(OUT, "> $gain_out/acis_gain_obs_list.html");

print OUT "<!DOCTYPE html>\n";
print OUT "<html>\n";
print OUT "<head>\n";
print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT '<link rel="stylesheet" type="text/css" href="https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css" /> ',"\n";
print OUT "<style  type='text/css'>\n";
print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "td{text-align:center;padding:8px}\n";
print OUT "a:link {color:#00CCFF;}\n";
print OUT "a:visited {color:yellow;}\n";
print OUT "span.nobr {white-space:nowrap;}\n";
print OUT "</style>\n";

print OUT '<title>ACIS Gain Input Data List </title>',"\n";
print OUT "</head>\n";

print OUT "<body>\n";
print OUT '<h2 style="text-align:center:margin-left:auto;margin-right:auto">ACIS Gain Input Data List</h2>',"\n";
print OUT '<p style="padding-bottom:20px">',"\n";
print OUT 'Data hilighted satisfies condtions (temp &le; -119.7 C and integration time > 2000 sec) and is used to compute ACIS Gain.',"\n";
print OUT '</p>',"\n";


print OUT '<table style="border-width:0px;text-align:center;margin-left:auto;margin-right:auto">',"\n";
print OUT '<tr><th>Date</th><th>obsid</th><th>Int time (sec)</th><th>Focal Temp (C)</th></tr>',"\n";

foreach $ent (@new){
	print OUT '<tr>',"\n";
	@atemp = split(/\s+/, $ent);
	if($atemp[2] > 2000 && $atemp[3] <= -119.7){
		print OUT "<td style='background-color:green; text-align:center'>$atemp[0]</td>\n";
		print OUT "<td style='background-color:green; text-align:center'>$atemp[1]</td>\n";
		print OUT "<td style='background-color:green; text-align:center'>$atemp[2]</td>\n";
		print OUT "<td style='background-color:green; text-align:center'>$atemp[3]</td>\n";
	}else{
		print OUT "<td style='text-align:center'>$atemp[0]</td>\n";
		print OUT "<td style='text-align:center'>$atemp[1]</td>\n";
		print OUT "<td style='text-align:center'>$atemp[2]</td>\n";
		print OUT "<td style='text-align:center'>$atemp[3]</td>\n";
	}
	print OUT '</tr>',"\n";
}

print OUT '</table>',"\n";

print OUT "</body>\n";
print OUT "</html>\n";
