#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
#  alignment_sim_twist_update_html.perl: update sim twist html pages	#
#									#
#	author: t. isobe (tisobe@cfa.harvard.edu)			#
#									#
#	last update: apr 16, 2013					#
#									#
#########################################################################
#
#---- html 5 conformed (Oct 17, 2012)
#

#
#--- is this test?
#

$comp_test = $ARGV[0];
chomp $comp_test;

############################################################
#---- set directries
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

############################################################

#
#--- if this is a test case, clen up the test directory
#
$cdir  = $test_dir;
$cdir  =~ s/Test_out\///;
$input = `ls $cdir`;
$chk   = 0;
@list  = split(/\//, $input);
OUTER:
foreach $ent (@list){
    if($ent eq /Test_out/){
        $chk = 1;
        last OUTER;
    }
}

if($chk > 0){
    system("rm -rf $test_dir/*");
    system("mkdir $test_dir/Data $test_dir/mta_sim_twist");
    system("mkdir $test_dir/Data $test_dir/mta_sim_twist/Html_dir");
    system("mkdir $test_dir/Data $test_dir/mta_sim_twist/Plots");
}else{
#    system("mkdir $test_dir");
#    system("mkdir $test_dir/Data $test_dir/mta_sim_twist");
#    system("mkdir $test_dir/Data $test_dir/mta_sim_twist/Html_dir");
#    system("mkdir $test_dir/Data $test_dir/mta_sim_twist/Plots");
}

#
#----  update the html page
#
if($comp_test =~ /test/i){
	$line = `cat $house_keeping/test_data_interval`;
	@atemp = split(/\s+|\t+/, $line);
	@ctemp = split(/\,/, $atemp[1]);
	@btemp = split(/\//, $ctemp[0]);
	$year  = $btemp[0];
	$month = $btemp[1];
	$ymday = $btemp[2];
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

	$year  = 1900   + $uyear;
	$month = $umon  + 1;
}

$date_line = "Last Update: $month/$umday/$year";

$lyear     = $year -1;
$last_year = 'sim_twist_'."$lyear".'.html';
$this_year = 'sim_twist_'."$year".'.html';

$check = `ls $web_dir/*html`;
if($check !~ /$this_year/){
	open(FH,  "$web_dir/$last_year");
	open(OUT, ">$web_dir/$this_year");
	while(<FH>){
		chomp $_;
		$line = $_;
		$line =~ s/$lyear/$year/g;
		print OUT "$line\n";
	}
	close(OUT);
	close(FH);
	for($qtr = 0; $qtr < 4; $qtr++){
		$file1 = 'twist_plot_'."$this_year".'_'."$qtr".'.gif';
		$file2 = 'dtheta_plot_'."$this_year".'_'."$qtr".'.gif';
		system("cp $bdata_dir/no_data.gif $web_dir/Plots/$file1");
		system("cp $bdata_dir/no_data.gif $web_dir/Plots/$file2");
	}
	$lchk = "year: $lyear";
	@save = ();
	open(FH, "$web_dir/sim_twist.html");
	while(<FH>){
		chomp $_;
		if($_ =~ /$lchk/){
			push(@save, $_);
			$line = "<a href='./sim_twist_"."$year".".html'> Plots for year: "."$year"."</a><br>";
			push(@save, $line);
		}else{
			push(@save, $_);
		}
	}
	close(FH);

	open(OUT, ">$web_dir/sim_twist.html");
	foreach $ent (@save){
		print OUT "$ent\n";
	}
	close(OUT);
}
	
#
#--- update sim html page
#

print_sim_page();

#
#--- update the reneal date
#

open(FH, "$house_keeping/fid_light_drift.html");
@save = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		push(@save, $date_line);
	}else{
		push(@save, $_);
	}
}
close(FH);

open(OUT, ">$web_dir/fid_light_drift.html");
foreach $ent (@save){
	print OUT "$ent\n";
}
close(OUT);


#open(FH, "$web_dir/sim_twist.html");
#@save = ();
#while(<FH>){
#	chomp $_;
#	if($_ =~ /Last Update/){
#		push(@save, $date_line);
#	}else{
#		push(@save, $_);
#	}
#}
#close(FH);
#
#open(OUT, ">$web_dir/sim_twist.html");
#foreach $ent (@save){
#	print OUT "$ent\n";
#}
#close(OUT);


########################################################################
########################################################################
########################################################################


