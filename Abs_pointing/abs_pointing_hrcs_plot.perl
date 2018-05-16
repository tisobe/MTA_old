#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################
#                                                                               #
#       hrcs_plot.perl: plottting hrc s  data                                   #
#                                                                               #
#       author: t. isobe (tiosbe@cfa.harvard.edu)                               #
#       last update Apr 26, 2013                                                #
#                                                                               #
#################################################################################
#
#---- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

###################################################################
#
#---- setting directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
###################################################################

open(FH, "$data_dir/hrc_s_data");
@time_save = ();
@y_diff = ();
@z_diff = ();
$count = 0;
while(<FH>) {
        chomp $_;
        @intemp = split(/\t/,$_);
        $time = $intemp[0];
        push(@time_save,$time);
        push(@y_diff, $intemp[5]);
        push(@z_diff, $intemp[6]);
        $count++;
}

######## setting up for pgplot

pgbegin(0, "/cps",1,1);
pgsubp(1,2);
pgsch(2); 
pgslw(4); 

@xbin = @time_save;
@ybin = @y_diff;

x_min_max();			# looking for min and max of date

### Here is a ra plot

#y_min_max();
$ymin = -2;
$ymax =  2;

$yt_axis = 'Y Axis Error (Arc-sec)';
$xt_axis = 'Time (Day of Mission)';

$title = 'HRC S Pointing Errors in Y axis (Obs - Nominal)';

$data_cnt = $count;
@xdata    = @xbin;
@ydata    = @ybin;

robust_fit();
$s_int = $int;
#least_fit();
plot_fig();			# ploting routines are in here

###  Here is a dec plot

$total = $count;
@ybin = @z_diff;
#y_min_max();

$yt_axis = 'Z Axis Error (Arc-sec)';
$xt_axis = 'Time (Day of Mission)';

$title = 'HRC S Pointing Errors in  Z axis (Obs - Nominal)';

@ydata = @ybin;
robust_fit();
$s_int = $int;
plot_fig();

pgend;

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $web_dir/Fig_save/hrc_s_point_err.gif");
system("rm -rf pgplot.ps");


########################################################
###    plot_fig: plot figure from a give data      #####
########################################################

