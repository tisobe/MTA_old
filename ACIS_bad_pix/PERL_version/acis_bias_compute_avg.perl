#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_bias_compute_avg.perl: compute averaged bias background.			#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: May 22, 2013							#
#											#
#########################################################################################

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

#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/bias_dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);



#######################################


$list = $ARGV[0];

open(FH, "$list");
@data_list = ();
while(<FH>){
	chomp $_;
	push(@data_list, $_);
}
close(FH);
int_file_for_day();


###########################################################
### int_file_for_day: prepare files for analysis        ###
###########################################################

sub int_file_for_day{

GETOUT:
	foreach $file (@data_list){			
		@atemp      = split(/acisf/,$file);
		@btemp      = split(/N/,$atemp[1]);
		$head       = 'acis'."$btemp[0]";

		timeconv1($btemp[0]);                           # time format to e.g. 2002:135:03:42:35
		$file_time  = $normal_time;			# $normal_time is output of timeconv1
		@ftemp      = split(/:/, $file_time);
		$today_time = "$ftemp[0]:$ftemp[1]";

		system("dmlist infile=$file opt=head outfile=./zdump");

		open(FH, './zdump');				# informaiton needed (ccd id, readmode)
		$ccd_id = -999;
		$readmode = 'INDEF';

		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($_ =~  /CCD_ID/){
				$ccd_id      = $atemp[2];
			}elsif($_ =~ /READMODE/){
				$readmode    = $atemp[2];
			}elsif($_ =~ /INITOCLA/){
				$overclock_a = $atemp[2];
			}elsif($_ =~ /INITOCLB/){
				$overclock_b = $atemp[2];
			}elsif($_ =~ /INITOCLC/){
				$overclock_c = $atemp[2];
			}elsif($_ =~ /INITOCLD/){
				$overclock_d = $atemp[2];
			}
		}
		close(FH);
		
		$find = 0;
		if($readmode =~ /^TIMED/i) {
			$find = 1;
		}

		if($find > 0){
			OUTER:
			for($im = 0; $im < 10; $im++){					# loop for ccds
				if($im != $ccd_id){
					next OUTER;
				}
				@bad_col0 = ();
				@bad_col1 = ();
				@bad_col2 = ();
				@bad_col3 = ();
				open (IN, "$house_keeping/Defect/bad_col_list");
				while(<IN>){
					chomp $_;
					@atemp = split(//, $_);	
					if($atemp[0] =~ /\d/){
						@atemp = split(/:/, $_);
						if($atemp[0] == $ccd_id){
							if($atemp[1] <= 256){
								push(@bad_col0, $atemp[1]);
							}elsif($atemp[1] <= 512){
								$col_no = $atemp[1] - 256;
								push(@bad_col1, $col_no);
							}elsif($atemp[1] <= 768){
								$col_no = $atemp[1] - 512;
								push(@bad_col2, $col_no);
							}elsif($atemp[1] <= 1024){
								$col_no = $atemp[1] - 768;
								push(@bad_col3, $col_no);
							}
						}
					}
				}
				close(IN);

				@atemp = split(/acisf/,$file);		
				@btemp = split(/N/,$atemp[1]);
				$htime = $btemp[0];
		
				$line ="$file".'[opt type=i4,null=-9999]';
                                system("dmcopy \"$line\"  temp.fits clobber='yes'");

				system("dmimgthresh infile=temp.fits outfile=comb.fits cut=0:4000 clobber='yes'");
				
	
				system("dmcopy \"comb.fits[x=1:256]\" out1.fits clobber='yes'");
				$q_file = 'out1.fits';
				$bias_avg = 0;
				$bias_std = 0;
				$bias_file = "$data_dir/".'Bias_save/CCD'."$im".'/quad0';
				$c_start = 0;                                   # starting column
				$xlow  = 1;
				$xhigh = 256;
				$overclock = $overclock_a;
				@bad_col = @bad_col0;
				quad_sep();                                      # sub to extract pixels
				system("rm -rf out1.fits");                                 # outside of acceptance range

				if($htime > 0 && $bias_avg > 0){
					open(QIN,">> $bias_file");
					printf QIN "%10.1f\t%4.2f\t%4.2f\t%4.2f\n",$htime,$bias_avg,$bias_std,$overclock;
					close(QIN);
				}
	
				system("dmcopy \"comb.fits[x=257:512]\" out2.fits clobber='yes'");

				$q_file = 'out2.fits';
				$bias_avg = 0;
				$bias_std = 0;
				$bias_file = "$data_dir/".'Bias_save/CCD'."$im".'/quad1';
				$c_start = 256;
				$xlow  = 257;
				$xhigh = 512;
				$overclock = $overclock_b;
				@bad_col = @bad_col1;
				quad_sep();
				system("rm -rf out2.fits");

				if($htime > 0 && $bias_avg > 0){
					open(QIN,">> $bias_file");
					printf QIN "%10.1f\t%4.2f\t%4.2f\t%4.2f\n",$htime,$bias_avg,$bias_std,$overclock;
					close(QIN);
				}
	
				system("dmcopy \"comb.fits[x=513:768]\" out3.fits clobber='yes'");

				$q_file = 'out3.fits';
				$c_start = 512;
				$bias_avg = 0;
				$bias_std = 0;
				$bias_file = "$data_dir/".'Bias_save/CCD'."$im".'/quad2';
				$xlow  = 513;
				$xhigh = 768;
				$overclock = $overclock_c;
				@bad_col = @bad_col2;
				quad_sep();
				system("rm  -rf out3.fits");

				if($htime > 0 && $bias_avg > 0){
					open(QIN,">> $bias_file");
					printf QIN "%10.1f\t%4.2f\t%4.2f\t%4.2f\n",$htime,$bias_avg,$bias_std,$overclock;
					close(QIN);
				}
	
				system("dmcopy \"comb.fits[x=769:1024]\" out4.fits clobber='yes'");

				$q_file = 'out4.fits';
				$c_start = 768;
				$bias_avg = 0;
				$bias_std = 0;
				$bias_file = "$data_dir/".'Bias_save/CCD'."$im".'/quad3';
				$xlow  = 769;
				$xhigh = 1024;
				$overclock = $overclock_d;
				@bad_col = @bad_col3;
				quad_sep();
				system("rm -rf  out4.fits");
				if($htime > 0 && $bias_avg > 0){
					open(QIN,">> $bias_file");
					printf QIN "%10.1f\t%4.2f\t%4.2f\t%4.2f\n",$htime,$bias_avg,$bias_std,$overclock;
					close(QIN);
				}
			}	
		}
	}
}


