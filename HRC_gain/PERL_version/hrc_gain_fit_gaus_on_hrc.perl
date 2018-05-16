#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	fit_gaus_on_hrc.perl: find AR Lac from HRC and fit Gaussian profile on its PHA	#
#			      distribution.						#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Apr 17, 2013						#
#											#
#########################################################################################

#
#---- check whether this is a test
#
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

#####################################
# AR Lac postion

$ra  = 332.179975;
$dec = 45.7422544;

#####################################

####################################################
#
#--- read directory locations
#

open(FH, "/data/mta/Script/HRC/Gain/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
####################################################

$file   = $ARGV[0];				# a list of AR Lac obsids
$user   = `cat $bdata_dir/.dare`;
$hakama = `cat $bdata_dir/.hakama`;
chomp $file;
chomp $user;
chomp $hakama;

$list   = `cat $file`;
@list   = split(/\s+/, $list);

OUTER:
foreach $obsid (@list){
#
#--- retrieve hrc evt2 file from archive
#
	open(OUT, ">./input_line");             # input script for arc4gl
	print OUT "operation=retrieve\n";
	print OUT "dataset=flight\n";
	print OUT "detector=hrc\n";
	print OUT "level=2\n";
	print OUT "filetype=evt2\n";
	print OUT "obsid=$obsid\n";
	print OUT "go\n";
	close(OUT);

	system("echo $hakama |arc4gl -U$user -Sarcocc -iinput_line"); 
	system("gzip -d hrcf*fits.gz");
	system("ls hrcf*fits > zlist");
	open(FH, "./zlist");
	while(<FH>){
		chomp $_;
		$file = $_;
	}
	close(FH);
	system("rm -rf zlist");
#
#--- find information from the header
#
	system("dmlist infile=$file outfile=zhead opt=head");
	open(FH, "zhead");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($_ =~ /RA_NOM/){
			$ra_pnt   = $atemp[2];
		}elsif($_ =~ /DEC_NOM/i){
			$dec_pnt  = $atemp[2];
		}elsif($_ =~ /ROLL_PNT/i){
			$roll_pnt = $atemp[2];
		}elsif($_ =~ /DETNAM/i){
			$detnam   = $atemp[2];
		}elsif($_ =~ /DATE-OBS/i){
			$date_obs = $atemp[2];
		}elsif($_ =~ /DATE-END/i){
			$date_end = $atemp[2];
		}elsif($_ =~ /TSTART/i){
			$tstart   = $atemp[2];
		}elsif($_ =~ /TSTOP/i){
			$tstop    = $atemp[2];
		}elsif($_ =~ /SIM_X/i){
			$sim_x    = $atemp[2];
		}elsif($_ =~ /SIM_Y/i){
			$sim_y    = $atemp[2];
		}elsif($_ =~ /SIM_Z/i){
			$sim_z    = $atemp[2];
		}elsif($_ =~ /OBS_ID/){
			$obsid    = $atemp[2];
		}elsif($_ =~ /DETNAM/){
			$detnam   = $atemp[2];
		}
	}
	close(FH);
	system("rm -rf zhead");
#
#--- find a difference between pointing direction and a position of AR Lac
#
        $ra_diff  = abs ($ra - $ra_pnt) * 60.0;
        $dec_diff = abs ($dec - $dec_pnt) * 60.0;
        $rad_diff = sqrt($ra_diff * $ra_diff + $dec_diff * $dec_diff);
#
#--- set extracted area size (radius in pixel #)
#
	if($rad_diff < 10){
		$fit_rad = 60;
	}else{
		$fit_rad = 200;
	}
#
#---------------------------------------------------------------------
#--- start looking for AR Lac; assume the brightest source on the HRC
#---------------------------------------------------------------------
#
#
#--- find the size of the image
#
	$line = "$file".'[cols x,y]';
	system("dmstat \"$line\" > zstat");
	
	open(FH, './zstat');
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($_ =~ /min/){
			$minx = $atemp[3];
			$miny = $atemp[4];
		}elsif($_ =~ /max/){
			$maxx = $atemp[3];
			$maxy = $atemp[4];
		}
	}
	close(FH);
	system("rm -rf zstat");
