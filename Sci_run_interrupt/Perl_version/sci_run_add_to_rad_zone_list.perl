#!/usr/bin/perl

#################################################################################################
#												#
#	sci_run_add_to_rad_zone_list.perl: add radiation zone list around a given date		#
#												#
#		author: t. isobe (tisobe@cfa.harvarad.edu)					#
#												#
#		last update: Jun 09, 2011							#
#												#
#################################################################################################
	
#################################################################
#
#--- setting directories
#

open(FH, '/data/mta/Script/Interrupt/house_keeping/dir_list');
@list = ();
while(<FH>){
	chomp $_;
	push(@list, $_);
}
close(FH);

$bin_dir       = $list[0];
$data_dir      = $list[1];
$web_dir       = $list[2];
$house_keeping = $list[3];

#################################################################

$file      = $ARGV[0];
@time_list = ();

open(FH, "$file");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@time_list, $atemp[1]);
}
close(FH);

#
#--- a starting date of the interruption in yyyy:mm:dd:hh:mm (e.g., 2006:03:20:10:30)
#

foreach $time (@time_list){

	@atemp = split(/:/, $time);
	$year  = $atemp[0];
	$month = $atemp[1];
	$date  = $atemp[2];

#
#--- date for the list
#

	$list_date = "$year$month$date";

#
#--- change to DOM
#

	find_dom();

#
#--- check radiation zones for 3 days before to 5 days after from the interruptiondate
#

	$begin = $dom - 3;
	$end   = $dom + 7;

#
#--- read radiation zone infornation
#

	open(FH, "$house_keeping/rad_zone_info");

	@status = ();
	@date   = ();
	$chk    = 0;
	$lst_st = '';
	$cnt    = 0;
	
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($chk == 0 && $atemp[0] =~ /ENTRY/i && $atemp[1] >= $begin){
			push(@status, $atemp[0]);
			push(@date,   $atemp[1]);
			$chk++;
			$last_st = $atemp[0];
			$cnt++;
		}elsif($chk > 0 && $atemp[1] >= $begin && $atemp[1] <= $end){
			push(@status, $atemp[0]);
			push(@date,   $atemp[1]);
			$last_st = $atemp[0];
			$cnt++;
		}elsif($atemp[1] >= $end && $last_st =~ /EXIT/i){
			last OUTER;
		}elsif($atemp[1] >= $end && $last_st =~ /ENTRY/i){
			push(@status, $atemp[0]);
			push(@date,   $atemp[1]);
			$cnt++;
			last OUTER;
		}
	}
	close(FH);

#
#--- print out the radiation zone data
#

	open(OUT, '>temp_zone');
	print OUT "$list_date\t";
	$i = 0;
	while($i < $cnt){
		print OUT "($date[$i],";
		$i++;
		if($i < $cnt -1){
			print OUT "$date[$i]):";
		}else{
			print OUT "$date[$i])\n";
		}
		$i++;
	}
	
	open(FH, "$house_keeping/rad_zone_list");
	while(<FH>){
		print OUT "$_";
	}
	close(FH);
	close(OUT);
	
	system("mv $house_keeping/rad_zone_list $house_keeping/rad_zone_list~");
	system("mv temp_zone $house_keeping/rad_zone_list");
}

###############################################################################
### find_dom: find DOM from year:month:mdate:hour:min                       ###
###############################################################################

sub find_dom{
        @btemp = split(/:/, $time);
	$dom = conv_date_dom($btemp[0], $btemp[1], $btemp[2]);
        $dom = $dom + $btemp[3]/24 + $btemp[4]/1440.0;
}


###########################################################################
###      conv_date_dom: modify data/time format                       #####
###########################################################################

sub conv_date_dom {

#############################################################
#       Input:  $year: year in a format of 2004
#               $month: month in a formt of  5 or 05
#               $day:   day in a formant fo 5 05
#
#       Output: acc_date: day of mission returned
#############################################################

        my($year, $month, $day, $chk, $acc_date);

        ($year, $month, $day) = @_;

        $acc_date = ($year - 1999) * 365;

        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }elsif($year > 2020) {
                $acc_date += 6;
        }elsif($year > 2024) {
                $acc_date += 7;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                $chk = 4.0 * int(0.25 * $year);
                if($year == $chk) {
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
        $acc_date -= 202;
        return $acc_date;
}

