#!/usr/bin/perl

#########################################################################
#                                                                       #
#       acis_hist_print_html: create html pages for count rate plots    #
#                                                                       #
#       author: Isobe Takashi (tisobe@cfa.harvard.edu)                  #
#                                                                       #
#       04/05/2011: last updated                                        #
#                                                                       #
#########################################################################

#############################################################################
#
#---- set directories
$dir_list = '/data/mta/Script/ACIS/Acis_hist_linux/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#############################################################################


##### find today's date and convert them appropriately

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}
$month = $umon + 1;

if ($uyear == 1999) {
        $dom = $uyday - 202;
}elsif($uyear >= 2000){
        $dom = $uyday + 163 + 365*($uyear - 2000);
        if($uyear > 2000) {
                $dom++;
        }
        if($uyear > 2004) {
                $dom++;
        }
        if($uyear > 2008) {
                $dom++;
        }
        if($uyear > 20012) {
                $dom++;
        }
}


$dyear  = $uyear - 1;
$dmonth = $month - 1; 
if($dmonth < 1){
	$dmonth = 12;
	$dyear = $uyear - 1;
}

open(FH, "$data_dir/Data/warn_no_data_trend");
@no_trend_data = ();
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	push(@no_trend_data, $atemp[0]);
}
close(FH);

open(FH, "$data_dir/Data/warn_no_data_trend_bkg");
@no_bkg_data = ();
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	push(@no_bkg_data, $atemp[0]);
}
close(FH);

open(FH, "$data_dir/Data/warn_no_data_total_bkg");
@no_total_bkg_data = ();
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	push(@no_total_bkg_data, $atemp[0]);
}
close(FH);

print_main_html();


##################################################
############### main page ########################
##################################################

