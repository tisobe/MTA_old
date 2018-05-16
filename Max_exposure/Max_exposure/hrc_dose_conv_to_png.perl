#!/usr/bin/perl

#########################################################################################
#											#
#	hrc_dose_conv_to_png.perl: convert full range HRC fits file to pgn images	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Aug 22, 2005							#
#											#
#########################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list3`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list3 is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];

$in_dir  = $ARGV[0];		# input directory name
$out_dir = $ARGV[1];		# output directory name
$year    = $ARGV[2];		# the year of the data obtained
$month   = $ARGV[3];		# the month of hte data obstained
chomp $in_dir;
chomp $out_dir;
chomp $year;
chomp $month;

if($month < 10){
	if($month !~ /^0/){
		$month = '0'."$month";
	}
}

$name = 'HRC*'."$month".'_'."$year".'*fits*';

$list = `ls $in_dir/$name`;
@in_list = split(/\s+/, $list);

system("mkdir Ftemp");
foreach $ent (@in_list){
	@atemp = split(/\//, $ent);
	$file  = pop (@atemp);
	@btemp = split(/fits/, $file);
	$out   = "$btemp[0]";
	$out   =~ s/\.//g;

#
#--- this is the actual script converts a fits image to a png image
#
	system("perl $bin_dir/mta_conv_fits_img.perl $ent ./Ftemp/$out log 125x125 heat png");
}
system("mv Ftemp/*png $out_dir/");
system("rm -rf Ftemp");
