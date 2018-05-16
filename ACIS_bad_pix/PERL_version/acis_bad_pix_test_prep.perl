#!/usr/bin/env /usr/local/bin/perl

#########################################################################################################################
#															#
#	acis_bad_pix_test_prep.perl: create directories and prepare for the test output					#
#															#
#		author: t. isobe (tisobe@cfa.harvard.edu)								#
#															#
#		last update: May 16, 2013										#
#															#
#########################################################################################################################
	
#
#--- setting a few paramters
#

#--- output directory

$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- hosue keeping directory
#

system("mkdir $web_dir");
system("mkdir $web_dir/house_keeping");
system("cp -r //data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/Defect $web_dir/house_keeping/Defect");

#
#--- bad pixel related
#
system("mkdir $web_dir/Data/");
system("cp -r /data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/Disp_dir_test_sample  $web_dir/Data/Disp_dir");
system("mkdir $web_dir/Data/Old_dir/");
for($i = 0; $i < 10; $i++){
	system("mkdir $web_dir/Data/Old_dir/CCD$i");
}
system("cp /data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_home.html $web_dir/house_keeping/.");
system("cp /data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/past_input_data $web_dir/house_keeping/.");

system("mkdir $web_dir/Html_dir");
system("mkdir $web_dir/Plots");

#
#--- bias data related
#

system("mkdir $web_dir/Bias_data");
system("cp -r /data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/Bias_data/* $web_dir/Bias_data/.");


system("mkdir $web_dir/Plots");
system("mkdir $web_dir/Plots/Bias_bkg");
system("mkdir $web_dir/Plots/Overclock");
system("mkdir $web_dir/Plots/Param_diff");
system("mkdir $web_dir/Plots/Sub");
system("mkdir $web_dir/Plots/Sub2");

for($i = 0; $i < 10; $i++){
	system("mkdir $web_dir/Plots/Param_diff/CCD$i");
	for($j = 0; $j < 4; $j++){
		$line = "$web_dir/Plots/Param_diff/CCD$i/CCD$i"."_q"."$j";
		system("mkdir $line");
		$line = "$web_dir/Plots/Param_diff/CCD$i/CCD$i"."_bias_q"."$j";
		system("mkdir $line");
	}
}
