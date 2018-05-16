#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	acis_cti_run_all_script.perl: this is a control script for cti comp	#
#										#
#	author: t. isobe (tiosbe@cfa.harvard.edu)				#
#										#
#	last update: May 15, 2013						#
#										#
#################################################################################

#
#-- if this is a $test run, set $comp_test to "test".
#

$comp_test = '';
$comp_test = $ARGV[0];
chomp $comp_test;

#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#########################################

#
#--- if this is a $test, clean up the output directories
#

if($comp_test =~ /test/i){
        system("rm -rf $data_dir/*/* $data_dir/*factor");
        system("$op_dir/perl $bin_dir/prep_test.perl ");
}

#
#--- check whether Working dir exist or not, and if not, create one.
#

$chk = `ls -d $exc_dir`;
if($chk !~ /Working_dir/){
        system("mkdir $exc_dir/Working_dir");
}

#
#--- a list of cti obsrvations are obtained from Jim's cti computation
#

system("$op_dir/perl $bin_dir/acis_cti_find_new_entry.perl $test");
system("$op_dir/perl $bin_dir/acis_cti_get_data.perl $test ");

#
#--- check a focal plane temp so that we can discreminate cti depending on temp
#

system("$op_dir/perl $bin_dir/acis_cti_find_time_temp_range.perl $test");

#
#--- recmpute cti according to temperature difference
#

system("$op_dir/perl $bin_dir/acis_cti_manual_cti.perl $test ");

#
#--- compute detrending factor
#

system("$op_dir/perl $bin_dir/acis_cti_detrend_factor.perl $test");

#
#--- create several data sets (e.g. temperature and/or time)
#

system("$op_dir/perl $bin_dir/acis_cti_adjust_cti.perl $test ");

#
#--- compute adjustment factor for temeprature depended cti
#

system("$op_dir/perl $bin_dir/acis_cti_comp_adjusted_cti.perl $test ");

#
#--- cti plottings start here
#

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Data119 $test");
system("$op_dir/perl $bin_dir/acis_cti_plot_only.perl 		Data119 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Data2000 $test");
system("$op_dir/perl $bin_dir/acis_cti_plot_only.perl 		Data2000 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Data7000 $test");
system("$op_dir/perl $bin_dir/acis_cti_plot_only.perl 		Data7000 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Data_adjust $test");
system("$op_dir/perl $bin_dir/acis_cti_plot_only.perl 		Data_adjust $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Data_cat_adjust $test");
system("$op_dir/perl $bin_dir/acis_cti_plot_only.perl 		Data_cat_adjust $test");


#
#--- create detrended data set
#

system("$op_dir/perl $bin_dir/acis_cti_make_detrend_data.perl $test");

system("$op_dir/perl $bin_dir/acis_cti_det_adjust_cti.perl $test ");

system("$op_dir/perl $bin_dir/acis_cti_det_comp_adjusted_cti.perl  $test");

#
#--- detrended cti plots start here
#

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Det_Data119 $test");
system("$op_dir/perl $bin_dir/acis_cti_det_plot_only.perl 	Det_Data119 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Det_Data2000 $test");
system("$op_dir/perl $bin_dir/acis_cti_det_plot_only.perl 	Det_Data2000 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Det_Data7000 $test");
system("$op_dir/perl $bin_dir/acis_cti_det_plot_only.perl 	Det_Data7000 $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Det_Data_adjust $test");
system("$op_dir/perl $bin_dir/acis_cti_det_plot_only.perl 	Det_Data_adjust $test");

system("$op_dir/perl $bin_dir/acis_cti_find_outlayer.perl 	Det_Data_cat_adjust $test");
system("$op_dir/perl $bin_dir/acis_cti_det_plot_only.perl 	Det_Data_cat_adjust $test");

#
#--- slightly different plottings
#

system("$op_dir/perl $bin_dir/acis_cti_new_plot_only.perl $test");
system("$op_dir/perl $bin_dir/acis_cti_new_det_plot_only.perl $test");
system("$op_dir/perl $bin_dir/acis_cti_new_det_plot_only_part.perl $test");

#
#----  update the html page
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year  = 1900   + $uyear;
$month = $umon  + 1;

$line = "<br><br><H3> Last Update: $month/$umday/$year</H3><br>";

open(OUT, ">$exc_dir/Working_dir/date_file");
print OUT "\n$line\n";
close(OUT);

system("cat $house_keeping/cti_page.html $exc_dir/Working_dir/date_file > $cti_www/cti_page.html");

#
#--- cleaning up
#

system("rm -rf $exc_dir/*");
