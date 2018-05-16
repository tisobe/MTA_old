#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#                                                                                               #
#       disk_space_read_dusk5.perl: check /data/swolk/disk space usages                         #
#                                                                                               #
#		this disk was /data/mays/ and /data/aaron/ prior to 10/29/08			#
#												#
#               author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                               #
#               last update: Mar  14, 2013                                                      #
#                                                                                               #
#################################################################################################

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

@name_list  = ('MAYS', 'AARON');
@name_list2 = ('MTA', 'BRAD', 'ANCHORS');					#/data/swolk/MAYS/
@name_list3 = ('BRAD','NADAMS', 'NBIZUNOK','OBSERVATIONS','SCIENCE','YAXX'); 	#/data/swolk/AARON/

$name_num  = 0;
foreach (@name_list){
        $name_num++;
}

$name_num2 = 0;
foreach (@name_list2){
        $name_num2++;
}

$name_num3 = 0;
foreach (@name_list3){
        $name_num3++;
}

$name_tot  = $name_num + $name_num2 + $name_num3;


$line          = `df -k /data/swolk/`;
@atemp         = split(/\s+/, $line);
OUTER:
foreach $ent (@atemp){
	if($ent =~ /\d/ && $ent !~ /vol/){
		$disk_capacity = $ent/100;
		last OUTER;
	}
}

$set_ymin = 0;
$set_ymax = 20;


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




#
#---- here is the output from dusk: /data/swolk/
#
#open(FH, "$run_dir/dusk_check5");
#
#@capacity = ();
#@name     = ();
#$cnt      = 0;
#while(<FH>){
#	chomp $_;
#	@atemp = split(//, $_);
#	if($atemp[0] =~ /\d/){
#		@btemp = split(/\s+/, $_);
#		push(@capacity, $btemp[0]);
#		push(@name,     $btemp[1]);
#		$cnt++;
#	}
#}
#close(FH);



#
#---- here is the output from dusk: /data/swolk/MAYS
#
open(FH, "$run_dir/dusk_check3");

