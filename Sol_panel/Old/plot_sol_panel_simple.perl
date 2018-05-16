#!/usr/bin/perl
use PGPLOT;

#
#---- plotting solar panel data
#


$file1 = $ARGV[0];	#solar_panel.dat
$file2 = $ARGV[1];

@tmysada = ();
@tpysada = ();
@tsamyt  = ();
@tsapyt  = ();
@time1   = ();
$cnt1    = 0;

open(FH, "$file1");
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[1] !~ /\d/){
		next OUTER;
	}
	push(@tmysada, $atemp[2]);
	push(@tpysada, $atemp[3]);
	push(@tsamyt,  $atemp[4]);
	push(@tsapyt,  $atemp[5]);
	push(@time1,   $atemp[6]);
	$cnt1++;
}
close(FH);

@angle = ();
@time2 = ();
$cnt2  = 0;

open(FH, "$file2");
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[1] !~ /\d/){
		next OUTER;
	}
	push(@angle, $atemp[2]);
	push(@time2, $atemp[3]);
	$cnt2++;
}
close(FH);

$total  = $cnt1;
@xbin   = @angle;
$x_axis = 'Sun Angle';

@ybin   = @tmysada;
$y_axis = 'tmysada';
$out_gif= 'tmysada.gif';
simple_plot();

@ybin   = @tpysada;
$y_axis = 'tpysada';
$out_gif= 'tpysada.gif';
simple_plot();

@ybin   = @tsamyt;
$y_axis = 'tsamyt';
$out_gif= 'tsamyt.gif';
simple_plot();

@ybin   = @tsapyt;
$y_axis = 'tsapyt';
$out_gif= 'tsapyt.gif';
simple_plot();

############################################################################
############################################################################
############################################################################

sub simple_plot{

	@temp  = sort{$a<=>$b} @xbin;
	$xmin  = $temp[0];
	$xmax  = $temp[$cnt1 - 1];
	$xdiff = $xmax - $xmin;
	$xmin -= 0.1 * $xdiff;
	if($xmin < 0){
		$xmin = 0;
	}
	$xmax += 0.1 * $xdiff;

	$xmin = 40;
	$xmax = 180;
	
	@temp  = sort{$a<=>$b} @ybin;
	$ymin  = $temp[0];
	$ymax  = $temp[$cnt1 - 1];
	$ydiff = $ymax - $ymin;
	$ymin -= 0.1 * $ydiff;
	if($ymin < 0){
		$ymin = 0;
	}
	$ymax += 0.1 * $ydiff;
	
	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,1);
	pgsch(1);
	pgslw(4);
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
	for($m = 0; $m < $total; $m++){
		pgpt(1,$xbin[$m], $ybin[$m], $symbol);
	}
	
	pglabel("$x_axis", "$y_axis", "$title");
	pgclos();
	
	system("echo ''|gs -sDEVICE=ppmraw  -r64x64 -q -NOPAUSE -sOutputFile=- ./pgplot.ps|pnmcrop| pnmflip -r270 |ppmtogif > $out_gif");

	system("rm pgplot.ps");
}




