#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	hrc_temperature_plot.perl: HRC related temperature MSIDs were trended			#
#												#
#	author: t. isobe (tisobe@cfa.harvard.edu)						#
#												#
#	last update: May 12, 2014								#
#												#
#################################################################################################

$house_keeping = '/data/mta/Script/HRC/house_keeping/';
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

if($comp_test =~ /test/i){
#
#--- for the test case
#
	$test_out = ' /data/mta/Script/HRC/Temperature/Test_out';
	system("mkdir $test_out");

	open(OUT, '>./ds_file');
	print OUT 'columns=mtahrc..hrctemp_avg',"\n";
	print OUT 'timestart=2010:001:00:00:00',"\n";
	print OUT 'timestop=2010:060:00:00:00'."\n";
	close(OUT);
}else{
#
#--- find today's date
#

	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
	$year = $uyear + 1900;
	$month = $umon + 1;
	$today = "$year:$uyday:00:00:00";

#
#--- set dataseeker input file
#

	open(OUT, '>./ds_file');
	print OUT 'columns=mtahrc..hrctemp_avg',"\n";
	print OUT 'timestart=1999:202:00:00:00',"\n";
	print OUT 'timestop='."$today\n";
	close(OUT);
}

#
#--- call dataseeker
#

system("punlearn dataseeker; dataseeker.pl infile=ds_file print=yes outfile=hrc_temp.fits loginFile=$house_keeping/loginfile");

system("dmlist infile=\"hrc_temp.fits[cols time,2ceahvpt_avg,2chtrpzt_avg,2condmxt_avg,2dcentrt_avg,2dtstatt_avg,2fhtrmzt_avg,2fradpyt_avg,2pmt1t_avg,2pmt2t_avg,2uvlspxt_avg]\" outfile=hrc_temp.dat opt=data");

if($comp_test =~ /test/i){
	system("mv hrc_temp.fits $test_out");
	system("gzip $test_out/hrc_temp.fits");
	system("rm -rf ds_file");
}else{
	system("rm -rf ds_file  hrc_temp.fits");
}

@time = ();
@ceahvpt = ();
@chtrpzt = ();
@condmxt = ();
@dcentrt = ();
@dtstatt = ();
@fhtrmzt = ();
@fradpyt = ();
@pmt1t   = ();
@pmt2t   = ();
@uvlspxt = ();

$count = 0;

open(FH, "./hrc_temp.dat");

OUTER:
while(<FH>){
	chomp $_;
	$string = $_;
	$string =~ s/^\s+//; 
	@atemp = split(/\s+/, $string);

	if($atemp[0] =~ /\d/){
		$date = $atemp[1] - 48902399;
		$date /= 86400;
		push(@time,    $date);
		push(@ceahvpt, $atemp[2]);
		push(@chtrpzt, $atemp[3]);
		push(@condmxt, $atemp[4]);
		push(@dcentrt, $atemp[5]);
		push(@dtstatt, $atemp[6]);
		push(@fhtrmzt, $atemp[7]);
		push(@fradpyt, $atemp[8]);
		push(@pmt1t,   $atemp[9]);
		push(@pmt2t,   $atemp[10]);
		push(@uvlspxt, $atemp[11]);
		$count++;
	}
}
close(FH);
if($comp_test =~ /test/i){
	system("mv hrc_temp.dat $test_out");
}else{
	system("rm -rf hrc_temp.dat");
}

@temp = sort{$a<=>$b} @time;
if($comp_test =~ /test/){
	$xmin = $temp[3];
}else{
	$xmin = 0;
}
$xmax = $temp[$count -1];
$diff = int($xmax - $xmin);
$xmax = $xmax + 0.05 * $diff;

$sum1  = 0;
$sum2  = 0;
$sum3  = 0;
$sum4  = 0;
$sum5  = 0;
$sum6  = 0;
$sum7  = 0;
$sum8  = 0;
$sum9  = 0;
$sum10 = 0;
$scnt  = 0;
@avg_ceahvpt   = ();
@avg_chtrpzt   = ();
@avg_condmxt   = ();
@avg_dcentrt   = ();
@avg_dtstatt   = ();
@avg_fhtrmzt   = ();
@avg_fradpyt   = ();
@avg_pmt1t     = ();
@avg_pmt2t     = ();
@avg_uvlspxt   = ();
@day   = ();
$start = 0;
$end   = 1;
$dtot  = 0;

