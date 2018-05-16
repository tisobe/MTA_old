#!/usr/bin/perl
use PGPLOT;

$data_name = $ARGV[0];
$switch    = $ARGV[1];
$ymin      = $ARGV[2];
$ymax      = $ARGV[3];
chomp $data_name;

open(FH, "$data_name");
@file_list = ();
@lower_lim = ();
@upper_lim = ();
@envelope  = ();
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@file_list, $atemp[0]);
	push(@lower_lim, $atemp[1]);
	push(@upper_lim, $atemp[2]);
	push(@envelope,  $atemp[3]);
}
close(FH);

$tmax = 0;
$fcnt = 0;
foreach $ent  (@file_list){
	@{data.$fcnt} = ();
	@{date.$fcnt} = ();
	${cnt.$fcnt}  = 0;
	open(FH, "$ent");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$ydate = sec1998_to_fracyear($atemp[0]);
		if($ydate > $tmax){
			$tmax = $ydate;
		}
		push(@{date.$fcnt},$ydate);
		push(@{data.$fcnt},$atemp[1]);
		${cnt.$fcnt}++;
	}
	close(FH);
	$fcnt++;
}

$tmax = int ($tmax + 1);

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(3);

$xvmin = 0.10;
$xvmax = 0.99;
$xmin  = 2000;
$xmax  = $tmax;
$xdiff = $xmax - $xmin;
$xmid  = 0.5 * ($xmax + $xmin);
$xbot  = $xmin - 0.05 * $xdiff;
$last  = $fcnt - 1;
$xname = "Time (Year)";

for($panel = 0; $panel < $fcnt; $panel++){

	$yname =  $file_list[$panel];
	$yname =~ s/_data//;
	$yname =~ s/Cdata\///;

	$yvmin = 0.76 - $panel * 0.23;
	$yvmax = 0.99 - $panel * 0.23;
	pgsvp($xvmin, $xvmax, $yvmin, $yvmax);

	@atemp = sort{$a<=>$b} @{data.$panel};
	if($ymin eq ''){
		$tmin  = 10 * $atemp[0];
		$tmax  = 10 * $atemp[${cnt.$panel} -1];
		$tdiff = $tmax - $tmin;
		$tmin -= 0.1 * $tdiff;
		$ymin  = 0.1 * int ($tmin);
	}
	if($ymax eq ''){
		$tmax += 0.1 * $tdiff;
		$ymax  = 0.1 * int ($tmax);
	}
	$ydiff = $ymax - $ymin;
	$ymid  = 0.5 * ($ymin + $ymax);
	$ybot  = $ymin - 0.24 * $ydiff;
	$yblw  = $ymax - 0.05 * $ydiff;
	
	pgswin($xmin, $xmax, $ymin, $ymax);
	if($panel >= $last){
		if($switch > 1){
			pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}else{
			pgbox(ABCNST, 0.0, 0.0, ABCNST,  0.0, 0.0);
		}
		pgptxt($xbot, $ymid, 90.0, 0.5, "$yname");
		pgptxt($xmid, $ybot, 0.0, 0.0,  "$xname");
	}else{
		if($switch > 1){
			pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		}else{
			pgbox(ABCST, 0.0, 0.0, ABCNST,  0.0, 0.0);
		}
		pgptxt($xbot, $ymid, 90.0, 0.5, "$yname");
	}

	for($i = 0; $i < ${cnt.$panel}; $i++){
		pgpt(1, ${date.$panel}[$i], ${data.$panel}[$i], 1);
	}

	if($envelope[$panel] ne ''){
		open(IN, "$envelope[$panel]");
		@mdate   = ();
		@mvavg   = ();
		@bottom  = ();
		@middle  = ();
		@top     = ();
		$env_cnt = 0;
		while(<IN>){
			chomp $_;
			@btemp = split(/\s+/, $_);
			$ydate = sec1998_to_fracyear($btemp[0]);
			if($ydate < 2000){
				next;
			}
			push(@mdate,  $ydate);
			push(@mvavg,  $btemp[1]);
			push(@bottom, $btemp[3]);
			push(@middle, $btemp[4]);
			push(@top,    $btemp[5]);
			$env_cnt++;
		}
		close(IN);

#
#--- estimation extention
#

		@x_dat = ();
		@y_mid = ();
		@y_bot = ();
		@y_top = ();
		$tot_cnt = 0;
		$c_start = $env_cnt - 1;
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
		#pgmove($mdate[0], $mvavg[0]);
		#for($k = 1; $k < $env_cnt; $k++){
		#       pgdraw($mdate[$k], $mvavg[$k]);
		#}
		pgmove($mdate[0], $middle[0]);
		for($k = 1; $k < $env_cnt; $k++){
        		pgdraw($mdate[$k], $middle[$k]);
		}
		
		$start = $m_int + $m_slp * $mdate[$c_start];
		$end   = $m_int + $m_slp * 2010;
		pgmove($mdate[$c_start], $start);
		pgdraw(2010, $end);
		
		pgmove($mdate[0], $bottom[0]);
		for($k = 1; $k < $env_cnt; $k++){
        		pgdraw($mdate[$k], $bottom[$k]);
		}
		
		$start = $b_int + $b_slp * $mdate[$c_start];
		$end   = $b_int + $b_slp * 2010;
		pgmove($mdate[$c_start], $start);
		pgdraw(2010, $end);
		
		pgmove($mdate[0], $top[0]);
		for($k = 1; $k < $env_cnt; $k++){
        		pgdraw($mdate[$k], $top[$k]);
		}
		
		$start = $t_int + $t_slp * $mdate[$c_start];
		$end   = $t_int + $t_slp * 2010;
		pgmove($mdate[$c_start], $start);
		pgdraw(2010, $end);

		pgsci(1);
	}


	pgsci(3);
	pgmove($xmin, $lower_lim[$panel]);
	pgdraw($xmax, $lower_lim[$panel]);

	pgmove($xmin, $upper_lim[$panel]);
	pgdraw($xmax, $upper_lim[$panel]);
	pgsci(1);
}
pgclos();

$ps_file  = "$data_name".'.ps';
$gif_file = "$data_name".'.gif';

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmcrop| pnmflip -r270 |ppmtogif > $gif_file");

system("mv pgplot.ps $ps_file");


###############################################################################
###sec1998_to_fracyear: change sec from 1998 to time in year               ####
###############################################################################

sub sec1998_to_fracyear{

        my($t_temp, $normal_year, $leap_year, $year, $j, $k, $chk, $jl, $base, $yfrac, $year_date);

        ($t_temp) = @_;

        $t_temp +=  86400;

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
                        $year_date = $year + $yfrac;
                        last OUTER;
                }
        }

        return $year_date;
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
###        $sigm_slope = sqrt($variance * $sum/$delta);
}

