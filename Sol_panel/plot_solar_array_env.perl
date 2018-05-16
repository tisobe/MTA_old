#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	plot_solar_array_env.perl: plot solar array temperature data and it model fits		#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Jun 05, 2013								#
#												#
#################################################################################################

$file         = $ARGV[0];       #--- e.g., $data_dir/Data/Data_solar_panel/solar_panel_angle80
$sadany_env   = $ARGV[1];       #--- e.g., solar_panel_angle80_sadany_evn.dat
$sadapy_env   = $ARGV[2];
$solany_param = $ARGV[3];
$solapy_param = $ARGV[4];
$comp_test    = $ARGV[5];	#--- if this is a test, "test"

chomp $file;
chomp $sadany_env;
chomp $sadapy_env;
chomp $solany_param;
chomp $solapy_param;
chomp $comp_test;

#
#---- set directories
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

#----------------------------------------------------------
#---- setting some quantities. these may change in future.
#----------------------------------------------------------
#
#---  -Y SADA
#
$sadany_ymin	= 240.0;
$sadany_ymax	= 300.0;
$sadany_opmin	= 248.0;
$sadany_opmax	= 294.0;
#
#--- + Y SADA
#
$sadapy_ymin	= 250.0;
$sadapy_ymax	= 300.0;
$sadapy_opmin	= 258.0;
$sadapy_opmax	= 294.1;
#
#--- - Y solar array
#
$solany_ymin	= 300.0;
$solany_ymax	= 370.0;
$solany_opmin	= 310.0;
$solany_opmax	= 349.7;
#
#--- + Y solar array
#
$solapy_ymin	= 300.0;
$solapy_ymax	= 340.0;
$solapy_opmin	= 311.1;
$solapy_opmax	= 330.2;

#-------------------------------------------------------
#---- finish settings
#-------------------------------------------------------

@time   = ();
@sadany = ();		# -Y SADA
@sadapy = ();		# +Y SADA
@solany = ();		# Solar array -Y
@solapy = ();		# Solar array +y
$cnt   = 0;

#
#---- read data
#---- use every 60th data point to keep the plot clean
#

open(FH, "$file");

$j = 0;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[1] !~ /\d/ || $atemp[2] !~ /\d/ || $atemp[3] !~ /\d/ || $atemp[4] !~ /\d/){
		next OUTER;
	}
	if($j == 60){
		push(@time,     $atemp[0]);
		push(@sadany,	$atemp[1]);
		push(@sadapy, 	$atemp[2]);
		push(@solany,	$atemp[3]);
		push(@solapy,	$atemp[4]);
		$cnt++;
		$j = 0;
	}
	$j++;
}
close(FH);

@xbin  = @time;
$total = $cnt;
$color = 1;
$symbol= 2;

#
#-- set x axis
#
$xvmin = 0.08;
$xvmax = 0.99;

$xmin  = 1999;
#
#-- xmax is about 2 years beyond the current date
#
@temp  = sort{$a<=>$b} @xbin;
$xmax  = $temp[$cnt-1];
$xmax  = int($xmax + 2.5);
	
$xdiff = $xmax - $xmin;
$xbot  = $xmin - 0.06 * $xdiff;
$xmid  = $xmin + 0.5 * $xdiff;

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(4);

#----------------------------------
#--- -Y SADA
#----------------------------------

#@temp  = sort{$a<=>$b} @sadany;
#$ymin  = $temp[0];
#$ymax  = $temp[$cnt -1];
#$ydiff = $ymax - $ymin;
#$ymin -= 0.1 * $ydiff;
#if($ymin < 0){
#	$ymin = 0;
#}
#$ymax += 0.1 * $ydiff;

#
#--- set y axis
#

$ymin  = $sadany_ymin;
$ymax  = $sadany_ymax;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.76, 0.96);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

#
#---- plot data
#

@ybin = @sadany;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;

#
#---- read the estimated envelope data
#

open(FH, "$sadany_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] < 2000){
		next;
	}
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

#
#--- estimate the extentions
#--- use the last 6 data points and fit a straight line
#

