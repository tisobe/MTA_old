#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	sci_run_get_ephin.perl: extract ephin data and plot around the interruption	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 10, 2011						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

open(FH, '/data/mta/Script/Interrupt/house_keeping/dir_list');
@list = ();
while(<FH>){
        chomp $_;
        push(@list, $_);
}
close(FH);

$bin_dir       = $list[0];
$data_dir      = $list[1];
$web_dir       = $list[2];
$house_keeping = $list[3];

################################################################

#
#--- start time, end time, arc4gl user name and password
#

$time   = $ARGV[0];
$time2  = $ARGV[1];
$user   = $ARGV[2];
$hakama = $ARGV[3];
$name   = $ARGV[4];

chomp $time;
chomp $user;
chomp $hakama;
chomp $name;

$dat_nam = $time;

@atemp   = split(/:/, $time);
$year    = $atemp[0];
$month   = $atemp[1];
$day     = $atemp[2];
$hour    = $atemp[3];
$min     = $atemp[4];
$sec     = '00';
 
$syear   = $year;
$smonth  = $month;
$sday    = $day;
$shour   = $hour;
$smin    = $min;

$uyear   = $year;
$umonth  = $month;
$uday    = $day;

to_dofy();

#
#--- interruption stating time
#

$irpt_start = $dofy + $hour/24.0 + $min/1440;

@atemp   = split(/:/, $time2);
$year2   = $atemp[0];
$month2  = $atemp[1];
$day2    = $atemp[2];
$hour2   = $atemp[3];
$min2    = $atemp[4];

$uyear   = $year2;
$umonth  = $month2;
$uday    = $day2;

to_dofy();

#
#--- interruption end time
#

$irpt_end = $dofy + $hour2/24.0 + $min2/1440;

#
#--- data collecting date  starts from $start_date
#

$start_date = $day - 3;

if ($start_date <= 0){
	$month--;
	if($month <= 0){
		$year--;
		$month += 12;
	}
	if($month == 1 || $month == 3 || $month == 5 || $month == 7 ||
		$month == 8 || $month == 10 || $month == 12){
		$start_date += 31;
	}elsif($month == 4 || $month == 6 || $month == 9 || $month == 11){
		$start_date += 30;
	}elsif($month == 2){
		$start_date += 28;
		if($year == 2000 || $year == $2004 || $year == 2008 || $year == 2012){
			$start_date++;
		}
	}
}