sub plot_fig {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

        pgpt(1, $xbin[0], $ybin[0], -1);                # plot a point (x, y)
        for($m = 0; $m < $count; $m++) {
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
	pgslw(4);
	pgpt(1,$xmin,0,-1);
	pgdraw($xmax,0);
        $y_bot = $s_int + $slope * $xmin;
        $y_top = $s_int + $slope * $xmax;
        pgsci(2);
        pgmove($xmin, $y_bot);
        pgdraw($xmax, $y_top);
        pgsci(1);
        pglabel("$xt_axis","$yt_axis", "$title");       # write labels
        $diff = $xmax - $xmin;
        $x_pos = $xmin + 0.01 * $diff;
        $diff = $ymax - $ymin;
        $y_pos = $ymax - 0.10 * $diff;
        $adjusted_slope = adjust_digit_length($slope);
        pgptxt($x_pos, $y_pos, 0.0, 0.0, "Slope: $adjusted_slope");
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


####################################################################
### adjust_digit_length: adjust digit 4 digit for display etc   ####
####################################################################

sub adjust_digit_length {

###############################################################################
#       Input: $org_value: original value, adjust_digit_length(<input value>)
#
#       Output: $add_value; shortened value for a display
#                               <output > = adjust_digit_length
###############################################################################

        my(@atemp, $org_value, $e_yes, $ent, $exp, @bt, $save, @at, $add_value, $add);

        ($org_value) = @_;

        $org_value =~ s/\s+//;

        @atemp = split(//, $org_value);
        unless($atemp[0] eq ''){
                $e_yes = 0;
                if($org_value =~ /e/i) {
                        $e_yes = 1;
                }

                if($e_yes == 0) {
                        $exp = 0;
                        $ad_value = $org_value;
                        unless($ad_value == 0) {
                                if(abs($ad_value) < 1.0){
                                        OUTER:
                                        while(abs($ad_value) < 1.0) {
                                                $exp++;
                                                $ad_value = 10.0 * $ad_value;
                                                if($exp > 10){
                                                        print "something wrong at digit adjust\n";
                                                        exit 1;
                                                }
                                        }
                                }
                                @bt = split(//,$ad_value);
                                $ad_value = "$bt[0]"."$bt[1]"."$bt[2]"."$bt[3]"."$bt[4]";
                                if($bt[0] eq '-'){
                                        $ad_value = "$ad_value"."$bt[5]";
                                }
                                if($exp > 0){
                                        $ad_value = "$ad_value".'e'.'-'."$exp";
                                }
                        }
                }else{
                        @at = split(//,$org_value);
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

                        $ad_value = "$save[0]"."$save[1]"."$save[2]";
                        $ad_value = "$ad_value"."$save[3]"."$save[4]";
                        if($save[0] eq '-') {
                                $ad_value = "$ad_value"."$save[5]";
                        }
                        $ad_value = "$ad_value"."e";
                        foreach $add (@exp) {
                                unless($add eq '0'){
                                if($add =~ /\d/){
                                        $add += 4;
                                }
                                        $ad_value = "$ad_value"."$add";
                                }
                        }

                }
        }
        return $ad_value;
}



####################################################################
### robust_fit: linear fit for data with medfit robust fit metho  ##
####################################################################

sub robust_fit{
	$sumx = 0;
	$symy = 0;
	for($n = 0; $n < $data_cnt; $n++){
		$sumx += $xdata[$n];
		$symy += $ydata[$n];
	}
	$xavg = $sumx/$data_cnt;
	$yavg = $sumy/$data_cnt;
#
#--- robust fit works better if the intercept is close to the
#--- middle of the data cluster.
#
	@xldat = ();
	@yldat = ();
	for($n = 0; $n < $data_cnt; $n++){
		$xldat[$n] = $xdata[$n] - $xavg;
		$yldat[$n] = $ydata[$n] - $yavg;
	}

	$total = $data_cnt;
	medfit();

	$alpha += $beta * (-1.0 * $xavg) + $yavg;
	
	$int   = $alpha;
	$slope = $beta;
}


####################################################################
### medfit: robust filt routine                                  ###
####################################################################

sub medfit{

#########################################################################
#									#
#	fit a straight line according to robust fit			#
#	Numerical Recipes (FORTRAN version) p.544			#
#									#
#	Input:		@xldat	independent variable			#
#			@yldat	dependent variable			#
#			total	# of data points			#
#									#
#	Output:		alpha:	intercept				#
#			beta:	slope					#
#									#
#	sub:		rofunc evaluate SUM( x * sgn(y- a - b * x)	#
#			sign   FORTRAN/C sign function			#
#									#
#########################################################################

	my $sx  = 0;
	my $sy  = 0;
	my $sxy = 0;
	my $sxx = 0;

	my (@xt, @yt, $del,$bb, $chisq, $b1, $b2, $f1, $f2, $sigb);
#
#---- first compute least sq solution
#
	for($j = 0; $j < $total; $j++){
		$xt[$j] = $xldat[$j];
		$yt[$j] = $yldat[$j];
		$sx  += $xldat[$j];
		$sy  += $yldat[$j];
		$sxy += $xldat[$j] * $yldat[$j];
		$sxx += $xldat[$j] * $xldat[$j];
	}

	$del = $total * $sxx - $sx * $sx;
#
#----- least sq. solutions
#
	$aa = ($sxx * $sy - $sx * $sxy)/$del;
	$bb = ($total * $sxy - $sx * $sy)/$del;
	$asave = $aa;
	$bsave = $bb;

	$chisq = 0.0;
	for($j = 0; $j < $total; $j++){
		$diff   = $yldat[$j] - ($aa + $bb * $xldat[$j]);
		$chisq += $diff * $diff;
	}
	$sigb = sqrt($chisq/$del);
	$b1   = $bb;
	$f1   = rofunc($b1);
	$b2   = $bb + sign(3.0 * $sigb, $f1);
	$f2   = rofunc($b2);

	$iter = 0;
	OUTER:
	while($f1 * $f2 > 0.0){
		$bb = 2.0 * $b2 - $b1;
		$b1 = $b2; 
		$f1 = $f2;
		$b2 = $bb;
		$f2 = rofunc($b2);
		$iter++;
		if($iter > 100){
			last OUTER;
		}
	}

	$sigb *= 0.01;
	$iter = 0;
	OUTER1:
	while(abs($b2 - $b1) > $sigb){
		$bb = 0.5 * ($b1 + $b2);
		if($bb == $b1 || $bb == $b2){
			last OUTER1;
		}
		$f = rofunc($bb);
		if($f * $f1 >= 0.0){
			$f1 = $f;
			$b1 = $bb;
		}else{	
			$f2 = $f;
			$b2 = $bb;
		}
		$iter++;
		if($iter > 100){
			last OTUER1;
		}
	}
	$alpha = $aa;
	$beta  = $bb;
	if($iter >= 100){
		$alpha = $asave;
		$beta  = $bsave;
	}
	$abdev = $abdev/$total;
}

##########################################################
### rofunc: evaluatate 0 = SUM[ x *sign(y - a bx)]     ###
##########################################################

sub rofunc{
	my ($b_in, @arr, $n1, $nml, $nmh, $sum);

	($b_in) = @_;
	$n1  = $total + 1;
	$nml = 0.5 * $n1;
	$nmh = $n1 - $nml;
	@arr = ();
	for($j = 0; $j < $total; $j++){
		$arr[$j] = $yldat[$j] - $b_in * $xldat[$j];
	}
	@arr = sort{$a<=>$b} @arr;
	$aa = 0.5 * ($arr[$nml] + $arr[$nmh]);
	$sum = 0.0;
	$abdev = 0.0;
	for($j = 0; $j < $total; $j++){
		$d = $yldat[$j] - ($b_in * $xldat[$j] + $aa);
		$abdev += abs($d);
		$sum += $xldat[$j] * sign(1.0, $d);
	}
	return($sum);
}


##########################################################
### sign: sign function                                ###
##########################################################

sub sign{
        my ($e1, $e2, $sign);
        ($e1, $e2) = @_;
        if($e2 >= 0){
                $sign = 1;
        }else{
                $sign = -1;
        }
        return $sign * $e1;
}
