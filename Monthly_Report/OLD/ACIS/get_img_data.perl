#!/usr/bin/perl

###############################################################################
#	dm_img.perl: obtain acis evt1 file from an archvie (arc4gl) and crate
#		     an combined image file			
#							
#	input: 					
#		list: list of acis evt 1 file
#		pass word:  pass word for archive account for isobe	
#		file name:  output file name			
#			list is a file in a same directory
#			two others are asked when you start this script 
#									
#									
#	Author:	Takashi Isobe (tisobe@cfa.harvard.edu)			
#									
#	Aug 8, 2000	First version					
#       Modified June 2001 BDS to override archive retrieval (-noget option)
########################################################################
my $noget = 0;
if ($ARGV[0] =~ /-noget/) { 
  $noget = 1;
}

if ($noget == 0) {
  $user   = $ARGV[0];
  $hakama = $ARGV[1];				# passwoard

  if($hakama eq '') {
          print "need argument!\n";
          exit 1;
  }
}

@data_list = ();			# opening a list of acis evt1 files
open(FH, "./list");
$check = 0;
while(<FH>) {
        chomp $_;
	@atemp = split(/ /,$_);
	push(@data_list, $atemp[0]);
}
close(FH);

$check = 0;

$dcnt = 0;
$que = 0;
@{data_set.$que} = ();

foreach $fits (@data_list) {		# divide a list to 10 entries each
	if($dcnt < 5) {		# data_set.0 ... data_set.9
#	if($dcnt < 20) {		# data_set.0 ... data_set.9
		push(@{data_set.$que}, $fits);
		$dcnt++;
	}else{
		$que++;
		@{data_set.$que} = ();
		push(@{data_set.$que}, $fits);
		$dcnt = 0;
	}
}
$que++;
		
for($d_set = 0; $d_set < $que; $d_set++) {

        if ($noget == 0) {
          open(OUT, ">./input_line");             # input script for arc4gl
	  foreach $file (@{data_set.$d_set}){
        	  print OUT "operation=retrieve\n";
        	  print OUT "dataset=flight\n";
        	  print OUT "detector=acis\n";
        	  print OUT "level=1\n";
        	  print OUT "filetype=evt1\n";
		  print OUT "filename=$file\n";
        	  print OUT "go\n";
	  }
          close(OUT);

          `echo $hakama |arc4gl -U$user -Sarcocc -iinput_line`;	# here is the arc4gl
        }

	OUT2:
	foreach $infits (@{data_set.$d_set}) {

                print "working  $infits\n";

		@atemp = split(/_evt1/,$infits);
		$head = $atemp[0];
		@gfits = `ls $infits*`;	#just in a case, it is zipped
                #old `gzip -d $gfits`;
                if ($gfits[0] =~ /\.gz$/) {
		  `gzip -d $gfits[0]`;
                  $infits = substr($gfits[0], 0, index($gfits[0], ".gz"));
                }
	
	# here we use dmcopy to create an image fits file

#		$line = "$gfits".'[EVENTS][bin tdetx=2800:5200:1, tdety=1650:4100:1]';
		$line = "$infits".'[EVENTS][bin tdetx=2800:5200:1, tdety=1650:4150:1]';
		#old `rm -f out.fits`;
                if (-e 'out.fits') {unlink 'out.fits';}
                #print "$line\n"; #debug
		`dmcopy "$line" out.fits  option=image clobber=yes`;

                $out_check = 0;
                if (-s 'out.fits') {
                  $out_check = 1;
                }

		#old `ls  > out_check`;		# checking whethr out.fits file is created
		#old open(ZZ,'./out_check');		# if it is not, the fits file is not complte
		#old $out_check = 0;			# and cannot create an image fits file
		#old OUTER:
		#old while(<ZZ>) {
			#old chomp $_;
			#old if($_ eq 'out.fits'){
				#old $out_check = 1;
				#old last OUTER;
			#old }
		#old }
		#old `rm out_check`;

		if($out_check == 0) {
			open(MISS, '>>./incomplete_file');
			print MISS "$infits\n";
			print "A BAD FILE; STOP COMPUTATION: $infits\n";
			close(MISS);
		}else{
			$name = "$head".'_'."img.fits";
			`mv out.fits $name`;
		}
                unlink $infits;
		#old `rm $infits`;
	}
}
close(FH);

