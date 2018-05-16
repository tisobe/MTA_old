#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	alignment_sim_twist_fid_trend_plots.perl: plot aca i and j postion shifts	#
#			  			  for each CCDs				#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Aug 04, 2014							#
#											#
#########################################################################################

#
#--- is this test?
#
$comp_test  = $ARGV[0];
chomp $comp_test;

############################################################
#---- set directries
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
############################################################

#
#--- some initial settings
#--- 	a list of detector names
#---    a number of sub plots for each detector
#--     an approximate mean of each subplots. if -999, no plot (only one plot instead of two)
#---    plot width for acent j
#---    dom stating date.
#

@detector_list  = ('I-1','I-2','I-3','I-4','I-5','I-6','S-1','S-2','S-3','S-4','S-5','S-6',
			'H-I-1','H-I-2','H-I-3','H-I-4','H-S-1','H-S-2','H-S-3','H-S-4');
#@detector_list  = ('S-2');

@sub_plot_cnt   = (1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1 );
@sub_plot_cent1 = (-163.5, -165.0, -189.0, 219.0,  217.0, 346.5, -343.5, -344.5, -369.0,  40.0,  37.5, 167.0,
		   -257.0, -257.0,  206.0, 206.5,  -88.0, -86.0,  118.5,  119.0);
@sub_plot_cent2 = (-181.5,  158.3,  -5.0 ,-427.3,  371.4,  -73.5,  -183.0,  158,   -6,      -427.3,  370.0, -75,
		   158.6,  -164.6,   245.5,  -250.5,   238.8,   -242.5, 239.7,  -241.8 );

$plot_begin = 0;

#
#---- create a temporary directory for computation, if there is not one.
#

$alist = `ls -d *`;
@dlist = split(/\s+/, $alist);

OUTER:
foreach $dir (@dlist){
        if($dir =~ /param/){
                system("rm -rf ./param/*");
                last OUTER;
        }
}
system('mkdir ./param');

OUTER:
foreach $dir (@dlist){
        if($dir =~ /Sim_twist_temp2/){
                system("rm -rf ./Sim_twist_temp2/");
                last OUTER;
        }
}
system('mkdir -p ./Sim_twist_temp2');

