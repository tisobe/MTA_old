#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	find_new_entry.perl: find newly logged data from 				#
#			/data/mta/www/mp_reports/photons/acis/cti/6*			#
#		and	/data/mta/www/mp_reports/photons/acis/cti/5*			#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#	last update: Apr 15, 2013							#
#		copied from an old script						#
#											#
#########################################################################################

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

#
#--- get a list of entires from the report dir
#

#
#--- if this is the test case: ------------------------------------------------------
#

if($comp_test =~ /test/i){
	system("ls -rd $house_keeping/Test_data/*_* > $exc_dir/Working_dir/temp_list");

	open(FH,  "$exc_dir/Working_dir/temp_list");
	open(OUT, ">$exc_dir/Working_dir/new_entry");

	while(<FH>){
		chomp $_;
		@atemp = split(/Test_data\//, $_);
		@btemp = split(/_/, $atemp[1]);
		print OUT "$btemp[0]\n";
	}
	close(OUT);
	close(FH);

	exit 1;
}

#
#---- if this is the live case ------------------------------------------------------
#

system("ls -rd /data/mta/www/mp_reports/photons/acis/cti/6*_* >  $exc_dir/Working_dir/temp_list");
system("ls -rd /data/mta/www/mp_reports/photons/acis/cti/5*_* >> $exc_dir/Working_dir/temp_list");
system("cp $house_keeping/input_list $house_keeping/input_list~");

@temp_list  = ();
@input_list = ();
open(FH, "$exc_dir/Working_dir/temp_list");
while(<FH>) {
        chomp $_;
        @atemp = split(/cti\//, $_);
        @btemp = split(/_/,$atemp[1]);
        if($btemp[0] =~ /\d/) {
                push(@temp_list, $_);
        }
}
close(FH);

#
#---- get a list of the last entries
#

open(FH,"$house_keeping/input_list");
while(<FH>) {
        chomp $_;
        push(@input_list, $_);
}
close(FH);

OUTER:
foreach $comp (@temp_list) {            # find out which data is new
        @atemp = split(/cti\//,$comp);
        foreach $dir (@input_list) {
                @btemp = split(/cti\//,$dir);
                if($btemp[1] =~ /$atemp[1]/) {
                        next OUTER;
                }
        }
        push(@new_list, $comp);
}

foreach $new (@new_list) {
        push(@input_list, $new);        # append new data to the old one
}

open(RENE, ">$house_keeping/input_list");

foreach $dir (@input_list) {
       	print RENE "$dir\n";            # update the input_list
}
close(RENE);

open(FH, "$house_keeping/keep_entry");
while(<FH>){
	chomp $_;
	push(@keep_entry, $_);
}
close(FH);

#
#---- make a file with the new entries for the next script
#

open(RENE, ">$exc_dir/Working_dir/new_entry");

foreach $dir (@new_list){
	@atemp = split(/\//, $dir);
	@btemp = split(/_/, $atemp[8]);
	print RENE "$btemp[0]\n";
}
foreach $ent (@keep_entry){
	print RENE "$ent\n";
}

close(RENE);
