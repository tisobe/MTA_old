#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	acis_gain_find_peak.perl: find acis gain from Al, Mn, Ti k-alpha peaks		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Arp 16, 2013							#
#											#
#########################################################################################

OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

#
#---- set several directory names
#

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Gain/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- password
#

$user   = `cat /data/mta/MTA/data/.dare`;
$hakama = `cat /data/mta/MTA/data/.hakama`;
chomp $user;
chomp $hakama;

$test = `ls -d `;
if($test =~ /param/){
}else{
	system("mkdir param");
}

$fits_list  = $ARGV[0];
chomp $fits_list;

@obsid_list = ();

if($fits_list eq ''){
#
#----- for the case, regular reading
#
	@old_list = ();
	open(FH, "$gain_out/Data/obsid_list");
	while(<FH>){
        	chomp $_;
        	push(@old_list, $_);
	}
	
	system("cat $cti_dir/Results/mn_ccd* > zall");
	open(FH, 'zall');
	@list = ();
	while(<FH>){
        	chomp $_;
        	@atemp = split(/\s+/, $_);
        	push(@list, $atemp[5]);
	}
	close(FH);
	system("rm -rf  zall");
	
	$first = shift(@list);
	@new = ($first);
	OUTER:
	foreach $ent (@list){
        	foreach $comp (@new){
                	if($ent == $comp){
                        	next OUTER;
                	}
        	}
        	push(@new, $ent);
	}
	system("cp $gain_out/Data/obsid_list $gain_out/Data/obsid_list~");
	open(OUT1, ">$gain_out/Data/obsid_list");
	OUTER:
	foreach $ent (@new){
        	print OUT1 "$ent\n";
        	foreach $comp (@old_list){
                	if($ent == $comp){
                        	next OUTER;
                	}
        	}
		push(@obsid_list, $ent);

	}
	close(OUT1);
}else{
	chomp $fits_list;				#---- get an obsid list 
	open(FH, "$fits_list");
	while(<FH>){
		chomp $_;
		push(@obsid_list, $_);
	}
	close(FH);
}

open(IN, "$gain_out/Data/keep_obsid");			#---- add back old obsid which was not
while(<IN>){						#---- in archive at the last run
	chomp $_;
	push(@obsid_list, $_);
}
close(IN);
system("rm -rf  $gain_out/Data/keep_obsid");



