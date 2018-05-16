#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################
#										#
#	acis_gain_plot_gain.perl: plot ACIS gain and offset from data from 	#
#			gain data						#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu				#	
#										#
#	last update: Apr 16, 2013						#
#										#
#################################################################################

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
#---- set output directory
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list';
}
	
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

$dir = '';
if($comp_test !~ /test/i){
	$dir = $ARGV[0]; 				#--- data file directory name
	chomp $dir;
}

if($dir eq ''){
	$dir = "$gain_out/Data";			#--- default data directory
}

for($iccd = 0; $iccd < 10; $iccd++){
	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,1);
	pgsch(1);
	pgslw(3);

	for($node = 0; $node < 4; $node++){
	
		@date   = ();
		@obsid  = ();
		@tstart = ();
		@tstop  = ();
		@gain   = ();
		@tmid	= ();
		@gerr   = ();
		@offset = ();
		@offerr = ();
		$cnt    = 0;
		$gsum1  = 0;
		$osum1  = 0;

		$file = "$dir".'/ccd'."$iccd".'_'."$node";
		open(FH, "$file");
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[4] <= 1000 ){
				next OUTER;
			}
			push(@date,   $atemp[0]);
			push(@obsid,  $atemp[1]);
			push(@tstart, $atemp[2]);
			push(@tstop,  $atemp[3]);
#
#---- get a middle of observation time, and convert it to time in year
#
			$avg = ($atemp[2] + $atemp[3])/2.0;
			$year_time = convtime($avg);
			push(@tmid,   $year_time);
			push(@gain,   $atemp[7]);
			$gsum1 += $atemp[7];
			push(@gerr,   $atemp[8]);
			push(@offset, $atemp[9]);
			$osum1 += $atemp[9];
			push(@offerr, $atemp[10]);
			$cnt++;
		}
		close(FH);
		
		$gavg = $gsum1/$cnt;			#--- these averages will be used to
		$oavg = $osum1/$cnt;			#--- compute ploting ranges
		
#
#--- set ranages for x axis
#

		@temp  = sort{$a<=>$b} @tmid;
		$xmin  = $temp[0];
		$xmax  = $temp[$cnt-1];
		$xdiff = $xmax - $xmin;
		$xmin -= 0.1 * $xdiff;
		$xmax += 0.1 * $xdiff;
		$xdiff = $xmax - $xmin;
		$xbot  = $xmin - 0.10 * $xdiff;
		$xmid  = $xmin + 0.5  * $xdiff;
		$xin   = $xmin + 0.05 * $xdiff;
	
#
#----- gain plot starts here
#

#
#---- robust fit
#
		@xdata = @tmid;
		@ydata = @gain;
		$data_cnt = $cnt;
		robust_fit();
		
		@temp = sort{$a<=>$b}@tmid;
		$xmiddle = $temp[$cnt/2];
		$ymiddle = $int + $slope * $xmiddle;

		$ymin = $ymiddle - 0.008;
		$ymax = $ymiddle + 0.008;

		$ydiff = $ymax - $ymin;
		$ybot  = $ymin - 0.15 * $ydiff;
		$ymid  = $ymin + 0.5  * $ydiff;
		$ytop  = $ymax + 0.02 * $ydiff;
		$yin   = $ymax - 0.10 * $ydiff;
		$yin2  = $ymax - 0.25 * $ydiff;

		if($node == 0){
			pgsvp(0.07, 0.51, 0.78, 0.98);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 1){
			pgsvp(0.07, 0.51, 0.56, 0.76);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 2){
			pgsvp(0.07, 0.51, 0.34, 0.54);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 3){
			pgsvp(0.07, 0.51, 0.12, 0.32);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
			pgptxt($xmax, $ybot, 0.0, 0.0, "Year");
		}
		
		@xbin = @tmid;
		@ybin = @gain;
		@yerr = @gerr;
		$total = $cnt;
		$color = 2;
		$symbol= 4;

		plot_fig();
	
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$boundary = 2006;
		if($iccd == 5 || $iccd == 7){
			$boundary = 2007;
		}
		for($k = 0; $k < $cnt; $k++){
			if($tmid[$k] < $boundary){
				push(@x1, $tmid[$k]);
				push(@y1, $gain[$k]);
				$cnt1++;
			}else{
				push(@x2, $tmid[$k]);
				push(@y2, $gain[$k]);
				$cnt2++;
			}
		}

		@xdata = @x1;
		@ydata = @y1;
		$data_cnt = $cnt1;
		robust_fit();
	
		$y_low = $int + $slope * $xmin;
		$y_top = $int + $slope * $boundary;
		pgmove($xmin, $y_low);
		pgdraw($boundary, $y_top);

		$wslope1 = sprintf "%4.5f", $slope;

		@xdata = @x2;
		@ydata = @y2;
		$data_cnt = $cnt2;
		robust_fit();
	
		$y_low = $int + $slope * $boundary;
		$y_top = $int + $slope * $xmax;
		pgmove($boundary,  $y_low);
		pgdraw($xmax, $y_top);

		$wslope2 = sprintf "%4.5f", $slope;
		pgptxt($xin, $yin,  0.0, 0.0, "Gain (ADU/eV) Node $node");
		pgptxt($xin, $yin2, 0.0, 0.0, "Slope: $wslope1/$wslope2");

