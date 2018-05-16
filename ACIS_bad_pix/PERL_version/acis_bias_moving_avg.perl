#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;


#########################################################################################
#											#
#	acis_bias_moving_avg.perl: fit a moving average, 5th degree polynomial, 	#
#				  and envelope to bias-overclock data			#
#       this version is modified for weekly trending, not for a memo			#
#	(we do not extend the prediction for 1 year)					#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: May 23, 2013							#
#											#
#########################################################################################

OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#######################################

#
#----- an example input: /data/mta_www/mta_bias_bkg/Bias_save/CCD3/quad0
#

$file   = $ARGV[0];
$pstart = $ARGV[1];
$pend   = $ARGV[2];
chomp $file;
chomp $pstart;
chomp $pend;
#
#--- extract CCD name and Node #
#
@atemp = split(/\//, $file);
$ncnt = 0;
foreach(@atemp){
	$ncnt++;
}
#
#--- a gif file name is here, something like: bias_plot_CCD3_quad0.gif
#
$out_name = 'bias_plot_'."$atemp[$ncnt-2]".'_'."$atemp[$ncnt-1]".'.gif';

#
#--- start reading data
#
@date = ();
@bmo  = ();
@err  = ();
$cnt  = 0;

open(FH, "$file");
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
#
#---- dom is  day of mission
#
	$dom   = $atemp[0]/86400 - 567;
	if($pstart =~ /\d/ && $dom < $pstart){
		next OUTER;
	}
	if($pend =~ /\d/ && $dom > $pend){
		last OUTER;
	}
#
#---- diff is difference between bias - overclock
#
	$diff = $atemp[1] - $atemp[3];
	if($diff < -3){
		next OUTER;
	}
#
#---- there are a few cases, the diff value changed significantly. assume that that happens
#---- if error for the bias changed to larger than 20 (normally around 1), and last more than 10 times
#---- consequently.
#---- we call that time is to $stop_date.
#
	if($pstart !~ /\d/ && $pend !~ /\d/){
		if($atemp[2] > 20 && $chk ==  0){
			$stop_date = $dom;
			if($err[$cnt-1] > 20 && $err[$cnt-2] > 20 && $err[$cnt-3] > 20 && $err[$cnt-10] > 20){
				$stop_date = $date[$cnt-11];
				$chk++;
				last OUTER;
			}
		}
	}
	if($chk == 0){
		$stop_date = $dom;
	}
	push(@date, $dom);
	push(@err,  $atemp[2]);
	push(@bmo,  $diff);
	$cnt++;
}
close(FH);
open(OUT, '>temp_data');
for($m = 0; $m < $cnt; $m++){
	print OUT  "$date[$m]\t$bmo[$m]\n";
}
close(OUT);
#
#-- the following perl script computes a moving average, envelopes, and
#-- polynomial fit for the data
#
system("$op_dir/perl $bin_dir/find_moving_avg.perl temp_data 5 4 out_data");
#
#--- read the data just computed
#
open(FH, "out_data");

@time    = ();
@mvavg   = ();
@sigma   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$tot     = 0;
$sum     = 0;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
if($atemp[1] < 0){
	next OUTER;
}
	push(@time,   $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@sigma,  $atemp[2]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	push(@std_fit,$atemp[6]);
	$tot++;
	$sum += $atemp[1];
}
close(FH);
if($tot > 0){
	$avg = $sum/$tot;
}else{
	$avg = 0;
}

#
#--- set a plotting range for x
#
@temp  = sort{$a<=>$b}@date;
$xmin  = $temp[0];
$xmax  = $temp[$cnt-1];
#
#--- set sampling period
#
@temp    = sort{$a<=>$b} @time;
$msample = int(0.03 * $tot);
$mpos    = $tot - $msample;
$xsampl  = $temp[$mpos];

#
#--- extend xmax for another 1 year: we are not doing this for this version
#
$xmaxs  = $xmax;
###$xmax += 365;


#
#--- plotting range for  y
#
$ymin =  $avg - 1.0;
$ymax =  $avg + 1.0;

#
#--- plotting start here
#

pgbegin(0, "/cps",1,1);
pgsubp(1,2);
pgsch(2);
pgslw(2);
pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
#
#---- data point plotting
#
for($m = 0; $m < $cnt; $m++){
	pgpt(1,$date[$m], $bmo[$m], -1);
}

#
#--  the bottom envelope
#
#--- to estimate a future trend, sample data (last 3% of data)
#
@xsample = ();
@ysample = ();
$s_cnt   = 0;

pgsci(4);
pgmove($time[0], $bottom[0]);
for($m = 1; $m < $tot; $m++){
#
#--- sampling data for future trend
#
	pgdraw($time[$m], $bottom[$m]);
	if($time[$m] > $xsampl){
		push(@xsample, $time[$m]);
		push(@ysample, $bottom[$m]);
		$s_cnt++;
	}
}
#
#--- fit a linear trend for future prediction
#
@xbin = @xsample;
@ybin = @ysample;
$total = $s_cnt;
if($total > 20){
	least_fit();
	$yest = $s_int + $slope * $xmax;
}else{
	$pos1 = $tot -1;
	$pos2 = $tot -2;
	$xd = $time[$pos1] - $time[$pos2];
	$yd = $bottom[$pos1] - $bottom[$pos2];
	$yest = $bottom[$pos2] + ($yd/$xd) * ($xmax - $time[$pos1]);
}
#pgsci(5);
#pgdraw($xmax, $yest);
#pgsci(4);

