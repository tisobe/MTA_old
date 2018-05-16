#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#		acis_ft_diff_fp_plots.perl: this creates plots of difference between	#
#				    focal plane temp and cold radiator temp		#
#				    plot agaist time for several different 		#
#				    time intervals.					#
#				    This is a part of a csh script: plotting_script	#
#		author: Takashi Isobe (tisobe@cfa.harvard.edu)				#
#		Apr 5, 2000	version 0.1						#
#		Jul 28, 2000	modified the origial diff_fp_daily.perl to accept	#
#				new database format					#
#		Feb 15, 2004	added three month plots					#
#											#
#		Last Update: Apr 16, 2013						#
#											#
#########################################################################################
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;


##############################################################################
#
#---- directory setting
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Focal/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
##############################################################################

#
#-- find today's date
#
if($comp_test =~ /test/i){
	@time =  (0, 0, 0, 24, 1, 113, 1, 56, 0);
}else{
	@time  = localtime(time);
}
$year  = $time[5] + 1900;
$add   = 365 * ($year - 2000);
$lyear = $year -1;

#
#---  need one exta after leap year
#
$add_date += int(0.25 * ($year - 1997));
#
#--- indicators for whether the data cross over a year line
#
$m3_ch  = 0;
$m_ch   = 0;
$w_ch   = 0;
$s_ch   = 0;

#
#--- find 3 month ago, 1 month ago, 7 day ago, and 1 day ago.
#--- check whether intervals accorss year line
#
$m3_ago = $time[7] - 90;
if($m3_ago < 0){
	$m3_ch = 1;
}
$m_ago = $time[7] - 30; 
if($m_ago < 0){	
	$m_ch = 1;
}
$w_ago = $time[7] - 7 ;
if($w_ago < 0) {
	$w_ch = 1;
}
$d3ago = $time[7] - 3 ;
if($d3ago < 0) {
	$s_ch = 1;
}
$today = $time[7] - 1;

@edate    = ();
@eside_a  = ();
@eside_b  = ();
@tyear    = ();
@xdate    = ();
@xtemp    = ();
@xsidea   = ();
@xsideb   = ();
@m3date   = ();
@m3side_a = ();
@m3side_b = ();
@mdate    = ();
@mside_a  = ();
@mside_b  = ();
@wdate    = ();
@wside_a  = ();
@wside_b  = ();
@sdate    = ();
@sside_a  = ();
@sside_b  = ();
@tdate    = ();
@tside_a  = ();
@tside_b  = ();
$ecount   = 0;
$m3count  = 0;
$mcount   = 0;
$ncount   = 0;
$wcount   = 0;
$scount   = 0;
$tcount   = 0;

#
#--- long term data are from long_term_data which has only averaged data
#
open(FH,"$data_out/long_term_data");
while(<FH>){			
	chomp $_;
	@atemp = split(/\t/,$_);
	push(@edate,$atemp[0]);
	$diff = $atemp[1] - $atemp[2];
	push(@eside_a,$diff);
	$diff = $atemp[1] - $atemp[3];
	push(@eside_b,$diff);
	$ecount++;
}
close(FH);
#
#--- any plot less than a month is from month_data which has full data point
#
open(FH, "$data_out/month_data");

$mcount = 0;			
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/,$_);
	push(@xyear,  $atemp[0]);
	push(@xdate,  $atemp[1]);
	push(@xtemp,  $atemp[2]);
	push(@xsidea, $atemp[3]);
	push(@xsideb, $atemp[4]);
	if($d_chk < 0){
		$y_begin = $xyear[$mcount-1]  -1;
	}else{
		$y_begin = $xyear[$mcount-1];
	}
	$chk = 4.0 * int (0.25 * $atemp[0]);
	if($chk == $atemp[0]){
        	$div = 366;
	}else{
        	$div = 365;
	}
	$t_temp = $atemp[0] + $atemp[1]/$div;
	push(@y_date, $t_temp);			# this is a date with, e.g.: 2000.34 format
	$mcount++;
}
close(FH);
#
#--- any plot less than a week is from week_data which has full data points
#
open(FH, "$data_out/week_data");
$ncount = 0;		
while(<FH>) {
	chomp $_;
	@atemp = split(/\t/,$_);
	push(@wxyear,  $atemp[0]);
	push(@wxdate,  $atemp[1]);
	push(@wxtemp,  $atemp[2]);
	push(@wxsidea, $atemp[3]);
	push(@wxsideb, $atemp[4]);
	$ncount++;
}
close(FH);
#
#--- three month plot data
#
$m3_begin = $y_date[$mcount-1] - 0.25;

