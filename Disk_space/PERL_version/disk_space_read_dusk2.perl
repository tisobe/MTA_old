#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#                                                                                               #
#       disk_space_read_dusk2.perl: check /data/mta4/ disk space usages                         #
#                                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                               #
#               last update: Mar  14, 2013                                                      #
#                                                                                               #
#################################################################################################

#################################################################################
#
#--- set directories
#

open(FH, "/data/mta/Script/Disk_check/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
    }
close(FH);

#
#--- and other settings
#
#@name_list = ('AExtract','www','MTA_DOC','alert_test','space_weather','MTA');
@name_list = ('AExtract', 'www', 'HRC', 'CUS', 'Repos', 'Deriv');

$name_num  = 0;
foreach (@name_list){
        $name_num++;
}

$line          = `df -k /data/mta4/`;
@atemp         = split(/\s+/, $line);
OUTER:
foreach $ent (@atemp){
        if($ent =~ /\d/ && $ent !~ /vol/){
                $disk_capacity = $ent/100;
                last OUTER;
        }
}

$set_ymin = 10;
$set_ymax = 70;

#################################################################################

#
#---- here is the output from dusk
#
open(FH, "$run_dir/dusk_check2");

@capacity = ();
@name     = ();
$cnt = 0;
while(<FH>){
	chomp $_;
	@atemp = split(//, $_);
	if($atemp[0] =~ /\d/){
		@btemp = split(/\s+/, $_);
		push(@capacity, $btemp[0]);
		push(@name, $btemp[1]);
		$cnt++;
	}
}
close(FH);
#
#--- find today's date
#
($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}

$tyear  = $uyear;
$tmonth = $umon + 1;
$tday   = $umday;
#
#---- change date to dom format
#
conv_date_dom();

$temp_time = $dom + $uhour/24 + $umin/1440;
$date = sprintf "%6.3f",$temp_time;

for($k = 0; $k < $name_num; $k++){
	@{data.$k} = ();
}
@time = ();
$dcnt = 0;
#
#--- read the past data
#
open(FH, "$data_out/disk0_data_mta4");
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	push(@time, $atemp[0]);
	for($k = 0; $k < $name_num; $k++){
		$j = $k + 1;
		push(@{data.$k},$atemp[$j]);
	}
	$dcnt++;
}
close(FH);
#
#--- add new data
#
push(@time, $date);
OUTER:
for($i = 0; $i < $cnt; $i++){
	for($k = 0;$k < $name_num; $k++){
		if ($name[$i] eq $name_list[$k]){
			$ratio = $capacity[$i]/$disk_capacity;
			$ratio = sprintf "%5.2f",$ratio;
			push(@{data.$k},$ratio);
			next OUTER;
		}
	}
}
$dcnt++;
#
#-- update the database
#
open(OUT, ">$data_out/disk0_data_mta4");
for($i = 0; $i < $dcnt; $i++){
	print OUT "$time[$i]";
	for($k = 0; $k < $name_num; $k++){
		print OUT ":${data.$k}[$i]";
	}
	print OUT "\n";
}
close(OUT);

$min = $time[0];
$max = $time[$dcnt -1];
#
#---- special treatment; if there are not enough data, keep the plotting range small
#---- but after 50 days, make it as that of /data/mta/
#
if($dcnt >=  50){
	$min = 1745.600;
}
$diff = $max - $min;
if($diff == 0){
        $xmin = $min -1;
        $xmax = $max +1;
}else{
        $xmin = $min -  0.1 * $diff;
        $xmax = $max +  0.1 * $diff;
}

pgbegin(0, "/cps",1,1);
pgsubp(1,2);
pgsch(2);
pgslw(3);

$ymin = $set_ymin;
$ymax = $set_ymax;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
pgsch(2);
pgslw(3);
for($k = 0; $k < $name_num; $k++){
	$j = $k + 2;
	pgsci($j);
	pgmove($time[0], ${data.$k}[0]);
#
#--- special treatment, if there are not enough data points, use a marker
#
	if($dcnt < 50){
		pgpt(1, $time[0], ${data.$k}[0], 3);
	}
	for($i = 1; $i < $dcnt; $i++){
        	pgdraw($time[$i], ${data.$k}[$i]);
		if($dcnt < 50){
			pgpt(1, $time[$i], ${data.$k}[$i], 3);
		}
	}
	$xt = $xmin;
	$yt = $ymax -5.00 - 0.08 * $k *  ($ymax - $ymin);
	pgtext($xt, $yt, "$name_list[$k]");
}
pgsci(1);
pgsch(2);
pgslw(3);

pglabel("Time (DOM)","Disk Space Used (%)", "Disk Space Usage of /data/mta4/");
pgclos();

system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 | $op_dir/pnmcrop -bottom | $op_dir/ppmtogif > $fig_out/data_mta4.gif");
system('rm pgplot.ps');

#####################################################################
### conv_date_dom: change the time format to dom                  ###
#####################################################################

sub conv_date_dom{

        $ydiff = $tyear - 1999;
        $acc_date = 365 * $ ydiff;
        $add = int(0.25 * ($ydiff + 2));
        $acc_date += $add;

        if($tmonth == 1){
                $dom =   1;
        }elsif($tmonth == 2){
                $dom =  32;
        }elsif($tmonth == 3){
                $dom =  60;
        }elsif($tmonth == 4){
                $dom =  91;
        }elsif($tmonth == 5){
                $dom = 121;
        }elsif($tmonth == 6){
                $dom = 152;
        }elsif($tmonth == 7){
                $dom = 182;
        }elsif($tmonth == 8){
                $dom = 213;
        }elsif($tmonth == 9){
                $dom = 244;
        }elsif($tmonth == 10){
                $dom = 274;
        }elsif($tmonth == 11){
                $dom = 305;
        }elsif($tmonth == 12){
                $dom = 335;
        }

        $chk = 4.0 * int(0.25 * $tyear);
        if($chk == $tyear){
                if($tmonth > 2){
                        $dom++;
                }
        }

        $dom = $dom + $acc_date + $tday - 202;
}

