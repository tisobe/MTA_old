#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#   alignment_sim_twist_extract_year_plot.perl: plot extracted sim dy, dz, dtheta 	#
#					        for one year long period		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Aug 04,  2014						#
#											#
#########################################################################################

#
#---- check whether this is a test
#
OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

############################################################
#---- set directries
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

############################################################

if($comp_test =~ /test/i){
	$line = `cat $house_keeping/test_data_interval`;
	@atemp = split(/\s+|\t+/, $line);
	@btemp = split(/\,/, $atemp[1]);
	@ctemp = split(/\//, $btemp[0]);
	$year  = $ctemp[0];
	$month = $ctemp[1];
}else{
	$year = $ARGV[0];
	chomp $year;
}

	
$chk = 0;

if($year eq ''){
#
#----  update the html page
#

        ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        $year  = 1900   + $uyear;
        $month = $umon  + 1;

        $line = "<br><H3> Last Update: $month/$umday/$year</H3>";
	$chk = 1;
}

if($month == 1 && $chk == 1){

#
#--- if this is the first month of the year, create the last year's plot
#

	$tyear = $year;
	$year = $year -1;

	$name1 = "data_extracted_$tyear";
	$name2 = "data_extracted_$year";

	system("cat $name1 >> $name2");
	system("rm -rf $name1");

	$name1 = "data_info_$tyear";
	$name2 = "data_info_$year";

	system("cat $name1 >> $name2");

	system("rm -rf $name1");

	$input_file = 'data_extracted_'."$year";
	$input_file2 = 'data_info_'."$year";

	plot_data();
}else{
	$input_file = 'data_extracted_'."$year";
	$input_file2 = 'data_info_'."$year";
	
	
	$test = `ls -d`;
	if($test !~ /Sim_twist_temp/){
		system("mkdir -p ./Sim_twist_temp");
	}
	
	plot_data();
}


system("rm -rf ./Sim_twist_temp");

##########################################################################
### plot_data: plotting data                                           ###
##########################################################################

sub plot_data{

	$in_list = `ls $data_dir/$input_file`;
	@data_file = split(/\s+/, $in_list);

	@time   = ();
	@dy     = ();
	@dz     = ();
	@dtheta = ();
	@dt_a_i = ();
	@dt_a_s = ();
	@dt_h_i = ();
	@dt_h_s = ();
	@dm_a_i = ();
	@dm_a_s = ();
	@dm_h_i = ();
	@dm_h_s = ();
	$dcnt   = 0;
	$dn_a_i = 0;
	$dn_a_s = 0;
	$dn_h_i = 0;
	$dn_h_s = 0;
	foreach $ent (@data_file){
		open(FH, "$ent");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			$add = 0;
			if($year > 2000){
        			$add = int(0.25 * ($year - 2001)) + 1;
			}
			$sub = 365 * ($year - 1998) + $add;
			$doy = $atemp[0]/86400 - $sub;
			$atemp[5] *= 3600;
			push(@time,   $doy);
			push(@dy,     $atemp[3]);
			push(@dz,     $atemp[4]);
			push(@dtheta, $atemp[5]);
			if($atemp[2] =~ /ACIS-I/i){
				push(@dt_a_i, $atemp[5]);
				push(@dm_a_i, $doy);
				$dn_a_i++;
			}elsif($atemp[2] =~ /ACIS-S/i){
				push(@dt_a_s, $atemp[5]);
				push(@dm_a_s, $doy);
				$dn_a_s++;
			}elsif($atemp[2] =~ /HRC-I/i){
				push(@dt_h_i, $atemp[5]);
				push(@dm_h_i, $doy);
				$dn_h_i++;
			}elsif($atemp[2] =~ /HRC-S/i){
				push(@dt_h_s, $atemp[5]);
				push(@dm_h_s, $doy);
				$dn_h_s++;
			}
			$dcnt++;
		}
		close(FH);
	}


	$in_list = `ls $data_dir/$input_file2`;
	@data_file = split(/\s+/, $in_list);

	@date     = ();
	@sim_x    = ();
	@sim_y    = ();
	@sim_z    = ();
	@pitchamp = ();
	@yawamp   = ();
	$icnt     = 0;

	foreach $ent (@data_file){
		open(FH, "$ent");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			@btemp = split(/T/, $atemp[3]);
			@ctemp = split(/-/, $btemp[0]);
			$year = $ctemp[0];
			$month = $ctemp[1];
			$date  = $ctemp[2];
			@dtemp = split(/:/, $btemp[1]);
			$hour  = $dtemp[0];
			$min   = $dtemp[1];
			$sec   = $dtemp[2];	
			
			$dyear = $year - 2000;
			$year_day = 365 * $dyear + 163;
			if($year > 2000) {
				$year_day++;
			}
			if($year > 2004) {
				$year_day++;
			}
			if($year > 2008) {
				$year_day++;
			}
			if($year > 2012) {
				$year_day++;
			}
			if($month == 1){
				$add = 0;
			}elsif($month == 2){
				$add = 31;
			}elsif($month == 3){
				$add = 59;
			}elsif($month == 4){
				$add = 90;
			}elsif($month == 5){
				$add = 120;
			}elsif($month == 6){
				$add = 151;
			}elsif($month == 7){
				$add = 181;
			}elsif($month == 8){
				$add = 212;
			}elsif($month == 9){
				$add = 243;
			}elsif($month == 10){
				$add = 273;
			}elsif($month == 11){
				$add = 304;
			}elsif($month == 12){
				$add = 334;
			}
			if($year == 2000 || $year == 2004 || $year == 2008 || $year == 2012 || $year == 2016  || $year == 2020){
				if($month > 2){
					$add++;
				}
			}
			$add += $year_day;
			$add += $date;
			$add += ($hour/24 + $min/1440 + $sec/86400);
	
			push(@date,     $add);
			push(@sim_x,    $atemp[5]);
			push(@sim_y,    $atemp[6]);
			push(@sim_z,    $atemp[7]);
			push(@pitchamp, $atemp[8]);
			push(@yawamp,   $atemp[9]);
			$icnt++;
		}
		close(FH);
	}

	$xmin  = $date[0];
	$xmax  = $date[$icnt -1];
	$xdiff = $xmax - $xmin;
	$xmin  = $xmin - 0.01 * $xdiff;
	if($xmin < 0){
		$xmin = 0;
	}
	$xmax  = $xmax + 0.01 * $xdiff;
	$xmid  = $xmin + 0.50 * $xdiff;
	$xside = $xmin - 0.10 * $xdiff;
	$xside2= $xmin - 0.12 * $xdiff;
			