OUTER:
foreach $obsid (@obsid_list){			#---- retrive fits file one at time
	open(OUT, ">./input_line");
	print OUT "operation=retrieve\n";
	print OUT "dataset=flight\n";
	print OUT "detector=acis\n";
	print OUT "level=1\n";
	print OUT "filetype=evt1\n";
	print OUT "obsid=$obsid\n";
	print OUT "go\n";
	close(OUT);
	
	`echo $hakama |arc4gl -U$user -Sarcocc -iinput_line`;
	system("rm -rf  input_line");
	$test = `ls `;					#--- check whether fits file is retrieved
	if($test =~ /$obsid/){				#--- if not, keep the obsid in keep_obsid list
		system("gzip -d *gz");			#--- so that the script check again the next time.
		$zlist = `ls acisf*fits`;
		@fits_entry = split(/\s+/, $zlist);	#--- there is a case which one obsid
							#--- retrieve 2 or more files (e1, e2, etc)
	}else{
		open(OUT, ">>$gain_out/Data/keep_obsid");
		print OUT "$obsid\n";
		close(OUT);
		next OUTER;
	}
	$fchk = 0;
	foreach $fits (@fits_entry){
#
#---- find out temperature range
#
		$test = `ls -d * `;
		$test =~ s/\s+//g;
		if($test !~ /Working_dir/){
			system("mkdir Working_dir");
		}
        	find_temp_range();		#---- find focal temp for a given acis evt1 file
        	find_time_range();		#---- create a list of time range for different temperature

		open(IN, './Working_dir/ztemp_range_list');
		OUTER4:
		while(<IN>){
#
#------ use data only if the focal temp <= -119.0 C and integrationn time >= 2000 sec
#
			chomp $_;
			@atemp = split(/\s+/, $_);

			if($atemp[4] =~ /\d/ && $atemp[1] =~ /\d/){ 
                        	open(OUT2, ">>$gain_out/gain_obs_list");
                        	print OUT2 "$tstart\t$obsid\t$atemp[4]\t$atemp[1]\n";
                        	close(OUT2);
			}

			if($atemp[1] > -119.0 || $atemp[4] < 2000){
				next OUTER4;
			}

			$line= "$fits".'[time='."$atemp[2]:$atemp[3]".']';
			$t_start= $atemp[2];
			$t_stop = $atemp[3];
#
#----- extract data part with the condition described above
#
			system("dmcopy \"$line\" t_selected.fits clobber='yes'");
#
#----- read observation data from the fits file header
#

			system("dmlist infile=\"$fits\" outfile='./Working_dir/ztemp_date' opt=head");

			open(FH, './Working_dir/ztemp_date');
			OUTER3:
			while(<FH>){
				chomp $_;
				if($_ =~ /DATE-OBS/){
					@atemp = split(/\s+/, $_);
					$date  = $atemp[2];
					last OUTER3;
				}
			}
			system("rm -rf  ./Working_dir/ztemp_date");
			
#
#---- loop around CCDs
#
			OUTER2:
			for($ccd = 0; $ccd < 10; $ccd++){
#
#---- select out data potion with grade = 0, 2, 3, 4, 6 and firs 20 rows of CCD
#
				$line = 't_selected.fits[ccd_id='."$ccd".',chipy=1:20][grade=0,2,3,4,6]';
				system("dmcopy \"$line\" out.fits clobber='yes'");
#
#----- select out each node 
#
				for($node_id = 0; $node_id < 4; $node_id++){
					$line = 'out.fits[node_id='."$node_id".']';
					system("dmcopy infile=\"$line\" outfile=out1.fits clobber='yes'");

					system("dmextract \"out1.fits[bin pha=1:4000:1]\" outfile=out2.fits clobber=yes");
#
#---- extract pulse height location in ADU (X), counts (Y), and  count error (ERROR)
#
					system("dmlist infile=out2.fits outfile=./Working_dir/pha opt=data");

					@xbin = ();
					@ybin = ();
					@yerr = ();
					$cnt  = 0;
					$sum  = 0;
					open(FH, "./Working_dir/pha");
					OUTER:
					while(<FH>){
						chomp $_;
						@atemp = split(/\s+/, $_);
						if($atemp[1] !~ /\d/){
							next OUTER;
						}
						push(@xbin, $atemp[3]);
						push(@ybin, $atemp[4]);
						push(@yerr, $atemp[5]);
						$cnt++;
						$sum += $atemp[4];
						if($cnt > 1800){
							last OUTER;
						}
					}
					close(FH);
					if($sum == 0){
						next OUTER2;
					}
#					$out_name = "$obsid".'_ccd'."$ccd".'_'."$node_id";
#					$test = `ls Outdir/*`;
#					if($out_name =~ /$test/){
#						$out_name = "$out_name".'_e2';
#					}
#					system("cp ./Working_dir/pha Outdir/$out_name");
#					system("gzip -f  Outdir/$out_name");
#					system("rm -rf  pha");
				
					find_peaks();
			
		
#
#---- peak position for peaks are:
#---- $pos1: Mn K<---> 5898.75;
#---- $pos2: Al K<---> 1486.70;
#---- $pos3: Ti K<---> 4510.84;
#
	
					$ev[0] = 5898.75;
					$ev[1] = 1486.70;
					$ev[2] = 4510.84;
					
					$po[0] = $pos1;
					$po[1] = $pos2;
					$po[2] = $pos3;
					
					@xtemp = @ev;
					@dep   = @po;
					$total = 3;
				
#
#------- fit a straight line (by least sq fit)
#
					least_fit();
				
					$ccd_name = 'ccd'."$ccd".'_'."$node_id";
					open(OUT, ">>$gain_out/Data/$ccd_name");
					print OUT  "$date\t$obsid\t$t_start\t$t_stop\t";
					printf OUT  "%4.4f\t%4.4f\t%4.4f\t%4.4f\t%4.4f\t%4.4f\t%4.4f\n",$pos1,$pos2, $pos3,$slope, $sigm_slope, $int, $sigm_int;
					close(OUT);
				}
			}
		}
		close(IN);
	}
	system("rm -rf *fits Working_dir");
}