#
#---- offset plot starts here
#


#
#---- robust fit
#
		@xdata = @tmid;
		@ydata = @offset;
		$data_cnt = $cnt;
		robust_fit();
	
		@temp = sort{$a<=>$b}@tmid;
		$xmiddle = $temp[$cnt/2];
		$ymiddle = $int + $slope * $xmiddle;

		$ymin = $ymiddle - 10;
		$ymax = $ymiddle + 10;

		if($iccd == 5){
			$ymin = $ymiddle - 30;
			$ymax = $ymiddle + 30;
		}

		if($iccd == 7){
			$ymin = $ymiddle - 14;
			$ymax = $ymiddle + 22;
		}

		$ydiff = $ymax - $ymin;
		$ybot  = $ymin - 0.15 * $ydiff;
		$ymid  = $ymin + 0.5  * $ydiff;
		$ytop  = $ymax + 0.02 * $ydiff;
		$yin   = $ymax - 0.10 * $ydiff;
		$yin2  = $ymax - 0.25 * $ydiff;

		if($node == 0){
			pgsvp(0.56, 1.00, 0.78, 0.98);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 1){
			pgsvp(0.56, 1.00, 0.56, 0.76);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 2){
			pgsvp(0.56, 1.00, 0.34, 0.54);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}elsif($node == 3){
			pgsvp(0.56, 1.00, 0.12, 0.32);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}
	
		@xbin = @tmid;
		@ybin = @offset;
		@yerr = @offerr;
		$total = $cnt;
		$color = 2;
		$symbol= 4;
		plot_fig();
	
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$boundary = 2006;
		if($iccd == 5 || $iccd == 7){
			$boundary = 2007;
		}
		for($k = 0; $k < $cnt; $k++){
			if($tmid[$k] < $boundary){
				push(@x1, $tmid[$k]);
				push(@y1, $offset[$k]);
				$cnt1++;
			}else{
				push(@x2, $tmid[$k]);
				push(@y2, $offset[$k]);
				$cnt2++;
			}
		}

		@xdata = @x1;
		@ydata = @y1;
		$data_cnt = $cnt1;
		robust_fit();
	
		$y_low = $int + $slope * $xmin;
		$y_top = $int + $slope * $boundary;
		pgmove($xmin, $y_low);
		pgdraw($boundary, $y_top);

		$wslope1 = sprintf "%4.5f", $slope;

		@xdata = @x2;
		@ydata = @y2;
		$data_cnt = $cnt2;
		robust_fit();
	
		$y_low = $int + $slope * $boundary;
		$y_top = $int + $slope * $xmax;
		pgmove($boundary,  $y_low);
		pgdraw($xmax, $y_top);
		$wslope2 = sprintf "%4.5f", $slope;
	
		$wslope = sprintf "%4.5f", $slope;
		pgptxt($xin, $yin,  0.0, 0.0, "Offset (ADU) Node $node");
		pgptxt($xin, $yin2, 0.0, 0.0, "Slope: $wslope1/$wslope2");
		
	}	
	pgclos();

#
#---- convert to a gif file
#

	$out_gif = 'gain_plot_ccd'."$iccd".'.gif';
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $gain_out/Plots/$out_gif");
	
	system("rm  -rf pgplot.ps");
}

########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
        pgsci($color);
        pgpt(1, $xbin[0], $ybin[0], $symbol);
        pgmove($xbin[0], $ybin[0]);
        for($m = 1; $m < $total; $m++){
                pgpt(1, $xbin[$m], $ybin[$m], $symbol);
        }
        pgsci(1);
}

##############################################################
### convtime: convert 1998 time to time in years           ###
##############################################################

sub convtime{
	my($l_time);
	($l_time) = @_;
        $t_day = $l_time/86400 + 1;
        $ytime = 1998;
        OUTER:
        while($ytime< 3200){
                $chk = 4.0 * int($ytime/4.0);
                $y_day = 365;
                if($chk == $ytime){
                        $y_day = 366;
                }
                if($t_day >= $y_day){
                        $t_day -= $y_day;
                        $ytime++;
                }else{
                        $ytime += $t_day/$y_day;
                        last OUTER;
                }
        }
	return $ytime;
}

####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
        $sumx = 0;
        $symy = 0;
        $symy2 = 0;

        for($n = 0; $n < $data_cnt; $n++){
                $sumx  += $xdata[$n];
                $symy  += $ydata[$n];
                $symy2 += $ydata[$n] * $ydata[$n];
        }
        $xavg = $sumx/$data_cnt;
        $yavg = $sumy/$data_cnt;
	$ysig = sqrt($symy2/$data_cnt - $yavg * $yavg);
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
        @xbin = ();
        @ybin = ();
	$total = 0;
	$ylow = $yavg - 3 * $ysig;
	$ytop = $yavg + 3 * $ysig;
        for($n = 0; $n < $data_cnt; $n++){
		if($ydata[$n] > $ylow && $ydata[$n] < $ytop){
                	$xbin[$n] = $xdata[$n] - $xavg;
                	$ybin[$n] = $ydata[$n] - $yavg;
			$total++;
		}
        }

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

