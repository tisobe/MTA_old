#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	alignment_sim_twist_extract_acadata.perl: extract aca position i and j, sim 	#
#						  postion, and creates a table		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Aug 03, 2014							#
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

###$ds = '/proj/cm/Integ/install.linux64.DS8.5/bin/';

############################################################

#
#---- two possible input; one from a data file telling date interval to compute
#---- another is to get one month interval from the 1st of the last month to
#---- the last day of the last month. Here we assume that the script is run on
#---- the first of the new month.
#

$file = $ARGV[0];               # if you want to use a data file, here is the input

if($file ne ''){
	if($comp_test =~ /test/i){
		open(FH, "$house_keeping/test_data_interval");
	}else{
        	open(FH, "$file");
	}
        @date_list = ();
        while(<FH>){
                chomp $_;
                push(@date_list, $_);
        }
        close(FH);

#
#---- otherwise, take a month interval
#

}else{

#
#---- find today's date, and set data colleciton interval (a last month)
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
        $line  = "$start\t$stop\n";
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
		system('rm -rf  ./param');
                last OUTER;
        }
}

system('mkdir ./param');

OUTER:
foreach $dir (@dlist){
        if($dir =~ /Sim_twist_temp/){
		system('rm -rf ./Sim_twist_temp');
                last OUTER;
        }
}

system('mkdir -p ./Sim_twist_temp');

#
#--- start looping around the date intervals
#
foreach $line (@date_list){
        @atemp = split(/\s+/, $line);
        $tstart = $atemp[0];
        $tstop  = $atemp[1];

	system("rm -rf ./Sim_twist_temp/*fits");
#
#---	get fidprops: fid light propertiy file
#
	open(OUT, ">./Sim_twist_temp/input_line");
	print OUT "operation=retrieve\n";
	print OUT "dataset=flight\n";
	print OUT "detector=pcad\n";
	print OUT "subdetector=aca\n";
	print OUT "level=1\n";
#	print OUT "version=last\n";
	print OUT "filetype=fidprops\n";
	print OUT "tstart=$tstart\n";
	print OUT "tstop=$tstop\n";
	print OUT "go\n";
	close(OUT);
	
	system("cd ./Sim_twist_temp/; echo $hakama  |arc4gl -U$dare -Sarcocc -i./input_line"); # here is the arc4gl
#
#---- get acacent: fid light postion information
#
	open(OUT, ">./Sim_twist_temp/input_line");
	print OUT "operation=retrieve\n";
	print OUT "dataset=flight\n";
	print OUT "detector=pcad\n";
	print OUT "subdetector=aca\n";
	print OUT "level=1\n";
#	print OUT "version=last\n";
	print OUT "filetype=acacent\n";
	print OUT "tstart=$tstart\n";
	print OUT "tstop=$tstop\n";
	print OUT "go\n";
	close(OUT);
	
	system("cd ./Sim_twist_temp; echo $hakama  |arc4gl -U$dare -Sarcocc -i./input_line"); # here is the arc4gl
	
	system("rm -rf ./Sim_twist_temp/input_line");
	system("gzip -d ./Sim_twist_temp/*gz");
#
#---- get fa and tsc postions from dataseeker
#
        $in_date = $tstart;
        conv_date();				#--- change time format to sec from 1998.1.1
        $tstart_sec = $sec_date;

        $in_date = $tstop;
        conv_date();
        $tstop_sec = $sec_date;


#	system("/opt/local/bin/perl dataseeker.pl outfile=./Sim_twist_temp/out.fits search_crit=\"columns=_fapos_avg,_tscpos_avg timestart=$tstart_sec timestop=$tstop_sec\"");

    $cline = "columns=_fapos_avg,_tscpos_avg timestart=$tstart_sec timestop=$tstop_sec";
    system("dataseeker.pl infile=$house_keeping/test outfile=./Sim_twist_temp/out.fits search_crit=\"$cline\" loginFile=$house_keeping/loginfile");
	
    $chk = is_file_exist('./Sim_twist_temp/', 'out.fits');              #--- added 8/3/14

    if($chk > 0){
	    system("dmlist infile=./Sim_twist_temp/out.fits outfile=./Sim_twist_temp/zout opt=data");
    	
	    open(FH, './Sim_twist_temp/zout');
	    @sim_time = ();
	    @fa       = ();
	    @tsc      = ();
	    $sim_cnt  = 0;
	    while(<FH>){
        	    chomp $_;
        	    @atemp = split(/\s+/, $_);
        	    if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
                	    push(@sim_time, $atemp[2]);
                	    push(@fa,       $atemp[3]);
                	    push(@tsc,      $atemp[4]);
                	    $sim_cnt++;
        	    }
	    }
	    close(FH);
	    system("rm -rf ./Sim_twist_temp/out.fits");
	    system("rm -rf ./Sim_twist_temp/zout");
    }

    $chk = is_file_exist('./Sim_twist_temp/', 'fidpr1.fits');               #--- added 8/3/14
    if($chk > 0){	
	    $line = `ls ./Sim_twist_temp/pcadf*_fidpr1.fits`;
	    @flist = split(/\s+/, $line);
	    $test_count = 0;
	    OUTER:
	    foreach $file (@flist){
		    $test_count++;
		    extract_data();			# sub to extract and print the extracted data
	    }
	    close(FH);
	    system("rm -rf ./Sim_twist_temp/pcadf*fits");
    }
}

