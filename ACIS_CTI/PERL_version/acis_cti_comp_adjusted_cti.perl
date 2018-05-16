#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	comp_adjusted_cti.perl: compute a new adjust ment factor for temp 	#
#			        dependency of CTI, and modify the data		#
#										#
#	Author: T. Isobe (tisobe@cfa.harvard.edu)				#
#	Last update: Apr 15, 2013						#
#		modified to fit a new directory system				#
#										#
#################################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;

#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#########################################

$dir = "$data_dir/Results";

foreach $elem (al, mn, ti){
	$elm_factor = "$elem".'_factor';
	open(ZOUT, ">$data_dir/$elm_factor");
	for($ccd = 0; $ccd < 10; $ccd++){
		$file     = "$elem".'_ccd'."$ccd";
		$in_file  = "$dir".'/'."$file";	
		$out_file = "$data_dir".'/Data_adjust/'."$file";

		@time  = ();
		@quad0 = ();
		@quad1 = ();
		@quad2 = ();
		@quad3 = ();
		$icnt   = 0;
		
		@time2 = ();
		@aquad0 = ();
		@aquad1 = ();
		@aquad2 = ();
		@aquad3 = ();
		
		@error0 = ();
		@error1 = ();
		@error2 = ();
		@error3 = ();
		@temperature = ();
		@del_temp    = ();
		$acnt   = 0;
		
		@qquad0 = ();
		@qquad1 = ();
		@qquad2 = ();
		@qquad3 = ();
		
		@tstart = ();
		@tstop  = ();
		@obsid  = ();
		@duration = ();
		
		open(FH, "$in_file");
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
#
#
#### if the integration time is less than 1000 sec, drop the data
#### if the integration time is less than 2000 sec, and the observation was done after
#### Jan 2003, drop the data
#### we also select out data with the focal plane temp <= 119.7 and integration time 
#### larger than 7000 for a good data.
#
#
			if($atemp[7] >  1000){
				@btemp = split(/-/, $atemp[0]);
				if($btemp[0] >= 2003 && $atemp[7] < 2000){
					next OUTER;
				}
#
#--- we need to adjust focal plane temperature between 9/16/2005 - 10/16/2005
#--- a reported temperature is about 1.3 warmer than a real focal temperature 
#--- (from 12/105 email from C. Grant)
#
	                        @ctemp = split(/T/, $btemp[2]);
                        	if($btemp[0] == 2005){
                                	if($btemp[1] == 9 || $btemp[1] == 10){
                                        	if($btemp[1] == 9 && $ctemp[0] >= 16){
                                                	$atemp[8] -= 1.3;
                                        	}elsif($btemp[1] == 10 && $ctemp[0] <= 16){
                                                	$atemp[8] -= 1.3;
                                        	}
                                	}
                        	}

				if($atemp[8] <= -119.7 && $atemp[7] > 7000){
					@btemp = split(/\+\-/, $atemp[1]);
					@ctemp = split(/\+\-/, $atemp[2]);
					@dtemp = split(/\+\-/, $atemp[3]);
					@etemp = split(/\+\-/, $atemp[4]);
					if($btemp[0] < 99999 && $ctemp[0] < 99999 && $dtemp[0] < 99999 
											&& $etemp[0] < 99999){
						push(@time,  $atemp[0]);
						push(@quad0, $btemp[0]);
						push(@quad1, $ctemp[0]);
						push(@quad2, $dtemp[0]);
						push(@quad3, $etemp[0]);
						$icnt++;
					}
				}
				@btemp = split(/\+\-/, $atemp[1]);
				@ctemp = split(/\+\-/, $atemp[2]);
				@dtemp = split(/\+\-/, $atemp[3]);
				@etemp = split(/\+\-/, $atemp[4]);
				if($btemp[0] < 99999 && $ctemp[0] < 99999 && $dtemp[0] < 99999 && $etemp[0] < 99999){
					push(@time2, $atemp[0]);
					push(@tstart, $atemp[0]);
		
					push(@aquad0, $btemp[0]);
					push(@error0, $btemp[1]);
		
					push(@aquad1, $ctemp[0]);
					push(@error1, $ctemp[1]);
		
					push(@aquad2, $dtemp[0]);
					push(@error2, $dtemp[1]);
		
					push(@aquad3, $etemp[0]);
					push(@error3, $etemp[1]);
			
					push(@obsid,  $atemp[5]);
					push(@tstop,  $atemp[6]);
					push(@duration, $atemp[7]);
					push(@temperature, $atemp[8]);
					$del = $atemp[8] + 119.7;
					push(@del_temp, $del);
					$acnt++;
				}
			}
		}
		close(FH);
		
		@new_time_list = @time;
		ch_time_form();
		@time = @xbin;
		
		@new_time_list = @time2;
		ch_time_form();
		@time2 = @xbin;
		
		for($qno = 0; $qno < 4; $qno++){
			@adjusted = ();
			$dname = 'quad'."$qno";
			$aname = 'aquad'."$qno";
			$qname = 'qquad'."$qno";
			@{$qname} = ();
		
#
### compute a linear fit for time vs cti so that we can remove a cti evolution effect
#
			@date = @time;
			@dep = @{$dname};
 			$total = $icnt;

			least_fit();			# linear fit sub

			for($i = 0; $i < $acnt; $i++){
				$qtemp = ${$aname}[$i] - ($int + $slope * $time2[$i]);
				push(@adjusted, $qtemp);
			}
		
#
### compute a linear fit for temp vs cti so that we can find a correciton factor
#
			@date = @del_temp;		# del_temp is temp - (-119.7)
			@dep  = @adjusted;
 			$total = $acnt;
			least_fit();
			print ZOUT  "CCD:$ccd\t Quad:$qno\t";
			printf ZOUT "\tFactor:\t%5.4e\n", $slope;
#
### set intercept to zero so that the correction is zero at -119.7
#
			$int = 0;	
			for($i = 0; $i < $acnt; $i++){
				$qtemp = ${$aname}[$i] - ($int +  $slope * ($temperature[$i] + 119.7));
				if($temperature[$i] < -119.7){
					$qtemp = ${$aname}[$i];
				}
				push(@{$qname}, $qtemp);
			}
		}

		open(OUT, ">./ztemp");
		for($i = 0; $i < $acnt; $i++){
			print  OUT "$tstart[$i]\t";
			printf OUT "%5.3f+-",$qquad0[$i];
			print  OUT "$error0[$i]\t";
			printf OUT "%5.3f+-",$qquad1[$i];
			print  OUT "$error1[$i]\t";
			printf OUT "%5.3f+-",$qquad2[$i];
			print  OUT "$error2[$i]\t";
			printf OUT "%5.3f+-",$qquad3[$i];
			print  OUT "$error3[$i]\t";
			print  OUT "$obsid[$i]\t";
			print  OUT "$tstop[$i]\t";
			print  OUT "$duration[$i]\t";
			print  OUT "$temperature[$i]\n";
		}
		close(OUT);
		system("mv ztemp $out_file");
	}

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

	$year  = 1900   + $uyear;
	$month = $umon  + 1;

	print ZOUT "\n\n Last Update: $month/$umday/$year\n";
	close(ZOUT);

}



