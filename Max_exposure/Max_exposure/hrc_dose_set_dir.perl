#!/usr/bin/perl

#########################################################################################
#                                                                                       #
#       hrc_dose_set_dir.perl: setting directries needed for hrc dose computation	#
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last update: Aug 22, 2005                                                       #
#                                                                                       #
#########################################################################################


$bin_dir  = '/data/mta/MTA/bin/';			    # a directory which holds all scripts
$dat_dir  = '/data/mta/MTA/data/';			    # a directory which holds all data used by the scripts
$mon_dir  = '/data/mta/www/mta_max_exp/Month_hrc/';	    # a directory which holds all hrc monthly data
$cum_dir  = '/data/mta/www/mta_max_exp/Cumulative_hrc/';    # a directory which holds all hrc cumulative data
$mon_dir2 = '/data/mta/Script/Exposure/Hrc/Month_hrc/';	    # a directory which holds all hrc monthly data
$cum_dir2 = '/data/mta/Script/Exposure/Hrc/Cumulative_hrc/';# a directory which holds all hrc cumulative data
$data_out = '/data/mta/www/mta_max_exp/Data/';		    # a directory which holds computed results
$data_out2= '/data/mta/www/mta_max_exp/HRC/Data/';	    # a directory which holds computed results (full data)
$plot_dir = '/data/mta/www/mta_max_exp/Plots/';		    # a directory which holds all plots
$img_dir  = '/data/mta/www/mta_max_exp/Images/';	    # a directory which holds all png images
$web_dir  = '/data/mta/www/mta_max_exp/';		    # a top directory

#
#--- print out directory lists so that other scripts can read it.
#
open(OUT, '>./dir_list');

print OUT "$bin_dir\n";
print OUT "$dat_dir\n";
print OUT "$mon_dir\n";
print OUT "$cum_dir\n";
print OUT "$data_out\n";
print OUT "$plot_dir\n";
print OUT "$img_dir\n";
print OUT "$web_dir\n";

close(OUT);

open(OUT, '>./dir_list2');

print OUT "$bin_dir\n";
print OUT "$dat_dir\n";
print OUT "$mon_dir2\n";
print OUT "$cum_dir2\n";
print OUT "$data_out2\n";
print OUT "$plot_dir\n";
print OUT "$img_dir\n";
print OUT "$web_dir\n";

close(OUT);


open(OUT, '>./dir_list3');

print OUT "$bin_dir\n";
print OUT "$dat_dir\n";

close(OUT);


open(OUT, '>./dir_list4');

print OUT "$bin_dir\n";
print OUT "$dat_dir\n";
print OUT "$web_dir\n";

close(OUT);

