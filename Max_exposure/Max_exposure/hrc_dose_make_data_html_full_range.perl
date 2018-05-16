#!/usr/bin/perl

#########################################################################################
#											#
#	hrc_dose_make_data_html.perl: create  html data pages for a report		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: May 24, 2005							#
#											#
#########################################################################################
	
$in_dir  = $ARGV[0];

if($in_dir eq ''){
	print "Usage: perl hrc_dose_make_data_html.perl <data dir>\n";
	exit 1;
}

$list = `ls $in_dir/*dff`;
@list = split(/\s+/, $list);
OUTER:
foreach $file (@list){
	if($file !~ /HRC/i){
		next OUTER;
	}
	@atemp = split(/_dff/, $file);

	if($file =~ /hrci/i){
		$pos = 'I';
	}else{
		$pos = 'S';
	}
	$acc_file = "$atemp[0]".'_acc';
	$out_file = "$atemp[0]".'.html';

	@btemp = split(/_/, $atemp[0]);
	$chk = 0;
	foreach (@btemp){
		$chk++;
	}
	$sec = $btemp[$chk -1];				#----- section indicator

	@btemp = split(/\\/, $atemp[0]);
	$title = 'HRC '."$pos".' Sec:'."$sec";

	@year   = ();
	@month  = ();
	@avg    = ();
	@sdv    = ();
	@min    = ();
	@minpos = ();
	@max    = ();
	@maxpos = ();
	@m10	= ();
	@m10pos = ();
	$cnt    = 0;
	open(FH, "$file");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@year,  $atemp[0]);
		push(@month, $atemp[1]);
		push(@avg,   $atemp[2]);
		push(@sdv,   $atemp[3]);
		push(@min,   $atemp[4]);
		push(@minpos,$atemp[5]);
		push(@m10,   $atemp[6]);
		push(@m10pos,$atemp[7]);
		push(@max ,  $atemp[8]);
		push(@maxpos,$atemp[9]);
		$cnt++;
	}
	close(FH);
	@ayear   = ();
	@amonth  = ();
	@aavg    = ();
	@asdv    = ();
	@amin    = ();
	@aminpos = ();
	@amax    = ();
	@amaxpos = ();
	@am10	= ();
	@am10pos = ();
	open(FH, "$acc_file");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		push(@ayear,  $atemp[0]);
		push(@amonth, $atemp[1]);
		push(@aavg,   $atemp[2]);
		push(@asdv,   $atemp[3]);
		push(@amin,   $atemp[4]);
		push(@aminpos,$atemp[5]);
		push(@am10,   $atemp[6]);
		push(@am10pos,$atemp[7]);
		push(@amax ,  $atemp[8]);
		push(@amaxpos,$atemp[9]);
	}
	close(FH);
		
	open(OUT, ">$out_file");
	print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="#00CCFF" ';
	print OUT 'VLINK="yellow" ALINK="yellow"background="./stars.jpg">',"\n";
	print OUT '<title>Data</title>',"\n";
	
	print OUT "<center> <h1>Data: $title </h1> </center>\n";

