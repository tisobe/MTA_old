#!/usr/bin/perl

#################################################################################
#										#
#	dm_img.perl: obtain acis evt1 file from an archvie (arc4gl) and crate	#
#		     an combined image file					#
#										#
#	input: 									#
#		list: list of acis evt 1 file					#
#		pass word:  pass word for archive account for isobe		#
#		file name:  output file name					#
#			list is a file in a same directory			#
#			two others are asked when you start this script 	#
#										#
#										#
#	Author:	Takashi Isobe (tisobe@cfa.harvard.edu)				#
#										#
#	Aug 8, 2000	First version						#
#										#
#################################################################################


#`ls acis*img.fits > img_list`;
open(FH,"./img_list");
@img_list = ();
while(<FH>) {
	chomp $_;
	push(@img_list,$_);
}
close(FH);

$first = shift(@img_list);
`cp  $first total.fits`;
`echo total.fits,0,0 > file`;

foreach $ent (@img_list) {
	print "$ent\n";
	`fimgmerge $ent \@file temp.fits`;
	`mv temp.fits total.fits`;
}
