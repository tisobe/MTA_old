#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	gyro_drift_create_fig_html.perl: create html pages for grating 			#
#						insertion/retraction plots		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update:	Ju  05, 2013							#
#											#
# 	usage: perl  gyro_drift_create_fig_html.perl HETG INSR				#
#											#
#########################################################################################
#
#--- html 5 conformed (Oct 15, 2012)
#
#
#--- check whether this is a test case
#
OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

#
#---- read directories
#
if($comp_test =~ /test/i){
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list_test");
}else{
	open(FH, "/data/mta/Script/Grating/Gyro/house_keeping/dir_list");
}
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#
#--- find today's date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst) = localtime(time);
$uyear += 1900;
$month = $umon + 1;

if($month < 10){
	$month = '0'."$month";
}
if($umday < 10){
	$umday = '0'."$umday";
}

$grating = $ARGV[0];		# grating name: HETG or LETG
$move    = $ARGV[1];		# grating move: INSR or RETR
chomp $grating;
chomp $move;

$ugrat   = uc($grating);
$umove   = uc($move);
$lgrat   = lc($grating);
$lmove   = lc($move);

$dir_name = "$web_dir".'/'."$ugrat".'_'."$umove".'/';
$gif_name = "$dir_name".'*.gif';
$in_list  = `ls $gif_name`;
@list     = split(/\s+/, $in_list);

$title1   = "$ugrat";
if($lmove eq 'insr'){
	$title2 = 'Insertion';
}else{
	$title2 = 'Retraction';
}

$name      = "$lgrat".'_'."$lmove";
$data_file =  uc($name);
$main_html = "$name".'.html';

open(FH, "$data_file");
@dyear  = ();
@dydate = ();
@pt_bf  = ();
@pt_md  = ();
@pt_af  = ();
@rl_bf  = ();
@rl_md  = ();
@rl_af  = ();
@yw_bf  = ();
@yw_md  = ();
@yw_af  = ();
$dcnt    = 0;
while(<FH>){
	chomp $_;
	@btemp = split(/\s+/, $_);
	push(@dyear,  $btemp[0]);
	push(@dydate, $btemp[1]);
	push(@pt_bf,  $btemp[2]);
	push(@pt_md,  $btemp[3]);
	push(@pt_af,  $btemp[4]);
	push(@rl_bf,  $btemp[5]);
	push(@rl_md,  $btemp[6]);
	push(@rl_af,  $btemp[7]);
	push(@yw_bf,  $btemp[8]);
	push(@yw_md,  $btemp[9]);
	push(@yw_af,  $btemp[10]);
	$dcnt++;
}
close(FH);

open(OUT2, ">$web_dir/$main_html");

print OUT2 "<!DOCTYPE html>\n";
print OUT2 '<html>',"\n";
print OUT2 "<head>\n";
print OUT2 "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT2 '<link rel="stylesheet" type="text/css" href="https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css" />',"\n";

print OUT2 "<style  type='text/css'>\n";
print OUT2 "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT2 "td{text-align:center;padding:8px}\n";
print OUT2 "a:link {color:#00CCFF;}\n";
print OUT2 "a:visited {color:yellow;}\n";
print OUT2 "span.nobr {white-space:nowrap;}\n";
print OUT2 "</style>\n";

print OUT2 '<title>',"$name ",' </title></head>',"\n";

print OUT2 '<body>',"\n";

print OUT2 '<h2>',"$title1 $title2",'</h2>',"\n";
print OUT2 '<br />',"\n",'<p>',"\n";
print OUT2 'The table below shows a plot of gyro drift rate, means and their standard deviations, ',"\n";
print OUT2 'ratios of standard deviations of Before/During, After/During, and Before/After ', "\n";
print OUT2 'around ',"$title1 $title2 ",'. To see the plot, click the "Plot" on the table, ',"\n";
print OUT2 'which opens up a new html page  with six plots on the page.',"\n";
print OUT2 '</p><p>',"\n";
print OUT2 'The plots on left panels are gyro drift rates of roll, pitch, and yaw around ',"\n";
print OUT2 "$title2",'. The red lines indicate the start time and the end time of the grating',"\n";
print OUT2 'movement. The green line fitted are 5th degree of polynomial line around the ',"\n";
print OUT2 'grating movement. The difference between the fitted line and the actual data points ',"\n";
print OUT2 'are plotted on the right side panels.',"\n";
print OUT2 '</p><br />',"\n";
print OUT2 '<table border=1>',"\n";
print OUT2 '<tr><th rowspan=2>Year</th><th rowspan=2>Year Date</th><th rowspan=2>Plot</th>',"\n";
print OUT2 '<th colspan=6>Pitch</th><th colspan=6>Roll</th><th colspan=6>Yaw</th></tr>',"\n";
print OUT2 "<tr>\n";
print OUT2 '<th>Before</th><th>During</th><th>After</th>';
print OUT2 '<th>Before/During</th><th>After/During</th><th>Before/After</th>';
print OUT2 '<th>Before</th><th>During</th><th>After</th>';
print OUT2 '<th>Before/During</th><th>After/During</th><th>Before/After</th>';
print OUT2 '<th>Before</th><th>During</th><th>After</th>';
print OUT2 '<th>Before/During</th><th>After/During</th><th>Before/After</th>';
print OUT2 "</tr>\n";
print OUT2 "\n";
#close(OUT2);