#
#----  update the html page
#

        ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        $year  = 1900   + $uyear;
        $month = $umon  + 1;

        $line = "<br><H3> Last Update: $month/$umday/$year</H3>";
        print OUT "$line\n";

	print OUT '<table border=1 cellspacing=3 cellpadding=3>',"\n";

	print OUT '<tr>',"\n";
	print OUT '<td>&#160</td><td>&#160</td>',"\n";
	print OUT '<td colspan=8>Monlthy</td>',"\n";
	print OUT '<td colspan=8>Cumulative</td>',"\n";
	print OUT '</tr><tr>',"\n";
	print OUT '<th>Year</th>',"\n";
	print OUT '<th>Month</th>',"\n";
	print OUT '<th>Mean</th>',"\n";
	print OUT '<th>SD</th>',"\n";
	print OUT '<th>Min</th>',"\n";
	print OUT '<th>Min Position</th>',"\n";
	print OUT '<th>Max</th>',"\n";
	print OUT '<th>Max Position</th>',"\n";
	print OUT '<th>Data</th>',"\n";
	print OUT '<th>Map</th>',"\n";

	print OUT '<th>Mean</th>',"\n";
	print OUT '<th>SD</th>',"\n";
	print OUT '<th>Min</th>',"\n";
	print OUT '<th>Min Position</th>',"\n";
	print OUT '<th>Max</th>',"\n";
	print OUT '<th>Max Position</th>',"\n";
	print OUT '<th>Data</th>',"\n";
	print OUT '<th>Map</th>',"\n";
	print OUT '</tr>',"\n";

	for($i = 0; $i < $cnt; $i++){
		print OUT '<tr>',"\n";
		print OUT "<td>$year[$i]</td>\t";
		print OUT "<td>$month[$i]</td>\t";
		print OUT "<td>$avg[$i]</td>\t";
		print OUT "<td>$sdv[$i]</td>\t";
		print OUT "<td>$min[$i]</td>\t";
		print OUT "<td>$minpos[$i]</td>\t";
		print OUT "<td>$max[$i]</td>\t";
		print OUT "<td>$maxpos[$i]</td>\t";
		$in_month = $month[$i];
		chg_month_format();
		$tmonth = $month[$i];
		if($month[$i] < 10 && $month[$i] !~ /^0/){
			$tmonth = '0'."$month[$i]";
		}
#		$line = "$year[$i]$cmonth".'/'.'HRC'."$pos"."_$tmonth".'_'."$year[$i]".'.fits.gz';
		$line = 'HRC'."$pos"."_$tmonth".'_'."$year[$i]".'_'."$sec".'.fits.gz';
		if($avg[$i] !~ /\d/){
			print OUT '<td>No Data</td>',"\n";
			print OUT '<td>No Image</td>',"\n";
		}else{
#			print OUT '<td><a href=http://asc.harvard.edu/mta/REPORTS/MONTHLY/'."$line".'>fits</a></td>'."\n";
			print OUT '<td><a href=http://cxc.harvard.edu/mta_days/mta_max_exp/HRC/Month_hrc/'."$line".'>fits</a></td>'."\n";
#			$line = "$year[$i]$cmonth".'/'.'HRC'."$pos"."_$tmonth".'_'."$year[$i]".'.gif';
#			$line = 'HRC'."$pos"."_$tmonth".'_'."$year[$i]".'.png';
			$line = 'HRC'."$pos"."_$tmonth".'_'."$year[$i]".'_'."$sec".'.png';
#			print OUT '<td><a href=http://asc.harvard.edu/mta/REPORTS/MONTHLY/'."$line".'>map</a></td>'."\n";
			print OUT '<td><a href=http://cxc.harvard.edu/mta_days/mta_max_exp/HRC/Month_hrc/'."$line".'>map</a></td>'."\n";
		}

		print OUT "<td>$aavg[$i]</td>\t";
		print OUT "<td>$asdv[$i]</td>\t";
		print OUT "<td>$amin[$i]</td>\t";
		print OUT "<td>$aminpos[$i]</td>\t";
		print OUT "<td>$amax[$i]</td>\t";
		print OUT "<td>$amaxpos[$i]</td>\t";
#		$line = "$year[$i]$cmonth".'/'.'HRC'."$pos"."_08_1999_$tmonth".'_'."$year[$i]".'.fits.gz';
		$line = 'HRC'."$pos"."_09_1999_$tmonth".'_'."$year[$i]".'_'."$sec".'.fits.gz';
#		print OUT '<td><a href=http://asc.harvard.edu/mta/REPORTS/MONTHLY/'."$line".'>fits</a></td>'."\n";
		print OUT '<td><a href=http://cxc.harvard.edu/mta_days/mta_max_exp/HRC/Cumulative_hrc/'."$line".'>fits</a></td>'."\n";
#		$line = "$year[$i]$cmonth".'/'.'HRC'."$pos"."_08_1999_$tmonth".'_'."$year[$i]".'.gif';
#		$line = 'HRC'."$pos"."_09_1999_$tmonth".'_'."$year[$i]".'.png';
		$line = 'HRC'."$pos"."_09_1999_$tmonth".'_'."$year[$i]".'_'."$sec".'.png';
#		print OUT '<td><a href=http://asc.harvard.edu/mta/REPORTS/MONTHLY/'."$line".'>map</a></td>'."\n";
		print OUT '<td><a href=http://cxc.harvard.edu/mta_days/mta_max_exp/HRC/Cumulative_hrc/'."$line".'>map</a></td>'."\n";
		print OUT '</tr>',"\n";
	}
	print OUT '</table>';

        close(OUT);
}


##########################################################################
### chg_month_format: change num month to letter month                 ###
##########################################################################

sub chg_month_format{
	if($in_month == 1){
		$cmonth = "JAN";
	}elsif($in_month == 2){
		$cmonth = "FEB";
	}elsif($in_month == 3){
		$cmonth = "MAR";
	}elsif($in_month == 4){
		$cmonth = "APR";
	}elsif($in_month == 5){
		$cmonth = "MAY";
	}elsif($in_month == 6){
		$cmonth = "JUN";
	}elsif($in_month == 7){
		$cmonth = "JUL";
	}elsif($in_month == 8){
		$cmonth = "AUG";
	}elsif($in_month == 9){
		$cmonth = "SEP";
	}elsif($in_month == 10){
		$cmonth = "OCT";
	}elsif($in_month == 11){
		$cmonth = "NOV";
	}elsif($in_month == 12){
		$cmonth = "DEC";
	}
}
