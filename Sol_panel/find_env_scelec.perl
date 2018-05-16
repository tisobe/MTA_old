#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	find_env_scelec.perl: find a moving average and an envelop for spacecarft	#
#			      electric power data (except elbi)				#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Jun 05, 2013						#
#											#
#########################################################################################

#
#--- test case; set this "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#---set directory
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- set a couple of input for find_moving_avg.perl script
#

$arange = '0.20';		#--- a period
$step   = '0.10';		#--- a step size
$nterms = 4;			#--- a degree of polynomial fitting

foreach $angle (40, 60, 80, 100, 120, 140, 160){
	foreach $col ('elbi', 'hrma', 'oba'){
		$name = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_'."$col".'.dat';
		$out  = "$data_dir".'/Data_scelec/scelec_angle'."$angle".'_'."$col".'_env.dat';
                $chk = 0;
#
#--- remove any lines which contains "NaN" (no data)
#

                open(FH, "$name");
                open(OUT, "> temp_out");
                while(<FH>){
                        chomp $_;
                        if($_ !~ /NaN/){
                                print OUT "$_\n";
                        }else{
                                $chk++;
                        }
                }
                close(FH);
                if($chk > 0){
                        system("mv temp_out $name");
                }else{
                        system("rm -rf temp_out");
                }
#
#--- find a moving average and an envelop for the data
#
		system("$op_dir/perl $script_dir/find_moving_avg.perl $name $arange $step $nterms $out");
	}
}
			

