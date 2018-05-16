#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_bias_html_update.perl: update bias backgroud html page			#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Apr 15, 2013							#
#											#
#########################################################################################

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

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst) = localtime(time);
$uyear += 1900;
$month = $umon + 1;

$line =  "Last Update: $month/$umday/$uyear";

open(FH, "$house_keeping/bias_home.html");
open(OUT, "> ./temp");
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		print OUT "$line\n";
	}else{
		print OUT "$_\n";
	}
}
close(OUT);
close(FH);
system("mv ./temp $web_dir/bias_home.html");
