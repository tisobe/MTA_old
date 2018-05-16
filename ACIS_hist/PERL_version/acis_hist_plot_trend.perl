#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	plot_trend.perl: plot trends of al K alpha, mn K alpha, ti K alpha, line 	#
#			 position, line width, and count rate				#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#	last update:  Jul 26, 2012	 						#
#		modified to fit a new directry system					#
#		cvs compatible								#
#											#
#########################################################################################

#############################################################################
#
#---- set directories
$dir_list = '/data/mta/Script/ACIS/Acis_hist_linux/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#############################################################################


#
#---- set a constant second per a histgram frame
#

$sec_per_frame = 3.2412;

system("mkdir ./Temp_dir");

$chk = `ls ./`;
if($chk =~ /param/){
        system("rm -rf param");
}
system("mkdir ./param");

#
#--- checking whether the data exist or not
#

open(WARN, ">$data_dir/Data/warn_no_data_trend");

OUTER:
for($ccd = 0; $ccd < 10; $ccd++){
	$name = "ccd$ccd".'_line_fitting_data';
	open(COUT,"> $web_dir/Results/$name");
	OUTER1:
	foreach $loc ('low', 'high'){

		$no_data = 0;

		OUTER2:
		for($node = 0; $node < 4; $node++){
			$input_file  = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_'."$loc";

			@{xtime.$node}    = ();
			@{frame.$node}    = ();
			@{peak_mn.$node}  = ();
			@{peak_al.$node}  = ();
			@{peak_ti.$node}  = ();
			@{width_mn.$node} = ();
			@{width_al.$node} = ();
			@{width_ti.$node} = ();
			@{count_mn.$node} = ();
			@{count_al.$node} = ();
			@{count_ti.$node} = ();
			$total            = 0;
			$psum_mn          = 0;
			$psum_al          = 0;
			$psum_ti          = 0;
			$wsum_mn          = 0;
			$wsum_al          = 0;
			$wsum_ti          = 0;
			$csum_mn          = 0;
			$csum_al          = 0;
			$csum_ti          = 0;

			system("ls $input_file> zcheck");
			open(IN, 'zcheck');
			$zchk = 0;
			while(<IN>){
				chomp $_;
				if($_ eq ''){
					$no_data++;
					print WARN "$ccd:$loc:$node\n";
					next OUTER2;
				}
				$zchk = 1;
			}
			if($zchk == 0){
				$no_data++;
				print WARN "$ccd:$loc:$node\n";
				next OUTER2;
			}
			close(IN);
			system("rm zcheck");

			open(FH, "$input_file");
			while(<FH>){
				chomp $_;
			 	@atemp = split(/\s+/, $_);
#
#--- change time to DOM
#
			 	$dom = ($atemp[0] - 48902399.0)/86400;
			 	push(@{xtime.$node},   $dom);
			 	push(@{frame.$node},  $atemp[2]);

			 	push(@{peak_mn.$node},  $atemp[7]);
			 	$psum_mn += $atemp[7];

			 	push(@{peak_al.$node},  $atemp[10]);
			 	$psum_al += $atemp[10];

			 	push(@{peak_ti.$node},  $atemp[13]);
			 	$psum_ti += $atemp[13];

			 	push(@{width_mn.$node}, $atemp[8]);
			 	$wsum_mn += $atemp[8];

			 	push(@{width_al.$node}, $atemp[11]);
			 	$wsum_al += $atemp[11];

			 	push(@{width_ti.$node}, $atemp[14]);
			 	$wsum_ti += $atemp[14];

			 	$cnt1 = $atemp[9] /$atemp[2]/$sec_per_frame;
			 	push(@{count_mn.$node}, $cnt1);
			 	$csum_mn += $cnt1;

			 	$cnt2 = $atemp[12]/$atemp[2]/$sec_per_frame;
			 	push(@{count_al.$node}, $cnt2);
			 	$csum_al += $cnt2;

			 	$cnt3 = $atemp[15]/$atemp[2]/$sec_per_frame;
			 	push(@{count_ti.$node}, $cnt3);
			 	$csum_ti += $cnt3;

			 	$total++;
		 	}
			close(FH);
#
#--- find averages so that we can set plotting ranges
#
			@temp = sort{$a<=>$b} @{xtime.$node};
			$xmin = $temp[1];
			$xmax = $temp[$total - 1];
			$diff = $xmax - $xmin;
			${xmin.$node} = $xmin - 0.05 * $diff;
			${xmax.$node} = $xmax + 0.05 * $diff;

			${pavg_mn.$node} = $psum_mn/$total;
			${pavg_al.$node} = $psum_al/$total;
			${pavg_ti.$node} = $psum_ti/$total;

			${wavg_mn.$node} = $wsum_mn/$total;
			${wavg_al.$node} = $wsum_al/$total;
			${wavg_ti.$node} = $wsum_ti/$total;

			${cavg_mn.$node} = $csum_mn/$total;
			${cavg_al.$node} = $csum_al/$total;
			${cavg_ti.$node} = $csum_ti/$total;

			${total.$node} = $total;
		}
#
#--- check whether there are any data, if not skip the next section, and back to the top;
#
		if($no_data > 0){
			next OUTER1;
		}
#
#---- plotting peaks
#

		$out_plot1 = "$web_dir".'/Results/CCD'."$ccd".'/'."$loc".'_peak.gif';
		if($loc eq 'high'){
			$line = '801 - 1001';
		}
		if($loc eq 'low') {
			$line = '21 - 401';
		}
		$title  = "Line Center Position: CCD $ccd Rows: $line";
		$ytitle = 'ADU';
		print COUT "\n#\n";
		print COUT "#Line Center Position Fitting y = int + slope * Time\n";
		print COUT "#ccd\tnode\trows\t\telement\tintercect\tslope\n";
		print COUT '#---------------------------------------------------------------------',"\n";
		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(2);
		foreach $elm ('mn', 'al','ti'){
			$asum = 0;
			for($node = 0; $node < 4; $node++){
				$xmin = ${xmin.$node};
				$xmax = ${xmax.$node};
				$name1 = "$elm".'_xdata_n'."$node";
				$name2 = "$elm".'_ydata_n'."$node";
				$name3 = "$elm".'_total_n'."$node";
				$name4 = "$elm".'_yest_n'."$node";
				@{$name1} = @{xtime.$node};
				if($elm eq 'mn'){
					@{$name2} = @{peak_mn.$node};
					$asum += ${pavg_mn.$node};
				}elsif($elm eq 'al'){
					@{$name2} = @{peak_al.$node};
					$asum += ${pavg_al.$node};
				}elsif($elm eq 'ti'){
					@{$name2} = @{peak_ti.$node};
					$asum += ${pavg_ti.$node};
				}
				${$name3} = ${total.$node};
				@date = @{xtime.$node};
				@dep  = @{$name2};
				$l_total = ${$name3};
#
#---- linear fit
#
				least_fit();

				if($loc eq 'high'){
					$l_line = '801 - 1001';
				}
				if($loc eq 'low'){
					$l_line = ' 21 - 1001';
				}
				print  COUT "$ccd\t$node\t$l_line\t$elm\t";
				printf COUT "%5.4f\t%5.4f\n",$int,$slope;

				for($n = 0; $n < $l_total; $n++){
					${$name4}[$n] = $int + $slope * ${xtime.$node}[$n];
				}
			}
			$mid = $asum/4.0;
			$ymin = $mid - 60;
			$ymax = $mid + 70;
			plot_three_panels();
		}

		pgclos();
		system("mv pgplot.ps peak.ps");

#
#---- plotting widths 
#

		$out_plot2 = "$web_dir".'/Results/CCD'."$ccd".'/'."$loc".'_width.gif';
		if($loc eq 'high'){
			$line = '801 - 1001';
		}
		if($loc eq 'low') {
			$line = '21 - 401';
		}
		$title  = "FWHM: CCD $ccd Rows: $line";
		$ytitle = 'ADU';
		print COUT "\n#\n";
		print COUT "#FWHM Fitting y = int + slope * Time\n";
		print COUT "#ccd\tnode\trows\t\telement\tintercect\tslope\n";
		print COUT '#---------------------------------------------------------------------',"\n";
		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(2);
		foreach $elm ('mn', 'al','ti'){
			$asum = 0;
			for($node = 0; $node < 4; $node++){
				$xmin = ${xmin.$node};
				$xmax = ${xmax.$node};
				$name1 = "$elm".'_xdata_n'."$node";
				$name2 = "$elm".'_ydata_n'."$node";
				$name3 = "$elm".'_total_n'."$node";
				$name4 = "$elm".'_yest_n'."$node";
				@{$name1} = @{xtime.$node};
				if($elm eq 'mn'){
					@{$name2} = @{width_mn.$node};
					$asum += ${wavg_mn.$node};
				}elsif($elm eq 'al'){
					@{$name2} = @{width_al.$node};
					$asum += ${wavg_al.$node};
				}elsif($elm eq 'ti'){
					@{$name2} = @{width_ti.$node};
					$asum += ${wavg_ti.$node};
				}
				${$name3} = ${total.$node};
				@date = @{xtime.$node};
				@dep  = @{$name2};
				$l_total = ${$name3};
#
#--- linear fit
#
				least_fit();

				if($loc eq 'high'){
					$l_line = '801 - 1001';
				}
				if($loc eq 'low'){
					$l_line = ' 21 - 1001';
				}
				print  COUT "$ccd\t$node\t$l_line\t$elm\t";
				printf COUT "%5.4f\t\t%5.4f\n",$int,$slope;

				for($n = 0; $n < $l_total; $n++){
					${$name4}[$n] = $int + $slope * ${xtime.$node}[$n];
				}
			}
			$mid = $asum/4.0;
			$ymin = $mid - 50;
			$ymax = $mid + 50;
			if($ymin < 0){
				$ymin = 0;
				$ymax = 120;
			}
			plot_three_panels();
		}

		pgclos();
		system("mv pgplot.ps width.ps");

#
#---- plotting count rates
#

		$out_plot3 = "$web_dir".'/Results/CCD'."$ccd".'/'."$loc".'_count.gif';
		if($loc eq 'high'){
			$line = '801 - 1001';
		}
		if($loc eq 'low') {
			$line = '21 - 401';
		}
		$title  = "Peak Count Rates: CCD $ccd Rows: $line";
		$ytitle = 'Counts/Sec';
		print COUT "\n#\n";
		print COUT "#Peak Count Rate Fitting y = const1 * exp( -1 * const2 * Time)\n";
		print COUT "#ccd\tnode\trows\t\telement\tconst1\tcont2\n";
		print COUT '#---------------------------------------------------------------------',"\n";
		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(2);
		foreach $elm ('mn', 'al','ti'){
			$asum = 0;
			for($node = 0; $node < 4; $node++){
				$xmin = ${xmin.$node};
				$xmax = ${xmax.$node};
				$name1 = "$elm".'_xdata_n'."$node";
				$name2 = "$elm".'_ydata_n'."$node";
				$name3 = "$elm".'_total_n'."$node";
				$name4 = "$elm".'_yest_n'."$node";
				@{$name1} = @{xtime.$node};
				if($elm eq 'mn'){
					@{$name2} = @{count_mn.$node};
					$asum += ${cavg_mn.$node};
				}elsif($elm eq 'al'){
					@{$name2} = @{count_al.$node};
					$asum += ${cavg_al.$node};
				}elsif($elm eq 'ti'){
					@{$name2} = @{count_ti.$node};
					$asum += ${cavg_ti.$node};
				}
				${$name3} = ${total.$node};
				@date = @{xtime.$node};
				@dep  = @{$name2};
				$l_total = ${$name3};
#
#---- linealize exp. data and fit liearn line
#					
				change_to_log_and_fit();

				for($n = 0; $n < $l_total; $n++){
					${$name4}[$n] =  $const1* exp( -1.0 * $const2 * ${xtime.$node}[$n]);
				}

				if($loc eq 'high'){
					$l_line = '801 - 1001';
				}
				if($loc eq 'low'){
					$l_line = ' 21 - 1001';
				}
				print  COUT "$ccd\t$node\t$l_line\t$elm\t";
				printf COUT "%5.4f\t\t%8.6f\n",$const1,$const2;

			}
			$mid = $asum/4.0;
			$ymin = 0;
			$ymax = $mid + 0.03;
			$ymax = 0.05;
			plot_three_panels();
		}

		pgclos();
#
#--- change ps files to gif files
#
		system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  peak.ps| $opn_dir/pnmflip -r270 |$op_dir/ppmtogif > $out_plot1");
		system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  width.ps| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $out_plot2");
		system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $out_plot3");
		system('rm *ps');

	}
	close(COUT);
}

