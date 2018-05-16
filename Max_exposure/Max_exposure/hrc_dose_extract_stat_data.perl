#!/usr/bin/perl

#################################################################################################
#												#
#	hrc_dose_extract_stat_data.perl: extract statistics from HRC S and I files		#
#				output is avg, min, max,               				#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Aug 23, 2005								#
#												#
#################################################################################################	

#
#------- find today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$tyear  = 1900 + $uyear;
$tmonth = $umon + 1;

#
#------- a few settings

#
$all = 'yes';

if($all == 'yes'){		#------ computing stat from Jul 1999 to today
	$byear = 1999;
	$one_mon = 'no';
}else{
	$byear = $tyear;	#------ setting for only the last month stat is computed
	$one_mon = 'yes';
	if($tmonth == 1){
		$tyear--;
		$byear = $tyear;
		$tmonth = 12;
	}else{
		$tmonth--;
	}
}


OUTER:
for($year = $byear; $year <= $tyear; $year++){
	if($year == 1999){
		@m_list = (8, 9, 10, 11, 12);
	}elsif($year == $tyear){
		if($month == 1){
			last OUTER;
		}elsif($one_mon ne 'no'){
			@m_list = ("$tmonth");
		}else{
			@m_list = ();
			for($i = 1; $i < $tmonth; $i++){
				push(@m_list, $i);
			}
		}
	}else{
		@m_list = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
	}
	foreach $month (@m_list){

		$smonth = $month;
		if($month < 10){
			$smonth = '0'."$month";
		}

##################################
#---- set input dirctory
##################################

		month_num_to_lett($month);
		$in_dir = './Save';					#--- data for cumulative data
#		$in_dir = "/data/mta4/www/REPORTS/MONTHLY/$year$cmonth";
		$in_dir2 = './Save/Data';				#--- data for each month
#		$in_dir2 = "/data/mta4/www/REPORTS/MONTHLY/$year$cmonth";

##################################

#
#----- file names
#
		$name1 = "$in_dir".'/HRCS_08_1999_'."$smonth".'_'."$year".'.fits*';
		$name2 = "$in_dir2".'/HRCS_'."$smonth".'_'."$year".'.fits*';

		$name3 = "$in_dir".'/HRCI_08_1999_'."$smonth".'_'."$year".'.fits*';
		$name4 = "$in_dir2".'/HRCI_'."$smonth".'_'."$year".'.fits*';

		$line = $name1;
		$out_name = 'hrcs_acc_out';
		comp_stat();

		$line = $name2;
		$out_name = 'hrcs_dff_out';
		comp_stat();

		$line = $name3;
		$out_name = 'hrci_acc_out';
		comp_stat();

		$line = $name4;
		$out_name = 'hrci_dff_out';
		comp_stat();
	}
}


######################################################################
### month_rum_to_lett: convert month name from num to letters     ####
######################################################################

sub month_num_to_lett{
	my($tmonth);
	($tmonth) = @_;
        if($tmonth == 1){
                $cmonth = 'JAN';
        }elsif($tmonth == 2){
                $cmonth = 'FEB';
        }elsif($tmonth == 3){
                $cmonth = 'MAR';
        }elsif($tmonth == 4){
                $cmonth = 'APR';
        }elsif($tmonth == 5){
                $cmonth = 'MAY';
        }elsif($tmonth == 6){
                $cmonth = 'JUN';
        }elsif($tmonth == 7){
                $cmonth = 'JUL';
        }elsif($tmonth == 8){
                $cmonth = 'AUG';
        }elsif($tmonth == 9){
                $cmonth = 'SEP';
        }elsif($tmonth == 10){
                $cmonth = 'OCT';
        }elsif($tmonth == 11){
                $cmonth = 'NOV';
        }elsif($tmonth == 12){
                $cmonth = 'DEC';
        }
}

###########################################################################
### comp_stat: compute statistics using ftools                          ###
###########################################################################

