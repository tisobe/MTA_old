#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	simbad_query.perl: go to SIMBAD site and retrieve coordinates inf	#
#										#
#	author: t. isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: 04/15/2012							#
#										#
#	THIA SCRIPT MUST HAVE QUER_mta.pm IN WORKING DIRECTORY			#
#										#
#################################################################################

#
#--- read a target name from a file ./tag_name
#
$target = `cat ./tag_name`;
system("rm -rf ./tag_name");

#print "TARGET: ";
#$target = <STDIN>;

#
#---- remove leading and trailing white spaces, and replace all other white space with "%20".
#
chomp $target; 
$target =~ s/^\s*//;
$target =~ s/\s*$//;
$target =~ s/\s+/\%20/g;

#
#--- go to simbad site and get coordinate results
#

$line = 'lynx -source http://simbad.u-strasbg.fr/simbad/sim-id\?output.format=ASCII\&Ident='.$target.'>zout';
system("$line");

open(FH, "zout");
$cchk = 0;
$pchk = 0;
OUTER:
while(<FH>){
    chomp $_;
    if($cchk == 0 && $_ =~ /Coordinates/){
#
#--- the best coordinates appears to top; so check from the top. if not there, go to the next "coodinates"
#
        @atemp = split(/:/, $_);
        @btemp = split(/\s+/, $atemp[1]);
        $ahr   = $btemp[1];
        $amin  = $btemp[2];
        $asec  = $btemp[3];
        $ra    = "$ahr:$amin:$asec";

        $deg   = $btemp[4];
        $min   = $btemp[5];
        $sec   = $btemp[6];
        $dec   = "$deg:$min:$sec";
        $cchk++;
    }
    if($_ =~ /Proper/){
#
#---- checking proper motions
#
        @atemp = split(/:/, $_);
        @btemp = split(/\s+/, $atemp[1]);
        $pra   = $btemp[1];
        $pdec  = $btemp[2];
        if($pra !~ /\d/){
            $pra = 0;
        }
#
#--- if the proper motion is not listed, set them to '0'
#
        if($pdec !~ /\d/){
            $pdec = 0;
        }
        $pchk++;
    }
    if($cchk > 0 && $pchk >0){
        last OUTER;
    }
}

$line = "$ra\t$dec\t$pra\t$pdec";

#print "$target: $line\n";

open(OUT, '>./simbad_out');
print OUT "$line\n";
close(OUT);