#
#--- since the image is too large to handle as one piece, divide it into 8x8 area
#
	$diffx = $maxx - $minx;
	$diffy = $maxy - $miny;
	$stepx = $diffx/8;
	$stepy = $diffy/8;
	
	open(OUT, "> zresult");
	for($i = 0; $i <= 8; $i++){
		for($j = 0; $j <= 8; $j++){
			$startx = $minx + $stepx * $i;
			$endx   = $startx + $stepx;
		
			$starty = $miny + $stepy * $j;
			$endy   = $starty + $stepy;
#
#--- cut out a small potion of the image, and then find max count pixel potion.
#		
			$line = "$file".'[events][bin x='."$startx".':'."$endx".':1, y='."$starty".':'."$endy".':1]';
			system("dmcopy \"$line\" opt=image outfile=temp.fits clobber=yes");
			system("dmstat temp.fits centroid=no > zstat");
	
			open(FH, './zstat');
			while(<FH>){
				chomp $_;
				@atemp = split(/\s+/, $_);
				if($_ =~ /max/){
					$max_val = $atemp[2];
					$max_x   = $atemp[5];
					$max_y   = $atemp[6];	
					print OUT "$i, $j:   $max_val, $max_x, $max_y\n";
				}
			}
			system("rm -rf zstat");
		}
	}
	close(OUT);
#
#--- find which seciton has the brightest pixel, and we assume that it is AR Lac
#	
	open(FH, "./zresult");
	$max   = 0; 
	$max_x = 0;
	$max_y = 0;
	while(<FH>){
		chomp $_;
		$temp = $_;
		$temp =~ s/\,//g;
		@atemp = split(/\s+/, $temp);
		if($atemp[2] > $max){
			$max   = $atemp[2];
			$max_x = $atemp[3];
			$max_y = $atemp[4];
		}
	}
	close(FH);
#
#--- now extract the small area around AR Lac
#	
	$line = "$file".'[(x,y)=circle('."$max_x,$max_y,$fit_rad".')]';
	
	system("dmcopy \"$line\"  outfile=small_pha.fits clobber=yes");
#
#--- now creates pha list
#	
	$line = 'small_pha.fits[cols pha]';
	system("dmlist \"$line\" opt=data outfile=pha_list");
	
	for($i = 0; $i < 2000; $i++){
        	$count[$i] = 0;
	}
	
	$max_pha = 0;
	$msum    = 0;
	open(FH, 'pha_list');
	while(<FH>){
        	chomp $_;
		$msum += $atemp[1];
        	@atemp = split(/\s+/, $_);
        	if($atemp[1] =~ /\d/){
			if($atemp[2] > 4){
                		$count[$atemp[2]]++;
				if($atemp[2] > $max_pha){
					$max_pha = $atemp[2];
				}
			}
        	}
	}
	close(FH);
	if($msum == 0){
		next OUTER;
	}

	$half = 0.5 * $msum;		# $half is used to find a median

	$max_count = 0;
	$max_pos   = 0;
	$max_pha  *= 2.0;
	$csum      = 0;
	$chk       = 0;
	$median    = 0;

	for($i = 0; $i < $max_pha; $i++){
			
		$csum += $count[$i];
		if($csum >= $half && $chk == 0){	# a median found
			$median = $i -1;
			$chk++;
		}
		if($count[$i] > $max_count){		# a max count point found
			$max_pos   = $i;
			$max_count = $count[$i];
		}
	}
	close(OUT);

	if($median == 0){
		$median = $max_pos;
	}
#
#--- print out data for this observation
#
	$max_pha = 2.0 * $max_pos;
	@xbin = ();
	@ybin = ();
	open(OUT, '>./pha_dist');
	OUTER2:
	for($i = 0; $i < $max_pha; $i++){
        	print OUT "$i\t$count[$i]\n";
		if($count[$i] == 0){
			next OUTER2;
		}
		push(@xbin, $i);
		push(@ybin, $count[$i]);
	}
	close(OUT);
	if($comp_test =~ /test/i){
		$data_name ="$test_data_dir/". 'hrc'."$obsid".'_pha.dat';
	}else{
		$data_name ="$data_dir/". 'hrc'."$obsid".'_pha.dat';
	}
	system("mv pha_dist $data_name");
#
#--- fit a Gaussian profile around the peak. $a[*] are initial estimate of
#--- a peak postion, a peak counts, and a peak width
#	
	$a[0] = $max_pos;
	$a[1] = $max_count;
	$a[2] = 5;
	
	gridls(3, $max_pha);				# fitting sub routine
