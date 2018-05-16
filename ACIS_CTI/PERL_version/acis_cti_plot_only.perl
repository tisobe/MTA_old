#!/usr/bin/env /proj/sot/ska/bin/perl
use PGPLOT;

#########################################################################
#									#
# plot_only.perl: plot time vs cti evolution 				#
#									#
#	author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	last update: Aug 10, 2004					#
#			modified to fit a ndw directry system		#
#			removed several un needed parts			#
#		     Jul , 2012						#
#			gs---> /usr/bin/gs				#
#		     May 09, 2013					#
#									#
#########################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[1];
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

$input_dir = $ARGV[0];
chomp $input_dir;

@atemp = split(/Data/, $input_dir);

$plot_dir = "$cti_www".'/Plot'."$atemp[1]";

$input_dir = "$data_dir/"."$input_dir";

ccd_plot(al);					# plotting the data
ccd_plot(ti);
ccd_plot(mn);

group_plot_imaging();
group_plot_spec_wo_bi();
group_plot_spec_bi(5);
group_plot_spec_bi(7);

open (OUT, ">$plot_dir/fitting_result");

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year  = 1900   + $uyear;
$month = $umon  + 1;

$date_line = "$month/$umday/$year";

print OUT "CTI change per Day (Last Update: $date_line)\n\n";
foreach $elm (al, mn, ti){
	if($elm eq 'al'){
		print OUT "Al K alpha\n";
	}
	if($elm eq 'mn'){
		print OUT "Mn K alpha\n";
	}
	if($elm eq 'ti'){
		print OUT "Ti K alpha\n";
	}
	print OUT "----------\n";
	print OUT "CCD\t";
	print OUT "Quad0\t\t\t\tQuad1\t\t\t\tQuad2\t\t\t\tQuad3\n";
	print OUT "\t";
	print OUT "Slope\t\tSigma\t\tSlope\t\tSigma\t\tSlope\t\tSigma\t\tSlope\t\tSigma\n";
	print OUT "\n";
	for($iccd = 0;  $iccd < 10; $iccd++){
		print OUT "$iccd\t";
        	for($iquad = 0; $iquad < 4; $iquad++){
			$slope = ${fit_result.$elm.$iccd.$iquad}{slope}[0] * 1.0e-4;
			$serr  = ${fit_result.$elm.$iccd.$iquad}{slope_err}[0] * 1.0e-4;
#			printf OUT "%4.3e\t", ${fit_result.$elm.$iccd.$iquad}{slope}[0];
#			printf OUT "%4.3e\t", ${fit_result.$elm.$iccd.$iquad}{slope_err}[0];
			printf OUT "%4.3e\t", $slope;
			printf OUT "%4.3e\t", $serr;
		}
		print OUT "\n";
	}
	print OUT  "\n";
	print OUT  'ACIS-I Average: ';
	$slope = ${img_fit_result.$elm}{slope}[0] * 1.0e-4;
	$serr  = ${img_fit_result.$elm}{slope_err}[0] * 1.0e-4;
#	printf OUT "\t%4.3e\t", ${img_fit_result.$elm}{slope}[0];
#	printf OUT "%4.3e\n", ${img_fit_result.$elm}{slope_err}[0];
	printf OUT "\t%4.3e\t", $slope;
	printf OUT "%4.3e\n", $serr;

	print OUT  'ACIS-S Average w/o BI: ';
	$slope = ${spec_fit_result.$elm}{slope}[0] * 1.0e-4;
	$serr  = ${spec_fit_result.$elm}{slope_err}[0] * 1.0e-4;
#	printf OUT "\t%4.3e\t", ${spec_fit_result.$elm}{slope}[0];
#	printf OUT "%4.3e\n", ${spec_fit_result.$elm}{slope_err}[0];
	printf OUT "\t%4.3e\t", $slope;
	printf OUT "%4.3e\n", $serr;

	print OUT  'Back Side CCD 5: ';
	$slope = ${bi_fit_result.$elm.5}{slope}[0] * 1.0e-4;
	$serr  = ${bi_fit_result.$elm.5}{slope_err}[0] * 1.0e-4;
#	printf OUT "\t%4.3e\t", ${bi_fit_result.$elm.5}{slope}[0];
#	printf OUT "%4.3e\n", ${bi_fit_result.$elm.5}{slope_err}[0];
	printf OUT "\t%4.3e\t", $slope;
	printf OUT "%4.3e\n", $serr;

	print OUT  'Back Side CCD 7: ';
	$slope = ${bi_fit_result.$elm.7}{slope}[0] * 1.0e-4;
	$serr  = ${bi_fit_result.$elm.7}{slope_err}[0] * 1.0e-4;
#	printf OUT "\t%4.3e\t", ${bi_fit_result.$elm.7}{slope}[0];
#	printf OUT "%4.3e\n", ${bi_fit_result.$elm.7}{slope_err}[0];
	printf OUT "\t%4.3e\t", $slope;
	printf OUT "%4.3e\n", $serr;

	print OUT "\n";
	print OUT "\n";
}
close(OUT);


#####################################################################################
###  ccd_plot: plotting cti for each node of all ccds with specified inteval ##
#####################################################################################

