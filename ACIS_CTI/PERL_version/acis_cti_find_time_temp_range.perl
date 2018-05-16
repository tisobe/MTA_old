#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
# find_time_temp_range.perl: find and set time range for temp.		#
#									#
#   this is just a combination of two script, previously separate	#
#									#
#	Author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	Last update: Jun 17, 2013					#
#		modified to fit a new directory system			#
#									#
#########################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;


#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#########################################

$chk = `ls $exc_dir/Working_dir`;
if($chk =~ /ztemp_range_list/){
	system("rm -rf $exc_dir/Working_dir/ztemp_range_list");
}

$in_list = `ls $exc_dir/Working_dir/acisf*fits`;
@fits_list = split(/\s+/, $in_list);

foreach $file (@fits_list){
	find_temp_range();
	find_time_range();
}

if($comp_test !~ /test/i){
	system("cat $exc_dir/Working_dir/ztemp_range_list $house_keeping/obsid_list > $exc_dir/Working_dir/zobs_id_list");
	system("cp $house_keeping/obsid_list $house_keeping/obsid_list~");
	system("mv $exc_dir/Working_dir/zobs_id_list $house_keeping/obsid_list");
}
$chk = `ls $exc_dir/Working_dir`;
if($chk =~/ztemp_range_list'){
    system("mv $exc_dir/Working_dir/ztemp_range_list $exc_dir/Working_dir/temp_file");
}
system("rm -rf $exc_dir/Working_dir/zfits_test $exc_dir/Working_dir/ztemp_input");

#########################################################################
#########################################################################
#########################################################################

