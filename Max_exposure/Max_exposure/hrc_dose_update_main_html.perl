#!/usr/bin/perl

#################################################################################
#										#
#	hrc_dose_update_main_html.perl: update web page date entry		#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: Aug 19, 2005						#
#										#
#################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list4`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];
$web_dir  = $dir_list[2];


#
#--- get today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year   = 1900   + $uyear;
$month  = $umon  + 1;

$new_line = '<br><br><H3> Last Update: '."$month/$umday/$year".'</H3>';

open(FH,"$web_dir/exposure.html");
open(OUT, "> ./temp");
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		print OUT "$new_line\n";
	}else{
		print OUT "$_\n";
	}
}
close(OUT);
close(FH); 
system("mv ./temp $web_dir/exposure.html");

open(FH,"$web_dir/HRC/full_hrc_exposure_map.html");
open(OUT, "> ./temp");
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		print OUT "$new_line\n";
	}else{
		print OUT "$_\n";
	}
}
close(OUT);
close(FH); 
system("mv ./temp $web_dir/HRC/full_hrc_exposure_map.html");
