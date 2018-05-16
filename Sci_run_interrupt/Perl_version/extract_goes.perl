#!/usr/bin/perl 
use PGPLOT;

#################################################################################
#										#
#	extract_goes.perl: extract GOES-11 data and plot the results		#
#										#
#		author: t. isobe (tisobe@cfa.harvard.edu)			#
#										#
#		last update: Mar 05, 2012					#
#										#
#	P1    .8 -   4.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#	P2   4.0 -   9.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#	P5  40.0 -  80.0 MeV protons (Counts/cm2 sec sr MeV) Uncorrected	#
#										#
#################################################################################


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
#--- data input example: 
#
#	name       start             stop
#	20061213   2006:12:13:22:44  2006:12:16:13:42
#

$file = $ARGV[0];
open(FH, "$file");
$input = <FH>;
close(FH);
chomp $input;
@atemp = split(/\s+/, $input);

$name  = $atemp[0];
$begin = $atemp[1];		#--- sci run interruption started
$end   = $atemp[2];		#--- sci run interruption finished

#
#--- change date  to fractional year format
#
@atemp = split(/:/, $begin);
$byear = $atemp[0];
$bmon  = $atemp[1];
$bday  = $atemp[2];
$bhour = $atemp[3];
$bmin  = $atemp[4];

$rstart = date_to_fyear($byear, $bmon, $bday, $bhour, $bmin);

@atemp = split(/:/, $end);
$eyear = $atemp[0];
$emon  = $atemp[1];
$eday  = $atemp[2];
$ehour = $atemp[3];
$emin  = $atemp[4];

$rstop = date_to_fyear($eyear, $emon, $eday, $ehour, $emin);

#
#--- read radiaiton zone for the period named "$name"
#--- this need $house_keeping/rad_zone_list with the current data
#

read_rad_zone();


#
#-- set up the ploting period: start begin 2 days before the interruption
#

$pyear = $byear;
$pmon  = int($bmon);
$pday  = int($bday -2);
$phour = int($bhour);
$pmin  = int($bmin);


if($pday < 1){
	$pmon = $bmon -1;
	if($pmon < 1){
		$pmon  = 12;
		$pyear = $byear -1;
		$pday  = 31 + $pday;
	}else{
		if($pmon == 2){
			$chk   = 4.0 *int(0.25 * $pyear);
			if($chk == $pyear){
				$pday =  29 + $pday;
			}else{
				$pday =  28 + $pday;
			}
		}elsif($pmon ==1 || $pmon == 3 || $pmon == 5 || $pmon == 7
			|| $pmon == 8  || $pmon == 10){
				$pday = 31 + $pday;
		}else{
				$pday = 30 + $pday;
		}
	}
}

#
#--- the plotting period finishes 5 days after the plot starting date
#

$peyear = $pyear;
$pemon  = int($pmon);
$peday  = int($pday +5);
$pehour = int($phour);
$pemin  = int($pmin);

if($pemon == 2){
	$chk   = 4.0 *int(0.25 * $peyear);
	if($chk == $peyear){
		$base = 29;
	}else{
		$base = 28;
	}
	if($peday > $base){
		$pemon = 3;
		$peday -= $base;
	}
}elsif($pemon ==12){
	if($peday > 31){
		$peyear++;
		$pemon = 1;
		$peday -= 31;
	}
}elsif($pemon ==1 || $pemon == 3 || $pemon == 5 || $pemon == 7
	|| $pemon == 8  || $pemon == 10){
	if($peday > 31){
		$pemon++;
		$peday -= 31;
	}
}else{
	if($peday > 30){
		$pemon++;
		$peday -= 30;
	}
}

#
#--- adjust naming format, and change into fraq year format
#

if($pmon < 10){
	$pmon = '0'."$pmon";
}
if($pday < 10){
	$pday = '0'."$pday";
}
if($phour < 10){
	$phour = '0'."$phour";
}
if($pmin < 10){
	$pmin = '0'."$pmin";
}

$start = date_to_fyear($pyear, $pmon, $pday, $phour, $pmin);

if($pemon < 10){
	$pemon = '0'."$pemon";
}
if($peday < 10){
	$peday = '0'."$peday";
}
if($pehour < 10){
	$pehour = '0'."$pehour";
}
if($pemin < 10){
	$pemin = '0'."$pemin";
}