@x_dat = ();
@y_mid = ();
@y_bot = ();
@y_top = ();
$tot_cnt = 0;
$c_start = $env_cnt -1;
$c_end   = $env_cnt - 6;
for($k = $c_start; $k >= $c_end; $k--){
	push(@x_dat, $mdate[$k]);
	push(@y_mid, $middle[$k]);
	push(@y_bot, $bottom[$k]);
	push(@y_top, $top[$k]);
	$tot_cnt++;
}

@y_dat = @y_mid;
least_fit();

$m_int = $s_int;
$m_slp = $lslope;

@y_dat = @y_bot;
least_fit();

$b_int = $s_int;
$b_slp = $lslope;


@y_dat = @y_top;
least_fit();

$t_int = $s_int;
$t_slp = $lslope;
	
pgsci(2);

#
#--- the average middle line
#
pgmove($mdate[0], $middle[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $middle[$k]);
}
#
#--- extension
#
$start = $m_int + $m_slp * $mdate[$c_start];
$end   = $m_int + $m_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);

#
#--- the bottom envelope
#
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
#
#--- extension
#
$start = $b_int + $b_slp * $mdate[$c_start];
$end   = $b_int + $b_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);

#
#--- the top envelope
#
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
#
#-- extension
#
$start = $t_int + $t_slp * $mdate[$c_start];
$end   = $t_int + $t_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);

pgsci(1);

#
#--- draw top and bottom operational limit lines
#

pgsci(3);
pgmove($xmin, $sadany_opmin);
pgdraw($xmax, $sadany_opmin);

pgmove($xmin, $sadany_opmax);
pgdraw($xmax, $sadany_opmax);
pgsci(1);

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "-Y SADA Temp");
pgsch(1);

#--------------------------------------------
#--- +Y SADA Temp
#--------------------------------------------

#@temp  = sort{$a<=>$b} @sadapy;
#$ymin  = $temp[0];
#$ymax  = $temp[$cnt -1];
#$ydiff = $ymax - $ymin;
#$ymin -= 0.1 * $ydiff;
#if($ymin < 0){
#	$ymin = 0;
#}
#$ymax += 0.1 * $ydiff;

#
#--- set y axis
#
$ymin  = $sadapy_ymin;
$ymax  = $sadapy_ymax;
$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.55, 0.75);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

#
#--- plot data
#
@ybin = @sadapy;
plot_fig();

@mdate   = ();
@mvavg   = ();
@bottom  = ();
@middle  = ();
@top     = ();
$env_cnt = 0;
#
#--- read envelope data
#
open(FH, "$sadapy_env");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] < 2000){
		next;
	}
	push(@mdate,  $atemp[0]);
	push(@mvavg,  $atemp[1]);
	push(@bottom, $atemp[3]);
	push(@middle, $atemp[4]);
	push(@top,    $atemp[5]);
	$env_cnt++;
}
close(FH);

#
#--- estimate extention
#

@x_dat = ();
@y_mid = ();
@y_bot = ();
@y_top = ();
$tot_cnt = 0;
$c_start = $env_cnt -1;
$c_end   = $env_cnt - 6;
for($k = $c_start; $k >= $c_end; $k--){
        push(@x_dat, $mdate[$k]);
        push(@y_mid, $middle[$k]);
        push(@y_bot, $bottom[$k]);
        push(@y_top, $top[$k]);
        $tot_cnt++;
}

@y_dat = @y_mid;
least_fit();

$m_int = $s_int;
$m_slp = $lslope;

@y_dat = @y_bot;
least_fit();

$b_int = $s_int;
$b_slp = $lslope;

@y_dat = @y_top;
least_fit();

$t_int = $s_int;
$t_slp = $lslope;