sub find_temp_range{

#########################################################################
#									#
#	find_temp_range.perl: find focal temp for a given acis evt1 file#
#									#
#########################################################################

	
	system("ls /data/mta/Script/ACIS/Focal/Short_term > $exc_dir/Working_dir/ztemp");	# get focal temp
	@temp_list = ();
	open(FH, "$exc_dir/Working_dir/ztemp");
	while(<FH>){
		chomp $_;
		@atemp = split(/data_/,$_);
		if($atemp[1] ne ''){
			push(@temp_list, $atemp[1]);
		}
	}
	close(FH);
	system("rm -rf $exc_dir/Working_dir/ztemp");
	
	open(OUT, "> $exc_dir/Working_dir/ztemp_input");
	print OUT  "$file\n";					#find out needed info from dump file
	if($file =~ /gz/){
		system("zgip -d $file");
		@atemp = split(/\.gz/, $file);
		$file = $atemp[0];
	}
	@btemp = split(/acisf/,$file);
	@ctemp = split(/_/, $btemp[1]);
	$msid = $ctemp[0];

	system("dmlist  infile=$file opt=head  outfile=$exc_dir/Working_dir/zdump");
	open(FH, "$exc_dir/Working_dir/zdump");
	OUTER:
	while(<FH>){
		chomp $_;
		if($_ =~ /DATE-OBS/i){
			@atemp = split(/\s+/,$_);
			@btemp = split(/T/, $atemp[2]);
			@ctemp = split(/-/, $btemp[0]);
			$tstart = $atemp[2];
			$tstart =~ s/\s+//g;
			$syear = $ctemp[0];
			$smon  = $ctemp[1];
			$sday  = $ctemp[2];
			@dtemp = split(/:/, $btemp[1]);
			$shour = $dtemp[0];
			$smin  = $dtemp[1];
			$ssec  = $dtemp[2];
			$tyear = $syear;
			$tmon  = $smon;
			$tday  = $sday;
			conv_to_yday();
			$syday = $yday;
			$sdhr  = "$shour$smin";
			$ssecd = 3600*$shour + 60*$smin + $ssec;
			$tyday = $syday;
			$tsecd = $ssecd;
			conv_time_1998();
			$st1998 = $t1998;
		}elsif($_ =~ /DATE-END/i){
			@atemp = split(/\s+/,$_);
			@btemp = split(/T/, $atemp[2]);
			@ctemp = split(/-/, $btemp[0]);
			$tstop = $atemp[2];
			$tstop =~ s/\s+//g;
			$eyear = $ctemp[0];
			$emon  = $ctemp[1];
			$eday  = $ctemp[2];
			@dtemp = split(/:/, $btemp[1]);
			$ehour = $dtemp[0];
			$emin  = $dtemp[1];
			$esec  = $dtemp[2];
			$tyear = $eyear;
			$tmon  = $emon;
			$tday  = $eday;
			conv_to_yday();
			$eyday = $yday;
			$edhr  = "$ehour$emin";
			$esecd = 3600*$ehour + 60*$emin + $esec;
			$tyday = $eyday;
			$tsecd = $esecd;
			conv_time_1998();
			$et1998 = $t1998;
			last OUTER;
		}
	}
	close(FH);
	system("rm -rf $exc_dir/Working_dir/zdump");

#
#### find actual starting time and stop time of the data set
#
	$line = "$file".'[cols time]';
	system("dmstat infile=\"$line\" centroid=no > $exc_dir/Working_dir/zstat");
	open(FH, "$exc_dir/Working_dir/zstat");
	while(<FH>){
		chomp $_;
		if($_ =~ /min/){
			@atemp = split(/\s+/,$_);
			$begin = $atemp[2];
			$begin =~ s/\s+//g;
		}
		if($_ =~ /max/){
			@atemp = split(/\s+/,$_);
			$end = $atemp[2];
			$end =~ s/\s+//g;
		}
	}
	close(FH);
	system("rm -rf $exc_dir/Working_dir/zstat");

#
### convert date format of focal temp file so that we can select correct ones
#
	$data_yes = 0;
	@data_list = ();
	OUTER:
	foreach $ent (@temp_list){
		@atemp = split(/_/, $ent);
		$tyear  = $atemp[0];
		$tyday  = $atemp[1];
		@ctemp  = split(//,$atemp[2]);
		$chh    = "$ctemp[0]$ctemp[1]";
		$cmm    = "$ctemp[2]$ctemp[2]";
		$tsecd  = 3600*$chh + 60*$cmm;
		conv_time_1998();
		$cstart = $t1998;
		$tyday  = $atemp[3];
		@ctemp  = split(//,$atemp[4]);
		$chh    = "$ctemp[0]$ctemp[1]";
		$cmm    = "$ctemp[2]$ctemp[2]";
		$tsecd  = 3600*$chh + 60*$cmm;
		conv_time_1998();
		$cend   = $t1998;

		if(($cstart <= $begin && $cend >= $begin)
		   || ($cstart >= $begin && $cend <= $end)
		   || ($cstart <= $end && $cend >= $end)){
			$name = "data_$ent";
			push(@data_list, $name);
			$data_yes = 1;
		}elsif($cend < $st1998){
			next  OUTER;
		}elsif($cstart > $et1998){
			last OUTER;
		}
	}

	if($data_yes > 0){
		foreach $ent (@data_list){
			print OUT "TEMP DATA: $ent\n";
#
#### put all time-focal temp info into one file
#
			system("cat /data/mta/Script/ACIS/Focal/Short_term/$ent >> $exc_dir/Working_dir/ztemp");
		}
	
		$b_ind = 0;
		$e_ind = 0;
		$ick = 0;
		@temp_save = ();
	
		open(FH, "$exc_dir/Working_dir/ztemp");
		@temp_range_list = ();
#
### compare time and print out focal temp info if it is in the range
#
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			push(@temp_save, $atemp[3]);
			@btemp = split(/:/,$atemp[2]);
			$tyday = $btemp[0];
			$tsecd = $btemp[1];
			conv_time_1998();
			$comp_time = $t1998 ;
	
			if($comp_time < $begin){
				next OUTER;
			}elsif($comp_time > $end){
				last OUTER;
			}elsif( $comp_time >= $begin){
				print OUT "$comp_time\t$atemp[3]\n";
			}
		}
	}
	close(FH);
	close(OUT);
	system("rm -rf $exc_dir/Working_dir/ztemp");
}

##############################################################################
### conv_to_yday: change date format to year-date                          ###
##############################################################################

sub conv_to_yday{
	$add = 0;
	if($tmon == 2){
		$add = 31;
	}elsif($tmon == 3){
		$add = 59;
	}elsif($tmon == 4){
		$add = 90;
	}elsif($tmon == 5){
		$add = 120;
	}elsif($tmon == 6){
		$add = 151;
	}elsif($tmon == 7){
		$add = 181;
	}elsif($tmon == 8){
		$add = 212;
	}elsif($tmon == 9){
		$add = 243;
	}elsif($tmon == 10){
		$add = 273;
	}elsif($tmon == 11){
		$add = 304;
	}elsif($tmon == 12){
		$add = 334;
	}
	$yday = $tday + $add;
	$chk = 4.0 * int(0.25 * $tyear);
	if($chk == $tyear){
		if($tmon > 2){
			$yday++;
		}
	}
}

####################################################################
### cov_time_1998: change date (yyyy:ddd) to sec from 01/01/1998  ##
####################################################################

sub conv_time_1998 {

        $totyday = 365*($tyear - 1998);
        if($tyear > 2000){
                $totyday++;
        }
        if($tyear > 2004){
                $totyday++;
        }
        if($tyear > 2008){
                $totyday++;
        }
        if($tyear > 2012){
                $totyday++;
        }

        $ttday = $totyday + $tyday - 1;
	$t1998 = 86400 * $ttday + $tsecd;
}


#################################################################################
#################################################################################
#################################################################################

sub find_time_range{

#################################################################################
#										#
#    find_time_range.perl: create a list of time range for different temperature#
#										#
#################################################################################


	open(FH, "$exc_dir/Working_dir/ztemp_input");
	@data = ();
	$cnt = 0;
	@time = ();
	@temperature = ();
	while(<FH>){
		chomp $_;
		@atemp = split(//, $_);
		if($atemp[0] =~ /\d/){
			@btemp = split(/\s+/, $_);
			push(@time, $btemp[0]);
			push(@temperature, $btemp[1]);
			$cnt++;
		}else{
			if($_ =~ /acisf/){
				@ctemp = split(/acisf/, $_);
				@dtemp = split(/_/, $ctemp[1]);
				$obsid = $dtemp[0];
			}
		}
	}
	close(FH);
	
#
### here we assume that a new range starts if temperature is same for 5 consequtive times
#

	$sample = $temperature[0];
	$l_sample = $sample;
	@cnt_list = ();
	$s_cnt = 0;
	$current_pos = 0;
	for($i = 1; $i < $cnt; $i++){
		if($sample == $temperature[$i]){
			$s_cnt++;
			if($s_cnt > 4){
				if($l_sample != $sample && $current_pos > 0){
					push(@cnt_list, $current_pos);
					$l_sample = $sample;
				}
			}
		}elsif($sample !=  $temperature[$i]){
			if($s_cnt < 5){
				if($temperature[$i] == $l_sample){
					$s_cnt = $s_cnt + $l_cnt;
					$sample = $l_sample;
				}else{
					$s_cnt = 0;
					$sample = $temperature[$i];
				}
			}else{
				$l_cnt = $s_cnt;
				$l_sample= $sample;
				$s_cnt = 0;
				$sample = $temperature[$i];
				$current_pos = $i - 1;
			}
		}
	}
	
#
#### print out the results
#

	$e_cnt = 0;
	foreach(@cnt_list){
		$e_cnt++;
	}

	if($cnt > 0){
		open(OUT, ">>$exc_dir/Working_dir/ztemp_range_list");
		if($e_cnt > 0){
			$diff = $time[$cnt_list[0]] - $time[0];
			print OUT "$obsid\t";
			print OUT "$temperature[$cnt_list[0]]\t";
			printf OUT "%10d\t",$time[0];
			printf OUT "%10d\t",$time[$cnt_list[0]];
			printf OUT "%5d\n",$diff;
			
			for($i = 1; $i <  $e_cnt; $i++){
				$diff = $time[$cnt_list[$i]] - $time[$cnt_list[$i -1]+1];
				print OUT "$obsid\t";
				print OUT "$temperature[$cnt_list[$i]]\t";
				printf OUT "%10d\t",$time[$cnt_list[$i -1]+1];
				printf OUT "%10d\t",$time[$cnt_list[$i]];
				printf OUT "%5d\n",$diff;
			}
			
			$diff = $time[$cnt - 1] - $time[$cnt_list[$e_cnt -1] + 1];
			print OUT "$obsid\t";
			print OUT "$temperature[$cnt_list[$e_cnt -1] + 1]\t"; 
			printf OUT "%10d\t",$time[$cnt_list[$e_cnt - 1] + 1];
			printf OUT "%10d\t",$time[$cnt - 1];
			printf OUT "%5d\n",$diff;
		}else{
			$diff = $time[$cnt - 1] - $time[0];
			print OUT "$obsid\t";
			print OUT "$temperature[0]\t";
			printf OUT "%10d\t",$time[0];
			printf OUT "%10d\t",$time[$cnt - 1];
			printf OUT "%5d\n",$diff;
		}
		close(OUT);
	}
}