sub print_main_html{

	open(OUT, ">$web_dir/acis_hist_main.html");

	print OUT '<HTML>';
	print OUT "\n";

	print OUT '<BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" VLINK="yellow" ALINK="#FF0000", background ="./stars.jpg">';
	print OUT "\n";


	print OUT '<script language="JavaScript">'; 
	print OUT "\n";
	print OUT 'function MyWindowOpener(imgname) {';
	print OUT "\n";
	print OUT 'msgWindow=open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no ,width=800,height=800,resize=yes");';
	print OUT "\n";
	print OUT 'msgWindow.document.close();';
	print OUT "\n";
	print OUT 'msgWindow.document.write("<HTML><TITLE>ACIS Histgram:   "+imgname+"</TITLE>");';
	print OUT "\n";
	print OUT "msgWindow.document.write(\"<BODY BGCOLOR='white'>\");";
	print OUT "\n";
	print OUT "msgWindow.document.write(\"<IMG SRC='/mta_days/mta_acis_hist/\"+imgname+\"' BORDER=0 WIDTH=800 HEIGHT=800><P></BODY></HTML>\");";
#	print OUT "msgWindow.document.write(\"<IMG SRC='/data/mta/Script/Acis_hist/New_acis_hist/\"+imgname+\"' BORDER=0 WIDTH=800 HEIGHT=800><P></BODY></HTML>\");";
	print OUT "\n";
	print OUT 'msgWindow.focus();';
	print OUT "\n";
	print OUT '}';
	print OUT "\n";
	print OUT '</script>';
	print OUT "\n";

	print OUT "\n";
	print OUT '<title> ACIS Histogram Data Plots </title>';
	print "\n";
	print OUT '<CENTER><H2>ACIS Histogram Data Plots</H2></CENTER>';
	print "\n";
#	print OUT '<CENTER><H3>Updated ';
#	print OUT "$uyear-$month-$umday  ";
#	print OUT "\n";
#	print OUT "<br>";
	$uyday++;
#	print OUT "DAY OF YEAR: $uyday ";
#	print OUT "\n";
#	print OUT "<br>";
#	print OUT "DAY OF MISSION: $dom ";
#	print OUT '</H3></CENTER>';
#	print OUT "\n";
#	print OUT '<P>';
#	print OUT "\n";
#	print OUT '<HR>';
#	print OUT "\n";
#	print OUT '<P>',"\n";

#	print OUT  '<b>External Source Plots from ',"Year: $dyear Month: $dmonth:",' 21-201 (left)  and 801-1001 (right) of CCD3, Node 1</b><br><br>',"\n\n";
#	print OUT  '<img src="', "$low_plot"  ,'"width =400, height=400>',"\n";
#	print OUT  '<img src="', "$high_plot" ,'"width =400, height=400>',"\n";
#	print OUT  "<br><br>\n";
#	print OUT  '<b>Composite Background Plots for the Entire Period: CCD 3 Node 1(left) and CCD 7 Node 1 (right)</b><br><br>',"\n\n";
#	print OUT  '<img src="', "$bkg_ccd3"  ,'"width =400, height=400>',"\n";
#	print OUT  '<img src="', "$bkg_ccd7"  ,'"width =400, height=400>',"\n";
#	print OUT  "<br><br><br>\n";

	print OUT '<p>',"\n";
	print OUT 'We have tended Event Histogram mode in order to characterize the ACIS response.',"\n";
	print OUT 'Two distinctive data are tended. One is data where ACIS is exposed to an ',"\n";
	print OUT 'external source, and the other is data where ACIS is seeing a background.',"\n";
	print OUT '</P>',"\n";

	print OUT '<p>',"\n";
	print OUT 'When HRC-S is located at the focal point (sim position:+250.1 mm: -100800 - -98400 motor steps),',"\n";
	print OUT 'ACIS is exposed to the external source. When this happens, ACIS observes ',"\n";
	print OUT 'Al K alpha, Mn K alpha, and Ti K alpha lines. Whenever this happens, we collected',"\n";
	print OUT 'histogram mode data, and fit a Gaussian profile to each peak, and find out',"\n";
	print OUT 'a peak position, a peak width, and a count rate. The peak portion is recoded',"\n";
	print OUT 'in ADU (bin position), the peak width is FWHM and in ADU, the count rate is',"\n";
	print OUT 'counts/sec (each histogram file typically contains 1650 frames or 5,348 sec).',"\n";
	print OUT '</p>',"\n";

	print OUT '<p>',"\n";
	print OUT 'There are also two different data sets in this histogram mode. One was obtained from ',"\n";
	print OUT 'CCD row positions 21-221, and the other are the row positions 801-1001. ',"\n";
	print OUT 'Since charges travel more in the latter, the peaks are more spread compared to the former cases.',"\n";
	print OUT '</p>',"\n";

	print OUT '<p>',"\n";
	print OUT 'When HRC-I is located at the focal point (sim position:+127.0 mm: -51700 - -49300 motor steps),',"\n";
	print OUT 'ACIS is seeing a background. Since there are not enough counts per observation, and',"\n";
	print OUT 'there are not many HRC-I observations, we did not create trend plots, but we created a',"\n";
	print OUT 'composite background plot for each CCD, Node, and CCD row. The bin size for',"\n";
	print OUT 'the background is 40 ADU so that there are 100 bins in the plot, and count rate is counts/second.',"\n";
	print OUT '</p>',"\n";

	print OUT '<p>',"\n";
	print OUT 'The following table contains:',"\n";
	print OUT '<br>',"\n";
	print OUT '1. CCD Name and row sampled',"\n";
	print OUT '<br>',"\n";
	print OUT '2. Trends of Peak Positions in ADU against Time (DOT). Three peaks (Mn, Al, and Ti) are plotted ',"\n";
	print OUT 'separately. Each point is from one histogram observation (~5,340 sec observation). ',"\n";
	print OUT 'No error is estimated.',"\n";
	print OUT '<br>',"\n";
	print OUT '3. Trends of Peak Widths (FWHM) in ADU against Time (DOT).',"\n";
	print OUT '<br>',"\n";
	print OUT '4. Trends of Peak Counts in Counts/sec against Time (DOT).',"\n";
	print OUT '<br>',"\n";
	print OUT '5. Trends of Background Count Rates in Counts/sec against Time (DOT). Counts are taken for each',"\n";
	print OUT 'histogram observation, and each bin size is 500 (ADU). There are 8 separate plots.',"\n";
	print OUT '<br>',"\n";
	print OUT '6. Composite Background Plots. A bin size is 40 ADU and there are 100 bins in the plots.',"\n";
	print OUT '<br>',"\n";
	print OUT '<br>',"\n";
#	print OUT 'Note: For the background, we used the entire range, instead of 201-401 or 801-1001.',"\n";
	print OUT 'Note: Background Counts/Plots data collection was terminated at the end of Year 2004.',"\n";
	print OUT '</p><p>',"\n";
	print OUT '<br>Reference:<br>',"\n";
	print OUT "<a href='http://asc.harvard.edu/cal/Acis/Cal_prods/bkgrnd/current/background.html'>\n";
	print OUT 'http://asc.harvard.edu/cal/Acis/Cal_prods/bkgrnd/current/background.html</a><br>',"\n";
	print OUT 'Using C handra Level 0 Event Histogram Files to Characterize the High-Energy Particle Background (PS file)<br>';
	print OUT "\n";
        print OUT 'Biller, B., Plucinsky, P., Edgar, R. 01/22/02<br>',"\n";
	print OUT '</P>',"\n";

	print OUT 'Please select Data:<br>';
	print OUT "\n";
	print OUT '';
	print OUT "\n";
	print OUT '<CENTER>';
	print OUT "\n";
	print OUT '<table border = 2 cellpadding = 10 >';
	print OUT "\n";
	print OUT '<tr>';
	print  OUT"\n";
	print OUT ' 		<th>CCD</th>';
	print OUT "\n";
	print OUT '      	<th>Peak Position</th>';
	print OUT "\n";
	print OUT '            <th>Peak Width</th>';
	print OUT "\n";
	print OUT '            <th>Peak Counts</th>';
	print OUT "\n";
	print OUT '            <th>Background Counts</th>';
	print OUT "\n";
	print OUT '            <th>Background Plots</th>';
	print OUT "\n";
	print OUT '</tr>';
	print OUT "\n";
	print OUT '<tr>';
#	for($ccd = 0; $ccd < 10; $ccd++){
#	foreach $ccd (1, 2, 3, 6, 7, 0, 4, 5, 8, 9){
	foreach $ccd (1, 2, 3, 6, 7){
		print OUT "<th>CCD $ccd</th>","\n";
		print OUT "\n";
			$chk_ind = 0;
			OUTER:
			foreach $ent (@no_trend_data){
				if($ent == $ccd){
					$chk_ind++;
					last OUTER;
				}
			}
			if($chk_ind == 0){
				print OUT "<td><a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/low_peak.gif')\">21-221</a><br>\n";
	
				print OUT "<a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/high_peak.gif')\">801-1001</a></td>\n";

	
				print OUT "<td><a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/low_width.gif')\">21-221</a><br>\n";
		
				print OUT "<a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/high_width.gif')\">801-1001</a></td>\n";


				print OUT "<td><a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/low_count.gif')\">21-221</a><br>\n";
		
				print OUT "<a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/high_count.gif')\">801-1001</a></td>\n";
			}else{
				print OUT '<td>21-221<br>801-1001</td>',"\n";
				print OUT '<td>21-221<br>801-1001</td>',"\n";
				print OUT '<td>21-221<br>801-1001</td>',"\n";
			}

		
			$chk_ind = 0;
			OUTER:
			foreach $ent (@no_bkg_data){
				if($ent == $ccd){
					$chk_ind++;
					last OUTER;
				}
			}
			if($chk_ind == 0){
				print OUT "<td><a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/full_bkg.gif')\">background trend</a><br>\n";

				print OUT "<td><a href=\"javascript:MyWindowOpener('./Results/CCD$ccd";
				print OUT "/total_bkg.gif')\">background</a><br>\n";
			}else{
				print OUT '<td>21-221<br>801-1001</td>',"\n";
				print OUT '<td>background</td>',"\n";
			}

		print OUT '</tr>',"\n";
	
	}
}
print OUT '</table></center>',"\n";