###############################################################
### quad_sep: separate CCD info into quad size          #######
###############################################################

sub quad_sep{

#
#---  dump the image to an acsii file
#
	system("dmlist $q_file opt=array > ./zout");

        open(FH, './zout');
        while(<FH>){
                chomp $_;
                @ctemp         = split(/\s+/, $_);
                if($ctemp[3] =~ /\d/ && $ctemp[4] =~ /\d/){
                        $x             = $ctemp[3];
                        $y             = $ctemp[4];
                        $val[$x][$y]   = $ctemp[6];
                }
        }

        for($i = 1;  $i <= 256; $i++){
                $sum[$i]    = 0;
                $sum2[$i]   = 0;
                $cnt[$i]    = 0;
        }
        for($i = 1; $i <= 256; $i++){
                for($j = 1; $j <= 256; $j++){
                        $sum[$i] += $val[$i][$j];
                        $sum2[$i] += $val[$i][$j] * $val[$i][$j];
                        $cnt[$i]++;
                }
        }

	system("rm -rf zout");

	find_mean();					# find bad columns

}

#######################################################################
###  find_mean: compute mean values                                 ###
#######################################################################

sub find_mean{
        $asum  = 0;
        $asum2 = 0;
        $fcnt = 0;
	OUTER:
        for($icol = 1; $icol <= 256; $icol++){			# make an average of averaged column value
                if($cnt[$icol] > 0){				# average of column is caluculated in 
								# sub extract
			foreach $bcol (@bad_col){
				if($icol == $bcol){
					next OUTER;
				}
			}
                        $avg[$icol] = $sum[$icol]/$cnt[$icol];	
                        $asum  += $avg[$icol];
                        $asum2 += $avg[$icol]*$avg[$icol];
                        $fcnt++;
                }
        }
	if($fcnt > 0){
        	$cavg = $asum/$fcnt;
        	$std = sqrt($asum2/$fcnt - $cavg*$cavg);
		$bias_avg = $cavg;
		$bias_std = $std;
	}
}

