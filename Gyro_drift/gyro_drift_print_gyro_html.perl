#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	gyro_drift_print_gyro_html.perl: compute statistics for gyro drift plots and create	#
#					 html page.						#
#												#
#	author:	t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: Jun 05, 2013								#
#												#
#################################################################################################
#
#--- html 5 conformed Oct 15, 2012
#
#
#--- check whether this is a test case.
#
$comp_test = $ARGV[0];
chomp $comp_test;

#
#---- read directories
#
if($comp_test =~ /test/i){
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list_test");
}else{
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list");
}

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- find today's date
#
if($comp_test =~ /test/i){
	$uyear      = 2012;
	$start_year = 2012;
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst) = localtime(time);
	$uyear += 1900;
	$start_year = 2000;
}

#
#--- read gif file names from the $fig_dir
#

$in_list =`ls $fig_dir/*gif`;
@list = split(/\s+/, $in_list);

foreach $file (@list){
#
#--- from the gif file name, create a html page, and find out which data it needs to use
#--- to compute statistics
#

#
#--- removing extra path from the head of gif file name
#
	@etemp = split(/gyro_drift_hist_/, $file);
	$gif_file = 'gyro_drift_hist_'."$etemp[1]";

	@atemp = split(/.gif/, $file);
	$head  = $atemp[0];
	@atemp = split(/.gif/, $gif_file);
	@btemp = split(/_/, $atemp[0]);
	$gyro  = $btemp[3];
	$ugyro = uc($gyro);
	$inst  = uc($btemp[4]);
	if($btemp[5] eq 'insr'){
		$ind  = 'insertion';
		$uind = 'Insertion';
	}else{
		$ind  = 'retraction';
		$uind = 'Retraction';
	}
#
#--- a html page priting start here
#
	$html_name = "$head".'.html';
	open(OUT, ">$html_name");
	print OUT "<!DOCTYPE html>\n";
	print OUT "<html>\n";
	print OUT "<head>\n";
	print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
	print OUT '<link rel="stylesheet" type="text/css" href="https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css" /> ',"\n";

	print OUT "<style  type='text/css'>\n";
	print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
	print OUT "td{text-align:center;padding:8px}\n";
	print OUT "a:link {color:#00CCFF;}\n";
	print OUT "a:visited {color:yellow;}\n";
	print OUT "span.nobr {white-space:nowrap;}\n";
	print OUT "</style>\n";

	print OUT '<title>',"$head",'</title></head>',"\n";
	print OUT '<body>',"\n";
	print OUT '<h2>Changes of ',"$ugyro ",'Gyro Drift Rate around ',"$inst $uind",'</h2>',"\n";
	print OUT '<br />',"\n";
	print OUT '<p>',"\n";
	print OUT 'First three plots below show time trend of standard',"\n";
	print OUT 'deviations of mean variations between observation and ',"\n";
	print OUT '5th degree polynomial line fitted on the data. The first one ',"\n";
	print OUT 'is before the grating motion started, the second one ',"\n";
	print OUT 'is during the motion, and the last one is after the motion completed.',"\n";
	print OUT 'The standard deviation larger than 5 is dropped from the computation as an outerlayer',"\n";
	print OUT '</p><p>',"\n";
	print OUT 'The next three plots are the ratio of the standard ',"\n";
	print OUT 'deviations used in the first three plots. ',"\n";
	print OUT 'The first one is before and during, the second one is after ',"\n";
	print OUT 'and during, and the last one is before and after the ',"\n";
	print OUT 'grating motion.',"\n";
	print OUT '</p><p style="padding-bottom:20px">',"\n";
	print OUT 'A fitted line is computed by robust method. Note that even for the last',"\n";
	print OUT 'three plots, the line was computed before taking log.',"\n";
	print OUT 'The values of  slopes are listed in <a href="#table">Table</a>',"\n";
	print OUT "</p>\n";

	print OUT '<img src="',"$gif_file",'" alt="',"$gif_file",'"  style="height:500px;width:700px">',"\n";

	print OUT "<p style='padding-bottom:20px;padding-top:20px'>\n";
	print OUT 'The next table shows the means and standard deviations of the ',"\n";
	print OUT 'original standard deviations, null probability, and slope of before, during, and after',"\n";
	print OUT 'the grating movements for the entire period.',"\n";
	print OUT 'The average and the standard deviation are also computed for each year.';
	print OUT "</p>\n";

	print OUT '<a id="table"></a>',"\n";
	print OUT '<table border=1>',"\n";
	print OUT '<tr><th rowspan=2>&#160;</th>';
	print OUT '<th colspan=2>Before</th>';
	print OUT '<th colspan=2>During</th>';
	print OUT '<th colspan=2>After</th>';
	print OUT '<th colspan=2>Before/During</th>';
	print OUT '<th colspan=2>After/During</th>';
	print OUT '<th colspan=2>Before/After</th>';
	print OUT '</tr>',"\n";
	print OUT '<tr>',"\n";
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '</tr>',"\n";
#
#--- here is the sub to compute statistics
#
	find_avg();
#
#--- avg and std for the entire period
#
	print OUT '<tr><th>Entire Period</th>',"\n";
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg1, $std1;
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg2, $std2;
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg3, $std3;
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg4, $std4;
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg5, $std5;
	printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",$avg6, $std6;
	print OUT "</tr>\n";
#
#--- null probability for the entire period
#
	print OUT '<tr><th>Null Probability</th>',"\n";
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_before;
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_during;
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_after;
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_b_d;
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_a_d;
	printf OUT "<td colspan=2 style='text-align:center'>%3.1f%</td>",$prob_b_a;
	print OUT "</tr>\n";
#
#--- slope and its error for the entire period
#
	print OUT '<tr><th>Slope</th>',"\n";
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_before;
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_during;
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_after;
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_b_d;
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_a_d;
	printf OUT "<td colspan=2 style='text-align:center'>%3.3e</td>",$slope_b_a;
	print OUT "</tr>\n";

	print OUT '<tr><td colspan=13>&#160;</td></tr>',"\n";

	print OUT '<tr><th rowspan=2>&#160;</th>';
	print OUT '<th colspan=2>Before</th>';
	print OUT '<th colspan=2>During</th>';
	print OUT '<th colspan=2>After</th>';
	print OUT '<th colspan=2>Before/During</th>';
	print OUT '<th colspan=2>After/During</th>';
	print OUT '<th colspan=2>Before/After</th>';
	print OUT '</tr>',"\n";
	print OUT '<tr>',"\n";
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '<th>Avg</th><th>Std</th>';
	print OUT '</tr>',"\n";
#
#--- avg and std for each year
#
	for($year = $start_year; $year <=$uyear; $year++){
		print OUT "<tr><th>$year</th>";
		$name3    = 'avg_'."$year".'_1';
		$name4    = 'std_'."$year".'_1';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		$name3    = 'avg_'."$year".'_2';
		$name4    = 'std_'."$year".'_2';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		$name3    = 'avg_'."$year".'_3';
		$name4    = 'std_'."$year".'_3';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		$name3    = 'avg_'."$year".'_4';
		$name4    = 'std_'."$year".'_4';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		$name3    = 'avg_'."$year".'_5';
		$name4    = 'std_'."$year".'_5';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		$name3    = 'avg_'."$year".'_6';
		$name4    = 'std_'."$year".'_6';
		printf OUT "<td style='text-align:center'>%3.4f</td><td style='text-align:center'>%3.4f</td>",${$name3},${$name4};

		print OUT '</tr>',"\n";
	}
	print OUT '</table>',"\n";
	print OUT "</body>\n";
	print OUT "</html>\n";

	close(OUT);
}

