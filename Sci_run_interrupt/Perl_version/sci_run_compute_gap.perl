#!/usr/bin/perl

#########################################################################################
#											#
#	sci_run_compute_gap.perl: compute science time lost 				#
#				(interuption total - radiation zone)			#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Mar 26, 2012						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

open(FH, "/data/mta/Script/Interrupt/house_keeping/dir_list");

@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$data_dir      = $atemp[1];
$web_dir       = $atemp[2];
$house_keeping = $atemp[3];

#################################################################

$file  = $ARGV[0];
open(FH, "$file");
$input = <FH>;
close(FH);
chomp $input;
@atemp = split(/\s+/, $input);

$name  = $atemp[0];
$begin = $atemp[1];
$end   = $atemp[2];
$ind   = $atemp[4];		#--- auto or manual

@atemp   = split(/:/, $begin);
$start   = conv_date_dom($atemp[0], $atemp[1], $atemp[2]) + $atemp[3]/24 + $atemp[4]/1440;

@atemp   = split(/:/, $end);
$stop    = conv_date_dom($atemp[0], $atemp[1], $atemp[2]) + $atemp[3]/24 + $atemp[3]/1440;

$tot_int = $stop - $start;

extract_rad_zone_info();

$sum = 0;
OUTER:
foreach $ent (@rad_entry){
	$ent =~ s/\(//;
	$ent =~ s/\)//;
	@atemp = split(/\,/, $ent);
	if($atemp[1] < $start){
		next OUTER;
	}elsif($atemp[0] > $stop){
		last OUTER;
	}elsif($atemp[0] >= $start && $atemp[1] <= $stop){
		$diff  = $atemp[1] - $atemp[0];
	}elsif($atemp[0] < $start && $atemp[1] > $start){
		$diff  = $atemp[1] - $start;
	}elsif($atemp[0] < $stop  && $atemp[1] > $stop){
		$diff = $stop - $atemp[0];
	}
	$sum += $diff;
}

$adj_int = sprintf "%4.1f",86.4 * ($tot_int - $sum);
print "$name\t$begin\t$end\t$adj_int\t$ind\n";


open(FH, "$house_keeping/all_data");
@input = ();
while(<FH>){
	chomp $_;
	push(@input, $_);
}
close(FH);
@temp  = sort{$a<=>$b} @input;
@rtemp = reverse(@temp);

$chk = 0;
OUTER:
foreach $ent (@rtemp){
	@atemp = split(/\s+/, $ent);
	if($atemp[0] =~ /$name/){
		$chk++;
		last OUTER;
	}
}
		
open(OUT, '>./temp_file');
if($chk == 0){
	print OUT "$name\t$begin\t$end\t$adj_int\t$ind\n";
	foreach $ent (@rtemp){
		print OUT "$ent\n";
	}
}else{
	foreach $ent (@rtemp){
		@atemp = split(/\s+/, $ent);
		if($atemp[0] =~ /$name/){
			print OUT "$name\t$begin\t$end\t$adj_int\t$ind\n";
		}else{
			print OUT "$ent\n";
		}
	}
}
close(OUT);


####system("mv $house_keeping/all_data $house_keeping/all_data~");
####system("mv temp_file $house_keeping/all_data");


##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

##################################################
#       Input   $tyear: year
#               $tmonth: month
#               $tday:   day of the month
#
#       Output  $ydate: day from Jan 1<--- returned
##################################################

        my($tyear, $tmonth, $tday, $ydate, $chk);
        ($tyear, $tmonth, $tday) = @_;

        if($tmonth == 1){
                $ydate = $tday;
        }elsif($tmonth == 2){
                $ydate = $tday + 31;
        }elsif($tmonth == 3){
                $ydate = $tday + 59;
        }elsif($tmonth == 4){
                $ydate = $tday + 90;
        }elsif($tmonth == 5){
                $ydate = $tday + 120;
        }elsif($tmonth == 6){
                $ydate = $tday + 151;
        }elsif($tmonth == 7){
                $ydate = $tday + 181;
        }elsif($tmonth == 8){
                $ydate = $tday + 212;
        }elsif($tmonth == 9){
                $ydate = $tday + 243;
        }elsif($tmonth == 10){
                $ydate = $tday + 273;
        }elsif($tmonth == 11){
                $ydate = $tday + 304;
        }elsif($tmonth == 12 ){
                $ydate = $tday + 333;
        }
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }
        return $ydate;
}


###################################################################################
### read_rad_zone: read rad zone and create the list for the specified period   ###
###################################################################################

sub extract_rad_zone_info{
        my ($start, $stop, @pstart, @pstop, @dom);
        open(FH,"$house_keeping/rad_zone_info");

        @ind    = ();
        @rtime  = ();
        @rtime2 = ();
        $rtot   = 0;

        while(<FH>){
                chomp $_;
                @atemp = split(/\s+/, $_);
                push(@ind,    $atemp[0]);
                push(@rtime,  $atemp[1]);
                push(@rtime2, $atemp[2]);
                $rtot++;
        }
        close(FH);

        @atemp = split(/:/, $begin);
        $dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
        $start = $dom - 8;

        @atemp = split(/:/, $end);
        $dom   = conv_date_dom($atemp[0],$atemp[1],$atemp[2]);
        $stop  = $dom + 8;

        @pstart = ();
        @pstop  = ();
        $pcnt   = 0;
        OUTER:
        for($i = 0; $i < $rtot; $i++){
                if($rtime[$i] < $start){
                        next OUTER;
                }elsif($rtime[$i] >= $start && $rtime[$i] < $stop){
                        if($ind[$i] =~ /ENTRY/i){
                                push(@pstart, $rtime[$i]);
                        }elsif($ind[$i] =~ /EXIT/i){
                                if(($pstart[$pcnt] != 0) && ($pstart[$pcnt] < $rtime[$i])
){
                                        push(@pstop, $rtime[$i]);
                                        $pcnt++;
                                }
                        }
                }elsif($rtime[$i] > $stop){
                        last OUTER;
                }
        }


        @rad_entry = ();
        for($i = 0; $i < $pcnt; $i++){
                $line = "($pstart[$i],$pstop[$i])";
                push(@rad_entry, $line);
        }
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
                $acc_date += 335;
        }
        $acc_date -= 202;
        return $acc_date;
        return $acc_date;
}