$pos = 0;

OUTER2:
foreach $ent (@list){
	chomp $ent;
	@atemp = split(/\.gif/, $ent);
	$name = $atemp[0];
	@btemp = split(/www/, $atemp[0]);
	$name2 = $btemp[1];
	$html_name  = "$name".'.html';
	$html_name2 = 'https://cxc.cfa.harvard.edu/mta_days/'."$name2".'.html';

	if($ent =~ /\//){
		@btemp = split(/\//, $ent);
		$cnt = 0;
		foreach(@btemp){
			$cnt++;
		}
		$gif_name = $btemp[$cnt-1];
	}else{
		$gif_name = $ent;
	}
	@btemp = split(/\.gif/, $gif_name);
	@ctemp = split(/_/, $btemp[0]);
	$inst  = $ctemp[0];
	$ind   = $ctemp[1];
	$time  = $ctemp[2];

	open(OUT, ">$html_name");

	print OUT "<!DOCTYPE html>\n";
	print OUT '<html>',"\n";
	print OUT "<head>\n";
	print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
	print OUT '<link rel="stylesheet" type="text/css" href="https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css" />', "\n";

	print OUT "<style  type='text/css'>\n";
	print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
	print OUT "td{text-align:center;padding:8px}\n";
	print OUT "a:link {color:#00CCFF;}\n";
	print OUT "a:visited {color:yellow;}\n";
	print OUT "span.nobr {white-space:nowrap;}\n";
	print OUT "</style>\n";

	print OUT  '<title>'," $inst $ind $time",' </title></head>',"\n";
	print OUT '<body>',"\n";
	print OUT '<h2>Instrument:'," $inst",' Move:'," $ind",'  Time:'," $time",' </h2>',"\n";
	print OUT '<p>',"\n";
	print OUT 'The plots on left panels are gyro  drift rates of roll, pitch, and yaw around ',"\n";
	print OUT "$title2",'. The plotted values are 10**5 of the actual values.',"\n";
	print OUT ' The red lines indicate the start time and the end time of the grating',"\n";
	print OUT 'movement. The green line fitted are 5th degree of polynomial line around the ',"\n";
	print OUT 'grating movement. The difference between the fitted line and the actual data points ',"\n";
	print OUT 'are plotted on the right side panels. The values plotted are 10**9 of the ',"\n";
	print OUT 'actual values.  Note that the time interval plotted on ',"\n";
	print OUT 'the right panels are only around the grating movement.',"\n";
	print OUT 'The values listed at the left top corner is the mean and standard deviation of ',"\n";
	print OUT 'the deviations.',"\n";
	print OUT '</p><br /><br />',"\n";
	print OUT '<img src= "',"$gif_name",'" alt = "',"$gif_name",'"  style="height:500px;width:700px">',"\n";
	print OUT '</body>',"\n";
	print OUT '</html>',"\n";

	close(OUT);

	@ct = split(//, $time);
	$year = "$ct[0]$ct[1]$ct[2]$ct[3]";
	$yday = "$ct[4]$ct[5]$ct[6]";
#
#--- add the new link to the main html page
#	
	OUTER:
	for($m = $pos; $m < $dcnt; $m++){
		if($year == $dyear[$m] && $yday == $dydate[$m]){
			$pos = $m;
			last OUTER;
		}
	}
	
	@bf_sig = split(/\+\/\-/, $pt_bf[$pos]);
	@md_sig = split(/\+\/\-/, $pt_md[$pos]);
	@af_sig = split(/\+\/\-/, $pt_af[$pos]);

	if($md_sig[1] == 0){
		$pt_r1 = 0;
		$pt_f2 = 0;
	}else{
		$pt_r1 = abs($bf_sig[1]/$md_sig[1]);
		$pt_r2 = abs($af_sig[1]/$md_sig[1]);
	}
	if($af_sig[1] == 0){
		$pt_r3 = 0;
	}else{
		$pt_r3 = abs($bf_sig[1]/$af_sig[1]);
	}
	
	@bf_sig = split(/\+\/\-/, $rl_bf[$pos]);
	@md_sig = split(/\+\/\-/, $rl_md[$pos]);
	@af_sig = split(/\+\/\-/, $rl_af[$pos]);

	if($md_sig[1] == 0){
		$rl_r1 = 0;
		$rl_f2 = 0;
	}else{
		$rl_r1 = abs($bf_sig[1]/$md_sig[1]);
		$rl_r2 = abs($af_sig[1]/$md_sig[1]);
	}
	if($af_sig[1] == 0){
		$rl_r3 = 0;
	}else{
		$rl_r3 = abs($bf_sig[1]/$af_sig[1]);
	}
	
	@bf_sig = split(/\+\/\-/, $yw_bf[$pos]);
	@md_sig = split(/\+\/\-/, $yw_md[$pos]);
	@af_sig = split(/\+\/\-/, $yw_af[$pos]);

	if($md_sig[1] == 0){
		$yw_r1 = 0;
		$yw_f2 = 0;
	}else{
		$yw_r1 = abs($bf_sig[1]/$md_sig[1]);
		$yw_r2 = abs($af_sig[1]/$md_sig[1]);
	}
	if($af_sig[1] == 0){
		$yw_r3 = 0;
	}else{
		$yw_r3 = abs($bf_sig[1]/$af_sig[1]);
	}

	if($pt_bf[$pos] > 30 || $pt_md[$pos] > 30 || $pt_af[$pos] > 30
			|| $rl_bf[$pos] > 30 || $rl_md[$pos] > 30 || $rl_af[$pos] > 30
			|| $yw_bf[$pos] > 30 || $yw_md[$pos] > 30 || $yw_af[$pos] > 30){
		next OUTER2;
	}
#	open(OUT2, ">>$web_dir/$main_html");
	print OUT2 '<tr><th>',"$year",'</th><th>',"$yday",'</th><td>';
	print OUT2 '<a href="',"$html_name2",'" target="_blank">Plot</a></td>';

	print OUT2 '<td style="text-align:right">',"$pt_bf[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$pt_md[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$pt_af[$pos]",'</td>';

	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$pt_r1;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$pt_r2;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$pt_r3;

	print OUT2 '<td style="text-align:right">',"$rl_bf[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$rl_md[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$rl_af[$pos]",'</td>';

	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$rl_r1;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$rl_r2;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$rl_r3;

	print OUT2 '<td style="text-align:right">',"$yw_bf[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$yw_md[$pos]",'</td>';
	print OUT2 '<td style="text-align:right">',"$yw_af[$pos]",'</td>';

	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$yw_r1;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$yw_r2;
	printf OUT2 "<td style='text-align:center'>%2.3f</td>",$yw_r3;

	print OUT2 '</tr>',"\n";
#	close(OUT2);
}

#open(OUT2,">>$web_dir/$main_html");
print OUT2 '</table>',"\n";
print OUT2 '<br /><br /><hr />',"\n";
print OUT2 "Last Update: $month/$umday/$uyear\n";
print OUT2 '<br /><br />',"\n";
print OUT2 'If you have any questions, please contact',"\n";
print OUT2 "<a href='mailto:isobe\@head.cfa.harvard.edu'>isobe\@head.cfa.harvard.edu</a>","\n";
print OUT2 '</body>',"\n";
print OUT2 '</html>',"\n";
close(OUT2);

#
#--- update the main html page
#

$update = "Last Update: $month/$umday/$uyear";

open (FH, "$house_keeping/gyro_main.html");
@save_line = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		push(@save_line, $update);
	}else{
		push(@save_line, $_);
	}
}
close(FH);

open(OUT, ">$web_dir/gyro_main.html");
foreach $ent (@save_line){
	print OUT "$ent\n";
}
close(OUT);