#############################################################################
### find_avg: compute statistics for a give data set                      ###
#############################################################################

sub find_avg {
#
#--- figuring out data file name
#
	if($file =~ /HETG/i){
		if($file =~ /INSR/i){
			$in_file = 'HETG_INSR';
		}else{
			$in_file = 'HETG_RETR';
		}
	}else{
		if($file =~ /INSR/i){
			$in_file = 'LETG_INSR';
		}else{
			$in_file = 'LETG_RETR';
		}
	}
#
#--- there are farther three possible combinations
#--- so there will be total 12 possibilities
#
	if($file =~ /pitch/i){
		$first  = 2;
		$second = 3;
		$third  = 4;
		$gyro   = 'pitch';
	}elsif($file =~ /roll/i){
		$first  = 5;
		$second = 6;
		$third  = 7;
		$gyro   = 'roll';
	}elsif($file =~ /yaw/i){
		$first  = 8;
		$second = 9;
		$third  = 10;
		$gyro   = 'yaw';
	}
#
#--- slope file name 
#
	$slope_file = 'slope_'."$in_file".'_'."$gyro";

	open(FH, "$in_file");

	@before = ();		#--- data for before the move
	@during = ();		#--- data for during the move
	@after  = ();		#--- data for after the move
	@b_d    = ();		#--- ratio of before/during
	@a_d    = ();		#--- ratio of after/during
	@b_a    = ();		#--- ratio of before/after
	$sum1   = 0;		#--- sum for before
	$sum2   = 0;		#--- sum of during
	$sum3   = 0;		#--- sum of after
	$sum4   = 0;		#--- sum of before/during
	$sum5   = 0;		#--- sum of after/during
	$sum6   = 0;		#--- sum of before/after
	$sum12  = 0;		#--- sum of (before)**2
	$sum22  = 0;		#--- sum of (during)**2
	$sum32  = 0;		#--- sum of (after)**2
	$sum42  = 0;		#--- sum of (before/during)**2
	$sum52  = 0;		#--- sum of (after/during)**2
	$sum62  = 0;		#--- sum of (before/after)**2
	$acnt   = 0;
#
#--- initialization for each year similar to the above
#
	for($year = $start_year; $year <= $uyear; $year++){
		$name     = 'sum_'."$year".'_1';
		$name2    = 'sum_'."$year".'_12';
		${$name}  = 0;
		${$name2} = 0;
		$name     = 'sum_'."$year".'_2';
		$name2    = 'sum_'."$year".'_22';
		${$name}  = 0;
		${$name2} = 0;
		$name     = 'sum_'."$year".'_3';
		$name2    = 'sum_'."$year".'_32';
		${$name}  = 0;
		${$name2} = 0;
		$name     = 'sum_'."$year".'_4';
		$name2    = 'sum_'."$year".'_42';
		${$name}  = 0;
		${$name2} = 0;
		$name     = 'sum_'."$year".'_5';
		$name2    = 'sum_'."$year".'_52';
		${$name}  = 0;
		${$name2} = 0;
		$name     = 'sum_'."$year".'_6';
		$name2    = 'sum_'."$year".'_62';
		${$name}  = 0;
		${$name2} = 0;
		$cname = 'cnt_'."$year";
		${$cname} = 0;
	}
	
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
#
#--- set a time in a unit of year
#
		$dev = 365;
		$chk = 4.0 * int(0.25 * $atemp[0]);
		if($chk == $atemp[0]){
			$dev = 366;
		}
		$date = $atemp[0]-1999 + $atemp[1]/$dev;
		push(@time, $date);
#
#--- save before, during, and after data
#
		@btemp = split(/\+\/\-/, $atemp[$first]);
		@ctemp = split(/\+\/\-/, $atemp[$second]);
		@dtemp = split(/\+\/\-/, $atemp[$third]);
#
#--- limit the std less than/equal 5
#
		if($btemp[1] > 5 || $ctemp[1] > 5 || $dtemp[1] > 5){
			next OUTER;
		}
		push(@before, $btemp[1]);
		push(@during, $ctemp[1]);
		push(@after,  $dtemp[1]);
#
#--- compute the ratios
#
		if($ctemp[1] == 0){
			$ratio1 = 0;
			$ratio2 = 0;
		}else{
			$ratio1 = abs($btemp[1]/$ctemp[1]);
			$ratio2 = abs($dtemp[1]/$ctemp[1]);
		}
		if($dtemp[1] == 0){
			$ratio3 = 0;
		}else{
			$ratio3 = abs($btemp[1]/$dtemp[1]);
		}

		push(@b_d, $ratio1);
		push(@a_d, $ratio2);
		push(@b_a, $ratio3);

		$sum1  += $btemp[1];
		$sum2  += $ctemp[1];
		$sum3  += $dtemp[1];
		$sum4  += $ratio1;
		$sum5  += $ratio2;
		$sum6  += $ratio3;
		$sum12 += $btemp[1] * $btemp[1];
		$sum22 += $ctemp[1] * $ctemp[1];
		$sum32 += $dtemp[1] * $dtemp[1];
		$sum42 += $ratio1 * $ratio1;
		$sum52 += $ratio2 * $ratio2;
		$sum62 += $ratio3 * $ratio3;
		$acnt++;

		$name     = 'sum_'."$atemp[0]".'_1';
		${$name} += $btemp[1];
		$name     = 'sum_'."$atemp[0]".'_2';
		${$name} += $ctemp[1];
		$name     = 'sum_'."$atemp[0]".'_3';
		${$name} += $dtemp[1];
		$name     = 'sum_'."$atemp[0]".'_4';
		${$name} += $ratio1;
		$name     = 'sum_'."$atemp[0]".'_5';
		${$name} += $ratio2;
		$name     = 'sum_'."$atemp[0]".'_6';
		${$name} += $ratio3;


		$name     = 'sum_'."$atemp[0]".'_12';
		${$name} += $btemp[1] * $btemp[1];
		$name     = 'sum_'."$atemp[0]".'_22';
		${$name} += $ctemp[1] * $ctemp[1];
		$name     = 'sum_'."$atemp[0]".'_32';
		${$name} += $dtemp[1] * $dtemp[1];
		$name     = 'sum_'."$atemp[0]".'_42';
		${$name} += $ratio1 * $ratio1;
		$name     = 'sum_'."$atemp[0]".'_52';
		${$name} += $ratio2 * $ratio2;
		$name     = 'sum_'."$atemp[0]".'_62';
		${$name} += $ratio3 * $ratio3;

#
#--- # of data in each year is recorded in ${$cname}
#
		$cname = 'cnt_'."$atemp[0]";
		${$cname}++;
	}
	close(FH);
