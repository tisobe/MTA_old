#!/usr/bin/env /usr/local/bin/perl

use DBI;
use DBD::Sybase;

#########################################################################################
#											#
#	alignment_sim_twist_extract.perl: extract dy, dz, and dtheta value, and         #
#			                  make trend plots				#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Sep 03, 2014 	 					#
#											#
#########################################################################################

#
#--- checking whether this is a test
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

#$ds = '/proj/cm/Integ/install.linux64.DS8.5/bin/';
####$ds = '/home/ascds/DS.test/bin/';

############################################################

#
#---- two possible input; one from a data file telling date interval to compute
#---- another is to get one month interval from the 1st of the last month to
#---- the last day of the last month. Here we assume that the script is run on
#---- the first of the new month.
#
$db_user   = "browser";
$server    = "ocatsqlsrv";
$db_passwd = 'newuser';

$file = $ARGV[0];		# if you want to use a data file, here is the input	e.g.2011/01/01,00:00:00\t2011/02/01,00:00:00
				# you can have multiple lines of the same format

if($file ne ''){
	if($comp_test =~ /test/i){
		open(FH, "$house_keeping/test_data_interval");			#--- this is a test interval.
	}else{
		open(FH, "$file");
	}
	@date_list = ();
	while(<FH>){
		chomp $_;
		push(@date_list, $_);
	}
	close(FH);

    @atemp = split(/\//, $date_list[0]);
    $lyear = $atemp[0];

}else{
#
#---- otherwise, take a month interval
#


#
#---- find today's date
#---- and set data colleciton interveral--- a last month
#

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
	$umon++;
	$year = $uyear + 1900;

	if($umon < 10){
		$month = "0$umon";
	}else{
		$month = $umon;
	}
	$lmonth = $umon -1;
	if($lmonth < 10){
		$lmonth = "0$lmonth";
	}
	$lyear  = $year;
	if($lmonth < 1){
		$lmonth = 12;
		$lyear  = $year -1;
	}

	$start = "$lyear"."/$lmonth".'/01'.',00:00:00';
	$stop  = "$year"."/$month".'/01'.',00:00:00';
	$line = "$start\t$stop\n";
	@date_list = ("$line");
}


open(FH, "$bdata_dir/.hakama");
while(<FH>){
       	chomp $_;
       	$hakama = $_;
       	$hakama =~ s/\s+//g;
}
close(FH);

open(FH, "$bdata_dir/.dare");
while(<FH>){
       	chomp $_;
       	$dare = $_;
       	$dare =~ s/\s+//g;
}
close(FH);

#
#---- create a temporary directory for computation, if there is not one.
#

$alist = `ls -d *`;
@dlist = split(/\s+/, $alist);

OUTER:
foreach $dir (@dlist){
	if($dir =~ /param/){
		system("rm -rf ./param");
		last OUTER;
	}
}

system('mkdir ./param');

OUTER:
foreach $dir (@dlist){
	if($dir =~ /Sim_twist_temp/){
		system("rm  -rf ./Sim_twist_temp");
		last OUTER;
	}
}

system('mkdir -p ./Sim_twist_temp');


#
#--- here we actually start computation
#

foreach $line (@date_list){
	@atemp = split(/\s+/, $line);
	$tstart = $atemp[0];
	$tstop  = $atemp[1];

#
#---- input file for arc4gl
#
	open(OUT, '>./Sim_twist_temp/input_line');
	print OUT "operation=browse\n";
	print OUT "dataset=flight\n";
	print OUT "detector=pcad\n";
	print OUT "subdetector=aca\n";
	print OUT "level=1\n";
#	print OUT "version=last\n";
	print OUT "tstart=$tstart\n";
	print OUT "tstop=$tstop\n";
	print OUT "go\n";
	close(OUT);

	system('rm  -rf ./Sim_twist_temp/*fits');
	system("cd ./Sim_twist_temp; echo $hakama  |arc4gl -U$dare -Sarcocc -i./input_line > zaca"); 
	system('rm -rf ./Sim_twist_temp/input_line');
	$alist  = `cat ./Sim_twist_temp/zaca |grep asol`;	#---- extract asol file names and make a list
	system('rm -rf ./Sim_twist_temp/zaca');

	@alist  = split(/\s+/, $alist);
	@asol_list = ();
	foreach $ent (@alist){
		if($ent =~ /asol/){
			push(@asol_list, $ent);
		}
	}

	foreach $in_file (@asol_list){
		open(OUT, '>./Sim_twist_temp/input_line');
		print OUT "operation=retrieve\n";
		print OUT "dataset=flight\n";
		print OUT "detector=pcad\n";
		print OUT "subdetector=aca\n";
		print OUT "level=1\n";
		print OUT "filename=$in_file\n";
		print OUT "go\n";
		close(OUT);

		system('rm -rf ./Sim_twist_temp/*fits');
		system("cd ./Sim_twist_temp; echo $hakama  |arc4gl -U$dare -Sarcocc -i./input_line"); 
		system('rm -rf ./Sim_twist_temp/input_line');
		system("gzip -d ./Sim_twist_temp/*gz");

        $test = `ls ./Sim_twist_temp/`;             #--- test added 09/03/14
        if($test =~ /$in_file/){
		    $name = "./Sim_twist_temp/$in_file";
		    @list = ("$name");
        }
#
#----- here is actual data extract sub
#
		extract_data();
	}
}

#
#----- plot routine
#

####plot_data();
##print_html();
####system('rm -rf  ./Sim_twist_temp ./param');

###################################################################################
### extract_data: read fits file, and extract needed data columns               ###
###################################################################################

sub extract_data{

	$cnt    = 0;
	$total  = 0;
	@time   = ();
	@dy     = ();
	@dz     = ();
	@dtheta = ();
#
#-------data_extracted contains a list of time, dy, dz, and dtheta
#-------data_info contains the file information, such as sim_position
#
$out_name1 = 'data_extracted_'."$lyear";
$out_name2 = 'data_info_'."$lyear";
	open(OUT,  ">> $data_dir/$out_name1");
	open(OUT2, ">> $data_dir/$out_name2");

	foreach $file (@list){

#
#---- use fdump to extact the part we need
#
#
##-NOTE: when update, check existance of "$file" before dmlist  (noted 07/05/13)
#
		system("dmlist infile=$file outfile=./Sim_twist_temp/zout opt=head");
		open(FH, "./Sim_twist_temp/zout");
		while(<FH>){
			chomp $_;
			@btemp = split(/\s+/, $_);
			if($_ =~ /DATE-OBS/){
				$date_obs = $btemp[2];
			}elsif($_ =~ /DATE-END/){
				$date_end = $btemp[2];
			}elsif($_ =~ /SIM_X/){
				$sim_x = $btemp[2];
			}elsif($_ =~ /SIM_Y/){
				$sim_y = $btemp[2];
			}elsif($_ =~ /SIM_Z/){
				$sim_z = $btemp[2];
			}elsif($_ =~ /PITCHAMP/){
				$pitchamp = $btemp[2];
			}elsif($_ =~ /YAWAMP/){
				$yawamp = $btemp[2];
			}elsif($_ =~ /OBS_ID/){
				$obsid = $btemp[2];
				$obsid =~ s/\'//g;
			}
		}
		close(FH);
		
		$line = "$file".'[cols time,dy,dz,dtheta]';
		system("dmlist infile=\"$line\" outfile=./Sim_twist_temp/zout opt=data");
		open(FH, "./Sim_twist_temp/zout");
		@ttime   = ();
		@tdy     = ();
		@tdz     = ();
		@tdtheta = ();
		$cnt    = 0;
		$counter = 0;
		$tdy_sum = 0;
		$tdz_sum = 0;
		$tdt_sum = 0;
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
				if($counter == 0){
					$tbegin   = $atemp[2];
					$tdy_sum += $atemp[3];
					$tdz_sum += $atemp[4];
					$tdt_sum += $atemp[5];
					$counter++;
				}elsif($counter == 1170){
					$atime = 0.5 *($tbegin + $atemp[2]);
					$tdy_sum += $atemp[3];
					$tdz_sum += $atemp[4];
					$tdt_sum += $atemp[5];
					$tdy_avg = $tdy_sum/1170;
					$tdz_avg = $tdz_sum/1170;
					$tdt_avg = $tdt_sum/1170;
					push(@ttime,   $atime);
					push(@tdy,     $tdy_avg);
					push(@tdz,     $tdz_avg);
					push(@tdtheta, $tdt_avg);
					$cnt++;
					$counter = 0;
					$tdy_sum = 0;
					$tdz_sum = 0;
					$tdt_sum = 0;
				}else{
					$tlast    = $atemp[2];
					$tdy_sum += $atemp[3];
					$tdz_sum += $atemp[4];
					$tdt_sum += $atemp[5];
					$counter++;
				}
			}
		}
		close(FH);
		if($counter < 1170 && $counter > 500){
			$atime = 0.5 *($tbegin + $tlast);
			$tdy_avg = $tdy_sum/$counter;
			$tdz_avg = $tdz_sum/$counter;
			$tdt_avg = $tdt_sum/$counter;
			push(@ttime,   $atime);
			push(@tdy,     $tdy_avg);
			push(@tdz,     $tdz_avg);
			push(@tdtheta, $tdt_avg);
			$cnt++;
		}

		get_inst_name();

		system("rm -rf ./Sim_twist_temp/zout");

		@ctemp = split(/\//, $file);
		print OUT2 "$ctemp[2]\t$obsid\t$instrument\t$date_obs\t$date_end\t$sim_x\t$sim_y\t$sim_z\t";
		print OUT2 "$pitchamp\t$yawamp\n";

#
#--- check time sequence so that there is no duplicated lines
#
		if($total  ==  0){
			for($i = 0; $i < $cnt; $i++){
				$time[$i]   = $ttime[$i];
				$dy[$i]     = $tdy[$i];
				$dz[$i]     = $tdz[$i];
				$dtheta[$i] = $tdtheta[$i];
#
#--- print out only when dy, dz, or dtheta have values
#
				if($dy[$i] > 0 || $dz[$i] > 0 || $dtheta[$i]> 0){
					print OUT "$time[$i]\t$obsid\t$instrument\t$dy[$i]\t$dz[$i]\t$dtheta[$i]\n";
				}
			}
		$total = $cnt;
		}else{
			for($i = 0; $i < $cnt; $i++){
				if($time[$total -1] < $ttime[$i]){
					$time[$total]   = $ttime[$i];
					$dy[$total]     = $tdy[$i];
					$dz[$total]     = $tdz[$i];
					$dtheta[$total] = $tdtheta[$i];
					$total++;
	
					if($dy[$total] > 0 || $dz[$total] > 0 || $dtheta[$total] > 0){
						print OUT "$time[$total]\t$obsid\t$instrument\t$dy[$total]\t$dz[$total]\t$dtheta[$total]\n";
					}
				}
			}
		}
	}
	close(OUT);
}


