#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	acis_bias_get_info.perl: extract information about baisbackground entires		#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#	last update: May 22, 2013								#
#												#
#################################################################################################

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

#
#---- use this to count how many CCDs are used for a particular observation
#
	@stamp_list = ();
	foreach $file (@data_list){
		@atemp = split(/acisf/,$file);
		@btemp = split(/N/,$atemp[1]);
		$head  = 'acis'."$btemp[0]";

		timeconv1($btemp[0]);
		$file_time  = $normal_time;			# $normal_time is output of timeconv1
		@ftemp      = split(/:/, $file_time);
		$today_time = "$ftemp[0]:$ftemp[1]";
#
#--- dump the fits header and find informaiton needed (ccd id, readmode)
#
		system("dmlist infile=$file outfile=./Working_dir/zdump opt=head");
		open(FH, './Working_dir/zdump');				
		$ccd_id = -999;
		$readmode = 'INDEF';

		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($_ =~ /CCD_ID/){
				$ccd_id      = $atemp[2];
				$ccd_id      =~ s/\s+//g;
			}elsif($_     =~ /READMODE/){
				$readmode    = $atemp[2];
				$readmode    =~ s/\s+//g;
			}elsif($_            =~ /DATAMODE/){
				$datamode    = $atemp[2];
				$datamode    =~ s/\s+//g;
			}elsif($_            =~ /FEP_ID/){
				$fep_id      = $atemp[2];
				$fep_id      =~ s/\s+//g;
			}elsif($_            =~ /STARTROW/){
				$start_row   = $atemp[2];
				$start_row   =~ s/\s+//g;
			}elsif($_            =~ /ROWCNT/){
				$rowcnt      = $atemp[2];
				$rowcnt      =~ s/\s+//g;
			}elsif($_            =~ /ORC_MODE/){
				$orc_mode    = $atemp[2];
				$orc_mode    =~ s/\s+//g;
			}elsif($_            =~ /DEAGAIN/){
				$deagain     = $atemp[2];
				$deagain     =~ s/\s+//g;
			}elsif($_            =~ /BIASALG/){
				$biasalg     = $atemp[2];
				$biasalg     =~ s/\s+//g;
			}elsif($_            =~ /BIASARG0/){
				$biasarg0    = $atemp[2];
				$biasarg0    =~ s/\s+//g;
			}elsif($_            =~ /BIASARG1/){
				$biasarg1    = $atemp[2];
				$biasarg1    =~ s/\s+//g;
			}elsif($_            =~ /BIASARG2/){
				$biasarg2    = $atemp[2];
				$biasarg2    =~ s/\s+//g;
			}elsif($_            =~ /BIASARG3/){
				$biasarg3    = $atemp[2];
				$biasarg3    =~ s/\s+//g;
			}elsif($_            =~ /INITOCLA/){
				$overclock_a = $atemp[2];
				$overclock_a =~ s/\s+//g;
			}elsif($_            =~ /INITOCLB/){
				$overclock_b = $atemp[2];
				$overclock_b =~ s/\s+//g;
			}elsif($_            =~ /INITOCLC/){
				$overclock_c = $atemp[2];
				$overclock_c =~ s/\s+//g;
			}elsif($_            =~ /INITOCLD/){
				$overclock_d = $atemp[2];
				$overclock_d =~ s/\s+//g;
			}
		}
		close(FH);
#
#---- only when the observation is TIMEED mode, process the data further
#		
		$find = 0;
		if($readmode =~ /^TIMED/i) {
			$find = 1;
		}

		if($find > 0){
			for($im = 0; $im < 10; $im++){			# loop for ccds
				if($im == $ccd_id){

					@atemp = split(/acisf/,$file);		
					@btemp = split(/N/,$atemp[1]);
					$htime = $btemp[0];
					push(@stamp_list, $htime);
		
					$overclock = $overclock_a;
					$bias_file = "$data_dir".'/Info_dir/CCD'."$im".'/quad0';
						open(QIN,">> $bias_file");
						printf QIN "%10.1f\t%4.2f\t",$htime,$overclock;
						print  QIN "$datamode\t";
						print  QIN "$fep_id\t$start_row\t$rowcnt\t$orc_mode\t";
						print  QIN "$deagain\t$biasalg\t$biasarg0\t$biasarg1\t";
						print  QIN "$biasarg2\t$biasarg3\t$biasarg4\n";
						close(QIN);
		
					$overclock = $overclock_b;
					$bias_file = "$data_dir".'/Info_dir/CCD'."$im".'/quad1';
						open(QIN,">> $bias_file");
						printf QIN "%10.1f\t%4.2f\t",$htime,$overclock;
						print  QIN "$datamode\t";
						print  QIN "$fep_id\t$start_row\t$rowcnt\t$orc_mode\t";
						print  QIN "$deagain\t$biasalg\t$biasarg0\t$biasarg1\t";
						print  QIN "$biasarg2\t$biasarg3\t$biasarg4\n";
						close(QIN);
		
					$overclock = $overclock_c;
					$bias_file = "$data_dir".'/Info_dir/CCD'."$im".'/quad2';
						open(QIN,">> $bias_file");
						printf QIN "%10.1f\t%4.2f\t",$htime,$overclock;
						print  QIN "$datamode\t";
						print  QIN "$fep_id\t$start_row\t$rowcnt\t$orc_mode\t";
						print  QIN "$deagain\t$biasalg\t$biasarg0\t$biasarg1\t";
						print  QIN "$biasarg2\t$biasarg3\t$biasarg4\n";
						close(QIN);
		
					$overclock = $overclock_d;
					$bias_file = "$data_dir".'/Info_dir/CCD'."$im".'/quad3';
						open(QIN,">> $bias_file");
						printf QIN "%10.1f\t%4.2f\t",$htime,$overclock;
						print  QIN "$datamode\t";
						print  QIN "$fep_id\t$start_row\t$rowcnt\t$orc_mode\t";
						print  QIN "$deagain\t$biasalg\t$biasarg0\t$biasarg1\t";
						print  QIN "$biasarg2\t$biasarg3\t$biasarg4\n";
						close(QIN);
				}
			}	
		}
	}
#
#----- now count how many CCDs are used for a particular observations
#
	$cnt = 0;
	foreach (@stamp_list){
		$cnt++;
	}
	if($cnt > 0){
#
#--- first find how many time stamps are in the list
#
		@temp = @stamp_list;
		$first = shift(@temp);
		%{cnt.$first} = (cnt =>["0"]);
		@new = ($first);
		OUTER:
		foreach $ent (@temp){
			foreach $comp (@new){
				if($ent == $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
			%{cnt.$ent} = (cnt =>["0"]);
		}
#
#--- count how many times one time stamps are repeated in the list
#

		foreach $ent (@stamp_list){
			${cnt.$ent}{cnt}[0]++;
		}
		open(CNO, ">>$data_dir/Info_dir/list_of_ccd_no");
		foreach $ent (@new){
			@atemp = split(/\./, $ent);
			print CNO "$atemp[0]\t${cnt.$ent}{cnt}[0]\n";
		}
		close(CNO);
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
		
