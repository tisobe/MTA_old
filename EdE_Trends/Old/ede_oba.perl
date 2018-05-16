#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	ede_oba.perl: plot OBA temperature - EdE relationship				#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jun 05, 2013							#
#											#
#########################################################################################

#--------------------------------------------------------------------------
#
#--- setting directories
#
open(FH, "/data/mta/Script/Grating/EdE/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#--------------------------------------------------------------------------

$file    = $ARGV[0];		# input data file: EdE data table file
$out_dir = $ARGV[1];		# OBA data directory
chomp $file;
chomp $out_dir;


@time   = ();
@dom    = ();
@obsid  = ();
@ede    = ();
@err    = ();
$total  = 0;

open(FH, "$file");

while(<FH>){
        chomp $_;
        if($_ =~ /\*/){
                next;
        }
        @atemp = split(/\s+/, $_);
	if($atemp[0] !~ /\d/){
		next;
	}
        push(@obsid, $atemp[0]);
        push(@dom, $atemp[10]);
        $tmonth= $atemp[6];
#
#--- change month format from letter to numeric
#
        $month = change_month_format($tmonth);
        $mday  = $atemp[7];
        $year  = $atemp[8];
#
#--- change date into day from Jan 1
#
        $yday  = find_ydate($year, $month, $mday);
#
#--- change time into 24 hr system
#
        if($atemp[9] =~ /AM/i){
                @btemp = split(/AM/,$atemp[9]);
                @ctemp = split(/:/, $btemp[0]);
                $hr    = $ctemp[0];
                $min   = $ctemp[1];
                if($hr < 10){
                        $hr = '0'."$hr";
                }
                $dtime = "$hr".':'."$min".':00';
        }else{
                @btemp = split(/PM/,$atemp[9]);
                @ctemp = split(/:/, $btemp[0]);
                $hr    = $ctemp[0] + 12;
                $min   = $ctemp[1];
                if($hr < 10){
                        $hr = '0'."$hr";
                }
                $dtime = "$hr".':'."$min".':00';
        }

        $date = "$year".':'."$yday".':'."$dtime";

        push(@time, $date);

        push(@ede, $atemp[4]);
        push(@err, $atemp[5]);
        $total++;
}
close(FH);
#
#--- only when there is new data, call dataseeker
#
if($total > 0){
OUTER:
	for($i = 0; $i < $total; $i++){
#
#--- time interval is set for the first 5 min of the observation
#
		$date = $time[$i];
		chomp $date;
		@ttemp = split(/:/, $date);
		$ttemp[3] += 5;
		if($ttemp[3] > 60){
			$ttemp[3] -= 60;
			$ttemp[2]++;
			if($ttemp[2] > 24){
				$ttemp[2] -= 24;
				$ttemp[1]++;
			}
		}
		$date2 = "$ttemp[0]:$ttemp[1]:$ttemp[2]:$ttemp[3]:$ttemp[4]";
#
#--- calling dataseeker
#
		system("dataseeker.pl infile= print=yes outfile=outfile.fits search_crit=\"timestart=$date timestop=$date2  columns=mtatel..obaheaters_avg\"");
			$chk = `ls ./`;
			if($chk !~ /outfile.fits/){
				next OUTER;
			}
#
#--- start getting data
#	
		LOUTER:
		for($obaj = 1; $obaj < 65; $obaj++){
			$num = $obaj;
			if($obaj < 10){
				$num = '0'."$obaj";
			}
		
			$msid = 'oobthr'."$num";;
			$chk_order = 0;
			$msid_name = "$msid".'_avg';
			$msid_val  = "$msid".'_val';
			$msid_out  = "$msid".'_out';
		
			@temp_list = ();
#
#--- extract temp data for each msids
#
			system("dmlist infile=\"outfile.fits[cols time,$msid_name]\" outfile=outfile.dat opt=data");
			open(FH, './outfile.dat');
			OUTER:
			while(<FH>){
				chomp $_;
				@atemp = split(/\s+/, $_);
				if($atemp[1] =~ /\d/){
					$msid_val = $atemp[3];
					last OUTER;
				}
			}
			close(FH);
			push(@temp_list, $msid_val);
#
#--- print out data
#
			open(OUT, ">>$out_dir/$msid_out");
			print OUT "$msid_val\t$ede[$i]\t$err[$i]\t$obsid[$i]\t$dom[$i]\n";
			close(OUT);
	
		}
		system("rm -rf outfile.fits outfile.dat");
	}
}

#
#---- plotting starts here; 6 figures on on page
#
$plt_cnt = 0;		# number of plot on a page
$tot_cnt = 0;		# number of page

LOUTER:
for($obaj = 1; $obaj < 65; $obaj++){
	$num = $obaj;
	if($obaj < 10){
		$num = '0'."$obaj";
	}
	
	$msid = 'oobthr'."$num";;
	$chk_order = 0;
	$msid_name = "$msid".'_avg';
	$msid_val  = "$msid".'_val';
	$msid_out  = "$msid".'_out';

	@temp_list = ();
	@xbin = ();
	@ybin = ();
	@yerr = ();
	$dcnt = 0;
	
	open(FH, "$out_dir/$msid_out");
	while(<FH>){
        	chomp $_;
        	@atemp = split(/\s+/, $_);
        	push(@xbin, $atemp[0]);
        	push(@ybin, $atemp[1]);
		push(@yerr, $atemp[2]);
        	$dcnt++;
	}
	close(FH);
#
#---- skip if the data is a constant for the entire range
#
	@temp = sort{$a<=>$b} @xbin;
	$xmin = $temp[0];
	$xmax = $temp[$dcnt -1];
	$diff = $xmax - $xmin;
	if($diff == 0){
		next LOUTER;
	}
	$xmin -= 0.1 * $diff;
	$xmax += 0.1 * $diff;
	$xdiff = $xmax - $xmin;
	$xside = $xmin - 0.08 * $xdiff;
	$xbot  = $xmin + 0.1 * $xdiff;
	$xmid  = $xmin + 0.5 * $xdiff;
#
#---- skip if the data is a constant for the entire range
#
	@temp = sort{$a<=>$b} @ybin;
	$ymin = $temp[0];
	$ymax = $temp[$dcnt -1];
	$diff = $ymax - $ymin;
	if($diff == 0){
		next LOUTER;
	}
	$ymin -= 0.1 * $diff;
	$ymax += 0.1 * $diff;
	$ydiff = $ymax - $ymin;
	$ytop  = $ymax - 0.1 * $ydiff;
	$ymid  = $ymin + 0.5 * $ydiff;
	$ybot  = $ymin - 0.1 * $ydiff;
#
#---- a new pgplot page opens every 6 figures
#	
	if($plt_cnt == 0){
		pgbegin(0, '"./pgplot.ps"/cps',1,1);
		pgsubp(2,3);
		pgsch(2);
		pgslw(2);
		pgsci(1);
	}

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	pgsci(1);
	$symbol = 2;	
	for($m = 0; $m < $dcnt; $m++){
        	pgpt(1,$xbin[$m], $ybin[$m], $symbol);
        	$ys = $ybin[$m] - $yerr[$m];
        	$yt = $ybin[$m] + $yerr[$m];
        	pgmove($xbin[$m], $ys);
        	pgdraw($xbin[$m], $yt);
	}
	pgsci(1);
#
#--- we fit a line with robust method
#
	@xdata = @xbin;
	@ydata = @ybin;
	$data_cnt = $dcnt;
	robust_fit();

	$ys = $int + $slope * $xmin;
	$yt = $int + $slope * $xmax;
	pgsci(3);
	pgmove($xmin, $ys);
	pgdraw($xmax, $yt);
	pgsci(1);
	$rslope  = sprintf "%4.1f", $slope;
	pgptxt($xbot, $ytop, 0.0, 0.0, "Slope: $rslope");

	pglab('Temperature (C)','E/dE',"$msid");
#
#--- check whether we plotted six figures on one page; if so, open up a new page
#
	if($plt_cnt >= 5){
		pgclos();
		$plt_cnt = 0;
		$tot_cnt++;
	
		$out_plot = "$out_dir/".'oba_'."$tot_cnt".'.gif';
	
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");
		system("rm -rf pgplot.ps");
	}else{
		$plt_cnt++;
	}
}

############################################################
### change_month_format: change month format             ###
############################################################

sub change_month_format{
        my ($month, $omonth);
        ($month) = @_;
        if($month =~ /\d/){
                if($month == 1){
                        $omonth = 'Jan';
                }elsif($month == 2){
                        $omonth = 'Feb';
                }elsif($month == 3){
                        $omonth = 'Mar';
                }elsif($month == 4){
                        $omonth = 'Apr';
                }elsif($month == 5){
                        $omonth = 'May';
                }elsif($month == 6){
                        $omonth = 'Jun';
                }elsif($month == 7){
                        $omonth = 'Jul';
                }elsif($month == 8){
                        $omonth = 'Aug';
                }elsif($month == 9){
                        $omonth = 'Sep';
                }elsif($month == 10){
                        $omonth = 'Oct';
                }elsif($month == 11){
                        $omonth = 'Nov';
                }elsif($month == 12){
                        $omonth = 'Dec';
                }
        }else{
                if($month =~ /jan/i){
                        $omonth = 1;
                }elsif($month =~ /feb/i){
                        $omonth = 2;
                }elsif($month =~ /mar/i){
                        $omonth = 3;
                }elsif($month =~ /apr/i){
                        $omonth = 4;
                }elsif($month =~ /may/i){
                        $omonth = 5;
                }elsif($month =~ /jun/i){
                        $omonth = 6;
                }elsif($month =~ /jul/i){
                        $omonth = 7;
                }elsif($month =~ /aug/i){
                        $omonth = 8;
                }elsif($month =~ /sep/i){
                        $omonth = 9;
                }elsif($month =~ /oct/i){
                        $omonth = 10;
                }elsif($month =~ /nov/i){
                        $omonth = 11;
                }elsif($month =~ /dec/i){
                        $omonth = 12;
                }
        }
        return $omonth;
        return $omonth;
}

##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

##################################################
#       Input   $tyear: year
#               $tmonth: month
#               $tday:   day of the month
#
#       Output  $ydate: day from Jan 1<--- returned
##################################################

        my($tyear, $tmonth, $tday, $ydate, $chk);
        ($tyear, $tmonth, $tday) = @_;

        if($tmonth == 1){
                $ydate = $tday;
        }elsif($tmonth == 2){
                $ydate = $tday + 31;
        }elsif($tmonth == 3){
                $ydate = $tday + 59;
        }elsif($tmonth == 4){
                $ydate = $tday + 90;
        }elsif($tmonth == 5){
                $ydate = $tday + 120;
        }elsif($tmonth == 6){
                $ydate = $tday + 151;
        }elsif($tmonth == 7){
                $ydate = $tday + 181;
        }elsif($tmonth == 8){
                $ydate = $tday + 212;
        }elsif($tmonth == 9){
                $ydate = $tday + 243;
        }elsif($tmonth == 10){
                $ydate = $tday + 273;
        }elsif($tmonth == 11){
                $ydate = $tday + 304;
        }elsif($tmonth == 12 ){
                $ydate = $tday + 333;
        }
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }
        return $ydate;
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


