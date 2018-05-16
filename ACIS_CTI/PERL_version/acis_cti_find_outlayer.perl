#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	find_outlayer.perl: find outlayer data points from data sets and remove them	#
#											#
#	author: T. Isobe (tisobe@cfa.harvard.edu)					#
#	Last update: Apr 15, 2013							#
#		modified to fit a new directory system					#
#											#	
#########################################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[1];
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

#
### set boundray: how many sigma out from the center to drop a data point
#
$factor1 = 5.0;			###### ccd 5 and 7
$factor2 = 4.0;			###### all other ccds

$dir = $ARGV[0];
chomp $dir;

$dir = "$data_dir/"."$dir";

$det_dir = 0;			##### check whether this detrend dataset or not
@ccd_list = (0,1,2,3,4,5,6,7,8,9);
if($dir =~ /Det/){
	$det_dir = 1;
	@ccd_list = (0,1,2,3,4,6,8,9);
}
$out1 = "$dir"."/dropped_data";		###### record which points were dropped
open(OUT1, ">$out1");

@bad_data_obsid = ();

foreach $elm (al, mn, ti){
	print OUT1 "ELM: $elm\n";
	foreach $iccd (@ccd_list){
		print OUT1 "CCD: $iccd\n";
		$file = "$dir".'/'."$elm".'_ccd'."$iccd";
		@above_sig_data = ();

		open(FH, "$file");
		@time  = ();
		@quad0 = ();
		@quad1 = ();
		@quad2 = ();
		@quad3 = ();
		@data  = ();
		$cnt   = 0;
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			unless($_ =~ /99999/){
				push(@data, $_);
				push(@time , $atemp[0]);
				push(@quad0, $atemp[1]);
				push(@quad1, $atemp[2]);
				push(@quad2, $atemp[3]);
				push(@quad3, $atemp[4]);
				$cnt++;
			}
		}
		close(FH);
		
		@new_time_list = @time;
		ch_time_form();		####### change time format to DOM
		@date = @xbin;
		$total = $cnt;
		
#
### quad 0
#
		@dep = @quad0;
		least_fit();		####### fitting a straight line
		print OUT1 "QUAD0\n";
		$sum  = 0;
		$sum2 = 0;
		@diff_save = ();
#
#### here compute deviations from a fitting line, and compute a mean and a sigma
#### of that devations. this mean and sigma will be used to find outlyer
#
		for($i = 0; $i< $total; $i++){
			$val = $int + $slope * $date[$i];
			$diff = abs($quad0[$i] - $val);
			push(@diff_save, $diff);
			$sum += $diff;
			$sum2 += $diff*$diff;
		}
		$avg = $sum/$total;
		$sigma = sqrt($sum2/$total - $avg*$avg);
		if($iccd == 5 || $iccd == 7){
			$sig3 = $factor1 * $sigma;
		}else{
			$sig3 = $factor2 * $sigma;
		}
#
#### here any data points with deviation larger than factor<1/2> * sigma will be
#### assigned as outlayers
#
		
		for($i = 0; $i< $total; $i++){
			if($diff_save[$i] > $sig3){
				@atemp = split(/\s+/, $data[$i]);
				print OUT1 "$atemp[5]\t$atemp[0]\t$atemp[6]\t$atemp[7]\t$atemp[7]\n";
				push(@bad_data_obsid, $atemp[5]);
				push(@above_sig_data, $data[$i]);
			}
		}
#
### quad 1
#
		
		@dep = @quad1;
		least_fit();
		print  OUT1 "QUAD1\n";
		$sum  = 0;
		$sum2 = 0;
		@diff_save = ();
		for($i = 0; $i< $total; $i++){
        		$val = $int + $slope * $date[$i];
        		$diff = abs($quad1[$i] - $val);
        		push(@diff_save, $diff);
        		$sum += $diff;
        		$sum2 += $diff*$diff;
		}
		$avg = $sum/$total;
		$sigma = sqrt($sum2/$total - $avg*$avg);
		if($iccd == 5 || $iccd == 7){
			$sig3 =  $factor1 * $sigma;
		}else{
			$sig3 =  $factor2 * $sigma;
		}
		
		for($i = 0; $i< $total; $i++){
        		if($diff_save[$i] > $sig3){
				@atemp = split(/\s+/, $data[$i]);
				print OUT1 "$atemp[5]\t$atemp[0]\t$atemp[6]\t$atemp[7]\t$atemp[7]\n";
				push(@bad_data_obsid, $atemp[5]);
				push(@above_sig_data, $data[$i]);
			}
		}
#
### quad 2
#
		
		@dep = @quad2;
		least_fit();
		print OUT1  "QUAD2\n";
		$sum  = 0;
		$sum2 = 0;
		@diff_save = ();
		for($i = 0; $i< $total; $i++){
        		$val = $int + $slope * $date[$i];
        		$diff = abs($quad2[$i] - $val);
        		push(@diff_save, $diff);
        		$sum += $diff;
        		$sum2 += $diff*$diff;
		}
		$avg = $sum/$total;
		$sigma = sqrt($sum2/$total - $avg*$avg);
		if($iccd == 5 || $iccd == 7){
			$sig3 = $factor1 * $sigma;
		}else{
			$sig3 = $factor2 * $sigma;
		}
		
		for($i = 0; $i< $total; $i++){
        		if($diff_save[$i] > $sig3){
				@atemp = split(/\s+/, $data[$i]);
				print OUT1 "$atemp[5]\t$atemp[0]\t$atemp[6]\t$atemp[7]\t$atemp[7]\n";
				push(@bad_data_obsid, $atemp[5]);
				push(@abov_sig_data, $data[$i]);
			}
		}

#
### quad 3
#
		
		@dep = @quad3;
		least_fit();
		print OUT1  "QUAD3\n";
		$sum  = 0;
		$sum2 = 0;
		@diff_save = ();
		for($i = 0; $i< $total; $i++){
        		$val = $int + $slope * $date[$i];
        		$diff = abs($quad3[$i] - $val);
        		push(@diff_save, $diff);
        		$sum += $diff;
        		$sum2 += $diff*$diff;
		}
		$avg = $sum/$total;
		$sigma = sqrt($sum2/$total - $avg*$avg);
		if($iccd == 5 || $iccd == 7){
			$sig3 = $factor1 * $sigma;
		}else{
			$sig3 = $factor2 * $sigma;
		}
		
		for($i = 0; $i< $total; $i++){
        		if($diff_save[$i] > $sig3){
				@atemp = split(/\s+/, $data[$i]);
				print OUT1 "$atemp[5]\t$atemp[0]\t$atemp[6]\t$atemp[7]\t$atemp[7]\n";
				push(@bad_data_obsid, $atemp[5]);
				push(@above_sig_data, $data[$i]);
			}
		}

#
#### check all outlayer data points and remove duplicates
#
		@temp = sort{$a<=>$b} @above_sig_data;
		$first = shift(@temp);
		@new = ($first);
		OUTER:
		foreach $ent (@temp){
			foreach $comp (@new){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
		}
		@above_sig_data = @new;
#
#### weed out all data points outside of the specified boundray (@above_sig_data)
#
		@better_data = ();
		OUTER:
		foreach $ent (@data){
			foreach $comp (@above_sig_data){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@better_data, $ent);
		}
#
#### replace the old dataset to a new one.
#
		open(OUT, ">$file");
		foreach $ent (@better_data){
			print OUT "$ent\n";
		}
		close(OUT);
	}		
	close(OUT1);
		
}

#
### check all bad data obsid and remove duplicates
#
@temp = sort{$a<=>$b}@bad_data_obsid;
$comp = shift(@temp);
@new = ($comp);
foreach $ent (@temp){
	if($ent > $comp){
		$comp = $ent;
		push(@new, $ent);
	}
}
@bad_data_obsid = @new;
open(OUT, ">$dir/bad_data_obsid");
foreach $ent (@bad_data_obsid){
	print OUT "$ent\n";
}
close(OUT);


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

###########################################################################
###      conv_date: modify data/time format                           #####
###########################################################################

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
        }elsif($year > 2012) {
                $acc_date += 6;
        }

        $acc_date += $day - 1;
	$chk = 4.0 * int (0.25 * $year);
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
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

        $tot1 = $total - 1;
        $variance = ($lsumy2 + $int*$int*$lsum + $slope*$slope*$lsumx2
                        -2.0 *($int*$lsumy + $slope*$lsumxy - $int*$slope*$lsumx))/$tot1;
        $sigm_slope = sqrt($variance*$lsum/$delta);
}

	
