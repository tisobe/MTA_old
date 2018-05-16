#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	hrc_dose_plot_exposure_stat.perl:plotting trendings of avg and max counts of	#
#					of each sections		            	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jan 24, 2012							#
#											#
#########################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list3`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];

$in_dir  = $ARGV[0];
$out_dir = $ARGV[1];

if($in_dir eq '' || $out_dir eq ''){
	print "Usage: hrc_dose_plot_exposure_stat.perl <input dir> <output dir>\n";
	exit 1;
}

OUTER:
foreach $head ('hrci', 'hrcs'){
	for($i = 0; $i < 10; $i++){			#---- loop around sections
		if($head eq 'hrci' && $i > 8){
			next OUTER;
		}
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
		$chk      = 0;

		foreach $set ('dff', 'acc'){

			$file = "$in_dir".'/'."$head".'_'."$i".'_'."$set";
			open(FH, "$file");
			while(<FH>){
				chomp $_;
				$_ =~ s/NA/0/g;

				@atemp = split(/\s+/, $_);
				if($set eq 'dff'){
					$time = $atemp[0] + ($atemp[1] - 0.5)/12; 
					push(@date, $time);
					push(@mean_dff, $atemp[2]);
					push(@min_dff,  $atemp[4]);
					push(@m10_dff,	$atemp[6]);
					push(@max_dff,  $atemp[8]);
					$cnt++;
				}else{
					if($chk > 0 && $atemp[2] == 0){
						push(@mean_acc, $mean_acc[$chk-1]);
						push(@min_acc,  $min_acc[$chk-1]);
						push(@max_acc,  $max_acc[$chk-1]);
					}else{
						push(@mean_acc, $atemp[2]);
						push(@min_acc,  $atemp[4]);
						push(@max_acc,  $atemp[8]);
					}
					$chk++;
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
		pgsvp(0.10, 0.5, 0.70, 1.00);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		plot_fig();
		pgptxt($xbot, $ytop, 0.0, 0.0, "Averge");
#---mean cumulative
		@temp = sort{$a<=>$b} @mean_acc;
		@ybin = @mean_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-2];
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
		pgsvp(0.60, 1.0, 0.70, 1.00);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		$save = $total;
		$total--;
		plot_fig();
		$total = $save;
		pgptxt($xbot, $ytop, 0.0, 0.0, "Averge Cumulative");
#--m10
#		@temp = sort{$a<=>$b} @m10_dff;
#		@ybin = @m10_dff;
#		$ymin = $temp[0];
#		$ymax = $temp[$cnt-1];
#		$diff = $ymax - $ymin;
#		if($ymin == $ymax){
#			$ymax = $ymin + 1;
#		}
#		$ymin  = $ymin - 0.01 * $diff;
#		if($ymin < 0){
#			$ymin = 0;
#		}
#		$ymax = $ymax + 0.01 * $diff;
#		if($ymax < 3) {
#			$ymax = 3;
#		}
#		$diff = $ymax - $ymin;
#		$ytop = $ymax - 0.08 * $diff;
#		pgsvp(0.10, 0.5, 0.38, 0.68);
#		pgswin($xmin, $xmax, $ymin, $ymax);
#		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
#		plot_fig();
#		pgptxt($xbot, $ytop, 0.0, 0.0, "10th Bright");
#---m10 cumulative
#		@temp = sort{$a<=>$b} @m10_acc;
#		@ybin = @m10_acc;
#		$asum1  = 0;
#		$asum2  = 0;
#		$acnt   = 0;
#                foreach $ent (@max_acc){
#                        $asum1 += $ent;
#                        $asum2 += $ent * $ent;
#                        $acnt++;
#                }
#                $avg = $asum1/$acnt;
#                $std = sqrt($asum2/$cnt - $avg * $avg);
#
#                $ymin = $avg - 3 * $std;
#                $ymin = int ($ymin);
#		if($ymin < 0){
#			$ymin = 0;
#		}
#                $ymax = $avg + 3 * $std;
#                $yamx = int ($ymax);
#		$diff = $ymax - $ymin;
#		$ytop = $ymax - 0.08 * $diff;
#
#		pgsvp(0.60, 1.0, 0.38, 0.68);
#		pgswin($xmin, $xmax, $ymin, $ymax);
#		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
#		plot_fig();
#		pgptxt($xbot, $ytop, 0.0, 0.0, "10th Bright");
#--min
#		@temp = sort{$a<=>$b} @min_dff;
#		@ybin = @min_dff;
#		$ymin = $temp[0];
#		$ymax = $temp[$cnt-1];
#		$diff = $ymax - $ymin;
#		if($ymin == $ymax){
#			$ymax = $ymin + 1;
#		}
#		$ymin  = $ymin - 0.01 * $diff;
#		if($ymin < 0){
#			$ymin = 0;
#		}
#		$ymax = $ymax + 0.01 * $diff;
#		if($ymax < 3) {
#			$ymax = 3;
#		}
#		$diff = $ymax - $ymin;
#		$ytop = $ymax - 0.08 * $diff;
#		pgsvp(0.10, 0.5, 0.38, 0.68);
#		pgswin($xmin, $xmax, $ymin, $ymax);
#		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
#		plot_fig();
#		pgptxt($xbot, $ytop, 0.0, 0.0, "Min");
#--- min cumulative
#		@temp = sort{$a<=>$b} @min_acc;
#		@ybin = @min_acc;
#		$ymin = $temp[0];
#		$ymax = $temp[$cnt-1];
#		if($ymin == $ymax){
#			$ymax = $ymin + 1;
#		}
#		$diff = $ymax - $ymin;
#		$ymin  = $ymin - 0.01 * $diff;
#		if($ymin < 0){
#			$ymin = 0;
#		}
#		if($diff < 3){
#			$ymax++;
#			$ytop = $ymax -0.3;
#		}elsif($diff < 10){
#			$ymax += 2;
#			$ytop = $ymax -1.0;
#		}else{
#			$ymax += 4;
#			$ytop = $ymax - 0.08 * $diff;
#		}
#		pgsvp(0.60, 1.0, 0.38, 0.68);
#		pgswin($xmin, $xmax, $ymin, $ymax);
#		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
#		plot_fig();
#		pgptxt($xbot, $ytop, 0.0, 0.0, "Min Cumulative");
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
#		pgsvp(0.10, 0.5, 0.06, 0.36);
		pgsvp(0.10, 0.5, 0.38, 0.68);
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

		$asum1 = 0;
		$asum2 = 0;
		$acnt  = 0;
		foreach $ent (@max_acc){
			$asum1 += $ent;
			$asum2 += $ent * $ent;
			$acnt++;
		}
		$avg = $asum1/$acnt;
		$std = sqrt(abs($asum2/$cnt - $avg * $avg));

		$ymin = $avg - 3 * $std;
		$ymin = int ($ymin);
		$ymax = $avg + 3 * $std;
		$yamx = int ($ymax);

		$diff = $ymax - $ymin;
		$ymin  = $ymin - 0.01 * $diff;
		if($ymin < 0){
			$ymin = 0;
		}
		$ymax = $ymax + 0.01 * $diff;
		$ytop = $ymax - 0.08 * $diff;
#		pgsvp(0.60, 1.0, 0.06, 0.36);
		pgsvp(0.60, 1.0, 0.38, 0.68);
		pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
		$save = $total;
		$total--;
		plot_fig();
		$total = $save;
		pgptxt($xbot, $ytop, 0.0, 0.0, "Max Cumulative");
		pgclos();
	
		$out_gif = "$out_dir".'/'."$head".'_'."$i".'.gif';

		system("echo ''|/opt/local/bin/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|$bin_dir/pnmcrop| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $out_gif");
	
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