#
#---- find today's dom
#
if($comp_test =~ /test/i){
	$line = `cat $house_keeping/test_data_interval`;
	@atemp = split(/\s+|\t+/, $line);
	@btemp = split(/\,/, $atemp[1]);
	@ctemp = split(/\//, $btemp[0]);
	$year  = $ctemp[0];
	$mon   = $ctemp[1];
	$day   = $ctemp[2];
	$uyday = 30 * ($mon - 1)  + $day;		#---- this is just an approximation; it does not need to be exact
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
	$year = 1900 + $uyear;
}

$add  = 365 * ($year - 2000) + 163;

if($year > 2000){
	$add++;
}
if($year > 2004){
	$add++;
}
if($year > 2008){
	$add++;
}
if($year > 2012){
	$add++;
}
if($year > 2016){
	$add++;
}
if($year > 2020){
	$add++;
}
if($year > 2024){
	$add++;
}

$dom_today = $uyday + $add;

#
#--- increase a y plotting range slightly as time passes
#

$interval = 4 + 0.5 * ($year - 2005);

#
#---- start plottings
#

$det_cnt = 0;
$xmin  = $plot_begin;
$xmax  = $dom_today;
$xdiff = $xmax - $xmin;
$xmid  = $xmin + 0.50 * $xdiff;
$xside = $xmin - 0.10 * $xdiff;
$xside2 = $xmin + 0.05 * $xdiff;
$step  = 0.15 * $xdiff;

foreach $detector (@detector_list){

#print "$detector\n";

#
#---- read data in (I-1, I-2, ....)
#
	$input = "$data_dir".'/'."$detector";

	open(FH, "$input");
	@time    = ();
	@timei1  = ();
	@timei2  = ();
	@timei3  = ();
	@timei4  = ();
	@timej1  = ();
	@timej2  = ();
	@timej3  = ();
	@timej4  = ();
	@fid     = ();
	@acenti  = ();
	@acentj  = ();
	@acenti1 = ();
	@acenti2 = ();
	@acenti3 = ();
	@acenti4 = ();
	@acentj1 = ();
	@acentj2 = ();
	@acentj3 = ();
	@acentj4 = ();
	@fa      = ();
	@tsc     = ();
	$cnt     = 0 ;
	$icnt1   = 0 ;
	$icnt2   = 0 ;
	$icnt3   = 0 ;
	$icnt4   = 0 ;
	$jcnt1   = 0 ;
	$jcnt2   = 0 ;
	$jcnt3   = 0 ;
	$jcnt4   = 0 ;

	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$dom = $atemp[0]/86400 - 567;
		push(@time,   $dom);
		push(@fid,    $atemp[2]);
		push(@acenti, $atemp[4]);
		push(@acentj, $atemp[5]);
		push(@fa,     $atemp[8]);
		push(@tsc,    $atemp[9]);
		$cnt++;
	}
	close(FH);

	@fid_id = ($fid[0]);
	$fid_no = 1;
	$fid_no1 =2;
	%{fid_color.$fid[0]} = (color =>["$fid_no1"]);
	OUTER:
	for($i = 1; $i< $cnt; $i++){
		foreach $comp (@fid_id){
			if($fid[$i] == $comp){
				next OUTER;
			}
		}
		push(@fid_id, $fid[$i]);
		$fid_no++;
		$fid_no1 += 2;
		%{fid_color.$fid[$i]} = (color =>["$fid_no1"]);
	}
		
#
#---- limit plotting range
#

#
#--- plot acent i data
#
	$i1 = 2;
	$line = 'sub_plot_cent'."$i1";
	$app_mean = ${$line}[$det_cnt];
	$bot      = $app_mean - 3.0 * $interval;
	$top      = $app_mean + 3.0 * $interval;
	
	$mean = 0; 
	$mcnt = 0;
	foreach $ent (@acenti){
		if($ent >= $bot && $ent < $top){
			$mean += $ent;
			$mcnt++;
		}
	}
	if($mcnt > 0){
		$mean = $mean/$mcnt;
	}else{
		$mean = $app_mean;
	}

	@xbin = @time;
	@ybin = @acenti;
	$total = $cnt;

	pgbegin(0, '"./Sim_twist_temp2/pgplot.ps"/cps',1,1);
	pgsch(1);
	pgslw(3);

	$ymin = $mean - 0.4 * $interval; 
	$ymax = $mean + 0.6 * $interval; 

#
#---- different tracks before dom = 1411 and after
#

	for($k = 0; $k < $cnt; $k++){
		if($time[$k] < 1411){
			push(@timei1, $time[$k]);
			push(@acenti1, $acenti[$k]);
			$icnt1++;
		}elsif($time[$k] < 2600){
			push(@timei2, $time[$k]);
			push(@acenti2, $acenti[$k]);
			$icnt2++;
		}elsif($time[$k] < 4400){
			push(@timei3, $time[$k]);
			push(@acenti3, $acenti[$k]);
			$icnt3++;
		}elsif($time[$k] > 4400){
			push(@timei4, $time[$k]);
			push(@acenti4, $acenti[$k]);
			$icnt4++;
		}
	}

	pgsvp(0.1, 0.9, 0.7, 0.98);
	pgswin($xmin, $xmax, $ymin, $ymax);
	pgbox(ABCST,0.0, 0.0, ABCNSTV, 0.0, 0.0);

	plot_fig();

	$tot = 	$icnt1;
	@xtemp = @timei1;
	@ytemp = @acenti1;
	least_fit();
	
	$ylin1 = $int + $slope * $xmin;
	$ylin2 = $int + $slope * 1411;
	pgmove($xmin,$ylin1);
	pgdraw(1411, $ylin2);
	$ymark_pos3 = $ymax - 0.2 * ($ymax - $ymin);
	$slope_yr = 365 * $slope;
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope(dom < 1411): $slope_yr");

	$tot = 	$icnt2;
	@xtemp = @timei2;
	@ytemp = @acenti2;
	least_fit();
	
	$ylin1 = $int + $slope * 1411;
	$ylin2 = $int + $slope * 2700;
	pgmove(1411,$ylin1);
	pgdraw(2700, $ylin2);
	$ymark_pos3 = $ymax - 0.3 * ($ymax - $ymin);
	$slope_yr = 365 * $slope;
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope(1411< dom <2700): $slope_yr");

	$tot = 	$icnt3;
	@xtemp = @timei3;
	@ytemp = @acenti3;
	least_fit();
	
	$ylin1 = $int + $slope * 2700;
	$ylin2 = $int + $slope * 4400;
	pgmove(2700,$ylin1);
	pgdraw(4400, $ylin2);
	$ymark_pos3 = $ymax - 0.4 * ($ymax - $ymin);
	$slope_yr = 365 * $slope;
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope(2700< dom <4400): $slope_yr");

	$tot = 	$icnt4;
	@xtemp = @timei4;
	@ytemp = @acenti4;
	least_fit();
	
	$ylin1 = $int + $slope * 4400;
	$ylin2 = $int + $slope * $xmax;
	pgmove(4400,$ylin1);
	pgdraw($xmax, $ylin2);
	$ymark_pos4 = $ymax - 0.5 * ($ymax - $ymin);
	$slope_yr = 365 * $slope;
	pgptxt($xside2, $ymark_pos4, 0.0, 0.0, "Slope(dom > 4400): $slope_yr");

	$ymark_pos4 = $ymark_pos2 - 0.1 * $ydiff;

	pgsci(4);
	pgmove(1411, $ymin);
	pgdraw(1411, $ymax);
	pgsci(1);

	pgsci(5);
	pgmove(2700, $ymin);
	pgdraw(2700, $ymax);
	pgsci(1);

	pgsci(6);
	pgmove(4400, $ymin);
	pgdraw(4400, $ymax);
	pgsci(1);

#
#---- plot acent j data
#

	$i1 = 1;
	$line = 'sub_plot_cent'."$i1";
	$app_mean = ${$line}[$det_cnt];
	$bot      = $app_mean - 3.0 * $interval;
	$top      = $app_mean + 3.0 * $interval;
	$mean = 0; 
	$mcnt = 0;
	foreach $ent (@acentj){
		if($ent >= $bot && $ent < $top){
			$mean += $ent;
			$mcnt++;
		}
	}
	if($mcnt > 0){
		$mean = $mean/$mcnt;
	}else{
		$mean = $app_mean;
		$mcnt = $cnt;
	}

	$ymin = $mean - 0.55 * $interval; 
	$ymax = $mean + 0.45 * $interval; 
#
#---- different tracks before dom = 1411 and after
#

	OUTER:
        for($k = 0; $k < $cnt; $k++){
		if($acentj[$k] < $ymin || $acentj[$k] > $ymax){
			next OUTER;
		}
                if($time[$k] < 1411){
                        push(@timej1, $time[$k]);
                        push(@acentj1, $acentj[$k]);
                        $jcnt1++;
                }elsif($time[$k] > 1411 && $time[$k] < 2600){
                        push(@timej2, $time[$k]);
                        push(@acentj2, $acentj[$k]);
                        $jcnt2++;
                }elsif($time[$k] > 2700 && $time[$k] < 4400){
                        push(@timej3, $time[$k]);
                        push(@acentj3, $acentj[$k]);
                        $jcnt3++;
                }elsif($time[$k] > 4400){
                        push(@timej4, $time[$k]);
                        push(@acentj4, $acentj[$k]);
                        $jcnt4++;
                }
        }


	pgsvp(0.1, 0.9, 0.4, 0.68);
	pgswin($xmin, $xmax, $ymin, $ymax);
	pgbox(ABCNST,0.0, 0.0, ABCNSTV, 0.0, 0.0);

	$total = $cnt;
	@xbin = @time;
	@ybin = @acentj;

	plot_fig();

        $tot =  $jcnt1;
        @xtemp = @timej1;
        @ytemp = @acentj1;
        least_fit();

	$ylin1 = $int + $slope * $xmin;
	$ylin2 = $int + $slope * 1411;
	pgmove($xmin, $ylin1);
	pgdraw(1411, $ylin2);

	$slope_yr = 365 * $slope;
	$ymark_pos3 = $ymin + 0.4 * ($ymax - $ymin);
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope (dom < 1411): $slope_yr");


        $tot =  $jcnt2;
        @xtemp = @timej2;
        @ytemp = @acentj2;
        least_fit();

	$ylin1 = $int + $slope * 1411;
	$ylin2 = $int + $slope * 2700;
	pgmove(1411, $ylin1);
	pgdraw(2700, $ylin2);

	$slope_yr = 365 * $slope;
	$ymark_pos3 = $ymin + 0.3 * ($ymax - $ymin);
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope (1411 < dom < 2700): $slope_yr");

        $tot =  $jcnt3;
        @xtemp = @timej3;
        @ytemp = @acentj3;
        least_fit();

	$ylin1 = $int + $slope * 2700;
	$ylin2 = $int + $slope * 4400;
	pgmove(2700, $ylin1);
	pgdraw(4400, $ylin2);

	$slope_yr = 365 * $slope;
	$ymark_pos3 = $ymin + 0.2 * ($ymax - $ymin);
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope (2700 < dom < 4400): $slope_yr");


        $tot =  $jcnt4;
        @xtemp = @timej4;
        @ytemp = @acentj4;
        least_fit();

	$ylin1 = $int + $slope * 4400;
	$ylin2 = $int + $slope * $xmax;
	pgmove(4400, $ylin1);
	pgdraw($xmax, $ylin2);

	$slope_yr = 365 * $slope;
	$ymark_pos3 = $ymin + 0.1 * ($ymax - $ymin);
	pgptxt($xside2, $ymark_pos3, 0.0, 0.0, "Slope (dom > 4400): $slope_yr");

	pgsci(4);
	pgmove(1411, $ymin);
	pgdraw(1411, $ymax);
	pgsci(1);

	pgsci(5);
	pgmove(2700, $ymin);
	pgdraw(2700, $ymax);
	pgsci(1);

	pgsci(6);
	pgmove(4400, $ymin);
	pgdraw(4400, $ymax);
	pgsci(1);

	pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");

	pgclos();
	
	$det_cnt++;

	$plot_name = "$detector".'.gif';
###	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp2/pgplot.ps|$op_dir/pnmcrop |$op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/$plot_name");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp2/pgplot.ps|pnmflip -r270 |ppmtogif > $web_dir/Plots/$plot_name");
	system("rm -rf ./Sim_twist_temp2/pgplot.ps");
}

