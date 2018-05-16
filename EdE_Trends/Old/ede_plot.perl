#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################################################
#														#
#	ede_plot.perl: this script plots dom - ede relation                      				#
#			fit two lines by a weighted least square and a robust fit				#
#														#
#	input: 	$file: data file										#
#		format: 0014     0.825740    12   0.825140   1.307   0.258       631.1      89    		#
#				 0.066784  0.016891    Apr 25 2000  4:33AM     277.19				#
#				(ede data from grating plus date in readable and dom attached)			#
#														#
#	author: t. isobe (tisobe@cfa.harvard.edu)								#
#														#
#	last update: Jun 05, 2013										#
#														#
#################################################################################################################

#-------------------------------------------------------------------------
#
#---- setting directories
#
open(FH, "/data/mta/Script/Grating/EdE/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#-------------------------------------------------------------------------

$file   = $ARGV[0];		# data file name
$energy = $ARGV[1];		# the line energy


open(FH, "$file");
@date = ();
@data = ();
@err  = ();
$total = 0;
$sum1  = 0;
$sum2  = 0;

while(<FH>){
	chomp $_;
	if($_ =~ /\*/){
		next;
	}
	@atemp = split(/\s+/, $_);
	$ede   = $atemp[4];
	push(@date, $atemp[10]);
	push(@data, $atemp[4]);
	push(@err,  $atemp[5]);
	$total++;
	$sum1 += $ede;
	$sum2 += $ede* $ede;
}
close(FH);
#
#--- to remove outlyers, set a range, 2 sigma from a mean
#--- and select data within
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
#---- set x axis related values
#
@temp = sort{$a<=>$b} @date;
$xmin = $temp[0];
$xmax = $temp[$total-1];
$xdiff = $xmax - $xmin;
$xmin -= 0.1 * $xdiff;
if($xmin < 0){
	$xmin = 0;
}
$xmax += 0.1 * $xdiff;
$xdiff = $xmax - $xmin;
$xside = $xmin - 0.08 * $xdiff;
$xbot  = $xmin + 0.1 * $xdiff;
$xmid  = $xmin + 0.5 * $xdiff;

#
#---- plot start here
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1, 1);
pgsch(1);
pgslw(3);

pgsvp(0.1, 1.0, 0.5, 1.00);
@indata = @data;
@yerr   = @err;
@temp = sort{$a<=>$b} @indata;
$ymin = $temp[0];
$ymax = $temp[$total-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
if($ymin < 0){
	$ymin = 0;
}
$ymax += 0.1 * $ydiff;
$ydiff = $ymax - $ymin;
$ytop  = $ymax - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$ybot  = $ymin - 0.1 * $ydiff;
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSVT, 0.0, 0.0);
#
#---- plot two dim scattered diagram
#
plot_fig();
#
#---- weighted linear least square fit
#
@date = @x;
@indata = @y;
@yerr   = @er;
$total = $tot1;
linfit();

$yb = $s_int + $slope * $xmin;
$yt = $s_int + $slope * $xmax;
pgmove($xmin, $yb);
pgsci(2);
pgdraw($xmax, $yt);
pgsci(1);
#
#--- robust liear regression
#
@xdata = @x;
@ydata = @y;
$data_cnt = $tot1;
robust_fit();

$yb = $int + $slope * $xmin;
$yt = $int + $slope * $xmax;
pgmove($xmin, $yb);
pgsci(3);
pgdraw($xmax, $yt);
pgsci(1);

$rslope = sprintf "%3.4f", $slope;

pgptxt($xbot, $ytop, 0.0, 0.0, " Slope Weighted Fit: $pslope/ Robust Fit: $rslope");
pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");
pgptxt($xside, $ymid, 90.0, 0.5, "E/dE Line: $energy keV ");

pgclos();

$out_plot = $file;
$out_plot =~ s/_data/_plot.gif/g;
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_plot");
system("rm -rf pgplot.ps");


#########################################################################
### plot_fig: plotting scatttered diagram                             ###
#########################################################################

sub plot_fig{
	pgsch(2);
	for($j = 0; $j < $total; $j++){
		pgpt(1, $date[$j], $indata[$j], 3);
		$le = $indata[$j] - $yerr[$j];
		$lt = $indata[$j] + $yerr[$j];
		pgmove($date[$j], $le);
		pgdraw($date[$j], $lt);
	}
	pgsch(1);
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