$stop = date_to_fyear($peyear, $pemon, $peday, $pehour, $pemin);

#
#--- if the interruption time is longer than the plotting period, run the second
#--- round of the plotting routine, and create another panel.
#

$run_second = 0;
if($rstop > $stop){
	$run_second = 1;

#
#-- for this plot, set up the ploting period: start begin 3 days after the interruption
#

	$p2year = $byear;
	$p2mon  = int($bmon);
	$p2day  = int($bday +3);
	$p2hour = int($bhour);
	$p2min  = int($bmin);
	
	
	if($p2day < 1){
		$p2mon = $bmon -1;
		if($p2mon < 1){
			$p2mon  = 12;
			$p2year = $byear -1;
			$p2day  = 31 + $p2day;
		}else{
			if($p2mon == 2){
				$chk   = 4.0 *int(0.25 * $p2year);
				if($chk == $p2year){
					$p2day =  29 + $p2day;
				}else{
					$p2day =  28 + $p2day;
				}
			}elsif($p2mon ==1 || $p2mon == 3 || $p2mon == 5 || $p2mon == 7
				|| $p2mon == 8  || $p2mon == 10){
					$p2day = 31 + $p2day;
			}else{
					$p2day = 30 + $p2day;
			}
		}
	}
	
#
#--- the plotting period finishes 5 days after the plot starting date
#
	
	$p2eyear = $p2year;
	$p2emon  = int($p2mon);
	$p2eday  = int($p2day +5);
	$p2ehour = int($p2hour);
	$p2emin  = int($p2min);
	
	if($p2emon == 2){
		$chk   = 4.0 *int(0.25 * $p2eyear);
		if($chk == $p2eyear){
			$base = 29;
		}else{
			$base = 28;
		}
		if($p2eday > $base){
			$p2emon = 3;
			$p2eday -= $base;
		}
	}elsif($p2emon ==12){
		if($p2eday > 31){
			$p2eyear++;
			$p2emon = 1;
			$p2eday -= 31;
		}
	}elsif($p2emon ==1 || $p2emon == 3 || $p2emon == 5 || $p2emon == 7
		|| $p2emon == 8  || $p2emon == 10){
		if($p2eday > 31){
			$p2emon++;
			$p2eday -= 31;
		}
	}else{
		if($p2eday > 30){
			$p2emon++;
			$p2eday -= 30;
		}
	}

#
#--- adjust naming format, and change into fraq year format
#

	if($p2mon < 10){
		$p2mon = '0'."$p2mon";
	}
	if($p2day < 10){
		$p2day = '0'."$p2day";
	}
	if($p2hour < 10){
		$p2hour = '0'."$p2hour";
	}
	if($p2min < 10){
		$p2min = '0'."$p2min";
	}
	
	$start2 = date_to_fyear($p2year, $p2mon, $p2day, $p2hour, $p2min);
	
	if($p2emon < 10){
		$p2emon = '0'."$p2emon";
	}
	if($p2eday < 10){
		$p2eday = '0'."$p2eday";
	}
	if($p2ehour < 10){
		$p2ehour = '0'."$p2ehour";
	}
	if($p2emin < 10){
		$p2emin = '0'."$p2emin";
	}
	
	$stop2 = date_to_fyear($p2eyear, $p2emon, $p2eday, $p2ehour, $p2emin);
}



#
#--- create a html address which includes the data
#

@html_list = ();

