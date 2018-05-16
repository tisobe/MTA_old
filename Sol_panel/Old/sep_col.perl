#!/usr/bin/perl

$file = $ARGV[0];
$col  = $ARGV[1];
$col2 = $ARGV[2];
chomp $file;
chomp $col;

open(FH, "$file");
open(OUT, '>temp_data');
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[$col] !~ /\d/){
		next OUTER;
	}
	print OUT "$atemp[$col]\t$atemp[$col2]\n";
}
close(OUT);
close(FH);

