#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	plot_hrc_evol.perl: plot evolution of HRC PHA from give data (fitting_results)		#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Apr 17, 2013							#
#												#
#################################################################################################
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

##########################################################################
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
##########################################################################

if($comp_test =~ /test/i){
	$file = "$test_web_dir/fitting_results";
}else{
	$file = "$house_keeping/fitting_results";
}

@year = ();
@date = ();
@inst = ();
@dist = ();
@med  = ();
@mean = ();
@std  = ();
$tot  = 0;

open(FH, "$file");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	$dom   = ch_time_form_to_dom($atemp[1]);
	@btemp = split(/-/, $atemp[1]);
	push(@year, $btemp[0]);
	push(@date, $dom);
	push(@inst, $atemp[2]);
	push(@dist, $atemp[7]);
	push(@med,  $atemp[8]);
	push(@mean, $atemp[9]);
	push(@std,  $atemp[11]);
	$tot++;
}
close(FH);
#
#--- find fitting range in year
#
@temp = sort{$a<=>$b}@year;
$max_yr = $temp[$tot-2];

#
#---HRC-I, Radial Plots
#
pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(2);
#
#--- plotting symbol and explanation of the symbol
#
pgsvp(0.05, 1.00, 0.96, 1.00);
pgswin(0, 18, 0, 1.0);

