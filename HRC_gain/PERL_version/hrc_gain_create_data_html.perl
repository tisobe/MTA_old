#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	hrc_create_data_html.perl: create a html page version of fitting results	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Apr 17, 2013						#
#											#
#########################################################################################

#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
$year = $uyear + 1900;
$month = $umon + 1;
$today = "$year:$uyday:00:00:00";

if($month < 10){
        $month = '0'."$month";
}
if($umday < 10){
        $umday = '0'."$umday";
}


##########################################################################
#
#----- reading directory locations
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
	open(OUT, ">$test_web_dir/pha_data_list.html");
}else{
	$file = "$hosue_keeping/fitting_results";
	open(OUT, ">$web_dir/pha_data_list.html");
}

print OUT "<!DOCTYPE html>\n";
print OUT "<html>\n";
print OUT "<head>\n";
print OUT '<title> HRC PHA Evolution Data</title>',"\n";
print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT "<style  type='text/css'>\n";
print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "a:link {color:yellow;}\n";
print OUT "a:visited {color:#FF0000;}\n";
print OUT "</style>\n";
print OUT "</head>\n";

print OUT "<body style='color:#FFFFFF;background-color:#000000'>\n";

print OUT '<h2 style="text-align:center;margin-left:auto;margin-right:auto">HRC PHA Evolution Data</h2>',"\n";


print OUT '<table border=1>',"\n";
print OUT '<tr>',"\n";
print OUT '<th>OBSID</th>',"\n";
print OUT '<th>Date</th>',"\n";
print OUT '<th>Instrument</th>',"\n";
print OUT '<th>Pointing RA</th>',"\n";
print OUT '<th>Pointing DEC</th>',"\n";
print OUT '<th>Diff in RA</th>',"\n";
print OUT '<th>Diff in DEC</th>',"\n";
print OUT '<th>Rad Distance</th>',"\n";
print OUT '<th>Median</th>',"\n";
print OUT '<th>Peak Position</th>',"\n";
print OUT '<th>Peak Counts</th>',"\n";
print OUT '<th>Peak Width</th>',"\n";
print OUT '</tr>',"\n";

open(FH, "$file");
while(<FH>){
	chomp $_;
	@col = split(/\t/, $_);
	print OUT '<tr>',"\n";
	print OUT "<td>$col[0]</td>\n";
	print OUT "<td>$col[1]</td>\n";
	print OUT "<td>$col[2]</td>\n";
	print OUT "<td>$col[3]</td>\n";
	print OUT "<td>$col[4]</td>\n";
	print OUT "<td>$col[5]</td>\n";
	print OUT "<td>$col[6]</td>\n";
	print OUT "<td>$col[7]</td>\n";
	print OUT "<td>$col[8]</td>\n";
	print OUT "<td>$col[9]</td>\n";
	print OUT "<td>$col[10]</td>\n";
	print OUT "<td>$col[11]</td>\n";
	print OUT '</tr>',"\n";
}
close(FH);

print OUT '</table>',"\n";

print OUT "<div style='padding-top:20px;padding-bottom:10px'>\n";
print OUT '<hr />',"\n";
print OUT "</div>\n";
print OUT 'Last Update:',"$month/$umday/$year\n";
print OUT "</body>\n";
print OUT "</html>\n";

close(OUT);

$line =  'Last Update:'."$month/$umday/$year";

foreach $file ('hrc_i_pha_radial.html', 'hrc_i_pha_time.html', 'hrc_s_pha_radial.html', 'hrc_s_pha_time.html'){
	open(FH, "$web_dir/../$file");
	@save_line = ();
	while(<FH>){
		chomp $_;
		if($_ !~ /Last Update:/){
			push(@save_line, $_);
		}else{
			push(@save_line, $line);
		}
	}
	close(FH);
	
	open(OUT, ">$web_dir/../$file");
	foreach $ent (@save_line){
		print OUT "$ent\n";
	}
	close(OUT);
}

#
#---- update the main hrc trending page
#

open(FH, '/data/mta_www/mta_hrc/Trending/hrc_trend.html');
open(OUT, '>./temp_out.html');

$chk = 0;
while(<FH>){
	chomp $_;
	if($_ =~ /QE and Gain Variation with Time/ && $chk == 0){
		print OUT '<li  style="font-size:105%;font-weight:bold"><a href = "#qe_gain">QE and Gain Variation with Time (HRC PHA Evolution)</a>';
		print OUT " (last update: $month-$umday-$year)\n";
		$chk++;
	}else{
		print OUT "$_\n";
	}
}
close(OUT);
close(FH);

if($comp_test =~ /test/i){
	system("mv ./temp_out.html $test_web_dir/hrc_trend.html");
}else{
	system("mv ./temp_out.html $web_dir/../hrc_trend.html");
}
