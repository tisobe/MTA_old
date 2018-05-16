#!/usr/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	acis_hist_main.perl: get acis histgram data nad plot trends				#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Jul 26, 2012								#
#												#
#################################################################################################

#############################################################################
#
#---- set directories
$dir_list = '/data/mta/Script/ACIS/Acis_hist_linux/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#############################################################################

open(FH, "$bdata_dir/.hakama");
while(<FH>){
	chomp $_;
	$pass = $_;
	$pass =~ s/\s+//g;
}
close(FH);

open(FH, "$bdata_dir/.dare");
while(<FH>){
	chomp $_;
	$dare = $_;
	$dare =~ s/\s+//g;
}
close(FH);

system("mkdir ./Temp_dir");

$chk = `ls ./`;
if($chk =~ /param/){
	system("rm -rf param");
}
system("mkdir ./param");

system("cp -r $web_dir/Results $data_dir/Results~");

#
#--- find out which month of data we want to work with
#--- zlist is created in a pearent script run_for_this_month.perl
#

$year  = $ARGV[0];
$month = $ARGV[1];
chomp $year;
chomp $month;

if($year eq '' || $month eq ''){

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        $year = 1900 + $uyear;
	
	$month = $umon;
	if($month == 0){
		$month = 12;
		$year--;
	}
}

#
#--- convert month to ydate period from 1998 1.1
#

find_ydate_month();
$tyear = $year;
$ydate = $date_start;
$hour  = 0;
$min   = 0; 
$sec   = 0;

convert_time();

$date_start = $t1998;
$ydate      = $date_end + 1;

convert_time();

$date_end   = $t1998;

#
#---- find sim position for the peirod
#

$file = 'comprehensive_data_summary'."$year";

open(FH, "$mj_dir/$year/$file");

@sim_time = ();
@sim_pos  = ();
$sim_cnt  = 0;
while(<FH>){
	chomp $_;
	@atemp  = split(/\s+/, $_);
	@btemp  = split(/:/, $atemp[0]);
	$tyear  = $btemp[0];
	$ydate  = $btemp[1];
	$hour   = $btemp[2];
	$min    = $btemp[3];
	$sec    = $btemp[4];

	convert_time();

	if($t1998 >= $date_start && $t1998 < $date_end){
		push(@sim_time, $t1998);
		push(@sim_pos,  $atemp[1]);
		$sim_cnt++;
	}
}
close(FH);

#
#---- obtain histgram data from archieve
#

$next_mon = $month + 1;

if($next_mon > 13 || $next_mon < 1){
	print "something wrong about the month\n";
	exit 1;
}
$end_year = $year;

if($next_mon == 13) {
	$next_mon = 1;
	$end_year = $end_year + 1;
}

#
#--- create output directory
#

$dir_name = "$data_dir".'/Data'."_$year"."_$month";

$chk = `ls -d $data_dir/Data/*`;
if($chk !~ /$dir_name/){
	system("mkdir $dir_name");
	system("mkdir $dir_name/CCD0 $dir_name/CCD1 $dir_name/CCD2 $dir_name/CCD3");
	system("mkdir $dir_name/CCD4 $dir_name/CCD6 $dir_name/CCD8 $dir_name/CCD9");
	system("mkdir $dir_name/CCD5 $dir_name/CCD7");
}

#
#--- initialize a few parameters
#

for($ccd = 0; $ccd < 10; $ccd++){
	for($node = 0; $node < 4; $node++){
		$cnt_out_file     = 'CCD'."$ccd".'_node'."$node".'_high_cnt';
		${$cnt_out_file}  = 0;
		$plot_out_file    = 'CCD'."$ccd".'_node'."$node".'_high';
		@{$plot_out_file} = ();

		for($i = 0; $i < 4096; $i++){
			${$plot_out_file}[$i] = 0;
		}
		$cnt_out_file     = 'CCD'."$ccd".'_node'."$node".'_low_cnt';
		${$cnt_out_file}  = 0;
		$plot_out_file    = 'CCD'."$ccd".'_node'."$node".'_low';
		@{$plot_out_file} = ();

		for($i = 0; $i < 4096; $i++){
			${$plot_out_file}[$i] = 0;
		}
		$cnt_out_file     = 'CCD'."$ccd".'_node'."$node".'_high_cnt_bkg';
		${$cnt_out_file}  = 0;
		$plot_out_file    = 'CCD'."$ccd".'_node'."$node".'_high_bkg';
		@{$plot_out_file} = ();

		for($i = 0; $i < 4096; $i++){
			${$plot_out_file}[$i] = 0;
		}
		$cnt_out_file     = 'CCD'."$ccd".'_node'."$node".'_low_cnt_bkg';
		${$cnt_out_file}  = 0;
		$plot_out_file    = 'CCD'."$ccd".'_node'."$node".'_low_bkg';
		@{$plot_out_file} = ();

		for($i = 0; $i < 4096; $i++){
			${$plot_out_file}[$i] = 0;
		}
	}
}

