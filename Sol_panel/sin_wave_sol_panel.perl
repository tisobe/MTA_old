#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	sin_wave_sol_panel.perl: linear + sine wave model fitting for solar pandel data	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 05, 2013						#
#											#
#########################################################################################

#
#---- this script fit a straight line + sine function + exp decay  on a data
#---- the initial condition is very important; it goes away very easily.
#

#
#--- read an input file name
#

$file = $ARGV[0];
chomp $file;

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
}else{
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

if($data_dir eq ''){
        $data_dir = './';
}


@xfull  = ();
@yfull  = ();
$t_cnt  = 0;
@xbin   = ();
@ybin   = ();
$ntotal = 0;
open(FH, "$file");

#
#--- to save the computation time, use only 1 out of 5 data point; $j is the counter for that
#

$j = 0;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@xfull, $atemp[0]);
	push(@yfull, $atemp[1]);
	$t_cnt++;
	if($j < 5){
		$j++;
		next OUTER;
	}
	$j = 0;
#
#--- removing the extreme outlier
#
	if($atemp[1] > 314){
		push(@xbin, $atemp[0]);
		push(@ybin, $atemp[1]);
		$ntotal++;
	}
}
close(FH);

@xdata    = @xbin;
@ydata    = @ybin;
$data_cnt = $ntotal;

#
#---- robust fit
#

robust_fit();

#
#--- set initial guess for the model fit parameters
#

$a[0] = $int;		#--- liner intercept coeff
$a[1] = $slope;		#--- linear slope coeff
$a[2] = -1.0;		#--- sine amplitude
$a[3] = 6.3;		#--- sine freq
$a[4] = 4.6;		#--- sine shift
$a[5] = -0.0005;	#--- exp decay 

#
#--- $nterms is the numbers of paramters
#

$nterms = 6;

#
#--- fit the model: see sub app_fun for the model
#

gridls($nterms, $ntotal);

open(OUT, '> fit_result');
print OUT  "$a[0]:$a[1]:$a[2]:$a[3]:$a[4]:$a[5]:$file\n";
close(OUT);

#
#--- estimate deviation around the fit
#
$sum  = 0;
$sum2 = 0;
for($i = 0; $i < $ntotal; $i++){
	$y_est = app_func($xbin[$i]);
	$diff  = $ybin[$i] - $y_est;
	$sum  += $diff;
	$sum2 += $diff * $diff;
}
$avg = $sum/$ntotal;
$sig = sqrt($sum2/$ntotal - $avg * $avg);

#
#--- set computation range (in year)
#

$xmin = 1999;
@temp = sort{$a<=>$b} @xdata;
$xmax = $temp[$ntotal -1];
$xmax = int($xmax + 1);

#
#---width of the band around the middle line
#

$sig3 = 3.0 * $sig;

#
#---print out the model fitting values
#

$xdiff = $xmax - $xmin;
$step  = $xdiff/400;
open(OUT, ">sin_data");
for($i = 0; $i < 400; $i++){
	$zzz = 2000 + $step * $i ;
	$y_est = app_func($zzz);
	$y_bot = $y_est - $sig3;
	$y_top = $y_est + $sig3;
	print OUT "$zzz\t$y_est\t$y_bot\t$y_top\n";
}
close(OUT);

####################################################################
## gridls: grid serach least squares fit for a non linear function #
####################################################################

sub gridls {

#######################################################################
#
#	this is grid search least-squares fit for non-linear fuction
#	described in "Data Reduction and Error Analysis for the Physical 
#	Sciences".
#	The function must be given (see the end of this file).
#
#	Input: 	$xbin:	independent variable
#		$ybin:	dependent variable
#		$nterms:	# of coefficients to be fitted
#		$total:		# of data points
#		$a:		initial guess of the coefficients
#				this must not be "0"
#
#		calling format:  gridls($nterms, $total)
#			@xbin, @ybin, @a must be universal
#
#	Output:	$a:		estimated coefficients
#
#######################################################################

	my($nterms, $total,  $no, $test, $fn, $free);
	my($i, $j, $k, $l, $m, $n);
	my($chi1, $chi2, $chi3, $save, $cmax, $delta,@delta);

	($nterms, $total) = @_;

	$rmin = 0; 
	$rmax = $total - 1;

        OUTER:
        for($j = 0; $j < $nterms ; $j++){
#        for($j = 5; $j >= 0 ; $j--){
                $deltaa[$j] = $a[$j]*0.05;
if($j == 5){
                $deltaa[$j] = $a[$j];
}

                $fn    = 0;
                $chi1  = chi_fit();
                $delta =  $deltaa[$j];

                $a[$j] += $delta;
                $chi2 = chi_fit();

                if($chi1  < $chi2){
                        $delta = -$delta;
                        $a[$j] += $delta;
                        chi_fit();
                        $save = $chi1;
                        $chi1 = $chi2;
                        $chi2 = $save;
                }elsif($chi1 == $chi2){
                        $cmax = 1;
                        while($chi1 == $chi2){
                                $a[$j] += $delta;
                                $chi2 = chi_fit();
                                $cmax++;
                                if($cmax > 100){
                                        $ok = 100;
                                        print "$cmax: $a[$j] $delta $chi1 $chi2 something wrong!\n";
                                        last OUTER;
                                        exit 1;
                                }
                        }
                }

                $no = 0;
                $test = 0;
                OUTER:
                while($test < 200){

                        $fn++;
                        $test++;
                        $a[$j] += $delta;
#                        if($a[$j] <= 0){
#                                $a[$j] = 10;
#                                $no++;
#                                last OUTER;
#                        }
                        $chi3 = chi_fit();
                        if($test > 150){
                                $a[$j] = -999;
                                $no++;
                                last OUTER;
                        }
                        if($chi2 >= $chi3) {
                                $chi1= $chi2;
                                $chi2= $chi3;
                        }else{
                                last OUTER;
                        }
                }

                if($no == 0){
                        $delta = $delta *(1.0/(1.0 + ($chi1-$chi2)/($chi3 - $chi2)) + 0.5);
                        $a[$j] = $a[$j] - $delta;
                        $free =  $rmax - $rmin - $nterms;
                        $siga[$j] = $deltaa[$j] * sqrt(2.0/($free*($chi3-2.0*$chi2 + $chi1)));
                }
        }
        $chisq = $sum;
}


