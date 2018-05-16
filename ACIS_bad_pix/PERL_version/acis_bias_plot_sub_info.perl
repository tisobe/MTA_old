#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	plot_sub_info.perl: plot bias background data of different classifications	#
#											#
#		author: t. isobe (tiosbe@cfa.harvard.edu)				#
#		last update: May 16, 2013						#
#											#
#########################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#######################################

	
for($ccd = 0; $ccd < 10; $ccd++){
	for($quad = 0; $quad < 4; $quad++){
		$y_axis = 'Bias';
		$dir = "$data_dir".'/Info_dir/CCD'."$ccd".'/quad'."$quad";
	}
}
#	
#--- overclock
#
for($ccd = 0; $ccd < 10; $ccd++){
	for($quad = 0; $quad < 4; $quad++){
		$y_axis = 'Overclock';
		if($comp_test =~ /test/i){
                	$dir2 = "$web_dir".'/Plots/Param_diff/CCD'."$ccd".'/CCD'."$ccd".'_q'."$quad";
		}else{
                	$dir2 = "$web_dir".'/Plots/Param_diff/CCD'."$ccd".'/CCD'."$ccd".'_q'."$quad";
		}
                plot_param_dep();
	}
}

#
#---- bias backgound
#
for($ccd = 0; $ccd < 10; $ccd++){
	for($quad = 0; $quad < 4; $quad++){

		$y_axis = 'Bias';
		if($comp_test =~ /test/i){
			$dir3 = "$web_dir".'/Plots/Param_diff/CCD'."$ccd".'/CCD'."$ccd".'_bias_q'."$quad";
		}else{
			$dir3 = "$web_dir".'/Plots/Param_diff/CCD'."$ccd".'/CCD'."$ccd".'_bias_q'."$quad";
		}
		plot_param_dep2();
	}
}


########################################################################################
### plot_param_dep: plotting for overclock 		                             ###
########################################################################################

