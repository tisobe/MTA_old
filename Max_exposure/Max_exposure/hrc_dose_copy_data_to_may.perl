#!/usr/bin/perl

#########################################################################################
#                                                                                       #
#       hrc_dose_copy_data_to_may.perl: copy data to may so that the world can see it   #
#                                                                                       #
#       author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                       #
#       last update: Feb 06, 2007                                                       #
#                                                                                       #
#########################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list2`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];
$mon_dir  = $dir_list[2];
$cum_dir  = $dir_list[3];
$data_out = $dir_list[4];
$plot_dir = $dir_list[5];
$img_dir  = $dir_list[6];
$web_dir  = $dir_list[7];

$mays_dir = '/data/mays/MTA/Exposure/Hrc/';                     #----- copying data


#
#--- get today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year   = 1900   + $uyear;
$month  = $umon  + 1;

#
#--- find out the last month
#

if($umon == 0){
        $lmonth = 12;
        $lyear = $year -1;
}else{
        $lmonth = $umon;
        $lyear  = $year;
}

#
#--- copy data to "mays" which can be seen from the outer world
#

$emonth = $lmonth;
if($lmonth < 10 && $lmonth !~ /0/){
       $emonth = '0'."$lmonth";
}

$new_data = '*'."$emonth".'_'."$lyear".'*';

system("gzip $mon_dir/$new_data");
system("cp $mon_dir/$new_data $mays_dir/Month_hrc");

system("gzip $cum_dir/$new_data");
system("cp $cum_dir/$new_data $mays_dir/Cumulative_hrc");