#	@temp        = sort{$a<=>$b} @sim_x;
#	$ymin_sim_x  = $temp[0];
#	$ymax_sim_x  = $temp[$icnt -1];

	$sum1 = 0;
	$sum2 = 0;
	for($j = 0; $j < $icnt; $j++){
		$sum1 += $sim_x[$j];
		$sum2 += $sim_x[$j] * $sim_x[$j];
	}
	$tavg = $sum1/$icnt;
	$tsig = sqrt($sum2/$icnt - $tavg * $tavg);
	$ymin_sim_x = $tavg - 4.0* $tsig;
	$ymax_sim_x = $tavg + 4.0* $tsig;

	$ydiff       = abs($ymax_sim_x - $ymin_sim_x);
	$ymin_sim_x  = $ymin_sim_x - 0.01 * $ydiff;
	$ymax_sim_x  = $ymax_sim_x + 0.01 * $ydiff;
	$ymid_sim_x  = $ymin_sim_x + 0.50 * $ydiff;
	$yside_sim_x = $ymin_sim_x + 0.50 * $ydiff;
	$ytop_sim_x  = $ymax_sim_x + 0.05 * $ydiff;
	$ybot_sim_x  = $ymin_sim_x - 0.20 * $ydiff;

#	@temp        = sort{$a<=>$b} @sim_y;
#	$ymin_sim_y  = $temp[0];
#	$ymax_sim_y  = $temp[$icnt -3];

	$sum1 = 0;
	$sum2 = 0;
	for($j = 0; $j < $icnt; $j++){
		$sum1 += $sim_y[$j];
		$sum2 += $sim_y[$j] * $sim_y[$j];
	}
	$tavg = $sum1/$icnt;
	$tsig = sqrt($sum2/$icnt - $tavg * $tavg);
	$ymin_sim_y = $tavg - 4.0* $tsig;
	$ymax_sim_y = $tavg + 4.0* $tsig;

	$ydiff       = abs($ymax_sim_y - $ymin_sim_y);
	if($ydiff == 0){
		$ymin_sim_y =-0.05;
		$ymax_sim_y = 0.05;
		$ydiff      = 0.10;
	}
	$ymin_sim_y  = $ymin_sim_y - 0.01 * $ydiff;
	$ymax_sim_y  = $ymax_sim_y + 0.01 * $ydiff;
	$ymid_sim_y  = $ymin_sim_y + 0.50 * $ydiff;
	$yside_sim_y = $ymin_sim_y + 0.50 * $ydiff;
	$ytop_sim_y  = $ymax_sim_y + 0.05 * $ydiff;
	$ybot_sim_y  = $ymin_sim_y - 0.20 * $ydiff;

#	@temp        = sort{$a<=>$b} @sim_z;
#	$ymin_sim_z  = $temp[0];
#	$ymax_sim_z  = $temp[$icnt -1];

	$sum1 = 0;
	$sum2 = 0;
	for($j = 0; $j < $icnt; $j++){
		$sum1 += $sim_z[$j];
		$sum2 += $sim_z[$j] * $sim_z[$j];
	}
	$tavg = $sum1/$icnt;
	$tsig = sqrt($sum2/$icnt - $tavg * $tavg);
	$ymin_sim_z = $tavg - 4.0* $tsig;
	$ymax_sim_z = $tavg + 4.0* $tsig;

	$ydiff       = abs($ymax_sim_z - $ymin_sim_z);
	$ymin_sim_z  = $ymin_sim_z - 0.01 * $ydiff;
	$ymax_sim_z  = $ymax_sim_z + 0.01 * $ydiff;
	$ymid_sim_z  = $ymin_sim_z + 0.50 * $ydiff;
	$yside_sim_z = $ymin_sim_z + 0.50 * $ydiff;
	$ytop_sim_z  = $ymax_sim_z + 0.05 * $ydiff;
	$ybot_sim_z  = $ymin_sim_z - 0.20 * $ydiff;
	
	@ptemp = ();
	foreach $ent (@pitchamp){
		$ent *= 3600;	
		push(@ptemp, $ent);
	}
	@pitchamp = @ptemp;

	@temp           = sort{$a<=>$b} @pitchamp;
	$ymin_pitchamp  = $temp[0];
	$ymax_pitchamp  = $temp[$icnt -10];
