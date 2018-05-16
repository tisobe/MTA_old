#!/usr/bin/perl 

#########################################################################################################
#													#
#	compute_ephin_avg.perl: compute statistics of given ephin data set				#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: Jun 14, 2011								#
#													#
#########################################################################################################

$file = $ARGV[0];
open(FH, "$file");
$input = <FH>;
close(FH);
chomp $input;
@atemp = split(/\s+/, $input);

$name = $atemp[0];	#--- name of the event
$beg  = $atemp[1];	#--- begining of the interruption

#
#-- convert into ydate
#

@atemp = split(/:/, $beg);
$start = find_ydate($atemp[0], $atemp[1], $atemp[2]) + $atemp[3]/24 + $atemp[4]/1440;

#
#--- read ephin data
#

$file = '/data/mta_www/mta_interrupt/Data_dir/'."$name".'_eph.txt';

open(FH, "$file");

$p4sum1    = 0;
$p4sum2    = 0;
$p4min     = 1.e14;
$p4max     = 1.e-14;
$p4int     = -999;

$p41sum1   = 0;
$p41sum2   = 0;
$p41min    = 1.e14;
$p41max    = 1.e-14;
$p41int    = -999;

$e1300sum1 = 0;
$e1300sum2 = 0;
$e1300min  = 1.e14;
$e1300max  = 1.e-14;
$e1300int  = -999;
 
$chk       = 0;
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] !~ /\d/){
		next OUTER;
	}
#
#--- convert back to noraml format
#

	$p4    = 2.302585093 * exp($atemp[1]);
	$p41   = 2.302585093 * exp($atemp[2]);
	$e1300 = 2.302585093 * exp($atemp[3]);

	if($chk == 0 && $atemp[0] >= $start){
		$chk      = 1;
		$p4int    = $p4;
		$p41int   = $p41;
		$e1300int = $e1300;
	}

	$tot++;
		
#
#---p4
#
	if($p4 < $p4min){
		$p4min  = $p4;
		$p4mint = $atemp[0];	
	}
	if($p4 > $p4max){
		$p4max  = $p4;
		$p4maxt = $atemp[0];	
	}

	$p4sum1  += $p4;
	$p4sum2  += $p4 * $p4;
		
#
#---p41
#
	if($p41 < $p41min){
		$p41min  = $p41;
		$p41mint = $atemp[0];	
	}
	if($p41 > $p41max){
		$p41max  = $p41;
		$p41maxt = $atemp[0];	
	}

	$p41sum1  += $p41;
	$p41sum2  += $p41 * $p41;
		
#
#---e1300
#
	if($e1300 < $e1300min){
		$e1300min  = $e1300;
		$e1300mint = $atemp[0];	
	}
	if($e1300 > $e1300max){
		$e1300max  = $e1300;
		$e1300maxt = $atemp[0];	
	}

	$e1300sum1  += $e1300;
	$e1300sum2  += $e1300 * $e1300;
}
close(FH);

#
#-- take avg and sigma
#

$p4avg = $p4sum1/$tot;
$p4sig = sqrt(abs($p4sum2/$tot - $p4avg * $p4avg));

$p41avg = $p41sum1/$tot;
$p41sig = sqrt(abs($p41sum2/$tot - $p41avg * $p41avg));

$e1300avg = $e1300sum1/$tot;
$e1300sig = sqrt(abs($e1300sum2/$tot - $e1300avg * $e1300avg));




$out = '/data/mta_www/mta_interrupt/Ephin_plot/'."$name".'_txt';
open(OUT, ">$out");
print OUT "\t\tAvg\t\t\t\tMax\t\t\tTime\t\t\Min\t\t\tTime\tValue at Interruption Started\n";
print OUT "--------------------------------------------------------------------------------------------------------------------------\n";

printf OUT "p4\t\t%2.3e+/-%2.3e\t\t%2.3e\t\t%2.3f\t\t%2.3e\t\t%2.3f\t\t%2.3e\n",    $p4avg,$p4sig,$p4max,$p4maxt,$p4min,$p4mint,$p4int;
printf OUT "p41\t\t%2.3e+/-%2.3e\t\t%2.3e\t\t%2.3f\t\t%2.3e\t\t%2.3f\t\t%2.3e\n",   $p41avg,$p41sig,$p41max,$p41maxt,$p41min,$p41mint,$p41int;
printf OUT "e1300\t\t%2.3e+/-%2.3e\t\t%2.3e\t\t%2.3f\t\t%2.3e\t\t%2.3f\t\t%2.3e\n", $e1300avg,$e1300sig,$e1300max,$e1300maxt,$e1300min,$e1300mint,$e1300int;
close(OUT);


##################################################
### find_ydate: change month/day to y-date     ###
##################################################

sub find_ydate {

##################################################
#       Input   $tyear: year
#               $tmonth: month
#               $tday:   day of the month
#
#       Output  $ydate: day from Jan 1<--- returned
##################################################

        my($tyear, $tmonth, $tday, $ydate, $chk);
        ($tyear, $tmonth, $tday) = @_;

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
        $chk = 4 * int (0.25 * $tyear);
        if($chk == $tyear && $tmonth > 2){
                $ydate++;
        }
        return $ydate;
}

