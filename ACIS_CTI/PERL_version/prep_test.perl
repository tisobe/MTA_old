#!/usr/bin/env /usr/local/bin/perl

$org_data = '/data/mta/Script/ACIS/CTI/Data/';

$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

system("mkdir $data_dir");
system("cd $data_dir; mkdir Data119  Data2000  Data7000  Data_adjust  Data_cat_adjust Det_Data119  Det_Data2000  Det_Data7000  Det_Data_adjust  Det_Data_cat_adjust  Det_Results Results");

$input = `ls $org_data/*/*`;
@list  = split(/\s+/, $input);

foreach $ent (@list){
	open(FH, "$ent");
	open(OUT, ">ztemp");
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		@btemp = split(/T/, $atemp[0]);
		$time  = $btemp[0];
		$time  =~ s/-//g;
		if($time > 20120900){
			next OUTER;
		}
		print OUT "$_\n";
	}
	close(OUT);
	close(FH);

	@atemp = split(/\//, $ent);
	$cnt   = 0; 
	foreach(@atemp){
		$cnt++;
	}
	$out_name = "$data_dir"."$atemp[$cnt-2]".'/'."$atemp[$cnt-1]";
	system("mv ztemp $out_name");
}


