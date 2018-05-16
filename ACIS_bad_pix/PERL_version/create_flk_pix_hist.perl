#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	create_flk_pix_hist.perl: create flickering warm pixel history files, count	#
#				  history file, cumlative warm pixel count histor 	#
#				  files (all warm pixels appeared even only once in	#
#				  the entire mission)					#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Apr 15, 2013						#
#											#
#########################################################################################

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



#-----------------------------------------

for($ccd = 0; $ccd < 10; $ccd++){
#
#--- set input/output file names
#
	$hst_ccd     = "$data_dir".'/Disp_dir/hist_ccd'."$ccd";		#--- warm pix history file
	$new_ccd     = "$data_dir".'/Disp_dir/new_ccd'."$ccd";		#--- use this (new_ccd#) for input
	$flk_ccd     = "$data_dir".'/Disp_dir/flk_ccd'."$ccd";		#--- flickering pix hist
	$flk_ccd_cnt = "$data_dir".'/Disp_dir/flk_ccd'."$ccd".'_cnt';	#--- flickering pix count hist
	$cum_ccd     = "$data_dir".'/Disp_dir/cum_ccd'."$ccd".'_cnt';	#--- cumulative # of warm pix

	$flickering_bad = "$data_dir".'/Disp_dir/flickering'."$ccd";

#
#--- read currently active warm pixel list
#

	open(FH,   "$hst_ccd");
	@hist_pix = ();
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/,  $_);
		$dom   = $atemp[0];
		$hist_pix[$dom] = $atemp[2];
	}
	close(FH);

	open(FH,   "$new_ccd");
	open(OUT1, ">$flk_ccd");
	open(OUT2, ">$flk_ccd_cnt");
	open(OUT3, ">$cum_ccd");

	$cum_cnt   = 0;
	@flikering = ();

	while(<FH>){
		chomp $_;
		@atemp     = split(/<>/, $_);
		$dom       = $atemp[0];
		$date      = $atemp[1];
		@today_flk = ();

		print OUT1 "$dom".'<>'."$date".'<>';

		print OUT2 "$dom".'<>'."$date".'<>';

		print OUT3 "$dom".'<>'."$date".'<>';

		if($atemp[2] =~ /\(/){
			@btemp = split(/<>:/, $_);
			@pixs  = split(/:/, $btemp[1]);
			foreach $pix (@pixs){
				$ent = $pix;
				$ent =~ s/\(//;
				$ent =~ s/\)//;
				$ent =~ s/\,/\./;
#
#--- find out whether the same pixel was warm in the past
#
				$p_dom = ${data.$ccd.$ent}{dom}[0];
				if($p_dom eq ''){
					$cum_cnt++;
				}else{	
#
#--- if it was, check whether it was in the last 90 days
#
					$diff = $dom - $p_dom;
					if($diff < 90){
						push(@today_flk, $pix);
						$today_cnt++;
					}
				}
#
#--- put the new date to the record
#
				%{data.$ccd.$ent} = (dom => ["$dom"]);
#
#--- if this is a new pix, count in cumulative count
#
			}
		}
#
#--- check whether all columns in the list is still active flickering columns
#
		@current = @today_flk;
		@temp    = ();
		OUTER2:
		foreach $ent (@flikering){
			foreach $comp (@current){
				if($ent eq $comp){
					next OUTER2;
				}
			}
			push(@temp, $ent);
		}

		OUTER3:
		foreach $ent (@temp){
			$ztext = $ent;
			$ztext =~ s/\(//;
			$ztext =~ s/\)//;
			@atemp = split(/,/, $ztext);
			if($atemp[0] =~ /\d/ && $atemp[1] =~ /\d/){
				$ztext =~ s/\,/\./;
				$p_dom = ${data.$ccd.$ztext}{dom}[0];
				$diff  = $dom - $p_dom;
				if($diff < 90){
					push(@current, $ent);
				}
			}
		}

#
#---- remove pixels listed on currently active list (from hist_pccd*) 
#---- so that only dimmed flickering pixels are listed 
#
		@today_flk = ();
		@active    = split(/:/, $hist_pix[$dom]);
		OUTER4:
		foreach $ent (@current){
			foreach $comp (@active){
				if($ent eq $comp){
					next OUTER4;
				}
			}
			push(@today_flk, $ent);
		}

		$today_cnt = 0;
		foreach $ent (@today_flk){
			if($today_cnt == 0){
				print OUT1 "$ent";
				$today_cnt++;
			}else{
				print OUT1 ":$ent";
				$today_cnt++;
			}
		}
		@flikering = @current;

		print OUT1 "\n";
		print OUT2 ":$today_cnt\n";
		print OUT3 ":$cum_cnt\n";
	}
	close(FH);
	close(OUT1);
	close(OUT2);
	close(OUT3);

	open(OUT4, ">$flickering_bad");
	foreach $ent (@today_flk){
		print OUT4 "$ent\n";
	}
	close(OUT4);
}

