#!/usr/bin/perl

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = './Data_sensor/sensor_angle'."$angle";
	$name2 = './Data_sensor/sensor_angle'."$angle".'_tfssbkt1_env.dat';
	$name3 = './Data_sensor/sensor_angle'."$angle".'_tfssbkt2_env.dat';
	$name4 = './Data_sensor/sensor_angle'."$angle".'_tpc_fsse_env.dat';
	$out   = './sensor_angle'."$angle".'.gif';

	system("perl ./Script/plot_sensor_env.perl $name1 $name2 $name3 $name4");
	system("mv env_plot.gif $out");
}