################################################################
### timeconv1: chnage sec time formant to yyyy:ddd:hh:mm:ss ####
################################################################

sub timeconv1 {
        ($time) = @_;
#        $normal_time = `/home/ascds/DS.release/bin/axTime3 $time u s t d`;
        $normal_time = y1999sec_to_ydate($time);
}

######################################################################################
### ydate_to_y1998sec: 20009:033:00:00:00 format to 349920000 fromat               ###
######################################################################################

sub ydate_to_y1998sec{
#
#---- this script computes total seconds from 1998:001:00:00:00
#---- to whatever you input in the same format. it is equivalent of
#---- axTime3 2008:001:00:00:00 t d m s
#---- there is no leap sec corrections.
#

	my($date, $atemp, $year, $ydate, $hour, $min, $sec, $yi);
	my($leap, $ysum, $total_day);

	($date)= @_;
	
	@atemp = split(/:/, $date);
	$year  = $atemp[0];
	$ydate = $atemp[1];
	$hour  = $atemp[2];
	$min   = $atemp[3];
	$sec   = $atemp[4];
	
	$leap  = 0;
	$ysum  = 0;
	for($yi = 1998; $yi < $year; $yi++){
		$chk = 4.0 * int(0.25 * $yi);
		if($yi == $chk){
			$leap++;
		}
		$ysum++;
	}
	
	$total_day = 365 * $ysum + $leap + $ydate -1;
	
	$total_sec = 86400 * $total_day + 3600 * $hour + 60 * $min + $sec;
	
	return($total_sec);
}

######################################################################################
### y1999sec_to_ydate: format from 349920000 to 2009:33:00:00:00 format            ###
######################################################################################

sub y1999sec_to_ydate{
#
#----- this chage the seconds from 1998:001:00:00:00 to (e.g. 349920000)
#----- to 2009:033:00:00:00.
#----- it is equivalent of axTime3 349920000 m s t d
#

	my($date, $in_date, $day_part, $rest, $in_hr, $hour, $min_part);
	my($in_min, $min, $sec_part, $sec, $year, $tot_yday, $chk, $hour);
	my($min, $sec);

	($date) = @_;

	$in_day   = $date/86400;
	$day_part = int ($in_day);
	
	$rest     = $in_day - $day_part;
	$in_hr    = 24 * $rest;
	$hour     = int ($in_hr);
	
	$min_part = $in_hr - $hour;
	$in_min   = 60 * $min_part;
	$min      = int ($in_min);
	
	$sec_part = $in_min - $min;
	$sec      = int(60 * $sec_part);
	
	OUTER:
	for($year = 1998; $year < 2100; $year++){
		$tot_yday = 365;
		$chk = 4.0 * int(0.25 * $year);
		if($chk == $year){
			$tot_yday = 366;
		}
		if($day_part < $tot_yday){
			last OUTER;
		}
		$day_part -= $tot_yday;
	}
	
	$day_part++;
	if($day_part < 10){
		$day_part = '00'."$day_part";
	}elsif($day_part < 100){
		$day_part = '0'."$day_part";
	}
	
	if($hour < 10){
		$hour = '0'."$hour";
	}
	
	if($min  < 10){
		$min  = '0'."$min";
	}
	
	if($sec  < 10){
		$sec  = '0'."$sec";
	}
	
	$time = "$year:$day_part:$hour:$min:$sec";
	
	return($time);
}
		
