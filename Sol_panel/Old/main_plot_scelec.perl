#!/usr/bin/perl

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	$name1 = './Data_scelec/scelec_angle'."$angle";
	$name2 = './Data_scelec/scelec_angle'."$angle".'_elbi_env.dat';
	$name3 = './Data_scelec/scelec_angle'."$angle".'_elbv_sine.dat';
	$name4 = './Data_scelec/scelec_angle'."$angle".'_hrma_env.dat';
	$name5 = './Data_scelec/scelec_angle'."$angle".'_oba_env.dat';
	$out   = './scelec_angle'."$angle".'.gif';

	open(FH, './fit_result_scelec');
	$citeria = 'angle'."$angle".'_elbv';
	OUTER:
	while(<FH>){
		chomp $_;
		if($_ =~ /$criteria/){
			$_ =~ s/\s+//g;
			@atemp = split(/:/, $_);
			@btemp = split(/<--->/, $atemp[1]);
			open(OUT, ">sine_data");
			print OUT "$btemp[0]\t";
			print OUT "$btemp[1]\t";
			print OUT "$btemp[2]\t";
			print OUT "$btemp[3]\t";
			print OUT "$btemp[4]\t";
			print OUT "$btemp[6]\n";
			close(OUT);
		}
	}
	close(FH);

	system("perl ./Script/plot_scelec_env.perl $name1 $name2 $name3 $name4 $name5");
	system("mv env_plot.gif $out");
}
