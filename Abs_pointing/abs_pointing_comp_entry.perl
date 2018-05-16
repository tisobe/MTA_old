#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	abs_pointing_comp_entry.perl: compare a list of objects to already known 	#
#			 objects with coordinates and create another list for finding 	#
#			 the positional offsets. if the object is not in the list, 	#
#			 create inquiry list to submit to SIMBAD so that we can find 	#
#			 the coordinates						#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#	last update:	Apr. 16, 2013							#
#		modified to fit a new directory structure				#
#		modified SIMBAD query list format					#
#											#
#	files needed: constellation: a list of the name of constellations in 3 letters	#
#		      constellation2: a list of the name of constellations (full)	#
# 		      coord_list:    a list of objects with known coordinates		#
#											#
#########################################################################################

#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

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
#---- read name of constellations, abbriviated, and full names
#
open(FH, "$bdata_dir/Abs_pointing/constellation");
@constellation = ();
while(<FH>){
	chomp $_;
	push(@constellation, $_);
}
close(FH);
#
open(FH, "$bdata_dir/Abs_pointing/constellation2");
@constellation2 = ();
while(<FH>){
	chomp $_;
	push(@constellation2, $_);
}
close(FH);

if($comp_test =~ /test/i){
	open(FH, "$data_dir/obsid_list");
}else{
	open(FH, "$house_keeping/obsid_list");
}
@past_obsid = ();
while(<FH>){
	chomp $_;
	push(@past_obsid, $_);
}
close(FH);

#
#--- here are names we need to pay attentions
#

@planets = (mercury, venus, earth, mars, jupiter, saturn, neptune, uranus, pluto, moon, titan);

@star_list = (achernar, mira, polaris, algol, aldebaran, rigel, capella, betelgeuse, canopus, sirius, castor, procyon, pollux, regulus, spica, arcturus, antares, vega, altair, deneb, fomalhaut);

@special_list = (ORION, CRAB, HYDRA, CAR, MAJOR, MINOR, MAJORI, MINORI, LMC, SMC,  borealis, austrinus);

@greek = (ALPHA, BETA, GANNMA, DELTA, EPSILON, ZETA, ETA, THETA, IOTA, KAPPA, LAMBDA, MU, NU, XI, OMICRON, PI, RHO, SIGMA, TAU, UPSILON, PHI, CHI, PSI, OMEGA);
#
#---- list of objects with already known coordinates
#
if($comp_test =~ /test/i){
	open(FH, "$data_dir/coord_list");
}else{
	open(FH, "$house_keeping/coord_list");
}
@sname_list = ();
while(<FH>){
	chomp $_;
	@atemp = split(/\t+/, $_);
	$name = $atemp[0];
	$ra   = $atemp[1];
	$dec  = $atemp[2];
	$dra  = $atemp[3];
	$ddec = $atemp[4];
	$sname = $name;
	$sname =~ s/\s+//g;
	%{ent.$sname} = (
		name => ["$name"],
		ra   => ["$ra"],
		dec  => ["$dec"],
		dra  => ["$dra"],
		ddec => ["$ddec"]
		);
	push(@sname_list, $sname);
}
close(FH);

#
#---- open the candidate list, then devide them into a konwn coodinates list and
#----  an un-known coordinate list
#
open(FH, './candidate_list');

open(OUT1, '>./known_coord');
open(OUT2, '>./check_coord');

@check_list = ();
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/:/, $_);
	$obsid = $atemp[0];
	foreach $comp (@past_obsid){
		if($obsid == $comp){
			next OUTER;
		}
	}
	$name  = $atemp[1];
	$inst  = $atemp[2];
	$grat  = $atemp[3];