@bkrange1 = (  0,  512, 1024, 1536, 2048, 2560, 3072, 3584);
@bkrange2 = (512, 1024, 1536, 2048, 2560, 3072, 3584, 4096);

#
#--- preparing for arc4gl to retrieve data
#

system("rm ./Temp_dir/*fits");

open (OUT, ">./Temp_dir/input_line");
print OUT "operation=retrieve\n";
print OUT "dataset=flight\n";
print OUT "detector=acis\n";
print OUT "level=0\n";
#print OUT "version=last\n";
print OUT "filetype=histogr\n";
print OUT "tstart=$month/01/$year,00:00:00\n";
print OUT "tstop=$next_mon/01/$end_year,00:00:00\n";
print OUT "go\n";
close(OUT);

system('rm -rf  ./Temp_dir/*fits param');

#####################################################
#
#---- here is the arc4gl reading
#
system("cd ./Temp_dir; echo $pass | arc4gl -U$dare -Sarcocc -i./input_line"); 
#####################################################

system("gzip -d ./Temp_dir/*gz");    # unzip data
system("rm ./Temp_dir/input_line");

$t_list    = `ls ./Temp_dir/*fits`;
@file_list = split(/\s+/, $t_list);
@list      = ();
@obs_list  = ();

foreach $file (@file_list){
	@btemp    = split(/\//,$file);
	@atemp    = split(/E/, $btemp[2]);
	$file_nam = $atemp[0];
	push(@{list.$atemp[0]}, $file);
	push(@obs_list,$atemp[0]);
}

OUTER2:
foreach $file (@file_list){

#
#---- read out information of the histgram data
#

	system("dmlist infile=$file outfile=./Temp_dir/zaout opt=head");
	open(FH,"./Temp_dir/zaout");
	$start  = 0;
	$pblock = 0;
	while(<FH>) {
		chomp $_;
		@line = split(/\s+/, $_);
		 if($_ =~ /FEP_ID/){
			$fep      = $line[2];
		 } elsif($_ =~ /CCD_ID/){
			$ccd      = $line[2];
			push(@{ccd_list.$file_nam},$ccd);
		} elsif($_ =~ /NODE_ID/){
			$node     = $line[2];
		} elsif($_ =~ /PBLOCK/){
			$pblock   = $line[2];
		} elsif($_ =~ /TSTART/ && $_ !~ /BEP/) {
			$tstart   = $line[2];
		} elsif($_ =~ /TSTOP/ && $_ !~ /BEP/) {
			$tstop    = $line[2];
		} elsif($_ =~ /EXPCOUNT/) {
			$expcount = $line[2];
		} elsif($_ =~ /DATE-OBS/){
			$date_obs = $line[2];
		} elsif($_ =~ /DATE-END/){
			$date_end = $line[2];
		}
	}	
	close(FH);
	system("rm ./Temp_dir/zaout"); 

	$line = "$file".'[cols counts]';
	system("dmlist infile=\"$line\" outfile=./Temp_dir/zaout opt=data");
	open(FH,"./Temp_dir/zaout");
	@data = ();
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
			push(@data, $atemp[2]);
		}
	}
	close(FH);
	system("rm ./Temp_dir/zaout"); 

	@ntemp = split(/\//, $file);
	@mtemp = split(/\.fits/,$ntemp[2]);
	$name  = $mtemp[0];

#
#---- find sim location
#
	find_sim_position();

#-------------------------------------------------------------------
#--- for the case that the sim is at the external calibraiton source:
#-------------------------------------------------------------------

	$info_file = "$dir_name".'/CCD'."$ccd".'/info_file';
	open(WRT, ">>$info_file");

	if($smin > -100800 && $smin < -98400 && $smax > -100800 && $smax <  -98400){

		$plot_out_data  = "$dir_name".'/CCD'."$ccd".'/'."$name";
		open(TBL, ">$plot_out_data");

#
#--- find a 3 peaks
#
		find_peaks();

#
#--- plot fitting for 3 peaks
#
		$plot_out_dir = "$dir_name".'/CCD'."$ccd".'/'."$name".'.gif';
		$title        = "$name: ". 'CCD'."$ccd".' Node'."$node";
		$plot_fit_line = 1;
		plot_fit();

#
#--- add up the counts for the months
#
		if($pblock == 2334740){
			print WRT "$name: source: high\n";
#
# --- ccd raws are between 801 and 1001
#
			$out_dir = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_high';

			open(OUT, ">> $out_dir");
			print OUT "$tstart\t";
			print OUT "$tstop\t";
			print OUT "$expcount\t";
			print OUT "$fep\t";
			printf OUT "%6d\t%6d\t%6d\t",$sim_avg,$smin,$smax;
			printf OUT "%6d\t%6d\t%6d\t",$pos1,$wid1,$cnt1;
			printf OUT "%6d\t%6d\t%6d\t",$pos2,$wid2,$cnt2;
			printf OUT "%6d\t%6d\t%6d\t",$pos3,$wid3,$cnt3;
			print OUT "$name\n";
			close(OUT);
	
			$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_high';
			$plot_out_cnt = 'CCD'."$ccd".'_node'."$node".'_high_cnt';
			${$plot_out_cnt}++;
			$ecnt = 0;
			@temp = ();
			foreach $ent (@{$plot_out_file}){
				print TBL "$ecnt\t$data[$ecnt]\n";
				$ent += $data[$ecnt]/$expcount/3.2412;
				push(@temp, $ent);
				$ecnt++;
			}
			@{$plot_out_file} = @temp;
		}elsif($pblock == 2342932){
			print WRT "$name: source: low\n";
#
# --- ccd raws are between 21 and 221
#
			$out_dir = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_low';

			open(OUT, ">> $out_dir");
			print OUT "$tstart\t";
			print OUT "$tstop\t";
			print OUT "$expcount\t";
			print OUT "$fep\t";
			printf OUT "%6d\t%6d\t%6d\t",$sim_avg,$smin,$smax;
			printf OUT "%6d\t%6d\t%6d\t",$pos1,$wid1,$cnt1;
			printf OUT "%6d\t%6d\t%6d\t",$pos2,$wid2,$cnt2;
			printf OUT "%6d\t%6d\t%6d\t",$pos3,$wid3,$cnt3;
			print OUT "$name\n";
			close(OUT);
	
			$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_low';
			$plot_out_cnt = 'CCD'."$ccd".'_node'."$node".'_low_cnt';
			${$plot_out_cnt}++;
			$ecnt = 0;
			@temp = ();
			foreach $ent (@{$plot_out_file}){
				print TBL "$ecnt\t$data[$ecnt]\n";
				$ent += $data[$ecnt]/$expcount/3.2412;
				push(@temp, $ent);
				$ecnt++;
			}
			@{$plot_out_file} = @temp;
		}
		close(TBL);

#--------------------------------------------------------
#--- for the case that the sim is at background position:
#--------------------------------------------------------

	}elsif($smin > -51700 && $smin < -49300 && $smax > -51700 && $smax < -49300){

		$plot_out_data  = "$dir_name".'/CCD'."$ccd".'/'."$name";
		open(TBL, ">$plot_out_data");
#
#--- add up the counts for the months
#
		if($pblock == 2334740){
			print WRT "$name: background: high\n";
#
# --- ccd raws are between 801 and 1001
#
			$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_high_bkg';
			$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_high_cnt_bkg';
			${$plot_out_cnt}++;
			$ecnt = 0;
			@temp = ();
			$m = 0;
			$bin1 = $bkrange1[$m];
			$bin2 = $bkrange2[$m];
			$bksum[$m] = 0;
			foreach $ent (@{$plot_out_file}){
				print TBL "$ecnt\t$data[$ecnt]\n";
				$de3 = $data[$ecnt]/$expcount/3.2412;
				$ent += $de3;
				push(@temp, $ent);
				if($ecnt >= $bin1 && $ecnt < $bin2){
					$bksum[$m] += $de3;
				}else{
					$m++;
					$bin1 = $bkrange1[$m];
					$bin2 = $bkrange2[$m];
					$bksum[$m] = $de3;
				}
				$ecnt++;
			}
			@{$plot_out_file} = @temp;
			$out_dir = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_high_bkg';
			open(BKG, ">>$out_dir");
			print BKG "$tstart\t";
			print BKG "$tstop\t";
			print BKG "$expcount\t";
			print BKG "$fep\t";
			for($m = 0; $m < 8; $m++){
				printf BKG "%8.6f\t",$bksum[$m];
			}
			print BKG "$name\n";
			close(BKG);
			

		}elsif($pblock == 2342932){
			print WRT "$name: background:low\n";
#
# --- ccd raws are between 21 and 221
#
			$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_low_bkg';
			$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_low_cnt_bkg';
			${$plot_out_cnt}++;
			$ecnt = 0;
			@temp = ();
			$m = 0;
			$bin1 = $bkrange1[$m];
			$bin2 = $bkrange2[$m];
			$bksum[$m] = 0;

			foreach $ent (@{$plot_out_file}){
				print TBL "$ecnt\t$data[$ecnt]\n";
				$de3 = $data[$ecnt]/$expcount/3.2412;
				$ent += $de3;
				push(@temp, $ent);
				if($ecnt >= $bin1 && $ecnt < $bin2){
					$bksum[$m] += $de3;
				}else{
					$m++;
					$bin1 = $bkrange1[$m];
					$bin2 = $bkrange2[$m];
					$bksum[$m] = $de3;
				}
				$ecnt++;
			}
			@{$plot_out_file} = @temp;
			$out_dir = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_low_bkg';
			open(BKG, ">>$out_dir");
			print BKG "$tstart\t";
			print BKG "$tstop\t";
			print BKG "$expcount\t";
			print BKG "$fep\t";

			for($m = 0; $m < 8; $m++){
				printf BKG "%8.6f\t",$bksum[$m];
			}
			print BKG "$name\n";
			close(BKG);
			
#		}elsif($pblock == 4530196){
		}else{
			print WRT "$name: background:low\n";
#
# --- ccd full range 0 - 4012
#
			$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_full_bkg';
			$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_full_cnt_bkg';
			${$plot_out_cnt}++;
			$ecnt = 0;
			@temp = ();
			$m = 0;
			$bin1 = $bkrange1[$m];
			$bin2 = $bkrange2[$m];
			$bksum[$m] = 0;
			foreach $ent (@{$plot_out_file}){
				print TBL "$ecnt\t$data[$ecnt]\n";
				$de3 = $data[$ecnt]/$expcount/3.2412;
				$ent += $de3;
				push(@temp, $ent);
				if($ecnt >= $bin1 && $ecnt < $bin2){
					$bksum[$m] += $de3;
				}else{
					$m++;
					$bin1 = $bkrange1[$m];
					$bin2 = $bkrange2[$m];
					$bksum[$m] = $de3;
				}
				$ecnt++;
			}
			@{$plot_out_file} = @temp;
			$out_dir = "$web_dir".'/Results/CCD'."$ccd".'/node'."$node".'_full_bkg';
			open(BKG, ">>$out_dir");
			print BKG "$tstart\t";
			print BKG "$tstop\t";
			print BKG "$expcount\t";
			print BKG "$fep\t";
			for($m = 0; $m < 8; $m++){
				printf BKG "%8.6f\t",$bksum[$m];
			}
			print BKG "$name\n";
			close(BKG);
			
		}
		close(TBL);
	}
	close(WRT);
}
			
