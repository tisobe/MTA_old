#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_ft_make_database.perl: collect data from Short_term database and		#
#			    mta_comprehensive_data_summary, make a database for		#
#			    plots and views						#
#											#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)					#
#	Jul 28, 2000:	version 0.1							#
#	Aug 29, 2000: 	version 0.2: now script get cold radiator information picewise	#
#				     so that it won't clog up memory			#
#	OCt 24, 2005:   bugged out and changed data spacing				#
#	Feb  2, 2006:	a bug related year change fixed					#
#											#
#	Last Update: May 24, 2013							#
#											#
#########################################################################################

#
#-- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

#######################################################################################
#
#---- diretory setting
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#######################################################################################

#
#--- find today's date
#
if($comp_test =~ /test/i){
	@today =  (0, 0, 0, 24, 1, 113, 1, 56, 0);
}else{
	@today  = localtime(time);
}

$day    = $today[7];
$year   = $today[5];
$year  += 1900;

$year_day  = 365;
$lyear     = $year -1;
$chk       = 4 * int(0.25 * $lyear);
if($lyear == $chk){
	$year_day = 366;
}
#
#--- when was the 3  months ago?
#
$month_ago = $day - 90;	
$year_mago = $year;
if($month_ago < 1) {
		$month_ago += $year_day;
		$year_mago--;
}
#
#--- when was the week ago (actually take 10 days for an error mergin)?
#
$week_ago = $day - 10;
$year_wago = $year;
if($week_ago < 1) {
		$week_ago += $year_day;
		$year_wago--;
}

#
#--- collect data about cold radiators from mta_comprehensive_data_summary
#--- todays_data contains only one day amount of data for radiator temperatures	
#

if($comp_test !~ /test/i){
	system("cat /data/mta/Script/OBT/MJ/todays_data >> $data_out/mj_month_data");

#
#---- remove duplicated lines;
#
	system("$op_dir/perl $bin_dir/acis_ft_rm_dupl.perl $data_out/mj_month_data");
	system("mv ./zout $data_out/mj_month_data");
}

@comp_date = ();
@comp_year = ();
@dom_date  = ();
@crat_data = ();
@crbt_data = ();
$line_no   = 0;

open(FH,  "$data_out/mj_month_data");
open(OUT, ">./temp_month_data");
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/, $_);
	@btemp = split(/:/,$atemp[0]);
	$year  = $btemp[0];
	$date  = $btemp[1] + $btemp[2]/24.0 + $btemp[3]/1440 + $btemp[4]/86400.0;

	push(@comp_year, $year);			# date is DOY
	push(@comp_date, $date);
	push(@crat_data, $atemp[3]);
	push(@crbt_data, $atemp[4]);

	@btemp = split(/:/, $date);
	$fday  = $btemp[0];
	$ftime = $btemp[1]/86400.;
	$fday += $ftime;

	if($year > 1999) {
		$add_date = 365 * ($year - 2000) + 163;
	}

	$add_date += int(0.25 * ($year - 1997));	# need one exta after leap year

	$dom_day = $fday + $add_date;
	push(@dom_date, $dom_day);

	$line_no++;
#
#--- updating mj_month_data dropping oldest one day amount of data
#
	if($year > $year_mago) {
		print OUT "$_\n";
	}elsif($year == $year_mago && $date >= $month_ago) {
		print OUT "$_\n";
	}
}
close(OUT);
close(FH);

system("mv ./temp_month_data $data_out/mj_month_data");

#
#---   first, we add new data for the long term database
#
#---   find unproccessed data and add back to the list
#
@data_list = ();		
if($comp_test !~ /test/i){
	open(FH, "$house_keeping/keep_data");
	while(<FH>){
		chomp $_;
		push(@data_list, $_);
	}
	close(FH);
}
#
#--- add new data name to data_list
#
open(FH, "./new_list");
@keep_data = ();
$keep_cnt  = 0;
while(<FH>){
	chomp $_;
	push(@data_list, $_);
}
close(FH);
#
#--- database for the entire period
#
open(OUT,">>$data_out/long_term_data");

