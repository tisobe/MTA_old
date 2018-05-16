#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	gyro_drift_prep_data_html.perl: prepare gyrop data for html page 		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jun 05, 2013							#
#											#
#########################################################################################

#
#--- test whether tthis is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;
#
#---- read directories
#
if($comp_test =~ /test/i){
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list_test");
}else{
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list");
}
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#
#--- open three data files
#

foreach $craft ('pitch', 'roll', 'yaw'){
	$file_name = "$result_dir".'gyro_drift_hist_'."$craft";
	open(FH, "$file_name");
	while(<FH>){
		chomp $_;
		@atemp  = split(/\s+/, $_);
#
#--- use axTime3 to convert date into 2000:100:00:00:00 format
#
		$ttemp  = `axTime3 $atemp[0] u s t d`;
		@btemp  = split(/:/, $ttemp);
		$year   = $btemp[0];
		$yday   = $btemp[1];
		$time   = "$year".'.'."$yday";
		$before = $atemp[1];		#-- avg before the movement
		$middle = $atemp[2];		#-- avg during the movement
		$after  = $atemp[3];		#-- avg after the movement
		$inst   = $atemp[4];		#-- HETG or LETG
		$move   = $atemp[5];		#-- INSR or RETR

#
#--- make a time list once
#
		if($craft eq 'pitch'){
			if($inst =~ /HETG/ && $move =~ /INSR/i){
				push(@hi_time_list, $time);
			}elsif($inst =~ /HETG/ && $move =~ /RETR/i){
				push(@hr_time_list, $time);
			}elsif($inst =~ /LETG/ && $move =~ /INSR/i){
				push(@li_time_list, $time);
			}elsif($inst =~ /LETG/ && $move =~ /RETR/i){
				push(@lr_time_list, $time);
			}
		}
#
#-- save data in hash lists
#
		$head = "$inst".'_'."$move".'_'."$craft";
		%{$head.$time} = ( before => ["$before"],
				   middle => ["$middle"],
				   after  => ["$after"]
				  );
	}
	close(FH);
}

#
#--- now print out the results
#

open(OUT, ">HETG_INSR");
foreach $time (@hi_time_list){
	@atemp = split(/\./, $time);
	$year  = $atemp[0];
	$yday  = $atemp[1];

	print OUT  "$year\t$yday\t";
	print OUT "${HETG_INSR_pitch.$time}{before}[0]\t";
	print OUT "${HETG_INSR_pitch.$time}{middle}[0]\t";
	print OUT "${HETG_INSR_pitch.$time}{after}[0]\t";

	print OUT "${HETG_INSR_roll.$time}{before}[0]\t";
	print OUT "${HETG_INSR_roll.$time}{middle}[0]\t";
	print OUT "${HETG_INSR_roll.$time}{after}[0]\t";

	print OUT "${HETG_INSR_yaw.$time}{before}[0]\t";
	print OUT "${HETG_INSR_yaw.$time}{middle}[0]\t";
	print OUT "${HETG_INSR_yaw.$time}{after}[0]\n";
}
close(OUT);

open(OUT, ">HETG_RETR");
foreach $time (@hr_time_list){
	@atemp = split(/\./, $time);
	$year  = $atemp[0];
	$yday  = $atemp[1];

	print OUT  "$year\t$yday\t";
	print OUT "${HETG_RETR_pitch.$time}{before}[0]\t";
	print OUT "${HETG_RETR_pitch.$time}{middle}[0]\t";
	print OUT "${HETG_RETR_pitch.$time}{after}[0]\t";

	print OUT "${HETG_RETR_roll.$time}{before}[0]\t";
	print OUT "${HETG_RETR_roll.$time}{middle}[0]\t";
	print OUT "${HETG_RETR_roll.$time}{after}[0]\t";

	print OUT "${HETG_RETR_yaw.$time}{before}[0]\t";
	print OUT "${HETG_RETR_yaw.$time}{middle}[0]\t";
	print OUT "${HETG_RETR_yaw.$time}{after}[0]\n";
}
close(OUT);

open(OUT, ">LETG_INSR");
foreach $time (@li_time_list){
	@atemp = split(/\./, $time);
	$year  = $atemp[0];
	$yday  = $atemp[1];

	print OUT  "$year\t$yday\t";
	print OUT "${LETG_INSR_pitch.$time}{before}[0]\t";
	print OUT "${LETG_INSR_pitch.$time}{middle}[0]\t";
	print OUT "${LETG_INSR_pitch.$time}{after}[0]\t";

	print OUT "${LETG_INSR_roll.$time}{before}[0]\t";
	print OUT "${LETG_INSR_roll.$time}{middle}[0]\t";
	print OUT "${LETG_INSR_roll.$time}{after}[0]\t";

	print OUT "${LETG_INSR_yaw.$time}{before}[0]\t";
	print OUT "${LETG_INSR_yaw.$time}{middle}[0]\t";
	print OUT "${LETG_INSR_yaw.$time}{after}[0]\n";
}
close(OUT);

open(OUT, ">LETG_RETR");
foreach $time (@lr_time_list){
	@atemp = split(/\./, $time);
	$year  = $atemp[0];
	$yday  = $atemp[1];

	print OUT  "$year\t$yday\t";
	print OUT "${LETG_RETR_pitch.$time}{before}[0]\t";
	print OUT "${LETG_RETR_pitch.$time}{middle}[0]\t";
	print OUT "${LETG_RETR_pitch.$time}{after}[0]\t";

	print OUT "${LETG_RETR_roll.$time}{before}[0]\t";
	print OUT "${LETG_RETR_roll.$time}{middle}[0]\t";
	print OUT "${LETG_RETR_roll.$time}{after}[0]\t";

	print OUT "${LETG_RETR_yaw.$time}{before}[0]\t";
	print OUT "${LETG_RETR_yaw.$time}{middle}[0]\t";
	print OUT "${LETG_RETR_yaw.$time}{after}[0]\n";
}
close(OUT);