sub comp_stat{
	$ztest = `ls $line`;
	if($ztest =~ /$line/){
#
#-- to avoid get min from outside of the edge of a CCD
#
		system("dmimgthresh infile=$line outfile=zcut.fits  cut=\"0:\" value=0 clobber=yes");
		system("dmstat infile=zthresh.fits centroid=no > result");
		system("rm zthresh.fits");

		$upper = 'I/INDEF';
		$chk = `cat ./result`;

#
#-- find the 10th brightest ccd position and the count
#
		if($chk =~ /mean/){

			find_10th("$line");

			system("dmimgthresh infile=$line outfile=zthresh.fits  cut=\"0:$upper\" value=0 clobber=yes");
			system("dmstat infile=zthresh.fits centroid=no > result2");
			system("rm zthresh.fits");
		}
	}else{
		open(ZZ, '> result');
		close(ZZ);
		open(ZZ, '> result2');
		close(ZZ);
	}
	print_stat();							#-- extract results and print data out
}

###########################################################################
###  sub print_stat: get a avg, dev, min, and max from fimgstat output  ###
###########################################################################

sub print_stat{
        open(IN,"./result");
	$mean = 'NA';
	$dev  = 'NA';
	$min  = 'NA';
	$max  = 'NA';
	$min_pos = 'NA';
	$max_pos = 'NA';

	$mean2 = 'NA';
	$dev2  = 'NA';
	$min2  = 'NA';
	$max2  = 'NA';
	$min_pos2 = 'NA';
	$max_pos2 = 'NA';

        while(<IN>) {
                chomp $_;
                @atemp = split(/\s+/,$_);
                if($_ =~ /mean/){
                        $mean = $atemp[2];
		}elsif($_ =~ /std/){
			$dev  = $atemp[2];
		}elsif($_ =~ /min/){
			$min     = $atemp[2];
			@btemp   = split(/\(/, $_);
			@ctemp   = split(/\s+/, $btemp[1]);
			$min_pos = "($ctemp[1],$ctemp[2])";
		}elsif($_ =~ /max/){
			$max     = $atemp[2];
			@btemp   = split(/\(/, $_);
			@ctemp   = split(/\s+/, $btemp[1]);
			$max_pos = "($ctemp[1],$ctemp[2])";
		}
        }
        close(IN);
#
#------ stat for 10th brightest case
#
        open(IN,"./result2");
        while(<IN>) {
                chomp $_;
                @atemp = split(/\s+/,$_);
                if($_ =~ /mean/){
                        $mean2 = $atemp[2];
		}elsif($_ =~ /std/){
			$dev2  = $atemp[2];
		}elsif($_ =~ /min/){
			$min2     = $atemp[2];
			@btemp    = split(/\(/, $_);
			@ctemp    = split(/\s+/, $btemp[1]);
			$min_pos2 = "($ctemp[1],$ctemp[2])";
		}elsif($_ =~ /max/){
			$max2     = $atemp[2];
			@btemp    = split(/\(/, $_);
			@ctemp    = split(/\s+/, $btemp[1]);
			$max_pos2 = "($ctemp[1],$ctemp[2])";
		}
        }
        close(IN);

        open(OUT,">>$out_name");
	print  OUT "$year\t$month\t";
	printf OUT "%5.6f\t%5.6f\t%5.1f\t",$mean,$dev,$min;
	print  OUT "$min_pos\t";
	printf OUT "%5.1f\t",$max;
	print  OUT "$max_pos\t";
	printf OUT "%5.1f\t", $max2;
	print  OUT "$max_pos2\n";
        close(OUT);
        `rm result result2` ;
}


##########################################################################
### find_10th: finding 10th brightest pisxel position and the count    ###
##########################################################################

sub find_10th {
	
	($fzzz) = @_;
	system("dmimghist infile=$fzzz outfile=outfile.fits hist=1::1 strict=yes clobber=yes");
	system("dmlist infile=outfile.fits outfile=./zout opt=data");

        open(FH, './zout');
        @hbin = ();
        @hcnt = ();
        $tot = 0;
        while(<FH>){
                chomp $_;
                @htemp = split(/\s+/, $_);
                if($htemp[1] =~ /\d/ && $htemp[2] =~ /\d/ && $htemp[3] > 0){
                        push(@hbin, $htemp[1]);
                        push(@hcnt, $htemp[3]);
                        $tot++;
                }
        }
        close(FH);
	$upper = $hbin[$tot-10];
	system("rm outfile.fits zout");
}

