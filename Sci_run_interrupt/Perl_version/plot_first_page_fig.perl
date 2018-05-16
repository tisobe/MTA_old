#!/usr/bin/perl 
use PGPLOT;

#########################################################################################
#											#
#	plot_first_page_fig.perl: plot intorductory plot for the first page		#
#											#
#											#
#		author: t. siboe (tisobe@cfa.harvard.edu)				#
#											#
#		last update Jun 13, 2011						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#


open(FH, "/data/mta/Script/Interrupt/house_keeping/dir_list");

@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$data_dir      = $atemp[1];
$web_dir       = $atemp[2];
$house_keeping = $atemp[3];

################################################################

#
#--- data input example:
#

$file = $ARGV[0];
open(FH, "$file");
$input = <FH>;
close(FH);
chomp $input;
@atemp = split(/\s+/, $input);

$name  = $atemp[0];
$begin = $atemp[1];              #--- sci run interruption started
$end   = $atemp[2];              #--- sci run interruption finished

@atemp = split(/:/, $begin);
$byear = $atemp[0];
$bmon  = $atemp[1];
$bday  = $atemp[2];
$bhour = $atemp[3];
$bmin  = $atemp[4];

$start = find_ydate($byear, $bmon, $bday) + $bhour/24 + $bmin/1440;

@atemp = split(/:/, $end);
$eyear = $atemp[0];
$emon  = $atemp[1];
$eday  = $atemp[2];
$ehour = $atemp[3];
$emin  = $atemp[4];

$stop  = find_ydate($eyear, $emon, $eday) + $ehour/24 + $emin/1440;


$data  = "$name".'_eph.txt';
@time  = ();
@e150  = ();
$pcnt  = 0;
open(FH, "$web_dir/Data_dir/$data");
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] !~ /\d/){
		next OUTER;
	}
	if($atemp[2] <= 0){
		next OUTER;
	}
#	$p4d      = (log($atemp[1]))/2.302585093;
	$e150d    = (log($atemp[2]))/2.302585093;
	push(@time, $atemp[0]);
	push(@e150,  $e150d);
	$pcnt++;
}
close(FH);

#
#--- read radiation zone information
#

read_rad_zone();

pgbegin(0, "/cps",1,1);
pgsubp(1,3);
pgsch(2);
pgslw(4);


$xmin = $start -2;
$xmax = $xmin  +5;
#$ylab = 'Log(P4 Rate)';
$ylab = 'Log(e150 Rate)';
$ymin = -3;
@temp = sort{$a<=>$b} @e150;
$ymax = $temp[$cnt-1];
$ymax = int($ymax) + 1;

pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pgsch(2.5);
pglab('Day of Year', $ylab, $title);
pgsch(2);

pgsci(2);
pgmove($start, $ymin);
pgdraw($start, $ymax);

$ym = $ymax - 0.1 * ($ymax - $ymin);

pgptxt($irpt_start, $ym, 0, left, interruption);

pgmove($stop, $ymin);
pgdraw($stop, $ymax);
#pgmove($xmin, 2.477);
#pgdraw($xmax, 2.477);
pgmove($xmin, 2.);
pgdraw($xmax, 2.);
pgsci(1);

pgsch(4);
for($m = 0; $m < $pcnt -1; $m++){
        pgpt(1, $time[$m], $e150[$m], 1);
}
pgsch(2);

plot_box();

pgclos();

$out_gif = "$web_dir/Intro_plot/$name".'_intro.gif';
 
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmcrop| pnmflip -r270 | ppmtogif > $out_gif");

system("rm pgplot.ps");




###############################################################
### read_rad_zone: read radiation zone information          ###
###############################################################

sub read_rad_zone{
        if($byear == 1999){
                $subt = - 202;
        }else{
                $subt = 365 *($byear - 2000) + 163;
                if($byear > 2000){
                        $subt++;
                }
                if($byear > 2004){
                        $subt++;
                }
                if($byear > 2008){
                        $subt++;
                }
                if($byear > 2012){
                        $subt++;
                }
                if($byear > 2016){
                        $subt++;
                }
                if($byear > 2020){
                        $subt++;
                }
        }

        open(FH, "$house_keeping/rad_zone_list");
        OUTER:
        while(<FH>){
                chomp $_;
                @atemp = split(/\s+/, $_);
                if($atemp[0] eq $name){
                        $line = $_;
                        last OUTER;
                }
        }

        @atemp = split(/\s+/, $line);
        @rad_entry = split(/:/, $atemp[1]);
        $ent_cnt = 0;
        foreach (@rad_entry){
                $ent_cnt++;
        }
}

###############################################################
### plot_box: create radiation zone box on the plot         ###
###############################################################

sub plot_box{
        pgsci(12);
        for($j = 0; $j < $ent_cnt; $j++){
                @dtmp = split(/\(/, $rad_entry[$j]);
                @etmp = split(/\)/, $dtmp[1]);
                @ftmp = split(/\,/, $etmp[0]);
                $r_start = $ftmp[0] - $subt;
                $r_end   = $ftmp[1] - $subt;
                if($r_start < $xmin){
                        $r_start = $xmin;
                }
                if($r_end > $xmax){
                        $r_end = $xmax;
                }
                pgshs (0.0, 1.0, 0.0);
                $ydiff = $ymax - $ymin;
                $yt = 0.05*$ydiff;
                $ytop = $ymin + $yt;
                pgsfs(4);
                pgrect($r_start,$r_end,$ymin,$ytop);
                pgsfs(1);
        }
        pgsci(1);
}

##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

##################################################
#       Input   $tyear: year
#               $tmonth: month
#               $tday:   day of the month
#
#       Output  $ydate: day from Jan 1<--- returned
##################################################

        my($tyear, $tmonth, $tday, $ydate, $chk);
        ($tyear, $tmonth, $tday) = @_;

        if($tmonth == 1){
                $ydate = $tday;
        }elsif($tmonth == 2){
                $ydate = $tday + 31;
        }elsif($tmonth == 3){
                $ydate = $tday + 59;
        }elsif($tmonth == 4){
                $ydate = $tday + 90;
        }elsif($tmonth == 5){
                $ydate = $tday + 120;
        }elsif($tmonth == 6){
                $ydate = $tday + 151;
        }elsif($tmonth == 7){
                $ydate = $tday + 181;
        }elsif($tmonth == 8){
                $ydate = $tday + 212;
        }elsif($tmonth == 9){
                $ydate = $tday + 243;
        }elsif($tmonth == 10){
                $ydate = $tday + 273;
        }elsif($tmonth == 11){
                $ydate = $tday + 304;
        }elsif($tmonth == 12 ){
                $ydate = $tday + 334;
        }
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }
        return $ydate;
}