system('rm -rf  ./Temp_dir/*fits param');


#####################################################################
### plot_four_panels: plot 4 nodes per panel and 3 lines per page ###
#####################################################################

sub plot_three_panels{
#	pgbegin(0, "/cps",1,1);
#	pgsch(1);
#	pgslw(2);

	if($xmin < 0){
		$xmin = 0;
	}
	$xdiff  = $xmax - $xmin;
	$ydiff  = $ymax - $ymin;
	$ymin  -= 0.1 * $ydiff;
	if($ymin < 0){
		$ymin = 0;
	}
	$ymax  += 0.1 * $ydiff;
	$ydiff  = $ymax - $ymin;
	$xpos   = $xmin + 0.10 * $xdiff;
	$ypos   = $ymax - 0.10 * $ydiff;
	$xpos1  = $xmin + 0.50 * $xdiff;
	$ypos1  = $ymax + 0.10 * $ydiff;
	$xpos2  = $xmin + 0.60 * $xdiff;
	$ypos2  = $ymax + 0.10 * $ydiff;
	$xpos3  = $xmin + 0.70 * $xdiff;
	$ypos3  = $ymax + 0.10 * $ydiff;
	$xpos4  = $xmin + 0.80 * $xdiff;
	$ypos4  = $ymax + 0.10 * $ydiff;
	
	$xmid   = $xmin + 0.50 * $xdiff;
	$xside  = $xmin - 0.08 * $xdiff;
	$yside  = $ymin + 0.50 * $ydiff;
	$ytop   = $ymax + 0.10 * $ydiff;
	$ybot   = $ymin - 0.15 * $ydiff;
#
#---- Mn K alpha case
#
	if($elm eq 'mn'){
		pgsvp(0.1, 1.0, 0.65, 0.95);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgsci(2);
		$ptotal = $mn_total_n0;
		@xbin = @mn_xdata_n0;
		@ybin = @mn_ydata_n0;
		$symbol = 2;
		plot_fig();
		@ybin = @mn_yest_n0;
		connect_points();
		pgpt(1, $xpos1, $ypos1,$symbol);
		pgtext($xpos1, $ypos1, 'Node 0');

		pgsci(3);
		$ptotal = $mn_total_n1;
		@xbin = @mn_xdata_n1;
		@ybin = @mn_ydata_n1;
		$symbol = 4;
		plot_fig();
		@ybin = @mn_yest_n1;
		connect_points();
		pgpt(1, $xpos2, $ypos2,$symbol);
		pgtext($xpos2, $ypos2, 'Node 1');
	
		pgsci(4);
		$ptotal = $mn_total_n2;
		@xbin = @mn_xdata_n2;
		@ybin = @mn_ydata_n2;
		$symbol = 5;
		plot_fig();
		@ybin = @mn_yest_n2;
		connect_points();
		pgpt(1, $xpos3, $ypos3,$symbol);
		pgtext($xpos3, $ypos3, 'Node 2');
	
		pgsci(5);
		$ptotal = $mn_total_n3;
		@xbin = @mn_xdata_n3;
		@ybin = @mn_ydata_n3;
		$symbol = 6;
		plot_fig();
		@ybin = @mn_yest_n3;
		connect_points();
		pgpt(1, $xpos4, $ypos4,$symbol);
		pgtext($xpos4, $ypos4, 'Node 3');
	
		pgsci(1);
		pgtext($xpos, $ypos, 'Mn K alpha');
		pgptxt($xmin, $ytop, 0.0, 0.0, "$title");
	
#
#---- Al K alpha case
#
	}elsif($elm eq 'al'){
		pgsvp(0.1, 1.0, 0.35, 0.65);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		
		pgsci(2);
		$ptotal = $al_total_n0;
		@xbin = @al_xdata_n0;
		@ybin = @al_ydata_n0;
		$symbol = 2;
		plot_fig();
		@ybin = @al_yest_n0;
		connect_points();

		pgsci(3);
		$ptotal = $al_total_n1;
		@xbin = @al_xdata_n1;
		@ybin = @al_ydata_n1;
		$symbol = 4;
		plot_fig();
		@ybin = @al_yest_n1;
		connect_points();
	
		pgsci(4);
		$ptotal = $al_total_n2;
		@xbin = @al_xdata_n2;
		@ybin = @al_ydata_n2;
		$symbol = 5;
		plot_fig();
		@ybin = @al_yest_n2;
		connect_points();
	
		pgsci(5);
		$ptotal = $al_total_n3;
		@xbin = @al_xdata_n3;
		@ybin = @al_ydata_n3;
		$symbol = 6;
		plot_fig();
		@ybin = @al_yest_n3;
		connect_points();
	
		pgsci(1);
		pgtext($xpos, $ypos, 'Al K alpha');
		pgptxt($xside, $yside, 90.0, 0.5, "$ytitle");
#
#---- Ti K alpha case
#		
	}elsif($elm eq 'ti' ){
		pgsvp(0.1, 1.0, 0.05, 0.35);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		
		pgsci(2);
		$ptotal = $ti_total_n0;
		@xbin = @ti_xdata_n0;
		@ybin = @ti_ydata_n0;
		$symbol = 2;
		plot_fig();
		@ybin = @ti_yest_n0;
		connect_points();

		pgsci(3);
		$ptotal = $ti_total_n1;
		@xbin = @ti_xdata_n1;
		@ybin = @ti_ydata_n1;
		$symbol = 4;
		plot_fig();
		@ybin = @ti_yest_n1;
		connect_points();
	
		pgsci(4);
		$ptotal = $ti_total_n2;
		@xbin = @ti_xdata_n2;
		@ybin = @ti_ydata_n2;
		$symbol = 5;
		plot_fig();
		@ybin = @ti_yest_n2;
		connect_points();
	
		pgsci(5);
		$ptotal = $ti_total_n3;
		@xbin = @ti_xdata_n3;
		@ybin = @ti_ydata_n3;
		$symbol = 6;
		plot_fig();
		@ybin = @ti_yest_n3;
		connect_points();
	
		pgsci(1);
		pgtext($xpos, $ypos, 'Ti K alpha');
		pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");
	}
}