########################################################
### print_html: print Sim_twist html page            ###
########################################################

sub print_html{
        open(OUT, ">$web_dir/sim_twist.html");
        print OUT '<html>',"\n";
#        print OUT '<BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" VLINK="#B6FFFF" ALINK="#FF0000", background ="./stars.jpg">',"\n";
        print OUT '<BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="yellow" VLINK="yellow" ALINK="yellow", background ="./stars.jpg">',"\n";
        print OUT '<h2>SIM Shift and Twist Trends</h2>',"\n";
        print OUT '<p>',"\n";
        print OUT 'This page shows trends of SIM shifts (dy and dz) and twist (dtheta). All quantities are directly taken from',"\n";
        print OUT 'pcaf*_asol1.fits files. The units are mm for dy and dz, and second  for dtheta.',"\n";
        print OUT 'We fit two lines separated before and after (Days of Mission)= 1400 (May 21, 2003).',"\n";
        print OUT 'The unit of slopes are mm per day or second per day.',"\n";
        print OUT '<p> The sudden shift around DOM = 1400 was due to fid light drift (see a memo by Aldocroft';
	print OUT "<a href='http://cxc.harvard.edu/mta/ASPECT/fid_drift/'> fiducial light drfit</a>).","\n";
        print OUT '<br><br>',"\n";
        print OUT "<img src='./Plots/twist_plot.gif' width='600' height='600'>","\n";
        print OUT '<br><br>',"\n";

        print OUT '<p>For dtheta, data are further devided into smaller groups according to which instrument was used (ACIS-I, ACIS-S,',"\n";
        print OUT 'HRC-I, and HRC-S)<br><br>',"\n";
        print OUT "<img src='./Plots/dtheta_plot.gif' width='600' height='600'>","\n";

        print OUT '<p> Followings are ASCII data tables for the data plotted above. The entires are time in seconds from',"\n";
        print OUT ' Jan 1, 1998, dy, dz, and dtheta. All entires are 5 min avaerage.<br><br> ',"\n";

        for($wyear = 1999; $wyear <= $year; $wyear++){
                $name = './Data/data_extracted_'."$wyear";
                print OUT "<a href='$name'> ASCII Data for year:  $wyear</a><br>","\n";
        }
        print OUT '<p>',"\n";
        print OUT 'From the same fits files, we also collected sim_x,y, and z postions, pitch amps, and yaw amps of dithers.',"\n";
        print OUT '<br><br>',"\n";
        print OUT "<img src='./Plots/sim_plot.gif' width='600' height='600'>","\n";
        print OUT '<br><br>',"\n";

        print OUT '<p>Followings are ASCII data tables for the data plotted above. The entries are Fits file name,',"\n";
        print OUT ' tstart, tstop, sim_x, sim_y, sim_z, pitchamp, and yawamp.<br><br>',"\n";
        for($wyear = 1999; $wyear <= $year; $wyear++){
                $name = './Data/data_info_'."$wyear";
                print OUT "<a href='$name'> ASCII Data for year:  $wyear</a><br>","\n";
        }
        print OUT '</body>',"\n";
        print OUT '</html>',"\n";

        close(OUT);
}



