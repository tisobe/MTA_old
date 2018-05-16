#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################
#										#
#	gyro_drift_sigma_plot.perl: plot time trend of sigmas of gyro drift 	#
#				 around graint move				#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update:	Jun 05, 2013						#
#										#
#---usage: perl plot_gyro_sigma.perl  gyro_drift_hist_before HETG INSR		#
#										#
#################################################################################

#
#--- check whether this is a test case
#
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

#
#---- read directories
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


$file = $ARGV[0];		# input data file name
$inst = $ARGV[1];		# instrument name
$ind  = $ARGV[2];		# INSR or RETR

chomp $file;
chomp $inst;
chomp $ind;
#
#--- we need fitted slope values in the other script; prepare an output file name
#
if($file =~ /pitch/){
	$move = 'pitch';
}
if($file =~ /roll/){
	$move = 'roll';
}
if($file =~ /yaw/){
	$move = 'yaw';
}
$slope_file = 'slope_'."$inst".'_'."$ind".'_'."$move";;
system("rm -rf $slope_file");

open(FH, "$result_dir/$file");

@time   = ();
@before = ();
@during = ();
@after  = ();
@ratio1 = ();
@ratio2 = ();
@ratio3 = ();
$cnt    = 0;

while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[4] =~ /$inst/ && $atemp[5] =~ /$ind/){
		$dom = $atemp[0]/86400 - 567;
		push(@time, $dom);
		@btemp = split(/\-/, $atemp[1]);
		$sig1 = $btemp[1];
		push(@before, $sig1);
		@btemp = split(/\-/, $atemp[2]);
		$sig2 = $btemp[1];
		push(@during, $sig2);
		@btemp = split(/\-/, $atemp[3]);
		$sig3 = $btemp[1];
		push(@after, $sig3);
#
#---- limit std range between 0 and 5
#
		if($sig2 <= 0 || $sig1 > 5 || $sig2 > 5){
			$rat1 = 0.0;
		}else{
			$rat1 = $sig1/$sig2;
		}
		if($sig2 <= 0 || $sig3 > 5 || $sig2 > 5){
			$rat1 = 0.0;
		}else{
			$rat2 = $sig3/$sig2;
		}
		if($sig3 <= 0 || $sig1 > 5 || $sig3 > 5){
			$rat3 = 0.0;
		}else{
			$rat3 = $sig1/$sig3;
		}
#
#--- ratio1 is before/during std ratio
#--- ratio2 is after/during std ratio
#--- ratio3 is before/after std ratio
#
		push(@ratio1, $rat1);
		push(@ratio2, $rat2);
		push(@ratio3, $rat3);
		$cnt++;
	}
}
close(FH);

#
#--- set time plotting range etc
#

@temp  = sort{$a<=>$b} @time;
$xmin  = $temp[0];
$xmax  = $temp[$cnt-1];
$xdiff = $xmax - $xmin;
$xmin -= 0.1 * $xdiff;
$xmax += 0.1 * $xdiff;
$xdiff = $xmax - $xmin;
$xbot  = $xmin - 0.1 * $xdiff;
$xmid  = $xmin + 0.5 * $xdiff;
$xside = $xmin - 0.07 * $xdiff;
$xin   = $xmin + 0.1 * $xdiff;

@xin      = @time;
@xdata    = @xin;
$tot      = $cnt;
$data_cnt = $cnt;

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(2);

$color  = 1;
$symbol = 2;

#
#--- before
#
pgsvp(0.08, 1.0, 0.85, 1.00);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = 5.0;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$yin   = $ymax - 0.15 * $ydiff;

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@yin = @before;
@ydata= @before;

robust_fit();

#
#--- print out the slope value
#
open(OUT, ">>$slope_file");
print OUT  "$slope\n";
close(OUT);

plot_fig();
pgptext($xin, $yin, 0.0, 0.0, "Before");

#
#---  during
#
pgsvp(0.08, 1.0, 0.69, 0.84);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = 5.0;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$yin   = $ymax - 0.15 * $ydiff;

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@yin = @during;
@ydata= @during;

robust_fit();

open(OUT, ">>$slope_file");
print OUT "$slope\n";
close(OUT);

