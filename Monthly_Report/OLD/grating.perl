#!/usr/bin/perl

#################################################################################
#										#
#	grating.perl: find no. of insertion/retraction of HETG/LETG		#
#										#
#	Need: month_list, ../ACIS/Save/sim_data_summary				#
#										#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)				#
#										#
#	Aug. 8, 2000: first version						#
#										#
#################################################################################


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
	${hetg_cnt.$i} = 0;
	${letg_cnt.$i} = 0;
	${hetg_cntb.$i} = 0;
	${letg_cntb.$i} = 0;
}

$hilsa = "INSR";
$hilsb = "RETR";
$lilsa = "INSR";
$lilsb = "RETR";
$ha_on = "DISA";
$hb_on = "DISA";
$la_on = "DISA";
$lb_on = "DISA";

open(OUT, ">zzz");
open(OUT2, ">zzz2");

for($i = 0; $i < $cnt; $i++) {
	open(FH, "../ACIS/Save/sim_data_summary");
	while(<FH>) {
		chomp $_;
		@atemp = split(/\t/,$_);
		@btemp = split(/:/,$atemp[0]);
		$eyear = $btemp[0];
		$eday  = $btemp[1];
	
		$ehilsa = $atemp[6];
		$ehilsb = $atemp[7];
		$elilsa = $atemp[8];
		$elilsb = $atemp[9];
		$eha_on  = $atemp[10];
		$ehb_on  = $atemp[11];
		$ela_on	= $atemp[12];
		$elb_on  = $atemp[13];


		if($year[$i] == $eyear && $begin[$i] <= $eday && $end[$i] >= $eday) {

print OUT  "$atemp[0]:\t$ehilsa\t$eha_on\t$elilsa\t$ela_on\n";
print OUT2 "$atemp[0]:\t$ehilsb\t$ehb_on\t$elilsb\t$elb_on\n";

			if(($ehilsa ne $hilsa) && ($ha_on =~ /ENAB/)) {
				${hetg_cnt.$i}++;
			}
			if(($ehilsb ne $hilsb) && ($hb_on =~ /ENAB/)) {
				${hetg_cntb.$i}++;
			}
			if(($elilsa ne $lilsa) && ($la_on =~ /ENAB/)) {
				${letg_cnt.$i}++;
			}
			if(($elilsb ne $lilsb) && ($lb_on =~ /ENAB/)) {
				${letg_cntb.$i}++;
			}

		}
		$hilsa = $ehilsa;
		$hilsb = $ehilsb;
		$lilsa = $elilsa;
		$lilsb = $elilsb;
		$ha_on = $eha_on;
		$hb_on = $ehb_on;
		$la_on = $ela_on;
		$lb_on = $elb_on;
	}
	close(FH);

	print "${hetg_cnt.$i}\t${letg_cnt.$i}\t";
	print "${hetg_cntb.$i}\t${letg_cntb.$i}\n";
}