system('rm -rf  ./Sim_twist_temp ./param');


######################################################################################
######################################################################################
######################################################################################

sub extract_data{

	$line = "$file".'[cols slot,id_string,id_num]';
	system("dmlist infile=\"$line\" outfile=./Sim_twist_temp/zout opt=data");
	open(IN, './Sim_twist_temp/zout');
	$ent_cnt = 0;
	@detect_chip_id = ();
	@detect_slot_id = ();
	@detect_fid_id  = ();
	while(<IN>){
        	chomp $_;
        	@atemp = split(/\s+/, $_);
        	if($atemp[1] =~ /\d/){
                	if($atemp[3] =~ /ACIS/){
                        	@btemp = split(/pcadf/, $file);
                        	@ctemp = split(/N/, $btemp[1]);
                        	$file_id = $ctemp[0];
                        	@dtemp = split(/ACIS-/, $atemp[3]);
                        	push(@detect_chip_id, $dtemp[1]);	#--- CCD name
                        	@ftemp = split(/\s+/, $_);
                        	push(@detect_slot_id, $ftemp[2]);	#--- Slot name
				push(@detect_fid_id, $ftemp[4]);	#--- fid id
                        	$ent_cnt++;
                	}elsif($atemp[3] =~ /HRC/){
                        	@btemp = split(/pcadf/, $file);
                        	@ctemp = split(/N/, $btemp[1]);
                        	$file_id = $ctemp[0];
                        	@dtemp = split(/HRC-/, $atemp[3]);
				$name = 'H-'."$dtemp[1]";
                        	push(@detect_chip_id, $name);		#---HRC name
                        	@ftemp = split(/\s+/, $_);
                        	push(@detect_slot_id, $ftemp[2]);	#---Slot name
				push(@detect_fid_id, $ftemp[4]);	#--- fid id
                        	$ent_cnt++;
                	}
        	}
	}
	close(IN);
	system("rm -rf ./Sim_twist_temp/zout");
	
#
#---- find acacent file name
#
	$file_name = './Sim_twist_temp/pcadf'."$file_id".'*_acen1.fits';

	$chip_cnt = 0;
	foreach $slot_id (@detect_slot_id){
#
#---- extract data just for one slot
#
		$line = "$file_name".'[slot='."$slot_id".']';
		system("dmcopy infile=\"$line\" outfile=./Sim_twist_temp/tmp.fits option=all  clobber=yes");
#
#---- extract time , center i and j position
#	
		$line = './Sim_twist_temp/tmp.fits[cols time,cent_i,cent_j]';
		system("dmlist infile=\"$line\" outfile=./Sim_twist_temp/zout2 opt=data");
		open(IN, './Sim_twist_temp/zout2');
		@time   = ();
		@cent_i = ();
		@cent_j = ();
		@ang_y  = ();
		@ang_z  = ();
		@alg    = ();
		$cnt  = 0;
		while(<IN>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
				push(@time,   $atemp[2]);
				push(@cent_i, $atemp[3]);
				push(@cent_j, $atemp[4]);
			}
		}
		close(IN);
		
#
#---- extract angle y and z, plus algorithm used (1 or 8)
#
		$line = './Sim_twist_temp/tmp.fits[cols ang_y,ang_z,alg]';
		system("dmlist infile=\"$line\" outfile=./Sim_twist_temp/zout2 opt=data");
		open(IN, './Sim_twist_temp/zout2');
		while(<IN>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
				push(@ang_y,  $atemp[2]);
				push(@ang_z,  $atemp[3]);
				push(@alg,    $atemp[4]);
				$cnt++;
			}
		}
		close(IN);
		system('rm -rf ./Sim_twist_temp/zout2');
		system('rm -rf ./Sim_twist_temp/tmp.fits');
		