###################################################################
### linfit: least sq. fitting  for a straight line with weight ####
###################################################################

sub linfit {

###########################################################
#  Input:       @date:       a list of independent variable
#               @indata:       a list of dependent variable
#               @yerr:       a list of dependent variable errors
#               $total:      # of data points
#
#  Output:      $s_int:      intercept of the line
#               $slope:      slope of the line
#               $sigm_slope: the error on the slope
###########################################################

        my($sum, $sumx, $sumy, $symxy, $sumx2, $sumy2, $tot1);

        $sum   = 0;
        $sumx  = 0;
        $sumy  = 0;
        $sumxy = 0;
        $sumx2 = 0;
        $sumy2 = 0;

        for($fit_i = 0; $fit_i < $total; $fit_i++) {
                $sum   += $yerr[$fit_i];
                $sumx  += $yerr[$fit_i] * $date[$fit_i];
                $sumy  += $yerr[$fit_i] * $indata[$fit_i];
                $sumx2 += $yerr[$fit_i] * $date[$fit_i] * $date[$fit_i];
                $sumy2 += $yerr[$fit_i] * $indata[$fit_i] * $indata[$fit_i];
                $sumxy += $yerr[$fit_i] * $date[$fit_i] * $indata[$fit_i];
        }

        $delta = $sum * $sumx2 - $sumx * $sumx;

        $s_int = ($sumx2 * $sumy - $sumx * $sumxy)/$delta;
        $slope = ($sumxy * $sum  - $sumx * $sumy) /$delta;
        $pslope= sprintf "%3.4f", $slope;

        $tot1 = $total - 1;
        $variance = ($sumy2 + $s_int * $s_int * $sum + $slope * $slope * $sumx2
                        -2.0 *($s_int * $sumy + $slope * $sumxy
                        - $s_int * $slope * $sumx))/$tot1;
        $sigm_slope = sqrt($variance * $sum/$delta);
}

