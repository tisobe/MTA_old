#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	abs_pointing_get_coord_from_simbad.perl: extract coordinates 		#
#				informaiton from SIMBAD	database.		#
#										#
#	author:	t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: Apr 26, 2013						#
#										#
#################################################################################
#
#--- check whether this is a test case
#
OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}

###################################################################
#
#---- setting directories
#
if($comp_test =~ /test/i){
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

###################################################################

#
#--- set email user name who will get email when coordinates are not obtained
#

$user = $ARGV[0];
chomp $user;

#
#--- read target names etc
#

open(FH, './check_coord');
@targets = ();
@obsid   = ();
@inst    = ();
@grat    = ();
$total   = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\t+/, $_);
	push(@targets, $atemp[0]);
	push(@obsid,   $atemp[1]);
	push(@inst,    $atemp[2]);
	push(@grat,    $atemp[3]);
	$total++;
}
close(FH);

@target_list = ();
open(FH, './simbad_list');
while(<FH>){
	chomp $_;
	push(@target_list, $_);
}
close(FH);

@results    = ();
@check_list = ();

foreach $target (@target_list){
#
#--- print a target name on a file so that the main script can read it
#
	open(OUT2, ">tag_name");
	print OUT2 "$target\n";
	close(OUT2);
#
#--- simbad_query.perl actually goes to SIBAD site and retrieves coordinate information
#
	system("$op_dir/perl  $bin_dir/abs_pointing_simbad_query.perl");
	$sim_data = '';
	@ctemp    = ();
	$sim_data = `cat simbad_out`;
	@ctemp = split(/\t+/, $sim_data);
#
#--- default settings for coordinates
#
	$ra    = '99:99:99.999';
	$dec   = '99:99:99.999';
	$pmra  = '0.0';
	$pmdec = '0.0';

	if($sim_data eq ''){
#
#--- if simbad failed to give coordinate information, keep the target name
#--- in check_list.
#
		push(@check_list, $target);
	}elsif($ctemp[0] =~ /\d/ && $ctemp[1] =~ /\d/){
		$ra  = $ctemp[0];
		$dec = $ctemp[1];
		if($ctemp[2] =~ /\d/ && $ctemp[3] =~ /\d/){
			$pmra  = $ctemp[2];
			$pmdec = $ctemp[3];
			chomp $pmra;
			chomp $pmdec;
		}
	}else{
		push(@check_list, $target);
	}

	system("rm -rf simbad_out");
#
#--- adjust target name length so that when it is printed, looks prittier.
#
	@atemp = split(//, $target);
	$tcnt = 0;
	foreach(@atemp){
		$tcnt++;
	}
	if($tcnt < 8){
        	$line = "$target\t\t$ra\t$dec\t$pmra\t$pmdec";
	}else{
        	$line = "$target\t$ra\t$dec\t$pmra\t$pmdec";
	}
	push(@results, $line);
}
#
#--- remove duplicated lines
#
$first = shift(@results);
@new   = ($first);
OUTER:
foreach $ent (@results){
	foreach $comp (@new){
		if($ent eq $comp){
			next OUTER;
		}
	}
	push(@new, $ent);
}

@results = @new;
#
#---- put the newly found coordinate values to coord_list
#
open(OUT, ">>./coord_list");
foreach $ent (@new){
	print OUT "$ent\n";
}
close(OUT);

#
#---- print checked coordinate values in know_coord list
#

open(OUT, '>>./known_coord');
OUTER:
for($i = 0; $i < $total; $i++){
	foreach $ent (@results){
		if($ent =~ /$targets[$i]/i && $targets[$i] ne ''){
			print OUT "$obsid[$i]\t$inst[$i]\t$grat[$i]\t$ent\n";
			next OUTER;
		}
	}
}
close(OUT);
#
#--- print out targets which we could not identify the coordinates
#
open(OUT, ">./unknown_coordinate");
$chk = 0;
OUTER:
for($i = 0; $i < $total; $i++){
	foreach $ent (@check_list){
		if($ent eq $targets[$i]){
			print OUT "$obsid[$i]\t$inst[$i]\t$grat[$i]\t$ent\n";
			$chk++;
			next OUTER;
		}
	}
}
close(OUT);

