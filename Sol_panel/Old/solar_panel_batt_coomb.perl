#!/usr/bin/perl

#
#---- create data set with solar pannel data and battery current and voltagae
#

$file1 = './Data/batt_full.dat';

@time1    = ();
@current1 = ();
@voltage1 = ();
@current2 = ();
@voltage2 = ();
$cnt1     = 0;

open(FH, "$file1");
$j = 0;
while(<FH>){
	if($j == 12){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@time1,    $atemp[0]);
		push(@current1, $atemp[1]);
		push(@voltage1, $atemp[2]);
		push(@current2, $atemp[3]);
		push(@voltage2, $atemp[4]);
		$cnt1++;
		$j = 0;
	}
	$j++;
}
close(FH);

$file2  = './Data/data_angle140';

@time2     = ();
@sada1     = ();
@sada2     = ();
@sol1      = ();
@sol2      = ();
$cnt2      = 0;

open(FH, "$file2");
open(OUT, '>comb_data');
$j = 0;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	while($time1[$j] < $atemp[0]){
		$j++;
		if($time1[$j-1] < $atemp[0] && $time1[$j] >= $atemp[0]){
			print OUT "$time1[$j]\t";
			print OUT "$current1[$j]\t";
			print OUT "$voltage1[$j]\t";
			print OUT "$current2[$j]\t";
			print OUT "$voltage2[$j]\t";
			print OUT "$atemp[1]\t";
			print OUT "$atemp[2]\t";
			print OUT "$atemp[3]\t";
			print OUT "$atemp[4]\n";
			next OUTER;
		}
		if($j > $cnt1){
			last OUTER;
		}
	}
}
close(FH);	

