#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	gyro_drift_detail.perl: plot gyro drift rate around grating moves		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jul 28, 2014							#
#											#
#########################################################################################
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

#########################################################
#
#---- set directories
#
if($comp_test =~ /test/i){
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list_test");
}else{
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list");
}
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- and other settings
#

$dare   = `cat $data_dir/.dare`;
chomp $dare;
$hakama = `cat $data_dir/.hakama`;
chomp $hakama;

#########################################################

if($comp_test =~ /test/i){
	$last_time = 2012363;
	$stop_time = 2013060;
}else{
#
#--- find today's date
#

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst) = localtime(time);
	$uyear += 1900;
	$month = $umon + 1;

#
#--- check the most recent data we computed
#

	$in_list = `ls -lrt $data_save/*gz`;
	@data_list = split(/\s+/, $in_list);
	@past_time = ();
	$tcnt = 0;
	foreach $ent (@data_list){
		@atemp = split(/_data/, $ent);
		@btemp = split(/_/, $atemp[0]);
		$atime = pop(@btemp);
		push(@past_time, $atime);
		$tcnt++;
	}
	close(FH);
	
	@t_list = sort{$b<=>$a} @past_time;

#
#----  the last data time
#

	$last_time = $t_list[0];
}

#
#--- read grating moves 
#

open(FH, "/data/mta_www/mta_otg/OTG_filtered.rdb");

@ind    = ();			# INSR or RETR
@grat   = ();			# HETG or LETG
@start  = ();			# starting time of the move
@syear  = ();
@syday  = ();
@stime  = ();
@stop   = ();			# stop time of the move
@eyear  = ();
@eyday  = ();
@etime  = ();
@tstart = ();
@tstop  = ();
@intvl  = ();			# duration
$ocnt   = 0;

$symbol = 2;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] =~ /INSR/i  || $atemp[0] =~ /RETR/i){
#
#--- don't repeat the data we already computed in the past
#
		if($atemp[2] <= $last_time){
			next OUTER;
		}
		if($comp_test =~ /test/ && $atemp[2] > $stop_time){	#-- if this is a test, limit data 
			last OUTER;
		}

		push(@ind,  $atemp[0]);
		push(@grat, $atemp[1]);
		push(@start, $atemp[2]);
		push(@stop,  $atemp[4]);
		$t1998s = chg_tform($atemp[2]);
		push(@tstart, $t1998s);
		push(@syear, $year);
		push(@syday, $yday);
		push(@stime, $sec);
		$t1998e = chg_tform($atemp[4]);
		push(@tstop, $t1998e);
		push(@eyear, $year);
		push(@eyday, $yday);
		push(@etime, $sec);
		$int    = $t1998e - $t1998s;
		push(@intvl, $int);
		$ocnt++;
	}
}
close(FH);

