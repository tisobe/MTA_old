#!/usr/bin/env /usr/local/bin/perl
#
#---- setting directories
#
$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list_test';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


system("mkdir $web_dir");
system("mkdir $web_dir/Fig_save");
system("mkdir $data_dir");
system("cp $house_keeping/Test_prep/* $data_dir");


