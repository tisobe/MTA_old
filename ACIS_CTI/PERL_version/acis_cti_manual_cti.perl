#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	maunal_cti.perl: compute cti for acis evt1 file for a given time range	#
#										#
#	!!!!IMPORTNAT!!!!!							#
#	YOU MUST CHANGE MTA_REPORT_DIR TO THE CURRENT DIRECTORY			#
#										#
#	author: T. Isobe (tisobe@cfa.harvard.edu)				#
#	last update: Apr 15, 2013						#
#			modfied to fit a new directory system (08/10/05)	#
#			modifed to accomodate a new flt_run_pipe		#
#										#
#################################################################################

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

#
### input file format is: 
###		60417   -119.54 189848344       189856139       7795
###		60434   -119.38 189391284       189393216       1932
### where columns are obsid, focal temp, start time, stop time, and duration
#

open(FH, "$exc_dir/Working_dir/temp_file");
@data_list = ();
while(<FH>){
	chomp $_;
	push(@data_list, $_);
}
close(FH);

if($comp_test !~ /test/i){
	system("mv $exc_dir/Working_dir/temp_file $house_keeping/temp_file~");
}

OUTER:
foreach $line (@data_list){

	@atemp = split(/\s+/, $line);
	$obsid          = $atemp[0];
	$temperature    = $atemp[1];
	$t_begin        = $atemp[2];
	$t_end          = $atemp[3];
	$total_int_time = $atemp[4];
	if($total_int_time < 600){
		next OUTER;
	}

	system("rm -rf param");				# since mta pipe is sensitive,
	system("mkdir param");				# just remove param dir to clean up eveytime
	system("source /home/mta/bin/reset_param");

#
#### acis evt1 fits file must be in ./Data directory
#
	$file = `ls $exc_dir/Working_dir/acisf*$obsid*evt1.fits*`;
	chomp $file;
#
#### find necessary information from dump file
#
	@btemp = split(/acisf/,$file);
	@ctemp = split(/_/, $btemp[1]);
	$msid = $ctemp[0];

print "$file\n";
	system("dmlist infile=$file outfile=$exc_dir/Working_dir/zdump opt=head");

	open(FH, "$exc_dir/Working_dir/zdump");
	$tstart = 'INDEF';
	$tstop  = 'INDEF';
	OUTER:
	while(<FH>){
		chomp $_;
		if($_ =~ /DATE-OBS/i){
			@atemp = split(/\s+/,$_);
			@btemp = split(/T/, $atemp[2]);
			@ctemp = split(/-/, $btemp[0]);
			$tstart = $atemp[2];
			$tstart =~ s/\s+//g;
			$syear = $ctemp[0];
			$smon  = $ctemp[1];
			$sday  = $ctemp[2];
			@dtemp = split(/:/, $btemp[1]);
			$shour = $dtemp[0];
			$smin  = $dtemp[1];
			$ssec  = $dtemp[2];
			$tyear = $syear;
			$tmon  = $smon;
			$tday  = $sday;
			conv_to_yday();
			$syday = $yday;
			$sdhr  = "$shour$smin";
			$ssecd = 3600*$shour + 60*$smin + $ssec;
			$tyday = $syday;
			$tsecd = $ssecd;
			conv_time_1998();
			$st1998 = $t1998;
		}elsif($_ =~ /DATE-END/i){
			@atemp = split(/\s+/,$_);
			@btemp = split(/T/, $atemp[2]);
			@ctemp = split(/-/, $btemp[0]);
			$tstop = $atemp[2];
			$tstop =~ s/\s+//g;
			$eyear = $ctemp[0];
			$emon  = $ctemp[1];
			$eday  = $ctemp[2];
			@dtemp = split(/:/, $btemp[1]);
			$ehour = $dtemp[0];
			$emin  = $dtemp[1];
			$esec  = $dtemp[2];
			$tyear = $eyear;
			$tmon  = $emon;
			$tday  = $eday;
			conv_to_yday();
			$eyday = $yday;
			$edhr  = "$ehour$emin";
			$esecd = 3600*$ehour + 60*$emin + $esec;
			$tyday = $eyday;
			$tsecd = $esecd;
			conv_time_1998();
			$et1998 = $t1998;
			last OUTER;
		}
	}
	close(FH);
	system("rm -rf $exc_dir/Working_dir/zdump");

#
### extract necessary data for the given time periods using dmcopy
#
	$chk = `ls $exc_dir`;
	if($chk !~ /Temp_comp_area/){
		system("mkdir $exc_dir/Temp_comp_area");
	}
	$in_line = "$file".'[time='."$t_begin:$t_end]";
	@ptemp = split(/acisf/, $file);
	@qtemp = split(/_evt1/, $ptemp[1]);
	$out_file = 'acisf'."$qtemp[0]".'_clipped_evt1.fits';
	system("dmcopy infile=\"$in_line\" outfile=$exc_dir/Working_dir/$out_file opt=all clobber=yes");
	system("echo $exc_dir/Working_dir/$out_file > $exc_dir/Temp_comp_area/zcomp_dat.lis");

#
### compute cti using mta pipe procedure
#
	system("flt_run_pipe -i $exc_dir/Temp_comp_area  -o $exc_dir/Temp_comp_area  -r zcomp -t mta_monitor_cti.ped -a \"genrpt=yes\"");

	system("rm -rf $exc_dir/Working_dir/$out_file");
#
#### cti info is in ./photons/.... directory
#### the values are read by sub read_ccd();
#
	system("ls $exc_dir/Temp_comp_area/photons/acis/cti/$msid*/ccd*/ccd*.html > $exc_dir/Working_dir/ztest_list");
	open(FH,"$exc_dir/Working_dir/ztest_list");
	while(<FH>){
		chomp $_;
		$dir = $_;
		@gtemp = split(/\//, $dir);
		pop @gtemp;
		$ccd = pop @gtemp;
		read_ccd();
		$ccd_out = "$ccd";
		open(OUT, ">>$data_dir/Results/al_$ccd_out");
		print OUT "$tstart\t${al_ratio.0}\t${al_ratio.1}\t${al_ratio.2}\t${al_ratio.3}\t$msid\t$tstop\t$total_int_time\t$temperature\n";
		close(OUT);
		open(OUT, ">>$data_dir/Results/ti_$ccd_out");
		print OUT "$tstart\t${ti_ratio.0}\t${ti_ratio.1}\t${ti_ratio.2}\t${ti_ratio.3}\t$msid\t$tstop\t$total_int_time\t$temperature\n";
		close(OUT);
		open(OUT, ">>$data_dir/Results/mn_$ccd_out");
		print OUT "$tstart\t${mn_ratio.0}\t${mn_ratio.1}\t${mn_ratio.2}\t${mn_ratio.3}\t$msid\t$tstop\t$total_int_time\t$temperature\n";
		close(OUT);
	}
	close(FH);
	system("rm -rf $exc_dir/Temp_comp_area/z*");
	system("rm -rf $exc_dir/Temp_comp_area/*.fits");
	system("rm -rf mta_cti*");
	system("rm -rf $exc_dir/Temp_comp_area/photons*");
	system("rm -rf $exc_dir/Temp_comp_area/ctirm_dir");
	system("rm -rf $exc_dir/Working_dir/ztest_list");

#### order of date could be out of order due to when the data was processed; sort out them.
	foreach $elm ('al', 'mn', 'ti'){
		for($iccd = 0; $iccd < 10; $iccd++){
			$chk_file = "$data_dir".'/Results/'."$elm".'_ccd'."$iccd";

			open(IN, "$chk_file");
			@lines = ();
			while(<IN>){
				chomp $_;
				push(@lines, $_);
			}
			close(IN);

			$first = shift(@lines);
			@new   = ($first);
			OUTER:
			foreach $ent (@lines){
				foreach $comp (@new){
					if($ent eq $comp){
						next OUTER;
					}
				}
				push(@new, $ent);
			}	

			@new_sorted = sort (@new);

			open(OUT, ">$chk_file");
			foreach $ent (@new_sorted){
				print OUT "$ent\n";
			}
			close(OUT);
		}
	}
}

#system("rm -rf $exc_dir/Working_dir/*fits");
#system("rm -rf -rf $exc_dir/Temp_comp_area");


##############################################################################
### conv_to_yday: change date format to year-date                          ###
##############################################################################

sub conv_to_yday{
	$add = 0;
	if($tmon == 2){
		$add = 31;
	}elsif($tmon == 3){
		$add = 59;
	}elsif($tmon == 4){
		$add = 90;
	}elsif($tmon == 5){
		$add = 120;
	}elsif($tmon == 6){
		$add = 151;
	}elsif($tmon == 7){
		$add = 181;
	}elsif($tmon == 8){
		$add = 212;
	}elsif($tmon == 9){
		$add = 243;
	}elsif($tmon == 10){
		$add = 273;
	}elsif($tmon == 11){
		$add = 304;
	}elsif($tmon == 12){
		$add = 334;
	}
	$chk = 4.0 * int(0.25 * $tyear);
	if($chk == $tyear){
		if($tmon > 2){
			$yday++;
		}
	}
}

####################################################################
### cov_time_1998: change date (yyyy:ddd) to sec from 01/01/1998  ##
####################################################################

sub conv_time_1998 {

        $totyday = 365*($tyear - 1998);
        if($tyear > 2000){
                $totyday++;
        }
        if($tyear > 2004){
                $totyday++;
        }
        if($tyear > 2008){
                $totyday++;
        }
        if($tyear > 2012){
                $totyday++;
        }

        $ttday = $totyday + $tyday;
	$t1998 = 86400 * $ttday + $tsecd;
}


##############################################################
### read_ccd: read input data and fine data needed       #####
##############################################################

sub read_ccd {
        open(IFH, "$dir");
        $docheck = 0;
        $decheck = 0;
        $idcheck = 0;
        $nocheck = 0;
        $si_read = 0;
        $al_node = 0;
        $ti_node = 0;
        $mn_node = 0;
	$elem    = '';
        OUTER:
        while(<IFH>) {
		chomp $_;
		if($_ =~ /Al Ka/){
			$elem = 'al';
		}elsif($_ =~ /Mn Ka/){
			$elem = 'mn';
		}elsif($_ =~ /Ti Ka/){
			$elem = 'ti';
		}

                if($idcheck == 0) {
                        @atemp = split(/\<TD ALIGN=\"CENTER\"\>\<B\>/,$_);
                        @btemp = split(/:/, $atemp[1]);
                        if($btemp[0] eq 'OBS_ID') {
                                @atemp = split(/\<FONT SIZE=-1.7\>/,$_);
                                @ctemp = split(/\</,$atemp[1]);
                                $obsid = $ctemp[0];
                                $idcheck = 1;
                        }
                }
                if($nocheck == 0) {
                        @atemp = split(/\<TD ALIGN=\"CENTER\"\>\<B\>/,$_);
                        @btemp = split(/:/, $atemp[1]);
                        if($btemp[0] eq 'OBI_NUM') {
                                @atemp = split(/\<FONT SIZE=-1.7\>/,$_);
                                @ctemp = split(/\</,$atemp[1]);
                                $obsnum = $ctemp[0];
                                $nocheck = 1;
                        }
                }
                if($docheck == 0) {
                        @atemp = split(/\<TD ALIGN="CENTER"\>\<B\>DATE-OBS\<\/B\>\<BR\>\<FONT SIZE=-1.7\>/,$_);
                        @btemp = split(/\+\-/,$atemp[1]);
                        if($btemp[0] =~ /\d/) {
                                @ctemp = split(/</,$atemp[1]);
                                $date = $ctemp[0];
                                $docheck = 1;
                        }
                }elsif($decheck == 0) {                         # finding date and time
                        @atemp = split(/\<TD ALIGN="CENTER"\>\<B\>DATE-END\<\/B\>\<BR\>\<FONT SIZE=-1.7\>/,$_);
                        @btemp = split(/\+\-/,$atemp[1]);
                        if($btemp[0] =~ /\d/) {
                                @ctemp = split(/\</,$atemp[1]);
                                $end_date = $ctemp[0];
                                $decheck = 1;
                        }
                } elsif($elem eq  'al' && $si_read == 1 && $al_node < 4) {        # find al Ka info
#                       @atemp = split(/\<TD\>\<FONT SIZE=-1.7\>/, $_);
                        @atemp = split(/\<TD\>\<FONT SIZE=-1.7 ALIGN=RIGHT WIDTH=125\>/, $_);
                        @btemp = split(/</,$atemp[1]);
                        @ctemp = split(//,$btemp[0]);
                        if($ctemp[0] eq '*') {                  # marking weired data
                                $btemp[0] = '-99999+-00000';
                        }
                        if($btemp[0] eq ''){
                                $btemp[0] = ' 99999+-00000';
                        }
                        ${al_ratio.$al_node} = $btemp[0];
                        $al_node++;
                        if($al_node == 4) {
                                $si_read = 0;
                        }
                } elsif($elem eq 'ti' && $si_read == 1 && $ti_node < 4) {        # find ti Ka info
#                       @atemp = split(/\<TD\>\<FONT SIZE=-1.7\>/, $_);
                        @atemp = split(/\<TD\>\<FONT SIZE=-1.7 ALIGN=RIGHT WIDTH=125\>/, $_);
                        @btemp = split(/</,$atemp[1]);
                        @ctemp = split(//,$btemp[0]);
                        if($ctemp[0] eq '*') {
                                $btemp[0] = '-99999+-00000';
                        }
                        if($btemp[0] eq ''){
                                $btemp[0] = ' 99999+-00000';
                        }
                        ${ti_ratio.$ti_node} = $btemp[0];
                        $ti_node++;
                        if($ti_node == 4) {
                                $si_read = 0;
                        }
                } elsif($elem eq 'mn' && $si_read == 1 && $mn_node < 4) {        # find mn Ka info
#                       @atemp = split(/\<TD\>\<FONT SIZE=-1.7\>/, $_);
                        @atemp = split(/\<TD\>\<FONT SIZE=-1.7 ALIGN=RIGHT WIDTH=125\>/, $_);
                        @btemp = split(/</,$atemp[1]);
                        @ctemp = split(//,$btemp[0]);
                        if($ctemp[0] eq '*') {
                                $btemp[0] = '-99999+-00000';
                        }
                        if($btemp[0] eq ''){
                                $btemp[0] = ' 99999+-00000';
                        }
                        ${mn_ratio.$mn_node} = $btemp[0];
                        $mn_node++;
                        if($mn_node == 4) {
                                $si_read = 0;
                        }
                } else {
                        @atemp = split(/\t/, $_);
                        if($atemp[2] =~                         # setting up to read needed data
#                       /^\<TD align=RIGHT width=60>\<U\>S\/Ix10\<\/U\>\<SUP\>4\<\/SUP\> \<\/TD\>/i) {
                        /^\<TD align=RIGHT width=80>\<U\>S\/Ix10\<\/U\>\<SUP\>4\<\/SUP\> \<\/TD\>/i) {
                                $si_read = 1;
                        }
                }
        }
	close(IFH);
}

