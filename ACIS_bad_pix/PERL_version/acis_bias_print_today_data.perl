#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	acis_bias_print_today_data.perl: this script print today's data list	#
#			                 for bias background computation	#
#										#
#		author: t. isobe (tisobe@cfa.harvard.edu)			#
#		last update: Apr 15, 2013					#
#										#
#################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;
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

#
#--- find out which data are new for today
#

if($comp_test =~ /test/i){
#
#--- test case
#
	system("ls /data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/Test_data/* >./Working_dir/today_input_data");
}else{
#
#--- normal case
#
	open(FH, "$house_keeping/past_input_data");
	@data1 = ();
	while(<FH>){
		chomp $_;
		push(@data1, $_);
	}
	close(FH);
	
	$first    = $data1[0];
	@atemp    = split(/\//,$first);
	@btemp    = split(/_/,$atemp[5]);
	$cut_date = "$btemp[0]$btemp[1]$btemp[2]";
	
	open(FH, "$house_keeping/past_input_data~");
	@data2 = ();
	
	while(<FH>){
		chomp $_;
		push(@data2, $_);
	}
	close(FH);
	
	$test = `ls -d `;
	if($test =~ /Working_dir/){
		system("rm -rf ./Working_dir/*");
	}else{
		system("mkdir ./Working_dir");
	}
	
	open(OUT, ">./Working_dir/today_input_data");
	
	OUTER:
	foreach $ent (@data1){
		foreach $comp (@data2){
			if($ent eq $comp){
				next OUTER;
			}
		}
		@atemp = split(/\//,$ent);
		@btemp = split(/_/,$atemp[5]);
		$date  = "$btemp[0]$btemp[1]$btemp[2]";
	
		if($date >= $cut_date){
			print OUT "$ent\n";
		}
	}
	
	close(OUT);
}