print OUT '<br><br><h3>Fitting Results</h3>',"\n";
print OUT '<a href="./Results/ccd1_line_fitting_data">CCD1 Line Fitting Results</a><br>',"\n";
print OUT '<a href="./Results/ccd2_line_fitting_data">CCD2 Line Fitting Results</a><br>',"\n";
print OUT '<a href="./Results/ccd3_line_fitting_data">CCD3 Line Fitting Results</a><br>',"\n";
print OUT '<a href="./Results/ccd6_line_fitting_data">CCD6 Line Fitting Results</a><br>',"\n";
#print OUT '<a href="./Results/ccd7_line_fitting_data">CCD7 Line Fitting Results</a><br>',"\n";
#print OUT '<br><br>',"\n";
#print OUT '<a href="./Results/ccd1_bkg_fitting_data">CCD1 Background Fitting Results</a><br>',"\n";
#print OUT '<a href="./Results/ccd2_bkg_fitting_data">CCD2 Background Fitting Results</a><br>',"\n";
#print OUT '<a href="./Results/ccd3_bkg_fitting_data">CCD3 Background Fitting Results</a><br>',"\n";
#print OUT '<a href="./Results/ccd6_bkg_fitting_data">CCD6 Background Fitting Results</a><br>',"\n";
#print OUT '<a href="./Results/ccd7_bkg_fitting_data">CCD7 Background Fitting Results</a><br>',"\n";
#
print OUT '<br><br><br><br>',"\n";
print OUT 'Last updated:  ';
print OUT "$uyear-$month-$umday  ","\n";







#########################################################
#########################################################
#########################################################

sub month_dig_lett {
        if($cmon == 1){
                $cmon ='JAN';
        }elsif($cmon == 2) {
                $cmon ='FEB';
        }elsif($cmon == 3) {
                $cmon ='MAR';
        }elsif($cmon == 4) {
                $cmon ='APR';
        }elsif($cmon == 5) {
                $cmon ='MAY';
        }elsif($cmon == 6) {
                $cmon ='JUN';
        }elsif($cmon == 7) {
                $cmon ='JUL';
        }elsif($cmon == 8) {
                $cmon ='AUG';
        }elsif($cmon == 9) {
                $cmon ='SEP';
        }elsif($cmon == 10) {
                $cmon ='OCT';
        }elsif($cmon == 11) {
                $cmon ='NOV';
        }elsif($cmon == 12) {
                $cmon ='DEC';
        }
}

