#!/usr/bin/env /usr/local/bin/perl

#########################################################################################################
#													#
#	create_pot_warm_col.perl: create count history of flickering + currently warm columns		#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last updated: Apr 15, 2013 								#
#													#
#########################################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

@dir_list = ();

#--- output directory

if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#------------------------------------------


for($ccd = 0; $ccd < 10; $ccd++){
	$hst = "$data_dir".'/Disp_dir/hist_col'."$ccd";
	$flk = "$data_dir".'/Disp_dir/flk_col'."$ccd";
	$ptn = "$data_dir".'/Disp_dir/bad_col'."$ccd".'_cnt';

#
#--- read history file
#
	open(FH, "$hst");
	@hist_file = ();

	$h_file[$i]  = '';
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/<>:/, $_);
		@btemp = split(/<>/,  $atemp[0]);
		if($btemp[0] < 0){
			next OUTER;
		}
		$hist_file[$btemp[0]] = $atemp[1];
	}
	close(FH);

#
#---- read flickering history file
#
	open(FH,  "$flk");
	open(OUT, ">$ptn");
	while(<FH>){
		chomp $_;
		$chk = 0;

		@atemp = split(/<>:/, $_);
		@btemp = split(/<>/,   $atemp[0]);

		print OUT "$atemp[0]".'<>';

#
#---- extract and add columns which are on flickering list but not curretnly warm
#
		if($hist_file[$btemp[0]] eq ''){
			if($atemp[1] ne ''){
				@ctemp = split(/:/, $atemp[1]);
				foreach $comp (@ctemp){
					if($comp ne ''){
						$chk++;
					}
				}
			}
		}else{
			@ctemp = split(/:/, $hist_file[$btemp[0]]);
			foreach $comp (@ctemp){
				if($comp ne ''){
					$chk++;
				}
			}
			if($atemp[2] ne ''){
				@dtemp = split(/:/, $atemp[1]);
				foreach $comp (@dtemp){
					if($comp ne ''){
						$chk++;
					}
				}
			}
		}
			
		print OUT ":$chk\n";
	}
	close(FH);
	close(OUT);
}
