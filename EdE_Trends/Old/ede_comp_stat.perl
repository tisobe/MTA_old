#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	ede_comp_stat.perl: compute student t probablity and other statistics		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Apr 22, 2013							#
#											#
#########################################################################################

$file = $ARGV[0];		# data file name
$line = $ARGV[1];		# line name

@x     = ();
@y     = ();
@date  = ();
@data  = ();
@err   = ();
$total = 0;
$sum1  = 0;
$sum2  = 0;
#
#--- read data
#
open(FH, "$file");
while(<FH>){
	chomp $_;
        if($_ =~ /\*/){
                next;
        }
	@atemp = split(/\s+/, $_);
	$ede = $atemp[4];
        push(@date, $atemp[10]);
        push(@data, $atemp[4]);
        push(@err,  $atemp[5]);
	$total++;
	$sum1 += $ede;
	$sum2 += $ede * $ede;
}
if($total <= 0){
	exit 1;
}
#
#--- find a mean of the data and its standard deviation
#--- so that we can set a range to limit our data in 2 sigma from the mean.
#
$avg = $sum1/$total;
$std = sqrt($sum2/$total - $avg * $avg);

@x    = ();
@y    = ();
@er   = ();
$tot1 = 0;

for($i = 0; $i < $total; $i++){
        $diff = abs($data[$i] - $avg);
        if($diff < 2.0 * $std){
                push(@x, $date[$i]);
                push(@y, $data[$i]);
                push(@er, $err[$i]);
                $tot1++;
        }
}

#
#---- weighted least square method
#

@date   = @x;
@indata = @y;
@yerr   = @er;
$total  = $tot1;
linfit();

#
#--- robust linear regression
#

@xdata = @x;
@ydata = @y;
$data_cnt = $tot1;
robust_fit();
$rslope = sprintf "%3.4f", $slope;

#
#--- student's t computation
#

$n = $tot1 -1;
pearsn();
$prob_p = sprintf "%3.2f", $prob;

#
#--- print out a table for a html use
#

@atemp = split(/EdE_Data/, $file);
$data_file  = 'https://cxc.cfa.harvard.edu/mta_days/mta_grat/EdE_trend/EdE_Data/'."$atemp[1]";

open(OUT, ">>stat_result.html");
print OUT "<tr><td>$line</td><td>$pslope+/-$std</td><td align='center'>$rslope</td><td align='center'>$prob_p</td>\n";
print OUT "<td><a href=\"$data_file\" target='blank'>Data</a></td></tr>\n";
close(OUT);


###################################################################
### linfit: least sq. fitting  for a straight line with weight ####
###################################################################

sub linfit {

###########################################################
#  Input:       @date:       a list of independent variable
#               @indata:     a list of dependent variable
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
	$std = sprintf "%3.4f", $sigm_slope;
}

###########################################################################
### pearsn: compute corr. coeff, and it's significant level             ###
###########################################################################

sub pearsn{
	my($j, $yt, $xt, $t, $df, $syy, $sxy, $sxx, $ay, $ax, $tiny);
	$tiny = 1.0e-20;

###############################################################
#	input: 	@x: array 1
#		@y: array 2
#		$n: number of elements 
#	output:	$r: linear correlation coefficient
#		$z: fisher's z transformation
#		$prob: student's t probability
#	this function and a few below were taken from 
#	Numerical Recipes (C version) Chapter 14.5 and 
#	related chapters
###############################################################

#
#---- find the means
#
	for($j = 1; $j <= $n; $j++){
		$ax += $x[$j];
		$ay += $y[$j];
	}
	$ax /= $n;
	$ay /= $n;
#
#---- compute the correlation coefficient
#
	for($j = 1; $j < $n; $j++){
		$xt = $x[$j] - $ax;
		$yt = $y[$j] - $ay;
		$sxx += $xt * $xt;
		$syy += $yt * $yt;
		$sxy += $xt * $yt;
	}
	$r = $sxy / (sqrt($sxx * $syy) + $tiny);
#
#---- Fisher's z transformation
#
	$z = 0.5 * log((1.0 + $r + $tiny)/(1.0 - $r + $tiny));
	$df = $n -2;
#
#---- Student's t probability
#
	$t    = $r * sqrt($df/((1.0 - $r + $tiny) * (1.0 + $r + $tiny)));
	$prob = betai(0.5 * $df, 0.5, $df/($df + $t * $t));
}

