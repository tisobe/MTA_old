#!/usr/bin/perl

@ind    = ();
@s_data = ();
$s_cnt  = 0;
open(FH, 'scelec_sine_data');
while(<FH>){
	chomp $_;
	@a = split(/\s+/, $_);
	$line = "$a[1]\t$a[2]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\n";
	push(@ind, $a[0]);
	push(@s_data, $line);
	$s_cnt++;
}
close(FH);
	

foreach $angle (40, 60, 80, 100, 120, 140, 160){

OUTER:
for($k = 0; $k < $s_cnt; $k++){
	if($angle == $ind[$k]){
		last OUTER;
	}
}
open(OUT, '>sine_data');
print OUT "$s_data[$k]";
close(OUT);

#
#--- input file name: e.g., scelec_angle120
#
	$name1 = './Ind_data_files/scelec_angle'."$angle";
#
#--- plotting a robust fit for elbi, elbv, hrmapower, obapower
#
##### 	system("perl Script/plot_scelec.perl $name1");
#
#--- extrac elbi data only and compute envelope for the data
#
	$name2 = './Ind_data_files/scelec_angle'."$angle".'_elbi_data';
	$name3 = './Ind_data_files/scelec_angle'."$angle".'_elbi_env.dat';
##	system("perl Script/sep_col.perl $name1 0  1");
##	system("mv temp_data $name2");
##	system("perl Script/find_moving_avg.perl $name2 0.01 4 $name3");
#
#--- extrac elbv data only and compute envelope for the data
#
	$name4 = './Ind_data_files/scelec_angle'."$angle".'_elbv_data';
	$name5 = './Ind_data_files/scelec_angle'."$angle".'_elbv_env.dat';
##	system("perl Script/sep_col.perl $name1 0  2");
##	system("mv temp_data $name4");
##	system("perl Script/find_moving_avg.perl $name4 0.15 3 $name5");
#
#--- extrac hrma data only and compute envelope for the data
#
	$name6 = './Ind_data_files/scelec_angle'."$angle".'_hrma_data';
	$name7 = './Ind_data_files/scelec_angle'."$angle".'_hrma_env.dat';
##	system("perl Script/sep_col.perl $name1 0  3");
##	system("mv temp_data $name6");
##	system("perl Script/find_moving_avg.perl $name6 0.01 4 $name7");
#
#--- extrac oba data only and compute envelope for the data
#
	$name8 = './Ind_data_files/scelec_angle'."$angle".'_oba_data';
	$name9 = './Ind_data_files/scelec_angle'."$angle".'_oba_env.dat';
##	system("perl Script/sep_col.perl $name1 0  4");
##	system("mv temp_data $name8");
##	system("perl Script/find_moving_avg.perl $name8 0.01 4 $name9");
#
#--- plot data with the envelopes computed above
#
	system("perl Script/plot_scelec_env.perl $name1 $name3 $name5 $name7 $name9");

	$name10 = './Plot_env/scelec_'."$angle".'.gif';
	system("mv env_plot.gif $name10");
}

system("rm sine_data");