for($i = 0; $i < $mcount; $i++){
	if($y_date[$i] > $m3_begin){
		push(@m3date, $y_date[$i]);
		$diff = $xtemp[$i] - $xsidea[$i];
		push(@m3side_a, $diff);
		$diff = $xtemp[$i] - $xsideb[$i];
		push(@m3side_b, $diff);
		$m3count++;
	}
}

#
#--- month data
#
$year_first = $xyear[0];
$year_end   = $xyear[$mcount-1];
$year_first = $year_end;
if($m_ch == 1) {
	$year_first = $year_end -1;
}
$smcount = 0;
#
#--- the case the entire datasets are in the same year
#
if($year_first == $year_end) {			
	for($inc = 0;$inc < $mcount; $inc++){	
		$diffa = $xtemp[$inc] - $xsidea[$inc];
		$diffb = $xtemp[$inc] - $xsideb[$inc];

		if($xyear[$inc] == $year_end && $xdate[$inc] >= $m_ago){
			push(@mdate,   $xdate[$inc]);
			push(@mside_a, $diffa);
			push(@mside_b, $diffb);
			$smcount++;
		}
	}
#
#--- the case that year changed during the plotting period
#
}elsif($year_first < $year_end) {
				
	$yadd   = 365;
	$chk    = 4 * int(0.25 * $year_first);
	if($year_first == $chk){
		$yadd = 366;
	}
	$nm_ago = $yadd + $m_ago;

	for($inc = 0; $inc < $mcount; $inc++){
		$adate = $xdate[$inc];
		if($year > $year_first){
			$yadd   = 365;
			$chk    = 4 * int(0.25 * $year_first);
			if($year_first == $chk){
				$yadd = 366;
			}
			$adate += $yadd;
		}

		$diffa = $xtemp[$inc] - $xsidea[$inc];
		$diffb = $xtemp[$inc] - $xsideb[$inc];

		if($xyear[$inc] > $year_first && $adate > $nm_ago){
			push(@mdate,   $adate);
			push(@mside_a, $diffa);
			push(@mside_b, $diffb);
			$smcount++;
		}
	}
}
#
#--- week data, 3 day data, and today's data
#

$year_first = $wxyear[0];
$year_end   = $wxyear[$ncount-1];

#
#--- the case the entire datasets are in the same year
#
if($year_first == $year_end) {			
	for($inc = 0; $inc < $ncount; $inc++){	
		$diffa = $wxtemp[$inc] - $wxsidea[$inc];
		$diffb = $wxtemp[$inc] - $wxsideb[$inc];
		if($wxdate[$inc] >= $w_ago) {
			push(@wdate,   $wxdate[$inc]);
			push(@wside_a, $diffa);
			push(@wside_b, $diffb);
			$wcount++;
		}

		if($wxdate[$inc] >= $d3ago) {
			push(@sdate,   $wxdate[$inc]);
			push(@sside_a, $diffa);
			push(@sside_b, $diffb);
			$scount++;
		}

		if($wxdate[$inc] >= $today) {
			push(@tdate,   $wxdate[$inc]);
			push(@tside_a, $diffa);
			push(@tside_b, $diffb);
			$tcount++;
		}
	}
#
#--- the case that year changed during the plotting period
#
}elsif($year_first < $year_end) {	
	$yadd = 365;
	$chk    = 4 * int(0.25 * $year_first);
	if($year_first == $chk){
		$yadd = 366;
	}

	$w_ago += $yadd;
	$d3ago += $yadd;
	$today += $yadd;

	for($inc = 0; $inc < $ncount; $inc++){
		$adate = $wxdate[$inc];
		if($year > $year_first){
			$yadd = 365;
			$chk    = 4 * int(0.25 * $year_first);
			if($year_first == $chk){
				$yadd = 366;
			}
			$adate += $yadd;
		}

		$diffa = $wxtemp[$inc] - $wxsidea[$inc];
		$diffb = $wxtemp[$inc] - $wxsideb[$inc];

		if($xdate[$inc] >= $w_ago) {
			push(@wdate,   $adate);
			push(@wside_a, $diffa);
			push(@wside_b, $diffb);
		}

		if($xdate[$inc] >= $d3ago) {
			push(@sdate,   $adate);
			push(@sside_a, $diffa);
			push(@sside_b, $diffb);
		}

		if($xdate[$inc] >= $today) {
			push(@tdate,   $adate);
			push(@tside_a, $diffa);
			push(@tside_b, $diffb);
		}
	}
}

	
########### plotting starts here #################