if($pyear == $peyear){
	if($pmon == $pemon){
		$tmon = int($pmon);
		if($tmon < 10){
			$tmon = '0'."$tmon";
		}
		for($tday = $pday; $tday <= $peday; $tday++){
			if($tday < 10){
				$tday = int($tday);
				$tday = '0'."$tday";
			}
			$time_stamp = "$pyear"."$tmon"."$tday";
			$html = 'http://www.swpc.noaa.gov/ftpdir/lists/pchan/'."$time_stamp".'_Gp_pchan_5m.txt';
			push(@html_list, $html);
		}
	}elsif($pmon < $pemon){
		if($pmon == 2){
			$chk = 4 * int(0.25  * $pyear);
			if($chk == $pyear){
				$end_date = 29;
			}else{
				$end_date = 28;
			}
		}elsif($pmon == 1 || $pmon == 3 || $pmon == 5 || $pmon == 7 || $pmon == 8 ||$pmon == 10 ){
			$end_date = 31;
		}else{
			$end_date = 30;
		}

		$tmon = int($pmon);
		if($tmon < 10){
			$tmon = '0'. "$tmon";
		}
		for($tday = $pday; $tday <= $end_date; $tday++){
			$time_stamp = "$pyear"."$tmon"."$tday";
			$html = 'http://www.swpc.noaa.gov/ftpdir/lists/pchan/'."$time_stamp".'_Gp_pchan_5m.txt';
			push(@html_list, $html);
		}
		$tmon = int($pemon);
		if($tmon < 10){
			$tmon = '0'. "$tmon";
		}
		for($tday = 1; $tday <= $peday; $tday++){
			$tday = int($tday);
			$tday = '0'."$tday";
			$time_stamp = "$pyear"."$tmon"."$tday";
			$html = 'http://www.swpc.noaa.gov/ftpdir/lists/pchan/'."$time_stamp".'_Gp_pchan_5m.txt';
			push(@html_list, $html);
		}
	}
}else{
	for($tday = $pday; $tday <= 31; $tday++){
		$time_stamp = "$pyear"."12"."$tday";
		$html = 'http://www.swpc.noaa.gov/ftpdir/lists/pchan/'."$time_stamp".'_Gp_pchan_5m.txt';
		push(@html_list, $html);
	}
	for($tday = 1; $tday <= $peday; $tday++){
		$tday = int($tday);
		$tday = '0'."$tday";
		$time_stamp = "$pyear"."01"."$tday";
		$html = 'http://www.swpc.noaa.gov/ftpdir/lists/pchan/'."$time_stamp".'_Gp_pchan_5m.txt';
		push(@html_list, $html);
	}
}


@day  = ();
@time = ();
@p1   = ();
@p2   = ();
@p5   = ();
$tot  = 0;
$chk  = 0;

$cstop = $stop;
if($run_second > 0){
	$cstop = $stop2;
}


