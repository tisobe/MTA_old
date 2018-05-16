#!/usr/bin/perl

#################################################################################################
#												#
#	sci_run_print_top_html.perl: print top level html page					#
#												#
#		author: t. isobe (tisobe@cfa.harvard.edu)					#
#												#
#		last update: Jun 10, 2011							#
#												#
#################################################################################################

#################################################################
#
#--- setting directories
#

open(FH, '/data/mta/Script/Interrupt/house_keeping/dir_list');
@list = ();
while(<FH>){
        chomp $_;
        push(@list, $_);
}
close(FH);

$bin_dir       = $list[0];
$data_dir      = $list[1];
$web_dir       = $list[2];
$house_keeping = $list[3];

################################################################

#
#--- if the next input is given as arguments, use it, otherwise, ask
#--- a user to type it in.
#

$date_list  = $ARGV[0];  		# date list

if($date_list eq ''){
	print "Time List: ";            # a list of science run interruption
	$date_list = <STDIN>;
}

chomp $date_list;
if($date_list =~ /all_data/){
	$date_list = "$house_keeping/$date_list";
}


open(FH, "$date_list");

@hardness = ();

open(OUT1, '>./auto_list');
open(OUT2, '>./manual_list');
while(<FH>){
        chomp $_;
        $line  = $_;
        @atemp = split(/\s+/, $_);

        if($atemp[4] eq 'auto'){
                print OUT1 "$_\n";
        }else{
                print OUT2 "$_\n";
        }

        $name      = $atemp[0];
        $stat_data = "$web_dir".'/Stat_dir/'."$name".'_stat';
        open(IN, "$stat_data");
        while(<IN>){
                chomp $_;
                @ctemp = split(/\s+/, $_);
                if($ctemp[0] eq 'p47/p1060'){
                        push(@hardness, $ctemp[2]);
                        %{data.$ctemp[2]} = (data =>["$line"]);
                }
        }
        close(IN);
}
close(FH);
close(OUT1);
close(OUT2);

open(FH, "$house_keeping/rad_zone_list");

@rad_zone_list = ();
while(<FH>){
	chomp $_;
	push(@rad_zone_list, $_);
}
close(FH);

@ordered  = sort{$a<=>$b} @hardness;
@reversed = reverse @ordered;
open(OUT3, '>./hardness_ordered');

foreach $ent (@reversed){
        print OUT3 "${data.$ent}{data}[0]\n";
}
close(OUT3);

($hsec, $hmin, $hhour, $hmday, $hmon, $hyear, $hwday, $hyday, $hisdst)= localtime(time);

if($hyear < 1900) {
        $hyear = 1900 + $hyear;
}
$hmonth    = $hmon + 1;

$print_chk = 'yes';

#
#--- time ordered list
#

$which     = 'time_order';
$in_file   = $date_list;
$out_file  = 'time_order.html';

print_sub_html();

$print_chk = 'no';

#
#--- auto interrupt list
#

$which    = 'auto';
$in_file  = 'auto_list';
$out_file = 'auto_shut.html';

print_sub_html();

#
#--- manual interrupt list
#

$which    = 'manual';
$in_file  = 'manual_list';
$out_file = 'manu_shut.html';

print_sub_html();

#
#--- hardness ordered list
#

$which    = 'hardness';
$in_file  = 'hardness_ordered';
$out_file = 'hard_order.html';

print_sub_html();

system("rm ./auto_list ./manual_list ./hardness_ordered");

#######################################################################################
### print_sub_html: create sub html pages                                           ###
#######################################################################################