#
#---- since the time interval is too fine, take average around 5 mins.
#---- 5 mins is about the data resolution of dataseeker
#		
		@atime   = ();
		@acent_i = ();
		@acent_j = ();
		@aang_y  = ();
		@aang_z  = ();
		$a_cnt  = 0;
		
		$sum_t = 0;
		$sum_i = 0;
		$sum_j = 0;
		$sum_y = 0;
		$sum_z = 0;
		$scnt  = 0;
		$avg_cnt = 0;
		for($i = 0; $i < $cnt; $i++){
			if($scnt == 0){
				$min_time = $time[$i];
				$diff = 0;
				$sum_t += $time[$i];
				$sum_i += $cent_i[$i];
				$sum_j += $cent_j[$i];
				$sum_y += $ang_y[$i];
				$sum_z += $ang_z[$i];
				$scnt++;
			}else{
				$diff = $time[$i] - $min_time;
				if($diff >= 300){
					$sum_t += $time[$i];
					$sum_i += $cent_i[$i];
					$sum_j += $cent_j[$i];
					$sum_y += $ang_y[$i];
					$sum_z += $ang_z[$i];
					$scnt++;
					$sum_t /= $scnt;
					$sum_i /= $scnt;
					$sum_j /= $scnt;
					$sum_y /= $scnt;
					$sum_z /= $scnt;
					push(@atime, $sum_t);
					push(@acent_i, $sum_i);
					push(@acent_j, $sum_j);
					push(@aang_y,  $sum_y);
					push(@aang_z,  $sum_z);
					$sum_t = 0;
					$sum_i = 0;
					$sum_j = 0;
					$sum_y = 0;
					$sum_z = 0;
					$scnt  = 0;
					$avg_cnt++;
				}else{
					$sum_t += $time[$i];
					$sum_i += $cent_i[$i];
					$sum_j += $cent_j[$i];
					$sum_y += $ang_y[$i];
					$sum_z += $ang_z[$i];
					$scnt++;
				}
			}
		}
		
		
		
		open(OUT, '>./Sim_twist_temp/test_out');
		$k = 0;
		for($j = 0; $j < $avg_cnt; $j++){
#
#--- compare time between the data and that from dataseeker and if they are
#--- close, take average 2 values of FA and TSC postions around that time
#--- and use them as positions for the particular observation
#
			OUTER:
			while($sim_time[$k]< $atime[$j]){
					$k++;
					if($k >= $sim_cnt){
						last OUTER;
					}
			}
			print OUT "$atime[$j]\t";
			print OUT "$slot_id\t";
			print OUT "$detect_fid_id[$chip_cnt]\t";
			print OUT "$alg[$j]\t";
			print OUT "$acent_i[$j]\t";
			print OUT "$acent_j[$j]\t";
			print OUT "$aang_y[$j]\t";
			print OUT "$aang_z[$j]\t";
			$fa_mid = 0.5 * ($fa[$k-1] + $fa[$k]);
			print OUT "$fa_mid\t";
			$tsc_mid = 0.5 * ($tsc[$k-1] + $tsc[$k]);
			print OUT "$tsc_mid\n";
		}
		close(OUT);
		$name = "$data_dir/$detect_chip_id[$chip_cnt]";
		$chip_cnt++;
		system("cat ./Sim_twist_temp/test_out >> $name");
		system("rm -rf ./Sim_twist_temp/test_out");
	}	
}						

