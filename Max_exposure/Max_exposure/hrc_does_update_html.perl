#!/usr/bin/perl

#########################################################################
#									#
#   hrc_does_update_html.perl: update date on full_hrc_exposure_map.html#
#									#
#	author: t. isobe (tisobe@cfa.harvard.edu)			#
#									#
#	Last update : Aug 22, 2005					#
#									#
#########################################################################


#
#---- set directories
#

$temp_in = `cat ./dir_list`;
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

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
$year  = 1900   + $uyear;
$month = $umon  + 1;

$line = "<br><br><H3> Last Update: $month/$umday/$year</H3>";

open(FH, "$web_dir/HRC/full_hrc_exposure_map.html");

@save = ();
while(<FH>){
	chomp $_;
	push(@save, $_);
}
close(FH);

open(OUT, "$web_dir/HRC/full_hrc_exposure_map.html");

foreach $ent (@save){
	if($ent =~ /Last Update/){
		print OUT "$line\n";
	}else{
		print OUT "$ent\n";
	}
}
close(OUT);
