#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	acis_focal_rm_dupl.perl: remove duplicated line from a file		#
#										#
#	usage: perl rm_dupl.perl <file name> 					#
#										#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)				#
#	Aug. 29, 2000: first version						#
#										#
#################################################################################

$file = $ARGV[0];
chomp $file;
if($file eq '') {
	print "need a file name!";
	exit 1;
}

`sort $file > sorted_file`;
open(FH, "sorted_file");
open(OUT, ">zout");
$count = 0;
while(<FH>) {
	chomp $_;
	if($count == 0) {
		$line = $_;
		print OUT "$_\n";
		$count++;
	}else{
		unless($_ eq $line) {
			$line = $_;
			print OUT "$_\n";
		}else {
			$line = $_;
		}
	}
}
close(OUT);
close(FH);
`rm sorted_file`;

