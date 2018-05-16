#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	alignment_sim_twist_relation_plot.perl: plots relations among sim_x, sim_y, 	#
#						sim_z, pitchamp, and yawamp		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last updated: Jun 04, 2013							#
#											#
#########################################################################################

############################################################
#---- set directries
$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
############################################################


($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$this_year = 1900 + $uyear;

#
#--- read data 
#

@date_obs = ();
@date_end = ();
@sim_x    = ();
@sim_y    = ();
@sim_z    = ();
@pitchamp = ();
@yawamp   = ();
$cnt      = 0;

for($year = 2000; $year <= $this_year; $year++){
	$in_data = 'data_info_'."$year";
	open(FH, "$web_dir/Data/$in_data");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@date_obs , $atemp[1]);
		push(@date_end , $atemp[2]);
		push(@sim_x    , $atemp[3]);
		push(@sim_y    , $atemp[4]);
		push(@sim_z    , $atemp[5]);
		push(@pitchamp , $atemp[6]);
		push(@yawamp   , $atemp[7]);
		$cnt++;
	}
	close(FH);
}

$total = $cnt;

#
#---- set min, max etc
#

@temp = sort{$a<=>$b} @sim_x;
$diff = $temp[$cnt-5] - $temp[0];
$sim_x_min = $temp[0] - 0.01 * $diff;
$sim_x_max = $temp[$cnt-5] + 0.01 * $diff;
if($sim_x_min == $sim_x_max){
	$sim_x_min = 0;
	$sim_x_max = 1;
}
$sim_x_mid  = $sim_x_min + 0.5 * $diff;
$sim_x_side = $sim_x_min + 0.1 * $diff;
$sim_x_bot  = $sim_x_min - 0.08 * $diff;

@temp = sort{$a<=>$b} @sim_y;
$diff = $temp[$cnt-5] - $temp[0];
$sim_y_min = $temp[0] - 0.01 * $diff;
$sim_y_max = $temp[$cnt-5] + 0.01 * $diff;
if($sim_y_min == $sim_y_max){
	$sim_y_min = 0;
	$sim_y_max = 1;
}
$diff = $sim_y_max - $sim_y_min;
$sim_y_mid  = $sim_y_min + 0.5 * $diff;
$sim_y_side = $sim_y_min + 0.1 * $diff;
$sim_y_bot  = $sim_y_min - 0.1 * $diff;

@temp = sort{$a<=>$b} @sim_z;
$diff = $temp[$cnt-5] - $temp[0];
$sim_z_min = $temp[0] - 0.01 * $diff;
$sim_z_max = $temp[$cnt-5] + 0.01 * $diff;
if($sim_z_min == $sim_z_max){
	$sim_z_min = 0;
	$sim_z_max = 1;
}
$diff = $sim_z_max - $sim_z_min;
$sim_z_mid  = $sim_z_min + 0.5 * $diff;
$sim_z_side = $sim_z_min + 0.1 * $diff;
$sim_z_bot  = $sim_z_min - 0.1 * $diff;

@temp = sort{$a<=>$b} @pitchamp;
$diff = $temp[$cnt-5] - $temp[0];
$pitchamp_min = $temp[0] - 0.01 * $diff;
$pitchamp_max = $temp[$cnt-5] + 0.01 * $diff;
if($pitchamp_min == $pitchamp_max){
	$pitchamp_min = 0;
	$pitchamp_max = 1;
}
$diff = $pitchamp_max - $pitchamp_min;
$pitchamp_mid  = $pitchamp_min + 0.5 * $diff;
$pitchamp_side = $pitchamp_min + 0.1 * $diff;
$pitchamp_bot  = $pitchamp_min - 0.1 * $diff;

@temp = sort{$a<=>$b} @yawamp;
$diff = $temp[$cnt-5] - $temp[0];
$yawamp_min = $temp[0] - 0.01 * $diff;
$yawamp_max = $temp[$cnt-5] + 0.01 * $diff;
if($yawamp_min == $yawamp_max){
	$yawamp_min = 0;
	$yawamp_max = 1;
}
$diff = $yawamp_max - $yawamp_min;
$yawamp_mid  = $yawamp_min + 0.5 * $diff;
$yawamp_side = $yawamp_min + 0.1 * $diff;
$yawamp_bot  = $yawamp_min - 0.1 * $diff;

