#!/usr/bin/perl 

#
#   get avg of quad 0 of , e.g., /data/mta_www/mta_temp/mta_cti/Det_Data2000/mn_ccd0
#				copy a part of the data to another file to get an avg of the part

$file = $ARGV[0];
open(FH, "$file");
$sum = 0;
$cnt = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	@btemp = split(/\+\-/, $atemp[1]);
	$sum += $btemp[0];
	$cnt++;
}
close(FH);

$avg = $sum/$cnt;
print "$avg\n";