#
#---- print out combined data for the month
#

for($ccd = 0; $ccd < 10; $ccd++){
	for($node = 0; $node < 4; $node++){
		@xdata = ();
		@ydata = ();
		$cnt_out_file  = 'CCD'."$ccd".'_node'."$node".'_high_cnt';
		$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_high';
		$out_file      = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_high';
		$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_high_cnt';

		if(${$plot_out_cnt} > 0){
			open(OUT,">$out_file");
			print OUT "# no. of file: ${$plot_out_cnt}\n";
			$tcnt = 0;
			foreach $ent (@{$plot_out_file}){
				$norm = $ent/${$plot_out_cnt};
				printf OUT "%5d\t%8.6f\n",$tcnt,$norm;
				push(@xdata, $tcnt);
				push(@ydata, $norm);
				$tcnt++;
			}
			close(OUT);
#
			$plot_out_dir  = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_high.gif';
			$title         = "Combined Data (# of file: ${$plot_out_cnt}): ". 'CCD'."$ccd".' Node'."$node";
			$plot_fit_line = 2;
			@data          = @ydata;
			find_peaks();
			plot_fit();
		}
		
		@xdata = ();
		@ydata = ();
		$cnt_out_file  = 'CCD'."$ccd".'_node'."$node".'_low_cnt';
		$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_low';
		$out_file      = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_low';
		$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_low_cnt';

		if(${$plot_out_cnt} > 0){
			open(OUT,">$out_file");
			print OUT "# no. of file: ${$plot_out_cnt}\n";
			$tcnt = 0;
			foreach $ent (@{$plot_out_file}){
				$norm = $ent/${$plot_out_cnt};
				printf OUT "%5d\t%8.6f\n",$tcnt,$norm;
				push(@xdata, $tcnt);
				push(@ydata, $norm);
				$tcnt++;
			}
			close(OUT);
#
			$plot_out_dir  = "$dir_name".'/'.'/CCD'."$ccd".'/node'."$node".'_low.gif';
			$title         = "Combined Data (# of file: ${$plot_out_cnt}): ". 'CCD'."$ccd".' Node'."$node";
			$plot_fit_line = 2;
			@data          = @ydata;
			find_peaks();
			plot_fit();
		}
		
		@xdata = ();
		@ydata = ();
		$cnt_out_file  = 'CCD'."$ccd".'_node'."$node".'_high_cnt_bkg';
		$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_high_bkg';
		$out_file      = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_high_bkg';
		$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_high_cnt_bkg';

		if(${$plot_out_cnt} > 0){
			open(OUT,">$out_file");
			print OUT "# no. of file: ${$plot_out_cnt}\n";
			$tcnt = 0;
			foreach $ent (@{$plot_out_file}){
				$norm = $ent/${$plot_out_cnt};
				printf OUT "%5d\t%8.6f\n",$tcnt,$norm;
				push(@xdata, $tcnt);
				push(@ydata, $norm);
				$tcnt++;
			}
			close(OUT);
#
			$plot_out_dir  = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_high_bkg.gif';
			$title         = "Combined Data (# of file: ${$plot_out_cnt}): ". 'CCD'."$ccd".' Node'."$node";
			$plot_fit_line = 0;
			plot_fit();
		}
		
		@xdata = ();
		@ydata = ();
		$cnt_out_file  = 'CCD'."$ccd".'_node'."$node".'_low_cnt_bkg';
		$plot_out_file = 'CCD'."$ccd".'_node'."$node".'_low_bkg';
		$out_file      = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_low_bkg';
		$plot_out_cnt  = 'CCD'."$ccd".'_node'."$node".'_low_cnt_bkg';

		if(${$plot_out_cnt} > 0){
			open(OUT,">$out_file");
			print OUT "# no. of file: ${$plot_out_cnt}\n";
			$tcnt = 0;
			foreach $ent (@{$plot_out_file}){
				$norm = $ent/${$plot_out_cnt};
				printf OUT "%5d\t%8.6f\n",$tcnt,$norm;
				push(@xdata, $tcnt);
				push(@ydata, $norm);
				$tcnt++;
			}
			close(OUT);
#
			$plot_out_dir  = "$dir_name".'/CCD'."$ccd".'/node'."$node".'_low_bkg.gif';
			$title         = "Combined Data (# of file: ${$plot_out_cnt}): ". 'CCD'."$ccd".' Node'."$node";
			$plot_fit_line = 0;
			plot_fit();
		}
		
	}
}

