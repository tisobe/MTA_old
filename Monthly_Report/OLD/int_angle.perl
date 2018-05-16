#!/usr/bin/perl

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
}

$h_a = "85.462502";
$h_b = "86.212502";
$l_a = "85.087502";
$l_b = "83.962502";


for($i = 0; $i < $cnt; $i++) {

	$hain = 0;
	$haout = 0;
	$hbin = 0;
	$hbout = 0;
	$lain = 0;
	$laout = 0;
	$lbin = 0;
	$lbout = 0;

	$cnt_hain = 0;
	$cnt_haout = 0;
	$cnt_hbin = 0;
	$cnt_hbout = 0;
	$cnt_1ain = 0;
	$cnt_laout = 0;
	$cnt_lbin = 0;
	$cnt_laout = 0;

	$ind_hain = 0;
	$ind_haout = 0;
	$ind_hbin = 0;
	$ind_hbout = 0;
	$ind_lain = 0;
	$ind_laout = 0;
	$ind_lbin = 0;
	$ind_lbout = 0;

	open(FH, "../MJ/mta_comprehensive_data_summary");
	while(<FH>) {
		chomp $_;
		@atemp = split(/\t/,$_);
		@btemp = split(/:/,$atemp[0]);
		$eyear = $btemp[0];
		$eday  = $btemp[1];
	
		if($year[$i] == $eyear && $begin[$i] <= $eday && $end[$i] >= $eday) {
			$ha_diff = $atemp[9]  - $h_a;
			$hb_diff = $atemp[10] - $h_b;
			$la_diff = $atemp[11] - $l_a;
			$lb_diff = $atemp[12] - $l_b;
	
			$h_a = $atemp[9];
			$h_b = $atemp[10];
			$l_a = $atemp[11];
			$l_b = $atemp[12];
	
			if($ha_diff > 0 ) {
				$hain += $ha_diff;
				$ind_hain++;
#				$cnt_hain++;
			}elsif($ha_diff < 0) {
				$haout += $ha_diff;
				$ind_haout++;
#				$cnt_haout++;
			}
			if($ha_diff < 0 && $ind_hain > 0) {
				$cnt_hain++;
				$ind_hain = 0;
			}
			if($ha_diff > 0 && $ind_haout > 0) {
				$cnt_haout++;
				$ind_haout = 0;
			}
	
			if($hb_diff > 0 ) {
				$hbin += $hb_diff;
				$ind_hbin++;
#				$cnt_hbin++;
			}elsif($hb_diff < 0) {
				$hbout += $hb_diff;
				$ind_hbout++;
#				$cnt_hbout++;
			}
			if($hb_diff < 0 && $ind_hbin > 0) {
				$cnt_hbin++;
				$ind_hbin = 0;
			}
			if($hb_diff > 0 && $ind_hbout > 0) {
				$cnt_hbout++;
				$ind_hbout = 0;
			}
	
			if($la_diff > 0 ) {
				$lain += $la_diff;
				$ind_lain++;
#				$cnt_lain++;
			}elsif($la_diff < 0) {
				$laout += $la_diff;
				$ind_laout++;
#				$cnt_laout++;
			}
			if($la_diff < 0 && $ind_lain > 0) {
				$cnt_lain++;
				$ind_lain = 0;
			}
			if($la_diff > 0 && $ind_laout > 0) {
				$cnt_laout++;
				$ind_laout = 0;
			}
	
			if($lb_diff > 0 ) {
				$lbin += $lb_diff;
				$ind_lbin++;
#				$cnt_lbin++;
			}elsif($lb_diff < 0) {
				$lbout += $lb_diff;
				$ind_lbout++;
#				$cnt_lbout++;
			}
			if($lb_diff < 0 && $ind_lbin > 0) {
				$cnt_lbin++;
				$ind_lbin = 0;
			}
			if($lb_diff > 0 && $ind_lbout > 0) {
				$cnt_lbout++;
				$ind_lbout = 0;
			}


		}
	}
	close(FH);
	
	$avg_hain = 0;
	$avg_haout = 0;
	$avg_hbin = 0;
	$avg_hbout = 0;
	$avg_lain = 0;
	$avg_laout = 0;
	$avg_lbin = 0;
	$avg_lbout = 0;

	if($cnt_hain > 0) {
		$avg_hain = $hain/$cnt_hain;
	}
	if($cnt_haout > 0) {
		$avg_haout = $haout/$cnt_haout;
	}
	if($cnt_hbin > 0) {
		$avg_hbin = $hbin/$cnt_hbin;
	}
	if($cnt_hbout > 0) {
		$avg_hbout = $hbout/$cnt_hbout;
	}
	if($cnt_lain > 0) {
		$avg_lain = $lain/$cnt_lain;
	}
	if($cnt_laout > 0) {
		$avg_laout = $laout/$cnt_laout;
	}
	if($cnt_lbin > 0) {
		$avg_lbin = $lbin/$cnt_lbin;
	}
	if($cnt_lbout > 0) {
		$avg_lbout = $lbout/$cnt_lbout;
	}

	print "$year[$i]: $begin[$i] - $end[$i]\n";
	print "$hain/$cnt_hain\t$haout/$cnt_haout\t$hbin/$cnt_hbin\t$hbout/$cnt_hbout\t";
	print "$lain/$cnt_lain\t$laout/$cnt_laout\t$lbin/$cnt_lbin\t$lbout/$cnt_lbout\n";

	print "$avg_hain\t$avg_haout\t$avg_hbin\t$avg_hbout\t";

	print "$avg_lain\t$avg_laout\t$avg_lbin\t$avg_lbout\n";
}



