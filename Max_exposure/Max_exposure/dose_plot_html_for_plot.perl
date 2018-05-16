#!/usr/bin/perl

#########################################################################################
#											#
#	dose_plot_html_for_plot.perl: update html pages					#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last updat: Jan 24, 2012							#
#											#
#########################################################################################


###############################################################################
#---- set directories

$bin_dir  = '/data/mta/MTA/bin/';
$dat_dir  = '/data/mta/MTA/data/';
$mon_dir  = '/data/mta_www/mta_max_exp/Month_hrc/';
$cum_dir  = '/data/mta_www/mta_max_exp/Cumulative_hrc/';
$data_out = '/data/mta/www/mta_max_exp/Data/';
$plot_dir = '/data/mta/www/mta_max_exp/Plots/';
$img_dir  = '/data/mta_www/mta_max_exp/Images';

$web_dir  = '/data/mta/www/mta_max_exp/';

$house_keeping = '/data/mta/Script/Exposure/house_keeping/';

###############################################################################


($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
$year  = 1900   + $uyear;
$month = $umon  + 1;

#
#---- ACIS Plot html
#

foreach $inst ('i', 's'){
	for($ccd = 2; $ccd <= 3; $ccd++){
		for($node = 0; $node < 4; $node++){
			$file_name = "$plot_dir/"."$inst".'_'."$ccd".'_n_'."$node".'.html';
			open(OUT, ">$file_name");
			print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000"',"\n";
			print OUT ' LINK="#00CCFF" VLINK="yellow" ALINK="#FF0000" background="./stars.jpg">',"\n";
			print OUT '<title>CCD '."$ccd".' Node '."$node".'</title>',"\n";
			print OUT '<center><h1>CCD'."$ccd".' Node '."$node","\n";
			print OUT '<h1>',"\n";
			print OUT "<img src='$inst".'_'."$ccd".'_n_'."$node".'.gif'."' width='700' height='700'>","\n";
			print OUT '<center>',"\n";
			print OUT '<html>',"\n";
#
#----  update the html page
#
        		$line = "<br><br><H3> Last Update: $month/$umday/$year</H3>";
        		print OUT "$line\n";

			close(OUT);
		}
	}
}

#
#---- HRC Plot html
#

$file_name = "$plot_dir/hrci.html";

open(OUT, ">$file_name");
print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" VLINK="yellow" ALINK="#FF0000" background="./stars.jpg">',"\n";
print OUT '<title>HRC I</title>',"\n";
print OUT '<center>',"\n";
print OUT '<h1>',"\n";
print OUT 'HRC I',"\n";
print OUT '</h1>',"\n";
print OUT "<img src='hrci.gif' width='700' height='700''>","\n";
print OUT '</center>',"\n";
$line = "<br><br><H3> Last Update: $month/$umday/$year</H3>";
print OUT "$line\n";
print OUT '</html>',"\n";
close(OUT);

$file_name = "$plot_dir/hrcs.html";

open(OUT, ">$file_name");
print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" VLINK="yellow" ALINK="#FF0000" background="./stars.jpg">',"\n";
print OUT '<title>HRC S</title>',"\n";
print OUT '<center>',"\n";
print OUT '<h1>',"\n";
print OUT 'HRC S',"\n";
print OUT '</h1>',"\n";
print OUT "<img src='hrcs.gif' width='700' height='700'>","\n";
print OUT '</center>',"\n";
$line = "<br><br><H3> Last Update: $month/$umday/$year</H3>";
print OUT "$line\n";
print OUT '</html>',"\n";
close(OUT);

#
#--- main html pages update
#

open(OUT, '>./ztemp');
$line = "<br><br><H3> Last Update: $month/$umday/$year</H3>";
print OUT "$line\n";
close(OUT);

$file_name = "$web_dir/exposure.html";

system("cat $house_keeping/exposure.html ./ztemp > $web_dir/exposure.html");

system("rm ./ztemp");