@capacity2= ();
@name2    = ();
$mays_tot = 0;
$cnt2     = 0;
while(<FH>){
	chomp $_;
	@atemp = split(//, $_);
	if($atemp[0] =~ /\d/){
		@btemp = split(/\s+/, $_);
		push(@capacity2, $btemp[0]);
		push(@name2,     $btemp[1]);
		$mays_tot += $btemp[0];
		$cnt2++;
	}
}
close(FH);



#
#---- here is the output from dusk: /data/swolk/AARON
#
open(FH, "$run_dir/dusk_check4");

@capacity3= ();
@name3    = ();
$aaron_tot= 0;
$cn3      = 0;
while(<FH>){
	chomp $_;
	@atemp = split(//, $_);
	if($atemp[0] =~ /\d/){
		@btemp = split(/\s+/, $_);
		push(@capacity3, $btemp[0]);
		push(@name3,     $btemp[1]);
		$aaron_tot += $btemp[0];
		$cnt3++;
	}
}
close(FH);



@time = ();
$dcnt = 0;

#
#--- read the past data
#

open(FH, "$data_out/disk0_data_swolk");
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	push(@time, $atemp[0]);
	for($k = 0; $k < $name_tot; $k++){
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

#OUTER:
#for($i = 0; $i < $cnt; $i++){
#	for($k = 0;$k < $name_num; $k++){
#		if ($name[$i] eq $name_list[$k]){
#			$ratio = $capacity[$i]/$disk_capacity;
#			$ratio = sprintf "%5.2f",$ratio;
#			push(@{data.$k},$ratio);
#			next OUTER;
#		}
#	}
#}

$ratio = $mays_tot/$disk_capacity;
$ratio = sprintf "%5.2f",$ratio;
push(@{data.0}, $ratio);

$ratio = $aaron_tot/$disk_capacity;
$ratio = sprintf "%5.2f",$ratio;
push(@{data.1}, $ratio);

OUTER2:
for($i = 0; $i < $cnt2; $i++){
	for($k = 0;$k < $name_num2; $k++){
		if ($name2[$i] eq $name_list2[$k]){
			$ratio = $capacity2[$i]/$disk_capacity;
			$ratio = sprintf "%5.2f",$ratio;
			$l = $name_num + $k;
			push(@{data.$l},$ratio);
			next OUTER2;
		}
	}
}

OUTER3:
for($i = 0; $i < $cnt3; $i++){
	for($k = 0;$k < $name_num3; $k++){
		if ($name3[$i] eq $name_list3[$k]){
			$ratio = $capacity3[$i]/$disk_capacity;
			$ratio = sprintf "%5.2f",$ratio;
			$l = $name_num + $name_num2 + $k;
			push(@{data.$l},$ratio);
			next OUTER3;
		}
	}
}
$dcnt++;


#
#-- update the database
#

open(OUT, ">$data_out/disk0_data_swolk");
for($i = 0; $i < $dcnt; $i++){
	print OUT "$time[$i]";
	for($k = 0; $k < $name_tot; $k++){
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
        $min = 1745.6
}

$diff = $max - $min;
if($diff == 0){
        $xmin = $min -1;
        $xmax = $max +1;
}else{
        $xmin = $min -  0.1 * $diff;
        $xmax = $max +  0.1 * $diff;
}

#
#---- /data/swolk/
#


pgbegin(0, "/cps",1,1);
pgsubp(1,2);
pgsch(2);
pgslw(3);

$ymin = $set_ymin;
$ymax = $set_ymax;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
pgsch(2);
pgslw(3);
for($k = 0; $k < 2; $k++){
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
	$yt = ${data.$k}[0] + 0.03 * ($ymax - $ymin);
	$yt = $ymax -5.00 - 0.08 * $k *  ($ymax - $ymin);
	pgtext($xt, $yt, "$name_list[$k]");
}
pgsci(1);
pgsch(2);
pgslw(3);

pglabel("Time (DOM)","Disk Space Used (%)", "Disk Space Usage of /data/swolk/");
pgclos();

system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 | $op_dir/pnmcrop -bottom | $op_dir/ppmtogif > $fig_out/data_swolk.gif");
system('rm pgplot.ps');


#
#---- /data/swolk/MAYS and /data/swolk/AARON
#

#
#---- first MAYS
#

pgbegin(0, "/cps",1,1);
pgsubp(1,2);
pgsch(2);
pgslw(3);

$ymin = $set_ymin;
$ymax = 10;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
pgsch(2);
pgslw(3);
for($k = 0; $k < 3; $k++){
	$j = $k + 2;
	$m = $k + 2;
	pgsci($j);
	pgmove($time[0], ${data.$m}[0]);
#
#--- special treatment, if there are not enough data points, use a marker
#
        if($dcnt < 50){
                pgpt(1, $time[0], ${data.$m}[0], 3);
        }
	for($i = 1; $i < $dcnt; $i++){
        	pgdraw($time[$i], ${data.$m}[$i]);
                if($dcnt < 50){
                        pgpt(1, $time[$i], ${data.$m}[$i], 3);
                }
	}
	$xt = $xmin;
	$yt = ${data.$m}[0] + 0.03 * ($ymax - $ymin);
	$yt = $ymax -5.00 - 0.08 * $k *  ($ymax - $ymin);
	pgtext($xt, $yt, "$name_list2[$k]");
}
pgsci(1);
pgsch(2);
pgslw(3);

pglabel("Time (DOM)","Disk Space Used (%)", "Disk Space Usage of /data/swolk/MAYS");

#
#--- AARON
#

$ymin = $set_ymin;
$ymax = 15;

pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
pgsch(2);
pgslw(3);
for($k = 0; $k < 6; $k++){
	$j = $k + 2;
	$m = $k + 5;
	pgsci($j);
	pgmove($time[0], ${data.$m}[0]);
#
#--- special treatment, if there are not enough data points, use a marker
#
        if($dcnt < 50){
                pgpt(1, $time[0], ${data.$m}[0], 3);
        }
	for($i = 1; $i < $dcnt; $i++){
        	pgdraw($time[$i], ${data.$m}[$i]);
                if($dcnt < 50){
                        pgpt(1, $time[$i], ${data.$m}[$i], 3);
                }
	}
	$xt = $xmin;
	$yt = ${data.$m}[0] + 0.03 * ($ymax - $ymin);
	$yt = $ymax -5.00 - 0.08 * $k *  ($ymax - $ymin);
	pgtext($xt, $yt, "$name_list3[$k]");
}
pgsci(1);
pgsch(2);
pgslw(3);

pglabel("Time (DOM)","Disk Space Used (%)", "Disk Space Usage of /data/swolk/AARON");
pgclos();

system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 | $op_dir/pnmcrop -bottom | $op_dir/ppmtogif > $fig_out/data_mays_arron.gif");
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

