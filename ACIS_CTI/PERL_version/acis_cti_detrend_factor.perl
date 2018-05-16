#!/usr/bin/env /usr/local/bin/perl

#################################################################################
#										#
#	detrerend_factor.perl(originally detrend_mn.perl)			#
#	this program computes detrend factor using drop_amp data		#
#										#
# 	the first half is to get data out from archive				#
#	using arc4gl, this script obtains src file for a given data		#
#	and make an avearge of drop_amp value					#
#	this average will be used to detrance ma Ka cti				#
#										#
#	input file: new_entry							#
#		    keep_entry: date from the previous run, but couldn't	#
#		                find a src file					#
#	we also need get_vale scripts in a same directory			#
#										#
#	author: Takashi Isobe (tisobe@cfa.harvard.edu)				#
#										#
#	last update: Apr 15, 2013						#
#										#
#################################################################################

#
#-- if this is a test run, set $comp_test to "test".
#

$comp_test = $ARGV[0];
chomp $comp_test;

#########################################
#--- set directories
#
if($comp_test =~ /test/i){
    $dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list_test';
}else{
    $dir_list = '/data/mta/Script/ACIS/CTI/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
#
#########################################

$dare   =`cat $bin_data/.dare`;
$hakama =`cat $bin_data/.hakama`;
chomp $dare;
chomp $hakama;

#system("cp $exc_dir/Working_dir/test_list       $exc_dir/Working_dir/test_list~");	# make backups
#system("cp $exc_dir/Working_dir/new_entry       $exc_dir/Working_dir/new_entry~");
if($comp_test !~ /test/i){
	system("cp $house_keeping/amp_avg_list $house_keeping/amp_avg_list~");	
}

#
#----- new_entry: today's entry list from plot_cti.perl
#

system("cat $exc_dir/Working_dir/new_entry > $exc_dir/Working_dir/test_list");

#
#---- combine left over and a new list
#	
if($comp_test !~ /test/i){
	system("cat $house_keeping/keep_entry >> $exc_dir/Working_dir/test_list");
}

#
#--- amp_avg_list is a list of detrend factors
#

open(FH,"$house_keeping/amp_avg_list");

$amp_cnt = 0;
@amp_obsid = ();
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/,$_);
	push(@amp_obsid, $atemp[2]);				# we need obsid list from amp_avg_list
	$amp_cnt++;
}
close(FH);

$in_count = 0;
@new_entry = ();
open(FH,"$exc_dir/Working_dir/test_list");

OUTER:
while(<FH>) {							# compare amp_avg_list and today's data and find
	chomp $_;						# data which are not processed yet.
	$obsid =  $_;
	foreach $comp (@amp_obsid){
		if($obsid == $comp){
			next OUTER;
		}
	}
	push(@new_entry, $obsid);				# @new_entry: data list to be processed
	$in_count++;
}
close(FH);

								# if there are new data, go ahead
