#!/usr/bin/perl

#
#---- this script order the data file according to the time
#

$file = $ARGV[0];

open(FH, "all");

@time = ();
@line = ();
$cnt  = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	$tim  = $atemp[1];
	$tim  =~ s/\.//;
	$tim  =~ s/:/\./;
	push(@time, $tim);
	%{data.$tim} = (line =>["$_"]); 
}
close(FH);

@sorted = sort{$a<=>$b} @time;

foreach $ent (@sorted){
	print "${data.$ent}{line}[0]\n";
}
