#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	get_data.perl: obtain data for unprocessed data from the previous run	#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#	last update: Apr 15, 2013						#
#			modified to fit into a new directory system		#
#										#
#################################################################################

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

$dare   =`cat $bin_data/.dare`;
$hakama =`cat $bin_data/.hakama`;
chomp $dare;
chomp $hakama;

if($comp_test !~ /test/i){
	system("rm -rf $house_keeping/keep_entry");
}

open(FH, "$exc_dir/Working_dir/new_entry");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	$obsid = $atemp[0];
       	open(OUT, ">$exc_dir/Working_dir/input_line");
        print OUT "operation=retrieve\n";
        print OUT "dataset=flight\n";
        print OUT "detector=acis\n";
        print OUT "level=1\n";
        print OUT "version=last\n";
        print OUT "filetype=evt1\n";
        print OUT "obsid=$obsid\n";
        print OUT "go\n";
        close(OUT);

        system("echo $hakama  |arc4gl -U$dare -Sarcocc -i$exc_dir/Working_dir/input_line"); # here is the arc4gl
        system("gzip -d *gz");
	
	$name = '*'."$obsid".'*fits';
	system("ls $name > $exc_dir/Working_dir/zfits_test");
	open(IN, "$exc_dir/Working_dir/zfits_test");
	$chk = 0;
	OUTER:
	while(<IN>){
		chomp $_;
		if($_ =~ /\w/){
			$chk++;
			if($chk > 1){
				system("rm -rf $_");
			}
		}
	}
	close(IN);
	if($comp_test !~ /test/i){
		if($chk == 0){
			open(OUT2, ">> $house_keeping/keep_entry");
			print OUT2 "$obsid\n";
			close(OUT2);
		}
	}
}
close(FH);

system("rm -rf $exc_dir/Working_dir/*fits");
system("mv *.fits $exc_dir/Working_dir/");
system("rm -rf $exc_dir/Working_dir/input_line");
system("rm -rf $exc_dir/Working_dir/zfits_test");
