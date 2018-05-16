#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#                                                                                       #
#       prep_for_test.perl: prepareing for test output directories and files            #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last update: Jun 05, 2013                                                       #
#                                                                                       #
#########################################################################################

#########################################################
#
#---- set directories
#
open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list_test");

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- and other settings
#

$dare   = `cat $data_dir/.dare`;
chomp $dare;
$hakama = `cat $data_dir/.hakama`;
chomp $hakama;

#########################################################


system("mkdir $web_dir");
system("mkdir $result_dir");
system("mkdir $fig_dir");
system("mkdir $fits_dir");
system("mkdir $data_save");

system("mkdir $web_dir/HETG_INSR/");
system("mkdir $web_dir/HETG_RETR/");
system("mkdir $web_dir/LETG_INSR/");
system("mkdir $web_dir/LETG_RETR/");

system("cp $house_keeping/Test_prep/* $result_dir");
