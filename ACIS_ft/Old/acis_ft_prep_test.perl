#!/usr/bin/env /usr/local/bin/perl

#
#--- directory setting
#

$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

system("mkdir $web_dir");
system("mkdir $data_out");
system("mkdir $short_term");
system("mkdir $web_dir/Figs/");
system("cp $house_keeping/old_list_short           $web_dir");
system("cp $house_keeping/Test_prep/mj_month_data  $data_out");
system("cp $house_keeping/Test_prep/long_term_data $data_out");
system("cp $house_keeping/Test_prep/month_data     $data_out");
system("cp $house_keeping/Test_prep/week_data      $data_out");
system("cp -r  $house_keeping/Test_prep/Short_term $web_dir");