#
#--- compute average and std
#
	$avg1 = $sum1/$acnt;
	$std1 = sqrt($sum12/$acnt - $avg1 * $avg1);

	$avg2 = $sum2/$acnt;
	$std2 = sqrt($sum22/$acnt - $avg2 * $avg2);

	$avg3 = $sum3/$acnt;
	$std3 = sqrt($sum32/$acnt - $avg3 * $avg3);

	$avg4 = $sum4/$acnt;
	$std4 = sqrt($sum42/$acnt - $avg4 * $avg4);

	$avg5 = $sum5/$acnt;
	$std5 = sqrt($sum52/$acnt - $avg5 * $avg5);

	$avg6 = $sum6/$acnt;
	$std6 = sqrt($sum62/$acnt - $avg6 * $avg6);

	for($year = $start_year; $year <= $uyear; $year++){
		$cname    = 'cnt_'."$year";

		$name     = 'sum_'."$year".'_1';
		$name2    = 'sum_'."$year".'_12';
		$name3    = 'avg_'."$year".'_1';
		$name4    = 'std_'."$year".'_1';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});
	
		$name     = 'sum_'."$year".'_2';
		$name2    = 'sum_'."$year".'_22';
		$name3    = 'avg_'."$year".'_2';
		$name4    = 'std_'."$year".'_2';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});

		$name     = 'sum_'."$year".'_3';
		$name2    = 'sum_'."$year".'_32';
		$name3    = 'avg_'."$year".'_3';
		$name4    = 'std_'."$year".'_3';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});

		$name     = 'sum_'."$year".'_4';
		$name2    = 'sum_'."$year".'_42';
		$name3    = 'avg_'."$year".'_4';
		$name4    = 'std_'."$year".'_4';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});

		$name     = 'sum_'."$year".'_5';
		$name2    = 'sum_'."$year".'_52';
		$name3    = 'avg_'."$year".'_5';
		$name4    = 'std_'."$year".'_5';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});

		$name     = 'sum_'."$year".'_6';
		$name2    = 'sum_'."$year".'_62';
		$name3    = 'avg_'."$year".'_6';
		$name4    = 'std_'."$year".'_6';

		${$name3} = ${$name}/${$cname};
		${$name4} = sqrt(${$name2}/${$cname} - ${$name3} * ${$name3});
	}
