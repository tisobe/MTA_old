#!/usr/bin/perl

#########################################################################
#									#
#	sim_tot.perl: compute TSC/FA movement for the month		#
#									#
#	Need: month_list						#
#	      ../MJ/Save/comprehensive_data_summary			#
#									#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)			#
#									#
#	Aug 9, 2000:	first version					#
#									#
#########################################################################


open(FH, "./month_list");

$cnt = 0;
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/, $_);
	push(@year, $atemp[0]);
	push(@begin, $atemp[1]);
	push(@end, $atemp[2]);
	$cnt++;
}
close(FH);


for($i = 0; $i < $cnt; $i++) {
	${tscpos_sum.$i} = 0;
	${fapos_sum.$i} = 0;
}

for($i = 0; $i < $cnt; $i++) {
	open(FH, "../MJ/Save/comprehensive_data_summary");
	while(<FH>) {
		chomp $_;
		@atemp = split(/\t/,$_);
		@btemp = split(/:/,$atemp[0]);
		$eyear = $btemp[0];
		$eday  = $btemp[1];
		$tscpos = $atemp[1];
		$fapos  = $atemp[2];
	
		if($year[$i] == $eyear && $begin[$i] <= $eday && $end[$i] >= $eday) {
#$xxx = abs($tscpos - $prev_tscpos);
#print "$xxx\n";
			${tscpos_sum.$i} += abs($tscpos - $prev_tscpos);
			${fapos_sum.$i} += abs($fapos - $prev_fapos);
		}
		$prev_tscpos = $tscpos;
		$prev_fapos  = $fapos;
	}
}
close(FH);

for($i = 0; $i < $cnt; $i++) {
	print "${tscpos_sum.$i}\t${fapos_sum.$i}\n";
}