OUTER:
for($i = 0; $i < $ocnt; $i++){

#
#--- find a time of the center of the plotting
#
	$mid_time  = 0.5 * ($tstart[$i] + $tstop[$i]);
	$mdiff     = $tstop[$i] - $tstart[$i];
	$sbegin    = $mid_time - 120;
	$send      = $mid_time + 120;
#
#--- setting a plotting range, if it is longer than 120 sec, set a longer range
#
	$range     = 120;
	if($mdiff > 120){
		$imdiff = int ($mdiff);
		$sbegin = $mid_time - $imdiff;
		$send   = $mid_time + $imdiff;
		$range  = $imdiff;
	}
#
#--- we use two different ranges of data (latter for polynomial fittting)
#
	$sz1  = $tstart[$i]-  $mid_time;
	$sz2  = $tstop[$i] -  $mid_time;
	$lsz1 = $tstart[$i]-  $mid_time - 0.2 * $range;
	$lsz2 = $tstop[$i] -  $mid_time + 0.2 * $range;
#
#---- set tstart and tstop of arc4gl to extract data
#
	@pstime = ();
	@pstsc  = ();
	$pscnt  = 0;
	$tyear  = $syear[$i];
	$tday   = $syday[$i];

	ch_ydate_to_mon_date();

	$hr     = int($stime[$i]/3600);
	$min    = int (($stime[$i] - 3600 * $hr)/ 60);
	$syear1 = $syear[$i];
	$hr--;
	if($hr < 0){
		$hr += 24;
		$mday--;
		if($mday < 0){
			$mday = 365;
			$syear1--;
			$chk = 4 * int(0.25 * $syear1);
			if($syear1 == $chk){
				$tday++;
			}
		}
	}
	$tstart2 = "$mon/$mday/$syear1,$hr:$min:00";

	$tyear = $eyear[$i];
	$tday  = $eyday[$i];

	ch_ydate_to_mon_date();

	$hr     = int($stime[$i]/3600);
	$min    = int (($stime[$i] - 3600 * $hr)/ 60);
	$syear2 = $syear[$i];
	$hr++;
	if($hr > 23){
		$hr -= 24;
		$mday++;
		if($mday > 365){
			$chk = 4 * int(0.25 * $syear2);
			if($syear1 != $chk){
				$mday = 1;
				$syear2++;
			}
		}
	}
	$tstop2 = "$mon/$mday/$syear2,$hr:$min:00";
#
#---- arc4gl input file; we are getting pcad3eng data
#
        open(OUT, ">./input_line");
        print OUT "operation=retrieve\n";
        print OUT "dataset=flight\n";
        print OUT "detector=pcad\n";
        print OUT "subdetector=eng\n";
        print OUT "level=0\n";
        print OUT "filetype=pcad3eng\n";
        print OUT "tstart=$tstart2\n";
        print OUT "tstop=$tstop2\n";
        print OUT "go\n";
        close(OUT);

        system("echo $hakama |arc4gl -U$dare -Sarcocc -iinput_line");
	    system("rm -rf input_line");
        system("gzip -d *gz");

        system("ls * > zlist");
        open(FH, "./zlist");
        @data_list = ();
        while(<FH>){
                chomp $_;
                if($_ =~ /pcadf/ && $_ =~ /eng0.fits/){
                    push(@data_list, $_);
                }
        }
        close(FH);

        system("rm zlist");

	@cstime   = ();
	@aogbias1 = ();			# gyro drift rate roll
	@aogbias2 = ();			# gyro drift rate pitch
	@aogbias3 = ();			# gyro drift rate yaw
	$ccnt     = 0;
#
#---- this data set for polynomial fitting
#
	@lcstime   = ();
	@laogbias1 = ();
	@laogbias2 = ();
	@laogbias3 = ();
	$lccnt     = 0;
	
	foreach $file (@data_list){
		$line = "$file".'[cols time,AOGBIAS1,AOGBIAS2,AOGBIAS3]';
		system("dmlist  \"$line\" opt=data > data_out");

		open(FH, "data_out");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] !~ /\d/){
				next;
			}
			$t_diff = ($atemp[2] - $mid_time);
			if($t_diff > -$range && $t_diff < $range){
				push(@cstime, $t_diff);

				$ain1 = 10e5 * $atemp[3];
				push(@aogbias1, $ain1);

				$ain2 = 10e5 * $atemp[4];
				push(@aogbias2, $ain2);

				$ain3 = 10e5 * $atemp[5];
				push(@aogbias3, $ain3);
				$ccnt++;

				if($t_diff > $lsz1 && $t_diff < $lsz2){
					push(@lcstime,   $t_diff);
					push(@laogbias1, $ain1);
					push(@laogbias2, $ain2);
					push(@laogbias3, $ain3);
					$lccnt++;
				}
			}
		}
		close(FH);
	}

	if($ccnt <= 0 || $lccnt <= 0){
		next OUTER;
	}

	@xbin   = @cstime;
	$xmin   = -$range;
	$xmax   = $range;
	$tot    = $ccnt;
	$xdiff  = $xmax - $xmin;
	$xside  = $xmin - 0.20 * $xdiff;

	@lxbin  = @lcstime;
	$lxdiff = $lzs2 - $lzs1;

	$ltot   = $lccnt - 1;
	$lymin  = -10;
	$lymax  =  10;

	$out_name = "$fig_out"."$grat[$i]".'_'."$ind[$i]".'/'."$grat[$i]".'_'."$ind[$i]".'_'."$start[$i]".'.gif';
	$out_data = "$grat[$i]".'_'."$ind[$i]".'_'."$start[$i]".'_data';
#
#--- save the data extracted: the name of the file is, e.g., HETG_RETR_2003344.09292220_data.gz
#
	open(OUT,"> $data_save/$out_data");
	for($jk = 0; $jk < $ccnt; $jk++){
		print OUT "$cstime[$jk]\t$aogbias1[$jk]\t$aogbias2[$jk]\t$aogbias3[$jk]\n";
	}
	close(OUT);
	system("gzip $data_save/$out_data");
#
#--- plotting begins here
#
	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,1);
	pgsch(1);
	pgslw(2);
#
#---- roll plot
#
	@temp  = sort{$a<=>$b} @aogbias1;
	$ymin  = $temp[0];
	$ymax  = $temp[$ccnt -1];
	$ydiff = $ymax - $ymin;
	@ybin  = @aogbias1;
	
	if($ydiff == 0){
		$ms  = abs (0.005 * $ymin);
		$ymax += $ms;
		$ymin -= $ms;
	}else{
		$ymax  += 0.1 * $ydiff;
		$ymin  -= 0.1 * $ydiff;
	}
	$ydiff = $ymax - $ymin;
	$ymid  = $ymin + 0.5 * $ydiff;
	
	pgsvp(0.15, 0.55, 0.70, 1.00);
	pgswin($xmin, $xmax, $ymin, $ymax);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	$y_axis = 'Gryo Drift Rate (Roll)';
