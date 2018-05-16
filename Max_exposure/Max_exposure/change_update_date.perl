#!/usr/bin/perl

#################################################################################
#										#
#	change_update_date.perl: change update date to today's date		#
#										#
#	author: t isobe (tisobe@cfa.harvard.edu)				#
#										#
#	Last Update: Jan 06, 2006						#
#										#
#################################################################################

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year  = 1900   + $uyear;
$month = $umon  + 1;
if($umday < 10){
	$umday = "0$umday";
}
if($month < 10){
	$month = "0$month";
}

$line = "<br><H3> Last Update: $month/$umday/$year</H3>";


$in_list = `ls /data/mta_www/mta_max_exp/Plots/*html`;
@html_list = split(/\s+/, $in_list);

foreach $ent (@html_list){
	open(FH, "$ent");
	open(OUT, ">temp");
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
	system("mv temp $ent");
}