##########################################################################
### plot_data: plotting data                                           ###
##########################################################################

sub plot_data{

	$in_list = `ls $data_dir/data_extracted_*`;
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
			$dom = $atemp[0]/86400 - 567;
			$atemp[5] * 3600;		#---- changed from degree to second
			push(@time,   $dom);
			push(@dy,     $atemp[3]);
			push(@dz,     $atemp[4]);
			push(@dtheta, $atemp[5]);
			if($atemp[2] =~ /ACIS-I/i){
				push(@dt_a_i, $atemp[5]);
				push(@dm_a_i, $dom);
				$dn_a_i++;
			}elsif($atemp[2] =~ /ACIS-S/i){
				push(@dt_a_s, $atemp[5]);
				push(@dm_a_s, $dom);
				$dn_a_s++;
			}elsif($atemp[2] =~ /HRC-I/i){
				push(@dt_h_i, $atemp[5]);
				push(@dm_h_i, $dom);
				$dn_h_i++;
			}elsif($atemp[2] =~ /HRC-S/i){
				push(@dt_h_s, $atemp[5]);
				push(@dm_h_s, $dom);
				$dn_h_s++;
			}
			$dcnt++;
		}
		close(FH);
	}

	$in_list = `ls $data_dir/data_info_*`;
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
				$add = 333;
			}
			if($year == 2000 || $year == 2004 || $year == 2008 || $year == 2012){
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
	$xside2= $xmin - 0.10 * $xdiff;
			
	@temp        = sort{$a<=>$b} @sim_x;
	$ymin_sim_x  = $temp[0];
	$ymax_sim_x  = $temp[$icnt -1];
	$ydiff       = abs($ymax_sim_x - $ymin_sim_x);
	$ymin_sim_x  = $ymin_sim_x - 0.01 * $ydiff;
	$ymax_sim_x  = $ymax_sim_x + 0.01 * $ydiff;
	$ymid_sim_x  = $ymin_sim_x + 0.50 * $ydiff;
	$yside_sim_x = $ymin_sim_x + 0.50 * $ydiff;
	$ytop_sim_x  = $ymax_sim_x + 0.05 * $ydiff;
	$ybot_sim_x  = $ymin_sim_x - 0.20 * $ydiff;

	@temp        = sort{$a<=>$b} @sim_y;
	$ymin_sim_y  = $temp[0];
	$ymax_sim_y  = $temp[$icnt -1];
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

	@temp        = sort{$a<=>$b} @sim_z;
	$ymin_sim_z  = $temp[0];
	$ymax_sim_z  = $temp[$icnt -1];
	$ydiff       = abs($ymax_sim_z - $ymin_sim_z);
	$ymin_sim_z  = $ymin_sim_z - 0.01 * $ydiff;
	$ymax_sim_z  = $ymax_sim_z + 0.01 * $ydiff;
	$ymid_sim_z  = $ymin_sim_z + 0.50 * $ydiff;
	$yside_sim_z = $ymin_sim_z + 0.50 * $ydiff;
	$ytop_sim_z  = $ymax_sim_z + 0.05 * $ydiff;
	$ybot_sim_z  = $ymin_sim_z - 0.20 * $ydiff;

	@ptemp = ();
	foreach $ent (@pitchamp){
		$temp = 3600 * $ent;
		push(@ptemp, $temp);
	}
	@pitchamp = @ptemp;

	@temp           = sort{$a<=>$b} @pitchamp;
	$ymin_pitchamp  = $temp[0];
	$ymax_pitchamp  = $temp[$icnt -3];
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
		$temp = 3600 * $ent;
		push(@ptemp, $temp);
	}
	@yawamp = @ptemp;

	@temp         = sort{$a<=>$b} @yawamp;
	$ymin_yawamp  = $temp[0];
	$ymax_yawamp  = $temp[$icnt -3];
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

	pgptxt($xmin,$ybot_yawamp, 0.0, 1.0, "Time (DOM)");
	pgclos();

