#!/usr/bin/perl 


$house_keeping = './house_keeping/';

$cmd = "/home/ascds/DS.release/bin/dataseeker.pl infile=ds_file outfile=vito2.fits loginFile=$house_keeping/loginfile clobber=yes";

system($cmd);

