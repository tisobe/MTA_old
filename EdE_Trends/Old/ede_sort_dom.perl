#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
#	ede_sort_dom.perl: sort ede data with dom value 		#
#									#
#	input example: EdE_Data/acis_htg_0824_data			#
#									#
#	author: t. isobe (tisobe@cfa.harvard.edu)			#
#									#
#	last update: Feb 8, 2006					#
#									#
#########################################################################

$file = $ARGV[0];
chomp $_;

@time = ();

open(FH, "$file");
open(OUT, ">./ztemp");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] !~ /\d/){
		print OUT  "$_\n";
	}else{
		push(@time, $atemp[10]);
		%{data.$atemp[10]} = (data => ["$_"]);
	}
}
close(FH);

@temp = sort{$a<=>$b} @time;
foreach $dom (@temp){
	print OUT  "${data.$dom}{data}[0]\n";
}