#
#--- entire mission
#
@date   = @edate;	
@side_a = @eside_a;
@side_b = @eside_b;
$count  = $ecount;
$x_axis = "Time (Day of Mission)";
$title  = "FP Temp - Cold Radiator";
$head   = "entire";
start_plot();
#
#--- three  month
#
@date   = @m3date;
@side_a = @m3side_a;
@side_b = @m3side_b;
$count  = $m3count;
$x_axis = "Time (Year)";
$title  = "FP Temp - Cold Radiator (Three Months)";
$head   = "month3";
start_plot();
#
#--- a month
#
@date   = @mdate;
@side_a = @mside_a;
@side_b = @mside_b;
$count  = $smcount;
$x_axis = "Time (Day of Year)";
$title  = "FP Temp - Cold Radiator (Month)";
$head   = "month";
start_plot();
#
#--- a week
#
@date   = @wdate;
@side_a = @wside_a;
@side_b = @wside_b;
$count  = $wcount;
$x_axis = "Time (Day of Year)";
$title  = "FP Temp - Cold Radiator (Week)";
$head   = "week";
start_plot();
#
#-- 3 days
#
@date   = @sdate;
@side_a = @sside_a;
@side_b = @sside_b;
$count  = $scount;
$x_axis = "Time (Day of Year)";
$title  = "FP Temp - Cold Radiator (3 Days)";
$head   = "day3";
start_plot();
#
#--- one day
#
@date   = @tdate;
@side_a = @tside_a;
@side_b = @tside_b;
$count  = $tcount;
$x_axis = "Time (Day of Year)";
$title  = "FP Temp - Cold Radiator (One Days)";
$head   = "today";
start_plot();

##########################
#### start_plot: plot ####
##########################

sub start_plot {
	$xmin = $date[1];
	$xmax = $date[$count-2];
	@temp = sort{$a<=>$b}@side_a;
#
#--- Side A plotting
#
	@y = @side_a;
#
#---  finding  y max; just in a case drop  any extreme	
#
	@rtemp = reverse(@temp);	
	OUTER:	
	foreach $ent (@rtemp) {
		if($ent < 20) {
#
#--- 2 deg of an extra space
#
			$ymax = $ent + 2;
			last OUTER;
		}
	}
#
#--- finding y min.
#
	OUTER:
	foreach $ent (@temp) {
		if($ent > -20) {
			$ymin = $ent - 2;
			last OUTER;
		}
	}
	$side= "Side A";
#
#--- plotting starts here 
#

	pgbegin(0, "/ps",1,1);
	pgsubp(1,1);          
	pgsch(2);             
	pgslw(4);
#
#--- plotting sub
#	
	plot_fig();
#
#--- convert a ps file to a gif file
#
	$name = "$head"."_side_a.gif";
	system("echo ''| gs -sDEVICE=pgmraw -sOutputFile=- -g2100x2769 -r256x256 -q pgplot.ps|  pnmscale -xsize 500| ppmquant 16| pnmpad -white -left=20 -right=20 -top=20 -bottom=20| pnmflip -r270| ppmtogif > $web_dir/Figs/$name");

	system("rm -rf pgplot.ps");
#
#--- Side B plotting
#
	@y     = @side_b;
	@temp  = sort{$a<=>$b}@side_b;
	@rtemp = reverse(@temp);
	OUTER:
	foreach $ent (@rtemp) {
        	if($ent < 20) {
                	$ymax = $ent + 2;
                	last OUTER;
        	}
	}
	OUTER:
	foreach $ent (@temp) {
		if($ent > -20) {
			$ymin = $ent - 2;
			last OUTER;
		}
	}
#
#--- plotting starts here 
#
	$side= "Side B";

	pgbegin(0, "/ps",1,1); 
	pgsubp(1,1);          
	pgsch(2);             
	pgslw(4);
#
#--- plotting sub
#	
	plot_fig();
#
#--- convert a ps file to a gif file
#
	$name = "$head"."_side_b.gif";
	system("echo ''| gs -sDEVICE=pgmraw -sOutputFile=- -g2100x2769 -r256x256 -q pgplot.ps|  pnmscale -xsize 500| ppmquant 16| pnmpad -white -left=20 -right=20 -top=20 -bottom=20| pnmflip -r270| ppmtogif > $web_dir/Figs/$name");
	system("rm -rf pgplot.ps");
}

##################################
### plot_fig: plotting routine ###
##################################

sub plot_fig {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

        pgpt(1, $date[0], $y[0], -1);                # plot a point (x, y)
        for($m = 1; $m < $count-1; $m++) {
                unless($y[$m] eq '*****' || $y[$m] eq ''){
                        pgpt(1,$date[$m], $y[$m], -2);
                }
        }
        pglabel("$x_axis","Differential Temp (C)", "$title $side");     # write labels
	pgclos();
}