sub ccd_plot{
	($elm,$start,$end) = @_;		# there are three possible input
	if($start =~ /\d/) {
		$range = "$elm"."_$start"."_range";
	}elsif($end =~ /\d/) {
		$range = "$elm"."_$end"."_range";
	}else{
		$range = "$elm"."_range";
	}
	
	open(FH,"$house_keeping/Range_data/$range");
	$cno = 0;
	OUTER:
	while(<FH>) {
		chomp $_;
		@atemp = split(/ /,$_);
		if($atemp[0] eq 'NONE') {
			$auto = 1;
			last OUTER;
		} else {
			$auto = 0;
			${range.$cno} = $atemp[1];
#			${min.$cno} = $atemp[1];
#			${max.$cno} = $atemp[3];
			$cno++;
		}
	}

	for($i = 0; $i < 10; $i++) {			# al, ti, and mn
		$count = 0;
		@time_list = ();
		if($elm eq 'al') {
			$ofile = "al_ccd$i";
		}elsif($elm eq 'ti'){
			$ofile = "ti_ccd$i";
		}elsif($elm eq 'mn') {
			$ofile = "mn_ccd$i";
		}

		open(FH, "$input_dir/$ofile");
		$sum0  = 0;
		$sum1  = 0;
		$sum2  = 0;
		$sum3  = 0;
		$tsum0  = 0;
		$tsum1  = 0;
		$tsum2  = 0;
		$tsum3  = 0;
		$count = 0;
		while(<FH>) {
			chomp $_;
			@atemp = split(/\t/, $_);
			@btemp = split(/\+\-/,$atemp[1]);
			$sum0 += $btemp[0];
			$tsum0 += $btemp[0]*$btemp[0];
			@ctemp = split(/\+\-/,$atemp[2]);
			$sum1 += $ctemp[0];
			$tsum1 += $ctemp[0]*$ctemp[0];
			@dtemp = split(/\+\-/,$atemp[3]);
			$sum2 += $dtemp[0];
			$tsum2 += $dtemp[0]*$dtemp[0];
			@etemp = split(/\+\-/,$atemp[4]);
			$sum3 += $etemp[0];
			$tsum3 += $etemp[0]*$etemp[0];
			$count++;
		}
		close(FH);

	if($count > 0){
			$avg0 = $sum0/$count;
			$sig0 = sqrt($tsum0/$count - $avg0*$avg0);
			$low0 = $avg0 - 4 * $sig0;
			$hig0 = $avg0 + 4 * $sig0;
			$avg1 = $sum1/$count;
			$sig1 = sqrt($tsum1/$count - $avg1*$avg1);
			$low1 = $avg1 - 4 * $sig1;
			$hig1 = $avg1 + 4 * $sig1;
			$avg2 = $sum2/$count;
			$sig2 = sqrt($tsum2/$count - $avg2*$avg2);
			$low2 = $avg2 - 4 * $sig2;
			$hig2 = $avg2 + 4 * $sig2;
			$avg3 = $sum3/$count;
			$sig3 = sqrt($tsum3/$count - $avg3*$avg3);
			$low3 = $avg3 - 4 * $sig3;
			$hig3 = $avg3 + 4 * $sig3;
	
	
			open(FH, "$input_dir/$ofile");
			@time_list = ();
			$count = 0;
			OUTER:
			while(<FH>) {
				@atemp = split(/\t/, $_);
				$date = $atemp[0];
				@btemp = split(/\+\-/,$atemp[1]);
				if($btemp[0] < $low0 || $btemp[0] > $hig0){
					next OUTER;
				}
				${node0.$date} = $btemp[0];
				${err0.$date}  = $btemp[1];
				@ctemp = split(/\+\-/,$atemp[2]);
				if($ctemp[0] < $low1 || $ctemp[0] > $hig1){
					next OUTER;
				}
				${node1.$date} = $ctemp[0];
				${err1.$date}  = $ctemp[1];
				@dtemp = split(/\+\-/,$atemp[3]);
				if($dtemp[0] < $low2 || $dtemp[0] > $hig2){
					next OUTER;
				}
				${node2.$date} = $dtemp[0];
				${err2.$date}  = $dtemp[1];
				@etemp = split(/\+\-/,$atemp[4]);
				if($etemp[0] < $low3 || $etemp[0] > $hig3){
					next OUTER;
				}
				${node3.$date} = $etemp[0];
				${err3.$date}  = $etemp[1];
				push(@time_list, $date);
				$count++;
			}
			close(FH);
			@new_time_list = @time_list;
			
			@node0 = ();
			@node1 = ();
			@node2 = ();
			@node3 = ();
			@err0  = ();
			@err1  = ();
			@err2  = ();
			@err3  = ();
		
			foreach $time (@new_time_list) {
				push (@node0, ${node0.$time});
				push (@node1, ${node1.$time});
				push (@node2, ${node2.$time});
				push (@node3, ${node3.$time});
				push (@err0,  ${err0.$time});
				push (@err1,  ${err1.$time});
				push (@err2,  ${err2.$time});
				push (@err3,  ${err3.$time});
			}
		
			ch_time_form();				# changing time format

##### pgplot routine starts from here.

			pgbegin(0, "/ps",1,1);			# setting ps file env
			pgsubp(2,2);				# page setup
			pgsch(2);				# charactor size
			pgslw(2);				# line width
			for($j = 0; $j < 4; $j++) {
				@ybin = @{node.$j};
				@yerr = @{err.$j};
				
				x_min_max();
	
				$fit = 0;
				@date = ();
				@dep  = ();
				$total = 0;
				$ysum = 0;
				for($k = 0; $k < $count;$k++) {
					if($xbin[$k] >=$xmin && $xbin[$k] <=$xmax){
#print "$xmin	$xmax	$xbin[$k]	 $ybin[$k]\n";
						if($ybin[$k] =~ /\d/ 
							&& abs($ybin[$k]) < 10.0 ) {
							push(@date,$xbin[$k]);
							push(@dep,$ybin[$k]);
							$ysum += $ybin[$k];
	
							$total++;
						}
					}
				}
				$yavg = $ysum/$total;	# this is used to set a plot range
				least_fit();
				%{fit_result.$elm.$i.$j} = (slope => ["$slope"],
						    	slope_err => ["$sigm_slope"]);
				$fit = 1;
				$ybeg = $int + $slope*$xmin;
				$yend = $int + $slope*$xmax;
	
				if($auto == 1) {
					y_min_max();		# find min and max of y
					if($start =~ /\d/ || $end =~ /\d/) {
						@ybin = @dep;
						y_min_max();	
					}
				}else{
					$ymin = $yavg -0.5*${range.$i};
					$ymax = $yavg +0.5*${range.$i};
				}

				$yt_axis = '(S/I)x10*4';
				$xt_axis = 'Time (Day of Mission)';
				$org_line = $slope;
				digit_adjust();
				$title = "ccd$i: Node$j";
					
				plot_fig();			# plotting routine
			}
			pgend;
			if($start =~ /\d/ || $end =~ /\d/) {
				$out_plot = "$plot_dir/"."$elm". "_ccd"."$i"."_plot_dated.gif";
			}else{
				$out_plot = "$plot_dir/"."$elm". "_ccd"."$i"."_plot.gif";
			} 
			system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");
	
			system("rm pgplot.ps");
		}
	}
}



