#!/usr/bin/perl

open(OUT1, "> ./monthly_diff");
open(OUT2, "> ./monthly_acc");
foreach $inst ('i','s'){
	for($iccd = 2; $iccd < 4; $iccd++){
		print OUT1 "\n";
		print OUT2 "\n";
		for($node = 0; $node < 4; $node++){
			$file1 = '/data/mta/www/mta_max_exp/Data/'."$inst".'_'."$iccd".'_n_'."$node".'_dff_out';
			$file2 = '/data/mta/www/mta_max_exp/Data/'."$inst".'_'."$iccd".'_n_'."$node".'_acc_out';
	
			open(FH, "$file1");
			while(<FH>){
				chomp $_;
				$line = $_;
			}
			close(FH);
			$uinst = uc($inst);
			@atemp = split(/\s+/, $line);
			print  OUT1 " $uinst$iccd node $node  262654\t";  
			printf OUT1 "%3.6f\t%3.6f\t%3.1f\t%5.1f\n", $atemp[2], $atemp[3], $atemp[4], $atemp[6];
	
			open(FH, "$file2");
			while(<FH>){
				chomp $_;
				$line = $_;
			}
			close(FH);
			$uinst = uc($inst);
			@atemp = split(/\s+/, $line);
			print  OUT2 " $uinst$iccd node $node  262654\t";  
			printf OUT2 "%3.6f\t%3.6f\t%3.1f\t%5.1f\n", $atemp[2], $atemp[3], $atemp[4], $atemp[6];
		}
	}
}
close(OUT1);
close(OUT2);