sub plot_param_dep{
	$file = $dir;
	
	$dest_dir = $dir2;
	
	open(FH, "$data_dir/Info_dir/list_of_ccd_no");
	@ttime = ();
	@ccd_no = ();
	$c_nt   = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$dom = ($atemp[0] - 48902399)/86400;
		$dom = 0.01 * int (100 * $dom);
		push(@ttime, $dom);
		push(@ccd_no, $atemp[1]);
		$c_cnt++;
	}
	close(FH);
	
	@time      = ();
	@overclock = ();
	@mode      = ();
	@ord_mode  = ();
	@outrow    = ();
	@num_row   = ();
	@sum2x2    = ();
	@deagain   = ();
	@biasalg   = ();
	@biasarg0  = ();
	@biasarg1  = ();
	@biasarg2  = ();
	@biasarg3  = ();
	#@biasarg4  = ();
	$cnt       = 0;
	$sum       = 0;
	
	open(FH, "$file");
	while(<FH>){
		chomp $_;
		@atemp = split(/\t/, $_);
		$dom = ($atemp[0] - 48902399)/86400;
		$dom = 0.01 * int (100 * $dom);
		push(@time,      $dom);
		push(@overclock, $atemp[1]);
		$sum += $atemp[1];
		push(@mode,      $atemp[2]);
		push(@ord_mode,  $atemp[3]);
		push(@outrow,    $atemp[4]);
		push(@num_row,   $atemp[5]);
		push(@sum2x2,    $atemp[6]);
		push(@deagain,   $atemp[7]);
		push(@blasalg,   $atemp[8]);
		push(@biasarg0,  $atemp[9]);
		push(@biasarg1,  $atemp[10]);
		push(@biasarg2,  $atemp[11]);
		push(@biasarg3,  $atemp[12]);
	#	push(@biasarg4,  $atemp[13]);
		$cnt++;
	}
	close(FH);
	if($cnt > 0){
	
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		for($i = 0; $i < $cnt; $i++){
			if($mode[$i] eq 'FAINT'){
				push(@x1, $time[$i]);
				push(@y1, $overclock[$i]);
				$cnt1++;
			}elsif($mode[$i] eq 'VFAINT'){
				push(@x2, $time[$i]);
				push(@y2, $overclock[$i]);
				$cnt2++;
			}else{
				push(@x3, $time[$i]);
				push(@y3, $overclock[$i]);
				$cnt3++;
			}
		}
		
		$xmin = $time[0];
		$xmax = $time[$cnt-1];
		$avg = $sum/$cnt;
		$ymin = $avg - 100;
		$ymax = $avg + 100;
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Faint Mode';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Very Faint Mode';
		plot_routine();
		
		@x = @x1;
		@y = @y1;
		$title = 'Others';
		$tot = $cnt3;
		plot_routine();
		
		pgclos();

		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/obs_mode.gif");

		system("rm -rf pgplot.ps");

		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		
		for($i = 0; $i < $cnt; $i++){
			if($num_row[$i] == 1024){
				push(@x1, $time[$i]);
				push(@y1, $overclock[$i]);
				$cnt1++;
			}else{
				push(@x2, $time[$i]);
				push(@y2, $overclock[$i]);
				$cnt2++;
			}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,2);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Full Readout';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Partial Readout';
		plot_routine();
		
		pgclos();

		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/partial_readout.gif");

		system("rm -rf pgplot.ps");

		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$cnt3 = 0;
		
		for($i = 0; $i < $cnt; $i++){
        		if($biasarg1[$i] == 9){
                		push(@x1, $time[$i]);
                		push(@y1, $overclock[$i]);
                		$cnt1++;
        		}elsif($biasarg1[$i] == 10){
                		push(@x2, $time[$i]);
                		push(@y2, $overclock[$i]);
                		$cnt2++;
        		}else{
                		push(@x3, $time[$i]);
                		push(@y3, $overclock[$i]);
                		$cnt3++;
        		}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Bias Arg 1 = 9';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Bias Arg 1 = 10';
		plot_routine();
		
		@x = @x3;
		@y = @y3;
		$tot = $cnt3;
		$title = 'Bias Arg 1 = others';
		plot_routine();
	
		pgclos();

		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/bias_arg1.gif");

		system("rm -rf pgplot.ps");
	
	
		$mstep = 0;

		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$cnt3 = 0;

		OUTER:
		for($i = 0; $i < $cnt; $i++){
#			for($m = $mstep; $m < $c_cnt; $m++){
			for($m = 0; $m < $c_cnt; $m++){
				if($time[$i] == $ttime[$m]){
					if($ccd_no[$m] == 6){
						push(@x1, $time[$i]);
						push(@y1, $overclock[$i]);
						$cnt1++;
					}elsif($ccd_no[$m] == 5){
						push(@x2, $time[$i]);
						push(@y2, $overclock[$i]);
						$cnt2++;
					}else{
						push(@x3, $time[$i]);
						push(@y3, $overclock[$i]);
						$cnt3++;
					}
					$mstep = $m;
					next OUTER;
				}elsif($time[$i] < $ttime[$m]){
					next OUTER;
				}
			}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = '# of CCDs = 6';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = '# of CCDs = 5';
		plot_routine();
	
		@x = @x3;
		@y = @y3;
		$tot = $cnt3;
		$title = '# of CCDs: others';
		plot_routine();
		
		pgclos();
							
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/no_ccds.gif");

		system("rm -rf pgplots.ps");
	}
}



######################################################################################
### plot_param_dep2: plotting for bias background                                  ###
######################################################################################

sub plot_param_dep2{

        $file = $dir;

        $dest_dir = $dir3;

	@btemp = split(/CCD/,$file);
	$in_file = 'CCD'."$btemp[1]";
	
	
	open(FH, "$data_dir/Info_dir/list_of_ccd_no");
	@ttime = ();
	@ccd_no = ();
	$ttcnt  = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
                $dom = ($atemp[0] - 48902399)/86400;
		$dom = 0.01 * int (100 * $dom);
                push(@ttime, $dom);
		push(@ccd_no, $atemp[1]);
		$ttcnt++;
	}
	close(FH);
	
	@time      = ();
	@overclock = ();
	@mode      = ();
	@ord_mode  = ();
	@outrow    = ();
	@num_row   = ();
	@sum2x2    = ();
	@deagain   = ();
	@biasalg   = ();
	@biasarg0  = ();
	@biasarg1  = ();
	@biasarg2  = ();
	@biasarg3  = ();
	#@biasarg4  = ();
	$cnt       = 0;
	$sum       = 0;
	
	open(FH, "$file");
	while(<FH>){
		chomp $_;
		@atemp = split(/\t/, $_);
		$dom = ($atemp[0] - 48902399)/86400;
		$dom = 0.01 * int (100 * $dom);
		push(@time,      $dom);
		push(@overclock, $atemp[1]);
		$sum += $atemp[1];
		push(@mode,      $atemp[2]);
		push(@ord_mode,  $atemp[3]);
		push(@outrow,    $atemp[4]);
		push(@num_row,   $atemp[5]);
		push(@sum2x2,    $atemp[6]);
		push(@deagain,   $atemp[7]);
		push(@blasalg,   $atemp[8]);
		push(@biasarg0,  $atemp[9]);
		push(@biasarg1,  $atemp[10]);
		push(@biasarg2,  $atemp[11]);
		push(@biasarg3,  $atemp[12]);
	#	push(@biasarg4,  $atemp[13]);
		$cnt++;
	}
	close(FH);
	
	open(FH, "$data_dir/Bias_save/$in_file");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		$diff = $atemp[1] - $atemp[3];
		if(abs($diff) > 10){
			$diff = 0;
		}
		push(@bias, $diff);
	}
	close(FH);
	
	@x1 = ();
	@y1 = ();
	@x2 = ();
	@y2 = ();
	@x3 = ();
	@y3 = ();
	$cnt1 = 0;
	$cnt2 = 0;
	$cnt3 = 0;

	if($cnt == 0){
		system("cp $house_keeping/no_data.gif  $dest_dir/obs_mode.gif");
		system("cp $house_keeping/no_data.gif  $dest_dir/partial_readout.gif");
		system("cp $house_keeping/no_data.gif  $dest_dir/bias_arg1.gif");
		system("cp $house_keeping/no_data.gif  $dest_dir/no_ccds.gif");

	}else{
		for($i = 0; $i < $cnt; $i++){
			if($mode[$i] eq 'FAINT'){
				push(@x1, $time[$i]);
				push(@y1, $bias[$i]);
				$cnt1++;
			}elsif($mode[$i] eq 'VFAINT'){
				push(@x2, $time[$i]);
				push(@y2, $bias[$i]);
				$cnt2++;
			}else{
				push(@x3, $time[$i]);
				push(@y3, $bias[$i]);
				$cnt3++;
			}
		}
		
		$xmin = $time[0];
		$xmax = $time[$cnt-1];
		$avg = $sum/$cnt;
		$ymin =  -0.5;
		$ymax =   1.5;
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Faint Mode';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Very Faint Mode';
		plot_routine();
		
		@x = @x1;
		@y = @y1;
		$title = 'Others';
		$tot = $cnt3;
		plot_routine();
		
		pgclos();
	
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/obs_mode.gif");

		system("rm -rf pgplot.ps");
	
	
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$cnt3 = 0;
	
		for($i = 0; $i < $cnt; $i++){
			if($num_row[$i] == 1024){
				push(@x1, $time[$i]);
				push(@y1, $bias[$i]);
				$cnt1++;
			}else{
				push(@x2, $time[$i]);
				push(@y2, $bias[$i]);
				$cnt2++;
			}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,2);
		pgsch(2);
		pgslw(2);
	
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Full Readout';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Partial Readout';
		plot_routine();
		
		pgclos();
	
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/partial_readout.gif");

		system("rm -rf pgplot.ps");
	
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$cnt3 = 0;
		
		for($i = 0; $i < $cnt; $i++){
        		if($biasarg1[$i] == 9){
                		push(@x1, $time[$i]);
                		push(@y1, $bias[$i]);
                		$cnt1++;
        		}elsif($biasarg1[$i] == 10){
                		push(@x2, $time[$i]);
                		push(@y2, $bias[$i]);
                		$cnt2++;
        		}else{
                		push(@x3, $time[$i]);
                		push(@y3, $bias[$i]);
                		$cnt3++;
        		}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
		
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = 'Bias Arg 1 = 9';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = 'Bias Arg 1 = 10';
		plot_routine();
		
		@x = @x3;
		@y = @y3;
		$tot = $cnt3;
		$title = 'Bias Arg 1 = others';
		plot_routine();
		
		pgclos();
	
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/bias_arg1.gif");
	
		system("rm -rf pgplot.ps");
		
		
		$mstep = 0;
		
		@x1 = ();
		@y1 = ();
		@x2 = ();
		@y2 = ();
		@x3 = ();
		@y3 = ();
		$cnt1 = 0;
		$cnt2 = 0;
		$cnt3 = 0;
		OUTER:
		for($i = 0; $i < $cnt; $i++){
			for($m = $mstep; $m < $ttcnt; $m++){
				if($time[$i] == $ttime[$m]){
					if($ccd_no[$m] == 6){
						push(@x1, $time[$i]);
						push(@y1, $bias[$i]);
						$cnt1++;
					}elsif($ccd_no[$m] == 5){
						push(@x2, $time[$i]);
						push(@y2, $bias[$i]);
						$cnt2++;
					}else{
						push(@x3, $time[$i]);
						push(@y3, $bias[$i]);
						$cnt3++;
					}
					$mstep = $m;
					next OUTER;
				}
			}
		}
		
		pgbegin(0, "/ps",1,1);
		pgsubp(1,3);
		pgsch(2);
		pgslw(2);
	
		@x = @x1;
		@y = @y1;
		$tot = $cnt1;
		$title = '# of CCDs = 6';
		plot_routine();
		
		@x = @x2;
		@y = @y2;
		$tot = $cnt2;
		$title = '# of CCDs = 5';
		plot_routine();
		
		@x = @x3;
		@y = @y3;
		$tot = $cnt3;
		$title = '# of CCDs: others';
		plot_routine();
		
		pgclos();
							
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $dest_dir/no_ccds.gif");

		system("rm -rf pgplot.ps");
	}
}