########################################################
###    plot_fig: plot figure from a give data      #####
########################################################

sub plot_fig {

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

	pgpt(1, $xbin[0], $ybin[0], -1);		# plot a point (x, y)
	for($m = 1; $m < $count-1; $m++) {
		unless($ybin[$m] eq '*****' || $ybin[$m] eq ''){
			pgpt(1,$xbin[$m], $ybin[$m], 3);
		}
		unless($yerr[$m] eq '*****' || $yerr[$m] eq ''){
			$yb = $ybin[$m] - $yerr[$m];
			$yt = $ybin[$m] + $yerr[$m];
			pgpt(1,$xbin[$m], $yb,-2);
			pgdraw($xbin[$m],$yt);
		}
	}
	if($fit == 1){
#print " $xmin,$ybeg	$xmax,$yend \n";
		pgslw(2); 
		pgpt(1, $xmin,$ybeg,-1);
		pgdraw($xmax,$yend);
		pgmtxt(T, 1.0, 0.2, 0,"Slope (CTI/Day): $ad_slope");
		$second_line = 0;
		$fit = 0;
	}

	pglabel("$xt_axis","$yt_axis", "$title");	# write labels
}

########################################################
###  ch_time_form: changing time format           ######
########################################################

sub ch_time_form {
	@xbin = ();
	OUTER:
	foreach $time (@new_time_list) {
		unless($time =~ /\w/) {
			next OUTER;
		}
		@atemp = split(/T/,$time);
		@btemp = split(/-/,$atemp[0]);

		$year = $btemp[0];
		$month = $btemp[1];
		$day  = $btemp[2];
		conv_date();

		@ctemp = split(/:/,$atemp[1]);
		$hr = $ctemp[0]/24.0;
		$min = $ctemp[1]/1440.0;
		$sec = $ctemp[2]/86400.0;
		$hms = $hr+$min+$sec;
		$acc_date = $acc_date + $hms;
		push(@xbin, $acc_date);
	}
}

########################################################
###   x_min_max: find min and max of y values      #####
########################################################

sub x_min_max {
	
	@xtrim = ();
	$subt = 0;
	foreach $xent (@xbin) {

		if($xent =~ /\d/) {
			push(@xtrim, $xent);
		} else {
			$subt++;
		}
	}
	@xtemp = sort { $a<=> $b }  @xtrim;
	$xmin = $xtemp[0];

	if($xmin < 0.0) {
		$xmin = $xmin*1.02;
	} else {
		$xmin = $xmin*0.98;
	}

	$xmax = @xtemp[$count -1 -$subt];
	if($xmax < 0.0) {
		$xmax = $xmax*0.99;
	}else{
		$xmax = $xmax*1.02;
	}
}


########################################################
###   y_min_max: find min and max of y values      #####
########################################################

sub y_min_max {
	@ytrim = ();
	$subt = 0;
	foreach $yent (@ybin) {
		if($yent =~ /\d/) {
			push(@ytrim, $yent);
		} else {
			$subt++;
		}
	}
	@ytemp = sort { $a <=> $b }  @ytrim;
	$ymin = @ytemp[0];
	if($ymin < 0.0) {
		$ymin = $ymin*1.02;
	} else {
		$ymin = $ymin*0.98;
	}

	$ymax = @ytemp[$count -1 - $subt];
	if($ymax < 0.0) {
		$ymax = $ymax*0.99;
	}else{
		$ymax = $ymax*1.02;
	}
}

###########################################################################
###      conv_date: modify data/time format                           #####
###########################################################################