@btemp = split(//, $year);

$start_time = "$month/$start_date/$btemp[2]$btemp[3],$hour:$min:$sec";

$year   = $syear;
$day    = $sday;
$hour   = $shour;
$min    = $smin;

#
#--- data collection ends  6 days after the plotting started
#

$end_date = $start_date + 6;

if($month == 1 || $month == 3 || $month == 5 || $month == 7 ||
	$month == 8 ||  $month == 10 || $month == 12){
	if($end_date > 31){
		$end_date -=31;
		$month++;
		if($month > 12){
			$year++;
			$month = 1;
		}
	}
}elsif($month == 4 || $month == 6 || $month == 9 || $month == 11){
	if($end_date > 30){
		$end_date -= 30;
		$month++;
	}
}elsif($month == 2){
	if($year == 2000 || $year == $2004 || $year == 2008 || $year == 2012){
		if($end_date > 29){	
			$end_date -=29;
			$month = 3;
		}
	}else{
		if($end_date > 28){
			$end_date -= 28;
			$month = 3;
		}
	}
}

@btemp     = split(//, $year);
$stop_time = "$month/$end_date/$btemp[2]$btemp[3],$hour:$min:$sec";

$year  = $syear;
$month = $smonth;
$day   = $sday;
$hour  = $shour;
$min   = $smin;

#
#--- plotting starts 2 days before the interruption started
#

$start_date = $day - 2;

if ($start_date <= 0){
	$month--;
	if($month <= 0){
		$year--;
		$month += 12;
	}
	if($month == 1 || $month == 3 || $month == 5 || $month == 7 ||
		$month == 8 || $month == 10 || $month == 12){
		$start_date += 31;
	}elsif($month == 4 || $month == 6 || $month == 9 || $month == 11){
		$start_date += 30;
	}elsif($month == 2){
		$start_date += 28;
		if($year == 2000 || $year == $2004 || $year == 2008 || $year == 2012){
			$start_date++;
		}
	}
}

$uyear  = $year;
$umonth = $month;
$uday   = $start_date;

to_dofy();

$start_time2 = $dofy + $hour/24 + $min/1440;

#
#--- plotting ends 5 days after the plotting started
#

$stop_time2 =  $start_time2 + 5;

$check = `ls *`;
if($check =~ /lc1.fits/){
	system("rm ephinf*_lc1.fits");
}

#
#--- data extraction starts here
#

open(PR, '>./arch_file');
print PR "operation=retrieve\n";
print PR "dataset=flight\n";
print PR "detector=ephin\n";
print PR "level=1\n";
print PR "filetype=ephrates\n";
print PR "tstart=$start_time\n";
print PR "tstop=$stop_time\n";
print PR "go\n";
close(PR);

system("echo $hakama |arc4gl -U $user -Sarcocc -i arch_file");

system("rm arch_file");

system("gzip -d *gz");
system("ls ephinf*_lc1.fits > zlist");

open(FH, './zlist');

@list      = ();
@time      = ();
@p4_dat    = ();
@p41_dat   = ();
@e1300_dat = ();
$cnt       = 0;

while(<FH>){
	chomp $_;
	push(@list, $_);

	$input_file = $_;

	$line = "$input_file".'[cols time, scp4, scp41, sce1300]';
	system("dmlist \"$line\" outfile=zout opt='data'");

	open(IN, './zout');
	while(<IN>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/ 
			&& $atemp[3] =~ /\d/ && $atemp[4] =~ /\d/){
			$in_time = `axTime3 $atemp[2] u s u d`;

			to_dofy2();

			if($dofy >= $start_time2 && $dofy<= $stop_time2){
				push(@time, $dofy);
				if($atemp[3] == 0){
					$atemp[3] = 1.0e-4;
				}
				if($atemp[4] == 0){
					$atemp[4] = 1.0e-4;
				}
				if($atemp[5] == 0){
					$atemp[5] = 1.0e-4;
				}
				$p4    = (log($atemp[3]))/2.302585093;
				$p41   = (log($atemp[4]))/2.302585093;
				$e1300 = (log($atemp[5]))/2.302585093;

				push(@p4_dat,    $p4);
				push(@p41_dat,   $p41);
				push(@e1300_dat, $e1300);
			}
		}
	}
	close(IN);
}
close(FH);
close(OUT1);
close(OUT2);
close(OUT3);
system("rm zlist");

open(OUT,'>./ephin_data.txt');
print OUT "Ephin Data: $dat_nam\n\n";
print OUT "dofy\tp4\tp41\te1300\n";
print OUT "--------------------------------------------------------------";
print OUT "-------------------------------------------------------------\n";
print OUT "\n";

$cnt = 0;
foreach $ent (@time){
	printf OUT "%5.3f\t%5.2e\t%5.2e\t%5.2e\n",$ent,$p4_dat[$cnt],$p41_dat[$cnt],$e1300_dat[$cnt];
	$cnt++;
}
close(OUT);

#
#--- read radiation zone information
#

read_rad_zone(); 

pgbegin(0, "/cps",1,1);
pgsubp(1,3);
pgsch(2);
pgslw(2); 

$xmin = $start_time2;
$xmax = $stop_time2;

$ylab = 'Log(P4 Rate)';
$ymin = -3;
@temp = sort{$a<=>$b} @p4_dat;
$ymax = $temp[$cnt-1];
$ymax = int($ymax) + 1;

pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pglab('Day of Year', $ylab, $title);

pgsci(2);
pgmove($irpt_start, $ymin);
pgdraw($irpt_start, $ymax);

$ym = $ymax - 0.1 * ($ymax - $ymin);

pgptxt($irpt_start, $ym, 0, left, interruption);

pgmove($irpt_end,$ymin);
pgdraw($irpt_end,$ymax);
pgmove($xmin, 2.477);
pgdraw($xmax, 2.477);
pgsci(1);

pgsch(4);
for($m = 0; $m < $cnt -1; $m++){
	pgpt(1, $time[$m], $p4_dat[$m], 1);
}
pgsch(2);

plot_box();

$ylab = 'Log(P41 Rate)';
@temp = sort{$a<=>$b} @p41_dat;
$ymax = $temp[$cnt-1];
$ymax = int($ymax) + 1;
pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pglab('Day of Year', $ylab, $title);

pgsci(2);
pgmove($irpt_start, $ymin);
pgdraw($irpt_start, $ymax);
$ym = $ymax - 0.1 * ($ymax - $ymin);
pgptxt($irpt_start, $ym, 0, left, interruption);

pgmove($irpt_end, $ymin);
pgdraw($irpt_end, $ymax);
pgmove($xmin, 1.0);
pgdraw($xmax, 1.0);

pgsci(1);

pgsch(4);
for($m = 0; $m < $cnt -1; $m++){
	pgpt(1, $time[$m], $p41_dat[$m], 1);
}
pgsch(2);

plot_box();

$ylab = 'Log(E1300 Rate)';
@temp = sort{$a<=>$b} @e1300_dat;
$ymax = $temp[$cnt-1];
$ymax = int($ymax) + 1;
pgenv($xmin, $xmax, $ymin, $ymax, 0 , 0);
pglab('Day of Year', $ylab, $title);

pgsci(2);
pgmove($irpt_start, $ymin);
pgdraw($irpt_start, $ymax);
$ym = $ymax - 0.1 * ($ymax - $ymin);
pgptxt($irpt_start, $ym, 0, left, interruption);

pgmove($irpt_end, $ymin);
pgdraw($irpt_end, $ymax);

#pgmove($xmin, 1.0);
#pgdraw($xmax, 1.0);
pgmove($xmin, 1.301);
pgdraw($xmax, 1.301);
pgsci(1);

pgsch(4);
for($m = 0; $m < $cnt -1; $m++){
	pgpt(1, $time[$m], $e1300_dat[$m], 1);
}
pgsch(2);

plot_box();

pgclos();

system("rm *fits zout");
	
##############################################################
### to_dofy: change date to day of the year                ###
##############################################################

sub to_dofy{
        if($umonth == 1){
                $add = 0;
        }elsif($umonth == 2){
                $add = 31;
        }elsif($umonth == 3){
                $add = 59;
        }elsif($umonth == 4){
                $add = 90;
        }elsif($umonth == 5){
                $add = 120;
        }elsif($umonth == 6){
                $add = 151;
        }elsif($umonth == 7){
                $add = 181;
        }elsif($umonth == 8){
                $add = 212;
        }elsif($umonth == 9){
                $add = 243;
        }elsif($umonth == 10){
                $add = 273;
        }elsif($umonth == 11){
                $add = 304;
        }elsif($umonth == 12){
                $add = 334;
        }

	if($uyear == 2000 || $uyear == 2004 || $uyear == 2008 || $uyear ==2012){
		if($umonth > 2){
			$add += 1;
		}
	}

        $dofy = $uday + $add;
}

##############################################################
#### to_dofy2: day of the year fraction version            ###
##############################################################

sub to_dofy2{

	@rtemp = split(/:/,$in_time);
	$uyear = $rtemp[0];
	$uyday = $rtemp[1];

	$hour  = $rtemp[2];
	$min   = $rtemp[3];

	$frac  = $hour/24 + $min/1440;

	$dofy = $uyday + $frac;
}

###############################################################
### read_rad_zone: read radiation zone information          ###
###############################################################

sub read_rad_zone{
        if($uyear == 1999){
                $subt = - 202;
        }else{
                $subt = 365 *($uyear - 2000) + 163;
                if($uyear > 2000){
                        $subt++;
                }
                if($uyear > 2004){
                        $subt++;
                }
                if($uyear > 2008){
                        $subt++;
                }
                if($uyear > 2012){
                        $subt++;
		}
                if($uyear > 2016){
                        $subt++;
		}
                if($uyear > 2020){
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

