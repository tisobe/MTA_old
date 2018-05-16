#!/usr/bin/perl

#########################################################################################
#											#
#	hrc_doese_get_data_full_rage.perl: obtain HRC Evt 1 data for a month and create	#
#				 cumulative data fits files in multiple image files	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last updated: 10/06/2008							#
#											#
#########################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list3`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];

#
#---- usage: perl hrc_doese_get_data_full_rage.perl 2004 3 2004 3 <arc4gl user name> <passwd>
#----             this will compute for  March 2004 HRC S and I dose map.
#

$start_year  = $ARGV[0];
$start_month = $ARGV[1];
$end_year    = $ARGV[2];
$end_month   = $ARGV[3];
$user        = $ARGV[4];
$hakama      = $ARGV[5];
$out_dir     = $ARGV[6];

chomp $start_year;
chomp $start_month;
chomp $end_year;
chomp $end_month;
chomp $user;
chomp $hakama;
chomp $out_dir;

if($start_year !~/\d/ || $start_month !~/\d/ || $end_year!~ /\d/ || $end_month !~ /\d/
				 || $user eq '' || $hakama eq ''){
		print "usage: perl acis_dose_get_data.perl ";
		print "<start year> <start month> <end year> <end month>\n";
		exit 1;
}

$test = `ls `;
if($test !~ /param/){
	system("mkdir param");
}
if($test !~ /$out_dir/){
	system("mkdir Save");
}

$month_list1 = ();
$month_list2 = ();
$month_list3 = ();

$chk = 0;

#
#--- initial setting for month list
#
if($start_year == $end_year){
	for($i = $start_month; $i <= $end_month; $i++){
		push(@month_list2, $i);
	}
	$chk++;
}else{
	for($i = $start_month; $i <=12; $i++){
		push(@month_list1, $i);
	}
	for($i = 1; $i <= $end_month; $i++){
		push(@month_list3, $i);
	}
	@month_list2 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
}

