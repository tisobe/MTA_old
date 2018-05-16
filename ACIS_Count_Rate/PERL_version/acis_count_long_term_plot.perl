#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	acis_doselong_term_plot.perl: plotting full range of count rate for s5, s6, 	#
#					and s7						#			
#											#
#											#
#	Author: Takashi Isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Apr 15, 2013  							#
#											#
#########################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

######################################################
#
#----- setting directories
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
######################################################
	
$start_date = '163';			# start from Jan 1, 2000
$interval   = '0.05';			# bin size

#
#--- find today's date in DOM
#
if($comp_test =~ /test/i){
    $uyday = 43;
    $uyear = 113;
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);	
}
$today = $uyday + ($uyear - 100) * 365 + 162;

$tdiff = int(0.25 * ($uyear + 3));
$today += $tdiff;

#
#---- plot setting 
#
pgbegin(0,"/ps",1,1);

pgsubp(1,3);
pgsch(2);
pgslw(4);


foreach $ccd ('ccd5', 'ccd6','ccd7') {
#
#--- find data file names
#

	system("ls $web_dir/*/$ccd > zlist");
	@file_list = ();
	open(FH, "./zlist");
	while(<FH>) {
		$file = chomp $_;
		push(@file_list,$_);
	}
	close(FH);
	system("rm zlist");
	
	@time_list  = ();
	@dose_count = ();
	$org_count  = 0;
	@all_data   = ();
#
#--- reading data for the entire period
#
	foreach $file (@file_list){
		open(IN, "$file");
		while(<IN>){
			chomp $_;
			push(@all_data, $_);
			$org_count++;
		}
		close(IN);
	}
#
#--- sort data by date
#
	@all_data = sort{$a<=>$b}@all_data;
	
	foreach $line (@all_data){
		@atemp = split(/\t/,$line);
		push(@time_list,  $atemp[0]);
		push(@dose_count, $atemp[1]);
	}
	
	$time_s    = $start_date;
	$time_e    = $time_s + $inverval;
	$i         = 0;
	$sum       = 0;
	$count     = 0;
	@bin_time  = ();
	@bin_data  = ();
	$bin_count = 0;
#
#--- binning starts here
#
	OUTER:
	while($time_e < $today && $i < $org_count){

		if($time_list[$i] < $time_s){
			$i++;
		}

		if($time_list[$i] >= $time_s && $time_list[$i] <$time_e) {
			$sum += $dose_count[$i];
			$count++;
			$i++;
		}

		if($time_list[$i] >= $time_e){
			$time_s = $time_e;
			$time_e = $time_s + $interval;
			if($count <= 0){
				next OUTER;
			}
			$avg  = $sum/$count/300;
			$time = 0.5 * ($time_s + $time_e);
			push(@bin_time, $time);
			push(@bin_data, $avg);
			$bin_count++;
			$sum   = 0;
			$count = 0;
		}
	}
#
#--- set plotting conditions
#
	$xmin     = $bin_time[2];		
	$xmax     = $bin_time[$bin_count - 1];
	@temp     = @bin_data;
	@temp     = sort{$a<=>$b} @temp;
	$ymin     = 0;
	$ymax     = $temp[$bin_count-2];
	@time     = @bin_time;
	@y_val    = @bin_data;
	$count    = $bin_count;
	$ccd_name = "$ccd";
#
#---- plotting sub
#
	plot_fig();
}

pgclos;

$output = "$web_dir/".'long_term_plot.gif';

system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $output");

system("rm pgplot.ps");

##################################
### plot_fig: plotting routine ###
##################################

sub plot_fig {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

        pgpt(1, $time[0], $y_val[0], -1);                # plot a point (x, y)
        for($im = 1; $im < $count-1; $im++) {
                unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
                        pgpt(1,$time[$im], $y_val[$im], -2);
                }
        }
        pglabel("Time (DOM)","counts/sec", "ACIS count rate: $ccd_name ");
                                                             # write labels

}