####################################################################
### plot_routine: plotting figs                                  ###
####################################################################

sub plot_routine{
#	least_fit();
	@xdata = @x;
	@ydata = @y;
	$data_cnt = $tot;
	if($tot > 0){
		@temp = sort{$a<=>$b} @x;
		$txmin = $temp[0];
		$txmax = $temp[$tot-1];
		$txdiff = $txmax - $txmin;
		if($txdiff > 0){
			robust_fit();
			$slope = sprintf "%2.4f",$slope;
		}
	}else{
		$slope = 'N/A';
	}

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	pgslw(3);
	for($m = 0; $m < $tot; $m++){
		pgpt(1,$x[$m], $y[$m], -1);
	}
	$ys = $int + $slope*$xmin;
	$ye = $int + $slope*$xmax;
	pgmove($xmin, $ys);
	pgdraw($xmax, $ye);
	pgslw(2);
	$xw = $x[0]+ 30;
	$yw = $ymax -0.3;
	pgptxt($xw, $yw, 0, 0, "Slope: $slope");
	pglabel("Time (DOM)", "$y_axis", "$title");
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

        for($fit_i = 0; $fit_i < $tot; $fit_i++) {
		if($y[$fit_i] !~ /\d/){
			next;
		}
                $lsum++;
                $lsumx += $x[$fit_i];
                $lsumy += $y[$fit_i];
                $lsumx2+= $x[$fit_i]*$x[$fit_i];
                $lsumy2+= $y[$fit_i]*$y[$fit_i];
                $lsumxy+= $x[$fit_i]*$y[$fit_i];
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