#
#--- fitting results are kept in "fitting_results" file
#
	if($comp_test =~ /test/i){
		open(RESULT, ">>$test_web_dir/fitting_results");
	}else{
		open(RESULT, ">> $house_keeping/fitting_results");
	}

	print RESULT "$obsid\t$date_obs\t$detnam\t$ra_pnt\t$dec_pnt\t\t";
	printf RESULT "%5.3f\t%5.3f\t%5.3f\t",$ra_diff,$dec_diff,$rad_diff;
	print RESULT "$median\t$a[0]\t$a[1]\t$a[2]\n";
#
#--- plot the fitting result on the data
#	
	$xmin = 0; 
	$xmax = $max_pha;
	@temp = sort{$a<=>$b} @ybin;
	$tcnt = 0;
	foreach (@ybin){
		$tcnt++;
	}
	$ymin = 0;
	$ymax = 1.2 * $temp[$tcnt -1];
	$symbol = 2;
	
	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,1);
	pgsch(1);
	pgslw(4);
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

	for($m = 0; $m < $max_pha; $m++){
		pgpt(1,$xbin[$m], $ybin[$m], $symbol);
	}
	
	$y_val = app_func($xbin[0]);
	pgmove($xbin[0], $y_val);
	for($m = 1; $m < $max_pha; $m++){
		$y_val = app_func($xbin[$m]);
		pgdraw($xbin[$m], $y_val);
		pgmove($xbin[$m], $y_val);
	}
	pglab("pha", "Counts",'');
	pgclos();

	if($comp_test =~ /test/i){
		$out_plot = "$test_web_dir/Plots/".'hrc'."$obsid".'_fits.gif';
	}else{
		$out_plot = "$web_dir/Plots/".'hrc'."$obsid".'_fits.gif';
	}

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_plot");
	system("rm -rf pgplot.ps");
	system("rm -rf input_line pha_list *.fits zresult");

}

####################################################################
## gridls: grid serach least squares fit for a non linear function #
####################################################################

sub gridls {

#######################################################################
#
#	this is grid search least-squares fit for non-linear fuction
#	described in "Data Reduction and Error Analysis for the Physical 
#	Sciences".
#	The function must be given (see the end of this file).
#
#	Input: 	$xbin:	independent variable
#		$ybin:	dependent variable
#		$nterms:	# of coefficients to be fitted
#		$total:		# of data points
#		$a:		initial guess of the coefficients
#				this must not be "0"
#
#		calling format:  gridls($nterms, $total)
#			@xbin, @ybin, @a must be universal
#
#	Output:	$a:		estimated coefficients
#
#######################################################################

	my($nterms, $total,  $no, $test, $fn, $free);
	my($i, $j, $k, $l, $m, $n);
	my($chi1, $chi2, $chi3, $save, $cmax, $delta, @deltaa);

	($nterms, $total) = @_;

	$rmin = 0; 
	$rmax = $total - 1;

        OUTER:
        for($j = 0; $j < $nterms ; $j++){
                $deltaa[$j] = $a[$j]*0.05;

                $fn    = 0;
                $chi1  = chi_fit();
                $delta =  $deltaa[$j];

                $a[$j] += $delta;
                $chi2 = chi_fit();

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
                                $chi2 = chi_fit();
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
                        $chi3 = chi_fit();
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
                        $free =  $rmax - $rmin - $nterms;
                        $siga[$j] = $deltaa[$j] * sqrt(2.0/($free*($chi3-2.0*$chi2 + $chi1)));
                }
        }
        $chisq = $sum;
}


####################################################################
###  chi_fit: compute chi sq value                              ####
####################################################################

sub chi_fit{
        $sum = 0;
        $base = $rmax - $rmin;
        if($base == 0){
                $base = 20;             # 20 is totally abitrally chosen
        }
        for($i = $rmin; $i <= $rmax; $i++){
                $y_est = app_func($xbin[$i]);
                $diff = ($ybin[$i] - $y_est)/$base;
                $sum += $diff*$diff;
        }
	return $sum;
}


####################################################################
### app_func: function form to be fitted                         ###
####################################################################

sub app_func{

#
#----- you need to difine a function here. coefficients are
#----- a[0] ... a[$nterms], and data points are $xbin[$i], $ybin[$i]
#----- this function is called by gridls
#
	my ($y_est, $x_val);
	($x_val) = @_;

        if($a[2] == 0){
                $z = 0;
        }else{
                $z = ($x_val - $a[0])/$a[2];
        }
        $y_est = $a[1]* exp(-1.0*($z*$z)/2.0);

	return $y_est;
}

