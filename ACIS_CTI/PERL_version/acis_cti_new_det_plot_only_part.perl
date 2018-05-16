#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################
#									#
# new_det_plot_only_part.perl: plot an example plot for display		#
#		   (Detreded CCD3 Node 0, no restriction, <-119.7 	#
#		    and Int time > 7000 sec, and temp adjucted plot)	#
#									#
#	author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	last update: Apr 15, 2013					#
#									#
#########################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;


#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#########################################

ccd_plot(mn);

#####################################################################################
###  ccd_plot: plotting cti for each node of all ccds with specified inteval ##
#####################################################################################

sub ccd_plot{
	($elm,$start,$end) = @_;		# there are three possible input
	if($start =~ /\d/) {
		$range = "$elm"."_$start"."_range";
	}elsif($end =~ /\d/) {
		$range = "$elm"."_$end"."_range";
	}else{
		$range = "$elm"."_range";
	}
	
	open(FH,"$house_keeping/Range_data/$range");
	$cno = 0;
	OUTER:
	while(<FH>) {
		chomp $_;
		@atemp = split(/ /,$_);
		if($atemp[0] eq 'NONE') {
			$auto = 1;
			last OUTER;
		} else {
			$auto = 0;
			${range.$cno} = $atemp[1];
#			${min.$cno} = $atemp[1];
#			${max.$cno} = $atemp[3];
			$cno++;
		}
	}

	for($i = 3; $i < 4 ; $i++) {			# al, ti, and mn
		foreach $input_in( 'Det_Data2000', 'Det_Data7000', 'Det_Data_adjust'){

			$input_dir = "$data_dir"."$input_in";

			$count = 0;
			@time_list = ();
			if($elm eq 'al') {
				$ofile = "al_ccd$i";
			}elsif($elm eq 'ti'){
				$ofile = "ti_ccd$i";
			}elsif($elm eq 'mn') {
				$ofile = "mn_ccd$i";
			}
	
			open(FH, "$input_dir/$ofile");
			$sum0  = 0;
			$sum1  = 0;
			$sum2  = 0;
			$sum3  = 0;
			$tsum0  = 0;
			$tsum1  = 0;
			$tsum2  = 0;
			$tsum3  = 0;
			$count = 0;
			while(<FH>) {
				chomp $_;
				@atemp = split(/\t/, $_);
				@btemp = split(/\+\-/,$atemp[1]);
				$sum0 += $btemp[0];
				$tsum0 += $btemp[0]*$btemp[0];
				@ctemp = split(/\+\-/,$atemp[2]);
				$sum1 += $ctemp[0];
				$tsum1 += $ctemp[0]*$ctemp[0];
				@dtemp = split(/\+\-/,$atemp[3]);
				$sum2 += $dtemp[0];
				$tsum2 += $dtemp[0]*$dtemp[0];
				@etemp = split(/\+\-/,$atemp[4]);
				$sum3 += $etemp[0];
				$tsum3 += $etemp[0]*$etemp[0];
				$count++;
			}
			close(FH);
	
			if($count > 0){
				$avg0 = $sum0/$count;
				$sig0 = sqrt($tsum0/$count - $avg0*$avg0);
				$low0 = $avg0 - 4 * $sig0;
				$hig0 = $avg0 + 4 * $sig0;
				$avg1 = $sum1/$count;
				$sig1 = sqrt($tsum1/$count - $avg1*$avg1);
				$low1 = $avg1 - 4 * $sig1;
				$hig1 = $avg1 + 4 * $sig1;
				$avg2 = $sum2/$count;
				$sig2 = sqrt($tsum2/$count - $avg2*$avg2);
				$low2 = $avg2 - 4 * $sig2;
				$hig2 = $avg2 + 4 * $sig2;
				$avg3 = $sum3/$count;
				$sig3 = sqrt($tsum3/$count - $avg3*$avg3);
				$low3 = $avg3 - 4 * $sig3;
				$hig3 = $avg3 + 4 * $sig3;
		
		
				open(FH, "$input_dir/$ofile");
				@time_list = ();
				$count = 0;
				OUTER:
				while(<FH>) {
					@atemp = split(/\t/, $_);
					$date = $atemp[0];
					@btemp = split(/\+\-/,$atemp[1]);
					if($btemp[0] < $low0 || $btemp[0] > $hig0){
						next OUTER;
					}
					${node0.$date} = $btemp[0];
					${err0.$date}  = $btemp[1];
					@ctemp = split(/\+\-/,$atemp[2]);
					if($ctemp[0] < $low1 || $ctemp[0] > $hig1){
						next OUTER;
					}
					${node1.$date} = $ctemp[0];
					${err1.$date}  = $ctemp[1];
					@dtemp = split(/\+\-/,$atemp[3]);
					if($dtemp[0] < $low2 || $dtemp[0] > $hig2){
						next OUTER;
					}
					${node2.$date} = $dtemp[0];
					${err2.$date}  = $dtemp[1];
					@etemp = split(/\+\-/,$atemp[4]);
					if($etemp[0] < $low3 || $etemp[0] > $hig3){
						next OUTER;
					}
					${node3.$date} = $etemp[0];
					${err3.$date}  = $etemp[1];
					push(@time_list, $date);
					$count++;
				}
				close(FH);
				@new_time_list = @time_list;
				
				@node0 = ();
				@node1 = ();
				@node2 = ();
				@node3 = ();
				@err0  = ();
				@err1  = ();
				@err2  = ();
				@err3  = ();
			
				foreach $time (@new_time_list) {
					push (@node0, ${node0.$time});
					push (@node1, ${node1.$time});
					push (@node2, ${node2.$time});
					push (@node3, ${node3.$time});
					push (@err0,  ${err0.$time});
					push (@err1,  ${err1.$time});
					push (@err2,  ${err2.$time});
					push (@err3,  ${err3.$time});
				}
		
				ch_time_form();				# changing time format
			}


			$comp = 'Det_Data2000';
			if($input_dir eq "$data_dir$comp"){
					@time_2000  = @xbin;
					@node0_2000 = @node0;
					@node1_2000 = @node1;
					@node2_2000 = @node2;
					@node3_2000 = @node3;
					@err0_2000  = @err0;
					@err1_2000  = @err1;
					@err2_2000  = @err2;
					@err3_2000  = @err3;
					$count_2000 = $count;
			}

			$comp = 'Det_Data7000';
			if($input_dir eq "$data_dir$comp"){
					@time_7000  = @xbin;
					@node0_7000 = @node0;
					@node1_7000 = @node1;
					@node2_7000 = @node2;
					@node3_7000 = @node3;
					@err0_7000  = @err0;
					@err1_7000  = @err1;
					@err2_7000  = @err2;
					@err3_7000  = @err3;
					$count_7000 = $count;
			}

			$comp = 'Det_Data_adjust';
			if($input_dir eq "$data_dir$comp"){
					@time_adjust  = @xbin;
					@node0_adjust = @node0;
					@node1_adjust = @node1;
					@node2_adjust = @node2;
					@node3_adjust = @node3;
					@err0_adjust  = @err0;
					@err1_adjust  = @err1;
					@err2_adjust  = @err2;
					@err3_adjust  = @err3;
					$count_adjust = $count;
			}
		}
					

##### pgplot routine starts from here.


		$xmin = $time_2000[0];
		$xmax = $time_2000[$count_2000 - 1];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
		$xmax += 0.05 * $diff;

		$xdiff  = $xmax - $xmin;
		$xmid   = $xmin + 0.50 * $xdiff;
		$xmin2  = $xmin + 0.05 * $xdiff;
		$xside  = $xmin - 0.08 * $xdiff;
		$xpos1  = $xmin + 0.05 * $xdiff;
		$xpos2  = $xmin + 0.25 * $xdiff;
		$xpos3  = $xmin + 0.60 * $xdiff;
		$xpos4  = $xmin + 0.25 * $xdiff;
		$xpos5  = $xmin + 0.50 * $xdiff;

		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(5);

#
#
		$sum = 0;
		foreach $ent (@node0_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.30;
		$ymax = $avg + 0.30;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax - 0.25 * $ydiff;
		$ybot   = $ymin - 0.20 * $ydiff;

       		pgsvp(0.15, 1.00, 0.70, 1.00);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node0_2000;
		@yerr  = @yerr0_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgptxt($xpos1, $ytop, 0.0, 0.0, "No correction , Int Time > 2000 sec");

		$org_line = $slope;
		digit_adjust();
		pgptxt($xpos1, $ytop2, 0.0, 0.0, "Slope: $ad_slope");

		pgsci(1);
       		pgsvp(0.15, 1.00, 0.40, 0.70);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node0_7000;
		@yerr  = @yerr0_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgptxt($xpos1, $ytop, 0.0, 0.0, "Focal Temp < -119.6 C & Int Time >7000 sec");

		$org_line = $slope;
		digit_adjust();
		pgptxt($xpos1, $ytop2, 0.0, 0.0, "Slope: $ad_slope");

		pgsci(1);
       		pgptxt($xside, $ymin, 90.0, 0.0, "(S/I)x10**4");

       		pgsvp(0.15, 1.00, 0.10, 0.40);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node0_adjust;
		@yerr  = @yerr0_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgptxt($xpos1, $ytop, 0.0, 0.0, "Temp Factor Corrected & Int Time >2000 sec");

		$org_line = $slope;
		digit_adjust();

		pgptxt($xpos1, $ytop2, 0.0, 0.0, "Slope: $ad_slope");

		pgsci(1);
		pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");

		pgclos();
		
		$name = "$cti_www".'/Det_Plot/example_ccd3_node0_mn.gif';
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $name");
		system("rm -rf pgplot.ps");
	}
}


########################################################
###    plot_fig: plot figure from a give data      #####
########################################################

sub plot_fig {

	pgpt(1, $xbin[0], $ybin[0], -1);		# plot a point (x, y)
	for($m = 1; $m < $count-1; $m++) {
		unless($ybin[$m] eq '*****' || $ybin[$m] eq ''){
			pgpt(1,$xbin[$m], $ybin[$m], 3);
		}
		unless($yerr[$m] eq '*****' || $yerr[$m] eq ''){
			$yb = $ybin[$m] - $yerr[$m];
			$yt = $ybin[$m] + $yerr[$m];
			pgpt(1,$xbin[$m], $yb,-2);
			pgdraw($xbin[$m],$yt);
		}
	}

	pgslw(5); 
	pgpt(1, $xmin,$ybeg,-1);
	pgdraw($xmax,$yend);
	$second_line = 0;
	$fit = 0;
	pgslw(5); 

}

########################################################
###  ch_time_form: changing time format           ######
########################################################

sub ch_time_form {
	@xbin = ();
	OUTER:
	foreach $time (@new_time_list) {
		unless($time =~ /\w/) {
			next OUTER;
		}
		@atemp = split(/T/,$time);
		@btemp = split(/-/,$atemp[0]);

		$year = $btemp[0];
		$month = $btemp[1];
		$day  = $btemp[2];
		conv_date();

		@ctemp = split(/:/,$atemp[1]);
		$hr = $ctemp[0]/24.0;
		$min = $ctemp[1]/1440.0;
		$sec = $ctemp[2]/86400.0;
		$hms = $hr+$min+$sec;
		$acc_date = $acc_date + $hms;
		push(@xbin, $acc_date);
	}
}

########################################################
###   x_min_max: find min and max of y values      #####
########################################################

sub x_min_max {
	
	@xtrim = ();
	$subt = 0;
	foreach $xent (@xbin) {

		if($xent =~ /\d/) {
			push(@xtrim, $xent);
		} else {
			$subt++;
		}
	}
	@xtemp = sort { $a<=> $b }  @xtrim;
	$xmin = $xtemp[0];

	if($xmin < 0.0) {
		$xmin = $xmin*1.02;
	} else {
		$xmin = $xmin*0.98;
	}

	$xmax = @xtemp[$count -1 -$subt];
	if($xmax < 0.0) {
		$xmax = $xmax*0.99;
	}else{
		$xmax = $xmax*1.02;
	}
}


########################################################
###   y_min_max: find min and max of y values      #####
########################################################

sub y_min_max {
	@ytrim = ();
	$subt = 0;
	foreach $yent (@ybin) {
		if($yent =~ /\d/) {
			push(@ytrim, $yent);
		} else {
			$subt++;
		}
	}
	@ytemp = sort { $a <=> $b }  @ytrim;
	$ymin = @ytemp[0];
	if($ymin < 0.0) {
		$ymin = $ymin*1.02;
	} else {
		$ymin = $ymin*0.98;
	}

	$ymax = @ytemp[$count -1 - $subt];
	if($ymax < 0.0) {
		$ymax = $ymax*0.99;
	}else{
		$ymax = $ymax*1.02;
	}
}

###########################################################################
###      conv_date: modify data/time format                           #####
###########################################################################

sub conv_date {

        $acc_date = ($year - 1999)*365;
        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }elsif($year > 2020) {
                $acc_date += 6;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
		$chk = 4.0 * int(0.25 * $year);
                if($year == $chk){
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
	$acc_date = $acc_date - 202;
}

##################################
### least_fit: least fitting  ####
##################################

sub least_fit {
        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;

        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                $lsum++;
                $lsumx += $date[$fit_i];
                $lsumy += $dep[$fit_i];
                $lsumx2+= $date[$fit_i]*$date[$fit_i];
                $lsumy2+= $dep[$fit_i]*$dep[$fit_i];
                $lsumxy+= $date[$fit_i]*$dep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

	$sum = 0;
	@diff_list = ();
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		$diff = $dep[$fit_i] - ($int + $slope*$date[$fit_i]);
		push(@diff_list,$diff);
		$sum += $diff;
	}
	$avg = $sum/$total;

	$diff2 = 0;
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		$diff = $diff_list[$fit_i] - avg;
		$diff2 += $diff*$diff;
	}
	$sig = sqrt($diff2/($total - 1));

	$sig3 = 3.0*$sig;

	@ldate = ();
	@ldep  = ();
	$cnt = 0;
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		if(abs($diff_list[$fit_i]) < $sig3) {
			push(@ldate,$date[$fit_i]);
			push(@ldep,$dep[$fit_i]);
			$cnt++;
		}
	}

        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;
	for($fit_i = 0; $fit_i < $cnt; $fit_i++) {
                $lsum++;
                $lsumx += $ldate[$fit_i];
                $lsumy += $ldep[$fit_i];
                $lsumx2+= $ldate[$fit_i]*$ldate[$fit_i];
                $lsumy2+= $ldep[$fit_i]*$ldep[$fit_i];
                $lsumxy+= $ldate[$fit_i]*$ldep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

	$tot1 = $total - 1;
	$variance = ($lsumy2 + $int*$int*$lsum + $slope*$slope*$lsumx2 
			-2.0 *($int*$lsumy + $slope*$lsumxy - $int*$slope*$lsumx))/$tot1;
	$sigm_slope = sqrt($variance*$lsum/$delta);
}