####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
        $sumx = 0;
        $symy = 0;
        for($n = 0; $n < $data_cnt; $n++){
                $sumx += $xdata[$n];
                $symy += $ydata[$n];
        }
        $xavg = $sumx/$data_cnt;
        $yavg = $sumy/$data_cnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
        @xbin = ();
        @ybin = ();
        for($n = 0; $n < $data_cnt; $n++){
                $xbin[$n] = $xdata[$n] - $xavg;
                $ybin[$n] = $ydata[$n] - $yavg;
        }

        $total = $data_cnt;
        medfit();

        $alpha += $beta * (-1.0 * $xavg) + $yavg;

        $int   = $alpha;
        $slope = $beta;
}


####################################################################
### medfit: robust filt routine                                  ###
####################################################################

sub medfit{

#########################################################################
#                                                                       #
#       fit a straight line according to robust fit                     #
#       Numerical Recipes (FORTRAN version) p.544                       #
#                                                                       #
#       Input:          @xbin   independent variable                    #
#                       @ybin   dependent variable                      #
#                       total   # of data points                        #
#                                                                       #
#       Output:         alpha:  intercept                               #
#                       beta:   slope                                   #
#                                                                       #

#       sub:            rofunc evaluate SUM( x * sgn(y- a - b * x)      #
#                       sign   FORTRAN/C sign function                  #
#                                                                       #
#########################################################################

        my $sx  = 0;
        my $sy  = 0;
        my $sxy = 0;
        my $sxx = 0;
        my (@xt, @yt, $del,$bb, $chisq, $b1, $b2, $f1, $f2, $sigb);
#
#---- first compute least sq solution
#
        for($j = 0; $j < $total; $j++){
                $xt[$j] = $xbin[$j];
                $yt[$j] = $ybin[$j];
                $sx  += $xbin[$j];
                $sy  += $ybin[$j];
                $sxy += $xbin[$j] * $ybin[$j];
                $sxx += $xbin[$j] * $xbin[$j];
        }

        $del = $total * $sxx - $sx * $sx;
#
#----- least sq. solutions
#
        $aa = ($sxx * $sy - $sx * $sxy)/$del;
        $bb = ($total * $sxy - $sx * $sy)/$del;
        $asave = $aa;
        $bsave = $bb;

        $chisq = 0.0;
        for($j = 0; $j < $total; $j++){
                $diff   = $ybin[$j] - ($aa + $bb * $xbin[$j]);
                $chisq += $diff * $diff;
        }
        $sigb = sqrt($chisq/$del);
        $b1   = $bb;
        $f1   = rofunc($b1);
        $b2   = $bb + sign(3.0 * $sigb, $f1);
        $f2   = rofunc($b2);

        $iter = 0;
        OUTER:
        while($f1 * $f2 > 0.0){
                $bb = 2.0 * $b2 - $b1;
                $b1 = $b2;
                $f1 = $f2;
                $b2 = $bb;
                $f2 = rofunc($b2);
                $iter++;
                if($iter > 100){
                        last OUTER;
                }
        }

        $sigb *= 0.01;
        $iter = 0;
        OUTER1:
        while(abs($b2 - $b1) > $sigb){
                $bb = 0.5 * ($b1 + $b2);
                if($bb == $b1 || $bb == $b2){
                        last OUTER1;
                }
                $f = rofunc($bb);
                if($f * $f1 >= 0.0){
                        $f1 = $f;
                        $b1 = $bb;
                }else{
                        $f2 = $f;
                        $b2 = $bb;
                }
                $iter++;
                if($iter > 100){
                        last OTUER1;
                }
        }
        $alpha = $aa;
        $beta  = $bb;
        if($iter >= 100){
                $alpha = $asave;
                $beta  = $bsave;
        }
        $abdev = $abdev/$total;
}

##########################################################
### rofunc: evaluatate 0 = SUM[ x *sign(y - a bx)]     ###
##########################################################

sub rofunc{
       my ($b_in, @arr, $n1, $nml, $nmh, $sum);

        ($b_in) = @_;
        $n1  = $total + 1;
        $nml = 0.5 * $n1;
        $nmh = $n1 - $nml;
        @arr = ();
        for($j = 0; $j < $total; $j++){
                $arr[$j] = $ybin[$j] - $b_in * $xbin[$j];
        }
        @arr = sort{$a<=>$b} @arr;
        $aa = 0.5 * ($arr[$nml] + $arr[$nmh]);
        $sum = 0.0;
        $abdev = 0.0;
        for($j = 0; $j < $total; $j++){
                $d = $ybin[$j] - ($b_in * $xbin[$j] + $aa);
                $abdev += abs($d);
                $sum += $xbin[$j] * sign(1.0, $d);
        }
        return($sum);
}


##########################################################
### sign: sign function                                ###
##########################################################

sub sign{
        my ($e1, $e2, $sign);
        ($e1, $e2) = @_;
        if($e2 >= 0){
                $sign = 1;
        }else{
                $sign = -1;
        }
        return $sign * $e1;
}
	
