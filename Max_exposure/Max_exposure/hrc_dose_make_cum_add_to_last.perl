#!/usr/bin/perl

#################################################################################################
#												#
#	hrc_dose_make_cum_add_to_last.perl: make cumulative hrc dose map for the month given	#
#				 		 to the given date				#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Aug 22, 2005							#
#												#
#################################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list2`;
@dir_list = split(/\s+/, $temp_in);

$chk = 0;
foreach (@dir_list){
        $chk++;
}
if($chk == 0){
        print "dir_list is not set\n";
        exit 1;
}

$bin_dir  = $dir_list[0];
$dat_dir  = $dir_list[1];
$mon_dir  = $dir_list[2];
$cum_dir  = $dir_list[3];
$data_out = $dir_list[4];
$plot_dir = $dir_list[5];
$img_dir  = $dir_list[6];
$web_dir  = $dir_list[7];

$in_dir  = $ARGV[0];	#----- directory contains hrc maps for each month
$cum_dir = $ARGV[1];	#----- directory contains hrc cumultavie data
$tyear   = $ARGV[2];	#----- the year ending the accumulation
$tmonth  = $ARGV[3];	#----- the month ending the accumulation
chomp $in_dir;
chomp $cum_dir;
chomp $tyear;
chomp $tmonth;

$lmonth = $tmonth -1;
if ($lmonth < 1){
	$lmonth = 12;
	$lyear = $tyear -1;
}else{
	$lyear = $tyear;
}
if($tmonth < 10 && $tmonth !~ /^0/){
	$tmonth = '0'."$tmonth";
}
if($lmonth < 10 && $lmonth !~ /^0/){
	$lmonth = '0'."$lmonth";
}


foreach $inst ('HRCI', 'HRCS'){
	OUTER:
	for($m = 0; $m < 10; $m++){			#----section indicator
		if($m == 9 && $inst eq 'HRCI'){
			next OUTER;
		}
		$lname = "$cum_dir".'/'."$inst".'_09_1999_'."$lmonth".'_'."$lyear".'_'."$m".'.fits.gz';
		$name  = "$in_dir".'/'."$inst".'_'."$tmonth".'_'."$tyear".'_'."$m".'.fits.gz';
		$out   = "$cum_dir".'/'."$inst".'_09_1999_'."$tmonth".'_'."$tyear".'_'."$m".'.fits';

		$test = `ls $name`;
		chomp $test;
		if($test =~ /$inst/){

			$line = "$name".'[opt type=i4,null=-99]';
			system("dmcopy infile=\"$line\"  outfile=temp3.fits clobber=yes");

			system("dmimgcalc infile=$lname infile2=temp3.fits outfile=./zout.fits operation=add clobber=yes");
			system("mv ./zout.fits $out");
			system("gzip $out");
		}else{
			$out2 = "$out".'.gz';
			system("cp $lname $out2");
		}
	}
}