#
#---- polynomial fitting
#
	@x_in   = @lcstime;
	@y_in   = @laogbias1;
	$npts   = $lccnt;		# of data point
	$nterms = 5;			# we use 5th degree
	$mode   = 0;			# no errors are used

	svdfit($npts, $nterms);
#
#--- record the fitting results
#
	open(OUT, ">>$result_dir/fitting_results_roll");
	print OUT "$out_data\t$a[0]\t$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\n";
	close(OUT);
#
#--- data point plotting is done with plot_fig sub script
#
	plot_fig();
#
#--- differetiated (data - polynomial fitting) plot is made here
#
	pgsvp(0.60, 1.0, 0.70, 1.00);
	pgswin($lsz1, $lsz2, $lymin, $lymax);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	@lybin = @y_diff;
	
	plot_fig2();
#
#--- pavg1/pstd1 are before the grating move, pavg2/pstd2 are during the move, 
#--- and pavg3/pstd3 are after the grating move. these data will be used for another
#--- analysis later
#
	open(OUT, ">>$result_dir/gyro_drift_hist_roll");
	print OUT "$mid_time\t$pavg1+/-$pstd1\t$pavg2+/-$pstd2\t$pavg3+/-$pstd3\t$grat[$i]\t$ind[$i]\t$mdiff\n";
	close(OUT);

#
#--- pitch plotting
#
	@temp = sort{$a<=>$b} @aogbias2;
	$ymin = $temp[0];
	$ymax = $temp[$ccnt -1];
	$ydiff = $ymax - $ymin;
	@ybin  = @aogbias2;
	
	if($ydiff == 0){
		$ms  = abs (0.005 * $ymin);
		$ymax += $ms;
		$ymin -= $ms;
	}else{
		$ymax  += 0.1 * $ydiff;
		$ymin  -= 0.1 * $ydiff;
	}
	$ydiff = $ymax - $ymin;
	$ymid  = $ymin + 0.5 * $ydiff;
	
	pgsvp(0.15, 0.55, 0.39, 0.69);
	pgswin($xmin, $xmax, $ymin, $ymax);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	$y_axis = 'Gryo Drift Rate (Pitch)';

	@x_in   = @lcstime;
	@y_in   = @laogbias2;
	$npts   = $lccnt;
	$nterms = 5;
	$mode   = 0;
	svdfit($npts, $nterms);

	open(OUT, ">>$result_dir/fitting_results_pitch");
	print OUT "$out_data\t$a[0]\t$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\n";
	close(OUT);

	plot_fig();
	
	pgsvp(0.60, 1.0, 0.39, 0.69);
	pgswin($lsz1, $lsz2, $lymin, $lymax);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	@lybin = @y_diff;

	plot_fig2();
	open(OUT, ">>$result_dir/gyro_drift_hist_pitch");
	print OUT "$mid_time\t$pavg1+/-$pstd1\t$pavg2+/-$pstd2\t$pavg3+/-$pstd3\t$grat[$i]\t$ind[$i]\t$mdiff\n";
	close(OUT);
#
#--- yaw plotting
#
	@temp  = sort{$a<=>$b} @aogbias3;
	$ymin  = $temp[0];
	$ymax  = $temp[$ccnt -1];
	$ydiff = $ymax - $ymin;
	@ybin  = @aogbias3;
	
	if($ydiff == 0){
		$ms    = abs (0.005 * $ymin);
		$ymax += $ms;
		$ymin -= $ms;
	}else{
		$ymax += 0.1 * $ydiff;
		$ymin -= 0.1 * $ydiff;
	}
	$ydiff = $ymax - $ymin;
	$ymid  = $ymin + 0.5 * $ydiff;
	
	pgsvp(0.15, 0.55, 0.08, 0.38);
	pgswin($xmin, $xmax, $ymin, $ymax);
	pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	$y_axis = 'Gryo Drift Rate (Yaw)';

	@x_in   = @lcstime;
	@y_in   = @laogbias3;
	$npts   = $lccnt;
	$nterms = 5;
	$mode   = 0;
	svdfit($npts, $nterms);

	open(OUT, ">>$result_dir/fitting_results_yaw");
	print OUT "$out_data\t$a[0]\t$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\n";
	close(OUT);

	plot_fig();
	$ybot = $ymin - 0.15 * $ydiff;
	pgptext($xmid, $ybot, 0.0,0.5, "Time (Sec)");
	
	pgsvp(0.60, 1.0, 0.08, 0.38);
	pgswin($lsz1, $lsz2, $lymin, $lymax);
	pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	@lybin = @y_diff;

	plot_fig2();
	$lybot = $lymin - 0.15 * $lydiff;
	pgptext($lxmid, $lybot, 0.0,0.5, "Time (Sec)");
	open(OUT, ">>$result_dir/gyro_drift_hist_yaw");
	print OUT "$mid_time\t$pavg1+/-$pstd1\t$pavg2+/-$pstd2\t$pavg3+/-$pstd3\t$grat[$i]\t$ind[$i]\t$mdiff\n";
	close(OUT);

	pgclos();