sub print_sub_html{
        open(FH, "$in_file");
        @name     = ();
        @start    = ();
        @end      = ();
        @interval = ();
        @method   = ();
        $total    = 0;

        while(<FH>){
                chomp $_;
                @atemp = split(/\s+/, $_);
                push(@name,     $atemp[0]);
                push(@start,    $atemp[1]);
                push(@end,      $atemp[2]);
                push(@interval, $atemp[3]);
                push(@method,   $atemp[4]);
                $total++;

                @btemp  = split(/:/, $atemp[1]);
                $uyear  = $btemp[0];
                $umonth = $btemp[1];
                $uday   = $btemp[2];

                to_dom();

                $begin  = $dom + $btemp[3]/24 + $btemp[4]/1440;

                @btemp  = split(/:/, $atemp[2]);
                $uyear  = $btemp[0];
                $umonth = $btemp[1];
                $uday   = $btemp[2];

                to_dom();

                $end    = $dom + $btemp[3]/24 + $btemp[4]/1440;

                OUTER:
                foreach $ent (@rad_zone_list){
                        if($ent =~ /$atemp[0]/){
                                @atemp = split(/\s+/, $ent);
                                @rad_entry = split(/:/, $atemp[1]);
                                $ent_cnt = 0;
                                foreach (@rad_entry){
                                        $ent_cnt++;
                                }
                        }
                }

                $rad_time = 0.0;
                foreach $ent (@rad_entry){
                        @dtmp = split(/\(/, $ent);
                        @etmp = split(/\)/, $dtmp[1]);
                        @ftmp = split(/\,/, $etmp[0]);

                        if($ftmp[0] >= $begin && $ftmp[1] <= $end){

                                $rad_time += ($ftmp[1] - $ftmp[0]);

                        }elsif($ftmp[0] < $begin && $ftmp[1] >= $begin && $ftmp[1] <= $end){

                                $rad_time += ($ftmp[1] - $begin);

                        }elsif($fmp[0] >= $begin && $fmp[0] <= $end &&  $ftmp[1] > $end){

                                $rad_time += ($end - $ftmp[0]);

                        }
                }
                $diff = 86.400 * ($end - $begin - $rad_time);
        }
        close(FH);

        open(OUT, ">$out_file");

        print OUT '<!DOCTYPE html PUBLIC "-//W3C//DTD html 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',"\n";
        print OUT '<html>',"\n";
        print OUT '<head>',"\n";
        print OUT '<!-- #### CSS STYLE SHEET FILE #### -->',"\n";
        print OUT '',"\n";
        print OUT '<link rel="stylesheet" type="text/css" href="http://asc.harvard.edu/mta/REPORTS/Template/mta_monthly.css" />',"\n";
        print OUT '',"\n";
        print OUT '</head>',"\n";
        print OUT '',"\n";
        print OUT '<title> Radiation Count Rate Plots for Periods Which Interrupted Science Runs </title>',"\n";
        print OUT '</head>',"\n";
        print OUT '',"\n";
        print OUT '<body>',"\n\n";
        print OUT '<h2>',"\n";
        print OUT 'Radiation Count Rate Plots for Periods Which Interrupted Science Runs',"\n";
        print OUT '</h2>',"\n";
        print OUT '<p style="text-align:right;font-weight:bold">',"\n";
        print OUT 'Last Updated: ', "$hyear-$hmonth-$hmday\n";
        print OUT '</p>',"\n";
        print OUT '',"\n";
        print OUT '<p style="font-weight:bold;padding-left:4em;padding-right:6em">',"\n";
        print OUT 'The following plots are P4 proton count rate (15.0 -  40.0 MeV protons Counts/cm2 sec sr MeV ---',"\n";
	print OUT 'before year 2011), or E150 electron count rate (electron Counts/cm2 sed sr eV from 2011)',"\n";
        print OUT 'around science runs were interrupted.  Plots start exactly 2 days before the interruption',"\n";
        print OUT 'started, and fnish 5 days after. ACE radiation data and other proton/electron count rate data',"\n";
        print OUT 'for the same periods can be found by clicking one of the plots, which opens up the page for',"\n";
        print OUT 'the specific period.',"\n";
        print OUT '</p>',"\n";

        print OUT '<p style="font-weight:bold;padding-left:4em;padding-right:6em">',"\n";
        print OUT 'If a plot is noted with "auto", the science run was automatically interrupted because the high radiation',"\n";
        print OUT 'tripped one of the criteria. If it is noted with "manual", it was done by an operator'."'".'s judgement.',"\n";
        print OUT '</pr>',"\n";

        print OUT '<p style="font-weight:bold;padding-left:4em;padding-right:6em">',"\n";
        print OUT 'Note: Data points in 2000 Data are one hour average. All others are 5 min average.',"\n";
	print OUT 'Plots after 2011 are siginficatlly different. Montoring of P4 and P41 were discontinued and ', "\n";
	print OUT 'replaced by e150 and e1500. GOES data are also chnaged from that of GOES 11 to GOES 15.', "\n";
        print OUT '</p>',"\n";

        print OUT '<hr />',"\n";


        if($which eq 'auto'){
                print OUT '<table border=0 cellpadding=3 cellspacing=3>',"\n";
                print OUT '<tr><td>',"\n";
                print OUT '<a href="time_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Time Ordered List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<em class="lime" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Auto Shutdown List</em>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="manu_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Manually Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="hard_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Hardness Ordered List</a>',"\n";
                print OUT '</td></tr></table>',"\n";
        }elsif($which eq 'manual'){
                print OUT '<table border=0 cellpadding=3 cellspacing=3>',"\n";
                print OUT '<tr><td>',"\n";
                print OUT '<a href="time_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Time Ordered List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="auto_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Auto Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<em class="lime" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Manually Shutdown List</em>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="hard_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Hardness Ordered List</a>',"\n";
                print OUT '</td></tr></table>',"\n";
        }elsif($which eq 'hardness'){
                print OUT '<table border=0 cellpadding=3 cellspacing=3>',"\n";
                print OUT '<tr><td>',"\n";
                print OUT '<a href="time_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Time Ordered List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="auto_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Auto Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="manu_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Manually Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<em class="lime" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Hardness Ordered List</em>',"\n";
                print OUT '</td></tr></table>',"\n";
                print OUT '<p style="font-weight:bold">',"\n";
                print OUT 'Hardness here is defined by the maximum ratio of P47/P1060',"\n";
                print OUT '</p>',"\n";
        }elsif($which eq 'time_order'){
                print OUT '<table border=0 cellpadding=3 cellspacing=3>',"\n";
                print OUT '<tr><td>',"\n";
                print OUT '<em class="lime" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Time Ordered List</em>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="auto_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Auto Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="manu_shut.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Manually Shutdown List</a>',"\n";
                print OUT '</td><td>',"\n";
                print OUT '<a href="hard_order.html" style="font-weight:bold;font-size:120%">',"\n";
                print OUT 'Hardness Ordered List</a>',"\n";
                print OUT '</td></tr></table>',"\n";

        }



        print OUT '<ul style="padding-bottom:30px">',"\n";

        for($k = 0; $k < $total; $k++){
                $sname           = $name[$k];
                $time            = $start[$k];
                @ttemp           = split(/:/, $time);
                $tyear           = $ttemp[0];
                $tmonth          = $ttemp[1];
                $tday            = $ttemp[2];

                to_yday();

                $time            = "$tyear:$tyday:$ttemp[3]:$ttemp[4]";
                $time2           = $end[$k];
                @ttemp           = split(/:/, $time2);
                $tyear           = $ttemp[0];
                $tmonth          = $ttemp[1];
                $tday            = $ttemp[2];

                to_yday();

                $time2           = "$tyear:$tyday:$ttemp[3]:$ttemp[4]";
                $interrupt_time  = $interval[$k];
                $int_method      = $method[$k];
                $data_file_name  = "$sname".'_dat.txt';
                $data_file_name2 = "$sname".'_eph.txt';
                $data_file_name3 = "$sname".'_goes.txt';
                $note_file_name  = "$sname".'.txt';

                $html_name       = "$sname".'.html';
                $stat_name       = "$sname".'_stat';
                $gif_name        = "$sname".'.gif';
                $ephin_gif       = "$sname".'_eph.gif';
                $goes_gif        = "$sname".'_goes.gif';
                $intro_gif       = "$sname".'_intro.gif';

                print  OUT '<li style="text-align:left;font-weight:bold;padding-bottom:20px">',"\n";
                print  OUT '<table border=0 cellpadding=3 cellspacing=3><tr>',"\n";
                print  OUT "<td>Science Run Stop: </td><td> $time</td><td>Start:  </td><td>$time2</td>";
                print  OUT "<td>Interruption: </td><td>";
                printf OUT  "%4.1f",$interrupt_time;
                print  OUT "ks</td><td>$int_method</td>","\n";
                print  OUT '</tr></table>',"\n";

                print  OUT "\<a href=\'./Html_dir/$html_name\'\>";
                print  OUT "\<img src = \'./Intro_plot/$intro_gif\'";
                print  OUT "width=\'100%\' height=\'20%\'\>\</a\>\n";

                print  OUT "\<a href=\'./Data_dir/$data_file_name\'\>ACE RTSW EPAM Data\</a\>,\n";
                print  OUT "\<a href=\'./Data_dir/$data_file_name2\'\>Ephin Data\</a\>,\n";
                print  OUT "\<a href=\'./Data_dir/$data_file_name3\'\>GOES Data\</a\>,\n";
                print  OUT "\<a href=\'./Note_dir/$note_file_name\'\>Note\</a\>,\n";
                print  OUT '<br>',"\n";
                print  OUT '<spacer type=vertical size=10>',"\n";
                print  OUT '</li>',"\n";

        }
        print OUT '</ul>',"\n";
        print OUT '<hr />',"\n";
        print OUT '<p style="float:right">',"\n";
        print OUT 'If you have any questions about this page, please contact:';
        print OUT '<a href="mailto:isobe@head.cfa.harvard.edu">isobe@head.cfa.harvard.edu</a>',"\n";
        print OUT '</p>',"\n";

        print OUT '</body>',"\n";
        print OUT '</html>',"\n";
        close(OUT);
}