system("rm -rf ./Temp_dir");

##########################################################################
### find_sim_postion: for a given time find where the sim is located   ###
##########################################################################

sub find_sim_position{

     #       HRC-I    +127.0 mm    -51700 - -49300 motor steps
     #       HRC-S    +250.1 mm    -100800 - -98400 motor steps
     #       ACIS-S   -190.1 mm   72000-77000 motor steps
     #       ACIS-I   -233.6 mm   92000-95000 motor steps
     #       HRC-S, you would expect the external calibration source.
     #       HRC-I, you would expect only background.  When the sim position is

        $sum   = 0;
        $smin  =  1000000;
        $smax  = -1000000;
        $tcnt  = 0;
        $istep = 0;

        OUTER:
        foreach $stime (@sim_time){

                if($stime > $tstart && $stime < $tstop){
                        $sum += $sim_pos[$istep];
                        if($sim_pos[$istep] < $smin){
                                $smin = $sim_pos[$istep];
                        }
                        if($sim_pos[$istep] > $smax){
                                $smax = $sim_pos[$istep];
                        }
                        $tcnt++;
                }

                if($stime > $tstop){
                        if($tcnt == 0){
                                $sim_avg = 0.5 * ($sim_pos[$istep -1] 
						+ $sim_pos[$istep]);
				if($sim_pos[$istep -1] == $sim_pos[$istep]){
                                	$smin = $sim_avg;
                                	$smax = $sim_avg;
				}elsif($sim_pos[$istep -1] > $sim_pos[$istep]){
					$smin = $sim_pos[$istep];
					$smax = $sim_pos[$istep -1];
				}else{
					$smin = $sim_pos[$istep -1];
					$smax = $sim_pos[$istep];
				}
                        }
                        last OUTER;
                }
                $istep++;
        }

        if($tcnt >0){
                $sim_avg = $sum / $tcnt;
        }
	$sim_avg = sprintf "%8d",$sim_avg;
}

