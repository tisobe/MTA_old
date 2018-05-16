#!/usr/bin/perl

@ind = ();
@s_data = ();
$s_cnt  = 0;
open(FH, 'sol_sine_data1');
while(<FH>){
     chomp $_;
     @a = split(/\s+/, $_);
     $line = "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\n";
     push(@ind, $a[0]);
     push(@s_data, $line);
     $s_cnt++;
}
close(FH);

@ind2 = ();
@s_data2 = ();
$s_cnt2  = 0;
open(FH, 'sol_sine_data2');
while(<FH>){
     chomp $_;
     @a = split(/\s+/, $_);
     $line = "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\n";
     push(@ind2, $a[0]);
     push(@s_data2, $line);
     $s_cnt2++;
}
close(FH);

foreach $angle (40, 60, 80, 100, 120, 140, 160){

OUTER:
for($k = 0; $k < $s_cnt; $k++){
     if($angle == $ind[$k]){
        last OUTER;
     }
}
open(OUT, '>sine_data1');
print OUT "$s_data[$k]";
close(OUT);

open(OUT, '>sine_data2');
print OUT "$s_data2[$k]";
close(OUT);

#
#--- input file name: e.g., scelec_angle120
#
	$name1 = './Data/data_angle'."$angle";
#
#--- plotting a robust fit for elbi, elbv, hrmapower, obapower
#
##### 	system("perl Script/plot_scelec.perl $name1");
#
#--- extrac elbi data only and compute envelope for the data
#
	$name2 = './Data/data_angle'."$angle".'_sadany_data';
	$name3 = './Data/data_angle'."$angle".'_sadany_env.dat';
###	system("perl Script/sep_col.perl $name1 0  1");
###	system("mv temp_data $name2");
###	system("perl Script/find_moving_avg.perl $name2 0.20 3 $name3");
#
#--- extrac elbv data only and compute envelope for the data
#
	$name4 = './Data/data_angle'."$angle".'_sadapy_data';
	$name5 = './Data/data_angle'."$angle".'_sadapy_env.dat';
###	system("perl Script/sep_col.perl $name1 0  2");
###	system("mv temp_data $name4");
###	system("perl Script/find_moving_avg.perl $name4 0.20 3 $name5");
#
#--- extrac hrma data only and compute envelope for the data
#
	$name6 = './Data/data_angle'."$angle".'_solany_data';
	$name7 = './Data/data_angle'."$angle".'_solany_env.dat';
###	system("perl Script/sep_col.perl $name1 0  3");
###	system("mv temp_data $name6");
###	system("perl Script/find_moving_avg.perl $name6 0.30 3 $name7");
#
#--- extrac oba data only and compute envelope for the data
#
	$name8 = './Data/data_angle'."$angle".'_solapy_data';
	$name9 = './Data/data_angle'."$angle".'_solapy_env.dat';
###	system("perl Script/sep_col.perl $name1 0  4");
###	system("mv temp_data $name8");
###	system("perl Script/find_moving_avg.perl $name8 0.30  3 $name9");
#
#--- plot data with the envelopes computed above
#
	system("perl Script/plot_solar_array_env.perl $name1 $name3 $name5 $name7 $name9");

	$name10 = './Plot_env/solar_array_'."$angle".'.gif';
	system("mv env_plot.gif $name10");
}

system("rm sine_data");

