#!/usr/bin/perl

#################################################################################################
#												#
#	extract_stat_data.perl: extract statistics from ACIS fits data from I2, I3, S2, and S3	#
#				output is avg, min, max, 10th brightest				#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Aug 23, 2005								#
#												#
#################################################################################################	

###############################################################################
#---- set directories

$web_dir  = '/data/mta/www/mta_max_exp/';

###############################################################################

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

		$in_dir  = "$web_dir/Cumulative";
		$in_dir2 = "$web_dir/Month";

##################################

#
#----- file names
#
		$name1 = "$in_dir".'/ACIS_07_1999_'."$smonth".'_'."$year".'.fits.gz';
		$name2 = "$in_dir2".'/ACIS_'."$smonth".'_'."$year".'.fits.gz';


#-------- ACIS I2 Chip ----------------

		$name1 = "$in_dir".'/ACIS_07_1999_'."$smonth".'_'."$year".'_i2.fits.gz';
		$name2 = "$in_dir2".'/ACIS_'."$smonth".'_'."$year".'_i2.fits.gz';

		$line = "$name1".'[1:1024,1:256]';
		$out_name = 'i_2_n_0_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,1:256]';
		$out_name = 'i_2_n_0_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,257:508]';		# the last few columns are dropped
		$out_name = 'i_2_n_1_acc_out';			# because they are bad columns and too bright
		comp_stat();					# this applies for all CCDs

		$line = "$name2".'[1:1024,257:508]';
		$out_name = 'i_2_n_1_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,513:768]';
		$out_name = 'i_2_n_2_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,513:768]';
		$out_name = 'i_2_n_2_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,769:1020]';
		$out_name = 'i_2_n_3_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,769:1020]';
		$out_name = 'i_2_n_3_dff_out';
		comp_stat();


#-------- ACIS I3 Chip ----------------

		$name1 = "$in_dir".'/ACIS_07_1999_'."$smonth".'_'."$year".'_i3.fits.gz';
		$name2 = "$in_dir2".'/ACIS_'."$smonth".'_'."$year".'_i3.fits.gz';

		$line = "$name1".'[1:1024,769:1020]';
		$out_name = 'i_3_n_0_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,769:1020]';
		$out_name = 'i_3_n_0_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,513:768]';
		$out_name = 'i_3_n_1_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,513:768]';
		$out_name = 'i_3_n_1_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,257:508]';
		$out_name = 'i_3_n_2_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,257:508]';
		$out_name = 'i_3_n_2_dff_out';
		comp_stat();

		$line = "$name1".'[1:1024,1:256]';
		$out_name = 'i_3_n_3_acc_out';
		comp_stat();

		$line = "$name2".'[1:1024,1:256]';
		$out_name = 'i_3_n_3_dff_out';
		comp_stat();


#-------- ACIS S2 Chip ----------------

		$name1 = "$in_dir".'/ACIS_07_1999_'."$smonth".'_'."$year".'_s2.fits.gz';
		$name2 = "$in_dir2".'/ACIS_'."$smonth".'_'."$year".'_s2.fits.gz';

		$line = "$name1".'[1:256,1:1020]';
		$out_name = 's_2_n_0_acc_out';
		comp_stat();

		$line = "$name2".'[1:256,1:1020]';
		$out_name = 's_2_n_0_dff_out';
		comp_stat();

		$line = "$name1".'[257:508,1:1020]';
		$out_name = 's_2_n_1_acc_out';
		comp_stat();

		$line = "$name2".'[257:508,1:1020]';
		$out_name = 's_2_n_1_dff_out';
		comp_stat();

		$line = "$name1".'[513:768,1:1020]';
		$out_name = 's_2_n_2_acc_out';
		comp_stat();

		$line = "$name2".'[513:768,1:1020]';
		$out_name = 's_2_n_2_dff_out';
		comp_stat();

		$line = "$name1".'[769:1024,1:1020]';
		$out_name = 's_2_n_3_acc_out';
		comp_stat();

		$line = "$name2".'[769:1024,1:1020]';
		$out_name = 's_2_n_3_dff_out';
		comp_stat();


#-------- ACIS S3 Chip ----------------


		$name1 = "$in_dir".'/ACIS_07_1999_'."$smonth".'_'."$year".'_s3.fits.gz';
		$name2 = "$in_dir2".'/ACIS_'."$smonth".'_'."$year".'_s3.fits.gz';

		$line = "$name1".'[1:256,1:1020]';
		$out_name = 's_3_n_0_acc_out';
		comp_stat();

		$line = "$name2".'[1:256,1:1020]';
		$out_name = 's_3_n_0_dff_out';
		comp_stat();

		$line = "$name1".'[257:508,1:1020]';
		$out_name = 's_3_n_1_acc_out';
		comp_stat();

		$line = "$name2".'[257:508,1:1020]';
		$out_name = 's_3_n_1_dff_out';
		comp_stat();

		$line = "$name1".'[513:768,1:1020]';
		$out_name = 's_3_n_2_acc_out';
		comp_stat();

		$line = "$name2".'[513:768,1:1020]';
		$out_name = 's_3_n_2_dff_out';
		comp_stat();

		$line = "$name1".'[769:1024,1:1020]';
		$out_name = 's_3_n_3_acc_out';
		comp_stat();

		$line = "$name2".'[769:1024,1:1020]';
		$out_name = 's_3_n_3_dff_out';
		comp_stat();

#-----------------------------

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
	system("dmcopy \"$line\" temp.fits");

	system("dmimgthresh infile=temp.fits outfile=zthresh.fits  cut=\"0:\" value=0 clobber=yes");
	system("dmstat infile=zthresh.fits centroid=no > result");
	system("rm zthresh.fits");

	find_10th("temp.fits");						#-- find the 10th brightest ccd position and the count

	system("dmimgthresh infile=temp.fits outfile=zthresh.fits  cut=\"0:$upper\" value=0 clobber=yes");
	system("dmstat infile=zthresh.fits centroid=no > result2");
	system("rm zthresh.fits temp.fits");

	print_stat();							#-- extract results and print data out
}

###########################################################################
###  sub print_stat: get a avg, dev, min, and max from fimgstat output  ###
###########################################################################

sub print_stat{
        open(IN,"./result");
        while(<IN>) {
                chomp $_;
                @atemp = split(/\s+/,$_);
                if($_ =~ /mean/){
                        $mean = $atemp[2];
                }elsif($_ =~ /sigma/){
                        $dev = $atemp[2];
                }elsif($_ =~ /min/){
                        $min     = $atemp[2];
			@btemp   = split(/\(/, $_);
			@ctemp   = split(/\s+/, $btemp[1]);
			$min_pos = "($ctemp[1],$ctemp[2])";
                }elsif($_ =~ /max/){
                        $max = $atemp[2];
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
		if($_ =~ /max/){
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
        system("rm result result2") ;
}


##########################################################################
### find_10th: finding 10th brightest pisxel position and the count    ###
##########################################################################

sub find_10th {

	system("dmimghist infile=temp.fits outfile=outfile.fits hist=1::1 strict=no clobber=yes");
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

