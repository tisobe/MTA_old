#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


$file_name = $ARGV[0];
$title     = $ARGV[1];
$ymax      = $ARGV[2];
chomp $file_name;
chomp $title;
chomp $ymax;

@date = ();
@pix  = ();
$tot  = 0;

open(FH, "$file_name");
while(<FH>){
	chomp $_;
	@atemp = split(/<>:/, $_);
	@btemp = split(/<>/,  $atemp[0]);
	@ctemp = split(/:/,   $atemp[1]);
	$cnt   = 0; 
	foreach (@ctemp){
		$cnt++;
	}
	push(@date, $btemp[0]);
	push(@pix,  $cnt);
	$tot++;
}
close(FH);

@temp = sort{$a<=>$b} @date;
$xmin = 0;
$xmax = $temp[$tot -1] + 20;
$xdiff = $xmax;

@temp = sort{$a<=>$b} @pix;
$ymin = 0;
if($ymax eq ''){
	$ymax = int(1.05 *  $temp[$tot -1]) + 1;
}

pgbegin(0, '"./pgplot.ps"/cps',1,1);
pgsubp(1,1);
pgsch(1);
pgslw(4);
pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

pgmove($date[0], $pix[0]);
for($i = 1; $i < $tot; $i++){
	pgdraw($date[$i], $pix[$i]);
}

pglabel('Time (DOM)', 'Count', "$title");
pgclos();

$out_gif = 'ccd_plot.gif';

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 |ppmtogif > $out_gif");




