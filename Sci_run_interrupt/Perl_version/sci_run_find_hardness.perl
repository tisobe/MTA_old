#!/usr/bin/perl

#################################################################################################
#												#
#	sci_run_find_hardness.perl: find hradness and other statistics of the radiation curves	#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Mar 17, 2011							#
#												#
#################################################################################################

#################################################################
#
#--- setting directories
#

open(FH, "/data/mta/Script/Interrupt/house_keeping/dir_list");

@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$data_dir      = $atemp[1];
$web_dir       = $atemp[2];
$house_keeping = $atemp[3];

################################################################

#
#--- if the next input is given as arguments, use it, otherwise, ask
#--- a user to type it in.
#

#
#--- list of data
#

$list      = $ARGV[0];

if($list eq ''){

	print "Time List: ";
	$list = <STDIN>;
}

chomp $list;

@name_list  = ();
@start_list = ();
@end_list   = ();
$dat_cnt    = 0;

open(FH, "$list");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@name_list,  $atemp[0]);
	push(@start_list, $atemp[1]);
	push(@end_list,   $atemp[2]);
	$dat_cnt++;
}
close(FH);

for($i = 0; $i < $dat_cnt; $i++){
	
####	print "$name_list[$i]\n";

	@atemp  = split(/:/, $start_list[$i]);
	$uyear  = $atemp[0];
	$umonth = $atemp[1];
	$uday   = $atemp[2];
#
#--- change date to day of the year
#
	to_doy();

	$start  = $uyday + $atemp[3]/24 + $atemp[4]/1440;

	@atemp  = split(/:/, $end_list[$i]);
	$uyear  = $atemp[0];
	$umonth = $atemp[1];
	$uday   = $atemp[2];

	to_doy();

	$end    = $uyday + $atemp[3]/24 + $atemp[4]/1440;
	
#
#--- setting several boundaries for computations
#

	$period_start = $start - 2.0;
	$period_end   = $start + 3.0;
	$check_start  = $start - 0.1;
	$tend         = $end   + 0.1;
	$check_end    = $start + 3.0;

	if($tend < $period_end){
		$check_end  = $tend;
	}
	
	$dname           = "$name_list[$i]".'_dat.txt';
	$chk             = 0;
	$cnt1            = 0;
	$cnt2            = 0;
	$cnt3            = 0;
	$cnt4            = 0;
	$cnt5            = 0;
	$cnt6            = 0;
	$cnt7            = 0;
	$cnt8            = 0;
	$cnt9            = 0;
	$cnt10           = 0;
	$cnt11           = 0;
	$cnt12           = 0;
	$cnt13           = 0;
	$e38_a           = 0;
	$e38_a2          = 0;
	$e175_a          = 0;
	$e175_a2         = 0;
	$p47_a           = 0;
	$p47_a2          = 0;
	$p112_a          = 0;
	$p112_a2         = 0;
	$p310_a          = 0;
	$p310_a2         = 0;
	$p761_a          = 0;
	$p761_a2         = 0;
	$p1060_a         = 0;
	$p1060_a2        = 0;
	$aniso_a         = 0;
	$aniso_a2        = 0;
	$r38_175_a       = 0;
	$r38_175_a2      = 0;
	$r47_1060_a      = 0;
	$r47_1060_a2     = 0;
	$r112_1060_a     = 0;
	$r112_1060_a2    = 0;
	$r310_1060_a     = 0;
	$r310_1060_a2    = 0;
	$r761_1060_a     = 0;
	$r761_1060_a2    = 0;
	
	$e38_max         = 0;
	$e38_min         = 1.0e10;
	$e175_max        = 0;
	$e175_min        = 1.0e10;
	$p47_max         = 0;
	$p47_min         = 1.0e10;
	$p112_max        = 0;
	$p112_min        = 1.0e10;
	$p310_max        = 0;
	$p310_min        = 1.0e10;
	$p761_max        = 0;
	$p761_min        = 1.0e10;
	$p1060_max       = 0;
	$p1060_min       = 1.0e10;
	$aniso_max       = 0;
	$aniso_min       = 1.0e10;
	$r38_175_max     = 0;
	$r38_175_min     = 1.0e10;
	$r47_1060_max    = 0;
	$r47_1060_min    = 1.0e10;
	$r112_1060_max   = 0;
	$r112_1060_min   = 1.0e10;
	$r310_1060_max   = 0;
	$r310_1060_min   = 1.0e10;
	$r761_1060_max   = 0;
	$r761_1060_min   = 1.0e10;
	
	$e38_max_t       = 0;
	$e38_min_t       = 0;
	$e175_max_t      = 0;
	$e175_min_t      = 0;
	$p47_max_t       = 0;
	$p47_min_t       = 0;
	$p112_max_t      = 0;
	$p112_min_t      = 0;
	$p310_max_t      = 0;
	$p310_min_t      = 0;
	$p761_max_t      = 0;
	$p761_min_t      = 0;
	$p1060_max_t     = 0;
	$p1060_min_t     = 0;
	$aniso_max_t     = 0;
	$aniso_min_t     = 0;
	$r38_175_max_t   = 0;
	$r38_175_min_t   = 0;
	$r47_1060_max_t  = 0;
	$r47_1060_min_t  = 0;
	$r112_1060_max_t = 0;
	$r112_1060_min_t = 0;
	$r310_1060_max_t = 0;
	$r310_1060_min_t = 0;
	$r761_1060_max_t = 0;
	$r761_1060_min_t = 0;

	open(FH, "$web_dir/Data_dir/$dname");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[0] =~/\d/ ){
			$time = $atemp[0];

		   	if($time > $period_start && $time < $period_end){
				$e38  = $atemp[1];
				if($e38 > 0){
					$cnt1++;
					if($e38 > $e38_max){
						$e38_max = $e38;
						$e38_max_t = $time;
					}
					if($e38 < $e38_min){
						$e38_min = $e38;
						$e38_min_t = $time;
					}
					$e38_a    += $e38;
					$e38_a2   += $e38*$e38;
				}
	
				$e175 = $atemp[2];
				if($e175 > 0){
					$cnt2++;
					if($e175 > $e175_max){
						$e175_max = $e175;
						$e175_max_t = $time;
					}
					if($e175 < $e175_min){
						$e175_min = $e175;
						$e175_min_t = $time;
					}
					$e175_a   += $e175;
					$e175_a2  += $e175*$e175;
				}

				$p47  = $atemp[3];
				if($p47 > 0){
					$cnt3++;
					if($p47 > $p47_max){
						$p47_max = $p47;
						$p47_max_t = $time;
					}
					if($p47 < $p47_min){
						$p47_min = $p47;
						$p47_min_t = $time;
					}
					$p47_a    += $p47;
					$p47_a2   += $p47*$p47;
				}

				$p112 = $atemp[4];
				if($p112 > 0){
					$cnt4++;
					if($p112 > $p112_max){
						$p112_max = $p112;
						$p112_max_t = $time;
					}
					if($p112 < $p112_min){
						$p112_min = $p112;
						$p112_min_t = $time;
					}
					$p112_a   += $p112;
					$p112_a2  += $p112*$p112;
				}
	
				$p310 = $atemp[5];
				if($p310 > 0){
					$cnt5++;
					if($p310 > $p310_max){
						$p310_max = $p310;
						$p310_max_t = $time;
					}
					if($p310 < $p310_min){
						$p310_min = $p310;
						$p310_min_t = $time;
					}
					$p310_a   += $p310;
					$p310_a2  += $p310*$p310;
				}
	
				$p761 = $atemp[6];
				if($p761 > 0){
					$cnt6++;
					if($p761 > $p761_max){
						$p761_max = $p761;
						$p761_max_t = $time;
					}
					if($p761 < $p761_min){
						$p761_min = $p761;
						$p761_min_t = $time;
					}
					$p761_a   += $p761;
					$p761_a2  += $p761*$p761;
				}
	
				$p1060= $atemp[7];
				if($p1060 > 0){
					$cnt7++;
					if($p1060 > $p1060_max){
						$p1060_max = $p1060;
						$p1060_max_t = $time;
					}
					if($p1060 < $p1060_min){
						$p1060_min = $p1060;
						$p1060_min_t = $time;
					}
					$p1060_a  += $p1060;
					$p1060_a2 += $p1060*$p1060;
				}
	
				$aniso= $atemp[8];
				if($aniso > 0){
					$cnt8++;
					if($aniso > $aniso_max){
						$aniso_max = $aniso;
						$aniso_max_t = $time;
					}
					if($aniso < $aniso_min){
						$aniso_min = $aniso;
						$aniso_min_t = $time;
					}
					$aniso_a  += $aniso;
					$aniso_a2 += $aniso*$aniso;
				}
	
				if($e175 > 0){
					$r38_175   = $e38/$e175;
					if($r38_175 > 0){
						$cnt9++;
						if($r38_175 > $r38_175_max){
							$r38_175_max = $r38_175;
							$r38_175_max_t = $time;
						}
						if($r38_175 < $r38_175_min){
							$r38_175_min = $r38_175;
							$r38_175_min_t = $time;
						}
						$r38_175_a    += $r38_175;
						$r38_175_a2   += $r38_175*$r38_175;
					}
				}

				if($p1060 > 0){
					$r47_1060  = $p47/$p1060;
					if($r47_1060 > 0){
						$cnt10++;
						if($r47_1060 > $r47_1060_max){
							$r47_1060_max = $r47_1060;
							$r47_1060_max_t = $time;
						}
						if($r47_1060 < $r47_1060_min){
							$r47_1060_min = $r47_1060;
							$r47_1060_min_t = $time;
						}
						$r47_1060_a   += $r47_1060;
						$r47_1060_a2  += $r47_1060*$r47_1060;
					}
		
					$r112_1060 = $p112/$p1060;
					if($r112_1060 > 0){
						$cnt11++;
						if($r112_1060 > $r112_1060_max){
							$r112_1060_max = $r112_1060;
							$r112_1060_max_t = $time;
						}
						if($r112_1060 < $r112_1060_min){
							$r112_1060_min = $r112_1060;
							$r112_1060_min_t = $time;
						}
						$r112_1060_a  += $r112_1060;
						$r112_1060_a2 += $r112_1060*$r112_1060;
					}
		
					$r310_1060 = $p310/$p1060;
					if($r310_1060 > 0){
						$cnt12++;
						if($r310_1060 > $r310_1060_max){
							$r310_1060_max = $r310_1060;
							$r310_1060_max_t = $time;
						}
						if($r310_1060 < $r310_1060_min){
							$r310_1060_min = $r310_1060;
							$r310_1060_min_t = $time;
						}
						$r310_1060_a  += $r310_1060;
						$r310_1060_a2 += $r310_1060*$r310_1060;
					}
		
					$r761_1060 = $p761/$p1060;
					if($r761_1060 > 0){
						$cnt13++;
						if($r761_1060 > $r761_1060_max){
							$r761_1060_max = $r761_1060;
							$r761_1060_max_t = $time;
						}
						if($r761_1060 < $r761_1060_min){
							$r761_1060_min = $r761_1060;
							$r761_1060_min_t = $time;
						}
						$r761_1060_a  += $r761_1060;
						$r761_1060_a2 += $r761_1060*$r761_1060;
					}
				}
	
				if($time >= $start && $chk == 0){
					$e38_int   = $e38;
					$e175_int  = $e175;
					$p47_int   = $p47;
					$p112_int  = $p112;
					$p310_int  = $p310;
					$p761_int  = $p761;
					$p1060_int = $p1060;
					$aniso_int = $aniso;
					$r38_175_int   = $r38_175;
					$r47_1060_int  = $r47_1060;
					$r112_1060_int = $r112_1060;
					$r310_1060_int = $r310_1060;
					$r761_1060_int = $r761_1060;
					$chk++;
				}
	
				$cnt++;
		  	}			# check time loop end
		}
	}
	if($cnt1 == 0){
		$e38_avg   =	0;	
		$e38_var   =	0;	
	}else{
		$e38_avg   =	$e38_a/$cnt1;
		$e38_var   =	sqrt($e38_a2/$cnt1  - $e38_avg * $e38_avg);
	}
	if($cnt2 == 0){
		$e175_avg  =	0;
		$e175_var  =	0;
	}else{
		$e175_avg  =	$e175_a/$cnt2;
		$e175_var  =	sqrt($e176_a2/$cnt2 - $e175_avg*$e176_avg);
	}

	if($cnt3 == 0){
		$p47_avg   =	0;
		$p47_var   =	0;
	}else{
		$p47_avg   =	$p47_a/$cnt3;
		$p47_var   =	sqrt($p47_a2/$cnt3  - $p47_avg * $p47_avg);
	}

	if($cnt4 == 0){
		$p112_avg  =	0;
		$p112_var  =	0;
	}else{
		$p112_avg  =	$p112_a/$cnt4;
		$p112_var  =	sqrt($p112_a2/$cnt4 - $p112_avg * $p112_avg);
	}

	if($cnt5 == 0){
		$p310_avg  =	0;
		$p310_var  =	0;
	}else{
		$p310_avg  =	$p310_a/$cnt5;
		$p310_var  =	sqrt($p310_a2/$cnt5 - $p310_avg * $p310_avg);
	}

	if($cnt6 == 0){
		$p761_avg  =	0;
		$p761_var  =	0;
	}else{
		$p761_avg  =	$p761_a/$cnt6;
		$p761_var  =	sqrt($p761_a2/$cnt6 - $p761_avg * $p761_avg);
	}

	if($cnt7 == 0){
		$p1060_avg =	0;
		$p1060_var =	0;
	}else{
		$p1060_avg =	$p1060_a/$cnt7;
		$p1060_var =	sqrt($p1060_a2/$cnt7 - $p1060_avg * $p1060_avg);
	}

	if($cnt8 == 0){
		$aniso_avg =	0;
		$aniso_var =	0;
	}else{
		$aniso_avg =	$aniso_a/$cnt8;
		$aniso_var =	sqrt($aniso_a2/$cnt8 - $aniso_avg * $aniso_avg);
	}

	if($cnt9 == 0){
		$r38_175_avg   =  0;
		$r38_175_var   =  0;
	}else{
		$r38_175_avg   =  $r38_175_a/$cnt9;
		$r38_175_var   =  sqrt($r38_175_a2/$cnt9 - $r38_175_avg * $r38_175_avg);
	}

	if($cnt10 == 0){
		$r47_1060_avg  =  0;
		$r47_1060_var  =  0;
	}else{
		$r47_1060_avg  =  $r47_1060_a/$cnt10;
		$r47_1060_var  =  sqrt($r47_1060_a2/$cnt10 - $r47_1060_avg * $r47_1060_avg);
	}

	if($cnt11 == 0){
		$r112_1060_avg =  0;
		$r112_1060_var =  0;
	}else{
		$r112_1060_avg =  $r112_1060_a/$cnt11;
		$r112_1060_var =  sqrt($r112_1060_a2/$cnt11 - $r112_1060_avg * $r112_1060_avg);
	}

	if($cnt12 == 0){
		$r310_1060_avg =  0;
		$r310_1060_var =  0;
	}else{
		$r310_1060_avg =  $r310_1060_a/$cnt12;
		$r310_1060_var =  sqrt($r310_1060_a2/$cnt12 - $r310_1060_avg * $r310_1060_avg);
	}

	if($cnt13 == 0){
		$r761_1060_avg =  0;
		$r761_1060_var =  0;
	}else{
		$r761_1060_avg =  $r761_1060_a/$cnt13;
		$r761_1060_var =  sqrt($r761_1060_a2/$cnt13 - $r761_1060_avg * $r761_1060_avg);
	}

	$out_name = "$web_dir". '/Stat_dir/'."$name_list[$i]".'_stat';

	open(OUT, ">$out_name");
	print  OUT "5 day Period (dom):";
	printf OUT "%5.4f - %5.4f\n", $period_start, $period_end;
	print  OUT "Interruption (dom):";
	printf OUT "%5.4f - %5.4f\n", $start ,$end;
	print  OUT "\t	Avg\t\t\t Max\t\tTime\t\tMin\t\tTime\tValue at Interruption Started\n";
	print  OUT "-----------------------------------------------------------------------------";
	print  OUT "---------------------------------------------\n";
	printf OUT "e38\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$e38_avg,$e38_var,$e38_max,$e38_max_t,$e38_min,$e38_min_t,$e38_int;
	printf OUT "e175\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$e175_avg,$e175_var,$e175_max,$e175_max_t,$e175_min,$e175_min_t,$e175_int;
	printf OUT "p47\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$p47_avg,$p47_var,$p47_max,$p47_max_t,$p47_min,$p47_min_t,$p47_int;
	printf OUT "p112\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$p112_avg,$p112_var,$p112_max,$p112_max_t,$p112_min,$p112_min_t,$p112_int;
	printf OUT "p310\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$p310_avg,$p310_var,$p310_max,$p310_max_t,$p310_min,$p310_min_t,$p310_int;
	printf OUT "p761\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$p761_avg,$p761_var,$p761_max,$p761_max_t,$p761_min,$p761_min_t,$p761_int;
	printf OUT "p1060\t\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$p1060_avg,$p1060_var,$p1060_max,$p1060_max_t,$p1060_min,$p1060_min_t,$p1060_int;
	printf OUT "anisotropy\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$aniso_avg,$aniso_var,$aniso_max,$aniso_max_t,$aniso_min,$aniso_min_t,$aniso_int;
	print  OUT "\nHardness:\n";
	print  OUT "---------\n";
	printf OUT "e38/e175\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$r38_175_avg,$r38_175_var,$r38_175_max,$r38_175_max_t,$r38_175_min,$r38_175_min_t,$r38_175_int;
	printf OUT "p47/p1060\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$r47_1060_avg,$r47_1060_var,$r47_1060_max,$r47_1060_max_t,$r47_1060_min,$r47_1060_min_t,$r47_1060_int;
	printf OUT "p112/p1060\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$r112_1060_avg,$r112_1060_var,$r112_1060_max,$r112_1060_max_t,$r112_1060_min,$r112_1060_min_t,$r112_1060_int;

	printf OUT "p310/p1060\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$r310_1060_avg,$r310_1060_var,$r310_1060_max,$r310_1060_max_t,$r310_1060_min,$r310_1060_min_t,$r310_1060_int;

	printf OUT "p761/p1060\t%4.3e+/-%4.3e\t%4.3e\t%4.3f \t%4.3e\t%4.3f\t\t%4.3e\n",
			$r761_1060_avg,$r761_1060_var,$r761_1060_max,$r761_1060_max_t,$r761_1060_min,$r761_1060_min_t,$r761_1060_int;

