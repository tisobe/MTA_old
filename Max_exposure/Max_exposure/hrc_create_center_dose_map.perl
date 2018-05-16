#!/usr/bin/perl

#########################################################################################
#											#
#	hrc_create_center_dose_map.perl: a master script to create center HRC dose map	#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Feb 02, 2012							#
#											#
#########################################################################################

#
#---- set directories
#

$temp_in = `cat ./dir_list`;
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

$usr  = `cat $dat_dir/.dare`;
$pass = `cat $dat_dir/.hakama`;
chomp $usr;
chomp $pass;

$chk = `ls -d`;
if($chk !~ /param/){
	system("mkdir param");
}

#
#--- get today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$year   = 1900   + $uyear;
$month  = $umon  + 1;

#
#--- find out the last month
#

if($umon == 0){
        $lmonth = 12;
        $lyear = $year -1;
}else{
        $lmonth = $umon;
        $lyear  = $year;
}

#
#--- two month ago
#

$tmonth = $lmonth -1;
$tyear  = $lyear;
if($tmonth < 1){
	$tmonth = 12;
	$tyear--;
}

#
#--- extract fits data from archive
#

system("perl $bin_dir/hrc_dose_get_data.perl $lyear $lmonth $lyear $lmonth $usr $pass");

system("mv ./Save/HRC*fits $mon_dir/");
system("gzip  $mon_dir/*fits");
system("rm -rf Save");

$dlmonth = $lmonth;
if($dlmonth < 10){
	$dlmonth = '0'."$dlmonth";
}
$dtmonth = $tmonth;
if($dtmonth < 10){
	$dtmonth = '0'."$dtmonth";
}

#
#--- create cumulative HRC dose maps
#

foreach $inst ('HRCI', 'HRCS'){
	$tname = "$cum_dir".'/'."$inst".'_08_1999_'."$dtmonth".'_'."$tyear".'.fits.gz';
	$name  = "$mon_dir".'/'."$inst".'_'."$dlmonth".'_'."$lyear".'.fits.gz';
	$out   = "$cum_dir".'/'."$inst".'_08_1999_'."$dlmonth".'_'."$lyear".'.fits';
	$test  = `ls $name`;
	chomp $test;
	if($test =~ /$name/){

		$line ="$name".'[opt type=i4,null=-99]';
		system("dmcopy infile=\"$line\"  outfile=temp3.fits clobber='yes'");

		system("dmimgcalc infile=$tname infile2=temp3.fits outfile=$out operation=add clobber=yes");
		system("gzip $out");
	}else{
		$out2 = "$out".'.gz';
		system("cp $tname $out2");
	}
}
system("rm file temp3.fits");

#
#--- compute statistics
#

system("perl $bin_dir/hrc_dose_extract_stat_data_month.perl $lyear $lmonth $cum_dir $mon_dir $data_out");

#
#--- plot statistics
#

system("/opt/local/bin/perl $bin_dir/hrc_dose_plot_exposure_stat.perl $data_out  $plot_dir");

#
#--- create data html page
#

system("perl $bin_dir/hrc_dose_make_data_html.perl $data_out");

#
#--- create png images from fits data
#

system("perl $bin_dir/hrc_dose_conv_to_png.perl $mon_dir $img_dir $lyear $lmonth");
system("perl $bin_dir/hrc_dose_conv_to_png.perl $cum_dir $img_dir $lyear $lmonth");

system("rm file input_line out.fits pgplot.ps");
