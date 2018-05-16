#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################
#									#
# acis_cti_new_plot_only.perl: plot time vs cti evolution 		#
#									#
#	author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	last update: May 16, 2013					#
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

ccd_plot(al);					# plotting the data
ccd_plot(ti);
ccd_plot(mn);

group_plot_imaging();
group_plot_spec_wo_bi();
group_plot_spec_bi(5);
group_plot_spec_bi(7);

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
			$cno++;
		}
	}

	for($i = 0; $i < 10; $i++) {			# al, ti, and mn
		foreach $input_in ('Data119', 'Data2000', 'Data7000', 'Data_adjust', 'Data_cat_adjust'){

			$input_dir = "$data_dir/"."$input_in";

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
			$sum0   = 0;
			$sum1   = 0;
			$sum2   = 0;
			$sum3   = 0;
			$tsum0  = 0;
			$tsum1  = 0;
			$tsum2  = 0;
			$tsum3  = 0;
			$count  = 0;
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
			}

			if($input_dir eq "$data_dir/Data119"){
					@time_119  = @xbin;
					@node0_119 = @node0;
					@node1_119 = @node1;
					@node2_119 = @node2;
					@node3_119 = @node3;
					@err0_119  = @err0;
					@err1_119  = @err1;
					@err2_119  = @err2;
					@err3_119  = @err3;
					$count_119 = $count;
			}

			if($input_dir eq "$data_dir/Data2000"){
					@time_2000  = @xbin;
					@node0_2000 = @node0;
					@node1_2000 = @node1;
					@node2_2000 = @node2;
					@node3_2000 = @node3;
					@err0_2000  = @err0;
					@err1_2000  = @err1;
					@err2_2000  = @err2;
					@err3_2000  = @err3;
					$count_2000 = $count;
			}

			if($input_dir eq "$data_dir/Data7000"){
					@time_7000  = @xbin;
					@node0_7000 = @node0;
					@node1_7000 = @node1;
					@node2_7000 = @node2;
					@node3_7000 = @node3;
					@err0_7000  = @err0;
					@err1_7000  = @err1;
					@err2_7000  = @err2;
					@err3_7000  = @err3;
					$count_7000 = $count;
			}

			if($input_dir eq "$data_dir/Data_adjust"){
					@time_adjust  = @xbin;
					@node0_adjust = @node0;
					@node1_adjust = @node1;
					@node2_adjust = @node2;
					@node3_adjust = @node3;
					@err0_adjust  = @err0;
					@err1_adjust  = @err1;
					@err2_adjust  = @err2;
					@err3_adjust  = @err3;
					$count_adjust = $count;
			}

			if($input_dir eq "$data_dir/Data_cat_adjust"){
					@time_cat  = @xbin;
					@node0_cat = @node0;
					@node1_cat = @node1;
					@node2_cat = @node2;
					@node3_cat = @node3;
					@err0_cat  = @err0;
					@err1_cat  = @err1;
					@err2_cat  = @err2;
					@err3_cat  = @err3;
					$count_cat = $count;
			}
		}
					

##### pgplot routine starts from here.


		$xmin = $time_cat[0];
		$xmax = $time_cat[$count_cat - 1];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
		$xmax += 0.05 * $diff;

		$xdiff  = $xmax - $xmin;
		$xmid   = $xmin + 0.50 * $xdiff;
		$xmin2  = $xmin + 0.05 * $xdiff;
		$xside  = $xmin - 0.20 * $xdiff;
		$xpos1  = $xmin - 0.10 * $xdiff;
		$xpos2  = $xmin + 0.25 * $xdiff;
		$xpos3  = $xmin + 0.60 * $xdiff;
		$xpos4  = $xmin + 0.25 * $xdiff;
		$xpos5  = $xmin + 0.50 * $xdiff;

		pgbegin(0, "/cps",1,1);
		pgsch(1);
		pgslw(2);

