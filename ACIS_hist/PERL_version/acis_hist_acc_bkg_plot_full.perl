#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	acc_bkg_plot.perl: obtain all past background count rate data, add them up, change bin	#
#			   size to 40, and plot it.						#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#	last update: Jul 26, 2012								#
#################################################################################################

#
#--- read directory path
#
$dir_list = '/data/mta/Script/ACIS/Acis_hist_linux/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#
#--- get a list of input data
#

$file = $ARGV[0];
if($file eq ''){
	close(FH);
	$list = `ls -d /data/mta/www/mta_acis_hist/Data/Data_*_*`;
	@dir_list = split(/\s+/, $list);
	$state_ind = 0;
}else{
	open(FH,"$file");
	while(<FH>){
		chomp $_;
		push(@dir_list, $_);
	}
	close(FH);
	$state_ind = 1;
}

system("mkdir ./Temp_dir");

$chk = `ls ./`;
if($chk =~ /param/){
        system("rm -rf param");
}
system("mkdir ./param");


#
#---- loop around all CCD, Node, and location on CCD
#

for($ccd = 0; $ccd < 10; $ccd++){
	foreach $loc ('full'){
		@count = ();
		@xbin  = ();
		for($node = 0; $node < 4; $node++){
			for($i = 0; $i < 4096; $i++){
				$count[$i] = 0;
				$xbin[$i]  = $i;
			}
#
#--- state_ind says that where to put resulting plots. if the data is taken from a usual place (Data_*_*), 
#--- they go to Results directory. Otherwise they go to a current directory
#
			$total = 0;
			OUTER:
			for $dir (@dir_list){
				$input_file  = "$dir".'/CCD'."$ccd".'/node'."$node".'_'."$loc".'_bkg';
				system("ls $input_file > zchk2");
				open(FH, './zchk2');
				$chk = 0;
				while(<FH>){
					chomp $_;
					if($_ ne ''){
						$chk = 1;
					}
				}
				close(FH);
				system('rm zchk2');
				if($chk == 0){
					next OUTER;
				}

#
#---- accumulate all data from the past
#
				$cnt = 0;
				open(FH, "$input_file");
                                while(<FH>){
                                        chomp $_;
                                        @atemp = split(//, $_);
                                        if($atemp[0] ne '#'){
                                                @btemp = split(/\s+/, $_);
                                                $count[$cnt] += $btemp[2];
                                                $cnt++;
                                        }
                                }
                                close(FH);
				$total++;
			}

				if($total > 0){
					@new_x_bin = ();
					@new_y_bin = ();
					@new_y_err = ();
					for($i = 0; $i < 102; $i++){
						$xpos = 40 * $i + 20;
						$start = 40 * $i;
						$end   = $start + 40;
						$sum = 0;
						$sum2 = 0;
						for($m = $start; $m <= $end; $m++){
							$norm = $count[$m]/$total;
							$sum += $norm;
							$sum2 += $norm * $norm;
						}
						$avg = $sum / 40;
						$avg2 = $sum2 / 40;
						$diff = $avg2 - $avg * $avg;
						if($diff < 0){
							$diff = 0;
						}
						$err = sqrt($diff);
						push(@new_x_bin, $xpos);
						push(@new_y_bin, $sum);
						push(@new_y_err, $err);
					}
						
					for($i = 0; $i < 4001; $i++){
						$norm = $count[$i]/$total;
						printf OUT "%5d\t%8.6f\n", $cnt, $norm;
					}
				}
		
				@{xbin.$node.$loc} = @new_x_bin;
				@{ybin.$node.$loc} = @new_y_bin;
				@{yerr.$node.$loc} = @new_y_err;
		}
	}

#
#--- state_ind says that where to put resulting plots. if the data is taken from a usual place (Data_*_*), 
#--- they go to Results directory. Otherwise they go to a current directory
#
		if($state_ind == 0){
			$plot_file = '/data/mta/www/mta_acis_hist/Results/CCD'."$ccd".'/'.'total_bkg.gif';
		}else {
			$plot_file = 'CCD'."$ccd".'/'.'total_bkg.gif';
		}
#
#--- plot starts here
#
		$xmin = 0; 
		$xmax = 4096;
		$ymin = 0;
		$ymax = 0.01;
		if($ccd == 5 || $ccd == 7){
			$ymax = 0.02;
		}
		$xdiff = $xmax - $xmin;
		$ydiff = $ymax - $ymin;
		$xpos   = $xmin + 0.10 * $xdiff;
		$ypos   = $ymax - 0.15 * $ydiff;
		$xmid   = $xmin + 0.50 * $xdiff;
		$xside  = $xmin - 0.09 * $xdiff;
		$yside  = $ymin + 0.50 * $ydiff;
		$ytop   = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.20 * $ydiff;

		$title = "Background Count Rates: CCD $ccd";
		$ytitle = 'Counts/sec';

		pgbegin(0, "/cps",1,1);
		pgsubp(1,1);
		pgsch(1);
		pgslw(2);
		for($node = 0; $node < 4; $node++){
			$vbegin = 0.95 - 0.225 * ($node + 1);
			$vend   = 0.95 - 0.225 * $node;
			pgsvp(0.1, 1.0, $vbegin, $vend);
			pgswin($xmin, $xmax, $ymin, $ymax);
			if($node == 3){
				pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
			}else{
				pgbox(ABCST,  0.0, 0.0, ABCNSTV, 0.0, 0.0);
			}
			pgsci(2);
			@xbin = @{xbin.$node.full};
			@ybin = @{ybin.$node.full};
			$ptotal = 101;
			connect_points();
			pgsci(1);

			if($node == 0){
				pgptxt($xpos, $ypos, 0.0, 0.0, 'Node 0');
				pgptxt($xmin, $ytop, 0.0, 0.0, "$title");
				pgsci(1);
			}
			if($node == 1){
				pgptxt($xpos, $ypos, 0.0, 0.0, 'Node 1');
			}
			if($node == 2){
				pgptxt($xpos, $ypos, 0.0, 0.0, 'Node 2');
				pgptxt($xside, $ymax, 90.0, 0.5, "$ytitle");
			}
			if($node == 3){
				pgptxt($xpos, $ypos, 0.0, 0.0, 'Node 3');
				pgptxt($xmid, $ybot, 0.0, 0.5, "Energy (ADU)");
			}
		}
		
		pgclos();
					
#
#---- changing a ps file to a gif file
#
	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 | $op_dir/ppmtogif >$plot_file");
	system('rm pgplot.ps');
}	

system('rm -rf  ./Temp_dir/*fits param');

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