$ymax_pitchamp = 70;
$ymin_pitchamp = 0.0;
	$ydiff          = abs($ymax_pitchamp - $ymin_pitchamp);
	$ymin_pitchamp  = $ymin_pitchamp - 0.01 * $ydiff;
	$ymax_pitchamp  = $ymax_pitchamp + 0.01 * $ydiff;
	$ymid_pitchamp  = $ymin_pitchamp + 0.50 * $ydiff;
	$yside_pitchamp = $ymin_pitchamp + 0.50 * $ydiff;
	$ytop_pitchamp  = $ymax_pitchamp + 0.05 * $ydiff;
	$ybot_pitchamp  = $ymin_pitchamp - 0.20 * $ydiff;

	@ptemp = ();
	foreach $ent (@yawamp){
		$ent *= 3600;	
		push(@ptemp, $ent);
	}
	@yawamp = @ptemp;

	@temp         = sort{$a<=>$b} @yawamp;
	$ymin_yawamp  = $temp[0];
	$ymax_yawamp  = $temp[$icnt -10];
$ymax_yawamp = 70;
$ymin_yawamp = 0.0;
	$ydiff        = abs($ymax_yawamp - $ymin_yawamp);
	$ymin_yawamp  = $ymin_yawamp - 0.01 * $ydiff;
	$ymax_yawamp  = $ymax_yawamp + 0.01 * $ydiff;
	$ymid_yawamp  = $ymin_yawamp + 0.50 * $ydiff;
	$yside_yawamp = $ymin_yawamp + 0.50 * $ydiff;
	$ytop_yawamp  = $ymax_yawamp + 0.05 * $ydiff;
	$ybot_yawamp  = $ymin_yawamp - 0.20 * $ydiff;


	pgbegin(0, '"./Sim_twist_temp/pgplot.ps"/cps',1,1);
	pgsch(1);
	pgslw(3);

	$color  = 2;
	$symbol = 1;

	$total = $icnt;
	@xbin  = @date;

	pgsvp(0.1, 0.95, 0.82,1.0);
	pgswin($xmin, $xmax, $ymin_sim_x, $ymax_sim_x);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgsch(0.8);
	pgptxt($xside,$ymid_sim_x, 90.0, 0.5, "sim_x (mm)");
	pgsch(1);
	@ybin = @sim_x;
	plot_fig();

	$color = 4;

	pgsvp(0.1, 0.95, 0.63,0.81);
	pgswin($xmin, $xmax, $ymin_sim_y, $ymax_sim_y);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgsch(0.8);
	pgptxt($xside,$ymid_sim_y, 90.0, 0.5, "sim_y (mm)");
	pgsch(1.0);
	@ybin = @sim_y;
	plot_fig();

	$color = 2;

	pgsvp(0.1, 0.95, 0.44,0.62);
	pgswin($xmin, $xmax, $ymin_sim_z, $ymax_sim_z);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgsch(0.8);
	pgptxt($xside,$ymid_sim_z, 90.0, 0.5, "sim_z (mm)");
	pgsch(1.0);
	@ybin = @sim_z;
	plot_fig();

	$color = 4;

	pgsvp(0.1, 0.95, 0.25,0.43);
	pgswin($xmin, $xmax, $ymin_pitchamp, $ymax_pitchamp);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgsch(0.8);
	pgptxt($xside,$ymid_pitchamp, 90.0, 0.5, "pitchamp (second)");
	pgsch(1.0);
	@ybin = @pitchamp;
	plot_fig();

	$color = 2;

	pgsvp(0.1, 0.95, 0.06,0.24);
	pgswin($xmin, $xmax, $ymin_yawamp, $ymax_yawamp);
	pgbox(ABCNSTV,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgsch(0.8);
	pgptxt($xside,$ymid_yawamp, 90.0, 0.5, "yawamp (second)");
	pgsch(1.0);
	@ybin = @yawamp;
	plot_fig();

	pgptxt($xmin,$ybot_yawamp, 0.0, 1.0, "Time (DOY)");
	pgclos();

#	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/sim_plot_$year.gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|pnmflip -r270 |ppmtogif > $web_dir/Plots/sim_plot_$year.gif");

#
#---- sim twist plot starts here
#
	
	@xbin        = @time;
	$xmin        = $time[0];
	$xmax        = $time[$dcnt -1];
$xmin = 0; 
$xmax = 366;
	$xhalf       = 0.5 * ($xmax + $xmin);
	$xdiff       = $xmax - $xmin;
	$xmid  	     = $xmin + 0.50 * $xdiff;
	$xside       = $xmin - 0.08 * $xdiff;
	$xside2      = $xmin - 0.12 * $xdiff;

	$ymin_dy     = -0.1;
	$ymax_dy     =  0.1;
	$ymin_dz     = -0.1;
	$ymax_dz     =  0.1;
	$ymin_dtheta = -0.1;
	$ymax_dtheta =  0.1;
	$ydiff       =  0.2;

	if($dcnt > 0){
#
#------ dy
#
		$sum  = 0;
		$sum2 = 0;
		OUTER:
		foreach $ent (@dy){
			if(abs($ent) > 10){
				next OUTER;
			}
			$sum  += $ent;
			$sum2 += $ent * $ent;
		}
		$avg = $sum/$dcnt;
		$std = sqrt($sum2/$dcnt - $avg * $avg);
		$ymin_dy = $avg - 3.0 * $std;
		$ymax_dy = $avg + 3.0 * $std;
		$ydiff   = abs($ymax_dy - $ymin_dy);
		if($ydiff > 0){
			$ymin_dy = $ymin_dy - 0.01 * $ydiff;
			$ymax_dy = $ymax_dy + 0.01 * $ydiff;
		}
		$ymid_dy      = $ymin_dy + 0.50 * $ydiff;
		$yside_dy     = $ymin_dy + 0.50 * $ydiff;
		$ytop_dy      = $ymax_dy + 0.05 * $ydiff;
		$ybot_dy      = $ymin_dy - 0.20 * $ydiff;

		@plotx1 = ();
		@ploty1 = ();
		@plotx2 = ();
		@ploty2 = ();
		$pcnt1  = 0;
		$pcnt2  = 0;
		OUTER:
		for($i = 0; $i < $dcnt; $i++){
			if(abs($dy[$i]) > 10){
				next OUTER;
			} 
			if($year == 2003 && $time[$i] < 170){
				push(@plotx1, $time[$i]);
				push(@ploty1, $dy[$i]);
				$pcnt1++;
			}else{
				push(@plotx2, $time[$i]);
				push(@ploty2, $dy[$i]);
				$pcnt2++;
			}
		}
		if($pcnt1 > 0 && $pcnt2 > 0){
			@xbin  = @plotx1;
			@ybin  = @ploty1;
			$total = $pcnt1;
			least_fit();
			$dy_int1   = $s_int;
			$dy_slope1 = $slope;
			$dy_disp1 = sprintf "%4.3e", $slope;
	
			@xbin  = @plotx2;
			@ybin  = @ploty2;
			$total = $pcnt2;
			least_fit();
			$dy_int2   = $s_int;
			$dy_slope2 = $slope;
			$dy_disp2 = sprintf "%4.3e", $slope;
		}elsif($pcnt1 > 0){
			@xbin  = @plotx1;
			@ybin  = @ploty1;
			$total = $pcnt1;
			least_fit();
			$dy_int1   = $s_int;
			$dy_slope1 = $slope;
			$dy_disp1 = sprintf "%4.3e", $slope;
		}elsif($pcnt2 > 0){
			@xbin  = @plotx2;
			@ybin  = @ploty2;
			$total = $pcnt2;
			least_fit();
			$dy_int1   = $s_int;
			$dy_slope1 = $slope;
			$dy_disp1 = sprintf "%4.3e", $slope;
		}
#
#------ dz
#
		$sum  = 0;
		$sum2 = 0;
		OUTER:
		foreach $ent (@dz){
			if(abs($ent) > 10){
				next OUTER;
			}
			$sum  += $ent;
			$sum2 += $ent * $ent;
		}
		$avg = $sum/$dcnt;
		$std = sqrt($sum2/$dcnt - $avg * $avg);
		$ymin_dz = $avg - 3.0 * $std;
		$ymax_dz = $avg + 3.0 * $std;
		$ydiff   = $ymax_dz - $ymin_dz;
		if($ydiff > 0){
			$ymin_dz = $ymin_dz - 0.01 * $ydiff;
			$ymax_dz = $ymax_dz + 0.01 * $ydiff;
		}
		$ymid_dz      = $ymin_dz + 0.50 * $ydiff;
		$yside_dz     = $ymin_dz + 0.50 * $ydiff;
		$ytop_dz      = $ymax_dz + 0.05 * $ydiff;
		$ybot_dz      = $ymin_dz - 0.20 * $ydiff;

		@plotx1 = ();
		@ploty1 = ();
		@plotx2 = ();
		@ploty2 = ();
		$pcnt1  = 0;
		$pcnt2  = 0;
		OUTER:
		for($i = 0; $i < $dcnt; $i++){
			if(abs($dz[$i]) >10){
				next OUTER;
			}
			if($year == 2003 && $time[$i] < 170){
				push(@plotx1, $time[$i]);
				push(@ploty1, $dz[$i]);
				$pcnt1++;
			}else{
				push(@plotx2, $time[$i]);
				push(@ploty2, $dz[$i]);
				$pcnt2++;
			}
		}
		if($pcnt1 > 0 && $pcnt2 > 0){
			@xbin  = @plotx1;
			@ybin  = @ploty1;
			$total = $pcnt1;
			least_fit();
			$dz_int1   = $s_int;
			$dz_slope1 = $slope;
			$dz_disp1 = sprintf "%4.3e", $slope;

			@xbin  = @plotx2;
			@ybin  = @ploty2;
			$total = $pcnt2;
			least_fit();
			$dz_int2   = $s_int;
			$dz_slope2 = $slope;
			$dz_disp2 = sprintf "%4.3e", $slope;
		}elsif($pcnt1 > 0){
			@xbin  = @plotx1;
			@ybin  = @ploty1;
			$total = $pcnt1;
			least_fit();
			$dz_int1   = $s_int;
			$dz_slope1 = $slope;
			$dz_disp1 = sprintf "%4.3e", $slope;
		}elsif($pcnt2 > 0){
			@xbin  = @plotx2;
			@ybin  = @ploty2;
			$total = $pcnt2;
			least_fit();
			$dz_int1   = $s_int;
			$dz_slope1 = $slope;
			$dz_disp1 = sprintf "%4.3e", $slope;
		}

#
#----- dtheta
#
		$sum  = 0;
		$sum2 = 0;

		foreach $ent (@dtheta){
			$sum  += $ent;
			$sum2 += $ent * $ent;
		}

		$avg = $sum/$dcnt;
		$std = sqrt($sum2/$dcnt - $avg * $avg);
		$ymin_dtheta = $avg - 3.0 * $std;
		$ymax_dtheta = $avg + 3.0 * $std;
$ymin_dtheta = -80;
$ymax_dtheta =  80;
		$ydiff       = $ymax_dtheta - $ymin_dtheta;
		if($ydiff > 0){
			$ymin_dtheta = $ymin_dtheta - 0.01 * $ydiff;
			$ymax_dtheta = $ymax_dtheta + 0.01 * $ydiff;
		}
		$ymid_dtheta  = $ymin_dtheta + 0.50 * $ydiff;
		$yside_dtheta = $ymin_dtheta + 0.50 * $ydiff;
		$ytop_dtheta  = $ymax_dtheta + 0.05 * $ydiff;
		$ybot_dtheta  = $ymin_dtheta - 0.20 * $ydiff;

		@xbin  = @time;
		@ybin  = @dtheta;
		$total = $dcnt;
		least_fit();
		$dtheta_int   = $s_int;
		$dtheta_slope = $slope;
		$dtheta_disp = sprintf "%4.3e", $slope;
	}

	system("rm -rf ./Sim_twist_temp/pgplot.ps");

	pgbegin(0,'"./Sim_twist_temp/pgplot.ps"/cps',1,1);

	pgsch(1);
	pgslw(3);

	$total = $dcnt;
	$color = 2;

	pgsvp(0.1, 0.95, 0.70,0.95);
	pgswin($xmin, $xmax, $ymin_dy, $ymax_dy);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgptxt($xside,$ymid_dy, 90.0, 0.5, "dy (mm)");
	@ybin = @dy;
	plot_fig();

	pgsci(3);
	if($pcnt1 > 0 && $pcnt2 > 0){
		$ymin = $dy_int1 + $dy_slope1 * $xmin;
		$ymax = $dy_int1 + $dy_slope1 * 170;
		pgmove($xmin, $ymin);
		pgdraw(170, $ymax);
		$ymin = $dy_int2 + $dy_slope2 * 170;
		$ymax = $dy_int2 + $dy_slope2 * $xmax;
		pgmove(170, $ymin);
		pgdraw($xmax, $ymax);
		pgsci(1);
		$xdpos = $xmin + 0.04 * $xdiff;
		$diff  = $ymax_dy - $ymin_dy;
		$ytop1 = $ymax_dy - 0.10 * $diff; 
		$ytop2 = $ymax_dy - 0.20 * $diff; 
		pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope (doy < 170): $dy_disp1");
		pgptxt($xdpos,$ytop2, 0.0, 0.0, "Slope (doy > 170): $dy_disp2");
	}else{
		$ymin = $dy_int1 + $dy_slope1 * $xmin;
		$ymax = $dy_int1 + $dy_slope1 * $xmax;
		pgmove($xmin, $ymin);
		pgdraw($xmax, $ymax);
		pgsci(1);
		$xdpos = $xmin + 0.04 * $xdiff;
		$diff  = $ymax_dy - $ymin_dy;
		$ytop1 = $ymax_dy - 0.10 * $diff; 
		pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope: $dy_disp1");
	}

	$color = 2;

	pgsvp(0.1, 0.95, 0.43,0.68);
	pgswin($xmin, $xmax, $ymin_dz, $ymax_dz);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgptxt($xside,$ymid_dz, 90.0, 0.5, "dz (mm)");
	@ybin = @dz;
	plot_fig();

	pgsci(3);
	if($pcnt1 > 0 && $pcnt2 > 0){
		$ymin = $dz_int1 + $dz_slope1 * $xmin;
		$ymax = $dz_int1 + $dz_slope1 * 170;
		pgmove($xmin, $ymin);
		pgdraw(170, $ymax);
		$ymin = $dz_int2 + $dz_slope2 * 170;
		$ymax = $dz_int2 + $dz_slope2 * $xmax;
		pgmove(170, $ymin);
		pgdraw($xmax, $ymax);
		pgsci(1);
		$xdpos = $xmin + 0.04 * $xdiff;
		$diff  = $ymax_dz - $ymin_dz;
		$ytop1 = $ymax_dz - 0.10 * $diff; 
		$ytop2 = $ymax_dz - 0.20 * $diff; 
		pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope (doy < 170): $dz_disp1");
		pgptxt($xdpos,$ytop2, 0.0, 0.0, "Slope (doy > 170): $dz_disp2");
	}else{
		$ymin = $dz_int1 + $dz_slope1 * $xmin;
		$ymax = $dz_int1 + $dz_slope1 * $xmax;
		pgmove($xmin, $ymin);
		pgdraw($xmax, $ymax);
		pgsci(1);
		$xdpos = $xmin + 0.04 * $xdiff;
		$diff  = $ymax_dz - $ymin_dz;
		$ytop1 = $ymax_dz - 0.10 * $diff; 
		pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope: $dz_disp1");
	}


	$color = 2;

	pgsvp(0.1, 0.95, 0.16,0.41);
	pgswin($xmin, $xmax, $ymin_dtheta, $ymax_dtheta);
	pgbox(ABCNSTV,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgptxt($xside,$ymid_dtheta, 90.0, 0.5, "dtheta (second)");
	@ybin = @dtheta;
	plot_fig();
	pgsci(3);
	$ymin = $dtheta_int + $dtheta_slope * $xmin;
	$ymax = $dtheta_int + $dtheta_slope * $xmax;
	pgmove($xmin, $ymin);
	pgdraw($xmax, $ymax);
	pgsci(1);
	$xdpos = $xmin + 0.04 * $xdiff;
	$diff  = $ymax_dtheta - $ymin_dtheta;
	$ytop1 = $ymax_dtheta - 0.10 * $diff; 
	pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope: $dtheta_disp");

	pgptxt($xmid,$ybot_dtheta, 0.0, 0.5, "Time (DOY)");
	pgclos();

#	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/twist_plot_$year.gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|pnmflip -r270 |ppmtogif > $web_dir/Plots/twist_plot_$year.gif");
	system("rm -rf ./Sim_twist_temp/pgplot.ps");

#
#----- dtheta detail plots (ACIS-I, ACIS-S, HRC-I, HRC-S)
#
	pgbegin(0,'"./Sim_twist_temp/pgplot.ps"/cps',1,1);
	pgsch(1);
	pgslw(3);

	$ped[0] = 0.98;
	$ped[1] = 0.75;
	$ped[2] = 0.52;
	$ped[3] = 0.30;
	
	$pst[0] = 0.76;
	$pst[1] = 0.53;
	$pst[2] = 0.31;
	$pst[3] = 0.08;
	
	$pnl_cnt = 0;

#----- ACIS-I

	if($dn_a_i > 0){
        	@xdata  = @dm_a_i;
        	@ydata  = @dt_a_i;
        	$data_cnt = $dn_a_i;
            if($data_cnt > 3){
        	    robust_fit();
        	    $dt_int   = $int;
        	    $dt_slope = $slope;
        	    $dt_disp  = sprintf "%4.3e", $slope;
            }else{
        	    $dt_int   = 0;
        	    $dt_slope = 0;
        	    $dt_disp  = 0;
            }

		$avg = 0;
		foreach $ent (@ydata){
			$avg += $ent;
		}
		$avg = $int + $slope * $xhalf;
		#$avg /= $data_cnt;
	
		$ymin = $avg - 10;
		$ymax = $avg + 10;
#$ymin = -50;
#$ymax =  50;
        	$ydiff      = $ymax - $ymin;

        	$ymid  = $ymin + 0.50 * $ydiff;
        	$yside = $ymin + 0.50 * $ydiff;
        	$ytop  = $ymax + 0.05 * $ydiff;
        	$ybot  = $ymin + 0.20 * $ydiff;
        	$ytop1 = $ymax - 0.10 * $ydiff;
        	pgsvp(0.15, 0.98, $pst[$pnl_cnt], $ped[$pnl_cnt]);
        	pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
        	pgptxt($xside,$ymid, 90.0, 0.5, "dtheta (second)");
	
		@xbin  = @dm_a_i;
		@ybin  = @dt_a_i;
		$total = $dn_a_i;

        	plot_fig();
	
        	pgsci(3);
        	$ysmin = $dt_int + $dt_slope * $xmin;
        	$ysmax = $dt_int + $dt_slope * $xmax;
        	pgmove($xmin, $ysmin);
        	pgdraw($xmax, $ysmax);
        	pgsci(1);
        	$xdpos = $xmin + 0.04 * $xdiff;
	
        	pgptxt($xdpos,$ytop1, 0.0, 0.0, "ACIS-I      Slope: $dt_disp");
        	$pnl_cnt++;
	}
	
#----- ACIS-S

	if($dn_a_s > 0){
        	@xdata  = @dm_a_s;
        	@ydata  = @dt_a_s;
        	$data_cnt = $dn_a_s;
            if($data_cnt > 3){
        	    robust_fit();
        	    $dt_int   = $int;
        	    $dt_slope = $slope;
        	    $dt_disp  = sprintf "%4.3e", $slope;
            }else{
        	    $dt_int   = 0;
        	    $dt_slope = 0;
        	    $dt_disp  = 0;
            }

		$avg = 0;
		foreach $ent (@ydata){
			$avg += $ent;
		}
		$avg = $int + $slope * $xhalf;
		#$avg /= $data_cnt;
	
		$ymin = $avg - 10;
		$ymax = $avg + 10;
#$ymin = -50;
#$ymax =  50;
        	$ydiff      = $ymax - $ymin;

        	$ymid  = $ymin + 0.50 * $ydiff;
        	$yside = $ymin + 0.50 * $ydiff;
        	$ytop  = $ymax + 0.05 * $ydiff;
        	$ybot  = $ymin + 0.20 * $ydiff;
        	$ytop1 = $ymax - 0.10 * $ydiff;
	
        	@xbin  = @dm_a_s;
        	@ybin  = @dt_a_s;
        	$total = $dn_a_s;
	
        	pgsvp(0.15, 0.98, $pst[$pnl_cnt], $ped[$pnl_cnt]);
        	pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
        	pgptxt($xside,$ymid, 90.0, 0.5, "dtheta (second)");
	
        	plot_fig();
	
        	pgsci(3);
        	$ysmin = $dt_int + $dt_slope * $xmin;
        	$ysmax = $dt_int + $dt_slope * $xmax;
        	pgmove($xmin, $ysmin);
        	pgdraw($xmax, $ysmax);
        	pgsci(1);
        	$xdpos = $xmin + 0.04 * $xdiff;
	
        	pgptxt($xdpos,$ytop1, 0.0, 0.0, "ACIS-S      Slope: $dt_disp");
        	$pnl_cnt++;
	}

#-----  HRC-I

	if($dn_h_i > 0){
        	@xdata  = @dm_h_i;
        	@ydata  = @dt_h_i;
        	$data_cnt = $dn_h_i;
            if($data_cnt > 3){
        	    robust_fit();
        	    $dt_int   = $int;
        	    $dt_slope = $slope;
        	    $dt_disp  = sprintf "%4.3e", $slope;
            }else{
        	    $dt_int   = 0;
        	    $dt_slope = 0;
        	    $dt_disp  = 0;
            }

		$avg = 0;
		foreach $ent (@ydata){
			$avg += $ent;
		}
		$avg = $int + $slope * $xhalf;
		#$avg /= $data_cnt;

	
		$ymin = $avg - 10;
		$ymax = $avg + 10;
#$ymin = -50;
#$ymax =  50;
        	$ydiff      = $ymax - $ymin;

        	$ymid  = $ymin + 0.50 * $ydiff;
        	$yside = $ymin + 0.50 * $ydiff;
        	$ytop  = $ymax + 0.05 * $ydiff;
        	$ybot  = $ymin + 0.20 * $ydiff;
        	$ytop1 = $ymax - 0.10 * $ydiff;
	
        	@xbin  = @dm_h_i;
        	@ybin  = @dt_h_i;
        	$total = $dn_h_i;
	
        	pgsvp(0.15, 0.98, $pst[$pnl_cnt], $ped[$pnl_cnt]);
        	pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
        	pgptxt($xside, $ymid, 90.0, 0.5, "dtheta (second)");
	
        	plot_fig();
	
        	pgsci(3);
        	$ysmin = $dt_int + $dt_slope * $xmin;
        	$ysmax = $dt_int + $dt_slope * $xmax;
        	pgmove($xmin, $ysmin);
        	pgdraw($xmax, $ysmax);
        	pgsci(1);
        	$xdpos = $xmin + 0.04 * $xdiff;
	
        	pgptxt($xdpos,$ytop1, 0.0, 0.0, "HRC-I      Slope: $dt_disp");
        	$pnl_cnt++;
	}

#-----  HRC-S

	if($dn_h_s > 0){
        	@xdata  = @dm_h_s;
        	@ydata  = @dt_h_s;
        	$data_cnt = $dn_h_s;
            if($data_cnt > 3){
        	    robust_fit();
        	    $dt_int   = $int;
        	    $dt_slope = $slope;
        	    $dt_disp  = sprintf "%4.3e", $slope;
            }else{
        	    $dt_int   = 0;
        	    $dt_slope = 0;
        	    $dt_disp  = 0;
            }

		$avg = 0;
		foreach $ent (@ydata){
			$avg += $ent;
		}
		$avg = $int + $slope * $xhalf;
		#$avg /= $data_cnt;

	
		$ymin = $avg - 10;
		$ymax = $avg + 10;
#$ymin = -50;
#$ymax =  50;
        	$ydiff      = $ymax - $ymin;

        	$ymid  = $ymin + 0.50 * $ydiff;
        	$yside = $ymin + 0.50 * $ydiff;
        	$ytop  = $ymax + 0.05 * $ydiff;
        	$ybot  = $ymin + 0.20 * $ydiff;
        	$ybot2 = $ymin - 0.10 * $ydiff;
        	$ytop1 = $ymax - 0.10 * $ydiff;
	
        	@xbin  = @dm_h_s;
        	@ybin  = @dt_h_s;
        	$total = $dn_h_s;
	
        	pgsvp(0.15, 0.98, $pst[$pnl_cnt], $ped[$pnl_cnt]);
        	pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
        	pgptxt($xside, $ymid, 90.0, 0.5, "dtheta (second)");
	
        	plot_fig();
	
        	pgsci(3);
        	$ysmin = $dt_int + $dt_slope * $xmin;
        	$ysmax = $dt_int + $dt_slope * $xmax;
        	pgmove($xmin, $ysmin);
        	pgdraw($xmax, $ysmax);
        	pgsci(1);
        	$xdpos = $xmin + 0.04 * $xdiff;
	
        	pgptxt($xdpos,$ytop1, 0.0, 0.0, "HRC-S      Slope: $dt_disp");
        	$pnl_cnt++;
	}
	pgptxt($xmin, $ybot2, 0.0, 1.0, "Time(DOY)");
	pgclos();
	
#    	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/dtheta_plot_$year.gif");
    	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|pnmflip -r270 |ppmtogif > $web_dir/Plots/dtheta_plot_$year.gif");

}

########################################################
### plot_fig: plotting data points on a fig          ###
########################################################

sub plot_fig{
        pgsci($color);
        for($m = 0; $m < $total; $m++){
                pgpt(1, $xbin[$m], $ybin[$m], $symbol);
        }
        pgsci(1);
}


##########################################################
### least_fit: least sq. fitting  for a straight line ####
##########################################################

sub least_fit {

###########################################################
#  Input:       @xbin:       a list of independent variable
#               @ybin:       a list of dependent variable
#               $total:      # of data points
#
#  Output:      $s_int:      intercept of the line
#               $slope:      slope of the line
#               $sigm_slope: the error on the slope
###########################################################

if($total == 0){
	$s_int = -9999;
	$slope = -9999;
}else{
        my($sum, $sumx, $sumy, $symxy, $sumx2, $sumy2, $tot1);

        $sum   = 0;
        $sumx  = 0;
        $sumy  = 0;
        $sumxy = 0;
        $sumx2 = 0;
        $sumy2 = 0;

        for($fit_i = 0; $fit_i < $total; $fit_i++) {
                $sum++;
                $sumx  += $xbin[$fit_i];
                $sumy  += $ybin[$fit_i];
                $sumx2 += $xbin[$fit_i] * $xbin[$fit_i];
                $sumy2 += $ybin[$fit_i] * $ybin[$fit_i];
                $sumxy += $xbin[$fit_i] * $ybin[$fit_i];
        }

        $delta = $sum * $sumx2 - $sumx * $sumx;
        $s_int = ($sumx2 * $sumy - $sumx * $sumxy)/$delta;
        $slope = ($sumxy * $sum  - $sumx * $sumy) /$delta;

        $tot1 = $total - 1;
        $variance = ($sumy2 + $s_int * $s_int * $sum + $slope * $slope * $sumx2
                        -2.0 *($s_int * $sumy + $slope * $sumxy
                        - $s_int * $slope * $sumx))/$tot1;
        $sigm_slope = sqrt($variance * $sum/$delta);
}
}

##########################################################################################
##########################################################################################
##########################################################################################

sub get_inst_name{
        my $db = "server=$server;database=axafocat";
        $dsn1 = "DBI:Sybase:$db";
        $dbh1 = DBI->connect($dsn1, $db_user, $db_passwd, { PrintError => 0, RaiseError => 1});

        $sqlh1 = $dbh1->prepare(qq(select
                instrument
        from target where obsid=$obsid));

       $sqlh1->execute();
        @targetdata = $sqlh1->fetchrow_array;
        $sqlh1->finish;



        $instrument = $targetdata[0];
        $instrument =~ s/\s//g;

}

####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
        $sumx = 0;
        $symy = 0;
        for($n = 0; $n < $data_cnt; $n++){
                $sumx += $xdata[$n];
                $symy += $ydata[$n];
        }
        $xavg = $sumx/$data_cnt;
        $yavg = $sumy/$data_cnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
        @xbin = ();
        @ybin = ();
        for($n = 0; $n < $data_cnt; $n++){
                $xbin[$n] = $xdata[$n] - $xavg;
                $ybin[$n] = $ydata[$n] - $yavg;
        }

        $total = $data_cnt;
	if($total > 0){
        	medfit();

        	$alpha += $beta * (-1.0 * $xavg) + $yavg;

        	$int   = $alpha;
        	$slope = $beta;
	}else{
		$int   = 0;
		$slope = 0;
	}
}


