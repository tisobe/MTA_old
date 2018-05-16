#!/usr/bin/perl 

for($year = 2000; $year <= 2007; $year++){
	$name = './Ind_data_files/angle'."$year".'.dat';
	open(FH, "$name");
	@angle = ();
	@time  = ();
	$cnt   = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@angle, $atemp[2]);
		push(@time,  $atmpe[3]);
		$cnt++;
	};
	close(FH);

	$name = './Ind_data_files/scelec_'."$year".'_data';
	open(FH, "$name");
	$tot = 0;
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] !~ /\d/){
			next OUTER;
		}
		if($angle[$tot] >= 40 && $angle[$tot] < 60){
			open(OUT, ">>scelec_angle40");	
		}elsif($angle[$tot] >= 60 && $angle[$tot] < 80){
			open(OUT, ">>scelec_angle60");	
		}elsif($angle[$tot] >= 80 && $angle[$tot] < 100){
			open(OUT, ">>scelec_angle80");	
		}elsif($angle[$tot] >= 100 && $angle[$tot] < 120){
			open(OUT, ">>scelec_angle100");	
		}elsif($angle[$tot] >= 120 && $angle[$tot] < 140){
			open(OUT, ">>scelec_angle120");	
		}elsif($angle[$tot] >= 140 && $angle[$tot] < 160){
			open(OUT, ">>scelec_angle140");	
		}elsif($angle[$tot] >= 160 && $angle[$tot] < 180){
			open(OUT, ">>scelec_angle160");	
		}
	$fyear = sec1998_to_fracyear($atemp[2]);

		print OUT "$fyear\t$atemp[3]\t$atemp[4]\t$atemp[6]\t$atemp[7]\n";
		close(OUT);
		$tot++;
	}
	close(FH);
}
###############################################################################

sub sec1998_to_fracyear{

     my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac);

     ($t_temp) = @_;

     $t_temp += 86400;

     $normal_year = 31536000;
     $leap_year   = 31622400;
     $year           = 1998;

     $j = 0;
     OUTER:
     while($t_temp > 1){
        $jl = $j + 2;
        $chk = 4.0 * int(0.25 * $jl);
        if($chk == $jl){
                $base = $leap_year;
        }else{
                $base = $normal_year;
        }

        if($t_temp > $base){
                        $year++;
                        $t_temp -= $base;
                        $j++;
                }else{
                        $yfrac = $t_temp/$base;
                        $yearfac = $year + $yfrac;
                        last OUTER;
                }
     }

     return $yearfac;
}

