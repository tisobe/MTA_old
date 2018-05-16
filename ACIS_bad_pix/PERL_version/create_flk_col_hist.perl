#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	create_flk_col_hist.perl: create flickering warm column history files, count	#
#				  history file, cumlative warm columnl count history	#
#				  files (all warm columns appeared even only once in	#
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

$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#---------------------------------------------

for($ccd = 0; $ccd < 10; $ccd++){
#
#--- set input/output file names
#
	$hst_col     = "$data_dir".'/Disp_dir/hist_col'."$ccd";		#--- col history file
	$new_col     = "$data_dir".'/Disp_dir/new_col'."$ccd";		#--- use this (new_ccd#) for input
	$flk_col     = "$data_dir".'/Disp_dir/flk_col'."$ccd";		#--- flickering col hist
	$flk_col_cnt = "$data_dir".'/Disp_dir/flk_col'."$ccd".'_cnt';	#--- flickering col count hist
	$cum_col     = "$data_dir".'/Disp_dir/cum_col'."$ccd".'_cnt';	#--- cumulative # of warm col

	$flickering_col = "$data_dir".'/Disp_dir/flickering_col'."$ccd";
#
#--- read currently active warm column list
#

	open(FH,   "$hst_col");
	@hist_col  = ();
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/,  $_);
		$dom   = $atemp[0];
		if($dom < 0){
			next OUTER;
		}
		@btemp = split(/<>:/, $_);
		$hist_col[$dom] = $btemp[1];
	}
	close(FH);

	open(FH,   "$new_col");
	open(OUT1, ">$flk_col");
	open(OUT2, ">$flk_col_cnt");
	open(OUT3, ">$cum_col");

	$cum_cnt   = 0;
	@flikering = ();
	while(<FH>){
		chomp $_;
		@atemp     = split(/<>:/, $_);
		$day       = $atemp[0];
		@ctemp     = split(/<>/, $day);
		$dom       = @ctemp[0];
		@today_flk = ();

		print OUT1 "$day".'<>:';

		print OUT2 "$day".'<>:';

		print OUT3 "$day".'<>:';

		if($atemp[1] ne ''){
			@list  = split(/:/, $atemp[1]);
			foreach $col (@list){
#
#--- find out whether the same column was warm in the past
#
				$p_dom = ${data.$ccd.$col}{dom}[0];
				if($p_dom eq ''){
					$cum_cnt++;
				}else{	
#
#--- if it was, check whether it was in the last 90 days
#
					$diff = $dom - $p_dom;
					if($diff < 90){
						push(@today_flk, $col);
					}
				}
#
#--- put the new date to the record
#
				%{data.$ccd.$col} = (dom => ["$dom"]);
#
#--- if this is a new col, count in cumulative count
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
				if($ent == $comp){
					next OUTER2;
				}
			}
			push(@temp, $ent);
		}
			
		OUTER3:
		foreach $ent (@temp){
			if($ent eq '' || $ent !~ /\d/){
				next OUTER3;
			}
			$p_dom = ${data.$ccd.$ent}{dom}[0];
			$diff = $dom - $p_dom;
			if($diff < 90){
				push(@current, $ent);
			}
		}

#
#---- remove cols listed on currently active list (from hist_col*)
#---- so that only dimmed flickering columns are listed
#
		@today_flk = ();
		@active    = split(/:/, $hist_col[$dom]);
		OUTER4:
		foreach $ent (@current){
			foreach $comp (@active){
				if($ent  == $comp){
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
		print OUT2 "$today_cnt\n";
		print OUT3 "$cum_cnt\n";
	}
	close(FH);
	close(OUT1);
	close(OUT2);
	close(OUT3);

	open(OUT4, ">$flickering_col");
	foreach $ent (@today_flk){
		print OUT4 "$ent\n";
	}
	close(OUT4);
}