sub conv_date {

        $acc_date = ($year - 1999)*365;
        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }elsif($year > 2020) {
                $acc_date += 6;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                if($year == 2000 || $year == 2004 || $year == 2008 || $year == 2012) {
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
$acc_date = $acc_date - 202;
}

################################################################
##  check_dupl: removing dupulicated line form the database  ###
################################################################

sub check_dupl {

	foreach $elm (al, mn, ti) {
		for($accd = 0; $accd < 10; $accd++) {
			$file = "$elm".'_ccd'."$accd";
			open(FH, "$input_dir/$file");
			@data_set = ();
			while(<FH>) {
				chomp $_;
				push(@data_set,$_);
			}
			close(FH);

			@data_set = sort @data_set;
			
			$first_line = shift(@data_set);
			@new_data = ("$first_line");

			OUTER:
			foreach $line (@data_set) {
				@ltime = split(/\t/,$line);
				foreach $comp (@new_data) {
					@ctime = split(/\t/,$comp);
					if($ltime[0] eq $ctime[0]) {
						next OUTER;
					}
				}
				push(@new_data,$line);
			}

			open(OUT, ">$input_dir/$file");
			foreach $line (@new_data) {
				print OUT "$line\n";
			}
			close(OUT);
		}
	}
}

################################################################
##   group_plot_imaging: making plot for avg of imaging area  ##
################################################################

sub group_plot_imaging {

	($element, $start, $end) = @_;

	@elm_array = (al, mn, ti);
	if($element =~ /\w/) {
		@elm_array = ("$element");
	}

	$auto = 1;
	if($start =~ /\d/) {
        	$range = "img"."_$start"."_range";
	}elsif($end =~ /\d/) {
        	$range = "img"."_$end"."_range";
	}else{
        	$range = "img"."_range";
	}

	open(IN, "$house_keeping/Range_data/$range");
	while(<IN>){
		chomp $_;
		@atemp = split(/\t/,$_);
		if($atemp[0] ne "NO"){
			$auto = 0;
		}
		${range.$atemp[0]} = $atemp[1];
#		${min.$atemp[0]} = $atemp[1];
#		${max.$atemp[0]} = $atemp[2];
	}
	close(IN);

        for($j = 0; $j < 4; $j++){              #initializing for 4 CCDs 
                @{time.$j} =();
        }

        foreach $elem (@elm_array) {

		@all_time =();
                @node_value = ();
                @node_sigma = ();
                @time =();

                foreach $gi ( 0, 1, 2, 3) {             # loop around 4 imaging CCDs
                        $file="$elem"."_ccd$gi";        # and read all data
                        open(FH, "$input_dir/$file");
                        while(<FH>){
                                chomp $_;
                                @atemp = split(/\t/, $_);
                                $time = $atemp[0];
				push(@all_time,$time);
#                                push(@{time.$gi},$time);
                                @btemp = split(/\+\-/,$atemp[1]);
                                @ctemp = split(/\+\-/,$atemp[2]);
                                @dtemp = split(/\+\-/,$atemp[3]);
                                @etemp = split(/\+\-/,$atemp[4]);
                                $name = "data_"."$gi"."_$time";
                                %{data.$gi.$time}= (                    #use a hash table
                                        val_node0 => ["$btemp[0]"],     #to save data for
                                        sig_node0 => ["$btemp[1]"],     #each time bin
                                        val_node1 => ["$ctemp[0]"],
                                        sig_node1 => ["$ctemp[1]"],
                                        val_node2 => ["$dtemp[0]"],
                                        sig_node2 => ["$dtemp[1]"],
                                        val_node3 => ["$etemp[0]"],
                                        sig_node3 => ["$etemp[1]"],
                                );
                        }
                        close(FH);
                }

#                @all_time = @{time.0};                  # since not all CCDs are used
#                push(@all_time,@{time.1});              # all the time, create a new
#                push(@all_time,@{time.2});              # time list which lists all
#                push(@all_time,@{time.3});              # time bins from all 4 CCDs
                @new_time_list = sort @all_time;
                rm_dupl();                              # remove duplication in time
#		@new_time_list = @new_data;


		@new_time_list = ();
                foreach $time (@new_data) {
                        $sum    = 0.0;
                        $sumx   = 0.0;
                        $sigma  = 0.0;
                        $sigmm  = 0.0;
			$i0 = 0;
			$i1 = 1;
			$i2 = 2;
			$i3 = 3;
			$schk0 = 1;
			$schk1 = 1;
			$schk2 = 1;
			$schk3 = 1;
			if(${data.$i0.$time}{val_node.0}[0] eq ''){
				$schk0 = 0;
			}
			if(${data.$i1.$time}{val_node.0}[0] eq ''){
				$schk1 = 0;
			}
			if(${data.$i2.$time}{val_node.0}[0] eq ''){
				$schk2 = 0;
			}
			if(${data.$i3.$time}{val_node.0}[0] eq ''){
				$schk3 = 0;
			}
			$sum_chk = $schk0 + $schk1 + $schk2 + $schk3;

			if($sum_chk == 4){
                        	foreach $gi (0,1,2,3) {         #loop to CCDs
                                	$name = "data_"."$gi"."_$time";

                                                        # here we make weighted means

                                	for($k = 0; $k < 4; $k++) {     #loop to nodes
                                        	if(${data.$gi.$time}{sig_node.$k}[0] >  0.0) {
                                                	${weight.$k}
                                                     	= 1./${data.$gi.$time}{sig_node.$k}[0];
							${weight.$k} = ${weight.$k}*${weight.$k};
                                                	$sum  += ${weight.$k};
                                                	$sumx += ${weight.$k}
                                                        	*${data.$gi.$time}{val_node.$k}[0];
                                        	}
                                	}
                        	}
			}
                        if($sum > 0.0) {
                                $mean = $sumx/$sum;
                                $sigmm = sqrt(1.0/$sum);
                                push(@node_value, $mean);
                                push(@node_sigma, $sigmm);
				push(@new_time_list, $time);
                        }

                }

                ch_time_form();                         # changing time format to DOM

                pgbegin(0, "/ps",1,1);                  # setting ps file env
                pgsubp(1,1);                            # page setup
                pgsch(2);                               # charactor size
                pgslw(2);                               # line width
               
                @ybin = @node_value;
                @yerr = @node_sigma;

                $count = 0;
                foreach (@ybin) {
                        $count++;
                }

                x_min_max();
                if($start =~ /\d/) {
                        $xmin = $start;
                }
                if($end =~ /\d/) {
                        $xmax = $end;
                }

                $fit = 0;
#                if($start =~ /\d/ || $end =~ /\d/) {
                        @date = ();
                        @dep  = ();
                        $total = 0;
			$ysum = 0;
                        for($k = 0; $k < $count;$k++) {
                                if($xbin[$k] >=$xmin && $xbin[$k] <=$xmax){
                                        if($ybin[$k] =~ /\d/) {
                                                push(@date,$xbin[$k]);
                                                push(@dep,$ybin[$k]);
						$ysum += $ybin[$k];
                                                $total++;
                                        }
                                }
                        }
			$yavg = $ysum/$total;   # this is used to set a plot range
                        least_fit();
			%{img_fit_result.$elem} = (slope => ["$slope"],
						    slope_err => ["$sigm_slope"]);
                        $fit = 1;
                        $ybeg = $int + $slope*$xmin;
                        $yend = $int + $slope*$xmax;
#                }


                if($auto == 1) {
                        y_min_max();
                        if($start =~ /\d/ || $end =~ /\d/) {
                                @ybin = @dep;
                                y_min_max();
                        }

                }else{
#                        $ymin = ${min.$elem};
#                        $ymax = ${max.$elem};
                         $ymin = $yavg -0.5*${range.$elem};
                         $ymax = $yavg +0.5*${range.$elem};
                }
                $yt_axis = '(S/I)x10*4';
                $xt_axis = 'Time (Day of Mission)';
                $org_line = $slope;
                digit_adjust();
                $title = "Average of ACIS-I CCDs: Element: $elem";
		$second_line = 1;
                plot_fig();                     # plotting routine
                
                pgend;
		if($start =~ /\d/ || $end =~ /\d/) {
			$out_plot =  "$plot_dir/"."Imaging_"."$elem".'_dated'.'.gif';
		}else{
                	$out_plot =  "$plot_dir/"."Imaging_"."$elem".'.gif';
		} 

			system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");

               system("rm pgplot.ps");
        }
}

################################################################
##   group_plot_spectral: making plot for avg of spec area    ##
################################################################

sub group_plot_spectral {

        ($element, $start, $end) = @_;

        @elm_array = (al, mn, ti);
        if($element =~ /\w/) {
                @elm_array = ("$element");
        }

        $auto = 1;
        if($start =~ /\d/) {
                $range = "spec"."_$start"."_range";
        }elsif($end =~ /\d/) {
                $range = "spec"."_$end"."_range";
        }else{
                $range = "spec"."_range";
        }

        open(IN, "$house_keeping/Range_data/$range");

        while(<IN>){
                chomp $_;
                @atemp = split(/\t/,$_);
                if($atemp[0] ne "NO"){
                        $auto = 0;
                }
		 ${range.$atemp[0]} = $atemp[1];
#                ${min.$atemp[0]} = $atemp[1];
#                ${max.$atemp[0]} = $atemp[2];
        }
	close(IN);

        foreach $elem (@elm_array) {

		@all_time = ();
                @node_value = ();
                @node_sigma = ();
                foreach $gi (4, 5, 6, 7, 8, 9)  {              #initializing for 4 CCDs
                        @{time.$gi} =();
                }
                foreach $gi (4, 5, 6, 7, 8, 9)  {               # loop around 6 Spec.  CCDs
                        $file="$elem"."_ccd$gi";        # and read all data
                        open(FH, "$input_dir/$file");
                        while(<FH>){
                                chomp $_;
                                @atemp = split(/\t/, $_);
                                $time = $atemp[0];
				push(@all_time,$time);
#                                push(@{time.$gi},$time);
                                @btemp = split(/\+\-/,$atemp[1]);
                                @ctemp = split(/\+\-/,$atemp[2]);
                                @dtemp = split(/\+\-/,$atemp[3]);
                                @etemp = split(/\+\-/,$atemp[4]);
                                $name = "data_"."$gi"."_$time";
                                %{data.$gi.$time}= (                    #use a hash table
                                        val_node0 => ["$btemp[0]"],     #to save data for
                                        sig_node0 => ["$btemp[1]"],     #each time bin
                                        val_node1 => ["$ctemp[0]"],
                                        sig_node1 => ["$ctemp[1]"],
                                        val_node2 => ["$dtemp[0]"],
                                        sig_node2 => ["$dtemp[1]"],
                                        val_node3 => ["$etemp[0]"],
                                        sig_node3 => ["$etemp[1]"],
                                );
                        }
                        close(FH);
                }

#                @all_time = @{time.4};                  # since not all CCDs are used
#                push(@all_time,@{time.5});              # all the time, create a new
#                push(@all_time,@{time.6});              # time list which lists all
#                push(@all_time,@{time.7});              # time bins from all 4 CCDs
#                push(@all_time,@{time.8});
#                push(@all_time,@{time.9});
                @new_time_list = sort @all_time;
                rm_dupl();                              # remove duplication in time
#		@new_time_list = @new_data;


		@new_time_list = ();
                foreach $time (@new_data) {
                        $sum   = 0.0;
                        $sumx  = 0.0;
                        $sigma = 0.0;
                        $sigmm = 0.0;
                        
                        foreach $gi (4, 5, 6, 7, 8, 9) {                #loop to CCDs
                                $name = "data_"."$gi"."_$time";

                                                        # here we make weighted means

                                for($k = 0; $k < 4; $k++) {     #loop to nodes
                                        if(${data.$gi.$time}{sig_node.$k}[0] >  0.0) {
                                                ${weight.$k}
                                                     = 1./${data.$gi.$time}{sig_node.$k}[0];
						${weight.$k} = ${weight.$k}*${weight.$k};
                                                $sum  += ${weight.$k};
                                                $sumx += ${weight.$k}
                                                        *${data.$gi.$time}{val_node.$k}[0];
                                        }
                                }
                        }
                        if($sum > 0.0) {
                                $mean = $sumx/$sum;
                                $sigmm = sqrt(1.0/$sum);
                                push(@node_value, $mean);
                                push(@node_sigma, $sigmm);
				push(@new_time_list, $time);
                        }

                }

                ch_time_form();                         # changing time format to DOM

                pgbegin(0, "/ps",1,1);                  # setting ps file env
                pgsubp(1,1);                            # page setup
                pgsch(2);                               # charactor size
                pgslw(2);                               # line width
               
                @ybin = @node_value;
                @yerr = @node_sigma;

                $count = 0;
                foreach (@ybin) {
                        $count++;
                }

                x_min_max();
                if($start =~ /\d/) {
                        $xmin = $start;
                }
                if($end =~ /\d/) {
                        $xmax = $end;
                }

                $fit = 0;
                if($start =~ /\d/ || $end =~ /\d/) {
                        @date = ();
                        @dep  = ();
                        $total = 0;
			$ysum = 0;
                        for($k = 0; $k < $count;$k++) {
                                if($xbin[$k] >=$xmin && $xbin[$k] <=$xmax){
                                        if($ybin[$k] =~ /\d/) {
                                                push(@date,$xbin[$k]);
                                                push(@dep,$ybin[$k]);
						$ysum += $ybin[$k];
                                                $total++;
                                        }
                                }
                        }
			$yavg = $ysum/$total;   # this is used to set a plot range
                        least_fit();
                        $fit = 1;
                        $ybeg = $int + $slope*$xmin;
                        $yend = $int + $slope*$xmax;
                }

                if($auto == 1) {
                        y_min_max();
                        if($start =~ /\d/ || $end =~ /\d/) {
                                @ybin = @dep;
                                y_min_max();
                        }

                }else{
#                        $ymin = ${min.$elem};
#                        $ymax = ${max.$elem};
                        $ymin = $yavg -0.5*${range.$elem};
                        $ymax = $yavg +0.5*${range.$elem};

                }
                $yt_axis = '(S/I)x10*4';
                $xt_axis = 'Time (Day of Mission)';
                $title = "Average of ACIS-S  CCDs: Element: $elem";
                $org_line = $slope;
                digit_adjust();
                $second_line = 1;
                plot_fig();                     # plotting routine
                
                pgend;
                if($start =~ /\d/ || $end =~ /\d/) {
                        $out_plot = "$plot_dir/". "Spec_"."$elem".'_dated'.'.gif';
		}else{
                	$out_plot = "$plot_dir/". "Spec_"."$elem".'.gif';
		}
			system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");

               system("rm pgplot.ps");
        }
}

#############################################################################
##   group_plot_spec_wo_bi: making plot for avg of spec area without BI    ##
#############################################################################

sub group_plot_spec_wo_bi {

        ($element, $start, $end) = @_;

        @elm_array = (al, mn, ti);
        if($element =~ /\w/) {
                @elm_array = ("$element");
        }

        $auto = 1;
        if($start =~ /\d/) {
                $range = "spec2"."_$start"."_range";
        }elsif($end =~ /\d/) {
                $range = "spec2"."_$end"."_range";
        }else{
                $range = "spec2"."_range";
        }

        open(IN, "$house_keeping/Range_data/$range");

        while(<IN>){
                chomp $_;
                @atemp = split(/\t/,$_);
                if($atemp[0] ne "NO"){
                        $auto = 0;
                }
		${range.$atemp[0]} = $atemp[1]; 
#                ${min.$atemp[0]} = $atemp[1];
#                ${max.$atemp[0]} = $atemp[2];
        }
	close(IN);

        foreach $elem (@elm_array) {

		@all_time = ();
                @node_value = ();
                @node_sigma = ();
                foreach $gi (4,  6,  8, 9)  {              #initializing for 4 nodes
                        @{time.$gi} =();
                }

               	foreach $gi (4,  6,  8, 9)  {           # loop around 6 Spec.  CCDs
                       	$file="$elem"."_ccd$gi";        # and read all data
                       	open(FH, "$input_dir/$file");
                       	while(<FH>){
                               	chomp $_;
                               	@atemp = split(/\t/, $_);
                               	$time = $atemp[0];
				push(@all_time, $time);
                      		        push(@{time.$gi},$time);
                               	@btemp = split(/\+\-/,$atemp[1]);
                               	@ctemp = split(/\+\-/,$atemp[2]);
                               	@dtemp = split(/\+\-/,$atemp[3]);
                               	@etemp = split(/\+\-/,$atemp[4]);
                               	$name = "data_"."$gi"."_$time";
                               	%{data.$gi.$time}= (                    #use a hash table
                                       	val_node0 => ["$btemp[0]"],     #to save data for
                                       	sig_node0 => ["$btemp[1]"],     #each time bin
                                       	val_node1 => ["$ctemp[0]"],
                                       	sig_node1 => ["$ctemp[1]"],
                                       	val_node2 => ["$dtemp[0]"],
                                       	sig_node2 => ["$dtemp[1]"],
                                       	val_node3 => ["$etemp[0]"],
                                       	sig_node3 => ["$etemp[1]"],
                               	);
                       	}
                       	close(FH);
               	}

#                @all_time = @{time.4};                  # since not all CCDs are used
#                push(@all_time,@{time.6});              # all the time, create a new
#                push(@all_time,@{time.8});              # time list which lists all
#                push(@all_time,@{time.9});              # time bins from all 4 CCDs
                @new_time_list = sort @all_time;
                rm_dupl();                              # remove duplication in time
#		@new_time_list = @new_data;


		@new_time_list = ();
                foreach $time (@new_data) {
                        $sum   = 0.0;
                        $sumx  = 0.0;
                        $sigma = 0.0;
                        $sigmm = 0.0;
			$i4 = 4;
			$i6 = 6;
			$i8 = 8;
			$i9 = 9;
			$schk4 = 1;
			$schk6 = 1;
			$schk8 = 1;
			$schk9 = 1;
			if(${data.$i4.$time}{val_node.0}[0] eq ''
				|| abs(${data.$i4.$time}{val_node.0}[0]) > 10){
				$schk4 = 0;
			}
			if(${data.$i6.$time}{val_node.0}[0] eq ''
				|| abs(${data.$i6.$time}{val_node.0}[0]) > 10){
				$schk6 = 0;
			}
			if(${data.$i8.$time}{val_node.0}[0] eq ''
				|| abs(${data.$i8.$time}{val_node.0}[0]) > 10){
				$schk8 = 0;
			}
			if(${data.$i9.$time}{val_node.0}[0] eq ''
				|| abs(${data.$i9.$time}{val_node.0}[0]) > 10){
				$schk9 = 0;
			}
			$sum_chk = $schk4 + $schk6 + $schk8 + $schk9;
			if($sum_chk == 4){
                        	foreach $gi (4,  6,  8, 9) {            #loop to CCDs
                                	$name = "data_"."$gi"."_$time";
	
                                                        	# here we make weighted means
	
                                	for($k = 0; $k < 4; $k++) {     #loop to nodes
                                        	if(${data.$gi.$time}{sig_node.$k}[0] >  0.0) {
                                                	${weight.$k}
                                                     	= 1./${data.$gi.$time}{sig_node.$k}[0];
							${weight.$k} = ${weight.$k}*${weight.$k};
                                                	$sum  += ${weight.$k};
                                                	$sumx += ${weight.$k}
                                                        	*${data.$gi.$time}{val_node.$k}[0];
                                        	}
                                	}
                        	}
			}
                              
                        if($sum > 0.0) {
                                $mean = $sumx/$sum;
                                $sigmm = sqrt(1.0/$sum);
                                push(@node_value, $mean);
                                push(@node_sigma, $sigmm);
				push(@new_time_list, $time);
                        }

                }

                ch_time_form();                         # changing time format to DOM

                pgbegin(0, "/ps",1,1);                  # setting ps file env
                pgsubp(1,1);                            # page setup
                pgsch(2);                               # charactor size
                pgslw(2);                               # line width
               
                @ybin = @node_value;
                @yerr = @node_sigma;

                $count = 0;
                foreach (@ybin) {
                                $count++;
                }

                x_min_max();
                if($start =~ /\d/) {
                        $xmin = $start;
                }
                if($end =~ /\d/) {
                        $xmax = $end;
                }

                $fit = 0;
#                if($start =~ /\d/ || $end =~ /\d/) {
                        @date = ();
                        @dep  = ();
                        $total = 0;
			$ysum = 0;
                        for($k = 0; $k < $count;$k++) {
                                if($xbin[$k] >=$xmin && $xbin[$k] <=$xmax){
                                        if($ybin[$k] =~ /\d/) {
                                                push(@date,$xbin[$k]);
                                                push(@dep,$ybin[$k]);
						$ysum += $ybin[$k];
                                                $total++;
                                        }
                                }
                        }
			$yavg = $ysum/$total;   # this is used to set a plot range
                        least_fit();
			%{spec_fit_result.$elem} = (slope => ["$slope"],
						    slope_err => ["$sigm_slope"]); 
                        $fit = 1;
                        $ybeg = $int + $slope*$xmin;
                        $yend = $int + $slope*$xmax;
#                }

                if($auto == 1) {
                        y_min_max();
                        if($start =~ /\d/ || $end =~ /\d/) {
                                @ybin = @{tnode.$j};
                                y_min_max();
                        }
                }else{
#                        $ymin = ${min.$elem};
#                        $ymax = ${max.$elem};
                         $ymin = $yavg -0.5*${range.$elem};
                         $ymax = $yavg +0.5*${range.$elem};
                }
                $yt_axis = '(S/I)x10*4';
                $xt_axis = 'Time (Day of Mission)';
                $title = "Average of ACIS-S CCDs w/o BI: Element: $elem";
                $org_line = $slope;
                digit_adjust();
                $second_line = 1;
                plot_fig();                     # plotting routine
                
                pgend;
		if($start =~ /\d/ || $end =~ /\d/) {
                        $out_plot = "$plot_dir/"."ACIS-S_w_o_BI_"."$elem".'_dated'.'.gif';
		}else{
                	$out_plot = "$plot_dir/"."ACIS-S_w_o_BI_"."$elem".'.gif';
		}

			system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");

               system("rm pgplot.ps");
        }
}

#############################################################################
##   group_plot_bi: making plot for avg of BI Chips  ##
#############################################################################

sub group_plot_spec_bi {

        ($ccd, $element, $start, $end) = @_;

        @elm_array = (al, mn, ti);
        if($element =~ /\w/) {
                @elm_array = ("$element");
        }

        $auto = 1;
        if($start =~ /\d/) {
                $range = "bi"."_$start"."_range";
        }elsif($end =~ /\d/) {
                $range = "bi"."_$end"."_range";
        }else{
                $range = "bi"."_range";
        }

        open(IN, "$house_keeping/Range_data/$range");
        while(<IN>){
                chomp $_;
                @atemp = split(/\t/,$_);
                if($atemp[0] ne "NO"){
                        $auto = 0;
                }
		${range.$atemp[0]}= $atemp[1];
#                ${min.$atemp[0]} = $atemp[1];
#                ${max.$atemp[0]} = $atemp[2];
        }
	close(IN);

        foreach $elem (@elm_array) {

		@all_time = ();
                @node_value = ();
                @node_sigma = ();
                foreach $gi ("$ccd")  {              		#initializing for 2 CCDs
                        @{time.$gi} =();
                }

                foreach $gi ("$ccd")  {           		# go to the given ccd
                        $file="$elem"."_ccd$gi";        	# and read all data
                        open(FH, "$input_dir/$file");
                        while(<FH>){
                                chomp $_;
                                @atemp = split(/\t/, $_);
                                $time = $atemp[0];
#                                push(@{time.$gi},$time);
				push(@all_time, $time);
                                @btemp = split(/\+\-/,$atemp[1]);
                                @ctemp = split(/\+\-/,$atemp[2]);
                                @dtemp = split(/\+\-/,$atemp[3]);
                                @etemp = split(/\+\-/,$atemp[4]);
                                $name = "data_"."$gi"."_$time";
                                %{data.$gi.$time}= (                    #use a hash table
                                        val_node0 => ["$btemp[0]"],     #to save data for
                                        sig_node0 => ["$btemp[1]"],     #each time bin
                                        val_node1 => ["$ctemp[0]"],
                                        sig_node1 => ["$ctemp[1]"],
                                        val_node2 => ["$dtemp[0]"],
                                        sig_node2 => ["$dtemp[1]"],
                                        val_node3 => ["$etemp[0]"],
                                        sig_node3 => ["$etemp[1]"],
                                );
                        }
                        close(FH);
                }

                @new_time_list = sort @all_time;
                rm_dupl();                              # remove duplication in time
#		@new_time_list = @new_data;

		@new_time_list = ();
                foreach $time (@new_data) {
                        $sum   = 0.0;
                        $sumx  = 0.0;
                        $sigma = 0.0;
                        $sigmm = 0.0;
                  
                        foreach $gi ("$ccd") {            #loop to CCDs
                                $name = "data_"."$gi"."_$time";

                                                        # here we make weighted means

                                for($k = 0; $k < 4; $k++) {     #loop to nodes
                                        if(${data.$gi.$time}{sig_node.$k}[0] >  0.0) {
                                                ${weight.$k}
                                                     = 1./${data.$gi.$time}{sig_node.$k}[0];
						${weight.$k} = ${weight.$k}*${weight.$k};
                                                $sum  += ${weight.$k};
                                                $sumx += ${weight.$k}
                                                        *${data.$gi.$time}{val_node.$k}[0];
                                        }
                                }
                        }
                        if($sum > 0.0) {
                                $mean = $sumx/$sum;
                                $sigmm = sqrt(1.0/$sum);
                                push(@node_value, $mean);
                                push(@node_sigma, $sigmm);
				push(@new_time_list, $time);
                        }

                }

                ch_time_form();                         # changing time format to DOM

                pgbegin(0, "/ps",1,1);                  # setting ps file env
                pgsubp(1,1);                            # page setup
                pgsch(2);                               # charactor size
                pgslw(2);                               # line width
               
                @ybin = @node_value;
                @yerr = @node_sigma;

                $count = 0;
                foreach (@ybin) {
                        $count++;
                }

                x_min_max();
                if($start =~ /\d/) {
                        $xmin = $start;
                }
                if($end =~ /\d/) {
                        $xmax = $end;
                }

                $fit = 0;
#                if($start =~ /\d/ || $end =~ /\d/) {
                        @date = ();
                        @dep  = ();
                        $total = 0;
			$ysum = 0;
                        for($k = 0; $k < $count;$k++) {
                                if($xbin[$k] >=$xmin && $xbin[$k] <=$xmax){
                                        if($ybin[$k] =~ /\d/) {
                                                push(@date,$xbin[$k]);
                                                push(@dep,$ybin[$k]);
						$ysum += $ybin[$k];
                                                $total++;
                                        }
                                }
                        }
			$yavg = $ysum/$total;   # this is used to set a plot range
                        least_fit();
			%{bi_fit_result.$elem.$ccd} = (slope => ["$slope"],
					slope_err => ["$sigm_slope"]);
                        $fit = 1;
                        $ybeg = $int + $slope*$xmin;
                        $yend = $int + $slope*$xmax;
#                }

                if($auto == 1) {
                        y_min_max();
                        if($start =~ /\d/ || $end =~ /\d/) {
                                @ybin = @dep;
                                y_min_max();
                        }
                }else{
#                        $ymin = ${min.$elem};
#                        $ymax = ${max.$elem};
                         $ymin = $yavg -0.5*${range.$elem};
                         $ymax = $yavg +0.5*${range.$elem};
                }
                $yt_axis = '(S/I)x10*4';
                $xt_axis = 'Time (Day of Mission)';
                $title = "Average of Back Side CCDs: Element: $elem";
                $org_line = $slope;
                digit_adjust();
                $second_line = 1;
                plot_fig();                     # plotting routine
                
                pgend;
		if($start =~ /\d/ || $end =~ /\d/) {
                        $out_plot = "$plot_dir/"."BackSide_"."$elem".'_dated'.'.gif';
                }else{
                	$out_plot = "$plot_dir/"."BackSide_"."$ccd".'_'."$elem".'.gif';
		}

			system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_plot");

               system("rm pgplot.ps");
        }
}

######################################################
######################################################
######################################################

sub rm_dupl {
#	$first_line ='';
       	$first_line = shift(@new_time_list);
        @new_data = ("$first_line");

        OUTER:
        foreach $line (@new_time_list) {
                foreach $comp (@new_data) {
                        if($line eq $comp) {
                                next OUTER;
                        }
                }
                push(@new_data, $line);
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
#        for($fit_i = 1; $fit_i < $total-1;$fit_i++) {
                $lsum++;
                $lsumx += $date[$fit_i];
                $lsumy += $dep[$fit_i];
                $lsumx2+= $date[$fit_i]*$date[$fit_i];
                $lsumy2+= $dep[$fit_i]*$dep[$fit_i];
                $lsumxy+= $date[$fit_i]*$dep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

#print "Intercept: $int, Slope: $slope Count: $total\n";

	$sum = 0;
	@diff_list = ();
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		$diff = $dep[$fit_i] - ($int + $slope*$date[$fit_i]);
		push(@diff_list,$diff);
		$sum += $diff;
	}
	$avg = $sum/$total;

	$diff2 = 0;
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		$diff = $diff_list[$fit_i] - avg;
		$diff2 += $diff*$diff;
	}
	$sig = sqrt($diff2/($total - 1));

	$sig3 = 3.0*$sig;

	@ldate = ();
	@ldep  = ();
	$cnt = 0;
	for($fit_i = 0; $fit_i < $total;$fit_i++) {
		if(abs($diff_list[$fit_i]) < $sig3) {
			push(@ldate,$date[$fit_i]);
			push(@ldep,$dep[$fit_i]);
			$cnt++;
		}
	}

        $lsum = 0;
        $lsumx = 0;
        $lsumy = 0;
        $lsumxy = 0;
        $lsumx2 = 0;
        $lsumy2 = 0;
	for($fit_i = 0; $fit_i < $cnt; $fit_i++) {
                $lsum++;
                $lsumx += $ldate[$fit_i];
                $lsumy += $ldep[$fit_i];
                $lsumx2+= $ldate[$fit_i]*$ldate[$fit_i];
                $lsumy2+= $ldep[$fit_i]*$ldep[$fit_i];
                $lsumxy+= $ldate[$fit_i]*$ldep[$fit_i];
        }

        $delta = $lsum*$lsumx2 - $lsumx*$lsumx;
        $int   = ($lsumx2*$lsumy - $lsumx*$lsumxy)/$delta;
        $slope = ($lsumxy*$lsum - $lsumx*$lsumy)/$delta;

	$tot1 = $total - 1;
	$variance = ($lsumy2 + $int*$int*$lsum + $slope*$slope*$lsumx2 
			-2.0 *($int*$lsumy + $slope*$lsumxy - $int*$slope*$lsumx))/$tot1;
	$sigm_slope = sqrt($variance*$lsum/$delta);

#print "Intercept: $int, Slope: $slope Count: $cnt\n";

}