#
#---- top envelope
#
@xsample = ();
@ysample = ();
$s_cnt   = 0;
pgmove($time[0], $top[0]);
for($m = 1; $m < $tot; $m++){
#
#--- sampling data for future trend
#
	pgdraw($time[$m], $top[$m]);
	if($time[$m] > $xsampl){
		push(@xsample, $time[$m]);
		push(@ysample, $top[$m]);
		$s_cnt++;
	}
}
#
#--- fit a linear trend for future prediction
#
@xbin = @xsample;
@ybin = @ysample;
$total = $s_cnt;
if($total > 20){
	least_fit();
	$yest = $s_int + $slope * $xmax;
}else{
	$pos1 = $tot -1;
	$pos2 = $tot -2;
	$xd = $time[$pos1] - $time[$pos2];
	$yd = $top[$pos1] - $top[$pos2];
	$yest = $top[$pos2] + ($yd/$xd) * ($xmax - $time[$pos1]);
}
#pgsci(5);
#pgdraw($xmax, $yest);

pgsci(1);
#
#-- plot moving average
#
pgmove($time[0], $mvavg[0]);
for($m = 1; $m < $tot; $m++){
	if($time[$m] > $stop_date){
		last;
	}
	pgdraw($time[$m], $mvavg[$m]);
}
#
#-- fitted line for moving average
#
pgsci(4);
pgmove($time[0], $middle[0]);
#
#---- stop_date terminates moving average plots
#
pgsci(2);
@xsample = ();
@ysample = ();
$s_cnt   = 0;
for($m = 1; $m < $tot; $m++){
	if($time[$m]> $stop_date){
		last;
	}
	pgdraw($time[$m], $middle[$m]);
	if($time[$m] > $xsampl){
		push(@xsample, $time[$m]);
		push(@ysample, $middle[$m]);
		$s_cnt++;
	}
}
@xbin = @xsample;
@ybin = @ysample;
$total = $s_cnt;
if($total > 20){
	least_fit();
	$yest = $s_int + $slope * $xmax;
}else{
	$pos1 = $tot -1;
	$pos2 = $tot -2;
	$xd = $time[$pos1] - $time[$pos2];
	$yd = $middle[$pos1] - $middle[$pos2];
	$yest = $middle[$pos2] + ($yd/$xd) * ($xmax - $time[$pos1]);
}
#pgsci(5);
#pgdraw($xmax, $yest);

pgsci(1);


pglabel("Time (DOM)", "Bias - OverClock", "$title");

#
#---- plotting standard deviation of moving averages
#

pgenv($xmin, $xmax, 0, 0.5, 0, 0);

pgmove($date[0], $sigma[0]);
for($m = 1; $m< $tot; $m++){
	pgdraw($time[$m], $sigma[$m]);
}
#
#---- polynomial fit for std
#
pgsci(2);
@xsample = ();
@ysample = ();
$s_cnt   = 0;
pgmove($date[0], $std_fit[0]);
for($m = 1; $m< $tot; $m++){
	pgdraw($time[$m], $std_fit[$m]);

        if($time[$m] > $xsampl){
                push(@xsample, $time[$m]);
                push(@ysample, $std_fit[$m]);
                $s_cnt++;
        }
}
@xbin = @xsample;
@ybin = @ysample;
$total = $s_cnt;
if($total > 20){
	least_fit();
	$yest = $s_int + $slope * $xmax;
}else{
	$pos1 = $tot -1;
	$pos2 = $tot -2;
	$xd = $time[$pos1] - $time[$pos2];
	$yd = $std_fit[$pos1] - $std_fit[$pos2];
	$yest = $std_fit[$pos2] + ($yd/$xd) * ($xmax - $time[$pos1]);
}
#pgsci(5);
#pgdraw($xmax, $yest);
pgsci(1);


pglabel("Time (DOM)", "Sigma of Moving Average", "$title");

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_name");

system("rm -rf temp_data out_data  pgplot.ps");

########################################################################
###svdfit: polinomial line fit routine                               ###
########################################################################

######################################################################
#       Input:  @x_in: independent variable list
#               @y_in: dependent variable list
#               @sigmay: error in dependent variable
#               $npts: number of data points
#               $mode: mode of the data set mode = 0 is fine.
#               $nterms: polinomial dimention
#               input takes: svdfit($npts, $nterms);
#
#       Output: $a[$i]: coefficient of $i-th degree
#               $chisq: chi sq of the fit
#
#       Sub:    svbksb, svdcmp, pythag, funcs
#               where fun could be different (see at the bottom)
#
#       also see pol_val at the end of this file
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
#       Input: $a[$i]: polinomial parameters of i-th degree
#               $dim:  demension of the fit
#               $x:    dependent variable
#       Output: $out:  the value at $x
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


##########################################################
### least_fit: least sq. fitting  for a straight line ####
##########################################################

sub least_fit {

###########################################################
#  Input:       @xbin:       a list of independent variable
#               @ybin:       a list of dependent variable
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
                $sum++;
                $sumx  += $xbin[$fit_i];
                $sumy  += $ybin[$fit_i];
                $sumx2 += $xbin[$fit_i] * $xbin[$fit_i];
                $sumy2 += $ybin[$fit_i] * $ybin[$fit_i];
                $sumxy += $xbin[$fit_i] * $ybin[$fit_i];
        }

        $delta = $sum * $sumx2 - $sumx * $sumx;
        $s_int = ($sumx2 * $sumy - $sumx * $sumxy)/$delta;
        $slope = ($sumxy * $sum  - $sumx * $sumy) /$delta;

        $tot1 = $total - 1;
        $variance = ($sumy2 + $s_int * $s_int * $sum + $slope * $slope * $sumx2
                        -2.0 *($s_int * $sumy + $slope * $sumxy
                        - $s_int * $slope * $sumx))/$tot1;
        $sigm_slope = sqrt($variance * $sum/$delta);
}

