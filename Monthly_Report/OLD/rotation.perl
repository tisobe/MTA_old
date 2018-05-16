#!/usr/bin/perl

#########################################################################
#									#
#	rotation.perl: compute total rotation for the month		#
#									#
#	Need:	month_list						#
#		/data/mta/Script/Trending/Outdir/			#
#									#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)			#
#									#
#	Aug. 9, 2000:	first version					#
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
	push(@month, $atemp[3]);
#print "$atemp[0]	$atemp[1]	$atemp[2]	$atemp[3]\n";
        $cnt++;
}
close(FH);

`ls /data/mta/Script/Trending/Outdir/ > trend_list`;
#`ls /18/swolk/MTA/Trending/Outdir/ > trend_list`;

@date_list= ();
for($i = 0; $i < $cnt; $i++) {
	for($n = 1; $n < 7; $n++) {
		${aor.$n.$i} = 0;
	}
}
 
open(FH, "./trend_list");
while(<FH>) {
	chomp $_;
	@atemp = split(/Outdir\//,$_);
	@btemp = split(//,$atemp[0]);
	$eyear = "$btemp[0]"."$btemp[1]"."$btemp[2]"."$btemp[3]";
	$emonth = "$btemp[4]"."$btemp[5]";

	for($i = 0; $i < $cnt; $i++) {
		if($eyear == $year[$i] && $emonth == $month[$i]){
#print "$eyear	$emonth $atemp[0]\n";
			open(IN, "/data/mta/Script/Trending/Outdir/$atemp[0]/tot_rwrate.ascii");
#			open(IN, "/18/swolk/MTA/Trending/Outdir/$atemp[0]/tot_rwrate.ascii");
			$n = 1;
			while(<IN>) {
				chomp $_;
				@ctemp = split(/\t/, $_);
				${aor.$n.$i} += abs($ctemp[6]);
				$n++;
			}
		}
	}
}

for($i = 0; $i < $cnt; $i++) {
	for($n = 1; $n < 7; $n++) {
		print "${aor.$n.$i}\t";
	}
	print "\n";
}
				
