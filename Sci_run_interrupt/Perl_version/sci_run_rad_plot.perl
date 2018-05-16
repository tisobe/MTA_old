#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	sci_run_rad_plot.perl: plot NOAA radiation data					#
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
#--- if the next two are given as arguments, use them, otherwise, ask 
#--- a user to type them in.
#

$file      = $ARGV[0];		#---- radiation data
$date_list = $ARGV[1];		#---- a list of science run interruption

chomp $file;
chomp $date_list;

if($file eq '' || $date_list eq ''){

#
#--- radiation database
#

	print "Radiation Data File (e.g., rad_data2006): ";
	$file = <STDIN>;
	chomp $file;

#
#--- a list of science run interruption
#--- format example:
#--- 20000608 2000:06:08:05:41 2000:06:09:08:30  96.5  auto
#

	print "Time List: ";
	$date_list = <STDIN>;	
	chomp $date_list;	

}

#
#--- read radiation data
#

open(FH, "$house_keeping/$file");

@database     = ();
$database_cnt = 0;	

while(<FH>){
	chomp $_;
	push(@database, $_);
	$database_cnt++;
}
close(FH);

#
#---- read the interuption date etc
#

open(FH, "$date_list");
@name     = ();
@start    = ();
@stop     = ();
@interval = ();
@method   = ();
$total    = 0;

while(<FH>){
        chomp $_;
        @atemp = split(/\s+/, $_);
        push(@name,   $atemp[0]);
        push(@start,  $atemp[1]);
        push(@end,    $atemp[2]);
	push(@method, $atemp[4]);
        $total++;

	@btemp  = split(/:/, $atemp[1]);
	$uyear  = $btemp[0];
	$umonth = $btemp[1];
	$uday   = $btemp[2];

#
#--- change to day of the year
#
	to_dofy();

	$begin  = $uyday + $btemp[3]/24 + $btemp[4]/1440;

	@btemp  = split(/:/, $atemp[2]);
	$uyear  = $btemp[0];
	$umonth = $btemp[1];
	$uday   = $btemp[2];

	to_dofy();

	$end    = $uyday + $btemp[3]/24 + $btemp[4]/1440;

	$diff   = 86.400*($end - $begin);
	push(@interval, $diff);
}
close(FH);

for($k = 0; $k < $total; $k++){
	$sname          = $name[$k];
	$time           = $start[$k];
	$time2          = $end[$k];
	$interrupt_time = $interval[$k];
	$int_method     = $method[$k];

#
#--- find a display interval (5 days: starting
#--- exactly 2days before the interruption and end 3days after
#
	set_time_int();
				
	@atime  = split(/:/, $start_time);
	$uyear  = $atime[0];
	$umonth = $atime[1];
	$uday   = $atime[2];

	to_dofy();

	$dofy_start = $uyday + $atime[3]/24 + $atime[4]/1440;

	@atime  = split(/:/, $stop_time);
	$uyear  = $atime[0];
	$umonth = $atime[1];
	$uday   = $atime[2];

	to_dofy();

	$dofy_end = $uyday + $atime[3]/24 + $atime[4]/1440;

#
#--- read radiation interval and make a plot
#

	rad_find();
}

########################################################################
### set_time_int: setting time interval for data collecition         ###
########################################################################

sub set_time_int {

#
#--- find the interruption starting time in dofy
#

	@atemp  = split(/:/, $time);
	$year   = $atemp[0];
	$month  = $atemp[1];
	$day    = $atemp[2];
	$hour   = $atemp[3];
	$min    = $atemp[4];
	$sec    = '00';
	
	$syear  = $year;
	$smonth = $month;
	$sday   = $day;
	$shour  =  $hour;
	$smin   = $min;

	$uyear  = $year;
	$umonth = $month;
	$uday   = $day;

	to_dofy();

	$irpt_start = $uyday + $hour/24.0 + $min/1440;
	
#
#--- find the interruption ending time in dofy
#

	@atemp  = split(/:/, $time2);
	$year2  = $atemp[0];
	$month2 = $atemp[1];
	$day2   = $atemp[2];
	$hour2  = $atemp[3];
	$min2   = $atemp[4];
	
	$uyear  = $year2;
	$umonth = $month2;
	$uday   = $day2;

	to_dofy();

	$irpt_end = $uyday + $hour2/24.0 + $min2/1440;
	
#print "$irpt_start	$irpt_end	\n";
	
	$year  = $syear;
	$month = $smonth;
	$day   = $sday;
	$hour  =  $shour;
	$min   = $smin;

#
#--- find the starting date for data collection
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
	$start_time = "$year:$month:$start_date:$hour:$min";
	
	$year  = $syear;
	$day   = $sday;
	$hour  = $shour;
	$min   = $smin;

#
#--- find the ending date for data collection
#

	$end_date = $start_date + 5;

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
	
	$stop_time = "$year:$month:$end_date:$hour:$min";
}

