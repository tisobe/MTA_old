#!/usr/bin/env /usr/local/bin/perl

#########################################################################################
#											#
#	abs_pointing_comp_second.perl: compare a list of objects to already known 	#
#			 objects with						 	#
#		  	 coordinates and create another list for finding the positional	#
#			 offsets. this is second round of check after checking 		#
#			 coordinates at SIMBAD. if we still cannot find the coordinates	#
#		         the observation will be drop from the further analysis		#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#	last update:	Apr. 16, 2012							#
#											#
#	needed file: constellation: a list of the name of constellations in 3 letters	#
#		     coord_list:    a list of objects with known coordinates		#
#		     obisid_list:   list all obsid checked (used and discarded)		#
#											#
#########################################################################################

#
#--- read directory list
#
$dir_list = '/data/mta/Script/ALIGNMENT/Abs_pointing/house_keeping/dir_list';
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#---- read name of constellations
#
open(FH, "$data_dir/Abs_pointing/constellation");
@constellation = ();
while(<FH>){
	chomp $_;
	push(@constellation, $_);
}
close(FH);

#
#--- heare are names we need to pay attentions
#
@planets = (mercury, venus, earth, mars, jupiter, saturn, neptune, uranus, pluto, moon, titan);

@star_list = (achernar, mira, polaris, algol, aldebaran, rigel, capella, betelgeuse, canopus, sirius, castor, procyon, pollux, regulus, spica, arcturus, antares, vega, altair, deneb, fomalhaut);

@special_list = (ORIONIS, CENTAURI, URSAEMAJORIS, AQUILAE, ANDROMEDAE, HERCULIS, CYGNUS, HYDRA);

#
#---- list of objects with already known coordinates
#
open(FH, "$house_keeping/coord_list");
@sname_list = ();
@obsid_list = ();
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
#---- open the candidate list
#
open(FH, './check_coord');

open(OUT1, '>>./known_coord');
@check_list = ();
OUTER:
while(<FH>){
	chomp $_;
	@atemp = split(/\t/, $_);
	$name  = $atemp[0];
	$obsid = $atemp[1];
	$inst  = $atemp[2];
	$grat  = $atemp[3];
#
#----- remove any appended note from the name of the object
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
		if($sname =~ /$ent/i){
			$ra_test = ${ent.$ent}{ra}[0];
			$dec_test = ${ent.$ent}{dec}[0];
			@rtemp = split(/:/, $ra_test);
			@stemp = split(/\./, $rtemp[2]);
			@ttemp = split(//, $stemp[1]);
			$tcnt = 0;
			foreach(@ttemp){
				$tcnt++;
			}
			@dtemp = split(/:/, $dec_test);
			@etemp = split(/\./, $dtemp[2]);
			@ftemp = split(//, $etemp[1]);
			$fcnt = 0;
			foreach(@ftemp){
				$fcnt++;
			}
			if($rtemp[0] == 99 || $dtemp[0] == 99){
				push(@obsid_list, $obsid);
			}elsif($tcnt < 3 || $fcnt < 3){
				push(@obsid_list, $obsid);
			}else{
				print OUT1 "$obsid\t$inst\t$grat\t";
				print OUT1 "${ent.$ent}{name}[0]\t";
				print OUT1 "${ent.$ent}{ra}[0]\t";
				print OUT1 "${ent.$ent}{dec}[0]\t";
				print OUT1 "${ent.$ent}{dra}[0]\t";
				print OUT1 "${ent.$ent}{ddec}[0]\n";
				push(@obsid_list, $obsid);
			}
			next OUTER;
		}
	}
}
close(OUT1);
close(FH);

open(OUT, '>> ./new_obsid_list');
foreach $ent (@obsid_list){
	print OUT "$ent\n";
}