foreach $file (@data_list) {
	@atemp       = split(/_/,$file);
	$year        = $atemp[0];
	$date_start  = $atemp[1];
	$time_start  = $atemp[2];
	$date_end    = $atemp[3];
	$time_end    = $atemp[4];
	
	@ctemp       = split(//,$time_start);
 	$shour       = "$ctemp[0]"."$ctemp[1]";
	$smin        = "$ctemp[2]"."$ctemp[3]";
	$tdate_start = $date_start + $shour/24. + $smin/1440;

	@ctemp       = split(//,$time_end);
	$ehour       = "$ctemp[0]"."$ctemp[1]";
	$emin        = "$ctemp[2]"."$ctemp[3]";
	$tdate_end   = $date_end + $ehour/24. + $emin/1440;


        if($year > 1999) {
                $add_date = 365*($year - 2000) + 163;
        }
#
#--- need one exta after leap year
#
        $add_date += int(0.25 * ($year - 1997));
	$date_mid  = 0.5*($tdate_start + $tdate_end) + $add_date;	# DOM format
#
#---   comparing date with that of cold radiators, we find a match.
#---   make an average of cold radiator temperature for that period
#
	$pos      = 0;
	$cnt      = 0;
	$crat_sum = 0;
	$crbt_sum = 0;

	foreach $cdate (@comp_date) {
		if($comp_year[$pos] == $year && $cdate >= $tdate_start && $cdate <= $tdate_end){
				$crat_sum += $crat_data[$pos];
				$crbt_sum += $crbt_data[$pos];
				$cnt++;
		}
		$pos++;
	}
#
#--- if no data in that period, put 999999
#
	if($cnt == 0) {
		$crat_avg = 999999.;
		$crbt_avg = 999999.;
#
#--- keep the data name which we could not find radiator temp for the future analysis
#
		push(@keep_data, $file);
		$keep_cnt++;
	}else{
		$crat_avg = $crat_sum/$cnt;
		$crbt_avg = $crbt_sum/$cnt;
	}
	
	$sum = 0;
	$cnt = 0;
	$name = "data_"."$file";
#
#---    get an average of the focal plane temperature of that period
#
	open(FH,"$short_term/$name");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/,$_);
		$date = $atemp[2];
		@btemp = split(/:/,$date);
		$day = $btemp[0];
		$time = $btemp[1]/86400.;
		$temp = $atemp[3];

		if($temp > -300 && $temp < -50) {
			$sum += $temp;
			$cnt++;
		}
	}
	close(FH);

	if($cnt != 0){
		if($crat_avg != 999999 && crbt_avg != 999999){
			$avg = $sum/$cnt;
			printf OUT ("%9.5f\t%9.5f\t%9.5f\t%9.5f\n"
				 ,$date_mid,$avg,$crat_avg,$crbt_avg);
		}
	}
}
close(OUT);
#
#--- keep the un-analyzed data file names in keep_data file
#
if($comp_test !~ /test/i){
	open(OUT,">$hosue_keeping/keep_data"); 
	foreach $ent (@keep_data){
		print OUT "$ent\n";
	}
	close(OUT);
}

system("$op_dir/perl $bin_dir/acis_ft_rm_dupl.perl $data_out/long_term_data");

