#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	fit_sin_for_scelec.perl: a control script to fit a sine wave model on the data	#
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
	$data = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_elbv.dat';
	$out  = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_elbv_sine.dat';
	$fnam = "$data_dir".'/Plot_data/scelec_angle'."$angle".'_elbv_sine_param';

#
#--- here is the actual function fitting the model on the data
#
	system("$op_dir/perl $script_dir/sin_wave_scelec.perl $data");
	system("mv sin_data $out");
	system("mv fit_result $fnam");
}

