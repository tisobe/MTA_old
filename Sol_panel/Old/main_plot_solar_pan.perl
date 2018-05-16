#!/usr/bin/perl

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = './Data_solar_pannel/solar_panel_angle'."$angle";
	$name2 = './Data_solar_pannel/solar_panel_angle'."$angle".'_tmysada_env.dat';
	$name3 = './Data_solar_pannel/solar_panel_angle'."$angle".'_tpysada_env.dat';
	$name4 = './Data_solar_pannel/solar_panel_angle'."$angle".'_tsamyt_sine.dat';
	$name5 = './Data_solar_pannel/solar_panel_angle'."$angle".'_tsapyt_sine.dat';
	$out   = './solar_panel_angle'."$angle".'.gif';

	open(FH, './fit_result_solar_pan');
	$criteria  = 'angle'."$angle".'_tsamyt';
	$criteria2 = 'angle'."$angle".'_tsapyt';
	OUTER:
	while(<FH>){
		chomp $_;
		if($_ =~ /$criteria/){
			$_ =~ s/\s+//g;
			@atemp = split(/:/, $_);
			@btemp = split(/<--->/, $atemp[1]);
			open(OUT, ">sine_data1");
			print OUT "$btemp[0]\t";
			print OUT "$btemp[1]\t";
			print OUT "$btemp[2]\t";
			print OUT "$btemp[3]\t";
			print OUT "$btemp[4]\t";
			print OUT "$btemp[6]\n";
			close(OUT);
		}elsif($_ =~ /$criteria2/){
			$_ =~ s/\s+//g;
			@atemp = split(/:/, $_);
			@btemp = split(/<--->/, $atemp[1]);
			open(OUT, ">sine_data2");
			print OUT "$btemp[0]\t";
			print OUT "$btemp[1]\t";
			print OUT "$btemp[2]\t";
			print OUT "$btemp[3]\t";
			print OUT "$btemp[4]\t";
			print OUT "$btemp[5]\n";
			close(OUT);
		}
	}
	close(FH);


	system("perl ./Script/plot_solar_array_env.perl $name1 $name2 $name3 $name4 $name5");
	system("mv env_plot.gif $out");
}
