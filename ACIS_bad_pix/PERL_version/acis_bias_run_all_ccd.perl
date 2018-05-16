#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_bias_run_all_ccd.perl: run moving_avg.perl for all CCD and nodes		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: May 22, 2013							#
#											#
#########################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#######################################

#
#---- plot special cases first
#
#system("perl $bin_dir/acis_bias_moving_avg.perl /data/mta_www/mta_bias_bkg/Bias_save/CCD0/quad0 2220 1e5");
#system("mv bias_plot_CCD0_quad0.gif $web_dir/Plots/Sub2/bias_plot_CCD0_quad0_second.gif");
#
#system("perl $bin_dir/acis_bias_moving_avg.perl /data/mta_www/mta_bias_bkg/Bias_save/CCD0/quad0 0 1e5");
#system("mv bias_plot_CCD0_quad0.gif $web_dir/Plots/Sub2/bias_plot_CCD0_quad0_special.gif");
#
#system("perl $bin_dir/acis_bias_moving_avg.perl /data/mta_www/mta_bias_bkg/Bias_save/CCD1/quad1 2220 1e5");
#system("mv bias_plot_CCD1_quad1.gif $web_dir/Plots/Sub2/bias_plot_CCD1_quad1_second.gif");
#
#system("perl $bin_dir/acis_bias_moving_avg.perl /data/mta_www/mta_bias_bkg/Bias_save/CCD1/quad1 0 1e5");
#system("mv bias_plot_CCD1_quad1.gif $web_dir/Plots/Sub2/bias_plot_CCD1_quad1_special.gif");


#
#--- general plotting
#

for($ccd = 0; $ccd < 10; $ccd++){
	for($node = 0; $node < 4; $node++){

		$file = "$data_dir".'/Bias_save/CCD'."$ccd".'/quad'."$node";
        
		system("$op_dir/perl $bin_dir/acis_bias_moving_avg.perl $file $comp_test");

		system("mv bias_plot_*.gif $web_dir/Plots/Sub2/");
	}
}
 