#
#----- year and month iteration starts here
#
for($year = $start_year; $year <= $end_year; $year++){
	@atemp = split(//, $year);
	$short_year = "$atemp[2]$atemp[3]";
	if($chk == 1){
		@month_list = @month_list2;
	}else{
		if($year == $start_year){
			@month_list = @month_list1;
		}elsif($year == $end_year){
			@month_list = @month_list3;
		}else{
			@month_list = @month_list2;
		}
	}
	OUTER:
	foreach $month (@month_list){
		$smonth = $month;
		if($month < 10){
			$smonth = '0'."$month";
		}
#
#---- to keep each file small, we disect HRCI and HRCS into smaller pices.
#

		$out_file_i[0] = '/HRCI_'."$smonth".'_'."$year".'_0.fits';
		$out_file_i[1] = '/HRCI_'."$smonth".'_'."$year".'_1.fits';
		$out_file_i[2] = '/HRCI_'."$smonth".'_'."$year".'_2.fits';
		$out_file_i[3] = '/HRCI_'."$smonth".'_'."$year".'_3.fits';
		$out_file_i[4] = '/HRCI_'."$smonth".'_'."$year".'_4.fits';
		$out_file_i[5] = '/HRCI_'."$smonth".'_'."$year".'_5.fits';
		$out_file_i[6] = '/HRCI_'."$smonth".'_'."$year".'_6.fits';
		$out_file_i[7] = '/HRCI_'."$smonth".'_'."$year".'_7.fits';
		$out_file_i[8] = '/HRCI_'."$smonth".'_'."$year".'_8.fits';

		$out_file_s[0] = '/HRCS_'."$smonth".'_'."$year".'_0.fits';
		$out_file_s[1] = '/HRCS_'."$smonth".'_'."$year".'_1.fits';
		$out_file_s[2] = '/HRCS_'."$smonth".'_'."$year".'_2.fits';
		$out_file_s[3] = '/HRCS_'."$smonth".'_'."$year".'_3.fits';
		$out_file_s[4] = '/HRCS_'."$smonth".'_'."$year".'_4.fits';
		$out_file_s[5] = '/HRCS_'."$smonth".'_'."$year".'_5.fits';
		$out_file_s[6] = '/HRCS_'."$smonth".'_'."$year".'_6.fits';
		$out_file_s[7] = '/HRCS_'."$smonth".'_'."$year".'_7.fits';
		$out_file_s[8] = '/HRCS_'."$smonth".'_'."$year".'_8.fits';
		$out_file_s[9] = '/HRCS_'."$smonth".'_'."$year".'_9.fits';

		$line1 = "$smonth/01/$short_year".',00:00:00';
		$next_month = $month+1;
		if($next_month > 12){
			$next_month = '01';
			$next_year  = $short_year + 1;
			if($next_year == 100){
				$next_year = '00';
			}
			$line2 = "$next_month".'/01/'."$next_year".',00:00:00';
		}else{
			if($next_month < 10){
				$next_month = '0'."$next_month";
			}
			$line2 = "$next_month".'/01/'."$short_year".',00:00:00';
		}
#
#----- use arc4gl to extract HRC data
#
		open(OUT, ">./input_line");
		print OUT "operation=browse\n";
		print OUT "dataset=flight\n";
		print OUT "detector=hrc\n";
		print OUT "level=1\n";
		print OUT "filetype=evt1\n";
		print OUT "tstart=$line1\n";
		print OUT "tstop=$line2\n";
		print OUT "go\n";
		close(OUT);

		system('rm hrcf*evt1.fits*');

		`echo $hakama |arc4gl -U$user -Sarcocc -iinput_line >fits_list`;
		system("rm input_line");

		open(IN, "fits_list");
		@file_list = ();
		while(<IN>){
			chomp $_;
			@htemp = split(/\s+/, $_);
			if($htemp[0] =~ /hrcf/){
				push(@file_list, $htemp[0]);
			}
		}
		close(IN);
		system("rm fits_list");
		${hrci_cnt.0}  = 0;
		${hrci_cnt.1}  = 0;
		${hrci_cnt.2}  = 0;
		${hrci_cnt.3}  = 0;
		${hrci_cnt.4}  = 0;
		${hrci_cnt.5}  = 0;
		${hrci_cnt.6}  = 0;
		${hrci_cnt.7}  = 0;
		${hrci_cnt.8}  = 0;
		${hrcs_cnt.0}  = 0;

		${hrcs_cnt.1}  = 0;
		${hrcs_cnt.2}  = 0;
		${hrcs_cnt.3}  = 0;
		${hrcs_cnt.4}  = 0;
		${hrcs_cnt.5}  = 0;
		${hrcs_cnt.6}  = 0;
		${hrcs_cnt.7}  = 0;
		${hrcs_cnt.8}  = 0;
		${hrcs_cnt.9}  = 0;

		foreach $file (@file_list){

			open(OUT, ">./input_line");
			print OUT "operation=retrieve\n";
			print OUT "dataset=flight\n";
			print OUT "detector=hrc\n";
			print OUT "level=1\n";
			print OUT "filetype=evt1\n";
			print OUT "filename=$file\n";
			print OUT "go\n";
			close(OUT);


			`echo $hakama |arc4gl -U$user -Sarcocc -iinput_line`;
			system("rm input_line");

			system('gzip -d *gz');

#
#---- classify each HRC file into S or I file.
#
			system("dmlist infile=$file outfile=zout opt=head");
			open(FH, './zout');
			OUTER:
			while(<FH>){
				chomp $_;
				if($_ =~/DETNAM/){
					@atemp = split(/\s+/, $_);
					$detector = $atemp[2];
					$detector =~s/\s+//g;
					last OUTER;
				}
			}
			close(FH);
			system("rm zout");


			if($detector =~ /HRC-S/i){
#
#----- HRC-S
#
				@rstart= (   1, 4916,  9832, 14748, 19664, 24580, 29496, 34412, 39328, 44244);
				@rend  = (4915, 9831, 14747, 19663, 24579, 29495, 34411, 39327, 44243, 49159);
				for($i = 0; $i < 10; $i++){	
					$line = "$file".'[EVENTS][bin rawx=0:4095:1, rawy='."$rstart[$i]:$rend[$i]";
					$line = "$line".':1][status=xxxxxx00xxxxxxxxx000x000xx00xxxx][option type=i4,mem=100]';
	
					system("dmcopy \"$line\" out.fits  option=image  clobber=yes");

					system("dmstat out.fits centroid=no > stest");
					open(FH, "./stest");
					$chk = 0; 
					OUTER:
					while(<FH>){
						chomp $_;
						if($_ =~ /sum/){
							@atemp = split(/\s+/, $_);
							if($atemp[2] > 0){
								$chk = 1;
								last OUTER;
							}
						}
					}
					close(FH);

					
					if(${hrcs_cnt.$i} == 0){
						$fit_file = 'total_s'."$i".'.fits';
						$line     = 'out.fits[opt type=i4,null=-99]';
						system("dmcopy infile=\"$line\"  outfile=$fit_file clobber=yes");
					}elsif(${hrcs_cnt.$i} > 0){
						$fit_file = 'total_s'."$i".'.fits';
						$line     = 'out.fits[opt type=i4,null=-99]';
						system("dmcopy infile=\"$line\" outfile=temp3.fits clobber=yes");
						system("dmimgcalc infile=temp3.fits infile2=$fit_file outfile=mtemp.fits operation=add clobber=yes");
						system("mv mtemp.fits $fit_file");
					}
					${hrcs_cnt.$i}++;
					system("rm out.fits temp3.fits");
				}
			}else{
#
#---- HRC-I
#
#rawx=6144:10239:1, rawy=6144:10239:1]
				@x_start = (   1,    1,     1,  5462,  5462,  5462, 10924, 10924, 10924);
				@x_end   = (5461, 5461 , 5461, 10923, 10923, 10923, 16385, 16385, 16385);
				@y_start = (   1, 5462, 10924,     1,  5462, 10924,     1,  5562, 10942);
				@y_end   = (5461,10923, 16385,  5461, 10923, 16385,  5461, 10923, 16385);

				for($i = 0; $i < 9; $i++){
					$line = "$file".'[EVENTS][bin rawx='."$x_start[$i]:$x_end[$i]".':1,rawy=';
					$line = "$line"."$y_start[$i]:$y_end[$i]".':1][status=xxxxxx00xxxxxxxxx000x000xx00xxxx][option type=i4,mem=130]';
		
					system("dmcopy \"$line\" out.fits  option=image clobber=yes");
	
					system("dmstat out.fits centroid=no > stest");
					open(FH, "./stest");
					$chk = 0; 
					OUTER:
					while(<FH>){
						chomp $_;
						if($_ =~ /sum/){
							@atemp = split(/\s+/, $_);
							if($atemp[2] > 0){
								$chk = 1;
								last OUTER;
							}
						}
					}
					close(FH);
		
					if(${hrci_cnt.$i} == 0){
						$fit_file = 'total_i'."$i".'.fits';
						$line = 'out.fits[opt type=i4,null=-99]';
						system("dmcopy infile=\"$line\" outfile=$fit_file clobber=yes");
					}elsif(${hrci_cnt.$i} > 0){
						$fit_file = 'total_i'."$i".'.fits';
						$line     = 'out.fits[opt type=i4,null=-99]';
						system("dmcopy infile=\"$line\" outfile=temp3.fits clobber=yes");
						system("dmimgcalc infile=temp3.fits infile2=$fit_file outfile= mtemp.fits operation=add clobber=yes");
						system("mv mtemp.fits $fit_file");
					}
					${hrci_cnt.$i}++;
					system("rm out.fits temp3.fits");
				}
			}
			system("rm $file");
		}

		for($i = 0; $i < 10; $i++){
			if(${hrcs_cnt.$i} > 0){
				$fit_file = 'total_s'."$i".'.fits';
				system("mv $fit_file $out_dir/$out_file_s[$i]");
				system("gzip $out_dir/$out_file_s[$i]");
			}
		}

		for($i = 0; $i < 9; $i++){
			if(${hrci_cnt.$i} > 0){
				$fit_file = 'total_i'."$i".'.fits';
				system("mv $fit_file $out_dir/$out_file_i[$i]");
				system("gzip $out_dir/$out_file_i[$i]");
			}
		}
	}
}
