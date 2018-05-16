#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	acis_dose_plot_exposure_stat.perl:plotting trendings of avg, min, 10th bright, 	#
#					and max counts of each quadrant of I2, I3, 	#
#					S2, and S3.					#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Aug 18, 2005							#
#											#
#########################################################################################

###############################################################################
#---- set directories

$bin_dir  = '/data/mta/MTA/bin/';
$dat_dir  = '/data/mta/MTA/data/';

###############################################################################

$in_dir  = $ARGV[0];
$out_dir = $ARGV[1];

if($in_dir eq '' || $out_dir eq ''){
	print "Usage: acis_dose_plot_exposure_stat.perl <input dir> <output dir>\n";
	exit 1;
}

foreach $ccd ('i_2', 'i_3', 's_2', 's_3'){
	foreach $node ('n_0', 'n_1', 'n_2', 'n_3'){
		@date     = ();
		@mean_acc = ();
		@min_acc  = ();
		@max_acc  = ();
		@m10_acc  = ();
		@mean_dff = ();
		@min_dff  = ();
		@max_dff  = ();
		@m10_dff  = ();
		$cnt      = 0;

		foreach $set ('dff', 'acc'){

			$file = "$in_dir".'/'."$ccd"."_$node"."_$set".'_out';
			open(FH, "$file");
			while(<FH>){
				chomp $_;
				@atemp = split(/\s+/, $_);
				if($set eq 'dff'){
					$time = $atemp[0] + ($atemp[1] - 0.5)/12; 
					push(@date, $time);
					push(@mean_dff, $atemp[2]);
					push(@min_dff,  $atemp[4]);
					push(@max_dff,  $atemp[6]);
					push(@m10_dff,	$atemp[8]);
					$cnt++;
				}else{
					push(@mean_acc, $atemp[2]);
					push(@min_acc,  $atemp[4]);
					push(@max_acc,  $atemp[6]);
					push(@m10_acc,	$atemp[8]);
				}
			}
			close(FH);
			$xmin = $date[0];
			$xmax = $date[$cnt-1];
			$diff = $xmax - $xmin; 
			$xmin = $xmin - 0.05 * $diff;
			$xmax = $xmax + 0.05 * $diff;
			$xbot  = $xmin + 0.05 * $diff;
			$xside = $xmin - 0.1  * $diff;
			@xbin = @date;
			$total = $cnt;
		}

		pgbegin(0, '"./pgplot.ps"/cps',1,1);
#---mean    
		@temp = sort{$a<=>$b} @mean_dff;
		@ybin = @mean_dff;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		pgsubp(1,1);
		pgsch(1);
		pgslw(2);
		pgsch(1.0);
		pgsvp(0.10, 0.5, 0.77, 1.00);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Averge");
#---mean cumulative
		@temp = sort{$a<=>$b} @mean_acc;
		@ybin = @mean_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $min - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		pgsvp(0.60, 1.0, 0.77, 1.00);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Averge Cumulative");
#--min
		@temp = sort{$a<=>$b} @min_dff;
		@ybin = @min_dff;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		$diff = $ymax - $ymin;
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		if($ymax < 3) {
			$ymax = 3;
		}
		$diff = $ymax - $ymin;
		$ytop = $ymax - 0.08 * $diff;
		pgsvp(0.10, 0.5, 0.52, 0.75);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Min");
#--- min cumulative
		@temp = sort{$a<=>$b} @min_acc;
		@ybin = @min_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		if($diff < 3){
			$ymax++;
			$ytop = $ymax -0.3;
		}elsif($diff < 10){
			$ymax += 2;
			$ytop = $ymax -1.0;
		}else{
			$ymax += 4;
			$ytop = $ymax - 0.08 * $diff;
		}
		pgsvp(0.60, 1.0, 0.52, 0.75);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Min Cumulative");
#--10 th bright
		@temp = sort{$a<=>$b} @m10_dff;
		@ybin = @m10_dff;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		$ybot = $ymin - 0.08 * $diff;
		pgsvp(0.10, 0.5, 0.27, 0.50);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "10th Brightest");
#-- 10 th bright cumulative
		@temp = sort{$a<=>$b} @m10_acc;
		@ybin = @m10_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		pgsvp(0.60, 1.0, 0.27, 0.50);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "10th Brightest Cumulative");
#-max
		@temp = sort{$a<=>$b} @max_dff;
		@ybin = @max_dff;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		$ybot = $ymin - 0.08 * $diff;
		pgsvp(0.10, 0.5, 0.03, 0.25);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Max");
		pgptxt($xmax, $ybot, 0.0, 0.0, "Time (year)");
#-- max cumulative
		@temp = sort{$a<=>$b} @max_acc;
		@ybin = @max_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}
		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
		pgsvp(0.60, 1.0, 0.03, 0.25);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Max Cumulative");
		pgclos();

		$out_gif = "$out_dir".'/'."$ccd"."_$node".'.gif';

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|$bin_dir/pnmcrop| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $out_gif");

	}
}

########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
        $color = 2;
        $symbol = 2;
        pgsci($color);
#        pgpt(1, $xmin, 0, $symbol);
        pgpt(1, $xbin[0], $ybin[0], $symbol);
        pgmove($xbin[0], $ybin[0]);
        for($m = 1; $m < $total; $m++){
		pgdraw($xbin[$m], $ybin[$m]);
                pgpt(1, $xbin[$m], $ybin[$m], $symbol);
        }
        pgsci(1);
}