#
#--- convert a ps file into a gif file
#

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_name");
	
	if($ts_cnt > $ccnt){
		print "end of the tsc data\n";
		exit 1;
	}
	system("rm -rf *fits");
}

##################################################################
### plot_fig: plot data and polynomial fit to the data         ###
##################################################################

sub plot_fig{
	$chk = 0;
	@y_diff = ();
	for($m = 0; $m < $tot; $m++){
		pgpt(1,$xbin[$m], $ybin[$m], $symbol);
		if($xbin[$m] > $lsz1 && $xbin[$m] < $lsz2){
#
#---- polynomial fitting is marked by a green line
#
			$y_est = $a[0]  + $a[1] * $xbin[$m]
		 			+ $a[2] * $xbin[$m] * $xbin[$m]
					+ $a[3] * $xbin[$m] * $xbin[$m] * $xbin[$m]
					+ $a[4] * $xbin[$m] * $xbin[$m] * $xbin[$m] * $xbin[$m]
					+ $a[5] * $xbin[$m] * $xbin[$m] * $xbin[$m] * $xbin[$m] * $xbin[$m];
			$diff = $ybin[$m] - $y_est;
			push(@y_diff, 1e5 * $diff);
			pgsci(3);
			if($chk == 0){
				pgmove($xbin[$m], $y_est);
				$chk++;
			}else{
				pgdraw($xbin[$m], $y_est);
			}
			pgsci(1);
		}
	}

#
#--- the grating move is indicated by two red vertial lines
#
	pgsci(2);
	pgmove($sz1,$ymin);
	pgdraw($sz1,$ymax);
	pgmove($sz2,$ymin);
	pgdraw($sz2,$ymax);

	pgsfs(2);
	pgrect($sz1, $sz2,$ymin, $ymax);
	pgsfs(1);
	pgsci(1);

	pgptext($xside, $ymid, 90.0,0.5, "$y_axis");
}

#############################################################################
### plot_fig2: plot differentiated data, and compute mean and std for     ###
### each sections							  ###
#############################################################################

sub plot_fig2{
	$sum  = 0;
	$sum2 = 0;
	$ara1 = 0;
	$ars1 = 0;
	$acnt1= 0;
	$ara2 = 0;
	$ars2 = 0;
	$acnt2= 0;
	$ara3 = 0;
	$ars3 = 0;
	$acnt3= 0;
#
#--- devide the data into three secitons before, during, and after the grating move
#
	for($m = 0; $m < $ltot; $m++){

		pgpt(1,$lxbin[$m], $lybin[$m], $symbol);

		$sum  += $lybin[$m];
		$sum2 += $lybin[$m] * $lybin[$m];
		if($lxbin[$m]< $sz1){
			$ara1 += $lybin[$m];
			$ars1 += $lybin[$m] * $lybin[$m];
			$acnt1++;
		}elsif($lxbin[$m] >= $sz1 && $lxbin[$m] < $sz2){
			$ara2 += $lybin[$m];
			$ars2 += $lybin[$m] * $lybin[$m];
			$acnt2++;
		}else{
			$ara3 += $lybin[$m];
			$ars3 += $lybin[$m] * $lybin[$m];
			$acnt3++;
		}
	}
#
#--- pavg/pstd   are avg and std for the entire range
#--- pavg1/pstd1 are avg and std before the grating move
#--- pavg2/pstd2 are avg and std during the grating move
#--- pavg3/pstd3 are avg and std after the grating move
#
	if($ltot <= 0){
		$pavg = 999;
		$pstd = 999;
	}else{
		$avg = $sum/$ltot;
		$std = sqrt($sum2/$ltot - $avg * $avg);
		$pavg = sprintf "%2.3f", $avg;
		$pstd = sprintf "%2.3f", $std;
	}


	if($acnt1 <= 0){
		$pavg1 = 999;
		$pstd1 = 999;
	}else{
		$avg1 = $ara1/$acnt1;
		$std1 = sqrt($ars1/$acnt1 - $avg1 * $avg1);
		$pavg1 = sprintf "%2.3f", $avg1;
		$pstd1 = sprintf "%2.3f", $std1;
	}

	if($acnt2 <= 0){
		$pavg2 = 999;
		$pstd2 = 999;
	}else{
		$avg2 = $ara2/$acnt2;
		$std2 = sqrt($ars2/$acnt2 - $avg2 * $avg2);
		$pavg2 = sprintf "%2.3f", $avg2;
		$pstd2 = sprintf "%2.3f", $std2;
	}

	if($acnt3 <= 0){
		$pavg3 = 999;
		$pstd3 = 999;
	}else{
		$avg3 = $ara3/$acnt3;
		$std3 = sqrt($ars3/$acnt3 - $avg3 * $avg3);
		$pavg3 = sprintf "%2.3f", $avg3;
		$pstd3 = sprintf "%2.3f", $std3;
	}

	$lxdiff = $lsz2 - $lsz1;
	$lxtop  = $lsz1 + 0.05 * $lxdiff;
	$lydiff = $lymax - $lymin;
	$lytop  = $lymax - 0.10 * $lydiff;
	pgptext($lxtop, $lytop, 0, 0.0, "$pavg+/-$pstd");

	pgsci(2);
	pgmove($sz1,$lymin);
	pgdraw($sz1,$lymax);
	pgmove($sz2,$lymin);
	pgdraw($sz2,$lymax);
	pgsci(1);
}

