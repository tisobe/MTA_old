#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
# make_detrend_data.perl: add detrend correction and create new dataset	#
#									#
#	author: T. Isobe (tisobe@cfa.harvard.edu)			#
#	Jul 24, 2012							#
#		modified to fit a new directry system			#
#	last update: Apr 15, 2013					#
#									#
#########################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;

#########################################
#--- set directories
#
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#########################################

open(FH, "$house_keeping/amp_avg_list");		#read correciton factors
@obsid_list = ();
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	%{detrend.$atemp[2]} = ( ratio => ["$atemp[1]"]);
	push(@obsid_list, $atemp[2]);
}
close(FH);

foreach $peak ('al', 'mn', 'ti'){
	foreach $iccd (0, 1, 2, 3, 4, 6, 8, 9){		         # imaging CCDs only
		$file     = "$data_dir/Results/"."$peak".'_ccd'."$iccd";
		$out_file = "$data_dir/Det_Results/"."$peak".'_ccd'."$iccd";

		open(FH,"$file");
		open(OUT,">$out_file");

		OUTER:
		while(<FH>){
                        chomp $_;
                        @atemp = split(/\s+/,$_);
                        $date  = $atemp[0];
                        $quad0 = $atemp[1];
                        $quad1 = $atemp[2];
                        $quad2 = $atemp[3];
                        $quad3 = $atemp[4];
                        $obsid = $atemp[5];
                        $date2 = $atemp[6];
			$t_int = $atemp[7];
			$focal = $atemp[8];

                        foreach $comp (@obsid_list){
                                if($obsid == $comp){
                                        $det = ${detrend.$comp}{ratio}[0];
                                        unless($det > 999){
                                                $quad  = $quad0;
                                                correct_det();
                                                $quad0 = $quad;

                                                $quad  = $quad1;
                                                correct_det();
                                                $quad1 = $quad;

                                                $quad  = $quad2;
                                                correct_det();
                                                $quad2 = $quad;

                                                $quad  = $quad3;
                                                correct_det();
                                                $quad3 = $quad;

                                                print OUT "$date\t";
                                                print OUT "$quad0\t";
                                                print OUT "$quad1\t";
                                                print OUT "$quad2\t";
                                                print OUT "$quad3\t";
                                                print OUT "$obsid\t";
                                                print OUT "$date2\t";
						print OUT "$t_int\t";
						print OUT "$focal\n";
                                                next OUTER;
                                        }
                                }
                        }
                }
                close(OUT);
                close(FH);
        }
}

####################################################################################
### sub correct_det: correct format for printing out                             ###
####################################################################################

sub correct_det{
        @btemp = split(/\+\-/,$quad);
        $val = $btemp[0];
        $err = $btemp[1];
        $val += $det;
        @ctemp = split(//,$val);
        $cval = "$ctemp[0]$ctemp[1]$ctemp[2]$ctemp[3]$ctemp[4]";
        $quad = "$cval".'+-'."$err";
}


