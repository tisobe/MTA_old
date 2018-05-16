#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	hrc_dose_monthly_plot_stat.perl :plotting trendings for monthly report, 	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Aug 22, 2005							#
#											#
#########################################################################################


#
#---- set directories
#

$temp_in = `cat ./dir_list`;
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
$mon_dir  = $dir_list[2];
$cum_dir  = $dir_list[3];
$data_out = $dir_list[4];
$plot_dir = $dir_list[5];
$img_dir  = $dir_list[6];
$web_dir  = $dir_list[7];

#$in_dir  = $ARGV[0];
#$out_dir = $ARGV[1];
$in_dir   = $data_out;

#if($in_dir eq '' || $out_dir eq ''){
#	print "Usage: acis_dose_plot_exposure_stat.perl <input dir> <output dir>\n";
#	exit 1;
#}

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsch(1);
pgslw(3);
foreach $ccd ('hrci', 'hrcs'){
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

		foreach $set ('acc'){

			$file = "$in_dir".'/'."$ccd"."_$set".'_out';
			open(FH, "$file");
			while(<FH>){
				chomp $_;
				$_ =~ s/NA/0/g;

				@atemp = split(/\s+/, $_);
 				$time = $atemp[0] + ($atemp[1] - 0.5)/12;
                                push(@date, $time);
				push(@max_acc,  $atemp[6]);
#				push(@m10_acc,	$atemp[8]);
				$cnt++;
			}
			close(FH);
			$xmin = $date[0];
			$xmax = $date[$cnt-1];
			$diff = $xmax - $xmin; 
			$xmin = $xmin - 0.05 * $diff;
			$xmax = $xmax + 0.05 * $diff;
			$xbot  = $xmin + 0.05 * $diff;
			$xside = $xmin - 0.1  * $diff;
			$xmid  = $xmin + 0.5 * $diff;
			@xbin = @date;
			$total = $cnt;
		}


#-- max cumulative
		@temp = sort{$a<=>$b} @max_acc;
		@ybin = @max_acc;
		$ymin = $temp[0];
		$ymax = $temp[$cnt-1];
		if($ymin == $ymax){
			$ymax = $ymin + 1;
		}

		if($ccd eq 'hrci'){
			$ymin = 250;

			$diff = $ymax - $ymin;
			$ymax = $ymax + 0.03 * $diff;
			$ytop = $ymax + 0.08 * $diff;
			$ybot = $ymin - 0.10 * $diff;

			pgsvp(0.10, 0.95, 0.65, 0.95);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
			pgptxt($xbot, $ytop, 0.0, 0.0, "HRC-I");
		}else{
			$ymin = 1400;

			$diff = $ymax - $ymin;
			$ymax = $ymax + 0.03 * $diff;
			$ytop = $ymax + 0.08 * $diff;
			$ybot = $ymin - 0.20 * $diff;

			pgsvp(0.10, 0.95, 0.30, 0.60);
			pgswin($xmin, $xmax, $ymin, $ymax);
			pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
			pgptxt($xbot, $ytop, 0.0, 0.0, "HRC-S");
			pgptxt($xmid, $ybot, 0.0, 0.0, "Year");
		}
		plot_fig();
}
		pgclos();

		$out_gif = "$img_dir/hrc_max_exp.gif";

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|$bin_dir/pnmcrop| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $out_gif");
system("rm pgplot.ps");


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