##################################################################
### chg_tform: change time format                              ###
##################################################################

sub chg_tform {
	my($year_form, @a1, @b1, $t1998);
	($year_form) = @_;
	@a1 = split(/\./, $year_form);
	@b1 = split(//, $a1[0]);
	$year = "$b1[0]$b1[1]$b1[2]$b1[3]";
	$yday = "$b1[4]$b1[5]$b1[6]";
	$t1998 = cnv_time_to_t1998($year, $yday, 0, 0, 0);
	$dpart = '0.'."$a1[1]";
	$sec   = $dpart * 86400;
	$t1998 += $sec;
	return $t1998;
}

##################################################################
### cnv_time_to_t1998: change time format to sec from 1998.1.1 ###
##################################################################

sub cnv_time_to_t1998{

#######################################################
#       Input   $year: year
#               $ydate: date from Jan 1
#               $hour:$min:$sec:
#
#       Output  $t1998<--- returned
#######################################################

        my($totyday, $totyday, $ttday, $t1998);
        my($year, $ydate, $hour, $min, $sec);
        ($year, $ydate, $hour, $min, $sec) = @_;

        $totyday = 365*($year - 1998);
        if($year > 2000){
                $totyday++;
        }
        if($year > 2004){
                $totyday++;
        }
        if($year > 2008){
                $totyday++;
        }
        if($year > 2012){
                $totyday++;
        }

        $ttday = $totyday + $ydate - 1;
        $t1998 = 86400 * $ttday  + 3600 * $hour + 60 * $min +  $sec;

        return $t1998;
}


#####################################################################
### ch_ydate_to_mon_date: change ydate to month and date          ###
#####################################################################

sub ch_ydate_to_mon_date {

        $tadd = 0;
        $chk = 4.0 * int(0.25 * $tyear);
        if($chk == $tyear){
                $tadd = 1;
        }
        if($tday < 32){
                $mon = '01';
                $mday = $tday;
        }

        if($tday > 31){
                if($tadd == 0){
                        if($tday <60){
                                $mon = '02';
                                $mday = $tday - 31;
                        }elsif($tday < 91){
                                $mon = '03';
                                $mday = $tday - 59;
                        }elsif($tday < 121){
                                $mon = '04';
                                $mday = $tday - 90;
                        }elsif($tday < 152){
                                $mon = '05';
                                $mday = $tday - 120;
                        }elsif($tday < 182){
                                $mon = '06';
                                $mday = $tday - 151;
                        }elsif($tday < 213){
                                $mon = '07';
                                $mday = $tday - 181;
                        }elsif($tday < 244){
                                $mon = '08';
                                $mday = $tday - 212;
                        }elsif($tday < 274){
                                $mon = '09';
                                $mday = $tday - 243;
                        }elsif($tday < 305){
                                $mon = '10';
                                $mday = $tday - 273;
                        }elsif($tday < 335){
                                $mon = '11';
                                $mday = $tday - 304;
                        }else{
                                $mon = '12';
                                $mday = $tday - 334;
                        }
                }else{
                        if($tday <61){
                                $mon = '02';
                                $mday = $tday - 31;
                        }elsif($tday < 92){
                                $mon = '03';
                                $mday = $tday - 60;
                        }elsif($tday < 122){
                                $mon = '04';
                                $mday = $tday - 91;
                        }elsif($tday < 153){
                                $mon = '05';
                                $mday = $tday - 121;
                        }elsif($tday < 183){
                                $mon = '06';
                                $mday = $tday - 152;
                        }elsif($tday < 214){
                                $mon = '07';
                                $mday = $tday - 182;
                        }elsif($tday < 245){
                                $mon = '08';
                                $mday = $tday - 213;
                        }elsif($tday < 275){
                                $mon = '09';
                                $mday = $tday - 244;
                        }elsif($tday < 306){
                                $mon = '10';
                                $mday = $tday - 274;
                        }elsif($tday < 336){
                                $mon = '11';
                                $mday = $tday - 305;
                        }else{
                                $mon = '12';
                                $mday = $tday - 335;
                        }
                }
        }
        $mday = int ($mday);
        if($mday < 10){
                $mday = '0'."$mday";
        }
}

########################################################################
###svdfit: polinomial line fit routine                               ###
########################################################################

######################################################################
#	Input: 	@x_in: independent variable list
#		@y_in: dependent variable list
#		@sigmay: error in dependent variable
#		$npts: number of data points		
#		$mode: mode of the data set mode = 0 is fine.
#		$nterms: polinomial dimention		
#		input takes: svdfit($npts, $nterms);
#	
#	Output:	$a[$i]: coefficient of $i-th degree
#		$chisq: chi sq of the fit
#
#	Sub:	svbksb, svdcmp, pythag, funcs
#		where fun could be different (see at the bottom)
#
#	also see pol_val at the end of this file
#
######################################################################

sub svdfit{
#
#----- this code was taken from Numerical Recipes. the original is FORTRAN
#

        $tol = 1.e-5;

        my($ndata, $ma, @x, @y, @sig, @w, $i, $j, $tmp, $ma, $wmax, $sum,$diff);
        ($ndata, $ma) = @_;
        for($i = 0; $i < $ndata; $i++){
                $j = $i + 1;
                $x[$j] = $x_in[$i];
                $y[$j] = $y_in[$i];
                $sig[$j] = $sigmay[$i];
        }
#
#---- accumulate coefficients of the fitting matrix
#
        for($i = 1; $i <= $ndata; $i++){
                funcs($x[$i], $ma);
                if($mode == 0){
                        $tmp = 1.0;
                        $sig[$i] = 1.0;
                }else{
                        $tmp = 1.0/$sig[$i];
                }
                for($j = 1; $j <= $ma; $j++){
                        $u[$i][$j] = $afunc[$j] * $tmp;
                }
                $b[$i] = $y[$i] * $tmp;
        }
#
#---- singular value decompostion sub
#
        svdcmp($ndata, $ma);            ###### this also need $u[$i][$j] and $b[$i]
#
#---- edit the singular values, given tol from the parameter statements
#
        $wmax = 0.0;
        for($j = 1; $j <= $ma; $j++){
                if($w[$j] > $wmax) {$wmax = $w[$j]}
        }
        $thresh = $tol * $wmax;
        for($j = 1; $j <= $ma; $j++){
                if($w[$j] < $thresh){$w[$j] = 0.0}
        }

        svbksb($ndata, $ma);            ###### this also needs b, u, v, w. output is a[$j]
#
#---- evaluate chisq
#
        $chisq = 0.0;
        for($i = 1; $i <= $ndata; $i++){
                funcs($x[$i], $ma);
                $sum = 0.0;
                for($j = 1; $j <= $ma; $j++){
                        $sum  += $a[$j] * $afunc[$j];
                }
                $diff = ($y[$i] - $sum)/$sig[$i];
                $chisq +=  $diff * $diff;
        }
}


########################################################################
### svbksb: solves a*x = b for a vector x                            ###
########################################################################

sub svbksb {
#
#----- this code was taken from Numerical Recipes. the original is FORTRAN
#
        my($m, $n, $i, $j, $jj, $s);
        ($m, $n) = @_;
        for($j = 1; $j <= $n; $j++){
                $s = 0.0;
                if($w[$j] != 0.0) {
                        for($i = 1; $i <= $m; $i++){
                                $s += $u[$i][$j] * $b[$i];
                        }
                        $s /= $w[$j];
                }
                $tmp[$j] = $s;
        }

        for($j = 1; $j <= $n; $j++){
                $s = 0.0;
                for($jj = 1; $jj <= $n; $jj++){
                        $s += $v[$j][$jj] * $tmp[$jj];
                }
                $i = $j -1;
                $a[$i] = $s;
        }
}

########################################################################
### svdcmp: compute singular value decomposition                     ###
########################################################################

sub svdcmp {
#
#----- this code wass taken from Numerical Recipes. the original is FORTRAN
#
        my ($m, $n, $i, $j, $k, $l, $mn, $jj, $x, $y, $s, $g);
        ($m, $n) = @_;

        $g     = 0.0;
        $scale = 0.0;
        $anorm = 0.0;

        for($i = 1; $i <= $n; $i++){
                $l = $i + 1;
                $rv1[$i] = $scale * $g;
                $g = 0.0;
                $s = 0.0;
                $scale = 0.0;
                if($i <= $m){
                        for($k = $i; $k <= $m; $k++){
                                $scale += abs($u[$k][$i]);
                        }
                        if($scale != 0.0){
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$i] /= $scale;
                                        $s += $u[$k][$i] * $u[$k][$i];
                                }
                                $f = $u[$i][$i];

                                $ss = $f/abs($f);
                                $g = -1.0  * $ss * sqrt($s);
                                $h = $f * $g - $s;
                                $u[$i][$i] = $f - $g;
                                for($j = $l; $j <= $n; $j++){
                                        $s = 0.0;
                                        for($k = $i; $k <= $m; $k++){
                                                $s += $u[$k][$i] * $u[$k][$j];
                                        }
                                        $f = $s/$h;
                                        for($k = $i; $k <= $m; $k++){
                                                $u[$k][$j] += $f * $u[$k][$i];
                                        }
                                }
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$i] *= $scale;
                                }
                        }
                }

                $w[$i] = $scale * $g;
                $g = 0.0;
                $s = 0.0;
                $scale = 0.0;
                if(($i <= $m) && ($i != $n)){
                        for($k = $l; $k <= $n; $k++){
                                $scale += abs($u[$i][$k]);
                        }
                        if($scale != 0.0){
                                for($k = $l; $k <= $n; $k++){
                                        $u[$i][$k] /= $scale;
                                        $s += $u[$i][$k] * $u[$i][$k];
                                }
                                $f = $u[$i][$l];

                                $ss = $f /abs($f);
                                $g  = -1.0 * $ss * sqrt($s);
                                $h = $f * $g - $s;
                                $u[$i][$l] = $f - $g;
                                for($k = $l; $k <= $n; $k++){
                                        $rv1[$k] = $u[$i][$k]/$h;
                                }
                                for($j = $l; $j <= $m; $j++){
                                        $s = 0.0;
                                        for($k = $l; $k <= $n; $k++){
                                                $s += $u[$j][$k] * $u[$i][$k];
                                        }
                                        for($k = $l; $k <= $n; $k++){
                                                $u[$j][$k] += $s * $rv1[$k];
                                        }
                                }
                                for($k = $l; $k <= $n; $k++){
                                        $u[$i][$k] *= $scale;
                                }
                        }
                }

                $atemp = abs($w[$i]) + abs($rv1[$i]);
                if($atemp > $anorm){
                        $anorm = $atemp;
                }
        }

        for($i = $n; $i > 0; $i--){
                if($i < $n){
                        if($g != 0.0){
                                for($j = $l; $j <= $n; $j++){
                                        $v[$j][$i] = $u[$i][$j]/$u[$i][$l]/$g;
                                }
                                for($j = $l; $j <= $n; $j++){
                                        $s = 0.0;
                                        for($k = $l; $k <= $n; $k++){
                                                $s += $u[$i][$k] * $v[$k][$j];
                                        }
                                        for($k = $l; $k <= $n; $k++){
                                                $v[$k][$j] += $s * $v[$k][$i];
                                        }
                                }
                        }
                        for($j = $l ; $j <= $n; $j++){
                                $v[$i][$j] = 0.0;
                                $v[$j][$i] = 0.0;
                        }
                }
                $v[$i][$i] = 1.0;
                $g = $rv1[$i];
                $l = $i;
        }

        $istart = $m;
        if($n < $m){
                $istart = $n;
        }
        for($i = $istart; $i > 0; $i--){
                $l = $i + 1;
                $g = $w[$i];
                for($j = $l; $j <= $n; $j++){
                        $u[$i][$j] = 0.0;
                }

                if($g != 0.0){
                        $g = 1.0/$g;
                        for($j = $l; $j <= $n; $j++){
                                $s = 0.0;
                                for($k = $l; $k <= $m; $k++){
                                        $s += $u[$k][$i] * $u[$k][$j];
                                }
                                $f = ($s/$u[$i][$i])* $g;
                                for($k = $i; $k <= $m; $k++){
                                        $u[$k][$j] += $f * $u[$k][$i];
                                }
                        }
                        for($j = $i; $j <= $m; $j++){
                                $u[$j][$i] *= $g;
                        }
                }else{
                        for($j = $i; $j <= $m; $j++){
                                $u[$j][$i] = 0.0;
                        }
                }
                $u[$i][$i]++;
        }

        OUTER2:
        for($k = $n; $k > 0; $k--){
                for($its = 0; $its < 30; $its++){
                        $do_int = 0;
                        OUTER:
                        for($l = $k; $l > 0; $l--){
                                $nm = $l -1;
                                if((abs($rv1[$l]) + $anorm) == $anorm){
                                        last OUTER;
                                }
                                if((abs($w[$nm]) + $anorm) == $anorm){
                                        $do_int = 1;
                                        last OUTER;
                                }
                        }
                        if($do_int == 1){
                                $c = 0.0;
                                $s = 1.0;
                                for($i = $l; $i <= $k; $i++){
                                        $f = $s * $rv1[$i];
                                        $rv1[i] = $c * $rv1[$i];
                                        if((abs($f) + $anorm) != $anorm){
                                                $g = $w[$i];
                                                $h = pythag($f, $g);
                                                $w[$i] = $h;
                                                $h = 1.0/$h;
                                                $c = $g * $h;
                                                $s = -1.0 * $f * $h;
                                                for($j = 1; $j <= $m; $j++){
                                                        $y = $u[$j][$nm];
                                                        $z = $u[$j][$i];
                                                        $u[$j][$nm] = ($y * $c) + ($z * $s);
                                                        $u[$j][$i]  = -1.0 * ($y * $s) + ($z * $c);
                                                }
                                        }
                                }
                        }

                        $z = $w[$k];
                        if($l == $k ){
                                if($z < 0.0) {
                                        $w[$k] = -1.0 * $z;
                                        for($j = 1; $j <= $n; $j++){
                                                $v[$j][$k] *= -1.0;
                                        }
                                }
                                next OUTER2;
                        }else{
                                if($its == 29){
                                        print "No convergence in 30 iterations\n";
                                        exit 1;
                                }
                                $x = $w[$l];
                                $nm = $k -1;
                                $y = $w[$nm];
                                $g = $rv1[$nm];
                                $h = $rv1[$k];
                                $f = (($y - $z)*($y + $z) + ($g - $h)*($g + $h))/(2.0 * $h * $y);
                                $g = pythag($f, 1.0);

                                $ss = $f/abs($f);
                                $gx = $ss * $g;

                                $f = (($x - $z)*($x + $z) + $h * (($y/($f + $gx)) - $h))/$x;

                                $c = 1.0;
                                $s = 1.0;
                                for($j = $l; $j <= $nm; $j++){
                                        $i = $j +1;
                                        $g = $rv1[$i];
                                        $y = $w[$i];
                                        $h = $s * $g;
                                        $g = $c * $g;
                                        $z = pythag($f, $h);
                                        $rv1[$j] = $z;
                                        $c = $f/$z;
                                        $s = $h/$z;
                                        $f = ($x * $c) + ($g * $s);
                                        $g = -1.0 * ($x * $s) + ($g * $c);
                                        $h = $y * $s;
                                        $y = $y * $c;
                                        for($jj = 1; $jj <= $n ; $jj++){
                                                $x = $v[$jj][$j];
                                                $z = $v[$jj][$i];
                                                $v[$jj][$j] = ($x * $c) + ($z * $s);
                                                $v[$jj][$i] = -1.0 * ($x * $s) + ($z * $c);
                                        }
                                        $z = pythag($f, $h);
                                        $w[$j] = $z;
                                        if($z != 0.0){
                                                $z = 1.0/$z;
                                                $c = $f * $z;
                                                $s = $h * $z;
                                        }
                                        $f = ($c * $g) + ($s * $y);
                                        $x = -1.0 * ($s * $g) + ($c * $y);
                                        for($jj = 1; $jj <= $m; $jj++){
                                                $y = $u[$jj][$j];
                                                $z = $u[$jj][$i];
                                                $u[$jj][$j] = ($y * $c) + ($z * $s);
                                                $u[$jj][$i] = -1.0 * ($y * $s) + ($z * $c);
                                        }
                                }
                                $rv1[$l] = 0.0;
                                $rv1[$k] = $f;
                                $w[$k] = $x;
                        }
                }
        }
}

