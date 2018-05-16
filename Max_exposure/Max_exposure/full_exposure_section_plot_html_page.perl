#!/usr/bin/perl

#################################################################################################
#												#
#	full_exposure_section_plot_html_page.html: update /data/mta_www/mta_max_exp/HRC/Plots	#
#						   html pages					#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last updat: Jan 24, 2012								#
#												#
#################################################################################################


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
foreach $inst ('i', 's'){
		for($node = 0; $node < 8; $node++){
			$file_name = "/data/mta_www/mta_max_exp/HRC/Plots/hrc"."$inst".'_'."$node".'.html';
			open(OUT, ">$file_name");
			print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000"',"\n";
			print OUT ' LINK="#00CCFF" VLINK="yellow" ALINK="#FF0000" background="./stars.jpg">',"\n";
			print OUT '<title>HRC_'."$inst".' Section: '."$node".'</title>',"\n";
			print OUT '<center><h1>HRC_'."$inst".' Section: '."$node","\n";
			print OUT '<h1>',"\n";
			print OUT "<img src='\.\/hrc"."$inst".'_'."$node".'.gif'."' width='90%'>","\n";
			print OUT '<center>',"\n";
			print OUT '<html>',"\n";
#
#----  update the html page
#
        		$line = "<br><br><em style='font-size:60%'> Last Update: $month/$umday/$year</em>";
        		print OUT "$line\n";

			close(OUT);
		}
}
