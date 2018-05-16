#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	plot_segment.perl: plot solar panel temperature history of give solar angle data	#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Aug 30, 2007							#
#												#
#################################################################################################

$file = $ARGV[0];			#--- e.g. Data/data_angle140
chomp $file;

@time    = ();
@angle   = ();		#--- solar angle
@tmysada = ();		#--- -Y SADA TEMP
@tpysada = ();		#--- +Y SADA TEMP
@tsamyt  = ();		#--- -Y WING SOLAR ARRAY TEMP
@tsapyt  = ();		#--- +Y WING SOLAR ARRAY TEMP
$cnt     = 0;

open(FH, "./$file");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@time,    $atemp[0]);
	push(@tmysada, $atemp[1]);
	push(@tpysada, $atemp[2]);
	push(@tsamyt,  $atemp[3]);
	push(@tsapyt,  $atemp[4]);
	push(@angle,   $atemp[5]);
	$cnt++;
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

#--- -Y SADA TEMP

@temp  = sort{$a<=>$b} @tmysada;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymax += 0.1 * $ydiff;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.76, 0.96);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @tmysada;
plot_fig();

#
#--- compute robust fits
#

@xdata = @xbin;
@ydata = @ybin;
$data_cnt = $total;

robust_fit();

#
#--- compute slope error
#

@org_xdata = @xbin;
@org_ydata = @ybin;
$org_tot   = $total;

find_ebar();

#
#--- shoten the digit for print
#

$int2000   = $int + 2000 * $slope;
$int_cln   = sprintf "%2.4f", $int2000;
$slope_cln = sprintf "%2.4f", $slope;
$std_cln   = sprintf "%2.4f", $std;
#
#---fit the line
#
$ypos1 = $int + $slope * $xmin;
$ypos2 = $int + $slope * $xmax;
pgmove($xmin, $ypos1);
pgdraw($xmax, $ypos2);

$xpos = $xmax - 0.5 * $xdiff;
$ypos = $ymin + 0.1 * $ydiff;

pgsch(0.8);
pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln +/- $std_cln");
###pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln");

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "-Y SADA TEMP");
pgsch(1);

#--- +Y SADA TEMP

@temp  = sort{$a<=>$b} @tpysada;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymax += 0.1 * $ydiff;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.55, 0.75);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @tpysada;
plot_fig();

#
#--- robust fits
#

@xdata = @xbin;
@ydata = @ybin;
$data_cnt = $total;

robust_fit();

#
#--- slope error
#

@org_xdata = @xbin;
@org_ydata = @ybin;
$org_tot   = $total;

find_ebar();

$int2000   = $int + 2000 * $slope;
$int_cln   = sprintf "%2.4f", $int2000;
$slope_cln = sprintf "%2.4f", $slope;
$std_cln   = sprintf "%2.4f", $std;

$ypos1 = $int + $slope * $xmin;
$ypos2 = $int + $slope * $xmax;
pgmove($xmin, $ypos1);
pgdraw($xmax, $ypos2);

$xpos = $xmax - 0.5 * $xdiff;
$ypos = $ymin + 0.1 * $ydiff;

pgsch(0.8);
pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln +/- $std_cln");
###pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln");

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "+Y SADA TEMP");
pgsch(1);

#--- -Y WING SOLAR ARRAY TEMP

@temp  = sort{$a<=>$b} @tsamyt;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymax += 0.1 * $ydiff;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.34, 0.54);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @tsamyt;
plot_fig();

#
#--- robust fit
#

@xdata = @xbin;
@ydata = @ybin;
$data_cnt = $total;

robust_fit();

#
#--- slope error
#

@org_xdata = @xbin;
@org_ydata = @ybin;
$org_tot   = $total;

find_ebar();

$int2000   = $int + 2000 * $slope;
$int_cln   = sprintf "%2.4f", $int2000;
$slope_cln = sprintf "%2.4f", $slope;
$std_cln   = sprintf "%2.4f", $std;

$ypos1 = $int + $slope * $xmin;
$ypos2 = $int + $slope * $xmax;
pgmove($xmin, $ypos1);
pgdraw($xmax, $ypos2);

$xpos = $xmax - 0.5 * $xdiff;
$ypos = $ymin + 0.1 * $ydiff;

pgsch(0.8);
pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln +/- $std_cln");
###pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln");

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "-Y SOL ARRAY TEMP");
pgsch(1);

#--- +Y WING SOLAR ARRAY TEMP

@temp  = sort{$a<=>$b} @tsapyt;
$ymin  = $temp[0];
$ymax  = $temp[$cnt -1];
$ydiff = $ymax - $ymin;
$ymin -= 0.1 * $ydiff;
$ymax += 0.1 * $ydiff;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.25 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.13, 0.33);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

@ybin = @tsapyt;
plot_fig();

#
#---- robust fit
#

@xdata = @xbin;
@ydata = @ybin;
$data_cnt = $total;

robust_fit();

#
#--- slope error
#

@org_xdata = @xbin;
@org_ydata = @ybin;
$org_tot   = $total;

find_ebar();

$int2000   = $int + 2000 * $slope;
$int_cln   = sprintf "%2.4f", $int2000;
$slope_cln = sprintf "%2.4f", $slope;
$std_cln   = sprintf "%2.4f", $std;

$ypos1 = $int + $slope * $xmin;
$ypos2 = $int + $slope * $xmax;
pgmove($xmin, $ypos1);
pgdraw($xmax, $ypos2);

$xpos = $xmax - 0.5 * $xdiff;
$ypos = $ymin + 0.1 * $ydiff;

pgsch(0.8);
pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln +/- $std_cln");
###pgptxt($xpos, $ypos, 0.0, 0.0, "Int: $int_cln (at 2000)/Slope: $slope_cln");

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "+Y SOL ARRAY TEMP");
pgptxt($xmid, $ybot, 0.0, 0.5,  "Time (Year)");
pgsch(1);

pgclos();

#
#--- change to a gif file
#

$out_gif = "$file".'.gif';

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