####################################################################
###  chi_fit: compute chi sq value                              ####
####################################################################

sub chi_fit{
        $sum = 0;
        $base = $rmax - $rmin;
        if($base == 0){
                $base = 20;             # 20 is totally abitrally chosen
        }
        for($i = $rmin; $i <= $rmax; $i++){
		$val = $xbin[$i];	
                $y_est = app_func($val);
                $diff = ($ybin[$i] - $y_est)/$base;
                $sum += $diff*$diff;
        }
	return $sum;
}


####################################################################
### app_func: function form to be fitted                         ###
####################################################################

sub app_func{

#
#----- you need to difine a function here. coefficients are
#----- a[0] ... a[$nterms], and data points are $xbin[$i], $ybin[$i]
#----- this function is called by gridls
#
	my ($y_est, $x_val);
	($x_val) = @_;

#############################################
# 	here is an example function form
#	replace the following to any
#	function from you need
#-------------------------------------------
#        if($a[2] == 0){
#                $z = 0;
#        }else{
#                $z = ($x_val - $a[0])/$a[2];
#        }
#        $y_est = $a[1]* exp(-1.0*($z*$z)/2.0);
#############################################

###	$y_est = $a[0] + $a[1] * $x_val + $a[2] * sin($a[3] * ($x_val-2000) - $a[4]) * exp($a[5]* ($x_val - 2000));
	$y_est = ($a[0] + $a[1] * $x_val + $a[2] * sin($a[3] * ($x_val-2000) - $a[4])) * exp($a[5]* ($x_val - 2000));

	return $y_est;
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
        @xldat = ();
        @yldat = ();
        for($n = 0; $n < $data_cnt; $n++){
                $xldat[$n] = $xdata[$n] - $xavg;
                $yldat[$n] = $ydata[$n] - $yavg;
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
#       Input:          @xldat  independent variable                    #
#                       @yldat  dependent variable                      #
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
                $xt[$j] = $xldat[$j];
                $yt[$j] = $yldat[$j];
                $sx  += $xldat[$j];
                $sy  += $yldat[$j];
                $sxy += $xldat[$j] * $yldat[$j];
                $sxx += $xldat[$j] * $xldat[$j];
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
                $diff   = $yldat[$j] - ($aa + $bb * $xldat[$j]);
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
                $arr[$j] = $yldat[$j] - $b_in * $xldat[$j];
        }
        @arr = sort{$a<=>$b} @arr;
        $aa = 0.5 * ($arr[$nml] + $arr[$nmh]);
        $sum = 0.0;
        $abdev = 0.0;
        for($j = 0; $j < $total; $j++){
                $d = $yldat[$j] - ($b_in * $xldat[$j] + $aa);
                $abdev += abs($d);
                $sum += $xldat[$j] * sign(1.0, $d);
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



############################################################################
### find_ebar: find error bar for slope using bootstrapp method          ###
############################################################################

sub find_ebar {

        my($sum, $sum2, $avg);
        $data_cnt = $org_tot;
        @sum      = 0;
        @sum2     = 0;

        for($m = 0; $m < 100; $m++){
                @xdata    = ();
                @ydata    = ();
                for($k = 0; $k < $org_tot; $k++){
                        $no = int($org_tot * sqrt(rand() * rand()));
                        push(@xdata, $org_xdata[$no]);
                        push(@ydata, $org_ydata[$no]);
                }
                robust_fit();
                $sum  += $slope;
                $sum2 += $slope * $slope;
        }

        $avg = $sum / 100;
        $std = sqrt($sum2/100 - $avg * $avg);
}

