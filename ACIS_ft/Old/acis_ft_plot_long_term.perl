#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	 acis_ft_plot_long_term.perl: this script plot an entire past history of focal 	#
#		plane temp. this is a part of a csh script plotting_script.		#
#	author: Takashi Isobe								#
#	March 14, 2000	first version							#
#	July  28, 2000	modified original plot_ft.perl to adjust a new database		#
#											#
#	Last Update: Apr 16, 2013							#
#											#
#########################################################################################
#
#--- check whether this is a test
#
$comp_test = $ARGV[0];
chomp $comp_test;

#########################################################
#
#---- directory setting
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#########################################################

@time  = ();
@avg   = ();
@dev   = ();
$count = 0;
#
#--- PDATA directoy has real data files
#
open(IN,"$data_out/long_term_data");

while(<IN>) {
	chomp $_;
	@atemp = split(/\t/,$_);
#
#--- extract time, avg, and dev
#
	$time = $atemp[0];
	$avg  = $atemp[1];
	push(@time, $time);
	push(@avg, $avg);
	$count++;
}
close(IN);
#
#--- here the plotting start
#
pgbegin(0, "/ps",1,1);
pgsubp(1,1);						      # pg routine: panel
pgsch(2);						      # pg routine: charactor size
pgslw(4);					      	      # pg routine: line width

$xmin = $time[0];
$xmax = $time[$count-1] + 5;
$ymin = -130;
$ymax = -80;

#
#--- plotting sub
#
plot_fig();	
#
#--- changing a ps-file to a gif-file
#
system("echo ''| gs -sDEVICE=pgmraw -sOutputFile=- -g2100x2769 -r256x256 -q pgplot.ps|  pnmscale -xsize 500| ppmquant 16| pnmpad -white -left=20 -right=20 -top=20 -bottom=20| pnmflip -r270| ppmtogif > $web_dir/Figs/fp_temp.gif");

system("rm -rf pgplot.ps");

##################################
### plot_fig: plotting routine ###
##################################

sub plot_fig {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);	        #pg routine: env setting

        pgpt(1, $time[0], $avg[0], -1);                         #pg routine:  plot a point (x, y)
        for($m = 1; $m < $count-1; $m++) {
                unless($avg[$m] eq '*****' || $avg[$m] eq ''){	#just in a case the value
                        pgpt(1,$time[$m], $avg[$m], -2);	#was overflow
                }
                unless($yerr[$m] eq '*****' || $yerr[$m] eq ''){
                        $yb = $avg[$m] - $dev[$m];
                        $yt = $avg[$m] + $dev[$m];
                        pgpt(1,$time[$m], $yb,-2);
                        pgdraw($time[$m],$yt);
                }
        }
        pglabel("Time (Day of Mission)","Temp (C)", "ACIS Focal Plane Temperature");     
							       # pg routine: write labels
	pgclos();
}

