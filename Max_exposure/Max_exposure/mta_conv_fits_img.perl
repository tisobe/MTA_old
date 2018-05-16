#!/usr/bin/perl

#########################################################################################
#											#
#	mta_conv_fits_img.perl: convert a fits img file to a ps, gif, jpg, or png file	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Mar 08, 2007							#
#											#
#########################################################################################

$pbin_dir = '/home/ascds/DS.release/otsbin/';

$infile  = $ARGV[0];		# input fits file name
$outfile = $ARGV[1];		# output png file name without a suffix
$scale   = $ARGV[2];		# scale of the output image; log, linear, or power
$size    = $ARGV[3];		# size of the output image; format: 125x125 --- no contorl of size on ps and jpg file
$color   = $ARGV[4];		# color of the output image: hear, rainbow1 etc
$type    = $ARGV[5];		# image type: ps, gif, jpg, or png

chomp $infile;
chomp $outfile;
chomp $size;
chomp $color;
chomp $type;

if($infile =~ /-h/i){
	print "Usage:\n";
	print " peal mta_conv_fits_img.perl <infile> <outfile> <scale> <size> <color> <img type>\n";
	print " where \n";
	print "		<infile>: 	input fits file\n";
	print "		<outfile>: 	output img file name. do not add an suffix\n";
	print "		<scale>:	scale of image, log, linear, or power\n";
	print "		<size>:		size of output image in format of 125x125, default:125x125\n";
	print "				ps or jpg do not take this paramter\n";
	print "		<color>:	color of output image. if you need to see which color is availabe\n";
	print "                         type: 'ls /home/ascds/DS.release/data/*.lut'. Default: grey\n";
	print "		<img type>:	ps, jpg, gif, or png\n";
	print "Example: \n";
	print " perl mta_conv_fits_img.perl HRCS_09_1999_04_2005.fits HRCS_09_1999_04_2005  log 125x125 heat png\n";
	exit 1;
}

if($scale !~ /log/i && $scale !~ /power/i){
	$scale = 'linear';
}

if($size eq '' || $size eq '-'){
	$size = '125x125';
}

$in_list = `ls /home/ascds/DS.release/data/*.lut`;
@list  = split(/\s+/, $in_list);
@c_list = ();
foreach $ent (@list){
	@atemp = split(/data\//, $ent);
	@btemp = split(/.lut/, $atemp[1]);
	push(@c_list, $btemp[0]);
}

$chk = 0;
$color = lc ($color);
OUTER:
foreach $comp (@c_list){
	if($color eq $comp){
		$chk++;
		last OUTER;
	}
}
if($chk == 0){
	$color = "grey";
}

$type = lc ($type);
$chk  = 0;
OUTER:
foreach $comp ('ps', 'gif', 'jpg', 'png'){
	if($type eq $comp){
		$chk++;
		last OUTER;
	}
}

if($chk == 0){
	$type = 'gif';
}

$outfile = "$outfile".'.'."$type";

#
#--- convert the fits image to an eps image
#

system("dmimg2jpg $infile  greenfile='' bluefile='' regionfile='' outfile='foo.jpg' scalefunction='$scale' psfile='foo.ps'  lut=')lut.$color' showgrid=no  clobber='yes'");

if($type eq 'ps'){

	system("mv foo.ps $outfile");

}elsif($type eq 'jpg'){

	system("mv foo.jpg $outfile");

}elsif($type eq 'gif'){

#
#--- convert the eps iamge to a gif image
#


	system("echo ''|gs -sDEVICE=ppmraw  -r$size  -q -NOPAUSE -sOutputFile=-  ./foo.ps|$pbin_dir/pnmcrop|$pbin_dir/ppmtogif > $outfile");

}elsif($type eq 'png'){

#
#--- convert the eps iamge to a png image
#

	system("echo ''|gs -sDEVICE=ppmraw  -r$size  -q -NOPAUSE -sOutputFile=-  ./foo.ps|$pbin_dir/pnmcrop|$pbin_dir/pnmtopng > $outfile");
}

system("rm foo.*");


