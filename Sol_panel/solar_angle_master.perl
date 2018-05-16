#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	solar_angle_master.perl: this is the master script to cotrol all others			#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Jun 05, 2013							#
#												#
#################################################################################################

#
#--- test case; set this "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- set directory
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#--- find today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
$this_year = 1900 + $uyear;
$uyday++;

#
#--- for the case, run only for year 2010
#
if($comp_test =~ /test/i){
        $this_year = 2010;
        print "This is a test run: gives 2010  data.\n";
}

#
#--- extract data using dataseeker
#

system("$op_dir/perl  $script_dir/extract_data_from_dataseek.perl $comp_test");

#
#--- check whether any new data is extracted. if not, terminate the procedure.
#

$test =`cat extract_test`;
chomp $test;
if($test == 0){
	system("rm -rf extract_test");
	print "\n\t\tNo new data. Exiting...\n\n";
	exit 1;
}
system("rm -rf extract_test");

#
#--- extract solar panel data
#

system("$op_dir/perl $script_dir/solar_panel_angle_comb.perl $this_year $comp_test");
system("$op_dir/perl $script_dir/sep_col_solar_pan.perl $comp_test");
system("$op_dir/perl $script_dir/find_env_solar_pan.perl $comp_test");
system("$op_dir/perl $script_dir/fit_sin_for_sol_pan.perl $comp_test");

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle";
	$name2 = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle".'_tmysada_env.dat';
	$name3 = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle".'_tpysada_env.dat';
	$name4 = "$data_dir".'/Plot_data/solar_panel_angle'."$angle".'_tsamyt_sine_param';
	$name5 = "$data_dir".'/Plot_data/solar_panel_angle'."$angle".'_tsapyt_sine_param';
	$out   = "$html_dir".'/Plots/solar_panel_angle'."$angle".'.gif';

	system("$op_dir/perl $script_dir/plot_solar_array_env.perl $name1 $name2 $name3 $name4 $name5 $comp_test");
	system("mv env_plot.gif $out");
}

#
#--- extract spacecraft electric power data
#

system("$op_dir/perl $script_dir/scelec_angle_comb.perl $this_year $comp_test");
system("$op_dir/perl $script_dir/sep_col_scelec.perl $comp_test");
system("$op_dir/perl $script_dir/find_env_scelec.perl $comp_test");
system("$op_dir/perl $script_dir/fit_sin_for_scelec.perl $comp_test");

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = "$data_dir".'/Data_scelec/scelec_angle'."$angle";
	$name2 = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_elbi_env.dat';
	$name3 = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_hrma_env.dat';
	$name4 = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_oba_env.dat';
	$name5 = "$data_dir".'/Plot_data/scelec_angle'."$angle".'_elbv_sine_param';
	$out   = "$html_dir".'/Plots/scelec_angle'."$angle".'.gif';

	system("$op_dir/perl $script_dir/plot_scelec_env.perl $name1 $name2 $name3 $name4 $name5 $comp_test");
	system("mv env_plot.gif $out");
}


#
#--- extract fine sensor temperature data
#

system("$op_dir/perl $script_dir/sensor_angle_comb.perl $this_year $comp_test");
system("$op_dir/perl $script_dir/sep_col_sensor.perl $comp_test");
system("$op_dir/perl $script_dir/find_env_sensor.perl $comp_test");

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = "$data_dir".'/Data_sensor/sensor_angle'."$angle";
	$name2 = "$data_dir".'/Data_sensor/sensor_angle'."$angle".'_tfssbkt1_env.dat';
	$name3 = "$data_dir".'/Data_sensor/sensor_angle'."$angle".'_tfssbkt2_env.dat';
	$name4 = "$data_dir".'/Data_sensor/sensor_angle'."$angle".'_tpc_fsse_env.dat';
	$out   = "$html_dir".'/Plots/sensor_angle'."$angle".'.gif';

	system("$op_dir/perl $script_dir/plot_sensor_env.perl $name1 $name2 $name3 $name4 $comp_test");
	system("mv env_plot.gif $out");
}

#
#---- sdsa temp and elbi relation
#

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = "$data_dir".'/Data_solar_panel/solar_panel_angle'."$angle".'_tpysada.dat';	
	$name2 = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_elbi.dat';
	$out   = "$html_dir".'/Plots/sada_elbi_angle'."$angle".'.gif';

	system("$op_dir/perl $script_dir/plot_elbi_sada.perl $name1 $name2 $comp_test");
	system("mv solpan_elbv.gif $out");
}


system("rm -rf pgplot.ps");

#
#--- update the html page (date of update only)
#

$date = `date`;
$line = "Last Update: $date";

open(FH, "$html_dir/solarpanel.html");
open(OUT, ">temp");
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		print OUT "$line\n";
	}else{
		print OUT "$_\n";
	}
}
close(OUT);
close(FH);

system("mv $html_dir/solarpanel.html $html_dir/solarpanel.html~");
system("mv temp $html_dir/solarpanel.html");