#
#---- node 0
#
		$sum = 0;
		foreach $ent (@node0_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.15 * $ydiff;

       		pgsvp(0.15, 0.55, 0.75, 0.95);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node0_2000;
		@yerr  = @yerr0_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgptxt($xpos1, $ytop2, 0.0, 0.0, "No correction");

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node0_119;
		@yerr  = @yerr0_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgptxt($xpos2, $ytop2, 0.0, 0.0, "Temp< -119.7");

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node0_7000;
		@yerr  = @yerr0_7000;
		$count = $count_7000;
		pgptxt($xpos3, $ytop2, 0.0, 0.0, "Temp< -119.7 & Time >7000");
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xmin2, $ytop,   0.0, 0.0, "Quad 0");
		pgslw(3);
		pgptxt($xside, $ytop2, 0.0, 1.0, "Elm: $elm CCD$i");
		pgslw(2);

		pgsci(1);

       		pgsvp(0.15, 0.55, 0.55, 0.75);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node0_2000;
		@yerr  = @yerr0_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node0_cat;
		@yerr  = @yerr0_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node0_adjust;
		@yerr  = @yerr0_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xside, $ymin, 90.0, 0.5, "(S/I)x10**4");
#
#---- node 1
#
		$sum = 0;
		foreach $ent (@node1_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.10 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.15 * $ydiff;

       		pgsvp(0.60, 1.00, 0.75, 0.95);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node1_2000;
		@yerr  = @yerr1_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node1_119;
		@yerr  = @yerr1_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node1_7000;
		@yerr  = @yerr1_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xmin2, $ytop,   0.0, 0.0, "Quad 1");
		pgsci(5);
		pgptxt($xpos5,  $ytop2, 0.0, 0.0, "MIT/ACIS Adjusted");
		pgsci(6);
		pgptxt($xpos4,  $ytop2, 0.0, 0.0, "Adjusted");
		pgsci(1);


       		pgsvp(0.60, 1.00, 0.55, 0.75);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node1_2000;
		@yerr  = @yerr1_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node1_cat;
		@yerr  = @yerr1_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node1_adjust;
		@yerr  = @yerr1_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
#
#--- node 2
#
		$sum = 0;
		foreach $ent (@node2_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.10 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.15 * $ydiff;

       		pgsvp(0.15, 0.55, 0.33, 0.53);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node2_2000;
		@yerr  = @yerr2_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node2_119;
		@yerr  = @yerr2_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node2_7000;
		@yerr  = @yerr2_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xmin2, $ytop,   0.0, 0.0, "Quad 2");

       		pgsvp(0.15, 0.55, 0.13, 0.33);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node2_2000;
		@yerr  = @yerr2_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node2_cat;
		@yerr  = @yerr2_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node2_adjust;
		@yerr  = @yerr2_adjust;
		$count = $count_adjust;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xmax, $ybot, 0.0, 0.0, "Time (DOM)");