################################################################
### find_peaks: find 3 peaks from data                     #####
################################################################

sub find_peaks{

        $max = -999;
        $xmax = 0;
        @peak_list = ();
        @xdata = @xbin;
        @ydata = @ybin;
	$cnt2 = 0;
#
#---- find out where is the Mn K-alpha peak
#
	OUTER:
	foreach $ent (@ydata){
                if($cnt2 > 2500){
                        last OUTER;
                }
                if($max < $ent){
			if($cnt2 > 1200){
                        	$xmax = $cnt2;
                        	$max  = $ent;
			}
                }
                $cnt2++;
        }

#
#---- set initial guess of the peak location, counts, and width.
#---- also set test range
#
        $a[0] = $xmax;
        $a[1] = $max;
        $a[2] = 10;
        $rmin  = int($xmax - 200);
        $rmax  = int($xmax + 200);

        $ok = 0;
        gridls();			#---- fitting routine

        if($ok > 0){
                $pos1 = -999;
                $cnt1 = -999;
                $wid1 = -999;
        }else{
                $a1 = $a[0];
                $a2 = $a[1];
                $a3 = $a[2];
		$pos1 = sprintf "%4.5f",$a1;
		$cnt1 = sprintf "%4.5f",$a2;
		$wid1 = sprintf "%4.5f",$a3;
        }

#
#------ initial guess for Al k-alpha peak
#
        $a[0] = 0.25 * $pos1;
        $a[1] = 0.50 * $cnt1;
        $a[2] = 10;
        $rmin  = int($a[0] - 50);
        $rmax  = int($a[0] + 50);

        $ok = 0;
        gridls();
        if($ok > 0){
                $pos2 = -999;
                $cnt2 = -999;
                $wid2 = -999;
        }else{
                $a1 = $a[0];
                $a2 = $a[1];
                $a3 = $a[2];
		$pos2 = sprintf "%4.5f",$a1;
		$cnt2 = sprintf "%4.5f",$a2;
		$wid2 = sprintf "%4.5f",$a3;
        }

#
#----- initial guess for Ti K-alpha peak
#
        $a[0] = 0.765 * $pos1;
        $a[1] = 0.50 * $cnt1;
        $a[2] = $wid1;
        $rmin  = int($a[0] - 100);
        $rmax  = int($a[0] + 100);

        $ok = 0;
        gridls();
        if($ok > 0){
                $pos3 = -999;
                $cnt3 = -999;
                $wid3 = -999;
        }else{
                $a1 = $a[0];
                $a2 = $a[1];
                $a3 = $a[2];
		$pos3 = sprintf "%4.5f",$a1;
		$cnt3 = sprintf "%4.5f",$a2;
		$wid3 = sprintf "%4.5f",$a3;
        }
        $wind++;
}

####################################################################
###  chi_fit: compute chi sq value                              ####
####################################################################

sub chi_fit{
#
#------ here, we use Lorentzian peak
#
        $sum = 0;
        $base = $rmax - $rmin;
        if($base == 0){
                $base = 20;             # 20 is totally abitrally chosen
        }
        for($i = $rmin; $i <= $rmax; $i++){
		if($a[2] == 0){
			$y_est = 0;
		}else{
			$y_est = 0.1591549431 * $a[1] * $a[2] /(($i - $a[0])*($i - $a[0]) + 0.25 * $a[2] * $a[2]);
		}

                $diff = ($ydata[$i] - $y_est)/$base;
                $sum += $diff*$diff;
        }
}


####################################################################
## gridls: grid serach least squares fit for a non linear function #
####################################################################

#### see Data Reduction and Error Analysis for the Physical Sciences