pgsci(2);
#
#--- middle average estimate
#
pgmove($mdate[0], $middle[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $middle[$k]);
}
#
#--- extension
#
$start = $m_int + $m_slp * $mdate[$c_start];
$end   = $m_int + $m_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);
#
#--- bottom envelope
#
pgmove($mdate[0], $bottom[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $bottom[$k]);
}
#
#---- extension
#
$start = $b_int + $b_slp * $mdate[$c_start];
$end   = $b_int + $b_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);
#
#--- top envelope
#
pgmove($mdate[0], $top[0]);
for($k = 1; $k < $env_cnt; $k++){
	pgdraw($mdate[$k], $top[$k]);
}
#
#--- extension
#
$start = $t_int + $t_slp * $mdate[$c_start];
$end   = $t_int + $t_slp * $xmax;
pgmove($mdate[$c_start], $start);
pgdraw($xmax, $end);

pgsci(1);

#
#--- draw operation limit envelopes
#
pgsci(3);
pgmove($xmin, $sadapy_opmin);
pgdraw($xmax, $sadapy_opmin);

pgmove($xmin, $sadapy_opmax);
pgdraw($xmax, $sadapy_opmax);
pgsci(1);

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "+Y SADA Temp");
pgsch(1);

#--------------------------------------------------------
#---  -Y solar array
#--------------------------------------------------------

#@temp  = sort{$a<=>$b} @solany;
#$ymin  = $temp[0];
#$ymax  = $temp[$cnt -1];
#$ydiff = $ymax - $ymin;
#$ymin -= 0.1 * $ydiff;
#if($ymin < 0){
#	$ymin = 0;
#}
#$ymax += 0.1 * $ydiff;

#
#--- set y axis
#
$ymin = $solany_ymin;
$ymax = $solany_ymax;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.1 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.34, 0.54);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

#
#--- plot data
#

@ybin = @solany;
plot_fig();

#
#--- read model parameters for the envelope
#

$in_line = `cat $solany_param`;
@in_data = split(/:/, $in_line);
$f_int = $in_data[0];
$f_slp = $in_data[1];
$f_amp = $in_data[2];
$f_phs = $in_data[3];
$f_sht = $in_data[4];
$f_exp = $in_data[5];

$f_sum  = 0;
$f_sum2 = 0;

#
#--- estimate std of the data from the model
#
for($k = 0; $k < $cnt; $k++){
     $y_est   = afunc($xbin[$k]);
     $diff    = $ybin[$k] - $y_est;
     $f_sum  += $diff;
     $f_sum2 += $diff * $diff;
}

$f_avg = $f_sum / $cnt;
$f_std = sqrt($f_sum2/$cnt - $f_avg * $f_avg);

$step = ($xmax - 2000)/ 200;

pgsci(2);
#
#--- model fits
#
$y_est = afunc(2000);
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos);
     pgdraw($x_pos, $y_est);
}
#
#--- the upper envelope
#
$y_est = afunc(2000) + 4.0 * $f_std;
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos) + 4.0 * $f_std;
     pgdraw($x_pos, $y_est);
}
#
#--- the lower envelope
#
$y_est = afunc(2000) - 4.0 * $f_std;
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos) -4.0 * $f_std;
     pgdraw($x_pos, $y_est);
}
pgsci(1);

#
#--- draw the operational limits
#
pgsci(3);
pgmove($xmin, $solany_opmin);
pgdraw($xmax, $solany_opmin);

pgmove($xmin, $solany_opmax);
pgdraw($xmax, $solany_opmax);
pgsci(1);

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "-Y Solar Array Temp");
pgsch(1);

#------------------------------------------------------
#--- +Y Solar Array
#------------------------------------------------------

#@temp  = sort{$a<=>$b} @solapy;
#$ymin  = $temp[0];
#$ymax  = $temp[$cnt -1];
#$ydiff = $ymax - $ymin;
#$ymin -= 0.1 * $ydiff;
#if($ymin < 0){
#	$ymin = 0;
#}
#$ymax += 0.1 * $ydiff;

#
#--- set y axis
#
$ymin = $solapy_ymin;
$ymax = $solapy_ymax;

$ydiff = $ymax - $ymin;
$ybot  = $ymin - 0.25 * $ydiff;
$ymid  = $ymin + 0.5 * $ydiff;

pgsvp($xvmin, $xvmax, 0.13, 0.33);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

#
#--- plot data
#

@ybin = @solapy;
plot_fig();