#
#---- find gradient
#

	find_grad();

	close(OUT);
}

##############################################################
### to_doy: date to day of the year                        ###
##############################################################

sub to_doy{
        if($umonth == 1){
                $add = 0;
        }elsif($umonth == 2){
                $add = 31;
        }elsif($umonth == 3){
                $add = 59;
        }elsif($umonth == 4){
                $add = 90;
        }elsif($umonth == 5){
                $add = 120;
        }elsif($umonth == 6){
                $add = 151;
        }elsif($umonth == 7){
                $add = 181;
        }elsif($umonth == 8){
                $add = 212;
        }elsif($umonth == 9){
                $add = 243;
        }elsif($umonth == 10){
                $add = 273;
        }elsif($umonth == 11){
                $add = 304;
        }elsif($umonth == 12){
                $add = 334;
        }

        $uyday = $uday + $add;

	if($umonth > 2){
        	if($uyear == 2000){
			$uyday++;
        	}elsif($uyear == 2004) {
			$uyday++;
        	}elsif($uyear == 2008) {
			$uyday++;
        	}elsif($uyear == 2012) {
			$uyday++;
        	}
	}
}

##########################################################################
### find_grad: finding gradiant                                        ###
##########################################################################

sub find_grad{

	@time = ();
	@e1   = ();
	@e2   = ();
	@p1   = ();
	@p2   = ();
	@p3   = ();
	@p4   = ();
	@p5   = ();
	@p6   = ();
	@p7   = ();
	@p8   = ();
	@ans  = ();
	$fcnt = 0;
	
	open(FH, "$web_dir/Data_dir/$dname");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@time, $atemp[0]);
		for($j = 1; $j < 9; $j++){
			if($atemp[$j]<= 0){
				$atemp[$j] = 1.0e-5;
			}
		}
		push(@e1, log($atemp[1]));
		push(@e2, log($atemp[2]));
		push(@p1, log($atemp[3]));
		push(@p2, log($atemp[4]));
		push(@p3, log($atemp[5]));
		push(@p4, log($atemp[6]));
		push(@p5, log($atemp[7]));
		push(@ans, $atemp[8]);
		$fcnt++;
	}
	close(FH);
	
	print OUT "\n";
	print OUT "Steepest Rise\n";
	print OUT "------------\n";
	print OUT "\tTime\tSlope(in log per hr)\n";
	print OUT '----------------------------------------',"\n";
	@ent = @e1;
	find_jump();
	print OUT "e38\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @e2;
	find_jump();
	printf OUT "e175\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @p1;
	find_jump();
	printf OUT "p47\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @p2;
	find_jump();
	print OUT "p112\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @p3;
	find_jump();
	print OUT "p310\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @p4;
	find_jump();
	print OUT "p761\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
	
	@ent = @p5;
	find_jump();
	print OUT "p1060\t";
	printf OUT "%5.4f\t%3.4f\n",$time[$max_pos],$max_slope;
}	

##############################################################################
### find_jump: find the largest jump                                       ###
##############################################################################

sub find_jump {
	$last      = $cnt - 10;
	$diff      = 24.0 * ($time[20] - $time[19]);
	$max_slope = 0;
	$max_pos   = 0;

	for($k = 10; $k < $last; $k++){
		$start = $k;
		$end   = $k + 1;
		$sum   = 0;

		for($m = 0; $m < 10; $m++){
			$sum += $ent[$end] - $ent[$start];
			$start++;
			$end++;
		}

		if($diff > 0){
			$slope = 0.1*$sum/$diff;
			if($slope > $max_slope){
				$max_slope = $slope;
				$max_pos   = $k + 5;
			}
		}
	}
}