####################################################################
### digit_adjust: adjust digit position     ########################
####################################################################

sub digit_adjust {
        @atemp = split(//,$org_line);
	unless($atemp[0] eq ''){
        	$e_yes = 0;
        	foreach $ent (@atemp) {
                	if($ent eq 'e' || $ent eq 'E') {
                        	$e_yes = 1;
                	}
        	}
       	 
        	if($e_yes == 0) {
                	$exp = 0;
                	$ad_slope = $org_line;
			unless($ad_slope == 0) {
                		if(abs($ad_slope) < 1.0){
					OUTER:
                        		while(abs($ad_slope) < 1.0) {
                                		$exp++; 
                                		$ad_slope = 10.0 * $ad_slope;
						if($exp > 10){
							print "something wrong at digit adjust\n";
				         		exit 1;
						}
                        		}
                		}
                		@bt = split(//,$ad_slope);
                		$ad_slope = "$bt[0]"."$bt[1]"."$bt[2]"."$bt[3]"."$bt[4]";
				if($bt[0] eq '-'){
					$ad_slope = "$ad_slope"."$bt[5]";
				}
				$exp += 4;
                		$ad_slope = "$ad_slope".'e'.'-'."$exp";

			}
        	}else{
                	@at = split(//,$org_line);
                	$e_chk = 0;
                	@save = ();
                	@exp =();
                	foreach $ent (@at) {
                        	if($ent eq 'e' || $ent eq 'E') {
                                	$e_chk = 1;
                        	}elsif($e_chk == 0){
                                	push(@save,$ent);
                                	$s_cnt++
                        	}elsif($e_chk == 1){
                                	push(@exp,$ent);
                        	}
                	}
	
                	$ad_slope = "$save[0]"."$save[1]"."$save[2]";
                	$ad_slope = "$ad_slope"."$save[3]"."$save[4]";
                	if($save[0] eq '-') {
                        	$ad_slope = "$ad_slope"."$save[5]";
                	}
                	$ad_slope = "$ad_slope"."e";
                	foreach $add (@exp) {
                        	unless($add eq '0'){
				if($add =~ /\d/){
					$add += 4;
				}
                                	$ad_slope = "$ad_slope"."$add";
				}
			}

        	}
	}


#print "Addjusted slope: $slope	$org_line	$ad_slope\n";
}

