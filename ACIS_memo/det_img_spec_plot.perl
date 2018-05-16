#!/usr/bin/perl
use PGPLOT;

#########################################################################
#									#
# plot detrened cti for ACIS I and ACIS S (without backside ccds)	#
#									#
#	author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	last update: Sep 22, 2010					#
#########################################################################


#########################################
#--- set directories
#
$cti_www       = '/data/mta/www/mta_cti/';

$house_keeping = '/house_keeping/';

$exc_dir       = '/data/mta/Script/ACIS/CTI/Exc/';

$bin_dir       = '/data/mta/MTA/bin/';
#
#########################################


group_plot_imaging();
#group_plot_spectral();
group_plot_spec_wo_bi();


########################################################
###    plot_fig: plot figure from a give data      #####
########################################################

sub plot_fig {

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

	pgslw(3); 
	pgpt(1, $xmin,$ybeg,-1);
	pgdraw($xmax,$yend);
	$second_line = 0;
	$fit = 0;
	pgslw(4); 

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
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
		$chk = 4.0 * int(0.25 * $year);
                if($year == $chk){
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

	open(IN, "$cti_dir/$hosue_keeping/Range_data/$range");
	while(<IN>){
		chomp $_;
		@atemp = split(/\t/,$_);
		if($atemp[0] ne "NO"){
			$auto = 0;
		}
		${range.$atemp[0]} = $atemp[1];
	}
	close(IN);

        for($j = 0; $j < 4; $j++){              #initializing for 4 CCDs 
                @{time.$j} =();
        }

        foreach $elem (@elm_array) {

               	foreach $input_in ('Det_Data7000', 'Det_Data_adjust'){

			$input_dir = "$cti_www/"."$input_in";
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


	               if($input_dir eq "$cti_www/Det_Data119"){
                              		@time_119  = @xbin;
                              		@node_119 = @node_value;
                              		@err_119  = @node_sigma;
				
                              		$count_119 = 0;
			foreach (@node_119){
					$count_119++;
				}
               		}


       	       		if($input_dir eq "$cti_www/Det_Data2000"){
                              		@time_2000  = @xbin;
                              		@node_2000 = @node_value;
                              		@err_2000  = @node_sigma;
				
                              		$count_2000 = 0;
				foreach (@node_2000){
					$count_2000++;
				}
               		}

		
       	       		if($input_dir eq "$cti_www/Det_Data7000"){
                              		@time_7000  = @xbin;
                              		@node_7000 = @node_value;
                              		@err_7000  = @node_sigma;
				
                              		$count_7000 = 0;
				foreach (@node_7000){
					$count_7000++;
				}
               		}


       	       		if($input_dir eq "$cti_www/Det_Data_adjust"){
                              		@time_adjust  = @xbin;
                              		@node_adjust = @node_value;
                              		@err_adjust  = @node_sigma;
				
                              		$count_adjust = 0;
				foreach (@node_adjust){
					$count_adjust++;
				}
               		}
		
		
	        	if($input_dir eq "$cti_www/Det_Data_cat_adjust"){
                              		@time_cat  = @xbin;
                              		@node_cat = @node_value;
                             		@err_cat  = @node_sigma;
				
                              		$count_cat = 0;
				foreach (@node_cat){
					$count_cat++;
				}
               		}
		}


##### pgplot routine starts from here.

		$xmin = $time_adjust[0];
		$last = $count_adjust - 1;
		$xmax = $time_adjust[$last];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
		$xmin = 0;
		$xmax += 0.05 * $diff;

		$xdiff  = $xmax - $xmin;
		$xmid   = $xmin + 0.50 * $xdiff;
		$xmin2  = $xmin + 0.05 * $xdiff;
		$xside  = $xmin - 0.05 * $xdiff;
		$xpos1  = $xmin - 0.10 * $xdiff;
		$xpos2  = $xmin + 0.25 * $xdiff;
		$xpos3  = $xmin + 0.60 * $xdiff;
		$xpos4  = $xmin + 0.25 * $xdiff;
		$xpos5  = $xmin + 0.50 * $xdiff;

		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(4);

#
#--- 
#
		$sum = 0;
		foreach $ent (@node_adjust){
			$sum += $ent;
		}
		$avg = $sum/$count_adjust;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ymin = 1.2;
		$ymax = 2.0;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.32 * $ydiff;

       		pgsvp(0.15, 0.96, 0.78, 0.96);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 7000 sec");
		pgptxt($xside, $ymin, 90.0, 0.5, "(S/I) * 10** 4");
#		pgptxt($xmid, $ytop2, 0.0, 0.5, "ACIS Imaging CCDs: Element: $elem");


		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node_7000;
		@yerr  = @yerr_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 0.96, 0.60, 0.78);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Temp Factor Corrected  & Int Time > 2000 sec");
		pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node_adjust;
		@yerr  = @yerr_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);
		pgclos();

		$name = './ACIS-I_'."$elem".'.gif';
		system("echo ''|/opt/local/bin/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $name");


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

	open(IN, "$cti_www/$house_keeping/Range_data/$range");
	while(<IN>){
		chomp $_;
		@atemp = split(/\t/,$_);
		if($atemp[0] ne "NO"){
			$auto = 0;
		}
		${range.$atemp[0]} = $atemp[1];
	}
	close(IN);

        for($j = 0; $j < 4; $j++){              #initializing for 4 CCDs 
                @{time.$j} =();
        }

        foreach $elem (@elm_array) {

               	foreach $input_in ('Det_Data7000', 'Det_Data_adjust'){

			$input_dir = "$cti_www/"."$input_in";

			@all_time =();
                	@node_value = ();
                	@node_sigma = ();
                	@time =();
                	foreach $gi ( 4, 6, 8, 9) {             # loop around 4 imaging CCDs


                        	$file="$elem"."_ccd$gi";        # and read all data
                        	open(FH, "$input_dir/$file");
                        	while(<FH>){
                                	chomp $_;
                                	@atemp = split(/\t/, $_);
                                	$time = $atemp[0];
					push(@all_time,$time);
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

			@new_time_list = ();
                	foreach $time (@new_data) {
                       		$sum    = 0.0;
                       		$sumx   = 0.0;
                       		$sigma  = 0.0;
                       		$sigmm  = 0.0;
				$i0 = 4;
				$i1 = 6;
				$i2 = 8;
				$i3 = 9;
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
                       			foreach $gi (4,6,8,9) {         #loop to CCDs
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


	               if($input_dir eq "$cti_www/Data119"){
                              		@time_119  = @xbin;
                              		@node_119 = @node_value;
                              		@err_119  = @node_sigma;
				
                              		$count_119 = 0;
			foreach (@node_119){
					$count_119++;
				}
               		}


       	       		if($input_dir eq "$cti_www/Data2000"){
                              		@time_2000  = @xbin;
                              		@node_2000 = @node_value;
                              		@err_2000  = @node_sigma;
				
                              		$count_2000 = 0;
				foreach (@node_2000){
					$count_2000++;
				}
               		}

		
       	       		if($input_dir eq "$cti_www/Data7000"){
                              		@time_7000  = @xbin;
                              		@node_7000 = @node_value;
                              		@err_7000  = @node_sigma;
				
                              		$count_7000 = 0;
				foreach (@node_7000){
					$count_7000++;
				}
               		}


       	       		if($input_dir eq "$cti_www/Data_adjust"){
                              		@time_adjust  = @xbin;
                              		@node_adjust = @node_value;
                              		@err_adjust  = @node_sigma;
				
                              		$count_adjust = 0;
				foreach (@node_adjust){
					$count_adjust++;
				}
               		}
		
		
	        	if($input_dir eq "$cti_www/Data_cat_adjust"){
                              		@time_cat  = @xbin;
                              		@node_cat = @node_value;
                             		@err_cat  = @node_sigma;
				
                              		$count_cat = 0;
				foreach (@node_cat){
					$count_cat++;
				}
               		}
		}


##### pgplot routine starts from here.

		$xmin = $time_adjust[0];
		$last = $count_adjust - 1;
		$xmax = $time_adjust[$last];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
		$xmin = 0;
		$xmax += 0.05 * $diff;

		$xdiff  = $xmax - $xmin;
		$xmid   = $xmin + 0.50 * $xdiff;
		$xmin2  = $xmin + 0.05 * $xdiff;
		$xside  = $xmin - 0.05 * $xdiff;
		$xpos1  = $xmin - 0.10 * $xdiff;
		$xpos2  = $xmin + 0.25 * $xdiff;
		$xpos3  = $xmin + 0.60 * $xdiff;
		$xpos4  = $xmin + 0.25 * $xdiff;
		$xpos5  = $xmin + 0.50 * $xdiff;

		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(4);

#
#--- not corrected
#
		$sum = 0;
		foreach $ent (@node_adjust){
			$sum += $ent;
		}
		$avg = $sum/$count_adjust;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ymin = 1.2;
		$ymax = 2.0;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.32 * $ydiff;

       		pgsvp(0.15, 0.96, 0.78, 0.96);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 7000 sec"); 
		pgptxt($xside, $ymin, 90.0, 0.5, "(S/I) * 10** 4");
#		pgptxt($xmid, $ytop2, 0.0, 0.5, "ACIS Spec. CCDs without BI Chips: Element: $elem");

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node_7000;
		@yerr  = @yerr_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);



       		pgsvp(0.15, 0.96, 0.60, 0.78);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmid, $ybot, 0.0, 0.5, "Time (DOM)");
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Temp Factor Corrected & Int Time > 2000 sec");


		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node_adjust;
		@yerr  = @yerr_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
print "$elm Slope: $slope\n";
		plot_fig();
		pgsci(1);
		pgclos();

		$name = './ACIS-S_w_o_BI_'."$elem".'.gif';
		system("echo ''|/opt/local/bin/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $name");


        }
}

######################################################
######################################################
######################################################

sub rm_dupl {
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
}

