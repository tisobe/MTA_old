#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	abs_pointing_main.perl: a control perl script for abs_pointing 		#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: Aug 01, 2012						#
#										#
#################################################################################

#
#--- check whether this is a test case
#

$comp_test = $ARGV[0];
chomp $comp_test;

###################################################################
#
#---- setting directories
#
if($comp_test =~ /test/){
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#
#---- and others
#
open(FH, "$bdata_dir/.dare");
@inline =<FH>;
close(FH);
$dare = $inline[0];
$dare =~ s/\s+//;

###################################################################


system("$op_dir/perl $bin_dir/abs_pointing_find_candidate.perl              $comp_test");

system("$op_dir/perl $bin_dir/abs_pointing_comp_entry.perl                  $comp_test");
system("$op_dir/perl $bin_dir/abs_pointing_get_coord_from_simbad.perl       $dare $comp_test");
system("$op_dir/perl $bin_dir/abs_pointing_extract_obsid.perl               $comp_test");
system("perl $bin_dir/abs_pointing_compute_pos_diff.perl            $comp_test");

system("$op_dir/perl $bin_dir/abs_pointing_acis_plot.perl                   $comp_test");
system("$op_dir/perl $bin_dir/abs_pointing_hrci_plot.perl                   $comp_test");
system("$op_dir/perl $bin_dir/abs_pointing_hrcs_plot.perl                   $comp_test");
system("$op_dir/perl $bin_dir/abs_pointing_print_html.perl                  $comp_test");


system("rm -rf candidate_list check_coord known_coord  simbad_list");