################################################################
### find_peaks: find 3 peaks from data                     #####
################################################################

sub find_peaks{

        $max       = -999;
        $xmax      = 0;
        $cnt       = 0;
        @peak_list = ();
        @xdata     = ();
        @ydata     = ();

        OUTER:
        foreach $ent (@data){
                if($cnt > 2500){
                        last OUTER;
                }
                push(@xdata, $cnt);
                push(@ydata, $ent);
                if($max < $ent){
                        $xmax = $cnt;
                        $max  = $ent;
                }
                $cnt++;
        }
        close(FH);

#        if($max > 10){

                $a[0]  = $xmax;
                $a[1]  = $max;
                $a[2]  = 10;
                $rmin  = int($xmax - 200);
                $rmax  = int($xmax + 200);

                $ok = 0;
                gridls();

                if($ok > 0){
                        $pos1 = -999;
                        $cnt1 = -999;
                        $wid1 = -999;
                }else{
                        $a1 = $a[0];
                        $a2 = $a[1];
                        $a3 = $a[2];
                        find_half_max();
                        $pos1 = $pos;
                        $cnt1 = $lmax;
                        $wid1 = $half_width;
                        $cf1  = $chisq;
                }

                $a[0]  = 0.25 * $xmax;
                $a[1]  = 0.50 * $max;
                $a[2]  = 10;
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
                        find_half_max();
                        $pos2 = $pos;
                        $cnt2 = $lmax;
                        $wid2 = $half_width;
                        $cf2  = $chisq;
                }

                $a[0]  = 0.765 * $xmax;
                $a[1]  = 0.50 * $max;
                $a[2]  = 10;
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
                        find_half_max();
                        $pos3 = $pos;
                        $cnt3 = $lmax;
                        $wid3 = $half_width;
                        $cf3  = $chisq;
                }
                $wind++;
