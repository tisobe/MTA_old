#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_ft_clean_month_data.perl: clean up month long data				#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Apr. 15, 2013							#
#											#
#########################################################################################
#
#--- check whether this is a test
#
$comp_test = $ARGV[0];
chomp $comp_test;

#######################################################################################
#
#---- diretory setting
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#######################################################################################

@data  = ();
open(FH, "$data_out/month_data");
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/,$_);
	$devi = 365;
	$chk       = 4 * int(0.25 * $atemp[0]);
	if($atemp[0] == $chk){
        	$devi = 366;
	}
	$time = $atemp[0] + $atemp[1]/$devi;
	push(@data,"$time\t$atemp[2]\t$atemp[3]\t$atemp[4]");
}
close(FH);
@data  = sort{$a<=>$b} @data;

$first    = shift(@data);
@atemp    = split(/\t/,$first);
$temp     = $atemp[1];
$atime    = $atemp[0];
@btemp    = split(/\./,$atemp[0]);
$ayear    = $btemp[0];

$devi     = 365;
$chk      = 4 * int(0.25 * $betemp[0]);
if($btemp[0] == $chk){
       	$devi = 366;
}

$ztemp    = '0.'."$btemp[1]";
$adate    = $ztemp*$devi;
@new_list = ("$ayear\t$adate\t$atemp[1]\t$atemp[2]\t$atemp[3]");

open(OUT, ">./new_data");
print OUT "$ayear\t$adate\t$atemp[1]\t$atemp[2]\t$atemp[3]\n";

OUTER:
foreach $ent (@data) {
	@atemp = split(/\t/,$ent);
	$ctemp = $atemp[1];
	$ctime = $atemp[0];
	@btemp = split(/\./,$atemp[0]);
	$cyear = $btemp[0];
	$devi  = 365;
	$chk   = 4 * int(0.25 * $btemp[0]);
	if($btemp[0] == $chk){
       		$devi = 366;
	}
	$ztemp = '0.'."$btemp[1]";
	$cdate = $ztemp*$devi;
	if($ctime == $atime) {
		next OUTER;
	}
	$atime = $ctime;
	print OUT "$cyear\t$cdate\t$ctemp\t$atemp[2]\t$atemp[3]\n";	
	$atime = $ctime;
	$ayear = $cyear;
	$adate = $cdate;
}
close(OUT);
system("mv new_data $data_out/month_data");