##########################################################################################
### conv_date: convert date format                                                     ###
##########################################################################################

sub conv_date{
	@atemp = split(/\,/, $in_date);
	@btemp = split(/\//, $atemp[0]);
	@ctemp = split(/:/,  $atemp[1]);
	if($btemp[0] == 1){
		$add = 0;
	}elsif($btemp[0] == 2){
		$add = 31;
	}elsif($btemp[0] == 3){
		$add = 59;
	}elsif($btemp[0] == 4){
		$add = 90;
	}elsif($btemp[0] == 5){
		$add = 120;
	}elsif($btemp[0] == 6){
		$add = 151;
	}elsif($btemp[0] == 7){
		$add = 181;
	}elsif($btemp[0] == 8){
		$add = 212;
	}elsif($btemp[0] == 9){
		$add = 243;
	}elsif($btemp[0] == 10){
		$add = 273;
	}elsif($btemp[0] == 11){
		$add = 304;
	}elsif($btemp[0] == 12){
		$add = 334;
	}
	if($btemp[2] == 0 || $btemp[2] == 4 || $btemp[2] == 8){
		if($btemp[2] > 2){
			$add++;
		}
	}
	$add += $ctemp[1];
	if($btemp[2] == 99 || $btemp[2] == 98){
		$add_year = $btemp[1]  - 98;
	}elsif($btemp[2] < 98){
		$add_year = $btemp[2] + 2;
	}
	$year_date = 365 * $add_year;
	if($btemp[2] == 1 || $btemp[2] == 5 || $btemp[2] == 9){
		$year_date++;
	}
	$sec_date = 86400 * ($year_date + $add + $btemp[1] - 1) + 3600 * $ctemp[0] + 60 * $ctemp[1] + $ctemp[2];
}

######################################################################################
### is_dir_empty: check whether the directry is empty                              ###
######################################################################################

sub is_dir_empty{

    my ($path) = @_;
    opendir(DIR, $path);

    if(scalar(grep( !/^\.\.?$/, readdir(DIR)) == 0)) {
        closedir DIR;
        return 0;                           #---- yes the directory is empty
    }else{
        closedir DIR;
        return 1;                           #---- no the directory is not empty
    }
}

######################################################################################
### is_file_exist: check whether file with a pattern exist                         ###
######################################################################################

sub is_file_exist{


    my ($path, $pattern) = @_;

    $cout = 0;
    $chk  = is_dir_empty($path);
    if($chk == 1){
        system("ls $path/* > ./ztemp");
        open(FTIN, "./ztemp");

        while(<FTIN>){
            chomp $_;
            if($_ =~ /$pattern/){
                $cout = 1;
                last;
            }
        }
        close(FTIN);
        system("rm ./ztemp");
    }
    return $cout;
}

######################################################################################
### get_file_list: find files with a given pattern in the given directory         ####
######################################################################################

sub get_file_list{


    my ($path, $pattern) = @_;

    @out = ();
    $chk = is_file_exist($path, $pattern);
    if($chk == 1){
        system("ls $path/* > ./ztemp");
        open(FTIN, "./ztemp");
        while(<FTIN>){
            chomp $_;
            if($_ =~ /$pattern/){
                push(@out, $_);
            }
        }
        close(FTIN);
        system("rm ./ztemp");
    }
    return @out;
}

