#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	plot_scelec2.perl: plot battery data							#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Oct 31, 2007								#
#												#
#################################################################################################

$file = $ARGV[0];		#--- e.g., Data/batt_full.dat
$elbi_env = $ARGV[1];
$elbv_env = $ARGV[2];
$hrma_env = $ARGV[3];
$oba_env  = $ARGV[4];
chomp $file;
chomp $elbi_env;
chomp $elbv_env;
chomp $hrma_env;
chomp $oba_env;

@time     = ();
@elbi     = ();		# LOAD BUS CURRENT
@elbv     = ();		# LOAD BUS VOLTAGE
@obattpwr = ();		# BATTERIES COMPUTED TOTAL POWER
@ohrmapwr = ();		# HRMA COMPUTED TOTAL POWER
@oobapwr  = ();		# OBA COMPUTED TOTAL POWER
$cnt   = 0;

open(FH, "./$file");
$j = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($j == 60){
		push(@time,     $atemp[0]);
		push(@elbi,	$atemp[1]);
		push(@elbv, 	$atemp[2]);
		push(@obattpwr,	$atemp[3]);
		push(@ohrmapwr,	$atemp[4]);
		push(@oobapwr,	$atemp[5]);
		$cnt++;
		$j = 0;
	}
	$j++;
}
close(FH);

@xbin = @time;
$total = $cnt;
$color = 1;
$symbol= 2;

$xvmin = 0.08;
$xvmax = 0.99;
$xmin  = 1999;
$xmax  = 2008;
	
$xdiff = $xmax - $xmin;
$xbot  = $xmin - 0.06 * $xdiff;
$xmid  = $xmin + 0.5 * $xdiff;


pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(4);

#--- Load bus current

@temp  = sort{$a<=>$b} @elbi;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
if($ymin < 0){
	$ymin = 0;
}
$ymax += 0.1 * $ydiff;

$ymin = 50.0;
$ymax = 70.0;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.76, 0.96);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @elbi;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;
open(FH, "$elbi_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

pgsci(2);
pgmove($mdate[0], $mvavg[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $mvavg[$k]);
}
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
pgsci(1);


pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "ELBI");
pgsch(1);

#--- Load bus voltage

@temp  = sort{$a<=>$b} @elbv;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
if($ymin < 0){
	$ymin = 0;
}
$ymax += 0.1 * $ydiff;

$ymin = 28;
$ymax = 32;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.55, 0.75);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @elbv;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;
open(FH, "$elbv_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

pgsci(2);
#pgmove($mdate[0], $mvavg[0]);
#for($k = 1; $k < $env_cnt; $k++){
#	pgdraw($mdate[$k], $mvavg[$k]);
#}
pgmove($mdate[0], $middle[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $middle[$k]);
}
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
pgsci(1);


pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "ELBV");
pgsch(1);

#--- HRMA computed total power

@temp  = sort{$a<=>$b} @ohrmapwr;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
if($ymin < 0){
	$ymin = 0;
}
$ymax += 0.1 * $ydiff;

$ymin = 40;
$ymax = 100;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.34, 0.54);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @ohrmapwr;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;
open(FH, "$hrma_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

pgsci(2);
pgmove($mdate[0], $mvavg[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $mvavg[$k]);
}
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
pgsci(1);


pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "OHRMAPWR");
pgsch(1);

#--- OBA computed total power

@temp  = sort{$a<=>$b} @oobapwr;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
if($ymin < 0){
	$ymin = 0;
}
$ymax += 0.1 * $ydiff;

$ymin = 20;
$ymax = 150;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.25 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.13, 0.33);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @oobapwr;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;
open(FH, "$oba_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

pgsci(2);
pgmove($mdate[0], $mvavg[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $mvavg[$k]);
}
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
pgsci(1);


pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "OOBAPWR");
pgptxt($xmid, $ybot, 0.0, 0.5,  "Time (Year)");
pgsch(1);

pgclos();

#
#--- change to a gif file
#

#####$out_gif = "$file".'.gif';
$out_gif = "env_plot.gif";

system("echo ''|gs -sDEVICE=ppmraw  -r128x128 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop|pnmflip -r270 |ppmtogif > $out_gif");


########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
        pgsci($color);
        pgpt(1, $xbin[0], $ybin[0], $symbol);
        pgmove($xbin[0], $ybin[0]);
        for($m = 1; $m < $total; $m++){
                if($connect == 1){
                        pgdraw($xbin[$m], $ybin[$m]);
                }
                pgpt(1, $xbin[$m], $ybin[$m], $symbol);
        }
        pgsci(1);
}


####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
        $sumx = 0;
        $symy = 0;
        for($n = 0; $n < $data_cnt; $n++){
                $sumx += ($xdata[$n]);
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
        my $sxx = 0;
        my $sxy = 0;

        my (@xt, @yt, $del,$bb, $chisq, $b1, $b2, $f1, $f2, $sigb);

        @xt = ();
        @yt = ();
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

###############################################################################
###sec1998_to_fracyear: change sec from 1998 to time in year               ####
###############################################################################

sub sec1998_to_fracyear{

        my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac);

        ($t_temp) = @_;

        $t_temp += 86400;

        $normal_year = 31536000;
        $leap_year   = 31622400;
        $year        = 1998;

        $j = 0;
        OUTER:
        while($t_temp > 1){
                $jl = $j + 2;
                $chk = 4.0 * int(0.25 * $jl);
                if($chk == $jl){
                        $base = $leap_year;
                }else{
                        $base = $normal_year;
                }

                if($t_temp > $base){
                        $year++;
                        $t_temp -= $base;
                        $j++;
                }else{
                        $yfrac = $t_temp/$base;
                        $yearfac = $year + $yfrac;
                        last OUTER;
                }
        }

        return $yearfac;
}