#        }else{
#                $cnt_ind = -1;
#                print "there are too few data, max: $max\n";
#        }
}

####################################################################
###  chi_fit: compute chi sq value                              ####
####################################################################

sub chi_fit{
        $sum  = 0;
        $base = $rmax - $rmin;

	if($base == 0){
		$base = 20;		# 20 is totally abitrally chosen
	}

        for($i = $rmin; $i <= $rmax; $i++){

		if($a[2] == 0){
			$z = 0;
		}else{
                	$z = ($i - $a[0])/$a[2];
		}

                $y_est = $a[1]* exp(-1.0*($z*$z)/2.0);

                $diff = ($ydata[$i] - $y_est)/$base;
                $sum += $diff*$diff;
        }
}


####################################################################
## gridls: grid serach least squares fit for a non linear function #
####################################################################

#### see Data Reduction and Error Analysis for the Physical Sciences

sub gridls {
        OUTER:
        for($j = 0; $j < 3 ; $j++){
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
}


####################################################################
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


########################################################
### find_ydate_month: find ydate period in the month ###
########################################################

sub find_ydate_month {
	$tday = 1;
	$tmonth = $month;
	find_ydate();
	$date_start = $ydate;
	$tmonth = $month + 1;
	if($tmonth == 13){
		$date_end  = 365;
		if($year == 2000 || $year == 2004 
			|| $year == 2008 || $year == 2012){
			$date_end++;
		}
	}else{
		find_ydate();
		$date_end = $ydate - 1;
		if($year == 2000 || $year == 2004 
			|| $year == 2008 || $year == 2012){
			if($month > 2){
				$date_end++;
			}
		}
	}
}

##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

	if($tmonth == 1){
		$ydate = $tday;
	}elsif($tmonth == 2){
		$ydate = $tday + 31;
	}elsif($tmonth == 3){
		$ydate = $tday + 59;
	}elsif($tmonth == 4){
		$ydate = $tday + 90;
	}elsif($tmonth == 5){
		$ydate = $tday + 120;
	}elsif($tmonth == 6){
		$ydate = $tday + 151;
	}elsif($tmonth == 7){
		$ydate = $tday + 181;
	}elsif($tmonth == 8){
		$ydate = $tday + 212;
	}elsif($tmonth == 9){
		$ydate = $tday + 243;
	}elsif($tmonth == 10){
		$ydate = $tday + 273;
	}elsif($tmonth == 11){
		$ydate = $tday + 304;
	}elsif($tmonth == 12 ){
		$ydate = $tday + 333;
	}
	if($tyear == 2000 || $tyear == 2004 || $tyear == 2008 || $tyear == 2012){
		if($tmonth > 2){
			$ydate++;
		}
	}
}