foreach $html (@html_list){
	system("/opt/local/bin/lynx -source $html >./Working_dir/temp_data");
	open(FH, "./Working_dir/temp_data");
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(//, $_);
		if($atemp[0] =~ /\#/ || $atemp[0] =~ /\:/){
			next OUTER;
		}
		@atemp = split(/\s+/, $_);
		$year  = $atemp[0];
		$mon   = $atemp[1];
		$day   = $atemp[2];
		@btemp = split(//, $atemp[3]);
		$hour  = "$btemp[0]$btemp[1]";
		$min   = "$btemp[2]$btemp[2]";
		
		$time = date_to_fyear($year, $mon, $day, $hour, $min);
		if($time >= $start && $time <= $cstop){
			push(@date, $time);
			push(@p1,   $atemp[6]);
			push(@p2,   $atemp[7]);
			push(@p5,   $atemp[10]);
			$tot++;
		}
	}
	close(FH);
}

system("rm ./Working_dir/temp_data");


#
#-- convert all date into ydate
#

@xdate = ();
for($m = 0; $m < $tot; $m++){
	@atemp = split(/\./, $date[$m]);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$xp = ($date[$m] - $atemp[0]) * $base;
	push(@xdate, $xp);
}

#
#--- printing out the data
#

$out = "/data/mta_www/mta_interrupt/Data_dir/$name".'_goes.txt';

open(OUT, ">$out");
print OUT "Scient Run Interruption: $begin\n\n";
print OUT "dofy\t\tp1\t\tp2\t\tp5\n";
print OUT "-------------------------------------------------------------------\n";

for($m = 0; $m < $tot; $m++){
	$sdate = sprintf "%4.3f", $xdate[$m];
	print OUT "$sdate\t\t$p1[$m]\t$p2[$m]\t$p5[$m]\n";
}

#
#--- setting for stat info gathering
#

$p1min  = 1e14;
$p1tmin = 0;
$p1max  = 1e-14;
$p1tmax = 0;
$p1int  = -999;
$sum1   = 0;
$sum1_2 = 0;
$stot1  = 0;

$p2min  = 1e14;
$p2tmin = 0;
$p2max  = 1e-14;
$p2tmax = 0;
$p2int  = -999;
$sum2   = 0;
$sum2_2 = 0;
$stot2  = 0;

$p5min  = 1e14;
$p5tmin = 0;
$p5max  = 1e-14;
$p5tmax = 0;
$p5int  = -999;
$sum5   = 0;
$sum5_2 = 0;
$stot5  = 0;

#
#--- plot starts here
#

#
#--- set overall y axis range
#

$ymin = -3;
@temp = sort{$a<=>$b} @p1;
$ymax = $temp[$cnt-1];
if($ymax > 0){
	$ymax = int(log($ymax)/2.302585093) + 1;
}else{
	$ymax = 1;
}

@temp = sort{$a<=>$b} @p2;
$ymax2= $temp[$cnt-1];
if($ymax2 > 0){
	$ymax2= int(log($ymax)/2.302585093) + 1;
}else{
	$ymax2 = 1;
}

if($ymax2 > $ymax){
	$ymax = $ymax2;
}

@temp = sort{$a<=>$b} @p5;
$ymax5= $temp[$cnt-1];
if($ymax5 > 0){
	$ymax5= int(log($ymax)/2.302585093) + 1;
}else{
	$ymax5 =1;
}

if($ymax5 > $ymax){
	$ymax = $ymax5;
}
$ymax++;

#
#--- date for the plotting is ydate. 
#

@atemp = split(/\./, $start);
$chk   = 4.0 * int(0.25 * $atemp[0]);
if($chk == $atemp[0]){
	$base = 366;
}else{
	$base = 365;
}

$xmin = ($start - $atemp[0])  * $base;

@btemp = split(/\./, $stop);
$chk   = 4.0 * int(0.25 * $btemp[0]);
if($chk == $btemp[0]){
	$base2 = 366;
}else{
	$base2 = 365;
}

#
#--- if year changes, pretend the date continues from the prev. year
#

$xmax = ($stop - $btemp[0]) * $base2;
if($btemp[0] > $atemp[0]){
	$xmax += $base;
}

$xmin = sprintf "%4.2f", $xmin;
$xmax = sprintf "%4.2f", $xmax;


$run_second_ind = 0;
plot_data ();

#
#--- if the interruption is longer than 5 days plotting period, 
#--- create the second plot
#

if($run_second > 0){
	$start = $start2;
	$stop  = $stop2;

#
#--- date for the plotting is ydate. 
#

	@atemp = split(/\./, $start);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	
	$xmin = ($start - $atemp[0])  * $base;
	
	@btemp = split(/\./, $stop);
	$chk   = 4.0 * int(0.25 * $btemp[0]);
	if($chk == $btemp[0]){
		$base2 = 366;
	}else{
		$base2 = 365;
	}

#
#--- if year changes, pretend the date continues from the prev. year
#

	$xmax = ($stop - $btemp[0]) * $base2;
	if($btemp[0] > $atemp[0]){
		$xmax += $base;
	}
	
	$xmin = sprintf "%4.2f", $xmin;
	$xmax = sprintf "%4.2f", $xmax;

	$run_second_ind = 1;

	plot_data();
}
	
#
#--- compute average and sigma of the radiation doses
#

if($stot1 > 0){
	$p1avg = $sum1/$stot1;
	$p1sig = sqrt($sum1_2/$stot1 - $p1avg * $p1avg);
}else{
	$p1avg = 'n/a';
	$p1sig = 'n/a';
}

if($stot2 > 0){
	$p2avg = $sum2/$stot2;
	$p2sig = sqrt($sum2_2/$stot2 - $p2avg * $p2avg);
}else{
	$p2avg = 'n/a';
	$p2sig = 'n/a';
}

if($stot5 > 0){
	$p5avg = $sum5/$stot5;
	$p5sig = sqrt($sum5_2/$stot5 - $p5avg * $p5avg);
}else{
	$p5avg = 'n/a';
	$p5sig = 'n/a';
}

#
#--- print out stat info
#

$p1min  = sprintf "%2.3e", $p1min;
$p1tmin = sprintf "%4.3f", $p1tmin;
$p1max  = sprintf "%2.3e", $p1max;
$p1tmax = sprintf "%4.3f", $p1tmax;
$p1avg  = sprintf "%2.3e", $p1avg;
$p1sig  = sprintf "%2.3e", $p1sig;
$p1int  = sprintf "%2.3e", $p1int;

$p2min  = sprintf "%2.3e", $p2min;
$p2tmin = sprintf "%4.3f", $p2tmin;
$p2max  = sprintf "%2.3e", $p2max;
$p2tmax = sprintf "%4.3f", $p2tmax;
$p2avg  = sprintf "%2.3e", $p2avg;
$p2sig  = sprintf "%2.3e", $p2sig;
$p2int  = sprintf "%2.3e", $p2int;

$p5min  = sprintf "%2.3e", $p5min;
$p5tmin = sprintf "%4.3f", $p5tmin;
$p5max  = sprintf "%2.3e", $p5max;
$p5tmax = sprintf "%4.3f", $p5tmax;
$p5avg  = sprintf "%2.3e", $p5avg;
$p5sig  = sprintf "%2.3e", $p5sig;
$p5int  = sprintf "%2.3e", $p5int;


$out = "$web_dir/GOES_plot/"."$name".'_text';

open(OUT, ">$out");
print OUT "\t\tAvg\t\t\t Max\t\tTime\t\tMin\t\tTime\tValue at Interruption Started\n";
print OUT "--------------------------------------------------------------------------------------------------------------------------\n";
print OUT "p1\t\t$p1avg+/-$p1sig\t";
print OUT "$p1max\t$p1tmax\t\t";
print OUT "$p1min\t$p1tmin\t\t";
print OUT "$p1int\n";

print OUT "p2\t\t$p2avg+/-$p2sig\t";
print OUT "$p2max\t$p2tmax\t\t";
print OUT "$p2min\t$p2tmin\t\t";
print OUT "$p2int\n";

print OUT "p5\t\t$p5avg+/-$p5sig\t";
print OUT "$p5max\t$p5tmax\t\t";
print OUT "$p5min\t$p5tmin\t\t";
print OUT "$p5int\n";
close(OUT);




#########################################################################################
#########################################################################################
#########################################################################################

sub plot_data{

#
#--- ploting starts here
#

	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,3);
	pgsch(2);
	pgslw(4);

#
#----- p1
#

	$ylab = 'Log(p1 Rate)';
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);