plot_fig();
pgptext($xin, $yin, 0.0, 0.0, "During");
pgptext($xside, $ymid, 90.0, 0.5, "Sigma of Gyro Drift Rate");


#
#--- after
#
pgsvp(0.08, 1.0, 0.53, 0.68);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = 5.0;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$yin   = $ymax - 0.15 * $ydiff;

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@yin = @after;
@ydata= @after;

robust_fit();

open(OUT, ">>$slope_file");
print OUT "$slope\n";
close(OUT);

plot_fig();
pgptext($xin, $yin, 0.0, 0.0, "After");


#
#--- ratio1
#
pgsvp(0.08, 1.0, 0.37, 0.52);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = log10(100.0);
$ymin  = log10(0.01);
$ydiff = ($ymax - $ymin);
$ybot  = ($ymin - 0.1 * $ydiff);
$ymid  = ($ymin + 0.5 * $ydiff);
$yin   = ($ymax - 0.15 * $ydiff);

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCLNSTV, 0.0, 0.0);
@yin = @ratio1;
@ydata= @ratio1;
#robust_fit2();

robust_fit();

open(OUT, ">>$slope_file");
print OUT "$slope\n";
close(OUT);

plot_fig2();
pgptext($xin, $yin, 0.0, 0.0, "Before/During");


#
#--- ratio2
#
pgsvp(0.08, 1.0, 0.21, 0.36);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymin  = 0.0;
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = 5.0;
$ymin  = 0.1;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$yin   = $ymax - 0.15 * $ydiff;
$ymax  = log10(100.0);
$ymin  = log10(0.01);
$ydiff = ($ymax - $ymin);
$ybot  = ($ymin - 0.1 * $ydiff);
$ymid  = ($ymin + 0.5 * $ydiff);
$yin   = ($ymax - 0.15 * $ydiff);

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCLNSTV, 0.0, 0.0);
@yin = @ratio2;
@ydata= @ratio2;
#robust_fit2();

robust_fit();

open(OUT, ">>$slope_file");
print OUT "$slope\n";
close(OUT);

plot_fig2();
pgptext($xin, $yin, 0.0, 0.0, "After/During");
pgptext($xside, $ymid, 90.0, 0.5, "Ratios of Sigma of Gyro Drift Rate (Log)");

#
#--- ratio3
#
pgsvp(0.08, 1.0, 0.05, 0.20);

@temp  = sort{$a<=>$b} @before;
$ymin  = $temp[0];
$ymax  = $temp[$cnt-1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymin  = 0.0;
$ymax += 0.1 * $ydiff;
$ymax  = 5.0;
$ymin  = 0.1;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.15 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;
$yin   = $ymax - 0.15 * $ydiff;
$ymax  = log10(100.0);
$ymin  = log10(0.01);
$ydiff = ($ymax - $ymin);
$ybot  = ($ymin - 0.15 * $ydiff);
$ymid  = ($ymin + 0.5 * $ydiff);
$yin   = ($ymax - 0.15 * $ydiff);

pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCLNSTV, 0.0, 0.0);
@yin = @ratio3;
@ydata= @ratio3;
#robust_fit2();

robust_fit();

open(OUT, ">>$slope_file");
print OUT "$slope\n";
close(OUT);

plot_fig2();
pgptext($xmin, $ybot, 0.0, 0.0, "Time (DOM)");
pgptext($xin, $yin, 0.0, 0.0, "Before/After");

pgclos();

$pinst = lc($inst);
$pind  = lc($ind);

$out_name = "$file".'_'."$pinst".'_'."$pind".'.gif';

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $fig_dir/$out_name");

system("rm -rf pgplot.ps");

########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
        pgsci(1);
        pgpt(1, $xin[0], $yin[0], $symbol);
        pgmove($xin[0], $yin[0]);
        for($m = 1; $m < $tot; $m++){
                if($connect == 1){
                        pgdraw($xin[$m], $yin[$m]);
                }
                pgpt(1, $xin[$m], $yin[$m], $symbol);
        }

	$ys = $int + $slope * $xmin;
	$ye = $int + $slope * $xmax;
	pgsci(2);
	pgmove($xmin, $ys);
	pgdraw($xmax, $ye);
        pgsci(1);
}