#############################################################
### convert_time: change time format to sec from 1998.1.1 ###
#############################################################

sub convert_time{
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

        $ttday = $totyday + $ydate - 1;
        $t1998 = 86400 * $ttday  + 3600 * $hour + 60 * $min +  $sec;
}
#############################################################
### plot_fit: plotting data and its fitting line         ####
#############################################################

sub plot_fit{
	pgbegin(0, "/cps",1,1);                  # setting ps file env
	pgsubp(1,1);                            # page setup
	pgsch(2);                               # charactor size
	pgslw(4);                               # line width

	if($plot_fit_line > 0){
		$xmin = 0;
		$xmax = 2000;
		$ymin = 0;
		$ymax = 120;
		if($plot_fit_line == 2){
			$xmin = 0;
			$xmax = 2000;
			$ymin = 0;
			$ymax = 0.03;
		}
	
		pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
		for($i = 0; $i < 2000; $i++){
        		pgpt(1,$xdata[$i], $ydata[$i], 1);
		}

		pgsci(2);
		$i = 0;
		fit_fnc();
		pgpt(1,0, $y_est, 1);
		
		for($i = 1; $i < 2000; $i++){
        		fit_fnc();
        		pgdraw($i, $y_est);
		}
		pgsci(1);
	}

	if($plot_fit_line == 0){
		$xmin = 0;
		$xmax = 4000;
		$ymin = 0;
		$ymax = 0.01;
	
		pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
		for($i = 0; $i < 4000; $i++){
        		pgpt(1,$xdata[$i], $ydata[$i], 1);
		}
	}
	if($plot_fit_line == 0 || $plot_fit_line == 2){
		pglabel("Channel","Counts/sec", "$title");
	}else{
		pglabel("Channel","Counts", "$title");
	}
	pgclos();

#
#--- change a ps file to a gif file
#
	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 | $op_dir/ppmtogif > $plot_out_dir");
}

################################################################
### fit_fnc: a fitting funciton model for plotting           ###
################################################################

sub fit_fnc {
		$est1 = 0;
		$est2 = 0;
		$est3 = 0;
		if($wid1 > 0){
                	$z1   = ($i - $pos1)/($wid1/2.354);
			$est1 = $cnt1* exp(-1.0*($z1*$z1)/2.0);
		}
		if($wid2 > 0){
                	$z2   = ($i - $pos2)/($wid2/2.354);
			$est2 = $cnt2* exp(-1.0*($z2*$z2)/2.0);
		}
		if($wid3 > 0){
                	$z3   = ($i - $pos3)/($wid3/2.354);
			$est3 = $cnt3* exp(-1.0*($z3*$z3)/2.0);
		}
                $y_est =  $est1 + $est2 + $est3;
}