#
#---- compute students t probablitiy---- it is a null hypothesis
#	
	$n = $acnt--;
	@x = @time;
	@y = @before;
	pearsn();
	$prob_before = 100 * $prob;
	@y = @during;
	pearsn();
	$prob_during = 100 * $prob;
	@y = @after;
	pearsn();
	$prob_after  = 100 * $prob;
	@y = @b_d;
	pearsn();
	$prob_b_d    = 100 * $prob;
	@y = @a_d;
	pearsn();
	$prob_a_d    = 100 * $prob;
	@y = @b_a;
	pearsn();
	$prob_b_a    = 100 * $prob;

#
#---- read slope values
#
	open(FH, "$slope_file");
	@slope = ();
	while(<FH>){
		chomp $_;
		push(@slope, $_);
	}
	close(FH);

	$slope_before = $slope[0];
	$slope_during = $slope[1];
	$slope_after  = $slope[2];
	$slope_b_d    = $slope[3];
	$slope_a_d    = $slope[4];
	$slope_b_a    = $slope[5];
}
	
###########################################################################
### pearsn: compute corr. coeff, and it's significant level             ###
###########################################################################

sub pearsn{
	my($j, $yt, $xt, $t, $df, $syy, $sxy, $sxx, $ay, $ax, $tiny);
	$tiny = 1.0e-20;

###############################################################
#	input: 	@x: array 1
#		@y: array 2
#		$n: number of elements 
#	output:	$r: linear correlation coefficient
#		$z: fisher's z transformation
#		$prob: student's t probability
#	this function and a few below were taken from 
#	Numerical Recipes (C version) Chapter 14.5 and 
#	related chapters
###############################################################

#
#---- find the means
#
	for($j = 1; $j <= $n; $j++){
		$ax += $x[$j];
		$ay += $y[$j];
	}
	$ax /= $n;
	$ay /= $n;
#
#---- compute the correlation coefficient
#
	for($j = 1; $j < $n; $j++){
		$xt = $x[$j] - $ax;
		$yt = $y[$j] - $ay;
		$sxx += $xt * $xt;
		$syy += $yt * $yt;
		$sxy += $xt * $yt;
	}
	$r = $sxy / (sqrt($sxx * $syy) + $tiny);
#
#---- Fisher's z transformation
#
	$z = 0.5 * log((1.0 + $r + $tiny)/(1.0 - $r + $tiny));
	$df = $n -2;
#
#---- Student's t probability
#
	$t    = $r * sqrt($df/((1.0 - $r + $tiny) * (1.0 + $r + $tiny)));
	$prob = betai(0.5 * $df, 0.5, $df/($df + $t * $t));
}