$diff = $max_yr - 1999;
$step = 1.5;
$cnt  = 0;
$cnt2 = 0;
for($j = 1999; $j <= $max_yr; $j++){
	$symbol = $j - 1997;
	pgsci($symbol);
	if($symbol < 14){
		$xpos = $cnt * $step + $xmin;
		$xpos2 = $xpos + 0.03 * $diff;
		pgpt(1, $xpos, 1.0 , $symbol); 
		@ytemp = split(//, $j);
		
		pgptxt($xpos2, 0.7, 0, 0, ": $ytemp[2]$ytemp[3]");
		$cnt++;
	}else{
		$xpos = $cnt2 * $step + $xmin;
		$xpos2 = $xpos + 0.03 * $diff;
		pgpt(1, $xpos, 0.5 , $symbol); 
		@ytemp = split(//, $j);
		pgptxt($xpos2, 0.2, 0, 0, ": $ytemp[2]$ytemp[3]");
		$cnt2++;
	}
}
pgsci(1);
#
#--- median
#
pgsvp(0.08, 1.00, 0.67, 0.96);
pgswin(0, 18, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($med[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $med[$i], $symbol);
}
pgsci(1);

$xlpos = 0.5;
pgptxt($xlpos, 210, 0,0, "PHA Median");

pgsci(1);
#
#--- mean
#
pgsvp(0.08, 1.00, 0.37, 0.66);
pgswin(0, 18, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($mean[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $mean[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 210, 0,0, "PHA Gaussian Peak Position");
pgptxt(-1.0, 110, 90, 0.5, 'PHA');
#
#--- width
#
pgsvp(0.08, 1.00, 0.07, 0.36);
pgswin(0, 18, 0, 40);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($std[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $std[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 36, 0,0, "PHA Gaussian Profile Width");
pgptxt(8, -7, 0, 0.5, "Radial Distance (Arcsec)");
pgclos();

if($comp_test =~ /test/i){
	$out_gif = "$test_web_dir/".'hrc_i_radial.gif';
}else{
	$out_gif = "$web_dir/".'hrc_i_radial.gif';
}
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_gif");


#
#---HRC-S, Radial Plots
#
pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(2);
#
#--- plotting symbol and explanation of the symbol
#
pgsvp(0.05, 1.00, 0.96, 1.00);
pgswin(0, 18, 0, 1.0);

$diff = $max_yr - 1999;
$step = 1.5;
$cnt  = 0;
$cnt2 = 0;
for($j = 1999; $j <= $max_yr; $j++){
        $symbol = $j - 1997;
        pgsci($symbol);
        if($symbol < 14){
                $xpos = $cnt * $step + $xmin;
                $xpos2 = $xpos + 0.03 * $diff;
                pgpt(1, $xpos, 1.0 , $symbol);
		@ytemp = split(//, $j);
                pgptxt($xpos2, 0.7, 0, 0, ": $ytemp[2]$ytemp[3]");
                $cnt++;
        }else{
                $xpos = $cnt2 * $step + $xmin;
                $xpos2 = $xpos + 0.02 * $diff;
                pgpt(1, $xpos, 0.5 , $symbol);
		@ytemp = split(//, $j);
                pgptxt($xpos2, 0.2, 0, 0, ": $ytemp[2]$ytemp[3]");
                $cnt2++;
        }
}
pgsci(1);
#
#--- median
#
pgsvp(0.08, 1.00, 0.67, 0.96);
pgswin(0, 18, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($med[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $med[$i], $symbol);
}
pgsci(1);

$xlpos = 0.5;
pgptxt($xlpos, 210, 0,0, "PHA Median");

pgsci(1);
#
#--- mean
#
pgsvp(0.08, 1.00, 0.37, 0.66);
pgswin(0, 18, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($mean[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $mean[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 210, 0,0, "PHA Gaussian Peak Position");
pgptxt(-1.0, 110, 90, 0.5, 'PHA');
#
#--- width
#
pgsvp(0.08, 1.00, 0.07, 0.36);
pgswin(0, 18, 0, 40);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	$symbol = $year[$i] - 1997;
	pgsci($symbol);
	if($std[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $dist[$i], $std[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 36, 0,0, "PHA Gaussian Profile Width");
pgptxt(8, -7, 0, 0.5, "Radial Distance (Arcsec)");
pgclos();

if($comp_test =~ /test/i){
	$out_gif = "$test_web_dir".'hrc_s_radial.gif';
}else{
	$out_gif = "$web_dir".'hrc_s_radial.gif';
}
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_gif");

system('rm -rf pgplot.ps');


#
#---HRC-I, Time  Plots
#


@temp = sort{$a<=>$b} @date;
$xmax = $temp[$tot -2];
$xmax *= 1.1;

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(2);
#
#--- notation 
#
pgsvp(0.05, 1.00, 0.96, 1.00);
pgswin(0, 1.0,  0, 1.0);

$symbol = 2;
pgsci($symbol);
pgpt(1, 0.1, 0.5, $symbol);
pgptxt(0.12, 0.4, 0, 0, ": Distance < 5");

$symbol = 3;
pgsci($symbol);
pgpt(1, 0.3, 0.5, $symbol);
pgptxt(0.32, 0.4, 0, 0, ": 5<= Distance < 10");

$symbol = 4;
pgsci($symbol);
pgpt(1, 0.6, 0.5, $symbol);
pgptxt(0.62, 0.4, 0, 0, ": 10 <= Distance");

pgsci(1);
#
#--- median
#
pgsvp(0.08, 1.00, 0.67, 0.96);
pgswin(0, $xmax, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $med[$i], $symbol);
}
pgsci(1);

$xlpos = 10;
pgptxt($xlpos, 210, 0,0, "PHA Median");

pgsci(1);
#
#--- mean
#
pgsvp(0.08, 1.00, 0.37, 0.66);
pgswin(0, $xmax, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	if($mean[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $mean[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 210, 0,0, "PHA Gaussian Peak Position");
$xbot = -1.0 * 0.06 * $xmax;
pgptxt($xbot, 110, 90, 0.5, 'PHA');
#
#--- width
#
pgsvp(0.08, 1.00, 0.07, 0.36);
pgswin(0, $xmax, 0, 40);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-S/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	if($std[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $std[$i], $symbol);
}
pgsci(1);
$xmid = 0.5 * $xmax;
pgptxt($xlpos,37, 0,0, "PHA Gaussian Profile Width");
pgptxt($xmid, -7, 0, 0.5, "Time (DOM)");
pgclos();

if($comp_test =~ /test/i){
	$out_gif = "$test_web_dir/".'hrc_i_time.gif';
}else{
	$out_gif = "$web_dir/".'hrc_i_time.gif';
}
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_gif");

system('rm -rf pgplot.ps');

#
#---HRC-S, Time  Plots
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(2);
#
#--- notation
#
pgsvp(0.05, 1.00, 0.96, 1.00);
pgswin(0, 1.0,  0, 1.0);

$symbol = 2;
pgsci($symbol);
pgpt(1, 0.1, 0.5, $symbol);
pgptxt(0.12, 0.4, 0, 0, ": Distance < 5");

$symbol = 3;
pgsci($symbol);
pgpt(1, 0.3, 0.5, $symbol);
pgptxt(0.32, 0.4, 0, 0, ": 5<= Distance < 10");

$symbol = 4;
pgsci($symbol);
pgpt(1, 0.6, 0.5, $symbol);
pgptxt(0.62, 0.4, 0, 0, ": 10 <= Distance");

pgsci(1);
#
#--- median
#
pgsvp(0.08, 1.00, 0.67, 0.96);
pgswin(0, $xmax, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $med[$i], $symbol);
}
pgsci(1);

$xlpos = 10;
pgptxt($xlpos, 210, 0,0, "PHA Median");

pgsci(1);
#
#--- mean
#
pgsvp(0.08, 1.00, 0.37, 0.66);
pgswin(0, $xmax, 0, 230);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	if($mean[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $mean[$i], $symbol);
}
pgsci(1);
pgptxt($xlpos, 210, 0,0, "PHA Gaussian Peak Position");
$xbot = -1.0 * 0.06 * $xmax;
pgptxt($xbot, 110, 90, 0.5, 'PHA');
#
#--- width
#
pgsvp(0.08, 1.00, 0.07, 0.36);
pgswin(0, $xmax, 0, 40);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);

OUTER:
for($i = 0; $i < $tot; $i++){
	if($inst[$i] =~ /HRC-I/i){
		next OUTER;
	}
	if($dist[$i] < 5){
		$symbol = 2;
		pgsci($symbol);
	}elsif($dist[$i] < 10){
		$symbol = 3;
		pgsci($symbol);
	}else{
		$symbol = 4;
		pgsci($symbol);
	}

	if($med[$i] <= 0){
		next OUTER;
	}
	if($std[$i] <= 0){
		next OUTER;
	}
	pgpt(1, $date[$i], $std[$i], $symbol);
}
pgsci(1);
$xmid = 0.5 * $xmax;
pgptxt($xlpos,37, 0,0, "PHA Gaussian Profile Width");
pgptxt($xmid, -7, 0, 0.5, "Time (DOM)");
pgclos();

if($comp_test =~ /test/i){
	$out_gif = "$test_web_dir/".'hrc_s_time.gif';
}else{
	$out_gif = "$web_dir/".'hrc_s_time.gif';
}
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_gif");

system('rm -rf pgplot.ps');

	









###############################################################
###  ch_time_form_to_dom: changing time format  to dom   ######
###############################################################

sub ch_time_form_to_dom {

#############################################################################
#       Input: time: format is 2004-01-05T01:02:03 (from fits file header)
#                    called in:  ch_time_form_to_dom($time);
#
#       Output: acc_date: day of mission (less than a day added) returned
#
#       Sub:    conv_date_dom
#############################################################################

        my ($time, @atemp, $year, $month, $day);
        my ( @atemp, @btemp, $hr, $min, $sec, $hms, $acc_date);

        ($time) = @_;

        @atemp = split(/T/,$time);
        @btemp = split(/-/,$atemp[0]);

        $year  = $btemp[0];
        $month = $btemp[1];
        $day   = $btemp[2];

        $acc_date = conv_date_dom($year, $month, $day); #--- another format change

        @ctemp = split(/:/,$atemp[1]);
        $hr  = $ctemp[0]/24.0;
        $min = $ctemp[1]/1440.0;
        $sec = $ctemp[2]/86400.0;

        $hms = $hr + $min + $sec;

        $acc_date += $hms;
        return $acc_date;
}

###########################################################################
###      conv_date_dom: modify data/time format                       #####
###########################################################################

sub conv_date_dom {

#############################################################
#       Input:  $year: year in a format of 2004
#               $month: month in a formt of  5 or 05
#               $day:   day in a formant fo 5 05
#
#       Output: acc_date: day of mission returned
#############################################################

        my($year, $month, $day, $chk, $acc_date);

        ($year, $month, $day) = @_;

        $acc_date = ($year - 1999) * 365;

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
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                $chk = 4.0 * int(0.25 * $year);
                if($year == $chk) {
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
        $acc_date -= 202;
        return $acc_date;
}




