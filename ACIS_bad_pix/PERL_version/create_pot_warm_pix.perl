#!/usr/bin/env /usr/local/bin/perl

#########################################################################################################
#													#
#	create_pot_warm_pix.perl: create count history of flickering + currently warm pixels		#
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


#-------------------------------------

for($ccd = 0; $ccd < 10; $ccd++){
	$hst = "$data_dir".'/Disp_dir/hist_ccd'."$ccd";
	$flk = "$data_dir".'/Disp_dir/flk_ccd'."$ccd";
	$ptn = "$data_dir".'/Disp_dir/bad_ccd'."$ccd".'_cnt';

#
#--- read history file
#
	open(FH, "$hst");
	@hist_file = ();

	$h_file[$i]  = '';
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/, $_);
		$hist_file[$atemp[0]] = $atemp[2];
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

		@atemp = split(/<>/, $_);

		print OUT "$atemp[0]"."<>"."$atemp[1]".'<>';

#
#---- extract and add pixels which are on flickering list but not curretnly warm
#
		if($hist_file[$atemp[0]] eq ''){
			if($atemp[2] ne ''){
				@btemp = split(/:/, $atemp[2]);
				foreach $comp (@btemp){
					if($comp ne ''){
						$chk++;
					}
				}
			}
		}else{
			@btemp = split(/:/, $hist_file[$atemp[0]]);
			foreach $comp (@btemp){
				if($comp ne ''){
					$chk++;
				}
			}
			if($atemp[2] ne ''){
				@ctemp = split(/:/, $atemp[2]);
				foreach $comp (@ctemp){
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
