#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	fit_sin_for_sol_pan.perl: control script to fit sin wave model to data		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 05, 2013						#
#											#
#########################################################################################

#
#--- test case; set this "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- set directory
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


foreach $angle(40, 60, 80, 100, 120, 140, 160){
	foreach $side ('tsapyt', 'tsamyt'){
		$data = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle".'_'."$side".'.dat';
		$out  = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle".'_'."$side".'_sine.dat';
		$fnam = "$data_dir".'/Plot_data/solar_panel_angle'."$angle".'_'."$side".'_sine_param';
#
#--- here is the function actually fitting the model on the data
#
		system("$op_dir/perl $script_dir/sin_wave_sol_panel.perl $data");
		system("mv sin_data $out");
		system("mv fit_result $fnam");
	}
}