system("rm -rf ./Sim_twist_temp2 ./param");


########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
	$ydiff = $ymax - $ymin;
	$ymid  = $ymin + 0.50 * $ydiff;
	$yside = $ymin + 0.50 * $ydiff;
	$ytop  = $ymax + 0.05 * $ydiff;
	$ybot  = $ymin - 0.20 * $ydiff;
	$ymark_pos2 = $ymax - 0.1 * $ydiff;

	for($n = 0; $n < 15; $n++){
		${fid_cnt.$n} = 0;
	}

	@xtemp = ();
	@ytemp = ();
	$tsc_avg = 0;
	$tsc_avg2 = 0;
	$tot  = 0;
        for($m = 0; $m < $total; $m++){
		if($ybin[$m] >= $ymin && $ybin[$m] < $ymax){ 

			$symbol = 2;
			${fid_cnt.$fid[$m]}++;

        		pgsci(${fid_color.$fid[$m]}{color}[0]);
                	pgpt(1, $xbin[$m], $ybin[$m], $symbol);

			push(@xtemp, $xbin[$m]);
			push(@ytemp, $ybin[$m]);

			$tsc_avg += $tsc[$m];
			$tsc_avg2 += $tsc[$m] * $tsc[$m];

			$tot++;
		}
        }
        pgsci(1);

	if($tot > 0){
		$tsc_avg /= $tot;
		$sig      = sqrt($tsc_avg2/$tot - $tsc_avg * $tsc_avg);
		$tsc_avg  = sprintf "%3.2f",$tsc_avg;
		$sig      = sprintf "%2.2f",$sig;
	}else{
		$tsc_avg = 'INDEF';
		$sig     = 'INDEF';
	}

	$next = 0;
        for($n = 0; $n < 15; $n++){
                if(${fid_cnt.$n} > 0){
                        $xpos = $xmin + $next * $step + 0.10 * $step;
                        $xpos2 = $xmin + $next * $step + 0.12 * $step;
                        $mark = $n + 1;
			if($i1 == 2){	
                        	$description = "ACENT I";
			}else{
                        	$description = "ACENT J";
				least_fit();
			}
                        $ymark_pos3 = $ymark_pos2 + 0.025 * $ydiff;
			pgsci(1);
                        pgtext($xpos2, $ymark_pos2, "$description");
                        $next++;
                 }
        }
}

####################################################################
### least_fit: least sq. fit routine                             ###
####################################################################

sub least_fit{
        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;

        for($fit_i = 0; $fit_i < $tot;$fit_i++) {
                $lsum++;
                $lsumx += $xtemp[$fit_i];
                $lsumy += $ytemp[$fit_i];
                $lsumx2+= $xtemp[$fit_i]*$xtemp[$fit_i];
                $lsumy2+= $ytemp[$fit_i]*$ytemp[$fit_i];
                $lsumxy+= $xtemp[$fit_i]*$ytemp[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        if($delta > 0){
                $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
                $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;
                $slope = sprintf "%2.4f",$slope;
        }else{
                $int = 999999;
                $slope = 0.0;
        }
}

