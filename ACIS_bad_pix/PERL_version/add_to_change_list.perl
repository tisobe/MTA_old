#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#	
#	add_to_change_list.perl: update change_ccd* lists			#
#										#
#		author: t. isobe (tisobe@cfa.harvard.edu)			#
#										#
#		last update: Aug 01, 2012					#
#										#
#################################################################################

#
#---- set directories
#

$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);




for($ccd = 0; $ccd < 10; $ccd++){
#
#--- find out today's new warm pixels
#

	open(FH, "$data_dir/Disp_dir/new_ccd$ccd");
	while(<FH>){
		chomp $_;
		$new = $_;
	}
	close(FH);
#
#--- find out today's disappeared warm pixels
#
	open(FH, "$data_dir/Disp_dir/imp_ccd$ccd");
	while(<FH>){
		chomp $_;
		$imp = $_;
	}
	close(FH);
#
#--- now add both entires on the change file
#
	open(OUT, ">>$data_dir/Disp_dir/change_ccd$ccd");

	@atemp = split(/<>/, $new);

	print OUT "$atemp[0]<>$atemp[1]\n";
	print OUT "\tNew:";

	@btemp = split(/:/, $atemp[2]);
	foreach $ent (@btemp){
		if($ent ne ''){
			print OUT " $ent";
		}
	}
	print OUT "\n";

	@atemp = split(/<>/, $imp);

	print OUT "\tImp:";

	@btemp = split(/:/, $atemp[2]);
	foreach $ent (@btemp){
		if($ent ne ''){
			print OUT " $ent";
		}
	}
	print OUT "\n";
	close(OUT);
}



