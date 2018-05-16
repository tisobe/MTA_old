#!/usr/bin/perl

#################################################################################
#										#
#	disk_space_run_dusk.perl: run dusk in each directory to get disk size	#
#				  information.					#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: Aug. 20, 2012						#
#										#
#################################################################################


############################################################
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


############################################################

system("mkdir $run_dir/param");

#
#--- /data/mta/
#
system("cd /data/mta; dusk > $run_dir/dusk_check");

#
#--- /data/mta4/
#
system("cd /data/mta4; dusk > $run_dir/dusk_check2");

#
#--- /data/swolk/MAYS/
#
system("cd /data/swolk/MAYS; dusk > $run_dir/dusk_check3");

#
#--- /data/swolk/AARON/
#
system("cd /data/swolk/AARON; dusk > $run_dir/dusk_check4");

#
#--- /data/swolk/	#---- this takes too long; dropped
#
#system("cd /data/swolk/; dusk > $run_dir/dusk_check5");
