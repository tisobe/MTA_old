#!/usr/bin/env /usr/local/bin/perl

#
#---- set several directory names
#

$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list_test';

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


system("mkdir /data/mta/Script/ACIS/Gain/Test_out");

system("mkdir $gain_out");
system("cp $house_keeping/Test_prep/gain_obs_list $gain_out/.");

system("mkdir $gain_out/Data");
system("cp $house_keeping/Test_prep/ccd* $gain_out/Data/.");

system("mkdir $gain_out/Plots");