#
#---- plot fig: sim_x base
#
pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsch(1);
pgslw(3);

pgsvp(0.10, 0.5, 0.60, 1.00);
pgswin($sim_x_min, $sim_x_max, $sim_y_min, $sim_y_max);
pgbox(ABCST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_x;
@ybin = @sim_y;
plot_fig();
pgptxt($sim_x_bot,$sim_y_mid, 90.0, 0.5, "sim_y");

pgsvp(0.55, 1.0, 0.60, 1.00);
pgswin($sim_x_min, $sim_x_max, $sim_z_min, $sim_z_max);
pgbox(ABCST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_x;
@ybin = @sim_z;
plot_fig();
pgptxt($sim_x_bot,$sim_z_mid, 90.0, 0.5, "sim_z");

pgsvp(0.10, 0.5, 0.19, 0.59);
pgswin($sim_x_min, $sim_x_max, $pitchamp_min, $pitchamp_max);
pgbox(ABCNST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_x;
@ybin = @pitchamp;
plot_fig();
pgptxt($sim_x_bot,$pitchamp_mid, 90.0, 0.5, "pitchamp");
pgptxt($sim_x_mid,$pitchamp_bot,  0.0, 0.5, "sim_x");

pgsvp(0.55, 1.0, 0.19, 0.59);
pgswin($sim_x_min, $sim_x_max, $yawamp_min, $yawamp_max);
pgbox(ABCNST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_x;
@ybin = @yawamp;
plot_fig();
pgptxt($sim_x_bot,$yawamp_mid, 90.0, 0.5, "yawamp");
pgptxt($sim_x_mid,$yawamp_bot,  0.0, 0.5, "sim_x");

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/sim_x_base.gif");

#
#--- plot fig: sim_z base
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsch(1);
pgslw(3);

pgsvp(0.10, 0.5, 0.60, 1.00);
pgswin($sim_z_min, $sim_z_max, $pitchamp_min, $pitchamp_max);
pgbox(ABCNST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_z;
@ybin = @pitchamp;
plot_fig();
pgptxt($sim_z_bot,$pitchamp_mid, 90.0, 0.5, "pitchamp");
pgptxt($sim_z_mid,$pitchamp_bot,  0.0, 0.5, "sim_z");

pgsvp(0.55, 1.0, 0.60, 1.00);
pgswin($sim_z_min, $sim_z_max, $yawamp_min, $yawamp_max);
pgbox(ABCNST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @sim_z;
@ybin = @yawamp;
plot_fig();
$sim_z_bot2 = $sim_z_bot  + 0.02 * ($sim_z_max - $sim_z_min);
pgptxt($sim_z_bot2,$yawamp_mid, 90.0, 0.5, "yawamp");
pgptxt($sim_z_mid,$yawamp_bot,  0.0, 0.5, "sim_z");

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/sim_z_base.gif");

#
#--- plot fig: pitchamp base
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsch(1);
pgslw(3);

pgsvp(0.10, 0.5, 0.60, 1.00);
pgswin($pitchamp_min, $pitchamp_max, $yawamp_min, $yawamp_max);
pgbox(ABCNST,0.0 , 0.0, ABCNST, 0.0, 0.0);
@xbin = @pitchamp;
@ybin = @yawamp;
plot_fig();
pgptxt($pitchamp_bot, $yawamp_mid, 90.0, 0.5, "yawamp");
pgptxt($pitchamp_mid,$yawamp_bot,  0.0, 0.5, "pitchamp");

pgclos();
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/pichamp_base.gif");


system("rm -rf pgplot.ps");

########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
	$color = 2;
	$symbol = 5;
        pgsci($color);
        for($m = 0; $m < $total; $m++){
                pgpt(1, $xbin[$m], $ybin[$m], $symbol);
        }
        pgsci(1);
}