########################################################
###  ch_time_form: changing time format           ######
########################################################

sub ch_time_form {
        @xbin = ();
        OUTER:
        foreach $time (@new_time_list) {
                unless($time =~ /\w/) {
                        next OUTER;
                }
                @atemp = split(/T/,$time);
                @btemp = split(/-/,$atemp[0]);

                $year = $btemp[0];
                $month = $btemp[1];
                $day  = $btemp[2];
                conv_date();

                @ctemp = split(/:/,$atemp[1]);
                $hr = $ctemp[0]/24.0;
                $min = $ctemp[1]/1440.0;
                $sec = $ctemp[2]/86400.0;
                $hms = $hr+$min+$sec;
                $acc_date = $acc_date + $hms;
                push(@xbin, $acc_date);
        }
}


#########################################################################
###      conv_date: modify data/time format                           ###
#########################################################################

sub conv_date {

        $acc_date = ($year - 1999)*365;
        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }elsif($year > 2020) {
                $acc_date += 6;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
		$chk = 4.0 * int(0.25 * $year);
                if($year == $chk){
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
	$acc_date = $acc_date - 202;
}


##################################
### least_fit: least fitting  ####
##################################

sub least_fit {
        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;

        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                $lsum++;
                $lsumx += $date[$fit_i];
                $lsumy += $dep[$fit_i];
                $lsumx2+= $date[$fit_i]*$date[$fit_i];
                $lsumy2+= $dep[$fit_i]*$dep[$fit_i];
                $lsumxy+= $date[$fit_i]*$dep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;


        $sum = 0;
        @diff_list = ();
        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                $diff = $dep[$fit_i] - ($int + $slope*$date[$fit_i]);
                push(@diff_list,$diff);
                $sum += $diff;
        }
        $avg = $sum/$total;

        $diff2 = 0;
        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                $diff = $diff_list[$fit_i] - avg;
                $diff2 += $diff*$diff;
        }
        $sig = sqrt($diff2/($total - 1));

        $sig3 = 3.0*$sig;

        @ldate = ();
        @ldep  = ();
        $cnt = 0;
        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                if(abs($diff_list[$fit_i]) < $sig3) {
                        push(@ldate,$date[$fit_i]);
                        push(@ldep,$dep[$fit_i]);
                        $cnt++;
                }
        }

        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;
        for($fit_i = 0; $fit_i < $cnt; $fit_i++) {
                $lsum++;
                $lsumx += $ldate[$fit_i];
                $lsumy += $ldep[$fit_i];
                $lsumx2+= $ldate[$fit_i]*$ldate[$fit_i];
                $lsumy2+= $ldep[$fit_i]*$ldep[$fit_i];
                $lsumxy+= $ldate[$fit_i]*$ldep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

}