#
#-- plot the interruption starting point
#

	@atemp = split(/\./, $rstart);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$rbeg = ($rstart - $atemp[0]) * $base;
	if($run_second_ind == 0){
		pgmove($rbeg, $ymin);
		pgdraw($rbeg, $ymax);
	
		$ym = $ymax - 0.1 * ($ymax - $ymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}

#
#--- plot the end of the interruption
#

	@atemp = split(/\./, $rstop);
	$chk   = 4.0 * int(0.25 * $atemp[0]);
	if($chk == $atemp[0]){
		$base = 366;
	}else{
		$base = 365;
	}
	$rend = ($rstop - $atemp[0]) * $base;

	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $ymin);
		pgdraw($rend, $ymax);
	}

#	pgmove($xmin, 2.477);
#	pgdraw($xmax, 2.477);
	pgsci(1);

#
#--- plot data points
#
	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
		
		if($p1[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($p1[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($p1min > $p1[$m]){
			$p1min  = $p1[$m];
			$p1tmin = $xdate[$m];
		}
		if($p1max < $p1[$m]){
			$p1max  = $p1[$m];
			$p1tmax = $xdate[$m];
		}
		if($p1int == -999 && $xdate[$m] >= $rbeg){
			$p1int = $p1[$m];
		}
		$sum1   += $p1[$m];
		$sum1_2 += $p1[$m] * $p1[$m];
		$stot1++;

	}
	pgsch(2);


#
#--- plot radation balt location
#

	plot_box();

#
#----- p2
#

	$ylab = 'Log(p2 Rate)';
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);
	if($run_second_ind == 0){
		pgmove($rbeg, $ymin);
		pgdraw($rbeg, $ymax);
	
		$ym = $ymax - 0.1 * ($ymax - $ymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}
	
	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $ymin);
		pgdraw($rend, $ymax);
	}
	
#	pgmove($xmin, 2.477);
#	pgdraw($xmax, 2.477);
	pgsci(1);

	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
	
		if($p2[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($p2[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($p2min > $p2[$m]){
			$p2min  = $p2[$m];
			$p2tmin = $xdate[$m];
		}
		if($p2max < $p2[$m]){
			$p2max  = $p2[$m];
			$p2tmax = $xdate[$m];
		}
		if($p2int == -999 && $xdate[$m] >= $rbeg){
			$p2int = $p2[$m];
		}
		$sum2   += $p2[$m];
		$sum2_2 += $p2[$m] * $p2[$m];
		$stot2++;
	}
	pgsch(2);
	
	plot_box();

#
#----- p5
#

	$ylab = 'Log(p5 Rate)';
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
	pglab('Day of Year', $ylab, $title);
	
	pgsci(2);
	if($run_second_ind == 0){
		pgmove($rbeg, $ymin);
		pgdraw($rbeg, $ymax);

		$ym = $ymax - 0.1 * ($ymax - $ymin);
		pgptxt($rbeg, $ym, 0, left, interruption);
	}

	if($run_second == 0 || $run_second_ind > 0){
		pgmove($rend, $ymin);
		pgdraw($rend, $ymax);
	}
#	pgmove($xmin, 2.477);
#	pgdraw($xmax, 2.477);
	pgsci(1);
	
	pgsch(4);
	OUTER:
	for($m = 0; $m < $tot -1; $m++){
	
		if($p5[$m] <= 0){
			next OUTER;
		}
		if($xdate[$m] < $xmin){
			next OUTER;
		}
		if($xdate[$m] > $xmax){
			last OUTER;
		}

		$ydata = log($p5[$m])/2.302585093;
        	pgpt(1, $xdate[$m], $ydata, 1);
	
		if($xdate[$m] < $rbeg || $xdata[$m] > $rend){
			next OUTER;
		}
	
		if($p5min > $p5[$m]){
			$p5min  = $p5[$m];
			$p5tmin = $xdate[$m];
		}
		if($p5max < $p5[$m]){
			$p5max  = $p5[$m];
			$p5tmax = $xdate[$m];
		}
		if($p5int == -999 && $xdate[$m] >= $rbeg){
			$p5int = $p5[$m];
		}
		$sum5   += $p5[$m];
		$sum5_2 += $p5[$m] * $p5[$m];
		$stot5++;
	}
	pgsch(2);
	
	plot_box();
	
	pgclos();

	if($run_second_ind == 0){
		$out_gif = "$web_dir/GOES_plot/"."$name".'_goes.gif';
		$out_ps  = "$web_dir/Ps_dir/"."$name".'_goes.ps';
	}else{
		$out_gif = "$web_dir/GOES_plot/"."$name".'_goes_pt2.gif';
		$out_ps  = "$web_dir/Ps_dir/"."$name".'_goes_pt2.ps';
	}
	
#	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmcrop| pnmflip -r270 | ppmtogif > $out_gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|  pnmflip -r270 | ppmtogif > $out_gif");

	system("mv pgplot.ps $out_ps");
	
}


###################################################################
###################################################################
###################################################################

sub date_to_fyear{
	my($year, $mon, $day, $hour, $min);
	($year, $mon, $day, $hour, $min) = @_;

	if($year < 1000){
		if($year > 70){
			$year = '19'."$year";
		}else{
			$year = '20'."$year";
		}
	}

	$chk = 4.0 * int(0.25 * $year);
	if($chk == $year){
		$base = 366;
	}else{
		$base = 365;
	}

	$fday = int($day) +  $hour/24 + $min/1440;
	$add = 0;
	if($mon == 2){
		$add = 31;
	}elsif($mon == 3){
		$add = 59;
	}elsif($mon == 4){
		$add = 90;
	}elsif($mon == 5){
		$add = 120;
	}elsif($mon == 6){
		$add = 151;
	}elsif($mon == 7){
		$add = 181;
	}elsif($mon == 8){
		$add = 212;
	}elsif($mon == 9){
		$add = 243;
	}elsif($mon == 10){
		$add = 273;
	}elsif($mon == 11){
		$add = 304;
	}elsif($mon == 12){
		$add = 334;
	}
	if($base == 366 && $mon > 2){
		$add++;
	}
	$year += ($fday + $add)/$base;
	
	return($year);
}


###############################################################
### read_rad_zone: read radiation zone information          ###
###############################################################

sub read_rad_zone{
	my(@atemp);

        if($byear == 1999){
               	$subt = - 202;
        }else{
               	$subt = 365 *($byear - 2000) + 163;
               	if($byear > 2000){
                       	$subt++;
               	}
                if($byear > 2004){
                        $subt++;
                }
                if($byear > 2008){
                        $subt++;
                }
                if($byear > 2012){
                        $subt++;
                }
                if($byear > 2016){
                        $subt++;
                }
                if($byear > 2020){
                        $subt++;
                }
                if($byear > 2024){
                        $subt++;
                }
                if($byear > 2028){
                        $subt++;
                }
        }
	
	if($byear < 2003){
        	open(FH, "$house_keeping/rad_zone_list");
        	OUTER:
        	while(<FH>){
                	chomp $_;
                	@atemp = split(/\s+/, $_);
                	if($atemp[0] eq $name){
                        	$line = $_;
                        	last OUTER;
                	}
        	}
	
        	@atemp = split(/\s+/, $line);
        	@rad_entry = split(/:/, $atemp[1]);
        	$ent_cnt = 0;
        	foreach (@rad_entry){
                	$ent_cnt++;
        	}
	}else{
		extract_rad_zone_info();
		$ent_cnt = $pcnt;
	}
}

###############################################################
### plot_box: create radiation zone box on the plot         ###
###############################################################

sub plot_box{
	my($j, $ydiff);
        pgsci(12);
	OUTER:
        for($j = 0; $j < $ent_cnt; $j++){
                @dtmp = split(/\(/, $rad_entry[$j]);
                @etmp = split(/\)/, $dtmp[1]);
                @ftmp = split(/\,/, $etmp[0]);
                $r_start = $ftmp[0] - $subt;
                $r_end   = $ftmp[1] - $subt;
		if($r_end < $r_start){
			next OUTER;
		}
                if($r_start < $xmin){
                        $r_start = $xmin;
                }
                if($r_end > $xmax){
                        $r_end = $xmax;
                }
                pgshs (0.0, 1.0, 0.0);
                $ydiff = $ymax - $ymin;
                $yt = 0.05*$ydiff;
                $ytop = $ymin + $yt;
                pgsfs(4);
                pgrect($r_start,$r_end,$ymin,$ytop);
                pgsfs(1);
        }
        pgsci(1);
}

###################################################################################
### read_rad_zone: read rad zone and create the list for the specified period   ###
###################################################################################

sub extract_rad_zone_info{
	my ($start, $stop, @pstart, @pstop, @dom);
	open(FH,"$house_keeping/rad_zone_info");

	@ind    = ();
	@rtime  = ();
	@rtime2 = ();
	$rtot   = 0;
	
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@ind,    $atemp[0]);
		push(@rtime,  $atemp[1]);
		push(@rtime2, $atemp[2]);
		$rtot++;
	}
	close(FH);
	
	@atemp = split(/:/, $begin);
	$dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
	$start = $dom - 8;
	
	@atemp = split(/:/, $end);
	$dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
	$stop  = $dom + 8;
	
	@pstart = ();
	@pstop  = ();
	$pcnt   = 0;
	OUTER:
	for($i = 0; $i < $rtot; $i++){
		if($rtime[$i] < $start){
			next OUTER;
		}elsif($rtime[$i] >= $start && $rtime[$i] < $stop){
			if($ind[$i] =~ /ENTRY/i){
				push(@pstart, $rtime[$i]);	
			}elsif($ind[$i] =~ /EXIT/i){
				if(($pstart[$pcnt] != 0) && ($pstart[$pcnt] < $rtime[$i])){
					push(@pstop, $rtime[$i]);
					$pcnt++;
				}
			}
		}elsif($rtime[$i] > $stop){
			last OUTER;
		}
	}
	
	
	@rad_entry = ();
	for($i = 0; $i < $pcnt; $i++){
		$line = "($pstart[$i],$pstop[$i])";
		push(@rad_entry, $line);
	}
}	



###########################################################################
###      conv_date_dom: modify data/time format                       #####
###########################################################################

sub conv_date_dom {

#############################################################
#       Input:  $year: year in a format of 2004
#               $month: month in a formt of  5 or 05
#               $day:   day in a formant fo 5 05
#
#       Output: acc_date: day of mission returned
#############################################################

        my($year, $month, $day, $chk, $acc_date);

        ($year, $month, $day) = @_;

        $acc_date = ($year - 1999) * 365;

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
        }elsif($year > 2024) {
                $acc_date += 7;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                $chk = 4.0 * int(0.25 * $year);
                if($year == $chk) {
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
        $acc_date -= 202;
        return $acc_date;
}