########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
	for($m = 0; $m < $ptotal; $m++){
		pgpt(1, $xbin[$m], $ybin[$m], $symbol);
	}
}

########################################################
### connect_points: drawing a line trhough data points #
########################################################

sub connect_points{
	$m = 0; 
	pgmove($xbin[$m], $ybin[$m]);
	for($m = 1; $m < $ptotal; $m++){
		pgdraw($xbin[$m], $ybin[$m]);
	}
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

        for($fit_i = 0; $fit_i < $l_total;$fit_i++) {
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
        for($fit_i = 0; $fit_i < $l_total;$fit_i++) {
                $diff = $dep[$fit_i] - ($int + $slope*$date[$fit_i]);
                push(@diff_list,$diff);
                $sum += $diff;
        }
        $avg = $sum/$l_total;

        $diff2 = 0;
        for($fit_i = 0; $fit_i < $l_total;$fit_i++) {
                $diff = $diff_list[$fit_i] - avg;
                $diff2 += $diff*$diff;
        }
        $sig = sqrt($diff2/($l_total - 1));

        $sig3 = 3.0*$sig;

        @ldate = ();
        @ldep  = ();
        $cnt = 0;
        for($fit_i = 0; $fit_i < $l_total;$fit_i++) {
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

        $tot1 = $l_total - 1;
        $variance = ($lsumy2 + $int*$int*$lsum + $slope*$slope*$lsumx2
                        -2.0 *($int*$lsumy + $slope*$lsumxy - $int*$slope*$lsumx))/$tot1;
        $sigm_slope = sqrt($variance*$lsum/$delta);
}


#########################################################################
### change_to_log_and_fit: fitting routine for exp decay data         ###
#########################################################################

sub change_to_log_and_fit{
#
#--- save the original data
#
	@x_temp = @date;
	@y_temp = @dep;
	$temp_cnt = $l_total;

	@x_save = ();
	@y_save = ();
	$save_cnt = 0;
#
#--- take log and remove if the y value is 0
#
	for($j = 0; $j < $l_total; $j++){
		if($dep[$j] > 0){
			$x_save[$save_cnt] = $date[$j];
			$y_save[$save_cnt] = log($dep[$j]);
			$save_cnt++;
		}
	}

	@date = @x_save;
	@dep  = @y_save;
	$l_total  = $save_cnt;
#
#--- call the linear fit
#
	least_fit();

	$const1 = exp($int);
	$const2 = -1.0 * $slope;
#
#--- put back the original data
#
	@date = @x_temp;
	@dep  = @y_temp;
	$l_total = $temp_cnt;
}

##################################################################
#------ subs below are not used in computation
##################################################################

#######################################################
#######################################################
#######################################################

sub exp_fit {
	$a[0] = 0.01;
	$a[1] = 0.001;
	$ok = 0;
	gridls();

	if($ok > 0){
		$const1 = -999;
		$const2 = -999;
	}else{
		$const1 = $a[0];
		$const2 = $a[1];
	}
}

#######################################################
#######################################################
#######################################################

sub chi_fit{
	$sum = 0;
	for($l = 0; $l < $val_cnt; $l++){
		$z = $a[0] * exp(-1.0 * $a[1] * $x_val[$l]);
		$diff = ($y_val[$l] - $z)/$l_total;
		$sum += $diff*$diff;
	}
}
		
#######################################################
#######################################################
#######################################################

sub find_out_layer {

	least_fit();

	$sum = 0;
	$sum2 = 0;

	for($j = 0; $j < $l_total; $j++){
		$est = $int + $slope * $date[$j];
		$diff = $dep[$j] - $est;
		$sum += $diff;
		$sum2 += $diff * $diff;
	}

	$avg = $sum/$l_total;
	$sig = sqrt ($sum2/$l_total - $avg * $avg);
	$sig3 = 3.0 * $sig;	
	
	@x_val = ();
	@y_val = ();
	$val_cnt = 0;

	for($j = 0; $j < $l_total; $j++){
		$est = $int + $slope * $date[$j];
		$diff =  abs($dep[$j] - $est);
		if($diff < $sig3){
			$x_val[$val_cnt] = $date[$j];
			$y_val[$val_cnt] = $dep[$j];
			$val_cnt++;
		}
	}
}

	


####################################################################
## gridls: grid serach least squares fit for a non linear function #
####################################################################

#### see Data Reduction and Error Analysis for the Physical Sciences

sub gridls {
        OUTER:
        for($j = 0; $j < 2 ; $j++){
                $deltaa[$j] = $a[$j]*0.5;

                $fn = 0;
                chi_fit();
                $chi1 = $sum;
                $delta =  $deltaa[$j];

                $a[$j] += $delta;
                chi_fit();
                $chi2 = $sum;

                if($chi1  < $chi2){
                        $delta = -$delta;
                        $a[$j] += $delta;
                        chi_fit();
                        $save = $chi1;
                        $chi1 = $chi2;
                        $chi2 = $save;
                }elsif($chi1 == $chi2){
                        $cmax = 1;
                        while($chi1 == $chi2){
                                $a[$j] += $delta;
                                chi_fit();
                                $chi2 = $sum;
                                $cmax++;
                                if($cmax > 100){
                                        $ok = 100;
                                        print "$cmax: $a[$j] $delta $chi1 $chi2 something wrong!\n";
                                        last OUTER;
                                        exit 1;
                                }
                        }
                }

                $no = 0;
                $test = 0;
                OUTER:
                while($test < 500){

                        $fn++;
                        $test++;
                        $a[$j] += $delta;
                        if($a[$j] <= 0){
                                $a[$j] = 10;
                                $no++;
                                last OUTER;
                        }
                        chi_fit();
                        $chi3 = $sum;
                        if($test > 400){
                                $a[$j] = -999;
                                $no++;
                                last OUTER;
                        }
                        if($chi2 >= $chi3) {
                                $chi1= $chi2;
                                $chi2= $chi3;
                        }else{
                                last OUTER;
                        }
                }

                if($no == 0){
                        $delta = $delta *(1.0/(1.0 + ($chi1-$chi2)/($chi3 - $chi2)) + 0.5);
                        $a[$j] = $a[$j] - $delta;
                        $free = $l_total - 2; 
                        $siga[$j] = $deltaa[$j] * sqrt(2.0/($free*($chi3-2.0*$chi2 + $chi1)));
                }
        }
        $chisq = $sum;
}

##########################################################################
##########################################################################
##########################################################################

sub chifit{
	$nfree = $npts - $nterm;
	if($nfree <= 0){
		$chisq = 0;
	}else{
		for($i = 0; $i < $npts; $i++){
			func();
			$yfit[$i] = $val;
		}
		fchisq();
		$chisq1 = $fchi;

		for($j = 0; $j < $nterms; $j++){
			$aj = $a[$j];
			$a[$j] = $aj + $deltaa[$j];
			for($i = 0; $i < $npts; $i++){
				func();
				$yfit[$i] = $val;
			}
			fchisq();
			$chisq2 = $fchi;
			$alpha[$j][$j] = $chisq2 - 2.0 * $chisq1;
			$beta[$j] = -1.0 * $chisq2;

			for($k = 0; $k < $nterms; $k++){
				$diff =  $k - $j;
				if($diff < 0){
					$alpha[$k][$j] = 0.5 * ($alpha[$k][$j]  - $chisq2);
					$alpha[$j][$k] = $alpha[$k][$j];
				}elsif($diff > 0){
					$alpha[$j][$k] = $chisq1 - $chisq2;
					$ak = $a[$k];
					$a[$k] = $ak + $deltaa[$k];
					for($i = 0; $i < $npts; $i++){
						func();
						$yfit[$i] = $val;
					}
					fchisq();
					$chisq3 = $fchi;
					$alpha[$j][$k] = $alpha[$j][$k] + $chisq3;
					$a[$k] = $ak;
				}

			}
			$a[$j] = $aj - $deltaa[$j];
			for($i = 0; $i < $npts; $i++){
				func();
				$yfit[$i] = $val;
			}
			fchisq();
			$chisq3 = $fchi;
			$a[$j] = $aj;
			$alpha[$j][$j] = 0.5 * ($alpha[$j][$j] + $chisq3);
			$beta[$j] = 0.25 * ($beta[$j] + $chisq3);
		}

		for($j = 0; $j < $nterms; $j++){
			if($alpha[$j][$j] <= 0){
				if($alpha[$j][$j] < 0){
					$alpha[$j][$j] *= -1.0;
				}elsif($alpha[$j][$j] == 0){
					$alpha[$j][$j] = 0.01;
				}
				for($k = 0; $k < $nterms; $k++){
					$diff = $k - $j;
					if($diff != 0){
						$alpha[$j][$k] = 0;
						$alpha[$k][$j] = 0;
					}
				}
			}
		}

		@array = @alpha;
		$norder = $nterms;
		matinv();
		@alpha = @array;

		for($j = 0; $j < $nterms; $j++){
			$da[$j] = 0;
			for($k = 0; $k < $nterms; $k++){
				$da[$j] = $da[$j] + $beta[$k] * $alpha[$j][$k];
			}
			$da[$j] = 0.2 * $da[$j] * $deltaa[$j];
		}

		for($j = 0; $j < $nterms; $j++){
			$a[$j] = $a[$j] + $da[$j];
		}
		OUTER:
		while(){
			for($i = 0; $i < $npts; $i++){
				func();
				$yfit[$i] = $val;
			}
			fchisq();
			$chisq2 = $fchi;
			$diff = $chisq1 - $chisq2;
			if($diff >=  0){
				last OUTER;
			}
			for($j = 0; $j < $nterms; $j++){
				$da[$j] = 0.5 * $da[$j];
				$a[$j] = $a[$j] - $da[$j];
			}
		}

		$loop_chk = 0;
		OUTER:
		while(){
			for($j = 0; $j < $nterms; $j++){
				$a[$j] += $da[$j];
			}
			for($i = 0; $i < $npts; $i++){
				func();
				$yfit[$i] = $val;
			}
			fchisq();
			$chisq3 = $fchi;
			$diff = $chisq3 - $chisq2;
			$loop_chk++;
			if($diff >=  0){
				last OUTER;
			}elsif($loop_chk > 5000){
				last OUTER;
			}
			$chisq1 = $chisq2;
			$chisq2 = $chisq3;
		}

		$denom = 1.0 + ($chisq1 - $chisq2)/($chisq3 - $chisq2);
		$delta = 1.0/$denom + 0.5;

		for($j = 0; $j < $nterms; $j++){
			$a[$j] -= $delta * $da[$j];
			$sigmaa[$j] = $deltaa[$j] * sqrt($nfree * $alpha[$j][$j]);
		}

		for($i = 0; $i < $npts; $i++){
			func();
			$yfit[$i] = $val;
		}
		fchisq();
		$chisq = $fchi;
		$diff = $chisq1 - $chisq; 
		if($diff < 0){
			for($j = 0; $j < $nterms; $j++){
				$a[$j] += ($delta - 1.0) * $da[$j];
				for($i = 0; $i < $npts; $i++){
					func();
					$yfit[$i] = $val;
				}
				$chisq = $chisq2;
			}
		}
	}
}
				

#########################################################################
#########################################################################
#########################################################################

sub fchisq{
	my $i;
	my $chisq;

	$chisq = 0;
	if($nfree <= 0){
		$fchi = 0;
	}else{
		for($i = 0; $i < $npts; $i++){
			$chisq =  $chisq + ($y[$i] - $yfit[$i])* ($y[$i] - $yfit[$i]);
		}
		$fchi = $chisq / $nfree;
	}
}


#################################################################
#################################################################
#################################################################

sub matinv{

	my $i, $j, $k;
	$det = 1.0;

	OUTER:
	for($k = 0; $k < $norder; $k++){
		OUTER1:
		while(){
			OUTER2:
			while(){
				for($i = $k; $i < $norder; $i++){
					for($j = $k; $j < $norder; $j++){
						$diff = abs($amax) - abs($array[$i][$j]);
						if($diff <= 0){
							$amax = $array[$i][$j];
						}
						$ik[$k] = $i;
						$jk[$k] = $j;
					}
				}
		
				if($amax ==  0){
					$det = 0;
					last OUTER;
				}
		
				$i = $ik[$k];
				$diff = $i - $k;
				if($diff >= 0){
					last OUTER2;
				}
			}

			if($diff > 0){
				for($j = 0; $j < $norder; $j++){
					$save = $array[$k][$j];
					$array[$k][$j] = $array[$i][$j];
					$array[$i][$j] = -1.0 * $save;
				}
			}
			$j = $jk[k];
			$diff = $j - $k;
			if($diff >= 0){
				last OUTER1; 
			}
		}
		if($diff > 0){
			for($i = 0; $i < $norder; $i++){
				$save = $array[$i][$k];
				$array[$i][$k] = $array[$i][$j];
				$array[$i][$j] = -1.0 * $save;
			}
		}

		for($i = 0; $i < $norder; $i++){
			$diff = $i - $k;
			if($diff != 0){
				$array[$i][$k] = -1.0 * $array[$i][$k] / $amax;
			}
		}

		for($i = 0; $i < $norder; $i++){
			for($j = 0; $j < $norder; $j++){
				$diff = $i - $k;
				if($diff != 0){
					$diff = $j - $k; 
					if($diff != 0){
						$array[$i][$j] = $array[$i][$j] + $array[$i][$k] * $array[$k][$j];
					}
				}
			}
		}

		for($j = 0; $j < $norder; $j++){
			$diff = $j - $k ; 
			if($diff != 0){
				$array[$k][$j] = $array[$k][$j] / $amax;
			}
		}
		$array[$k][$k] = 1.0/$amax;
		$det *= $amax;
	}

	if($det != 0){
		for($l = 0 ;$l < $norder; $l++){
			$k = $norder - $l;
			$j = $ik[$k];
			$diff = $j - $k;
			if($diff > 0){
				for($i = 0; $i < $norder; $i++){
					$save = $array[$i][$k];
					$array[$i][$k] = -1.0 * $array[$i][$j];
					$array[$i][$j] = $save;
				}
			}
			$i = $jk[$k];
			$diff = $i - $k;
			if($diff > 0){
				for($j = 0; $j < $norder; $j++){
					$save = $array[$k][$j];
					$array[$k][$j] = -1.0 * $array[$i][$j];
					$array[$i][$j] = $save;
				}
			}
		}
	}
}

####################################################################
####################################################################
####################################################################

sub func{
	$val = $a[0] * exp(-1.0 * $a[1] * $x[$i]);
}
