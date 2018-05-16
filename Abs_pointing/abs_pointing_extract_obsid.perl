#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
#	abs_pointing_extract_obsid.perl: this script updates obsid_list	#
#			    which lists already processed objects	#
#	    use this after comp_second_time.perl			#
#									#
#	author: t. isobe (tisobe@cfa.harvard.edu)			#
#	last update:  Apr 16 , 2013					#
#		modified to fit a new directory system			#
#									#
#########################################################################
#
#---- cehck whether this is a test
#
$comp_test = $ARGV[0];
chomp $comp_test;

###################################################################
#
#---- setting directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

###################################################################

if($comp_test =~ /test/i){
	open(FH, "$data_dir/obsid_list");
}else{
	open(FH, "$house_keeping/obsid_list");
}
@obsid_list = ();
while(<FH>){
	chomp $_;
	push(@obsid_list, $_);
}
close(FH);

open(FH, "./known_coord");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@obsid_list, $atemp[0]);
}
close(FH);

$first = shift(@obsid_list);
@new = ($first);
OUTER:
foreach $ent (@obsid_list){
	foreach $comp (@new){
		if($ent == $comp){	
			next OUTER;
		}
	}
	push(@new, $ent);
}

@obsid_list = sort{$a<=>$b} @new;

if($comp_test =~ /test/i){
	open(OUT, ">$data_dir/obsid_list");
}else{
	open(OUT, ">$house_keeping/obsid_list");
}
foreach $ent (@obsid_list){
	print OUT "$ent\n";
}
close(OUT);