sub print_sim_page{
	open(OUT, ">$web_dir/sim_twist.html");
	print OUT "<!DOCTYPE html>\n";
	print OUT "<html> \n";
	print OUT "<head> \n";
	print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
	print OUT " \n";
	print OUT "<link rel=\"stylesheet\" type=\"text/css\" href=\"http://asc.harvard.edu/mta/REPORTS/Template/mta.css\" /> \n";
	print OUT " \n";
        print OUT "<style  type='text/css'>\n";
        print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
        print OUT "td{text-align:center;padding:8px}\n";
        print OUT "a:link {color:#00CCFF;}\n";
        print OUT "a:visited {color:yellow;}\n";
        print OUT "span.nobr {white-space:nowrap;}\n";
        print OUT "</style>\n";

	print OUT "<title>SIM Shift and Twist Trends </title> \n";
	print OUT " \n";
	print OUT "<script> \n";
	print OUT "        function MyWindowOpener(imgname) { \n";
	print OUT "                msgWindow=open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=900,height=700,resize=yes\"); \n";
	print OUT "                msgWindow.document.close(); \n";
	print OUT "                msgWindow.document.write(\"<html><head><title>CTI plot:   \"+imgname+\"</title></head>\"); \n";
	print OUT "                msgWindow.document.write(\"<body sytle='background-color:white'>\"); \n";
	print OUT "                msgWindow.document.write(\"<img src='/mta_days/mta_cti/\"+imgname+\"' style='width:700px;height:700px'></body></html>\"); \n";
	print OUT "                msgWindow.focus(); \n";
	print OUT "        } \n";
	print OUT "</script> \n";
	print OUT "</head> \n";
	print OUT "<body> \n";


	print OUT '<h2>SIM Shift and Twist Trends</h2>',"\n";
	print OUT '<p>',"\n";
	print OUT 'This page shows trends of SIM shifts (dy and dz) and twist (dtheta). All quantities are directly taken from',"\n";
	print OUT 'pcaf*_asol1.fits files. The units are mm for dy and dz, and second  for dtheta.',"\n";
	print OUT 'We fit three lines separated before (Days of Mission)= 1400 (May 21, 2003),',"\n";
	print OUT 'between 1400 and 2700 (Dec 11, 2006),  between 2700 and 4400 (*****), and after 4400.',"\n";
	print OUT 'The unit of slopes are mm per day or second per day.',"\n";
	print OUT "</p>,\n";
	print OUT "<p style='padding-bottom:30px'> \n";
	print OUT ' These sudden shifts were due to fid light drift',"\n";
	print OUT ' (see a memo by Aldocroft<a href=',"\n";
	print OUT '"http://cxc.harvard.edu/mta/ASPECT/fid_drift/"> fiducial light drfit</a>).',"\n";
	print OUT '</p>',"\n";
	print OUT "<p style='padding-bottom:30px'> \n";
	print OUT "<img src='./Plots/twist_plot.gif' alt='twist plot' style='width:600px;height:600px'>","\n";
	print OUT '</p>',"\n";
	print OUT "<p style='padding-bottom:30px'> \n";
	print OUT 'For dtheta, data are further devided into smaller groups according to which instrument was used (',"\n";
	print OUT "ACIS-I, ACIS-S, HRC-I, and HRC-S). \n";
	print OUT "</p> \n";

	print OUT "<p style='padding-bottom:30px'> \n";
	print OUT "<img src='./Plots/dtheta_plot.gif' alt='thera plot'  style='width:600px;height:600px'>","\n";
	print OUT "</p> \n";


	print OUT "<p style='padding-bottom:20px'> \n";
	print OUT "For the indivisual year, please open one of the following links. \n";
	print OUT 'The entires of the data tables are time in seconds from',"\n";
 	print OUT 'Jan 1, 1998, dy, dz, and dtheta. All entires are 5 min avaerage.',"\n";

	print OUT "<table style='border-width:0px'> \n";
	print OUT "<tr><th>Year</th><th>Plot</th><th>Data</th></tr> \n";
	for($iyr = 1999; $iyr <= $year; $iyr++){
		$plot_name = './sim_twist_'."$iyr".'.html';
		$data_name = './Data/data_extracted_'."$iyr";

		print OUT "<tr><th>$iyr</th><td><a href='$plot_name' target='_blank'>Plot</a></td><td><a href='$data_name' target='_blank'>Data</a></td></tr> \n";
	}
	print OUT "</table> \n";


	print OUT "<hr /> \n";

	print OUT "<h3> SIM X, Y, Z, and  Pitch and Yaw Amps of Dithers</h3> \n";

	print OUT "<p style='padding-top:30px;padding-bottom:30px'> \n";

	print OUT "<img src='./Plots/sim_plot.gif' alt='sim plot'  style='width:600px;height:600px'>","\n";
	print OUT "</p>\n";

	print OUT "<p style='padding-bottom:30px'> \n";
	print OUT 'Followings are ASCII data tables for the data plotted above. The entries are Fits file name,',"\n";
 	print OUT "tstart, tstop, sim_x, sim_y, sim_z, pitchamp, and yawamp. \n";
	print OUT "</p> \n";

	print OUT "<p style='padding-bottom:30px'> \n";
	for($iyr = 1999; $iyr <= $year; $iyr++){
		print OUT "<a href='./Data/data_info_$iyr";
		print OUT "'> ASCII Data for year:  $iyr";
		print OUT "</a><br />","\n";
	}
	print OUT "</p> \n";
	print OUT "<hr /> \n";

	print OUT "<p style='padding-bottom:5px'><em> \n";
	print OUT "If you have any questions about this page, please contact <a href='mailto:swolk\@head.cfa.harvard.edu'>swolk\@head.cfa.harvard.edu</a>. \n";
	print OUT "</em></p> \n";

	print OUT "<p>\n";
	print OUT "$date_line\n";
	print OUT "</p> \n";
	print OUT '</body>',"\n";
	print OUT '</html>',"\n";

	close(OUT);
}

