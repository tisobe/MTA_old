#!/usr/bin/perl

#########################################################
#							#
#  acis_sci_run_rm_dupl.perl: clean up duplicated line	#
#							#
#  author: t. isobe (tisobe@cfa.harvard.edu)		#
#							#
#	last update: Jun 8, 2005			#
#							#
#########################################################


$file = $ARGV[0];
open(FH, "$file");
@list = ();
while(<FH>){
	chomp $_;
	push(@list, $_);
}
close(FH);

$first = shift(@list);
@new = ($first);
OUTER:
foreach $ent (@list){
	foreach $comp (@new){
		if($ent eq $comp){
			next OUTER;
		}
	}
	push(@new, $ent);
}

#@temp = sort{$a<=>$b} @new;
@temp = @new;

open(OUT, ">$file");
foreach $ent (@temp){
	print OUT "$ent\n";
}