#
#---- modify data interval from 5 min to one day to reduce # of data points
#
$start = int($time[0]);
$end   = $start + 1;

OUTER:
for($i = 0; $i < $count; $i++){
	if($time[$i] > $start && $time[$i] <= $end){
		$sum1 += $ceahvpt[$i];
		$sum2 += $chtrpzt[$i];
		$sum3 += $condmxt[$i];
		$sum4 += $dcentrt[$i];
		$sum5 += $dtstatt[$i];
		$sum6 += $fhtrmzt[$i];
		$sum7 += $fradpyt[$i];
		$sum8 += $pmt1t[$i];
		$sum9 += $pmt2t[$i];
		$sum10+= $uvlspxt[$i];
		$scnt++;
	}elsif($time[$i] < $start){
		next OUTER;	
	}elsif($time[$i] > $xmax){
		last OUTER;
	}elsif($time[$i] > $end){
		if($scnt > 0){
			$sum1 /= $scnt;
			$sum2 /= $scnt;
			$sum3 /= $scnt;
			$sum4 /= $scnt;
			$sum5 /= $scnt;
			$sum6 /= $scnt;
			$sum7 /= $scnt;
			$sum8 /= $scnt;
			$sum9 /= $scnt;
			$sum10 /= $scnt;
		}else{
			$sum1 = 0;
			$sum2 = 0;
			$sum3 = 0;
			$sum4 = 0;
			$sum5 = 0;
			$sum6 = 0;
			$sum7 = 0;
			$sum8 = 0;
			$sum9 = 0;
			$sum10 = 0;
		}
		push(@day, $start);
		push(@avg_ceahvpt, $sum1);
		push(@avg_chtrpzt, $sum2);
		push(@avg_condmxt, $sum3);
		push(@avg_dcentrt, $sum4);
		push(@avg_dtstatt, $sum5);
		push(@avg_fhtrmzt, $sum6);
		push(@avg_fradpyt, $sum7);
		push(@avg_pmt1t, $sum8);
		push(@avg_pmt2t, $sum9);
		push(@avg_uvlspxt, $sum10);
		$dtot++;
		$sum1 = $ceahvpt[$i];
		$sum2 = $chtrpzt[$i];
		$sum3 = $condmxt[$i];
		$sum4 = $dcentrt[$i];
		$sum5 = $dtstatt[$i];
		$sum6 = $fhtrmzt[$i];
		$sum7 = $fradpyt[$i];
		$sum8 = $pmt1t[$i];
		$sum9 = $pmt2t[$i];
		$sum10= $uvlspxt[$i];
		$scnt = 1;
		$start++;
		$end++;
	}
}


#
#--- plotting start here
#

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(3);

@temp = sort{$a<=>$b} @avg_ceahvpt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
	$asum1 += $ent;
	$asum2  += $ent * $ent;
	$tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 4.0 * $std);
$ymax = int($mean + 4.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'ceahvpt';

pgsvp(0.1, 0.95, 0.81, 0.98);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCSNTV, 0.0, 0.0);
@avg = @avg_ceahvpt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_chtrpzt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'chtrpzt';

pgsvp(0.1, 0.95, 0.63, 0.80);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCSNTV, 0.0, 0.0);
@avg = @avg_chtrpzt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_condmxt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'condmxt';

pgsvp(0.1, 0.95, 0.45, 0.62);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCSNTV, 0.0, 0.0);
@avg = @avg_condmxt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_dcentrt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'dcentrt';

pgsvp(0.1, 0.95, 0.27, 0.44);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_dcentrt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_dtstatt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'dtstatt';

pgsvp(0.1, 0.95, 0.09, 0.26);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_dtstatt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");

$xmid = 0.5 * ($xmax + $xmin);
$ybot = $ymin - 0.3 * $diff;
pgptxt($xmid, $ybot, 0.0, 0.0, "Time (DOM)");

pgclos();

if($comp_test =~ /test/i){
	$out_plot = "$test_out/hrc_temp1.gif";
}else{
	$out_plot = '/data/mta_www/mta_hrc/Trending/Temp_data/hrc_temp1.gif';
}

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_plot");
system("rm -rf pgplot.ps");

#-----------------------------------------

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(4);

@temp = sort{$a<=>$b} @avg_fhtrmzt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'fhtrmzt';

pgsvp(0.1, 0.95, 0.81, 0.98);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_fhtrmzt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_fradpyt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'fradpyt';

pgsvp(0.1, 0.95, 0.63, 0.80);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_fradpyt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_pmt1t;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'pmt1t';

