#!/usr/bin/perl 

open(OUT, '>./ds_file');
print OUT "columns=mtahrc..hrcveto_avg\n";
close(OUT);

$house_keeping = './house_keeping/';

$cmd = "/home/ascds/DS.release/bin/dataseeker.pl infile=ds_file outfile=vito.fits loginFile=$house_keeping/loginfile clobber=yes";

system($cmd);

system("rm ./ds_file");