###########################################################################
### betai: returns the incomplete beta fuction                          ###
###########################################################################

sub betai {
	my ($a, $b, $x, $bt);
	($a, $b, $x) = @_;

	if($x < 0.0 || $x > 1.0) {
		print "Bad x in routine betai\n";
		exit 1;
	}

	if($x == 0.0 || $x == 1.0){
		$bt = 0.0;
	}else{
#
#--- factors in front of the continued fraction
#
		$bt = exp(gammln($a + $b) - gammln($a) - gammln($b) + $a * log($x) + $b * log(1.0 - $x));
	}
	if($x < ($a + 1.0)/($a + $b + 2.0)){
		$beta_i = $bt * betacf($a, $b, $x)/$a;
	}else{
		$beta_i = 1.0 - $bt * betacf($b, $a, 1.0- $x)/$b;
	}
	return $beta_i;
}


###########################################################################
### betacf: evaluates continued fraction for incomplete beta function   ###
###########################################################################

sub betacf{
	my($a, $b, $x, $m, $m2, $aa, $c, $d, $del, $h, $qab, $qam, $qap, $maxit, $eps, $fpmin);
	$maxit = 100;
	$eps   = 3.0e-7;
	$fpmin = 1.0e-30;

	($a, $b, $x) = @_;
#
#--- these q's will be used in factors that occur in the coefficient
#
	$qab = $a + $b;
	$qap = $a + 1.0;
	$qam = $a - 1.0;
#
#--- first step of Lentz's method
#
	$c   = 1.0;
	$d   = 1.0 - $qab * $x / $qap;

	if(abs($d) < $fpmin){
		 $d = $fpmin;
	}
	$d = 1.0 / $d;
	$h = $d;

	for($m = 1; $m <= $maxit; $m++){
		$m2 = 2 * $m;
		$aa = $m * ($b - $m)* $x / (($qam + $m2) * ($a + $m2));
#
#--- one step (the even one) of the recurrence
#
		$d  = 1.0 + $aa * $d;
		if(abs($d) < $fpmin ){
			 $d = $fpmin;
		}
		$c = 1.0 + $aa/$c;
		if(abs($c) < $fpmin){
			$c = $fpmin;
		}
		$d = 1.0 / $d;
		$h *= $d * $c;
		$aa = -1.0 * ($a + $m) * ($qab + $m) * $x/(($a + $m2) * ($qap + $m2));
#
#--- next step of the recurrence (the odd one)
#
		$d = 1.0 + $aa * $d;
		if(abs($d) < $fpmin){
			 $d = $fpmin;
		}
		$c = 1.0 + $aa / $c;
		if(abs($c) < $fpmin){
			$c = $fpmin;
		}
		$d = 1.0 / $d;
		$del = $d * $c;
		$h  *= $del;
		if(abs($del - 1.0) < $eps){
			last;
		}
	}
	if($m > $maxit){
		print "a or b too big, or maxit too small in betacf\n";
	}
	return $h;
}

###########################################################################
### return ln of gamma functioin                                        ###
###########################################################################

sub gammln{

	my($xx, $x,$t, $tmp, $ser, $j, $result);
	my(@cof);
	($xx) = @_;
		
	@cof = (76.18009172947146, -86.50532032941677, 24.01409824083091, -1.231739572450155, 
		0.1208650973866179e-2, -0.5395239384953e-5);

	$x = $xx;
	$y = $xx; 
	$tmp = $x + 5.5;
	$tmp -= ($x + 0.5) * log($tmp);
	$ser  = 1.000000000190015;
	for($j = 0; $j <= 5; $j++){
		$ser += $cof[$j] / $y;
		$y++;
	}
	$result = -1.0 * $tmp + log(2.5066282746310005 * $ser / $x);
	return $result;
}
