#!/usr/bin/perl

#
#--- this script combines battery data
#

for($year = 2000; $year <= 2007; $year++){
	$file1 = './Ind_data_files/batt'."$year".'.dat';

	@time    = ();
	@eb1ci	 = ();
	@eb1v    = ();
	@eb2ci   = ();
	@eb2v    = ();
	$cnt     = 0;

	open(FH, "$file1");
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] !~ /\d/){
			next OUTER;
		}
		$year_time = sec1998_to_fracyear($atemp[2]);
#		push(@time,  $year_time);
#		push(@eb1ci, $atemp[4]);
#		push(@eb1v,  $atemp[5]);
#		push(@eb2ci, $atemp[6]);
#		push(@ev2v,  $atemp[7]);
#		$cnt++;
		print "$year_time\t";
		print "$atemp[3]\t";
		print "$atemp[4]\t";
		print "$atemp[5]\t";
		print "$atemp[6]\n";
	}
	close(FH);
}


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