#
#--- node 3
#
		$sum = 0;
		foreach $ent (@node3_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.10 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.15 * $ydiff;

       		pgsvp(0.60, 1.00, 0.33, 0.53);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node3_2000;
		@yerr  = @yerr3_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node3_119;
		@yerr  = @yerr3_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(4);
		@xbin  = @time_7000;
		@ybin  = @node3_7000;
		@yerr  = @yerr3_7000;
		$count = $count_7000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(1);
       		pgptxt($xmin2, $ytop,   0.0, 0.0, "Quad 3");

       		pgsvp(0.60, 1.00, 0.13, 0.33);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCNST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node3_2000;
		@yerr  = @yerr3_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node3_cat;
		@yerr  = @yerr3_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();

		pgsci(6);
		@xbin  = @time_adjust;
		@ybin  = @node3_adjust;
		@yerr  = @yerr3_adjust;
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
		
		$name = "$cti_www/".'Data_Plot/'."$elm".'_ccd'."$i".'_plot.gif';
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $name");
	}
}


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
	pgslw(2); 

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

	open(IN, "$house_keeping/Range_data/$range");
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

               	foreach $input_in ('Data119', 'Data2000', 'Data7000', 'Data_adjust', 'Data_cat_adjust'){

			$input_dir = "$data_dir/"."$input_in";

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


	               if($input_dir eq "$data_dir/Data119"){
                              		@time_119  = @xbin;
                              		@node_119 = @node_value;
                              		@err_119  = @node_sigma;
				
                              		$count_119 = 0;
			foreach (@node_119){
					$count_119++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data2000"){
                              		@time_2000  = @xbin;
                              		@node_2000 = @node_value;
                              		@err_2000  = @node_sigma;
				
                              		$count_2000 = 0;
				foreach (@node_2000){
					$count_2000++;
				}
               		}

		
       	       		if($input_dir eq "$data_dir/Data7000"){
                              		@time_7000  = @xbin;
                              		@node_7000 = @node_value;
                              		@err_7000  = @node_sigma;
				
                              		$count_7000 = 0;
				foreach (@node_7000){
					$count_7000++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data_adjust"){
                              		@time_adjust  = @xbin;
                              		@node_adjust = @node_value;
                              		@err_adjust  = @node_sigma;
				
                              		$count_adjust = 0;
				foreach (@node_adjust){
					$count_adjust++;
				}
               		}
		
		
	        	if($input_dir eq "$data_dir/Data_cat_adjust"){
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

		$xmin = $time_cat[0];
		$last = $count_cat - 1;
		$xmax = $time_cat[$last];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
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
		pgslw(2);

#
#--- not corrected
#
		$sum = 0;
		foreach $ent (@node_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.32 * $ydiff;

       		pgsvp(0.15, 1.00, 0.78, 0.96);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Int Time > 2000 sec");
		pgptxt($xmid, $ytop2, 0.0, 0.5, "ACIS Imaging CCDs: Element: $elem");

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node_2000;
		@yerr  = @yerr_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.60, 0.78);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 2000 sec");

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node_119;
		@yerr  = @yerr_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.42, 0.60);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 7000 sec"); 
		pgptxt($xside, $ymin, 90.0, 0.0, "(S/I) * 10** 4");

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

       		pgsvp(0.15, 1.00, 0.24, 0.42);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "MIT/ACIS Temp Factor Corrected & Int Time > 2000 sec");

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node_cat;
		@yerr  = @yerr_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.06, 0.24);
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
		plot_fig();
		pgsci(1);
		pgclos();
		
		$name = "$cti_www/".'Data_Plot/ACIS-I_'."$elem".'.gif';
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $name");


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
	}
	close(IN);

        for($j = 0; $j < 4; $j++){              #initializing for 4 CCDs 
                @{time.$j} =();
        }

        foreach $elem (@elm_array) {

               	foreach $input_in ('Data119', 'Data2000', 'Data7000', 'Data_adjust', 'Data_cat_adjust'){

			$input_dir = "$data_dir/"."$input_in";

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


	               if($input_dir eq "$data_dir/Data119"){
                              		@time_119  = @xbin;
                              		@node_119 = @node_value;
                              		@err_119  = @node_sigma;
				
                              		$count_119 = 0;
			foreach (@node_119){
					$count_119++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data2000"){
                              		@time_2000  = @xbin;
                              		@node_2000 = @node_value;
                              		@err_2000  = @node_sigma;
				
                              		$count_2000 = 0;
				foreach (@node_2000){
					$count_2000++;
				}
               		}

		
       	       		if($input_dir eq "$data_dir/Data7000"){
                              		@time_7000  = @xbin;
                              		@node_7000 = @node_value;
                              		@err_7000  = @node_sigma;
				
                              		$count_7000 = 0;
				foreach (@node_7000){
					$count_7000++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data_adjust"){
                              		@time_adjust  = @xbin;
                              		@node_adjust = @node_value;
                              		@err_adjust  = @node_sigma;
				
                              		$count_adjust = 0;
				foreach (@node_adjust){
					$count_adjust++;
				}
               		}
		
		
	        	if($input_dir eq "$data_dir/Data_cat_adjust"){
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

		$xmin = $time_cat[0];
		$last = $count_cat - 1;
		$xmax = $time_cat[$last];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
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
		pgslw(2);

#
#--- not corrected
#
		$sum = 0;
		foreach $ent (@node_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.32 * $ydiff;

       		pgsvp(0.15, 1.00, 0.78, 0.96);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Int Time > 2000 sec");
		pgptxt($xmid, $ytop2, 0.0, 0.5, "ACIS Spec. CCDs without BI Chips: Element: $elem");

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node_2000;
		@yerr  = @yerr_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.60, 0.78);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 2000 sec");

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node_119;
		@yerr  = @yerr_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.42, 0.60);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 7000 sec"); 
		pgptxt($xside, $ymin, 90.0, 0.0, "(S/I) * 10** 4");

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

       		pgsvp(0.15, 1.00, 0.24, 0.42);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "MIT/ACIS Temp Factor Corrected & Int Time > 2000 sec");

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node_cat;
		@yerr  = @yerr_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.06, 0.24);
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
		plot_fig();
		pgsci(1);
		pgclos();
		
		$name = "$cti_www/".'Data_Plot/ACIS-S_w_o_BI_'."$elem".'.gif';
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $name");


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
	}
	close(IN);

        for($j = 0; $j < 4; $j++){              #initializing for 4 CCDs 
                @{time.$j} =();
        }

        foreach $elem (@elm_array) {

               	foreach $input_in ('Data119', 'Data2000', 'Data7000', 'Data_adjust', 'Data_cat_adjust'){

			$input_dir = "$data_dir/"."$input_in";

			@all_time =();
                	@node_value = ();
                	@node_sigma = ();
                	@time =();
                	foreach $gi ($ccd) {             # loop around 4 imaging CCDs


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
                       		foreach $gi ("$ccd") {         #loop to CCDs
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


	               if($input_dir eq "$data_dir/Data119"){
                              		@time_119  = @xbin;
                              		@node_119 = @node_value;
                              		@err_119  = @node_sigma;
				
                              		$count_119 = 0;
			foreach (@node_119){
					$count_119++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data2000"){
                              		@time_2000  = @xbin;
                              		@node_2000 = @node_value;
                              		@err_2000  = @node_sigma;
				
                              		$count_2000 = 0;
				foreach (@node_2000){
					$count_2000++;
				}
               		}

		
       	       		if($input_dir eq "$data_dir/Data7000"){
                              		@time_7000  = @xbin;
                              		@node_7000 = @node_value;
                              		@err_7000  = @node_sigma;
				
                              		$count_7000 = 0;
				foreach (@node_7000){
					$count_7000++;
				}
               		}


       	       		if($input_dir eq "$data_dir/Data_adjust"){
                              		@time_adjust  = @xbin;
                              		@node_adjust = @node_value;
                              		@err_adjust  = @node_sigma;
				
                              		$count_adjust = 0;
				foreach (@node_adjust){
					$count_adjust++;
				}
               		}
		
		
	        	if($input_dir eq "$data_dir/Data_cat_adjust"){
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

		$xmin = $time_cat[0];
		$last = $count_cat - 1;
		$xmax = $time_cat[$last];
		$diff = $xmax - $xmin;
		$xmin -= 0.05 * $diff;
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
		pgslw(2);

#
#--- not corrected
#
		$sum = 0;
		foreach $ent (@node_2000){
			$sum += $ent;
		}
		$avg = $sum/$count_2000;
		$ymin = $avg - 0.4;
		$ymax = $avg + 0.4;
		$ydiff  = $ymax - $ymin;
		$yside  = $ymin + 0.55 * $ydiff;
		$ytop   = $ymax - 0.15 * $ydiff;
		$ytop2  = $ymax + 0.10 * $ydiff;
		$ybot   = $ymin - 0.32 * $ydiff;

       		pgsvp(0.15, 1.00, 0.78, 0.96);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Int Time > 2000 sec");
		pgptxt($xmid, $ytop2, 0.0, 0.5, "ACIS Backside CCD$ccd: Element: $elem");

		pgsci(2);
		@xbin  = @time_2000;
		@ybin  = @node_2000;
		@yerr  = @yerr_2000;
		$count = $count_2000;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.60, 0.78);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 2000 sec");

		pgsci(3);
		@xbin  = @time_119;
		@ybin  = @node_119;
		@yerr  = @yerr_119;
		$count = $count_119;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.42, 0.60);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "Focal Temp < -119.7 C & Int Time > 7000 sec"); 
		pgptxt($xside, $ymin, 90.0, 0.0, "(S/I) * 10** 4");

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

       		pgsvp(0.15, 1.00, 0.24, 0.42);
       		pgswin($xmin, $xmax, $ymin, $ymax);
       		pgbox(ABCST, 0.0, 0.0, ABCNSTV, 0.0, 0.0);
		pgptxt($xmin2, $ytop, 0.0, 0.0, "MIT/ACIS Temp Factor Corrected & Int Time > 2000 sec");

		pgsci(5);
		@xbin  = @time_cat;
		@ybin  = @node_cat;
		@yerr  = @yerr_cat;
		$count = $count_cat;
		@date = @xbin;
		@dep  = @ybin;
		$total = $count;
		least_fit();
		$ybeg = $int + $slope * $xmin;
		$yend = $int + $slope * $xmax;
		plot_fig();
		pgsci(1);

       		pgsvp(0.15, 1.00, 0.06, 0.24);
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
		plot_fig();
		pgsci(1);
		pgclos();
		
		$name = "$cti_www/".'Data_Plot/BackSide_'."$ccd".'_'."$elem".'.gif';
		system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $name");


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