####################################################################
### medfit: robust filt routine                                  ###
####################################################################

sub medfit{

#########################################################################
#                                                                       #
#       fit a straight line according to robust fit                     #
#       Numerical Recipes (FORTRAN version) p.544                       #
#                                                                       #
#       Input:          @xbin   independent variable                    #
#                       @ybin   dependent variable                      #
#                       total   # of data points                        #
#                                                                       #
#       Output:         alpha:  intercept                               #
#                       beta:   slope                                   #
#                                                                       #
#       sub:            rofunc evaluate SUM( x * sgn(y- a - b * x)      #
#                       sign   FORTRAN/C sign function                  #
#                                                                       #
#########################################################################

        my $sx  = 0;
        my $sy  = 0;
        my $sxy = 0;
        my $sxx = 0;

        my (@xt, @yt, $del,$bb, $chisq, $b1, $b2, $f1, $f2, $sigb);
#
#---- first compute least sq solution
#
        for($j = 0; $j < $total; $j++){
                $xt[$j] = $xbin[$j];
                $yt[$j] = $ybin[$j];
                $sx  += $xbin[$j];
                $sy  += $ybin[$j];
                $sxy += $xbin[$j] * $ybin[$j];
                $sxx += $xbin[$j] * $xbin[$j];
        }

        $del = $total * $sxx - $sx * $sx;
#
#----- least sq. solutions
#
        $aa = ($sxx * $sy - $sx * $sxy)/$del;
        $bb = ($total * $sxy - $sx * $sy)/$del;
        $asave = $aa;
        $bsave = $bb;

        $chisq = 0.0;
        for($j = 0; $j < $total; $j++){
                $diff   = $ybin[$j] - ($aa + $bb * $xbin[$j]);
                $chisq += $diff * $diff;
        }
        $sigb = sqrt($chisq/$del);
        $b1   = $bb;
        $f1   = rofunc($b1);
        $b2   = $bb + sign(3.0 * $sigb, $f1);
        $f2   = rofunc($b2);

        $iter = 0;
        OUTER:
        while($f1 * $f2 > 0.0){
                $bb = 2.0 * $b2 - $b1;
                $b1 = $b2;
                $f1 = $f2;
                $b2 = $bb;
                $f2 = rofunc($b2);
                $iter++;
                if($iter > 100){
                        last OUTER;
                }
        }

        $sigb *= 0.01;
        $iter = 0;
        OUTER1:
        while(abs($b2 - $b1) > $sigb){
                $bb = 0.5 * ($b1 + $b2);
                if($bb == $b1 || $bb == $b2){
                        last OUTER1;
                }
                $f = rofunc($bb);
                if($f * $f1 >= 0.0){
                        $f1 = $f;
                        $b1 = $bb;
                }else{
                        $f2 = $f;
                        $b2 = $bb;
                }
                $iter++;
                if($iter > 100){
                        last OTUER1;
                }
        }
        $alpha = $aa;
        $beta  = $bb;
        if($iter >= 100){
                $alpha = $asave;
                $beta  = $bsave;
        }
        $abdev = $abdev/$total;
}

##########################################################
### rofunc: evaluatate 0 = SUM[ x *sign(y - a bx)]     ###
##########################################################

sub rofunc{
        my ($b_in, @arr, $n1, $nml, $nmh, $sum);

        ($b_in) = @_;
        $n1  = $total + 1;
        $nml = 0.5 * $n1;
        $nmh = $n1 - $nml;
        @arr = ();
        for($j = 0; $j < $total; $j++){
                $arr[$j] = $ybin[$j] - $b_in * $xbin[$j];
        }
        @arr = sort{$a<=>$b} @arr;
        $aa = 0.5 * ($arr[$nml] + $arr[$nmh]);
        $sum = 0.0;
        $abdev = 0.0;
        for($j = 0; $j < $total; $j++){
                $d = $ybin[$j] - ($b_in * $xbin[$j] + $aa);
                $abdev += abs($d);
                $sum += $xbin[$j] * sign(1.0, $d);
        }
        return($sum);
}


##########################################################
### sign: sign function                                ###
##########################################################

sub sign{
        my ($e1, $e2, $sign);
        ($e1, $e2) = @_;
        if($e2 >= 0){
                $sign = 1;
        }else{
                $sign = -1;
        }
        return $sign * $e1;
}