#
#--- read model parameters for the envelope
#

$in_line = `cat $solapy_param`;
@in_data = split(/:/, $in_line);
$f_int = $in_data[0];
$f_slp = $in_data[1];
$f_amp = $in_data[2];
$f_phs = $in_data[3];
$f_sht = $in_data[4];
$f_exp = $in_data[5];

#
#--- estimate std of data form the model
#
$f_sum  = 0;
$f_sum2 = 0;

for($k = 0; $k < $cnt; $k++){
     $y_est   = afunc($xbin[$k]);
     $diff    = $ybin[$k] - $y_est;
     $f_sum  += $diff;
     $f_sum2 += $diff * $diff;
}

$f_avg = $f_sum / $cnt;
$f_std = sqrt($f_sum2/$cnt - $f_avg * $f_avg);

$step = ($xmax - 2000)/ 200;

pgsci(2);
#
#--- model fit
#
$y_est = afunc(2000);
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos);
     pgdraw($x_pos, $y_est);
}
#
#--- the upper envelope
#
$y_est = afunc(2000) + 4.0 * $f_std;
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos) + 4.0 * $f_std;
     pgdraw($x_pos, $y_est);
}
#
#---- the lower envelope
#
$y_est = afunc(2000) - 4.0 * $f_std;
pgmove(2000, $y_est);
for($k = 1; $k < 200; $k++){
     $x_pos = 2000 + $step * $k;
     $y_est = afunc($x_pos) -4.0 * $f_std;
     pgdraw($x_pos, $y_est);
}
pgsci(1);

#
#--- draw operational limits
#

pgsci(3);
pgmove($xmin, $solapy_opmin);
pgdraw($xmax, $solapy_opmin);

pgmove($xmin, $solapy_opmax);
pgdraw($xmax, $solapy_opmax);
pgsci(1);

pgsch(0.7);
pgptxt($xbot, $ymid, 90.0, 0.5, "+Y Solar Array Temp");
pgptxt($xmid, $ybot, 0.0, 0.5,  "Time (Year)");
pgsch(1);

pgclos();

#
#--- change to a gif file
#

$out_gif = "env_plot.gif";

system("echo ''|gs -sDEVICE=ppmraw  -r128x128 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_gif");


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



##########################################################
### least_fit: least sq. fitting  for a straight line ####
##########################################################

sub least_fit {

###########################################################
#  Input:       @x_dat:       a list of independent variable
#               @y_dat:       a list of dependent variable
#               $tot_cnt:      # of data points
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

        for($fit_i = 0; $fit_i < $tot_cnt; $fit_i++) {
                $sum++;
                $sumx  += $x_dat[$fit_i];
                $sumy  += $y_dat[$fit_i];
                $sumx2 += $x_dat[$fit_i] * $x_dat[$fit_i];
                $sumy2 += $y_dat[$fit_i] * $y_dat[$fit_i];
                $sumxy += $x_dat[$fit_i] * $y_dat[$fit_i];
        }

        $delta = $sum * $sumx2 - $sumx * $sumx;
        $s_int = ($sumx2 * $sumy - $sumx * $sumxy)/$delta;
        $lslope = ($sumxy * $sum  - $sumx * $sumy) /$delta;


        $tot1 = $tot_cnt - 1;
        $variance = ($sumy2 + $s_int * $s_int * $sum + $slope * $slope * $sumx2
                        -2.0 *($s_int * $sumy + $slope * $sumxy
                        - $s_int * $slope * $sumx))/$tot1;
        $sigm_slope = sqrt($variance * $sum/$delta);
}


#########################################################################
### afunc: liear + sine wave + exp decay model                        ###
#########################################################################

sub afunc{
        ($input) = @_;
###     $y_est = $f_int + $f_slp * $input + $f_amp * sin($f_phs * ($input - 2000) - $f_sht) * exp($f_exp * ($input - 2000));
     $y_est = ($f_int + $f_slp * $input + $f_amp * sin($f_phs * ($input - 2000) - $f_sht)) * exp($f_exp * ($input - 2000));

     return $y_est;
}