if($in_count > 0) {
	@new_time_list = sort{$a<=>$b}  @new_entry; 		# here we clean up data. sorted and remove duplicates
	rm_dupl();
	@new_entry = @new_data;					# this is output from rm_dupl();

	$chk = `ls $exc_dir/Working_dir/`;

	if($chk =~ /tempdir/){
		$chk2 = `ls $exc_dir/Working_dir/tempdir/`;
		if($chk2 =~ /fits/){
			system("rm -rf $exc_dir/Working_dir/tempdir/*fits*");	# clean up old data
		}
	}else{
		system("mkdir $exc_dir/Working_dir/tempdir/");
	}

	open(OUT,">$exc_dir/Working_dir/input_line");		# input for arc4gl

	foreach $obsid (@new_entry){
		print OUT "operation=retrieve\n";
		print OUT "dataset=flight\n";
		print OUT "detector=acis\n";
		print OUT "level=1\n";
		print OUT "version=last\n";
		print OUT "filetype=expstats\n";
		print OUT "obsid=$obsid\n";
		print OUT "go\n";
	}
	close(OUT);

#
#	using arc4gl, retreive stat files
#

	system("cd $exc_dir/Working_dir/tempdir/; echo $hakama |arc4gl -U$dare -Sarcocc -i$exc_dir/Working_dir/input_line");

	system("rm -rf $exc_dir/Working_dir/input_line");

	system("gzip -d $exc_dir/Working_dir/tempdir/*.gz");

	$in_list = `ls $exc_dir/Working_dir/tempdir/acisf*stat*.fits*`;
	@tempdir_list = split(/\s+/, $in_list);			# checking whether tempdir_list is empty or not
	@chk_list = ();

	foreach $fits_file (@tempdir_list) {

		@btemp = split(/acisf/, $fits_file);
        	@ctemp = split(/_/, $btemp[1]);
        	$obsid = $ctemp[0];
		push(@chk_list, $obsid);
		                                        	# get a date from the fits file

		system("dmlist $fits_file opt=head outfile=$exc_dir/Working_dir/outfile");

        	open(IN,"$exc_dir/Working_dir/outfile");
        	OUTER:
        	while(<IN>){
                	chomp $_;
                	@atemp = split(/\s+/, $_);
                	if($_ =~ /DATE-OBS/){
                        	$date_obs = $atemp[2];
                        	last OUTER;
                	}
        	}
		close(IN);
        	system("rm -rf  $exc_dir/Working_dir/outfile");

		$infile = "$fits_file".'[cols ccd_id,drop_amp]';
		system("dmlist infile=\"$infile\" opt=data outfile=$exc_dir/Working_dir/ztemp");

		@data  = ();
		$sum   = 0;
		$count = 0;
		open(FH, "$exc_dir/Working_dir/ztemp");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] =~ /\d/ && $atemp[2] =~ /\d/){
				if($atemp[2] == 7){
					push(@data, $atemp[3]);
					$sum += $atemp[3];
					$count++;
				}
			}
		}
		close(FH);
	
		if($comp_test =~ /test/i){
			open(AOUT, ">$data_dir/amp_avg_list");
		}else{
	  		open(AOUT,">>$house_keeping/amp_avg_list"); 		#output into amp_avg_list
		}

       		if($count > 0) {
               		$avg = $sum/$count;
			$norm_avg = $avg * 0.00323;			# new value from cgrant  (03/07/05)
	
               		print AOUT "$date_obs\t$norm_avg\t$obsid\n";
#                	print "$date_obs:       $obsid  $norm_avg\n";
       		}else {
               		print AOUT "$date_obs\t999999\t$obsid\n";
#	               	print "$date_obs:       $obsid  NOT A STANDARD\n";
        	}
        	close(AOUT);
		system("rm -rf $exc_dir/Working_dir/ztemp");
	}
	close(DATIN);

	system("rm -rf  $exc_dir/Working_dir/tempdir");

#
#--- if this is the test case, ignore all following operation
#
	if($comp_test =~ /test/i){
		exit(1);
	}

     	open(BOUT,">$house_keeping/keep_entry");			# find whether any data was not processedw
	OUTER:								# if there are, keep them for the next time
	foreach $new (@new_entry){
		foreach $tmp (@chk_list) {
			if($new eq $tmp){
				next OUTER;
			}
		}
		if($new =~ /\d/){
			print BOUT "$new\n";
		}
	}
	close(BOUT);

	open(FH,"$house_keeping/keep_entry");				# just in a case, clean up keep_entry file
	$l_count = 0;
	@temp_line = ();

	while(<FH>) {
        	chomp $_;
        	push(@temp_line, $_);
        	$l_count++;
	}
	close(FH);

	if($l_count > 0) {
        	$temp = shift(@temp_line);
        	@clean_line = ("$temp");
        	OUTER:
        	foreach $ent (@temp_line){
                	foreach $comp (@clean_line) {
                        	if($comp eq $ent) {
                                	next OUTER;
                        	}
                	}
                	push(@clean_line, $ent);
        	}
	
        	open(FH, ">$house_keeping/keep_entry");
        	foreach $ent (@clean_line) {
               		print FH "$ent\n";
        	}
        	close(FH);
	}
	open(FH,"$house_keeping/amp_avg_list");	# now clean up am_avg_list
	@amp_test = ();
	while(<FH>){
		chomp $_;
		push(@amp_test, $_);
	}
	close(FH);
	@new_time_list = sort{$a<=>$b} @amp_test;
	@new_time_list = reverse(@new_time_list);
       	$first_line = shift(@new_time_list);
        @new_data = ("$first_line");					# since there are often more than one entry
									# for a sane obsid (processed more than once)
        OUTER:								# choose the most recent value
        foreach $line (@new_time_list) {
		@atemp = split(/\t/,$line);
                foreach $comp (@new_data) {
			@btemp = split(/\t/,$comp);
                        if($atemp[2] eq $btemp[2]) {
                                next OUTER;
                        }
                }
                push(@new_data, $line);
        }
	@new_data = reverse(@new_data);

	open(OUT,">$house_keeping/amp_avg_list");			# update am_avg_list
	foreach $ent(@new_data){
		print OUT "$ent\n";
	}
	close(OUT);

	system("sort $house_keeping/amp_avg_list > ./Working_dir/atemp");
	system("mv  ./Working_dir/atemp $house_keeping/amp_avg_list");
}

######################################################
######################################################
######################################################

sub rm_dupl {
        $first_line = shift(@new_time_list);
        @new_data = ("$first_line");

        OUTER:
        foreach $line (@new_time_list) {
                foreach $comp (@new_data) {
                        if($line eq $comp) {
                                next OUTER;
                        }
                }
                push(@new_data, $line);
        }
}


