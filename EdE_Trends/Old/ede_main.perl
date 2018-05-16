#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	ede_main.perl: this script drive all other ede related perl scripts		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Jun 05, 2013							#
#											#
#########################################################################################
#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

#####################################################
#
#----- set directories
#
open(FH, "/data/mta/Script/Grating/EdE/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#---- set line selections 
#
@htg_list = (0.824, 1.022, 1.472);
@mtg_list = (0.654, 0.824, 1.022, 1.472);
@ltg_list = (0.654, 0.824, 1.022);
#####################################################

#
#--- if this is a test, prepare for the test
#

if($comp_test =~ /test/i){
	system("mkdir $test_web_dir");
	system("mkdir $test_web_dir/EdE_Data/");
	system("mkdir $test_web_dir/EdE_Plots/");
	system("mkdir $test_web_dir/HRMA/");
	system("mkdir $test_web_dir/HRMA/ACIS_HTG_1022/");
	system("mkdir $test_web_dir/HRMA/ACIS_MTG_1022/");
	system("mkdir $test_web_dir/HRMA/HRC_LTG_1022/");
	system("mkdir $test_web_dir/OBA/");
	system("mkdir $test_web_dir/OBA/ACIS_HTG_1022/");
	system("mkdir $test_web_dir/OBA/ACIS_MTG_1022/");
	system("mkdir $test_web_dir/OBA/HRC_LTG_1022/");

	system("mkdir $test_data_dir");
	system("cp $house_keeping/Test_prep/*_data  $test_web_dir/EdE_Data/.");

	$out_dir = $test_web_dir;
}else{
	$out_dir = $web_dir;
}

#
#---- statistics of time trends are computed by several parts; so first, we just print out the headers
#---- and statistics themselves are computed by ede_comp_stat.perl
#
open(OUT, '>stat_result.html');
print OUT "<!DOCTYPE html>\n";
print OUT '<html>',"\n";
print OUT "<head>\n";
print OUT "<title>E/dE Trend Page</title></head>\n";
print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
print OUT "<style  type='text/css'>\n";
print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
print OUT "a:link {color:blue;}\n";
print OUT "a:visited {color:teal;}\n";
print OUT "</style>\n";
print OUT "<head>\n";

print OUT "<body style='color:#000000;background-color:#FFFFFF;'>\n";
print OUT "\n";
print OUT '<h2>E/dE Trends Linear Regression Results</h2>',"\n";
print OUT "\n";
print OUT '<div style="text-align:center;margin-left:auto;margin-right;auto">',"\n";
print OUT '<table border=1>',"\n";
print OUT '<tr>',"\n";
print OUT '<th align="center">Line<br>(keV)</th>',"\n";
print OUT '<th align="center">Weighted Fit<br></th>',"\n";
print OUT '<th align="center">Robust Fit<br></th>',"\n";
print OUT "<th align='center'>Correlation  Probability</th>","\n";
print OUT '<th align="center">Data</th>',"\n";
print OUT '</tr>',"\n";
print OUT '<tr>',"\n";
print OUT '<th colspan =5>ACIS-S HETG</th>',"\n";
print OUT '</tr>',"\n";
close(OUT);
#
#---- acis hetg time trend computation starts
#
$grat = htg;
foreach $line (@htg_list){
	$nline = $line;
	$nline =~ s/\.//g;
	$data_file = "$out_dir".'/EdE_Data/acis_htg_'."$nline".'_data';

	system("$op_dir/perl $bin_dir/ede_find_value.perl $line $grat $data_file $comp_test");	# get data
	system("$op_dir/perl $bin_dir/ede_plot.perl       $data_file  $line");			# plot time - ede relation
	system("$op_dir/perl $bin_dir/ede_comp_stat.perl  $data_file  $line");			# compute correlation prob
}

system("mv $out_dir/EdE_Data/*gif $out_dir/EdE_Plots");

#
#---- acis hetg oba temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_oba.perl $out_dir/EdE_Data/acis_htg_1022_data_new $out_dir/OBA/ACIS_HTG_1022");
#system("mv $out_dir/OBA/ACIS_HTG_1022/*gif $out_dir/EdE_Plots");
#
#---- acis hetg hrma temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_hrma.perl $out_dir/EdE_Data/acis_htg_1022_data_new $out_dir/HRMA/ACIS_HTG_1022");
#system("mv $out_dir/HRMA/ACIS_HTG_1022/*gif $out_dir/EdE_Plots");



#
#--- acis metg time trend computation starts
#
open(OUT, '>>stat_result.html');
print OUT "\n";
print OUT '<tr>',"\n";
print OUT '<th colspan =5>ACIS-S METG</th>',"\n";
print OUT '</tr>',"\n";
close(OUT);

$grat = mtg;
foreach $line (@mtg_list){
	$nline = $line;
	$nline =~ s/\.//g;
	$data_file = "$out_dir".'/EdE_Data/acis_mtg_'."$nline".'_data';
	system("$op_dir/perl $bin_dir/ede_find_value.perl $line $grat $data_file $comp_test");
	system("$op_dir/perl $bin_dir/ede_plot.perl       $data_file  $line");
	system("$op_dir/perl $bin_dir/ede_comp_stat.perl  $data_file  $line");
}

system("mv $out_dir/EdE_Data/*gif $out_dir/EdE_Plots");

#
#---- acis metg oba temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_oba.perl $out_dir/EdE_Data/acis_mtg_1022_data_new $out_dir/OBA/ACIS_MTG_1022");
#system("mv $out_dir/OBA/ACIS_MTG_1022/*gif $out_dir/EdE_Plots");
#
#---- acis hetg hrma temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_hrma.perl $out_dir/EdE_Data/acis_mtg_1022_data_new $out_dir/HRMA/ACIS_MTG_1022");
#system("mv $out_dir/HRMA/ACIS_MTG_1022/*gif $out_dir/EdE_Plots");



#
#--- hrc letg time trend computation start here
#
open(OUT, '>>stat_result.html');
print OUT "\n";
print OUT '<tr>',"\n";
print OUT '<th colspan =5>ACIS-S METG</th>',"\n";
print OUT '</tr>',"\n";
close(OUT);

$grat = ltg;
foreach $line (@ltg_list){
	$nline = $line;
	$nline =~ s/\.//g;
	$data_file = "$out_dir".'/EdE_Data/hrc_ltg_'."$nline".'_data';
	system("$op_dir/perl $bin_dir/ede_find_value.perl $line $grat $data_file $comp_test");
	system("$op_dir/perl $bin_dir/ede_plot.perl       $data_file  $line");
	system("$op_dir/perl $bin_dir/ede_comp_stat.perl  $data_file  $line");
}

system("mv $out_dir/EdE_Data/*gif $out_dir/EdE_Plots");

#
#---- hrc letg oba temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_oba.perl $out_dir/EdE_Data/hrc_ltg_1022_data_new $out_dir/OBA/HRC_LTG_1022");
#system("mv $out_dir/OBA/HRC_LTG_1022/*gif $out_dir/EdE_Plots");
#
#---- hrc letg hrma temperature relation plotting starts here
#
system("$op_dir/perl $bin_dir/ede_hrma.perl $out_dir/EdE_Data/hrc_ltg_1022_data_new $out_dir/HRMA/HRC_LTG_1022");
#system("mv $out_dir/HRMA/HRC_LTG_1022/*gif $out_dir/EdE_Plots");
#
#---- complete and  move time trend statistics web page to the web direcotry
#
open(OUT, '>>stat_result.html');
print OUT "\n</table>\n";
print OUT "</div>\n";
print OUT "</body>\n";
print OUT "</html>\n";
close(OUT);

system("mv stat_result.html $out_dir/stat_result.html");

#
#--- compute OBA/HRMA statistics and create web pages
#
system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/OBA/ACIS_HTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/OBA/acis_htg_stat.html");

system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/OBA/ACIS_MTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/OBA/acis_mtg_stat.html");

system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/OBA/HRC_LTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/OBA/hrc_ltg_stat.html");


system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/HRMA/ACIS_HTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/HRMA/acis_htg_stat2.html");

system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/HRMA/ACIS_MTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/HRMA/acis_mtg_stat2.html");

system("perl $bin_dir/ede_mk_stat_table.perl $out_dir/HRMA/HRC_LTG_1022/ $comp_test");
system("mv stat_out.html $out_dir/HRMA/hrc_ltg_stat2.html");

#
#--- plotting oba example
#

system("$op_dir/perl $bin_dir/ede_oba_example.perl");
system("mv oba_example.gif $out_dir/EdE_Plots/");

#
#--- chage the "update" date on each html page to today's date
#
($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}
$month = $umon + 1;
$pmonth = conv_month_num_to_chr($month);

if($umday < 10){
	$pday = '0'."$umday";
}else{
	$pday = "$umday";
}

$line = "Last Updated: $pmonth $pday, $uyear";

open(FH, "$out_dir/ede_trend.html");
@save = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last/){
		push(@save, $line);
	}else{
		push(@save, $_);
	}
}
close(FH);