########################################################################
### rad_find: read radiation interval and make a plot                ###
########################################################################

sub rad_find {

	@dofy_date = ();
	@elec38    = ();
	@elec175   = ();
	@prot47    = ();
	@prot112   = ();
	@prot310   = ();
	@prot761   = ();
	@prot1060  = ();
	@anis      = ();
	$dat_cnt   = 0;

	$out_data = "$web_dir".'/Data_dir/'."$sname".'_dat.txt';
	open(ODAT,">$out_data");

	print ODAT "Science Run Interruption: $time\n\n";
	print ODAT "dofy\telectron38\telectron175\tprotont47\tproton112\t";
	print ODAT "proton310\tproton761\tproton1060\taniso\n";
	print ODAT "--------------------------------------------------------------";
	print ODAT "-------------------------------------------------------------\n";
	print ODAT "\n";
	OUTER:
	foreach $line (@database){
		@atemp = split(//, $line);
		if($atemp[0] eq '#'){
			### do nothing, just skip	
		}else{
			@btemp = split(/\s+/, $line);
			$time  = "$btemp[0]$btemp[1]$btemp[2].$btemp[3]";

			push(@date, $time);

			$uyear  = $btemp[0];
			$umonth = $btemp[1];
			$uday   = $btemp[2];

			to_dofy();

			$ftime = $btemp[5]/86400;
			$dofy  = $uyday+$ftime;
			if($dofy >=  $dofy_start && $dofy < $dofy_end){	
				push(@dofy_date, $dofy);
				push(@elec38,   $btemp[7]);
				push(@elec175,  $btemp[8]);
				push(@prot47,   $btemp[10]);
				push(@prot112,  $btemp[11]);
				push(@prot310,  $btemp[12]);
				push(@prot761,  $btemp[13]);
				push(@prot1060, $btemp[14]);
				push(@anis,     $btemp[15]);
				$dat_cnt++;
				if($btemp[7] > 0){
					printf ODAT "%5.4f\t",$dofy;
					print ODAT "$btemp[7]\t$btemp[8]\t";
					print ODAT "$btemp[10]\t$btemp[11]\t$btemp[12]\t";
					print ODAT "$btemp[13]\t$btemp[14]\t$btemp[15]\n";
				}
			}elsif($dofy >= $dofy_end){
				last OUTER;
			}
		}
	}
	close(FH);
	close(ODAT);

#
#--- read radiation zone information
#	

	read_rad_zone();

	pgbegin(0, "/cps",1,1);
	pgsubp(1,3);
	pgsch(2);			 
	pgslw(2);

	$xmin = $dofy_start;
	$xmax = $dofy_end;
	$xlab = 'Day of year';

	$ymin = 1;
	$ymax = 6;
	$ylab = 'Electron/cm2-a-sr-Mev';
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 20);
	pglab('Day of Year', $ylab, $title);

	pgsci(2);
	pgmove($irpt_start, $ymin);
	pgdraw($irpt_start, $ymax);
	$ym = $ymax + 0.5;
	$ym = $ymax - 0.1*($ymax - $ymin);
	pgptxt($irpt_start, $ym, 0, left, interruption);
	
	pgmove($irpt_end, $ymin);
	pgdraw($irpt_end, $ymax);
	pgsci(1);

	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		if($elec38[$m] > 0){
			$y = (log  $elec38[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);

	pgtext($dofy_start, 0.1, 'Electron30-53');
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(4);
		if($elec175[$m] > 0){
			$y = (log  $elec175[$m])/2.302585093;
			pgpt(1,$dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, -0.4, 'Electron175-315');

	plot_box();

	pgsci(1);
	$ymin = 1;
	$ymax = 6;
	$ylab = 'Proton/cm2-a-sr-Mev';
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 20);
	pglab('Day of Year',$ylab,'');

	pgsci(2);
	pgmove($irpt_start,$ymin);
	pgdraw($irpt_start,$ymax);
	$ym = $ymax - 0.1*($ymax - $ymin);
	pgptxt($irpt_start,$ym, 0,left,interruption);
	
	pgmove($irpt_end,$ymin);
	pgdraw($irpt_end,$ymax);
	pgsci(1);

	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		if($prot47[$m] > 0){
			$y = (log  $prot47[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, 0, 'Proton47-65');
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(4);
		if($prot112[$m] > 0){
			$y = (log  $prot112[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, -0.5, 'Proton112-187');
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(6);
		if($prot310[$m] > 0){
			$y = (log  $prot310[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, -1.0, 'Proton310-580');
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(8);
		if($prot761[$m] > 0){
			$y = (log  $prot761[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, -1.5, 'Proton761-1220');
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(10);
		if($prot1060[$m] > 0){
			$y = (log  $prot1060[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, -1);
		}
	}
	pgslw(2);
	pgtext($dofy_start, -2.0, 'Proton1060-1910');

	plot_box();

	pgsci(1);
	$ymin = 0.0;
	$ymax = 2.0;
	$ylab = 'Anisotropy Index';
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	pglab('Day of Year',$ylab,'');

	pgsci(2);
	pgmove($irpt_start,$ymin);
	pgdraw($irpt_start,$ymax);
	$ym = $ymax - 0.1*($ymax - $ymin);
	pgptxt($irpt_start,$ym, 0,left,interruption);
	
	pgmove($irpt_end,$ymin);
	pgdraw($irpt_end,$ymax);
	pgsci(1);

	$pchk = 0;
	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		pgpt(1,$dofy_date[$m],$anis[$m],, -1);
		if($anis[$m] > 0){
			$pchk++;
		}
	}

	if($pchk == 0){
		$xnote = $xmin + 0.1 * ($xmax - $xmin);
		pgsch(6);
		pgptxt($xnote, 1.5, 0, 0, "No Data");
		pgsch(2);
	}

	plot_box();

	pgclos;

	$out_name  = "$sname".'.ps';
	$out_name2 = "$web_dir".'/Main_plot/'."$sname".'.gif';

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $out_name2");

	system("mv pgplot.ps $web_dir/Ps_dir/$out_name");
	
#--------- tiny plots

	pgbegin(0, "/cps",1,1);
	pgsubp(1,3);	
	pgsch(2);	
	pgslw(2);	

	$xmin = $dofy_start;
	$xmax = $dofy_end;
	$xlab = 'Day of Year';

	$ymin = 1;
	$ymax = 6;
	$ylab = 'Electron/cm2-a-sr-Mev';
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 20);

	pgsch(4);
	pgsci(2);
	pgmove($irpt_start, $ymin);
	pgdraw($irpt_start, $ymax);
	
	pgmove($irpt_end, $ymin);
	pgdraw($irpt_end, $ymax);
	pgsci(1);

	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		if($elec38[$m] > 0){
			$y = (log  $elec38[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(4);
		if($elec175[$m] > 0){
			$y = (log  $elec175[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	pgsch(2);
	pgsci(1);
	$ymin = 1;
	$ymax = 6;
	$ylab = 'Proton/cm2-a-sr-Mev';
	pgenv($xmin, $xmax, $ymin, $ymax, 0 , 20);
	pglab('Day of Year',$ylab,'');

	pgsci(2);
	pgsch(4);
	pgmove($irpt_start,$ymin);
	pgdraw($irpt_start,$ymax);
	
	pgmove($irpt_end,$ymin);
	pgdraw($irpt_end,$ymax);
	pgsci(1);

	pgslw(3);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		if($prot47[$m] > 0){
			$y = (log  $prot47[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(4);
		if($prot112[$m] > 0){
			$y = (log  $prot112[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(6);
		if($prot310[$m] > 0){
			$y = (log  $prot310[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(8);
		if($prot761[$m] > 0){
			$y = (log  $prot761[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(10);
		if($prot1060[$m] > 0){
			$y = (log  $prot1060[$m])/2.302585093;
			pgpt(1, $dofy_date[$m], $y, 2);
		}
	}
	pgsch(2);

	pgsci(1);
	$ymin = 0.0;
	$ymax = 2.0;
	$ylab = 'Anisotropy Index';
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	pglab('Day of Year', $ylab, '');

	pgsci(2);
	pgmove($irpt_start, $ymin);
	pgdraw($irpt_start, $ymax);
	
	pgmove($irpt_end, $ymin);
	pgdraw($irpt_end, $ymax);
	pgsci(1);

	pgslw(3);
	pgsch(4);
	for($m = 0; $m < $dat_cnt -1; $m++){
		pgsci(2);
		pgpt(1, $dofy_date[$m], $anis[$m] ,, 2);
	}
	pgsch(1);
	pgend;

	$out_name  = "$sname".'_tiny.ps';
	$out_name2 = "$web_dir".'/Tiny_plot/'."$sname".'_tiny.gif';

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $out_name2");

	system("mv pgplot.ps $web_dir/Ps_dir/$out_name");
}	
	
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

	$uyday = $uday + $add;
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
                if($atemp[0] eq $sname){
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
### plot_box: plotting a box around radiation zone          ###
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
                $yt    = 0.05*$ydiff;
                $ytop  = $ymin + $yt;
                pgsfs(4);
                pgrect($r_start, $r_end, $ymin, $ytop);
                pgsfs(1);
        }
        pgsci(1);
}


