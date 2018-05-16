#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	acis_bad_pix_new_plot_set.perl: adjust old dataset, and create a new set of plots 	#
#					for warm pixs/cols					#
#			  		this is a control script.				#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: May 22, 2013							#
#												#
#################################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#------------

system("cp $data_dir/Disp_dir/hist_ccd* $data_dir/Disp_dir/hist_col* .");

#
#--- warm pixel cases
#

system("$op_dir/perl $bin_dir/create_new_and_imp_ccd_list.perl $comp_test");

system("$op_dir/perl $bin_dir/create_flk_pix_hist.perl         $comp_test");

system("$op_dir/perl $bin_dir/create_pot_warm_pix.perl         $comp_test");

system("$op_dir/perl $bin_dir/plot_ccd_history.perl            $comp_test");

system("$op_dir/perl $bin_dir/plot_front_ccd_history.perl      $comp_test");

#
#--- warm column cases
#

system("$op_dir/perl $bin_dir/create_new_and_imp_col_list.perl $comp_test");

system("$op_dir/perl $bin_dir/create_flk_col_hist.perl $comp_test");

system("$op_dir/perl $bin_dir/create_pot_warm_col.perl $comp_test");

system("$op_dir/perl $bin_dir/plot_col_history.perl $comp_test");

system("$op_dir/perl $bin_dir/plot_front_col_history.perl $comp_test");


system("mv *gif $web_dir/Plots/");
#system("mv bad* cum* ccd*cnt col*cnt hist* new* imp* flk*     $data_dir/Disp_dir/");
