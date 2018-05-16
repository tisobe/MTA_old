#!/usr/bin/perl

#########################################################################################
#											#
#	acis_dose_seprate_ccd.perl: create images for i2, i3, s2, s4 CCD separately 	#
#				    from a main image file (e.g. ACIS_05_2004.fits)	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: 	Apr 12, 2005							#
#											#
#########################################################################################


$in_list = $ARGV[0];			# a name of file list which has all fits file name
@file_list = ();
open(FH, "$in_list");
while(<FH>){
	chomp $_;
	push(@file_list, $_);
}
close(FH);

foreach $file (@file_list){

	@atemp = split(/\.fits/, $file);
	@btemp = split(/ACIS/, $atemp[0]);
	$head  = "ACIS"."$btemp[1]";

#----- CCD I2
	$name = "$head".'_i2.fits';
	$line = "$file".'[264:1288,1416:2435]';
	system("dmcopy \"$line\" $name");

#----- CCD I3
	$name = "$head".'_i3.fits';
	$line = "$file".'[1308:2332,1416:2435]';
	system("dmcopy \"$line\" $name");

#----- CCD S2
	$name = "$head".'_s2.fits';
	$line = "$file".'[80:1098,56:1076]';
	system("dmcopy \"$line\" $name");

#----- CCD S3
	$name = "$head".'_s3.fits';
	$line = "$file".'[1122:2141,56:1076]';
	system("dmcopy \"$line\" $name");
}