##############################################################
### to_dom: change date format to DOM                      ###
##############################################################

sub to_dom{
        if($umonth == 1){
                $add = 0;
        }elsif($umonth == 2){
                $add = 31;
        }elsif($umonth == 3){
                $add = 59;
        }elsif($umonth == 4){
                $add = 90;
        }elsif($umonth == 5){
                $add = 120;
        }elsif($umonth == 6){
                $add = 151;
        }elsif($umonth == 7){
                $add = 181;
        }elsif($umonth == 8){
                $add = 212;
        }elsif($umonth == 9){
                $add = 243;
        }elsif($umonth == 10){
                $add = 273;
        }elsif($umonth == 11){
                $add = 304;
        }elsif($umonth == 12){
                $add = 334;
        }

	$chk = 4.0 * int(0.25 * $uyear);
	if($uyear == $chk){
		if($umonth > 2){
			$add++;
		}
	}

        $uyday = $uday + $add;

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
                if($uyear > 2012) {
                        $dom++;
                }
                if($uyear > 2016) {
                        $dom++;
                }
                if($uyear > 2020) {
                        $dom++;
                }
        }
}

##############################################################
### to_yday: change date format to year date               ###
##############################################################

sub to_yday{
        if($tmonth == 1){
                $add = 0;
        }elsif($tmonth == 2){
                $add = 31;
        }elsif($tmonth == 3){
                $add = 59;
        }elsif($tmonth == 4){
                $add = 90;
        }elsif($tmonth == 5){
                $add = 120;
        }elsif($tmonth == 6){
                $add = 151;
        }elsif($tmonth == 7){
                $add = 181;
        }elsif($tmonth == 8){
                $add = 212;
        }elsif($tmonth == 9){
                $add = 243;
        }elsif($tmonth == 10){
                $add = 273;
        }elsif($tmonth == 11){
                $add = 304;
        }elsif($tmonth == 12){
                $add = 334;
        }

        $tyday = $tday + $add;

        if($tyear == 2000 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2004 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2008 && $tmonth > 2) {
                $tyday++;
        }
        if($tyear == 2012 && $tmonth > 2) {
                $tyday++;
        }
}


