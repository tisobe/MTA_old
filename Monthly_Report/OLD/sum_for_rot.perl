#!/usr/bin/perl

#########################################################################
#									#
#	sum_for_rot.perl: compute cummurative rotation and difference 	#
#			  from the last month				#
#									#
#	Need:	 rot_dat: all data for the period you want to summing	#
#			  up.						#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)			#
#									#
#	Aug. 9, 2000:	first version					#
#									#
#########################################################################

open(FH,"./rot_dat");
$sum1 = 0;
$sum2 = 0;
$sum3 = 0;
$sum4 = 0;
$sum5 = 0;
$sum6 = 0;
$cnt = 0;
while(<FH>) {
	chomp $_;
	@atemp = split(/ /,$_);
	@{line.$cnt} = ();
	foreach $ent (@atemp){
		if($ent =~ /\d/){
			push(@{line.$cnt},$ent);
		}
	}
$cnt++;
}
for($i = 0; $i < $cnt; $i++) {
	$sum1 += ${line.$i}[0];
	$sum2 += ${line.$i}[1];
	$sum3 += ${line.$i}[2];
	$sum4 += ${line.$i}[3];
	$sum5 += ${line.$i}[4];
	$sum6 += ${line.$i}[5];

}
printf("%6.5e	%6.5e	%6.5e	%6.5e	%6.5e	%6.5e\n",$sum1,$sum2,$sum3,$sum4,$sum5,$sum6);

$this = $cnt - 1;
$last = $cnt - 2;
$diff1 = ${line.$this}[0] - ${line.$last}[0];
$diff2 = ${line.$this}[1] - ${line.$last}[1];
$diff3 = ${line.$this}[2] - ${line.$last}[2];
$diff4 = ${line.$this}[3] - ${line.$last}[3];
$diff5 = ${line.$this}[4] - ${line.$last}[4];
$diff6 = ${line.$this}[5] - ${line.$last}[5];

printf("%6.5e	%6.5e	%6.5e	%6.5e	%6.5e	%6.5e\n",$diff1,$diff2,$diff3,$diff4,$diff5,$diff6);