pgsvp(0.1, 0.95, 0.45, 0.62);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_pmt1t;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_pmt2t;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'pmt2t';

pgsvp(0.1, 0.95, 0.27, 0.44);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_pmt2t;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");



@temp = sort{$a<=>$b} @avg_uvlspxt;
$asum1 = 0; 
$asum2  = 0;
$tcnt = 0;
foreach $ent (@temp){
        $asum1 += $ent;
        $asum2  += $ent * $ent;
        $tcnt++;
}
$mean = $asum1/$tcnt;
$std  = sqrt($asum2/$tcnt - $mean * $mean);
$ymin = int($mean - 3.0 * $std);
$ymax = int($mean + 3.0 * $std);
$diff = $ymax - $ymin;
$yblw = $ymax - 0.12 * $diff;
$symbol = 1;
$text = 'uvlspxt';

pgsvp(0.1, 0.95, 0.09, 0.26);
pgswin($xmin, $xmax, $ymin, $ymax);
pgbox(ABCNST,0.0 , 0.0, ABCNSTV, 0.0, 0.0);
@avg = @avg_uvlspxt;
plot_fig();
pgptxt($xin, $yblw, 0.0, 0.0, "$text");

$xmid = 0.5 * ($xmax + $xmin);
$ybot = $ymin - 0.3 * $diff;
pgptxt($xmid, $ybot, 0.0, 0.0, "Time (DOM)");

pgclos();


if($comp_test =~ /test/i){
	$out_plot = "$test_out/hrc_temp2.gif";
}else{
	$out_plot = '/data/mta_www/mta_hrc/Trending/Temp_data/hrc_temp2.gif';
}

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps|pnmflip -r270 |ppmtogif > $out_plot");
system("rm -rf pgplot.ps");

open(OUT, '> /data/mta_www/mta_hrc/Trending/hrc_temp.html');


print OUT "<!DOCTYPE html>\n";
print OUT "<html>\n";
print OUT "<head>\n";
print OUT '<title>HRC Temperature</title>',"\n";
print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT "<style  type='text/css'>\n";
print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "a:link {color:blue;}\n";
print OUT "a:visited {color:teal;}\n";
print OUT "</style>\n";
print OUT "</head>\n";

print OUT "<body style='color:#000000;background-color:#FFFFFF'>\n";

print OUT '<div style="text-align:center;margin-left:auto;margin-right:auto">',"\n";
print OUT '<h2>Time History of HRC Temperature </h2>',"\n";
print OUT '</div>',"\n";
print OUT '',"\n";
print OUT '<p style="padding-bottom:20px">',"\n";
print OUT '',"\n";
print OUT '<img src ="./Temp_data/hrc_temp1.gif" alt="hrc temperature 1 plot" style="width:800px;height:800px">',"\n";
print OUT '<br />',"\n";
print OUT '<img src ="./Temp_data/hrc_temp2.gif" alt="hrc temperature 2 plot" style="width:800px;height:800px">',"\n";
print OUT '',"\n";
print OUT '</p>',"\n";
print OUT '',"\n";
print OUT "<hr />\n";
print OUT '<p style="padding-bottom:10px">',"\n";

if($month < 10){
	$month = '0'."$month";
}
if($umday < 10){
	$umday = '0'."$umday";
}

print OUT 'Last Update:',"$month/$umday/$year\n";
print OUT "</p>\n";
print OUT "</body>\n";
print OUT "</html>\n";

close(OUT);

#
#---- update the main hrc trending page
#

#open(FH, '/data/mta_www/mta_hrc/Trending/hrc_trend.html');
#open(OUT, '>./temp_out.html');
#
#$chk = 0;
#while(<FH>){
#        chomp $_;
#        if($_ =~ /Temperature Time Series Plots/ && $chk == 0){
#                print OUT '<li style="font-size:105%;font-weight:bold"><a href = "#temperature">Temperature Time Series Plots</a>';
#                print OUT " (last update: $month-$umday-$year)\n";
#                $chk++;
#        }else{
#                print OUT "$_\n";
#        }
#}
#close(OUT);
#close(FH);
#
#system("mv ./temp_out.html /data/mta_www/mta_hrc/Trending/hrc_trend.html");




##########################################################################
##########################################################################
##########################################################################

sub plot_fig{
	for($m = 0; $m < $dtot; $m++){
		pgpt(1, $day[$m], $avg[$m], $symbol);
	}
}
