#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_ft_make_list.perl: this perl script prepare data for plotting		#
#	this is a part of csh script plotting_script.					#
#											#
#	author: Takashi Isobe	(tisobe@cfa.harvard.edu)				#
#	first version: 3/14/00								#
#	last update: May 15, 2013							#
#											#
#	You must set environment to: 							#
#		setenv ACISTOOLSDIR /home/pgf						#
#	before running this scripts (pgf scripts: getnrt and fptemp.pl)			#
#											#
#########################################################################################

#
#--- find whether this is a test case
#

$comp_test = $ARGV[0];
chomp $comp_test;

#########################################################
#
#---- directory setting
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
#########################################################

#
#--- old_list_short contains a list of data previously read into the data
#
if($comp_test =~ /test/i){
	open(FH,"$web_dir/old_list_short");
}else{
	open(FH,"$house_keeping/old_list_short");
}

@old_list_short = ();			
while(<FH>) {
        chomp $_;
	if($comp_test =~ /test/i){
        	@atemp = split(/\/data\/mta\/Script\/ACIS\/Focal\/house_keeping\/Test_prep\/DS_data\//, $_);
	}else{
        	@atemp = split(/\/dsops\/GOT\//, $_);
	}
#
#--- first find the date that the file is created.
#
        @btemp = split(/\s+/, $atemp[0]);
	$pos   = 0;
	foreach(@btemp){
		$pos++;
	}

      	$time = $btemp[$pos-1];
       	$cday = $btemp[$pos-2];
       	$lm   = $btemp[$pos-3];

        if($lm eq "Jan") {
                $cmonth = 1;
        }elsif($lm eq "Feb"){
                $cmonth = 2;
        }elsif($lm eq "Mar"){
                $cmonth = 3;
        }elsif($lm eq "Apr"){
                $cmonth = 4;
        }elsif($lm eq "May"){
                $cmonth = 5;
        }elsif($lm eq "Jun"){
                $cmonth = 6;
        }elsif($lm eq "Jul"){
                $cmonth = 7;
        }elsif($lm eq "Aug"){
                $cmonth = 8;
        }elsif($lm eq "Sep"){
                $cmonth = 9;
        }elsif($lm eq "Oct"){
                $cmonth = 10;
        }elsif($lm eq "Nov"){
                $cmonth = 11;
        }elsif($lm eq "Dec"){
                $cmonth = 12;
        }
        @dtemp = split(/_/,  $atemp[1]);
	@etemp = split(/\//, $dtemp[0]);
	if($etemp[0] eq 'input'){
		$cyear = $etemp[1];
	}else{
        	$cyear = $dtemp[0];
	}
#
#--- data list without the file information 
#--- (remove: -rw-r--r--   1 got      59420898 Mar  2 09:54
#---  and keep: /dsops/GOT/input/2006_088_2228_089_0409_Dump_EM_30564.gz)
#
	if($comp_test =~ /test/i){
        	$dat_name = '/data/mta/Script/ACIS/Focal/house_keeping/Test_prep/DS_data/'."$atemp[1]";
	}else{
        	$dat_name = '/dsops/GOT/'."$atemp[1]";
	}
	push(@old_list_short, $dat_name);
}
close(FH);

@old_list_short = sort(@old_list_short);		#	sorting 

#
#--- create a list from /dsops/GOT/input (for a new list)
#
if($comp_test =~ /test/i){
	system("cp  $house_keeping/Test_prep/DS_data/ds_list  ./zztemp");
}else{
	system("ls -ldtr  /dsops/GOT/input/*Dump_EM* > zztemp");
}

open(FH,"./zztemp");
@new_list     = ();
@new_save     = ();
@new_list_org = ();

while(<FH>) {
        chomp $_;
	$org_line = $_;
	if($comp_test =~ /test/i){
		@atemp = split(/\/data\/mta\/Script\/ACIS\/Focal\/house_keeping\/Test_prep\/DS_data\//, $_);
	}else{
       		@atemp = split(/\/dsops\/GOT\/input\//, $_);
	}

        @btemp = split(/\s+/, $atemp[0]);
	$pos   = 0;
	foreach(@btemp){
		$pos++;
	}

      	$time = $btemp[$pos-1];
       	$day  = $btemp[$pos-2];
       	$lm   = $btemp[$pos-3];

        if($lm eq "Jan") {
                $month = 1;
        }elsif($lm eq "Feb"){
                $month = 2;
        }elsif($lm eq "Mar"){
                $month = 3;
        }elsif($lm eq "Apr"){
                $month = 4;
        }elsif($lm eq "May"){
                $month = 5;
        }elsif($lm eq "Jun"){
                $month = 6;
        }elsif($lm eq "Jul"){
                $month = 7;
        }elsif($lm eq "Aug"){
                $month = 8;
        }elsif($lm eq "Sep"){
                $month = 9;
        }elsif($lm eq "Oct"){
                $month = 10;
        }elsif($lm eq "Nov"){
                $month = 11;
        }elsif($lm eq "Dec"){
                $month = 12;
        }

        @dtemp = split(/_/, $atemp[1]);
        $year  = $dtemp[0];

	if($comp_test =~ /test/i){
        	$dat_name = "$house_keeping".'Test_prep/DS_data/'."$atemp[1]";
	}else{
        	$dat_name = '/dsops/GOT/input/'."$atemp[1]";
	}
	@ftemp    = split(/_Dump_EM/, $atemp[1]);
#
#--- here we are comparing date of file creating. if there are
#
	if($year > $cyear) {
		push(@new_save,     $ftemp[0]);
		push(@new_list,     $dat_name);
		push(@new_list_org, $org_line);
#
#--- any file created after the last entry of the old list the data 
#--- name will be added in a new_list.
#
	}elsif($year == $cyear){
		if($month > $cmonth) {
			push(@new_save,     $ftemp[0]);
			push(@new_list,     $dat_name);
			push(@new_list_org, $org_line);
		}elsif($month == $cmonth){
			if($day > $cday) {
				push(@new_save,     $ftemp[0]);
				push(@new_list,     $dat_name);
				push(@new_list_org, $org_line);
			}elsif($day == $cday) {
				if($time > $ctime){
					push(@new_save,     $ftemp[0]);
					push(@new_list,     $dat_name);
					push(@new_list_org, $org_line);
				}
			}
		}
	}
}
close(FH);
#
#--- sort accroding to file name
#
@new_list = sort(@new_list);
system("rm -rf zztemp");		

#
#--- today's date
#

if($comp_test =~ /test/i){
	@time = (0, 0, 0, 24, 1, 113, 1, 56, 0);
}else{
	@time  = localtime(time);
}

$cyear = $time[5] + 1900;
$add   = 365*($cyear - 2000);

$m_ch = 0;
$w_ch = 0;
$s_ch = 0;

$year_day = 365;
$lyear = $cyear -1;
$chk   = 4 * int(0.25 * $lyear);
if($lyear == $chk){
	$year_day = 366;
}

#
#--- date of a month ago
#
$m_ago   = $time[7] - 30;
if($m_ago < 0){
        $m_ch = $year_day + $m_ago;
}
#
#--- date of a week ago
#
$w_ago    = $time[7] - 7 ;
if($w_ago < 0) {
        $w_ch = $year_day + $w_ago;
}
#
#--- date of 3 days ago
#
$d3ago  = $time[7] - 3 ;
if($d3ago < 0) {
        $s_ch = $year_day + $d3ago;
}

$today = $time[7];

if($comp_test =~ /test/i){
	open(OUT,">>$web_dir/old_list_short");
}else{
	open(OUT,">>$house_keeping/old_list_short");
}

foreach $ent (@new_list_org) {
	print OUT "$ent\n";
}
close(OUT);
#
#---- update old_list_short
#
open(OUT,">./today_list");
foreach $ent (@new_list){
	push(@old_list_short, $ent);
	print OUT "$ent\n";
#
#--- following is Peter Ford (pgf@space.mit.edu) script to extract data from dump data
#
	@stmp1 = split(/_Dump_EM/, $ent);
	if($comp_test =~ /test/i){
		@stmp2 = split(/\/data\/mta\/Script\/ACIS\/Focal\/house_keeping\/Test_prep\/DS_data\//,$stmp1[0]);
	}else{
		@stmp2 = split(/\/dsops\/GOT\/input\//,$stmp1[0]);
	}
#	system("gzip -dc $ent |$data_dir/Acis_ft/getnrt -O $*  | $bin_dir/acis_ft_fptemp.perl >> $short_term/data_$stmp2[1]");
	system("gzip -dc $ent |$data_dir/Acis_ft/getnrt -O  | $bin_dir/acis_ft_fptemp.perl >> $short_term/data_$stmp2[1]");
}
close(OUT);
#
#--- month data
#
@m_list  = ();
@w_list  = ();
@d3_list = ();
foreach $ent (@old_list_short) {
	@atemp = split(/_/,$ent);
	if($comp_test =~ /test/i){
		@btemp = split(/DS_data\//, $atemp[0]);
	}else{
		@btemp = split(/input\//,   $atemp[0]);
	}
	if($m_ch == 0) {
		if($btemp[1] >= $cyear && $atemp[1] >= $m_ago) {
			push(@m_list, $ent);	# m_list: month data list
		}
	}else{
		if($btemp[1] >= $lyear && $atemp[1] > $m_ch) {
			push(@m_list, $ent);
		}elsif($atemp[1] > 0 && $atemp[1] <= $today) {
			push(@m_list, $ent);
		}
	}
#
#--- week data
#
	if($lday == 0) {
		if($btemp[1] >= $cyear && $atemp[1] >= $w_ago) {
			push(@w_list, $ent);	# w_list: week data list
		}
	}else{
		if($btemp[1] >= $lyear && $atemp[1] > $w_ch) {
			push(@w_list, $ent);
		}elsif($atemp[1] > 0 && $atemp[1] <= $today) {
			push(@w_list, $ent);
		}
	}
#
#--- 3 day data
#
	if($lday == 0) {
		if($btemp[1] >= $cyear && $atemp[1] >= $d3ago) {
			push(@d3_list, $ent);	# d3_list: 3 day data list
		}
	}else{
		if($btemp[1] >= $lyear && $atemp[1] > $s_ch) {
			push(@d3_list, $ent);
		}elsif($atemp[1] > 0 && $atemp[1] <= $today) {
			push(@d3_list, $ent);
		}
	}
}

#
#--- in this block, try to figure out  which files are with in a day
#

@t_list = reverse (@old_list_short);
$last   = shift(@t_list);		
if($comp_test =~ /test/i){
	@ctemp = split(/DS_data\//, $last);
	$lval  = $ctemp[1];
}else{
#	@ctemp = split(/input\//, $last);
	$lval  = $last;
}

@btemp  = split(/_/,$lval);
$cyear  = $btemp[0];
$cday   = $btemp[3];
@btemp  = split(//, $btemp[4]);
$chr    = "$btemp[0]"."$btemp[1]";
$cmin   = "$btemp[2]"."$btemp[3]";

push(@d_list, $last);

OUTER:
foreach $ent (@t_list) {
	if($comp_test =~ /test/i){
		@ctemp = split(/DS_data\//, $ent);
		$ent2 = $ctemp[1];
	}else{
		@ctemp = split(/input\//, $ent);
#		$ent2 = $ctemp[1];
		$ent2 = $ent;
	}
	@ctemp = split(/_/,$ent2);
	$year  = $ctemp[0];
	$day   = $ctemp[3];
	@ctemp = split(//,$ctemp[4]);
	$hr    = "$ctemp[0]"."$ctemp[1]";
	$min   = "$ctemp[2]"."$ctemp[3]";
	$dyear = $cyear - $year;
	$dday  = $cday - $day;
	$dhr   = $chr -$hr;
	$dmin  = $cmin -$min;
	$diff  = $dyear * 525600 + $dday * 1440 + $dhr * 60 + dmin;

	if($diff < 1440) {
		push(@d_list, $ent);		# d_list: day data list
	}else {
		last OUTER;
	}
}

@d_list = reverse(@d_list);

#
#--- create a temporary file for a month
#
open(OUT,">./month_list");
foreach $data (@m_list){
	if($comp_test =~ /test/i){
		@ctemp = split('DS_data\/', $data);
		$ztemp = $ctemp[1];
	}else{
		@atemp = split(/\//,$data);
		if($atemp[3] eq 'input') {
			$ztemp = $atemp[4];
		}else{
			$ztemp = $atemp[3];
		}
	}
	@btemp = split(/_Dump_EM_/,$ztemp);
	$dname = 'data_'."$btemp[0]";
	print OUT "$dname\n";
}
close(OUT);

#
#--- create a temporary file for a week
#
open(OUT,">./week_list");
foreach $data (@w_list){
	if($comp_test =~ /test/i){
		@ctemp = split('DS_data\/', $data);
		$ztemp = $ctemp[1];
	}else{
		@atemp = split(/\//,$data);
		if($atemp[3] eq 'input') {
			$ztemp = $atemp[4];
		}else{
			$ztemp = $atemp[3];
		}
	}
	@btemp = split(/_Dump_EM_/,$ztemp);
	$dname = 'data_'."$btemp[0]";
	print OUT "$dname\n";
}
close(OUT);
#
#--- create a temporary file for 3 days
#
open(OUT,">./day3_list");
foreach $data (@d3_list){
	if($comp_test =~ /test/i){
		@ctemp = split('DS_data\/', $data);
		$ztemp = $ctemp[1];
	}else{
		@atemp = split(/\//,$data);
		if($atemp[3] eq 'input') {
			$ztemp = $atemp[4];
		}else{
			$ztemp = $atemp[3];
		}
	}
	@btemp = split(/_Dump_EM_/,$ztemp);
	$dname = 'data_'."$btemp[0]";
	print OUT "$dname\n";
}
close(OUT);
#
#--- create a temporary file for a day
#
open(OUT,">./day_list");
foreach $data(@d_list){
	if($comp_test =~ /test/i){
		@ctemp = split('DS_data\/', $data);
		$ztemp = $ctemp[1];
	}else{
		@atemp = split(/\//,$data);
		if($atemp[3] eq 'input') {
			$ztemp = $atemp[4];
		}else{
			$ztemp = $atemp[3];
		}
	}
	@btemp = split(/_Dump_EM_/,$ztemp);
	$dname = 'data_'."$btemp[0]";
	print OUT "$dname\n";
}
close(OUT);

open(OUT, ">./new_list");
foreach $ent (@new_save){
	print OUT "$ent\n";
}
close(OUT);