open(OUT, ">$out_dir/ede_trend.html");
foreach $ent (@save){
	print OUT "$ent\n";
}
close(OUT);


open(FH, "$out_dir/ede_time.html");
@save = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last/){
		push(@save, $line);
	}else{
		push(@save, $_);
	}
}
close(FH);

open(OUT, ">$out_dir/ede_time.html");
foreach $ent (@save){
	print OUT "$ent\n";
}
close(OUT);

open(FH, "$out_dir/ede_temp.html");
@save = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last/){
		push(@save, $line);
	}else{
		push(@save, $_);
	}
}
close(FH);

open(OUT, ">$out_dir/ede_temp.html");
foreach $ent (@save){
	print OUT "$ent\n";
}
close(OUT);

system("rm -rf $out_dir/EdE_Data/*_new");


###################################################################
### conv_month_num_to_chr: change month format to e.g. 1 to Jan ###
###################################################################

sub conv_month_num_to_chr{

        my ($temp_month, $cmonth);
        ($temp_month) = @_;

        if($temp_month == 1){
                $cmonth = "Jan";
        }elsif($temp_month == 2){
                $cmonth = "Feb";
        }elsif($temp_month == 3){
                $cmonth = "Mar";
        }elsif($temp_month == 4){
                $cmonth = "Apr";
        }elsif($temp_month == 5){
                $cmonth = "May";
        }elsif($temp_month == 6){
                $cmonth = "Jun";
        }elsif($temp_month == 7){
                $cmonth = "Jul";
        }elsif($temp_month == 8){
                $cmonth = "Aug";
        }elsif($temp_month == 9){
                $cmonth = "Sep";
        }elsif($temp_month == 10){
                $cmonth = "Oct";
        }elsif($temp_month == 11){
                $cmonth = "Nov";
        }elsif($temp_month == 12){
                $cmonth = "Dec";
        }
        return $cmonth;
}



