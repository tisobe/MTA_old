#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	solar_panel_angle_comb.perl: this script combine solar panel data and solar agnle data.	#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Jun 05, 2013							#
#												#
#################################################################################################

#
#--- read the latest year
#

$this_year = $ARGV[0];
chomp $this_year;

#
#--- test case; set this "test"
#

$comp_test = $ARGV[1];
chomp $comp_test;

#
#--- set directory
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
	$begin_year = 2010;
}else{
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
	$begin_year = 2000;
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#--- clean up the working directory; remove files named "solar_panel_angle*"
#
$check = `ls `;
if($check =~ /solar_panel_angle/){
	system("rm -rf solar_panel_angle*0");
}

for($year = $begin_year; $year <= $this_year; $year++){
	$file1 = "$data_dir".'/Ind_data_files/angle'."$year".'.dat';
	$file2 = "$data_dir".'/Ind_data_files/solar_panel'."$year".'.dat';

	@time    = ();
	@time2   = ();
	@angle   = ();
	@tmysada = ();
	@tpysada = ();
	@tsamyt  = ();
	@tsapyt  = ();
	$cnt     = 0;
	$cnt2    = 0;

	open(FH, "$file1");		#----- solar angle data
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] !~ /\d/){
			next OUTER;
		}
		if($atemp[0] =~ /\d/){
			push(@time,  $atemp[1]);
			push(@angle, $atemp[2]);
		}else{
			push(@time,  $atemp[2]);
			push(@angle, $atemp[3]);
		}
		$cnt++;
	}
	close(FH);

	open(FH, "$file2");		#----- solar panel temperature data
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] !~ /\d/){
			next OUTER;
		}
		if($atemp[0] =~ /\d/){
			push(@time2,   $atemp[1]);
			push(@tmysada, $atemp[2]);
			push(@tpysada, $atemp[3]);
			push(@tsamyt,  $atemp[4]);
			push(@tsapyt,  $atemp[5]);
			$cnt2++;
		}else{
			push(@time2,   $atemp[2]);
			push(@tmysada, $atemp[3]);
			push(@tpysada, $atemp[4]);
			push(@tsamyt,  $atemp[5]);
			push(@tsapyt,  $atemp[6]);
			$cnt2++;
		}
	}
	close(FH);

#
#-- find matched time interval
#
	$m = 0;
	OUTER2:
	for($k = 0; $k < $cnt2; $k++){
		if($tmysada[$k] !~ /\d/ || $tpysada[$k] !~ /\d/ || $tsamyt[$k] !~ /\d/ 
			|| $tsapyt[$k] !~ /\d/ || $angle[$k] !~ /\d/){
			next OUTER2;
		}

		if($time[$m -1] < $time2[$k] && $time[$m] >= $time2[$k]){
		}elsif($time[$m] < $time2[$k]){
			OUTER3:
			while($time[$m] < $time2[$k]){
				$m++;
				if($time[$m -1] < $time2[$k] && $time[$m] >= $time2[$k]){
					last OUTER3;
				}
				if($m > $cnt){
					last OUTER2;
				}
			}
		}elsif($time[$m] > $time2[$k]){
			OUTER3:
			while($time[$m] > $time2[$k]){
				$m--;
				if($time[$m -1] < $time2[$k] && $time[$m] >= $time2[$k]){
					last OUTER3;
				}
				if($m < 0){
					$m = 0;
					next OUTER2;
				}
			}
		}

                if($angle[$m] > 40  && $angle[$m] <= 60){
                        open(OUT, ">>./solar_panel_angle40");

                }elsif($angle[$m] > 60  && $angle[$m] <= 80){
                        open(OUT, ">>./solar_panel_angle60");

                }elsif($angle[$m] > 80  && $angle[$m] <= 100){
                        open(OUT, ">>./solar_panel_angle80");

                }elsif($angle[$m] > 100  && $angle[$m] <= 120){
                        open(OUT, ">>./solar_panel_angle100");

                }elsif($angle[$m] > 120  && $angle[$m] <= 140){
                        open(OUT, ">>./solar_panel_angle120");

                }elsif($angle[$m] > 140  && $angle[$m] <= 160){
                        open(OUT, ">>./solar_panel_angle140");

                }elsif($angle[$m] > 160  && $angle[$m] <= 180){
                        open(OUT, ">>./solar_panel_angle160");

                }

		$year_time = sec1998_to_fracyear($time2[$k]);

		print OUT "$year_time\t$tmysada[$k]\t$tpysada[$k]\t$tsamyt[$k]\t$tsapyt[$k]\t$angle[$m]\n";
		close(OUT);
		$m++;
	}
}

#
#--- replace old ones with the new one just complied
#

system("mv solar_panel_angle* $data_dir/Data_solar_panel/");


###############################################################################
###sec1998_to_fracyear: change sec from 1998 to time in year               ####
###############################################################################

sub sec1998_to_fracyear{

        my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac);

        ($t_temp) = @_;

        $t_temp += 86400;

        $normal_year = 31536000;
        $leap_year   = 31622400;
        $year        = 1998;

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

