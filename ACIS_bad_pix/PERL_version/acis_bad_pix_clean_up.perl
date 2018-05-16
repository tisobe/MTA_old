#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
#	acis_bad_pix_clean_up.perl: this cleans up duplicated lines in	#
#				    in ccd and hccd. 			#
#				    this is a temporary measure		#
#									#
#	author: t isobe (tisobe@cfa.harvard.edu)			#
#									#
#	last update: Apr 15, 2013		#
#									#
#########################################################################

#
#--- if this is the test run, ignore this function, and simply exist. 
#

$comp_test = $ARGV[0];
chomp $comp_test;
if($comp_test =~ /test/i){
	exit 1;
}

#######################################
#
#--- setting a few paramters
#

#--- output directory

$dir_list =  "/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list";
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);


#######################################

#
#--- check whether there is enough space
#

system('df -k . > zspace');
open(FH, "./zspace");
while(<FH>){
	chomp $_;
	if($_ =~ /\%/){
		@atemp = split(/\s+/, $_);
		@btemp = split(/\%/, $atemp[4]);
		if($btemp[0] > 98){
                        if($btemp[0] > 98){
                                open(FILE, ">./zwarning");
                                print FILE 'Please check: Bad Pixel Data/',"\n\n" ;
                                print FILE "Due to a disk space, the data was not updated correctly\n";
                                close(FILE);
				system("cat ./zwarning| mailx -s \"Subject: bad pixel data problem detected !!\n \" -r isobe\@head.cfa.harvard.edu  isobe\@head.cfa.harvard.edu ");
                                system("rm  -rf ./zwarning");

				exit 0;
			}
		}
	}
}
close(FH);
system("rm  -rf ./zspace");


$test  = `ls $data_dir/Disp_dir/ccd*`;
$test2 = `ls $data_dir/Disp_dir/hccd*`;

for($iccd = 0; $iccd < 10; $iccd++){
#
#--- warm case
#
	$ccd = "ccd$iccd";
	if($test =~ /$ccd/){
		$file = "$data_dir/Disp_dir/$ccd";
		@save = ();
		open(FH, "$file");
		while(<FH>){
			chomp $_;
			push(@save, $_);
		}
		close(FH);
		@atemp = sort{$a<=>$b} @save;
		$first = shift(@atemp);
		@new   = ($first);
		OUTER:
		foreach $ent (@atemp){
			foreach $comp (@new){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
		}

		open(OUT, ">$file");
		foreach $ent (@new){
			print OUT "$ent\n";
		}
	}
#
#--- hot case;
#
	$ccd = "hccd$iccd";
	if($test =~ /$ccd/){
		$file = "$data_dir/Disp_dir/$ccd";
		@save = ();
		open(FH, "$file");
		while(<FH>){
			chomp $_;
			push(@save, $_);
		}
		close(FH);
		@atemp = sort{$a<=>$b} @save;
		$first = shift(@atemp);
		@new   = ($first);
		OUTER:
		foreach $ent (@atemp){
			foreach $comp (@new){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
		}

		open(OUT, ">$file");
		foreach $ent (@new){
			print OUT "$ent\n";
		}
	}
}