########################################################
### plot_fig2: plotting data points on a fig          ###
########################################################

sub plot_fig2{
        pgsci(1);
        for($m = 0; $m < $tot; $m++){
		if($yin[$m] <= 0){
			next;
		}
		$ly = log10($yin[$m]);
                pgpt(1, $xin[$m], $ly, $symbol);
        }

	$step = $xdiff/100;
	pgsci(2);
	$mchk = 0;
	for($m = 1; $m < 100; $m++){
		$xest = $step * $m;
		$yest = $int + $slope * $xest;
		if($yest > 0){
			$yest = log10($yest);
			if($mchk == 0){
				pgmove($xest,$yest);
				$mchk++;
			}
			pgdraw($xest, $yest);
		}
	}

        pgsci(1);
}


####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
	$sumx = 0;
	$sumy = 0;
	@xtemp = ();
	@ytemp = ();
	$tcnt  = 0;
	for($n = 0; $n < $data_cnt; $n++){
		if($ydata[$n] >= 0 && $ydata[$n] < 5){
			push(@xtemp, $xdata[$n]);
			push(@ytemp, $ydata[$n]);
			$tcnt++;
			$sumx += $xdata[$n];
			$sumy += $ydata[$n];
		}
	}
	if($tcnt > 0){
		$xavg = $sumx/$tcnt;
		$yavg = $sumy/$tcnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
		@xbin = ();
		@ybin = ();
		for($n = 0; $n < $tcnt; $n++){
			$xbin[$n] = $xtemp[$n] - $xavg;
			$ybin[$n] = $ytemp[$n] - $yavg;
		}
	
		$total  = $tcnt;
		medfit();
		$alpha += $beta * (-1.0 * $xavg) + $yavg;
		$int    = $alpha;
		$slope  = $beta;
		$pslope = sprintf "%4.3e", $slope;
	}else{
		$int    = -999;
		$slope  = -999;
		$pslope = -999;
	}
}

####################################################################
### robust_fit2: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit2{
	my(@xbin, @ybin);
	$sumx = 0;
	$sumy = 0;
	@xtemp = ();
	@ytemp = ();
	$tcnt  = 0;
	for($n = 0; $n < $data_cnt; $n++){
		if($ydata[$n] > 0.0){
			push(@xtemp, $xdata[$n]);
			push(@ytemp, log10($ydata[$n]));
			$tcnt++;
			$sumx += $xdata[$n];
			$sumy += log10($ydata[$n]);
		}
	}
	$xavg = $sumx/$tcnt;
	$yavg = $sumy/$tcnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
	@xbin = ();
	@ybin = ();
	for($n = 0; $n < $tcnt; $n++){
		$xbin[$n] = $xtemp[$n] - $xavg;
		$ybin[$n] = $ytemp[$n] - $yavg;
#		$xbin[$n] = $xtemp[$n] ;
#		$ybin[$n] = $ytemp[$n] ;
	}

	$total = $tcnt;
#	medfit();
least_fit();

print "$alpha<--->";
#	$alpha += $beta * (-1.0 * $xavg) + $yavg;
	
#	$int   = $alpha;
$int += $slope * (-1.0 * $xavg) + $yavg;
#	$slope = $beta;
	$pslope = sprintf "%4.3e", $slope;

print "$int<--->$pslope<--->$xavg<--->$yavg\n";
}


####################################################################
### medfit: robust filt routine                                  ###
####################################################################

sub medfit{

#########################################################################
#									#
#	fit a straight line according to robust fit			#
#	Numerical Recipes (FORTRAN version) p.544			#
#									#
#	Input:		@xbin	independent variable			#
#			@ybin	dependent variable			#
#			total	# of data points			#
#									#
#	Output:		alpha:	intercept				#
#			beta:	slope					#
#									#
#	sub:		rofunc evaluate SUM( x * sgn(y- a - b * x)	#
#			sign   FORTRAN/C sign function			#
#									#
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

###########################################################
###########################################################
###########################################################

sub log10{
	my($val, $lval);
	($val) = @_;
	$lval = log($val)/2.302585093;
	return $lval;
}
