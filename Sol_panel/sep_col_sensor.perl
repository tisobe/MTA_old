#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	sep_col_sensor.perl: separate fine sensor data into each element		#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 05, 2013						#
#											#
#########################################################################################

#
#--- test case; set this "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- set directory
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

if($data_dir eq ''){
        $data_dir = './';
}

@col_name = ('tfssbkt1', 'tfssbkt2', 'tpc_fsse');
foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$data = "$data_dir".'/Data_sensor/sensor_angle'."$angle";
	for($i = 1; $i < 4; $i++){
		$name = "$data_dir".'/Data_sensor/sensor_angle'."$angle".'_'."$col_name[$i -1]".'.dat';
		open(FH, "$data");
		open(OUT, ">$name");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			print OUT "$atemp[0]\t$atemp[$i]\n";
		}
		close(OUT);
		close(FH);
	}
}