###	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmcrop| $op_dir/pnmcrop| $op_dir/pnmflip -r270 |op_dir/ppmtogif > $web_dir/Plots/sim_plot.gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/sim_plot.gif");

#
#---- sim twist plot starts here
#
	
	@xbin        = @time;
	$xmin        = $time[0];
	$xmax        = $time[$dcnt -1];
	$xdiff       = $xmax - $xmin;
	$xmid  	     = $xmin + 0.50 * $xdiff;
	$xside       = $xmin - 0.08 * $xdiff;
	$xside       = $xmin - 0.12 * $xdiff;

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
		foreach $ent (@dy){
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
		@plotx3 = ();
		@ploty3 = ();
		$pcnt1  = 0;
		$pcnt2  = 0;
		$pcnt3  = 0;
		for($i = 0; $i < $dcnt; $i++){
			if($time[$i] < 1400){
				push(@plotx1, $time[$i]);
				push(@ploty1, $dy[$i]);
				$pcnt1++;
			}elsif($time[$i] < 2700){
				push(@plotx2, $time[$i]);
				push(@ploty2, $dy[$i]);
				$pcnt2++;
			}else{
				push(@plotx3, $time[$i]);
				push(@ploty3, $dy[$i]);
				$pcnt3++;
			}
		}
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

		@xbin  = @plotx3;
		@ybin  = @ploty3;
		$total = $pcnt3;
		least_fit();
		$dy_int3   = $s_int;
		$dy_slope3 = $slope;
		$dy_disp3 = sprintf "%4.3e", $slope;
#
#------ dz
#
		$sum  = 0;
		$sum2 = 0;
		foreach $ent (@dz){
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
		@plotx3 = ();
		@ploty3 = ();
		$pcnt1  = 0;
		$pcnt2  = 0;
		$pcnt3  = 0;
		for($i = 0; $i < $dcnt; $i++){
			if($time[$i] < 1400){
				push(@plotx1, $time[$i]);
				push(@ploty1, $dz[$i]);
				$pcnt1++;
			}elsif($time[$k] < 2700){
				push(@plotx2, $time[$i]);
				push(@ploty2, $dz[$i]);
				$pcnt2++;
			}else{
				push(@plotx3, $time[$i]);
				push(@ploty3, $dz[$i]);
				$pcnt3++;
			}
		}
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

		@xbin  = @plotx3;
		@ybin  = @ploty3;
		$total = $pcnt3;
		least_fit();
		$dz_int3   = $s_int;
		$dz_slope3 = $slope;
		$dz_disp3 = sprintf "%4.3e", $slope;

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
	$ymin = $dy_int1 + $dy_slope1 * $xmin;
	$ymax = $dy_int1 + $dy_slope1 * 1400;
	pgmove($xmin, $ymin);
	pgdraw(1400, $ymax);
	$ymin = $dy_int2 + $dy_slope2 * 1400;
	$ymax = $dy_int2 + $dy_slope2 * 2700;
	pgmove(1400, $ymin);
	pgdraw(2700, $ymax);
	$ymin = $dy_int3 + $dy_slope3 * 2700;
	$ymax = $dy_int3 + $dy_slope3 * $xmax;
	pgmove(2700, $ymin);
	pgdraw($xmax, $ymax);
	pgsci(1);
	$xdpos = $xmin + 0.04 * $xdiff;
	$diff  = $ymax_dy - $ymin_dy;
	$ytop1 = $ymax_dy - 0.10 * $diff; 
	$ytop2 = $ymax_dy - 0.20 * $diff; 
	$ytop3 = $ymax_dy - 0.30 * $diff; 
	pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope (dom < 1400): $dy_disp1");
	pgptxt($xdpos,$ytop2, 0.0, 0.0, "Slope (dom < 2700): $dy_disp2");
	pgptxt($xdpos,$ytop3, 0.0, 0.0, "Slope (dom > 2700): $dy_disp3");

	$color = 2;

	pgsvp(0.1, 0.95, 0.43,0.68);
	pgswin($xmin, $xmax, $ymin_dz, $ymax_dz);
	pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgptxt($xside,$ymid_dz, 90.0, 0.5, "dz (mm)");
	@ybin = @dz;
	plot_fig();

	pgsci(3);
	$ymin = $dz_int1 + $dz_slope1 * $xmin;
	$ymax = $dz_int1 + $dz_slope1 * 1400;
	pgmove($xmin, $ymin);
	pgdraw(1400, $ymax);
	$ymin = $dz_int2 + $dz_slope2 * 1400;
	$ymax = $dz_int2 + $dz_slope2 * 2700;
	pgmove(1400, $ymin);
	pgdraw(2700, $ymax);
	$ymin = $dz_int3 + $dz_slope3 * 2700;
	$ymax = $dz_int3 + $dz_slope3 * $xmax;
	pgmove(2700, $ymin);
	pgdraw($xmax, $ymax);
	pgsci(1);
	$xdpos = $xmin + 0.04 * $xdiff;
	$diff  = $ymax_dz - $ymin_dz;
	$ytop1 = $ymax_dz - 0.10 * $diff; 
	$ytop2 = $ymax_dz - 0.20 * $diff; 
	$ytop3 = $ymax_dz - 0.30 * $diff; 
	pgptxt($xdpos,$ytop1, 0.0, 0.0, "Slope (dom < 1400): $dz_disp1");
	pgptxt($xdpos,$ytop2, 0.0, 0.0, "Slope (dom < 2700): $dz_disp2");
	pgptxt($xdpos,$ytop3, 0.0, 0.0, "Slope (dom > 2700): $dz_disp3");


	$color = 2;

	pgsvp(0.1, 0.95, 0.16,0.41);
	pgswin($xmin, $xmax, $ymin_dtheta, $ymax_dtheta);
	pgbox(ABCNSTV,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
	pgptxt($xside,$ymid_dtheta, 90.0, 0.5, "dtheta (deg)");
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

	pgptxt($xmid,$ybot_dtheta, 0.0, 0.5, "Time (DOM)");
	pgclos();

###	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmcrop| $op_dir/pnmcrop| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/twist_plot.gif");
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/twist_plot.gif");
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
        	robust_fit();
        	$dt_int   = $int;
        	$dt_slope = $slope;
        	$dt_disp  = sprintf "%4.3e", $slope;

#		$avg = $int + $slope * $xbin[$data_cnt/2];
#	
#		$ymin = $avg - 0.01;
#		$ymax = $avg + 0.01;
		$ymin = -80;
		$ymax =  80;
        	$ydiff      = $ymax - $ymin;

        	$ymid  = $ymin + 0.50 * $ydiff;
        	$yside = $ymin + 0.50 * $ydiff;
        	$ytop  = $ymax + 0.05 * $ydiff;
        	$ybot  = $ymin + 0.20 * $ydiff;
        	$ytop1 = $ymax - 0.10 * $ydiff;
        	pgsvp(0.15, 0.98, $pst[$pnl_cnt], $ped[$pnl_cnt]);
        	pgswin($xmin, $xmax, $ymin, $ymax);
		pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
        	pgptxt($xside2,$ymid, 90.0, 0.5, "dtheta (deg)");
	
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
        	robust_fit();
        	$dt_int   = $int;
        	$dt_slope = $slope;
        	$dt_disp  = sprintf "%4.3e", $slope;

#		$avg = $int + $slope * $xbin[$data_cnt/2];
#	
#		$ymin = $avg - 0.01;
#		$ymax = $avg + 0.01;
		$ymin = -80;
		$ymax =  80;
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
        	pgptxt($xside2,$ymid, 90.0, 0.5, "dtheta (deg)");
	
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
        	robust_fit();
        	$dt_int   = $int;
        	$dt_slope = $slope;
        	$dt_disp  = sprintf "%4.3e", $slope;

#		$avg = $int + $slope * $xbin[$data_cnt/2];
#	
#		$ymin = $avg - 0.01;
#		$ymax = $avg + 0.01;
		$ymin = -80;
		$ymax =  80;
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
        	pgptxt($xside,$ymax, 90.0, 0.5, "dtheta (deg)");
	
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
        	robust_fit();
        	$dt_int   = $int;
        	$dt_slope = $slope;
        	$dt_disp  = sprintf "%4.3e", $slope;

#		$avg = $int + $slope * $xbin[$data_cnt/2];
#	
#		$ymin = $avg - 0.01;
#		$ymax = $avg + 0.01;
		$ymin = -80;
		$ymax =  80;
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
        	pgptxt($xside2,$ymid, 90.0, 0.5, "dtheta (deg)");
	
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
	pgptxt($xmin, $ybot2, 0.0, 1.0, "Time(DOM)");
	pgclos();
	
###    	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps|$op_dir/pnmcrop| $op_dir/pnmcrop| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $web_dir/Plots/dtheta_plot.gif");
    	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./Sim_twist_temp/pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/dtheta_plot.gif");
	system("rm -rf ./Sim_twist_temp/pgplot.ps");

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
        medfit();

        $alpha += $beta * (-1.0 * $xavg) + $yavg;

        $int   = $alpha;
        $slope = $beta;
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

