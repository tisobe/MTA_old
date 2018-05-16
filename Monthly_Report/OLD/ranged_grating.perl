#!/usr/bin/perl

#########################################################################
#									#
#	ranged_grating.perl: count # of insertion and retraction of 	#
#		    	     hetg and letg				#
#									#
#   		This version of grating movement check is:		#
#			out: when a value is > 70			#
#			in:  when a value is < 20			#
#									#
#		Need: month_list					#
#		      ../MJ/Save/comprehensive_data_summary		#
#									#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)			#
#									#
#	Aug. 9, 2000:	first version					#
#									#
#########################################################################


open(FH, "./month_list");

$cnt = 0;
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/, $_);
	push(@year, $atemp[0]);
	push(@begin, $atemp[1]);
	push(@end, $atemp[2]);
	$d_cnt++;
}
close(FH);

$pre_ha = 50;
$pre_hb = 50;
$pre_la = 50;
$pre_lb = 50;

@tha_max_list = ();
@tha_min_list = ();
@thb_max_list = ();
@thb_min_list = ();
@tla_max_list = ();
@tla_min_list = ();
@tlb_max_list = ();
@tlb_min_list = ();

for($i = 0; $i < $d_cnt; $i++) {
	@ha_max_list = ();
	@ha_min_list = ();
	@hb_max_list = ();
	@hb_min_list = ();
	@la_max_list = ();
	@la_min_list = ();
	@lb_max_list = ();
	@lb_min_list = ();
	@save_ha_out = ();
	@save_ha_in  = ();
	@save_hb_out = ();
	@save_hb_in  = ();
	@save_la_out = ();
	@save_la_in  = ();
	@save_lb_out = ();
	@save_lb_in  = ();
	
	open(FH, "../MJ/Save/comprehensive_data_summary");
	while(<FH>) {
		chomp $_;
		@atemp = split(/\t/,$_);
		@btemp = split(/:/,$atemp[0]);
		$eyear = $btemp[0];
		$eday  = $btemp[1];
		$hposaro = $atemp[9];
		$hposbro = $atemp[10];
		$lposaro = $atemp[11];
		$lposbro = $atemp[12];

	
		if($year[$i] == $eyear && $begin[$i] <= $eday && $end[$i] >= $eday) {


			if($hposaro > 70) {
				push(@save_ha_out, $hposaro);
			}else{
				if($pre_ha > 70) {
					@save_ha_out = sort{$a<=>$b} @save_ha_out;
					$max = pop(@save_ha_out);
					push(@ha_max_list, $max);
					push(@tha_max_list, $max);
					@save_ha_out = ();
				}
			}	

			if($hposaro < 20) {
				push(@save_ha_in, $hposaro);
			}else{
				if($pre_ha < 20) {
					@save_ha_in = sort{$a<=>$b} @save_ha_in;
					$min = shift(@save_ha_in);
					push(@ha_min_list, $min);
					push(@tha_min_list, $min);
					@save_ha_in = ();
				}
			}	


			if($hposbro > 70) {
				push(@save_hb_out, $hposbro);
			}else{
				if($pre_hb > 70) {
					@save_hb_out = sort{$a<=>$b} @save_hb_out;
					$max = pop(@save_hb_out);
					push(@hb_max_list, $max);
					push(@thb_max_list, $max);
					@save_hb_out = ();
				}
			}	

			if($hposbro < 20) {
				push(@save_hb_in, $hposbro);
			}else{
				if($pre_hb < 20) {
					@save_hb_in = sort{$a<=>$b} @save_hb_in;
					$min = shift(@save_hb_in);
					push(@hb_min_list, $min);
					push(@thb_min_list, $min);
					@save_hb_in = ();
				}
			}	


			if($lposaro > 70) {
				push(@save_la_out, $lposaro);
			}else{
				if($pre_la > 70) {
					@save_la_out = sort{$a<=>$b} @save_la_out;
					$max = pop(@save_la_out);
					push(@la_max_list, $max);
					push(@tla_max_list, $max);
					@save_la_out = ();
				}
			}	

			if($lposaro < 20) {
				push(@save_la_in, $lposaro);
			}else{
				if($pre_la < 20) {
					@save_la_in = sort{$a<=>$b} @save_la_in;
					$min = shift(@save_la_in);
					push(@la_min_list, $min);
					push(@tla_min_list, $min);
					@save_la_in = ();
				}
			}	


			if($lposbro > 70) {
				push(@save_lb_out, $lposbro);
			}else{
				if($pre_lb > 70) {
					@save_lb_out = sort{$a<=>$b} @save_lb_out;
					$max = pop(@save_lb_out);
					push(@lb_max_list, $max);
					push(@tlb_max_list, $max);
					@save_lb_out = ();
				}
			}	

			if($lposbro < 20) {
				push(@save_lb_in, $lposbro);
			}else{
				if($pre_lb < 20) {
					@save_lb_in = sort{$a<=>$b} @save_lb_in;
					$min = shift(@save_lb_in);
					push(@lb_min_list, $min);
					push(@tlb_min_list, $min);
					@save_lb_in = ();
				}
			}	
		}
		$pre_ha = $hposaro;
		$pre_hb = $hposbro;
		$pre_la = $lposaro;
		$pre_lb = $lposbro;
	}
	close(FH);

	print_mean(@ha_max_list);
	print_mean(@ha_min_list);
	print_mean(@hb_max_list);
	print_mean(@hb_min_list);
	print_mean(@la_max_list);
	print_mean(@la_min_list);
	print_mean(@lb_max_list);
	print_mean(@lb_min_list);
	print "\n";

}
print "Total \n";
print_mean(@tha_max_list);
print_mean(@tha_min_list);
print_mean(@thb_max_list);
print_mean(@thb_min_list);
print_mean(@tla_max_list);
print_mean(@tla_min_list);
print_mean(@tlb_max_list);
print_mean(@tlb_min_list);
print "\n";

########################################################################
########################################################################
########################################################################


sub print_mean {
	@list = @_;
	$sum  = 0;
	$sum2 = 0;
	$mcnt  = 0;
	
	OUTER:
	foreach $ent (@list) {
		@atemp = split(//,$ent);
		unless(pop(@atemp) =~ /\d/) {
			next OUTER;
		}
		$sum += $ent;
		$sum2 += $ent*$ent;
		$mcnt++;
	}
	$mean = 0;
	$dev  = 0;
	if($mcnt > 0) {
		$mean = $sum/$mcnt;
		$mean2 = $sum2/$mcnt;
		$var = ($mean2 - $mean*$mean);
		$dev = sqrt ($var);
	}

	printf("%5.2f+/-%5.2f:%3d   ",$mean,$dev,$mcnt);
}