#
#----- remove any appended nate from the name of the object
#
	if($name =~ /\,/){
		@stemp = split(/\,/, $name);
		$name = $stemp[0];
	}elsif($name =~ /\[/){
		@stemp = split(/\[/, $name);
		$name = $stemp[0];
	}elsif($name =~ /\(/){
		@stemp = split(/\(/, $name);
		$name = $stemp[0];
	}
	if($name =~ /\_/){
		@stemp = split(/_/, $name);
		$name = "$stemp[0] $stemp[1]";
	}

#
#---- if the object is already listed in known coordinate list, use it
#---- the objects will be written in 'known_coord' file
#
	$sname = $name;
	$sname =~ s/\s+//g;
	foreach $ent (@sname_list){
		if($sname =~ /$ent/i || $sname eq "$ent"){
			print OUT1 "$obsid\t$inst\t$grat\t";
			print OUT1 "${ent.$ent}{name}[0]\t";
			print OUT1 "${ent.$ent}{ra}[0]\t";
			print OUT1 "${ent.$ent}{dec}[0]\t";
			print OUT1 "${ent.$ent}{dra}[0]\t";
			print OUT1 "${ent.$ent}{ddec}[0]\n";
			next OUTER;
		}
	}

#
#---- if it is test, drop it
	if($sname =~ /TEST/i){
		next OUTER;
	}
#
#---- clean up the name so that we can submit to SIMBAD
#
	@ntemp = split(//, $sname);
	$cnt = 0;
	foreach(@ntemp){
		$cnt++;
	}
#
#---- the case the name contains "plusar"
#
	if($sname =~ /pulsar/i){
		@stemp = split(/pulsar/i, $sname);

		$name = "$stemp[0] pulsar";
		print OUT2 "$name\t$obsid\t$inst\t$grat\n";
		push(@check_list, $name);
		next OUTER;
	}
#
#--- the case the name is markarian
#
	if($sname =~ /MARKARIAN/i){
		print OUT2 "$name\t$obsid\t$inst\t$grat\n";
		push(@check_list, $name);
		next OUTER;
	}
#
#--- if the object is one of planets, remove it
#
	foreach $plt (@planets){
		if($sname =~ /$plt/i){
			next OUTER;
		}
	}
#
#--- the case that  the object is one of famous stars
#
	foreach $ent (@star_list){
		if($sname =~ /$ent/i){
			@stemp = split(/$ent/i, $sname);
			if($stemp[0] eq ''){
				$name = "$ent $stemp[1]";
			}else{
				$name = "$stemp[0] $ent";
			}
			print OUT2 "$name\t$obsid\t$inst\t$grat\n";
			push(@check_list, $name);
			next OUTER;
		}
	}
#
#--- other special cases, mainly constellation names
#
	foreach $ent (@special_list){
		if($sname =~ /$ent/i){
			@stemp = split(/$ent/i, $sname);
			if($sname =~ /major/i || $sname =~ /minor/){
				foreach $cpart ('canis', 'ursa', 'leo'){
					if($sname =~ /$cpart/i){
						@ttemp = split(/$cpart/i, $sname);
						$name = "$ttemp[0] $cpart $ent";
					}
				}
			}elsif($stemp[0] ne '' && $stemp[1] ne ''){
				$name = "$stemp[0] $ent $stemp[1]";
			}elsif($stemp[0] eq ''){
				$name = "$ent $stemp[1]";
			}else{
				$name = "$stemp[0] $ent";
			}
			print OUT2 "$name\t$obsid\t$inst\t$grat\n";
			push(@check_list, $name);
			next OUTER;
		}
	}
#
#---- check the name contains a full constellation names
#

	foreach $ent (@constellation2){
		if($sname =~ /$ent/i){
			@stemp = split(/$ent/i, $sname);
			if($stemp[0] eq ''){
				$name = "$ent $stemp[1]";
			}else{
				$name = "$stemp[0] $ent";
			}
			print OUT2 "$name\t$obsid\t$inst\t$grat\n";
			push(@check_list, $name);
			next OUTER;
		}
	}
#
#---- check whether fully spelled out greek letter is used
#
	foreach $ent (@greek){
		if($sname =~ /$ent/i){
			@stemp = split(/$ent/i, $sname);
			$name = "$ent $stemp[1]";
			print OUT2 "$name\t$obsid\t$inst\t$grat\n";
			push(@check_list, $name);
			next OUTER;
		}
	}
#
#--- find out whether the name contains 3 letter constellation names
#--- if it does, separate so that SIMBAD can use it
#
	$cnt_3 = $cnt -3;
	$cnt_2 = $cnt -2;
	$cnt_1 = $cnt -1;
	$first_three = "$ntemp[0]$ntemp[1]$ntemp[2]";
	$last_three = "$ntemp[$cnt_3]$ntemp[$cnt_2]$ntemp[$cnt_1]";
	OUTER2:
	foreach $ent (@constellation){
		if($sname =~ /$ent/i){
			if($first_three =~ /$ent/i){
				$part2 = '';
				for($k = 3; $k < 6; $k++){
					$part2 = "$part2"."$ntemp[$k]";
				}
				$name = "$ent $part2";
				last OUTER2;
			}else{
				@stemp = split(/$ent/i, $sname);
				$name = "$stemp[0] $ent";
				last OUTER2;
			}
		}
	}
	print OUT2 "$name\t$obsid\t$inst\t$grat\n";
	push(@check_list, $name);

}
close(OUT1);
close(OUT2);
close(FH);

@check_list = sort @check_list;
foreach $ent (@check_list){
	$uent = uc $ent;
	push(@temp, $uent);
}
@check_list = @temp;

$first = shift(@check_list);
@new = ("$first");
OUTER:
foreach $ent (@check_list){
	$sent = $ent;
	$sent =~ s/\s+//g;
	foreach $comp (@new){
		$scomp = $comp;
		$scomp =~ s/\s+//g;
		if($sent eq $scomp){
			next OUTER;
		}
	}
	push(@new, $ent);
}
#
#--- sending out inquiry to SIMBAD
#
open(OUT4, '>./simbad_list');
foreach $ent (@new){
	if($ent =~ /\w/){
		print OUT4 "$ent\n";
	}
}
close(OUT4);