#
#---	here we start making a detail one week database		
#
#--- detail data are in here
#
system("ls $short_term/data_* > ./zshort_term");
open(FH,"./zshort_term");
@data_list =();
while(<FH>) {
	chomp $_;
#	@atemp = split(/Short_term\//,$_);
	@atemp = split(/$short_term\//,$_);
	push(@data_list, $atemp[1]);
}
close(FH);
system("rm -rf ./zshort_term");

$fcnt = 0;
$ccnt = 0;
$cday = shift(@comp_date);
$out_check = 0;

#
#---  a week (10 days) long data
#

open(OUT, ">$data_out/week_data");	

foreach $dat (@data_list){
	@atemp = split(/_/,$dat);
	$year = $atemp[1];
	$day  = $atemp[2];
#
#--- select out data for last 10 days
#
	if(($year == $year_wago && $day > $week_ago)
		|| ($year > $year_wago)) {	
		open(FH, "$short_term/$dat");
		while(<FH>) {
			chomp $_;
			@atemp = split(/ /,$_);
			@dtemp = ();
			foreach $ent (@atemp) {
				 unless($ent eq '' || $ent =~ /\s/){
					 push(@dtemp, $ent);
				}
			}
			$date = $dtemp[1];
			@btemp = split(/:/,$date);
			$fday = $btemp[0];
			$ftime = $btemp[1]/86400.;
			$fday += $ftime;
			$temperature = $dtemp[2];
			if($year > 1999) {
				$add_date = 365*($year - 2000) + 163;
			}
			
			$add_date += int(0.25 * ($year - 1997));

			$dom_day = $fday +  $add_date;
#
#--- here we go; printing the database, year, day of year, temp, crat, crbt
#
			OUTER:
			while(){
				if($out_check == 1){
		
					$pyear = $year;
					$pday  = $fday;
					$ptemp = $temperature;
					$crat = 99999;
					$crbt = 99999;
					printf OUT ("%4d\t%9.5f\t%9.5f\t%9.5f\t%9.5f\n",
					$pyear, $pday, $ptemp, $crat, $crbt);

					last OUTER;
				}elsif($dom_day < $cday){
					$pyear = $year;
					$pday  = $fday;
					$ptemp = $temperature;
					$ccntm = $ccnt - 1;
					$crat  = 0.5*($crat_data[$ccntm]+$crat_data[$ccnt]);
					$crbt  = 0.5*($crbt_data[$ccntm]+$crbt_data[$ccnt]);
	
					unless($temperature > -50. || $temperature < -300){
					printf OUT ("%4d\t%9.5f\t%9.5f\t%9.5f\t%9.5f\n",
						$pyear, $pday, $ptemp, $crat, $crbt);
					}
					last OUTER;
				}else{
					if($ccnt >= $line_no) {
						$out_check = 1;
						last OUTER;
					}
					$cday = shift(@dom_date);
					$ccnt++;
				}
			}
		}
		close(FH);
	}
}
close(OUT);
#
#--- remove duplicated lines
#
system("$op_dir/perl $bin_dir/acis_ft_rm_dupl.perl $data_out/week_data");

#
#--- Month long data
#

#
#--- read a previous month_data, and then
#--- remove data older than one month ago
#
open(FH, "$data_out/month_data");
open(OUT,">./temp_data");
while(<FH>){
	chomp $_;
	@atemp = split(/\t/, $_);
	$year = $atemp[0];
	$date = $atemp[1];
	if($year > $year_mago){
		print OUT "$_\n";
	}elsif($year == $year_mago && $date > $month_ago){
		print OUT "$_\n";
	}
}
close(FH);
close(OUT);
system("mv temp_data $data_out/month_data");

#
#--- to reduce a data size, take an average of 20 data points (about 6mins)
#--- for a month data
#

open(FH, "$data_out/week_data");
open(OUT,">>$data_out/month_data");

$cnt = 0;
$sum_year = 0;
$sum_time = 0;
$sum_temp = 0;
$sum_rada = 0;
$sum_radb = 0;

while(<FH>){
	chomp $_;
	@atemp = split(/\t/,$_);
	if($cnt < 20){
		$sum_year += $atemp[0];
		$sum_time += $atemp[1];
		$sum_temp += $atemp[2];
		$sum_rada += $atemp[3];
		$sum_radb += $atemp[4];
		$cnt++;
	}else{
		$year = $sum_year/20.0;
		$time = $sum_time/20.0;
		$temp = $sum_temp/20.0;
		$rada = $sum_rada/20.0;
		$radb = $sum_radb/20.0;

		print OUT  "$year\t$time\t$temp\t$rada\t$radb\n";
		$sum_year = 0;
		$sum_time = 0;
		$sum_temp = 0;
		$sum_rada = 0;
		$sum_radb = 0;
		$cnt = 0;
	}
}

#
#--- remove duplicated lines
#
system("$op_dir/perl $bin_dir/acis_ft_rm_dupl.perl $data_out/month_data");