sub gridls {
	$chk = 1;
	while($chk <= 10){
        OUTER:
#        for($j = 0; $j < 3 ; $j++){
	for($j = 2; $j >= 0 ; $j--){
                $deltaa[$j] = $a[$j]*0.05;

                $fn = 0;
                chi_fit();
                $chi1 = $sum;
                $delta =  $deltaa[$j];

                $a[$j] += $delta;
                chi_fit();
                $chi2 = $sum;

                if($chi1  < $chi2){
                        $delta = -$delta;
                        $a[$j] += $delta;
                        chi_fit();
                        $save = $chi1;
                        $chi1 = $chi2;
                        $chi2 = $save;
                }elsif($chi1 == $chi2){
                        $cmax = 1;
                        while($chi1 == $chi2){
                                $a[$j] += $delta;
                                chi_fit();
                                $chi2 = $sum;
                                $cmax++;
                                if($cmax > 100){
                                        $ok = 100;
                                        print "$cmax: $a[$j] $delta $chi1 $chi2 something wrong!\n";
                                        last OUTER;
                                        exit 1;
                                }
                        }
                }

                $no = 0;
                $test = 0;
                OUTER:
                while($test < 200){

                        $fn++;
                        $test++;
                        $a[$j] += $delta;
                        if($a[$j] <= 0){
                                $a[$j] = 10;
                                $no++;
                                last OUTER;
                        }
                        chi_fit();
                        $chi3 = $sum;
                        if($test > 150){
                                $a[$j] = -999;
                                $no++;
                                last OUTER;
                        }
                        if($chi2 >= $chi3) {
                                $chi1= $chi2;
                                $chi2= $chi3;
                        }else{
                                last OUTER;
                        }
                }

                if($no == 0){
                        $delta = $delta *(1.0/(1.0 + ($chi1-$chi2)/($chi3 - $chi2)) + 0.5);
                        $a[$j] = $a[$j] - $delta;
                        $free =  $rmax - $rmin;
                        $siga[$j] = $deltaa[$j] * sqrt(2.0/($free*($chi3-2.0*$chi2 + $chi1)));
                }
        }
        $chisq = $sum;
	$chk++;
	}
}


###################################################################
### find_half_max: find out a width at a half of a peak         ####
####################################################################

sub find_half_max{
        $lmax = $ydata[$a1];
        $half = 0.5 * $lmax;
        $a3 = abs($a3);
#       $start = int($a1 - 2*$a3);
        $start = int($a1 - 100);
        if($start < 0){
                $start = 0;
        }
#       $end   = int($a1 + 2*$a3);
        $end   = int($a1 + 100);
        if($end > 2500){
                $end = 2500;
        }
        $mid   = int($a1);
        $pos   = $mid;

        $chk = 0;
        $lower_edge = -999;
        OUTER:
        for($k = $mid; $k > $start; $k--){
                $point = $ydata[$k];
                if($point > $half){
                        $chk = $k;
                }elsif($point < $half){
                        $lower_edge = 0.5*($chk + $k);
                        last OUTER;
                }else{
                        $lower_edge = $k;
                        last OUTER;
                }
        }

        $chk = 0;
        $upper_edge = -999;
        OUTER:
        for($k = $mid; $k < $end; $k++){
                $point = $ydata[$k];
                if($point > $half){
                        $chk = $k;
                }elsif($point < $half){
                        $upper_edge = 0.5*($chk + $k);
                        last OUTER;
                }else{
                        $upper_edge = $k;
                        last OUTER;
                }
        }

        if($upper_edge != -999 && $lower_edge != -999){
                $half_width = $upper_edge - $lower_edge;
        }else{
                $half_width = -999;
        }
}

##################################
### least_fit: least fitting  ####
##################################

