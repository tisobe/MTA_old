#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################################
#												#
#	 plot_col_history.perl: plot warm column history					#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Apr 15, 2013							#
#												#
#################################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

@dir_list = ();

#--- output directory

if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#-------------------------------------------

for($ccd = 0; $ccd < 10; $ccd++){

	pgbegin(0, '"./pgplot.ps"/cps',1,1);
	pgsubp(1,3);
	pgsch(2);
	pgslw(4);

#
#---- warm column counts
#

	$file = "$data_dir".'/Disp_dir/col'."$ccd".'_cnt';
	open(FH, "$file");
	@x    = ();
	@y    = ();
	$tot  = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/, $_);
		push(@x, $atemp[0]);

		@btemp = split(/:/, $atemp[2]);
		push(@y, $btemp[1]);
		$tot++;
	}
	close(FH);

	@temp = sort{$a<=>$b} @x;
	$xmin = 0;
	$xmax = 1.1 * $temp[$tot -1];

	@temp = sort{$a<=>$b} @y;
	$med  = $temp[$tot/2];
	$max  = $temp[int(0.98 * $tot)];
	$min  = $temp[int(0.02 * $tot)];
	if($min - 5 < 0){
		$ymin = 0;
	}else{
		$ymin = $min;
	}
	$diff = $temp[$tot-1] - $max;
	if($diff > 10){
		$ymax = int(1.4 * $max) + 3;
	}else{ 
		$ymax = int(1.1 * $temp[$tot-1]) + 1;
	}

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

	pgmove($x[0], $y[0]);
	for($i = 1; $i < $tot; $i++){
		pgdraw($x[$i], $y[$i]);
	}

	pglabel("Time (DOM)", "Counts", "Numbers of Warm Columns: CCD $ccd");

#
#----- potentintial bad pixel counts
#

	$file = "$data_dir".'/Disp_dir/bad_col'."$ccd".'_cnt';
	open(FH, "$file");
	@x   = ();
	@y   = ();
	$tot = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/, $_);
		push(@x, $atemp[0]);
		$atemp[2] =~ s/\://g;
		push(@y, $atemp[2]);
		$tot++;
	}
	close(FH);

	@temp = sort{$a<=>$b} @x;
	$xmin = 0;
	$xmax = 1.1 * $temp[$tot -1];

	@temp = sort{$a<=>$b} @y;
	$med  = $temp[$tot/2];
	$max  = $temp[int(0.98 * $tot)];
	$min  = $temp[int(0.02 * $tot)];
	if($min - 5 < 0){
		$ymin = 0;
	}else{
		$ymin = $min;
	}
	$diff = $temp[$tot-1] - $max;
	if($diff > 10){
		$ymax = int(1.4 * $max) + 3;
	}else{ 
		$ymax = int(1.1 * $temp[$tot-1]) + 1;
	}

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

	pgmove($x[0], $y[0]);
	for($i = 1; $i < $tot; $i++){
		pgdraw($x[$i], $y[$i]);
	}

	$title = "Numbers of Potential Warm Columns (Warm Columns + Flickering Columns)";
	$title = "$title".": CCD $ccd";
	pglabel("Time (DOM)", "Counts", "$title");

#
#----- cumulative warm pixel counts
#

	$file = "$data_dir".'/Disp_dir/cum_col'."$ccd".'_cnt';
	open(FH, "$file");
	@x   = ();
	@y   = ();
	$tot = 0;
	while(<FH>){
		chomp $_;
		@atemp = split(/<>/, $_);
		push(@x, $atemp[0]);
		@btemp = split(/:/, $atemp[2]);
		push(@y, $btemp[1]);
		$tot++;
	}
	close(FH);

	@temp = sort{$a<=>$b} @x;
	$xmin = 0;
	$xmax = 1.1 * $temp[$tot -1];

	@temp = sort{$a<=>$b} @y;
	$med  = $temp[$tot/2];
	$max  = $temp[int(0.98 * $tot)];
	$diff = 1.1 * $max - $med;
	if($diff > 20){
		$diff = 20;
	}
	$min  = $med - $diff;
	if($min < 0){
		$ymin = 0;
	}else{
		$ymin = $min;
	}
	$ymin = 0;
	
	$ymax = $med + $diff;
	$chk  = $ymax - $temp[$tot -1];
	if($chk < 0){
		$ymax = int(1.1 * $temp[$tot-1]) + 1;
	}elsif($chk > 10){
		$ymax = $temp[$tot -1] + 10;
	}

	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

	pgmove($x[0], $y[0]);
	for($i = 1; $i < $tot; $i++){
		pgdraw($x[$i], $y[$i]);
	}

	$title = "Cumulative Numbers of Columns Which Were Warm Columns during the Mission: CCD $ccd";
	pglabel("Time (DOM)", "Counts", "$title");

	pgclos();
	
	$out_gif = 'hist_plot_col'."$ccd".'.gif';

	system("echo ''|gs -sDEVICE=ppmraw  -r128x128 -q -NOPAUSE -sOutputFile=-  ./pgplot.ps| pnmflip -r270 | ppmtogif > $out_gif");
	system("rm -rf  pgplot.ps");

}
		
