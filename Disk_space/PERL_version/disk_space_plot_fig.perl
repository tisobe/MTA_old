#/usr/bin/perl

#################################################################################################
#                                                                                               #
#       disk_space_plot_fig.perl: control all plotting scripts 	                                #
#                                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                               #
#               last update: Aug. 16, 2012                                                      #
#                                                                                               #
#################################################################################################

#################################################################################
#
#--- set directories
#
open(FH, "/data/mta/Script/Disk_check/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#################################################################################

system("$op_dir/perl $bin_dir/disk_space_check_size.perl");

system("$op_dir/perl $bin_dir/disk_space_read_dusk.perl");

system("$op_dir/perl $bin_dir/disk_space_read_dusk2.perl");

system("$op_dir/perl $bin_dir/disk_space_read_dusk5.perl");	#---- /data/swolk added 10/29/08

#system("perl $bin_dir/disk_space_read_dusk3.perl");	#---- /data/mays  removed
#system("perl $bin_dir/disk_space_read_dusk4.perl");	#---- /data/aaron removed

system("rm -r param ./dusk*");

#
#--- find today's date
#
($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

if($uyear < 1900) {
        $uyear = 1900 + $uyear;
}

$tyear  = $uyear;
$tmonth = $umon + 1;
if($tmonth < 10){
	$tmonth = '0'."$tmonth";
}
$tday   = $umday;
if($tday < 10){
	$tday   = '0'."$tday";
}

$update = "Last Update: $tmonth/$umday/$tyear";


open(FH, "$web_dir/disk_space.html");
@line = ();
while(<FH>){
	chomp $_;
	if($_ =~ /Last Update/){
		push(@line, $update);
	}else{
		push(@line, $_);
	}
}
close(FH);

open(OUT, ">$web_dir/disk_space.html");
foreach $ent (@line){
	print OUT "$ent\n";
}
close(OUT);