sub least_fit {
        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;

        for($fit_i = 0; $fit_i < $total;$fit_i++) {
                $lsum++;
                $lsumx += $xtemp[$fit_i];
                $lsumy += $dep[$fit_i];
                $lsumx2+= $xtemp[$fit_i]*$xtemp[$fit_i];
                $lsumy2+= $dep[$fit_i]*$dep[$fit_i];
                $lsumxy+= $xtemp[$fit_i]*$dep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

	$tot1 = $total - 1;
        $variance = ($lsumy2 + $int*$int*$lsum + $slope*$slope*$lsumx2
                        -2.0 *($int*$lsumy + $slope*$lsumxy - $int*$slope*$lsumx))/$tot1;
	$sigm_int   = sqrt($variance*$lsumx2/$delta);
        $sigm_slope = sqrt($variance*$lsum/$delta);
}

#########################################################################
#########################################################################
#########################################################################

sub find_temp_range{

#########################################################################
#									#
#	find_temp_range.perl: find focal temp for a given acis evt1 file#
#									#
#########################################################################

	
	system("rm ./Working_dir/*");
	system("ls $focal_temp > ./Working_dir/ztemp");	# get focal temp
	@temp_list = ();
	open(FH, './Working_dir/ztemp');
	while(<FH>){
		chomp $_;
		@atemp = split(/data_/,$_);
		if($atemp[1] ne ''){
			push(@temp_list, $atemp[1]);
		}
	}
	close(FH);
	system("rm ./Working_dir/ztemp");
	
	open(OUT, '> ./Working_dir/ztemp_input');
	@btemp = split(/acisf/,$fits);
	@ctemp = split(/_/, $btemp[1]);
	$msid = $ctemp[0];
#$$##	system("/home/ascds/DS.release/otsbin/fdump $fits ./Working_dir/zdump - 1 clobber='yes'");
	system("dmlist infile=$fits outfile=./Working_dir/zdump opt=head");
	open(FH, './Working_dir/zdump');
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
	system("rm ./Working_dir/zdump");

#
#### find actual starting time and stop time of the data set
#
#$$##	system("/home/ascds/DS.release/otsbin/fstatistic $fits time - outfile=./Working_dir/zstat clobber='yes'");
	$line = "$fits".'[cols time]';
	system("dmstat infile=\"$line\" centroid=no > ./Working_dir/zstat");

	open(FH, './Working_dir/zstat');
	while(<FH>){
		chomp $_;
		if($_ =~ /min/){
			@atemp = split(/\s+/,$_);
			$begin = $atemp[2];
			$begin =~ s/\s+//g;
		}
		if($_ =~ /max/){
			@atemp = split(/\s+/,$_);
			$end = $atemp[2];
			$end =~ s/\s+//g;
		}
	}
	close(FH);
	system("rm ./Working_dir/zstat");

#
### convert date format of focal temp file so that we can select correct ones
#
	$data_yes = 0;
	@data_list = ();
	OUTER:
	foreach $ent (@temp_list){
		@atemp = split(/_/, $ent);
		$tyear  = $atemp[0];
		$tyday  = $atemp[1];
		@ctemp  = split(//,$atemp[2]);
		$chh    = "$ctemp[0]$ctemp[1]";
		$cmm    = "$ctemp[2]$ctemp[2]";
		$tsecd  = 3600*$chh + 60*$cmm;
		conv_time_1998();
		$cstart = $t1998;
		$tyday  = $atemp[3];
		@ctemp  = split(//,$atemp[4]);
		$chh    = "$ctemp[0]$ctemp[1]";
		$cmm    = "$ctemp[2]$ctemp[2]";
		$tsecd  = 3600*$chh + 60*$cmm;
		conv_time_1998();
		$cend   = $t1998;

		if(($cstart <= $begin && $cend >= $begin)
		   || ($cstart >= $begin && $cend <= $end)
		   || ($cstart <= $end && $cend >= $end)){
			$name = "data_$ent";
			push(@data_list, $name);
			$data_yes = 1;
		}elsif($cend < $st1998){
			next  OUTER;
		}elsif($cstart > $et1998){
			last OUTER;
		}
	}

	if($data_yes > 0){
		foreach $ent (@data_list){
			print OUT "TEMP DATA: $ent\n";
#
#### put all time-focal temp info into one file
#
			system("cat $focal_temp/$ent >> ./Working_dir/ztemp");
		}
	
		$b_ind = 0;
		$e_ind = 0;
		$ick = 0;
		@temp_save = ();
	
		open(FH, './Working_dir/ztemp');
		@temp_range_list = ();
#
### compare time and print out focal temp info if it is in the range
#
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			push(@temp_save, $atemp[3]);
			@btemp = split(/:/,$atemp[2]);
			$tyday = $btemp[0];
			$tsecd = $btemp[1];
			conv_time_1998();
			$comp_time = $t1998 ;
	
			if($comp_time < $begin){
				next OUTER;
			}elsif($comp_time > $end){
				last OUTER;
			}elsif( $comp_time >= $begin){
				print OUT "$comp_time\t$atemp[3]\n";
			}
		}
	}
	close(FH);
	close(OUT);
	system("rm ./Working_dir/ztemp");
}

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
	$yday = $tday + $add;
	if($tyear == 2000 || $tyear == 2004 || $tyear == 2008 || $tyear == 2012){
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

        $ttday = $totyday + $tyday - 1;
	$t1998 = 86400 * $ttday + $tsecd;
}


#################################################################################
#################################################################################
#################################################################################

sub find_time_range{

#################################################################################
#										#
#    find_time_range.perl: create a list of time range for different temperature#
#										#
#################################################################################


	open(FH, "./Working_dir/ztemp_input");
	@data = ();
	$cnt = 0;
	@time = ();
	@temperature = ();
	while(<FH>){
		chomp $_;
		@atemp = split(//, $_);
		if($atemp[0] =~ /\d/){
			@btemp = split(/\s+/, $_);
			push(@time, $btemp[0]);
			push(@temperature, $btemp[1]);
			$cnt++;
		}else{
			if($_ =~ /acisf/){
				@ctemp = split(/acisf/, $_);
				@dtemp = split(/_/, $ctemp[1]);
				$obsid = $dtemp[0];
			}
		}
	}
	close(FH);
	
#
### here we assume that a new range starts if temperature is same for 5 consequtive times
#

	$sample = $temperature[0];
	$l_sample = $sample;
	@cnt_list = ();
	$s_cnt = 0;
	$current_pos = 0;
	for($i = 1; $i < $cnt; $i++){
		if($sample == $temperature[$i]){
			$s_cnt++;
			if($s_cnt > 4){
				if($l_sample != $sample && $current_pos > 0){
					push(@cnt_list, $current_pos);
					$l_sample = $sample;
				}
			}
		}elsif($sample !=  $temperature[$i]){
			if($s_cnt < 5){
				if($temperature[$i] == $l_sample){
					$s_cnt = $s_cnt + $l_cnt;
					$sample = $l_sample;
				}else{
					$s_cnt = 0;
					$sample = $temperature[$i];
				}
			}else{
				$l_cnt = $s_cnt;
				$l_sample= $sample;
				$s_cnt = 0;
				$sample = $temperature[$i];
				$current_pos = $i - 1;
			}
		}
	}
	push(@cnt_list, $cnt -1);
	
#
#### print out the results
#

	$e_cnt = 0;
	foreach(@cnt_list){
		$e_cnt++;
	}

	if($cnt > 0){
		open(OUT, ">>./Working_dir/ztemp_range_list");
		if($e_cnt > 0){
			$diff = $time[$cnt_list[0]] - $time[0];
			print OUT "$obsid\t";
			print OUT "$temperature[$cnt_list[0]]\t";
			printf OUT "%10d\t",$time[0];
			printf OUT "%10d\t",$time[$cnt_list[0]];
			printf OUT "%5d\n",$diff;
			
			for($i = 1; $i <  $e_cnt; $i++){
				$diff = $time[$cnt_list[$i]] - $time[$cnt_list[$i -1]+1];
				print OUT "$obsid\t";
				print OUT "$temperature[$cnt_list[$i]]\t";
				printf OUT "%10d\t",$time[$cnt_list[$i -1]+1];
				printf OUT "%10d\t",$time[$cnt_list[$i]];
				printf OUT "%5d\n",$diff;
			}
			
			$diff = $time[$cnt - 1] - $time[$cnt_list[$e_cnt -1] + 1];
			print OUT "$obsid\t";
			print OUT "$temperature[$cnt_list[$e_cnt -1] + 1]\t"; 
			printf OUT "%10d\t",$time[$cnt_list[$e_cnt - 1] + 1];
			printf OUT "%10d\t",$time[$cnt - 1];
			printf OUT "%5d\n",$diff;
		}else{
			$diff = $time[$cnt - 1] - $time[0];
			print OUT "$obsid\t";
			print OUT "$temperature[0]\t";
			printf OUT "%10d\t",$time[0];
			printf OUT "%10d\t",$time[$cnt - 1];
			printf OUT "%5d\n",$diff;
		}
		close(OUT);
	}
}