###########################################################################
### betai: returns the incomplete beta fuction                          ###
###########################################################################

sub betai {
	my ($a, $b, $x, $bt);
	($a, $b, $x) = @_;

	if($x < 0.0 || $x > 1.0) {
		print "Bad x in routine betai\n";
		exit 1;
	}

	if($x == 0.0 || $x == 1.0){
		$bt = 0.0;
	}else{
#
#--- factors in front of the continued fraction
#
		$bt = exp(gammln($a + $b) - gammln($a) - gammln($b) + $a * log($x) + $b * log(1.0 - $x));
	}
	if($x < ($a + 1.0)/($a + $b + 2.0)){
		$beta_i = $bt * betacf($a, $b, $x)/$a;
	}else{
		$beta_i = 1.0 - $bt * betacf($b, $a, 1.0- $x)/$b;
	}
	return $beta_i;
}


###########################################################################
### betacf: evaluates continued fraction for incomplete beta function   ###
###########################################################################

sub betacf{
	my($a, $b, $x, $m, $m2, $aa, $c, $d, $del, $h, $qab, $qam, $qap, $maxit, $eps, $fpmin);
	$maxit = 100;
	$eps   = 3.0e-7;
	$fpmin = 1.0e-30;

	($a, $b, $x) = @_;
#
#--- these q's will be used in factors that occur in the coefficient
#
	$qab = $a + $b;
	$qap = $a + 1.0;
	$qam = $a - 1.0;
#
#--- first step of Lentz's method
#
	$c   = 1.0;
	$d   = 1.0 - $qab * $x / $qap;

	if(abs($d) < $fpmin){
		 $d = $fpmin;
	}
	$d = 1.0 / $d;
	$h = $d;

	for($m = 1; $m <= $maxit; $m++){
		$m2 = 2 * $m;
		$aa = $m * ($b - $m)* $x / (($qam + $m2) * ($a + $m2));
#
#--- one step (the even one) of the recurrence
#
		$d  = 1.0 + $aa * $d;
		if(abs($d) < $fpmin ){
			 $d = $fpmin;
		}
		$c = 1.0 + $aa/$c;
		if(abs($c) < $fpmin){
			$c = $fpmin;
		}
		$d = 1.0 / $d;
		$h *= $d * $c;
		$aa = -1.0 * ($a + $m) * ($qab + $m) * $x/(($a + $m2) * ($qap + $m2));
#
#--- next step of the recurrence (the odd one)
#
		$d = 1.0 + $aa * $d;
		if(abs($d) < $fpmin){
			 $d = $fpmin;
		}
		$c = 1.0 + $aa / $c;
		if(abs($c) < $fpmin){
			$c = $fpmin;
		}
		$d = 1.0 / $d;
		$del = $d * $c;
		$h  *= $del;
		if(abs($del - 1.0) < $eps){
			last;
		}
	}
	if($m > $maxit){
		print "a or b too big, or maxit too small in betacf\n";
	}
	return $h;
}

###########################################################################
### return ln of gamma functioin                                        ###
###########################################################################

sub gammln{

	my($xx, $x,$t, $tmp, $ser, $j, $result);
	my(@cof);
	($xx) = @_;
		
	@cof = (76.18009172947146, -86.50532032941677, 24.01409824083091, -1.231739572450155, 
		0.1208650973866179e-2, -0.5395239384953e-5);

	$x = $xx;
	$y = $xx; 
	$tmp = $x + 5.5;
	$tmp -= ($x + 0.5) * log($tmp);
	$ser  = 1.000000000190015;
	for($j = 0; $j <= 5; $j++){
		$ser += $cof[$j] / $y;
		$y++;
	}
	$result = -1.0 * $tmp + log(2.5066282746310005 * $ser / $x);
	return $result;
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
