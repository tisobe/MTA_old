#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#                                                                       #
#  det_adjust_cti.perl: screen out the original data 			#
#			(in directory Det_Results)			#
#                   and create a few data set                           #
#									#
#	THIS IS DETREND VERSION OF ADJUST_CTI.PERL			#
#	SEE DETAIL EXPLANATION IN ADJUST_CTI.PERL			#
#									#
#                                                                       #
#       auther: T. Isobe (tisobe@cfa.harvard.edu)                       #
#       Jul 24, 2012                                       		#
#		modified to fit a new directry system			#
#       Last Update: May 16, 2013                                       #
#									#
#########################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;

#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#########################################

foreach $element ('al', 'mn', 'ti'){
	foreach $iccd (0, 1, 2, 3, 4, 6, 8, 9){ 

		$factor = 0.036;
		if($iccd == 5 || $iccd == 7){
			$factor = 0.045;
		}

		$read_dir  = "$data_dir".'Det_Results/'."$element".'_ccd'."$iccd";
		$out_dir   = "$data_dir".'Det_Data119/'."$element".'_ccd'."$iccd";
		$out_dir2  = "$data_dir".'Det_Data_cat_adjust/'."$element".'_ccd'."$iccd";
		$out_dir3  = "$data_dir".'Det_Data2000/'."$element".'_ccd'."$iccd";
		$out_dir4  = "$data_dir".'Det_Data7000/'."$element".'_ccd'."$iccd";

		system("rm -rf $out_dir $out_dir2 $out_dir3 $out_dir4");
		open(FH, "$read_dir");
		OUTER:
		while(<FH>){
			chomp $_;
			$ent_line = $_;
			@atemp = split(/\s+/, $_);
			$temperature = $atemp[8];
			if($atemp[7] < 1000){
				next OUTER;
			}
			@btemp = split(/-/, $atemp[0]);
			if($btemp[0] >= 2003 && $atemp[7] < 2000){
				next OUTER;
			}
#
#--- we need to adjust focal plane temperature between 9/16/2005 - 10/16/2005
#--- a reported temperature is about 1.3 warmer than a real focal temperature
#--- (from 12/105 email from C. Grant)
#
                        @ctemp = split(/T/, $btemp[2]);
                        if($btemp[0] == 2005){
                                if($btemp[1] == 9 || $btemp[1] == 10){
                                        if($btemp[1] == 9 && $ctemp[0] >= 16){
                                                $atemp[8] -= 1.3;
                                        }elsif($btemp[1] == 10 && $ctemp[0] <= 16){
                                                $atemp[8] -= 1.3;
                                        }
                                }
                        }

			open(OUT, ">>$out_dir3");
			print OUT "$ent_line\n";
			close(OUT);

			$diff = $factor * ($temperature + 119.87);
			@ctemp = split(/\./, $diff);
			@dtemp = split(//,$ctemp[1]);
			$diff = "$ctemp[0]".'.'."$dtemp[0]$dtemp[1]$dtemp[2]";
			if($temperature <= -119.7){
				open(OUT, ">>$out_dir");
				print OUT "$ent_line\n";
				close(OUT);
				if($atemp[7] > 7000){
					open(OUT, ">>$out_dir4");
					print OUT "$ent_line\n";
					close(OUT);
				}
			}

			@btemp = split(/\+\-/, $atemp[1]);
			$qtemp = $btemp[0] - $diff;
			if($qtemp > 10){
				next OUTER;
			}
			$quad0 = "$qtemp".'+-'."$btemp[1]";

			@btemp = split(/\+\-/, $atemp[2]);
			$qtemp = $btemp[0] - $diff;
			if($qtemp > 10){
				next OUTER;
			}
			$quad1 = "$qtemp".'+-'."$btemp[1]";

			@btemp = split(/\+\-/, $atemp[3]);
			$qtemp = $btemp[0] - $diff;
			if($qtemp > 10){
				next OUTER;
			}
			$quad2 = "$qtemp".'+-'."$btemp[1]";

			@btemp = split(/\+\-/, $atemp[4]);
			$qtemp = $btemp[0] - $diff;
			if($qtemp > 10){
				next OUTER;
			}
			$quad3 = "$qtemp".'+-'."$btemp[1]";

			open(OUT, ">>$out_dir2");
			print OUT "$atemp[0]\t$quad0\t$quad1\t$quad2\t$quad3\t";
			print OUT "$atemp[5]\t$atemp[6]\t$atemp[7]\t$atemp[8]\n";
			close(OUT);
		}	
	}
}