####################################################################
### digit_adjust: adjust digit position     ########################
####################################################################

sub digit_adjust {
        @atemp = split(//,$org_line);
	unless($atemp[0] eq ''){
        	$e_yes = 0;
        	foreach $ent (@atemp) {
                	if($ent eq 'e' || $ent eq 'E') {
                        	$e_yes = 1;
                	}
        	}
       	 
        	if($e_yes == 0) {
                	$exp = 0;
                	$ad_slope = $org_line;
			unless($ad_slope == 0) {
                		if(abs($ad_slope) < 1.0){
					OUTER:
                        		while(abs($ad_slope) < 1.0) {
                                		$exp++; 
                                		$ad_slope = 10.0 * $ad_slope;
						if($exp > 10){
							print "something wrong at digit adjust\n";
				         		exit 1;
						}
                        		}
                		}
                		@bt = split(//,$ad_slope);
                		$ad_slope = "$bt[0]"."$bt[1]"."$bt[2]"."$bt[3]"."$bt[4]";
				if($bt[0] eq '-'){
					$ad_slope = "$ad_slope"."$bt[5]";
				}
				$exp += 4;
                		$ad_slope = "$ad_slope".'e'.'-'."$exp";

			}
        	}else{
                	@at = split(//,$org_line);
                	$e_chk = 0;
                	@save = ();
                	@exp =();
                	foreach $ent (@at) {
                        	if($ent eq 'e' || $ent eq 'E') {
                                	$e_chk = 1;
                        	}elsif($e_chk == 0){
                                	push(@save,$ent);
                                	$s_cnt++
                        	}elsif($e_chk == 1){
                                	push(@exp,$ent);
                        	}
                	}
	
                	$ad_slope = "$save[0]"."$save[1]"."$save[2]";
                	$ad_slope = "$ad_slope"."$save[3]"."$save[4]";
                	if($save[0] eq '-') {
                        	$ad_slope = "$ad_slope"."$save[5]";
                	}
                	$ad_slope = "$ad_slope"."e";
                	foreach $add (@exp) {
                        	unless($add eq '0'){
				if($add =~ /\d/){
					$add += 4;
				}
                                	$ad_slope = "$ad_slope"."$add";
				}
			}

        	}
	}
}