########################################################################
### pythag: compute sqrt(x**2 + y**2) without overflow               ###
########################################################################

sub pythag{
        my($a, $b);
        ($a,$b) = @_;

        $absa = abs($a);
        $absb = abs($b);
        if($absa == 0){
                $result = $absb;
        }elsif($absb == 0){
                $result = $absa;
        }elsif($absa > $absb) {
                $div    = $absb/$absa;
                $result = $absa * sqrt(1.0 + $div * $div);
        }elsif($absb > $absa){
                $div    = $absa/$absb;
                $result = $absb * sqrt(1.0 + $div * $div);
        }
        return $result;
}

########################################################################
### funcs: linear polymonical fuction                                ###
########################################################################

sub funcs {
        my($inp, $pwr, $kf, $temp);
        ($inp, $pwr) = @_;
        $afunc[1] = 1.0;
        for($kf = 2; $kf <= $pwr; $kf++){
                $afunc[$kf] = $afunc[$kf-1] * $inp;
        }
}

########################################################################
### funcs2 :Legendre polynomial function                            ####
########################################################################

sub funcs2 {
#
#---- this one is not used in this script
#
        my($inp, $pwr, $j, $f1, $f2, $d, $twox);
        ($inp, $pwr) = @_;
        $afunc[1] = 1.0;
        $afunc[2] = $inp;
        if($pwr > 2){
                $twox = 2.0 * $inp;
                $f2   = $inp;
                $d    = 1.0;
                for($j = 3; $j <= $pwr; $j++){
                        $f1 = $d;
                        $f2 += $twox;
                        $d++;
                        $afunc[$j] = ($f2 * $afunc[$j-1] - $f1 * $afunc[$j-2])/$d;
                }
        }
}


######################################################################
### pol_val: compute a value for polinomial fit for  give coeffs   ###
######################################################################

sub pol_val{
###############################################################
#	Input: $a[$i]: polinomial parameters of i-th degree
#		$dim:  demension of the fit
#		$x:    dependent variable 
#	Output: $out:  the value at $x
###############################################################
        my ($x, $dim, $i, $j, $out);
        ($dim, $x) = @_;
        funcs($x, $dim);
        $out = $a[0];
        for($i = 1; $i <= $dim; $i++){
                $out += $a[$i] * $afunc[$i +1];
        }
        return $out;
}

