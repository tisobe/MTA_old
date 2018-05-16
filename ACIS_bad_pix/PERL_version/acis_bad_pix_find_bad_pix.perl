#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;

#################################################################################
#										#
#	acis_bad_pix_find_bad_pix.perl: find bad pixel, hot pixels, 		#
#				and warm columns and plots the results		#
#										#
#	author: t. isobe	(tisobe@cfa.harvard.edu)			#
#	last update:	May 22, 2013						#
#										#
#	input:									#
#		if $ARGV[0] = live: /dsops/ap/sdp/cache/*/acis/*bias0.fits	#
#			otherwse:   *bias0.fits in dir given by $ARGV[0]	#		
#		$hosue_keepign/past_input_data: a list of the past input data	#
#		$house_keeping/Defect/bad_pix_list: known bad pix list		#
#		$house_keeping/Defect/Bad_col_list: known bad col list		#
#	output:									#
#		$web_dir/Defect/CCD*/						#
#			acis*_q*_max: bad pix candidates			#
#			acis*_q*_hot: hot pix candidates			#
#		$data_dir/Disp_dir/  						#
#			all_past_bad_col*: a list of all past bad columns	#
#			all_past_bad_pix*: a list of all past bad pixels	#
#			all_past_hot_pix*: a list of all past hot pixels	#
#			bad_col_cnt*:      a history of # of bad columns	#
#			bad_pix_cnt*:	   a history of # of bad pixels		#
#			ccd*:		   a list of today's bad pixels		#
#			change_ccd*:	   a history of changes of bad pixels   #
#			change_col*:	   a history of changes of bad columns	#
#			change_hccd*:	   a history of changes of hot pixels	#
#			col*:		   a list of today's bad columns	#
#			data_used.*:	   a list of data used for the CCD	#
#			flickering*:	   a list of flickering bad pixels	#
#			flickering_col*:   a list of flickering bad columns	#
#			flickering_col_save* a history of flickering columns	#
#			flickering_save*:  a history of flickering pixels	#
#			hccd*:		   a list of today's hot pixels		#
#			hflickering*:      a list of flickering hod pixels	#
#			hflickering_save*  a history of flickering hot pixels	#
#			hist_ccd*:	   a history of changes of hot pixels	#
#			hot_pix_cnt*:	   a history of # of hot pixels		#
#			imp_bad_col_save:  a history of changes of improved col #
#			imp_bad_pix_save*: a history of changes of improved pix	#
#			imp_ccd*:	   a history of improved pixels		#
#			imp_hccd*:	   a history of improved hot pixels	#
#			imp_hot_pix_save*: a history of improved hot pix cnt	#
#			new_bad_pix_save*: a history of improved bad pix cnt	#
#			new_ccd*:	   a history of appreared bad pix	#
#			new_hccd*:	   a history of appeared hot pixs	#
#			new_hot_pix_save*: a history of appeared hot pix cnt	#
#			today_new_col*:	   a list of today's bad columns	#
#			totally_new*:	   a list of totally new bad pix	#
#			totally_new_col*:  a list of totally new bad cols	#
#		$bias_dir/Bias_save/CCD*/					#
#			quad*:  a list of time bias averge and sigma		#
#		$web_dir/Plot/							#
#			ccd*.gif: a plot of bias background			#
#			hist_ccd*.gif:	a plot of history of # of bad pix	#
#			hist_col*.gif:  a plot of history of # of bad col	#
#			hist_hccd*.gif:	a plot of history of # of hot pix	#
#										#
#										#
#	sub									#
#	----									#
#	get_dir:	find data files from /dspos/ap/sdp/cache		#
#			use daily update (indicated $ARGV[0]: live)		#
#	regroup_data:	read data from a given directory and regroup for the	#
#			next step						#
#	find_ydate:	find day of the year using on axTime3			#
#	int_file_for_day: 	prepare files for analysis, then call 		#
#				extract to find bad pix candidates		#
#	extract:	find bad pixel candidates				#
#	loca_chk:	cimpute a local mean around a givn pix 16x16		#
#	read_bad_pix_list:	read a knwon bad pixel/column list		#
#	rm_prev_bad_data:	rmove known bad pixels/columns from data	#	
#	select_bad_pix:	find bac pix appeared three consecutive files		#
#			actual findings are done in the following sub		#
#	find_bad_pix:	find bad pixels						#
#	add_to_list:	add bad pixels to output data list			#
#	print_bad_pix_data:	print bad pixl list ($web_dir/Disp_dir)		#
#	find_bad_col:	find bad columns					#
#	comp_to_local_avg_col: compute a local average column values		#
#	prep_col:	preparing bad column test				#
#	chk_bad_col:	find and print bad column lists (use the next sub)	#
#	print_bad_col:	print bad column lists					#
#	conv_time:	chnage time format from 1998.1.1 in sec to 		#
#			yyyy:ddd:hh:mm:ss					#
#	chk_old_data:	find data older than 30 days and move to save dir	#
#	cov_time_dom:	change time format from yyyy:ddd to dom			#
#	timeconv1:	chnage sec time formant to yyyy:ddd:hh:mm:ss		#
#	timeconv2:	change: yyyy:ddd form to sec time formart		#
#	today_dom:	find today dom						#
#	print_html:	update a html page for bad piexls			#
#	plot_hist:	plotting history of no. of bad pixel changes		#
#	plot_diff:	plotting routine					#
#	linr_fit:	least sq linear fit 					#
#	mv_old_data:	move old data from an active dir to a save dir		#
#	flickering_check:	check whcih pixels are flickering in the past 	#
#				90 days						#
#	conv_date_form4:	change date format from yy:mm:dd to yy:ydyd	#
#	rm_incomplete_data:	remove incomplete data so that we can fill	#
#				it correctly					#
#	conv_time_dom:	change date from yyyy:ddd to dom			#
#	find_more_bad_pix_info: find additional information about bad pix	#
#	find_flickering:	find flickering pixels				#
#	find_flickering_col:	find flickering cols				#
#	find_all_past_bad_pix:	make a list of all bad pixels in the past	#
#	find_all_past_bad_col:	make a list of all bad columns in the past	#
#	find_totally_new:	find first time bad pixels (call new_pix)	#
#	new_pix:	find first time bad pixels --- main script 		#
#	find_totally_new_col:	find first time bad columns			#
#										#
#################################################################################


$input_type = $ARGV[0];                                 # three different types of input: live, <dir path>, or test
chomp $input_type;       

if($input_type =~ /test/i){
	$comp_test  = 'test';
	$input_type = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/Test_data_save/Test_data/';
}

#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

$lookup   = '/home/ascds/DS.release/data/dmmerge_header_lookup.txt';    # dmmerge header rule lookup table

#--- factor for how may std out from the mean

$factor     = 5.0;
$col_factor = 3.0;
$hot_factor = 1000.0;

#######################################

$file = `ls -d`;					# clearn up the directory
@file = split(/\s+/, $file);				

if($file =~ /Working_dir/){
	system("rm -rf ./Working_dir");
}
system("mkdir ./Working_dir");				# create working dirctory

if($file =~ /param/){
	system("rm -rf ./param");
}
system("mkdir ./param");

if($input_type eq 'live'){
	get_dir();					# this is for the automated case
}else{
	regroup_data();					# this is a test case or the case in which a path to data is given
}

read_bad_pix_list();					# read known bad pixel list and bad col list

$dcnt = 1;

if($dcnt > 0){						# yes we have new data, so let compute
	
	system("rm -rf  $data_dir/Disp_dir/today*");
	for($kn = 0; $kn <= $kdir; $kn++){
		system("rm -rf  ./Working_dir/today*");
		$today_new_bad_pix  = 0;		# these are used to count how many new and improved
		$today_new_bad_pix5 = 0;		# bad pixels appeared today.
		$today_new_bad_pix7 = 0;
		$today_imp_bad_pix  = 0;
		$today_imp_bad_pix5 = 0;
		$today_imp_bad_pix7 = 0;
	
		$today_new_hot_pix  = 0;		# these are used to count how many new and improved
		$today_new_hot_pix5 = 0;		# hot pixels appeared today.
		$today_new_hot_pix7 = 0;
		$today_imp_hot_pix  = 0;
		$today_imp_hot_pix5 = 0;
		$today_imp_hot_pix7 = 0;
	
		$today_new_bad_col  = 0;		# these are used to count how many new and improved
		$today_new_bad_col5 = 0;		# bad columns appeared today.
		$today_new_bad_col7 = 0;
		$today_imp_bad_col  = 0;
		$today_imp_bad_col5 = 0;
		$today_imp_bad_col7 = 0;
	
		int_file_for_day();			# prepare files for analysis
	
		select_bad_pix();			# find bad pix appear three consecutive files
	
####		prep_bad_col();				# preparing bad column test (!!!we do not use this anymore!!!)
	
		add_to_list();				# adding bad pixels to lists
	
		chk_bad_col();				# find and print bad columns
	
		print_bad_col();			# pint bad columns

#		system("perl $bin_dir/mk_front_ccd_tot.perl");
#		system("perl $bin_dir/mk_front_ccd_tot.perl hot");
#		system("perl $bin_dir/mk_front_col_tot.perl");
	
		if($input_type eq 'live'){
			chk_old_data();			# find data older than 30 days (7 days) and move to Save
		}

	}

##	flickering_check('warm');			# check which pixels are flickering in the past 90 days
##	flickering_check('hot');			# check which pixels are flickering in the past 90 days
##	flickering_col();         			# check which cols are flickering in the past 90 days
	find_more_bad_pix_info();			# find additional information about bad pixels

#
#--- plotting of the history is now done by new_plot_set.perl
#

###	plot_hist();					# plotting history of bad pixel increase

	print_html();					# print up-dated html page for bad pixel
}

if($comp_test !~ /test/i){
	mv_old_data();					# move old data from an active dir to a save dir
}

#system("rm -rf ./Working_dir/");



#########################################################
### get_dir: find data files from /dsops/ap/sdp/cache ###
#########################################################

sub get_dir {
	open(FH, "$house_keeping/past_input_data");
	@past_list = ();
	@past_date_list = ();				# get a previous data list
	while(<FH>){
		chomp $_;
		push(@past_list, $_);
		@atemp = split(/\//, $_);
		@btemp = split(/_/, $atemp[5]);
		$year  = $btemp[0];
		$month = $btemp[1];
		$day   = $btemp[2];
		conv_date_form4();
		push(@past_date_list, $date);
	}
	close(FH);

	system("ls /dsops/ap/sdp/cache/*/acis/*bias0.fits > ./Working_dir/zinput");
	@input_list     = ();
	@new_list       = ();				# find a new data candidates
	@new_date_list  = ();
	@new_date_list2 = ();
	open(FH,'./Working_dir/zinput');
	while(<FH>){
		chomp $_;
		push(@input_list, $_);
		
		$old = 0;				# select new data and save
		OUTER:
		foreach $comp (@past_list){
			if($comp eq $_){
				$old = 1;
				last OUTER;
			}
		}
		if($old == 0){
			push(@new_list, $_);
			@atemp = split(/\//, $_);
			@btemp = split(/_/, $atemp[5]);
			$year  = $btemp[0];
			$month = $btemp[1];
			$day   = $btemp[2];
			conv_date_form4();
			push(@new_date_list, $date);
			$dir = "/$atemp[1]/$atemp[2]/$atemp[3]/$atemp[4]/$atemp[5]";
			push(@new_date, $dir);
		}
	}
	close(FH);
	system("mv $house_keeping/past_input_data $house_keeping/past_input_data~");
	system("mv ./Working_dir/zinput $house_keeping/past_input_data");

	@past_date_list = sort{$a<=> $b} @past_date_list;

	@temp = (shift(@past_date_list));		# remove duplicates from the past data
	OUTER:
	foreach $ent (@past_date_list){
        	foreach $comp (@temp){
                	if($comp == $ent){
                        	next OUTER;
                	}
        	}
        	push(@temp, $ent);
	}
	@past_date_list = @temp;

	@new_date_list = sort{$a <=> $b} @new_date_list;

	@temp = (shift(@new_date_list));		# remove duplicates from the new data
	OUTER:
	foreach $ent (@new_date_list){
        	foreach $comp (@temp){
                	if($comp == $ent){
                        	next OUTER;
                	}
        	}
        	push(@temp, $ent);
	}
	@new_date_list = @temp;

	@cnew_list = ();				# select un-processed data
	OUTER:
	foreach $ent (@new_date_list){
		foreach $comp (@past_date_list){
			if($ent == $comp){
				next OUTER;
			}
		}
		push(@cnew_list, $ent);
	}

	$chk_date = shift(@cnew_list);
	$plast_date = pop(@past_date_list);
		

	if(($chk_date ne '') && ($plast_date ne '') && ($chk_date <= $plast_date)){
		$cut_date = $chk_date;

		rm_incomplete_data();		# rm data from database for recomputation
	
		@new_date = ();
		foreach $ent (@input_list){
			@atemp = split(/\//,$ent);
			@btemp = split(/_/, $atemp[5]);
			$year = $btemp[0];
			$month = $btemp[1];
			$day = $btemp[2];
			conv_date_form4();
			
			if($date >= $chk_date){
				$dir = "/$atemp[1]/$atemp[2]/$atemp[3]/$atemp[4]/$atemp[5]";
				push(@new_date, $dir);
			}
		}
			
	}

	@new_date = sort{$a<=>$b} @new_date;
	$dcnt = 0;
	foreach(@new_date){
		$dcnt++;
	}
	$first = shift(@new_date);
	@dir1 = ($first);
	OUTER:
	foreach $ent (@new_date){
		foreach $comp (@dir1){
			if($ent eq $comp){
				next OUTER;
			}
		}
		push(@dir1, $ent);
	}

	open(OUT, '>./Working_dir/today_input_data');
	@bias_bg_comp_list = ();	# this list will be used to compute bias background.
	$kdir = 0;			# find bias0 file names in today's new directories
	OUTER:
	foreach $dir (@dir1){
		$tdy_data = `ls $dir/acis/acis*bias0*`;
		@tyd_data_list = split(/\s+/, $tdy_data);
		$chk = 0;
		@{day_list.$kdir} = ();
		foreach $ent (@tyd_data_list){
			chomp $ent;
			push(@{day_list.$kdir}, $ent);
			push(@bias_bg_comp_list, $ent);
			print OUT "$ent\n";
			$chk++;
		}
		if($chk > 0){
			$kdir++;
		}
	}
	close(OUT);
	if($kdir > 0){
		$kdir--;
	}
}

################################################################
### regroup_data: regroup data for farther analysis          ###
################################################################

sub regroup_data{

	$t_input = `ls $input_type/acisf*bias0.fits`;
	@t_input_list = split(/\s+/, $t_input);
	@bias_bg_comp_list = ();				# this will be used to compute bias bg
        @data = ();
	$dcnt = 0;
        $cnt = 0;
        foreach $ent (@t_input_list){
                chomp $ent;
                push(@data, $ent);
		push(@bias_bg_comp_list, $ent);
                $cnt++;
        }
	
	if($cnt < 1){
		print "There is not bias data in this period; existing\n";
		exit 1;
	}

        find_ydate($data[0]);                                   # chnage date format
        $day_start      = $yday;                                # first date of the data period
	$data_set_start = $time_sec;

        find_ydate($data[$cnt-1]);
        $day_end = $yday;                                       # last date of the data period

        $diff = $day_end - $day_start;
        for($i = 0; $i <= $diff; $i++){
                @{day_list.$i} = ();                            # create arrays for # of dates
        }

        $comp_date = $day_start;
        $kdir = 0;
        foreach $ent (@data){
                find_ydate($ent);
                if($yday == $comp_date){
                        push(@{day_list.$kdir}, $ent);
                }else{
                        $comp_date = $yday;
                        $kdir++;
                        push(@{day_list.$kdir}, $ent);
                }
        }
	if($kdir >= 0){
		$dcnt++;
	}
}

################################################################
### find_ydate: find day of the year                         ###
################################################################

sub find_ydate {
        ($input)  = @_;
        @atemp    = split(/acisf/, $input);
        @btemp    = split(/N/, $atemp[1]);
#	$n_time   = `/home/ascds/DS.release/bin/axTime3 $btemp[0] u s t d`;
	$n_time   = y1999sec_to_ydate($btemp[0]);
        @atemp    = split(/:/, $n_time);
        $yday     = $atemp[1];
	$time_sec = $btemp[0];
}


###########################################################
### int_file_for_day: prepare files for analysis        ###
###########################################################

sub int_file_for_day{

	for($n = 0; $n < 10; $n++){				# loop for ccds: initialization
		@{list.$n}      = ();
		@{todaylist.$n} = ();
		${cnt.$n}       = 0;
	}

	foreach $file (@{day_list.$kn}){			# loop for data of the $kn-th day
		@atemp = split(/acisf/,$file);
		@btemp = split(/N/,$atemp[1]);
		$head  = 'acis'."$btemp[0]";

		timeconv1($btemp[0]);				# time format to e.g. 2002:135:03:42:35	
		$file_time  = $normal_time;			# $normal_time is output of timeconv1
		@ftemp      = split(/:/, $file_time);
		$today_time = "$ftemp[0]:$ftemp[1]";

#
#---  dump the fits header and find informaiton needed (ccd id, readmode)
#
###		system("$op_dir/dmlist infile=$file opt=head outfile=./Working_dir/zdump");
		system("dmlist infile=$file opt=head outfile=./Working_dir/zdump");
		open(FH, './Working_dir/zdump');			
		$ccd_id   = -999;
		$readmode = 'INDEF';
		$date_obs = 'INDEF';
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			if($_ =~ /CCD_ID/){
				$ccd_id      = $atemp[2];
			}elsif($_ =~ /READMODE/){
				$readmode    = $atemp[2];
			}elsif($_ =~ /DATE-OBS/){
				$date_obs    = $file_time;
				@dtemp       = split(/:/,$file_time);
				$dtime       = "$dtemp[0]:$dtemp[1]";
                        }elsif($_ =~ /INITOCLA/){
                                $overclock_a = $atemp[2];
                        }elsif($_ =~ /INITOCLB/){
                                $overclock_b = $atemp[2];
                        }elsif($_ =~ /INITOCLC/){
                                $overclock_c = $atemp[2];
                        }elsif($_ =~ /INITOCLD/){
                                $overclock_d = $atemp[2];
			}
		}
		close(FH);

#
#---  if it is in a timed mode add to process list for the ccd
#		
		if($readmode =~ /^TIMED/i) {
			push(@{todaylist.$ccd_id}, $file);
			${cnt.$ccd_id}++;		
		}
	}

	@warm_data_list     = ();
	@hot_data_list      = ();
	for($im = 0; $im < 10; $im++){					# loop for ccds

		@{today_warm_list.$im}    = ();
		@{today_hot_list.$im}     = ();
#
#--- tdycnt is used as an indicator whether there are any data
#
		${tdycnt.$im} = ${cnt.$im};
		if(${cnt.$im} > 0){
			open(FOUT, ">>$data_dir/Disp_dir/data_used.$im");	# record for data used
			foreach $file (@{todaylist.$im}){
				@ntemp = split(/acisf/, $file);
				print FOUT "$date_obs: acisf$ntemp[1]\n";
			}
			close(FOUT);

			$first = shift(@{todaylist.$im});		
			if(${cnt.$im} > 1){				
				@atemp = split(/acisf/,$first);		
				@btemp = split(/N/,$atemp[1]);
				$head  = 'acis'."$btemp[0]";
				$htime = $btemp[0];

				timeconv1($btemp[0]);
				$file_time = $normal_time;
				@ftemp     = split(/:/, $file_time);
				$date_obs  = "$ftemp[0]:$ftemp[1]";		
#
#---  change fits file format to LONG
#
				$line ="$first".'[opt type=i4,null=-9999]';
				system("dmcopy infile=\"$line\"  outfile=./Working_dir/comb.fits clobber='yes'");
#
#--- merge all data into one
#
				foreach $pfile (@{todaylist.$im}){
					$line ="$pfile".'[opt type=i4,null=-9999]';

					system("dmcopy \"$line\"  ./Working_dir/temp.fits clobber='yes'");

					system("dmimgthresh infile=./Working_dir/temp.fits outfile=./Working_dir/temp2.fits cut=\"0:4000\" value=0 clobber=yes");
					open(OUT, '>./Working_dir/zadd');			
					print OUT "./Working_dir/temp2.fits,0,0\n";
					close(OUT);

					system("dmimgcalc infile=./Working_dir/comb.fits infile2=./Working_dir/temp2.fits outfile=./Working_dir/comb2.fits operation=add clobber=yes");
					system("mv ./Working_dir/comb2.fits ./Working_dir/comb.fits");
				}

			}else{
				@atemp = split(/acisf/,$first);		
				@btemp = split(/N/,$atemp[1]);
				$head  = 'acis'."$btemp[0]";
				$htime = $btemp[0];

				@ftemp    = split(/:/, $file_time);
				$date_obs = "$ftemp[0]:$ftemp[1]";
				$line     = "$first".'[opt type=i4,null=-9999]';

				system("dmcopy \"$line\"  ./Working_dir/temp.fits clobber='yes'");

				system("dmimgthresh infile=./Working_dir/temp.fits outfile=./Working_dir/comb.fits cut=\"0:4000\" value=0 clobber=yes");
			}
			
			$ccd_dir = "$house_keeping/Defect/CCD"."$im";
			system("rm -rf  ./Working_dir/out*.fits");

			system("dmcopy \"./Working_dir/comb.fits[x=1:256]\" ./Working_dir/out1.fits clobber='yes'");
			$q_file       = 'out1.fits';
			$min_file     = "$head".'_q1_min';            # setting a file name lower
			$max_file     = "$head".'_q1_max';            # setting a file name upper
			$hot_max_file = "$head".'_q1_hot';            # setting a file name hot
			$c_start      = 0;                            # starting column
			$xlow         = 1;
			$xhigh        = 256;
			extract();                                    # sub to extract pixels
			system("rm -rf  ./Working_dir/out1.fits");         # outside of acceptance range

			system("dmcopy \"./Working_dir/comb.fits[x=257:512]\" ./Working_dir/out2.fits clobber='yes'");
			$q_file       = 'out2.fits';
			$min_file     = "$head".'_q2_min';
			$max_file     = "$head".'_q2_max';
			$hot_max_file = "$head".'_q2_hot';
			$c_start      = 256;
			$xlow         = 257;
			$xhigh        = 512;
			extract();
			system("rm -rf  ./Working_dir/out2.fits");

			system("dmcopy \"./Working_dir/comb.fits[x=513:768]\" ./Working_dir/out3.fits clobber='yes'");
			$q_file       = 'out3.fits';
			$min_file     = "$head".'_q3_min';
			$max_file     = "$head".'_q3_max';
			$hot_max_file = "$head".'_q3_hot';
			$c_start      = 512;
			$xlow         = 513;
			$xhigh        = 768;
			extract();
			system("rm -rf  ./Working_dir/out3.fits");

			system("dmcopy \"./Working_dir/comb.fits[x=769:1024]\" ./Working_dir/out4.fits clobber='yes'");
			$q_file       = 'out4.fits';
			$min_file     = "$head".'_q4_min';
			$max_file     = "$head".'_q4_max';
			$hot_max_file = "$head".'_q4_hot';
			$c_start      = 768;
			$xlow         = 769;
			$xhigh        = 1024;
			extract();
			system("rm -rf  ./Working_dir/out4.fits");
#
#--- removing known bad pixels and bad columns
#
			@today_bad_list = @{today_warm_list.$im};
			rm_prev_bad_data();
	
			@today_bad_list = @{today_hot_list.$im};
			rm_prev_bad_data();
		}

	}
}


###############################################################
### extract: find bad pixel candidates                  #######
###############################################################

sub extract {
	open(UPPER, ">>$ccd_dir/$max_file");		# create data file; it could be empty
	close(UPPER);					# at the end, but it will be used for 
	open(HOT,">>$ccd_dir/$hot_max_file");		# bookkeeping later
	close(HOT);

	system("rm -rf  ./Working_dir/zout");
###        system("$op_dir/dmlist ./Working_dir/$q_file opt=array > ./Working_dir/zout");
        system("dmlist ./Working_dir/$q_file opt=array > ./Working_dir/zout");
        open(FH, './Working_dir/zout');
        while(<FH>){
                chomp $_;
                @ctemp         = split(/\s+/, $_);
                if($ctemp[3] =~ /\d/ && $ctemp[4] =~ /\d/){
                        $x             = $ctemp[3];
                        $y             = $ctemp[4];
                        $val[$x][$y]   = $ctemp[6];
                }
        }

#
#--- find bad cloumns
#
        for($i = 1;  $i <= 256; $i++){
                $sum[$i]    = 0;
                $sum2[$i]   = 0;
                $cnt[$i]    = 0;
        }
        for($i = 1; $i <= 256; $i++){
                for($j = 1; $j <= 256; $j++){
                        $sum[$i] += $val[$i][$j];
                        $sum2[$i] += $val[$i][$j] * $val[$i][$j];
                        $cnt[$i]++;
                }
        }

        find_bad_col();

#
#--- devide the quad to 8x32 areas so that we can compare the each pix to a local average
#
        for($ry = 0;$ry < 32; $ry++){
                $ybot = 32*$ry + 1;
                $ytop = $ybot + 31;
                OUTER3:
                for($rx = 0; $rx < 8; $rx++){
                        $xbot = 32*$rx + 1;
                        $xtop = $xbot + 31;
                        $sum = 0;
                        $sum2 = 0;
                        $count = 0;
                        for($ix = $xbot; $ix<=$xtop; $ix++){
                                OUTER2:
                                for($iy = $ybot; $iy<=$ytop; $iy++){
                                        $sum  += $val[$ix][$iy];
                                        $sum2 += $val[$ix][$iy] * $val[$ix][$iy];
                                        $count++;
                                }
                        }
                        if($count < 1){
                                next OUTER3;
                        }
                        $mean = $sum/$count;                    # here is the local mean
                        $std  = sqrt($sum2/$count - $mean * $mean);
                        $warm = $mean + $factor*$std;           # define warm pix
                        $hot  = $mean + $hot_factor;            # define hot pix
#
#--- now find bad pix candidates
#
                        for($ix = $xbot; $ix<=$xtop; $ix++){
                                OUTER2:
                                for($iy = $ybot; $iy<=$ytop; $iy++){
#
#--- warm pix candidates
#
                                        if($val[$ix][$iy] > $warm && $val[$ix][$iy] < $hot){
                                                local_chk();    # recompute a local mean
                                                if($val[$ix][$iy] > $cwarm){
                                                        open(UPPER, ">>$ccd_dir/$max_file");
                                                        print UPPER "$ix\t$iy\t$val[$ix][$iy]\t$date_obs\t$cmean\t$cstd\n";
                                                        close(UPPER);
                                                        push(@warm_list,"$ccd_dir/$max_file");
                                                }
#
#--- hot pix candidates
#
                                        }elsif($val[$ix][$iy] >= $hot){
                                                local_chk();
                                                if($val[$ix][$iy] > $chot){
                                                        open(HOT,">>$ccd_dir/$hot_max_file");
                                                        print HOT "$ix\t$iy\t$val[$ix][$iy]\t$date_obs\t$cmean\t$cstd\n";
                                                        close(HOT);
                                                        push(@hot_list,"$ccd_dir/$hot_max_file");
                                                }
                                        }
                                }
                        }
                }
        }
#
#--- checking duplicates, if there are, remove it.
#
	$first = shift(@warm_list);
	@new_list = ("$first");
	OUTER:
	foreach $ent (@warm_list){
		foreach $comp (@new_list){
			if($ent eq $comp){
				next OUTER;
			}
		}
		push(@new_list, $ent);
	}
	open(OUT,">>./Working_dir/today_warm_list");
	foreach $ent (@new_list){
		if($ent ne ''){
			print OUT "$ent\n";
			push(@{today_warm_list.$im},$ent);
		}
	}
	close(OUT);

	$first = shift(@hot_list);
	@new_list = ("$first");
	OUTER:
	foreach $ent (@hot_list){
		foreach $comp (@new_list){
			if($ent eq $comp){
				next OUTER;
			}
		}
		push(@new_list, $ent);
	}
	open(OUT,">>./Working_dir/today_hot_list");
	foreach $ent (@new_list){
		if($ent ne ''){
			print OUT "$ent\n";
			push(@{today_hot_list.$im},$ent);
		}
	}
	close(OUT);
}


#########################################################################
### local_chk: compute a local mean around a givn pix. 16x16 area    ####
#########################################################################

sub local_chk {

	$x1 = $ix - 8;
	$x2 = $ix + 8;
	if($x1 < 0){				# check the case, when the pixel is
		$x2 += abs($x1);		# located at the coner, and cannot
		$x1 = 1;			# take 16x16 around it.
	}elsif($x2 > 256){			# if that is the case, shift the area
		$x1 -= ($x2 - 256);
		$x2 = 256;
	}
	$y1 = $iy - 8;
	$y2 = $iy + 8;
	if($y1 < 0){
		$y2 += abs($y1);
		$y1 = 1;
	}elsif($y2 > 256){
		$y1 -= ($y2 - 256);
		$y2 = 256;
	}
	$csum = 0;
	$csum2 = 0;
	$ccount = 0;
	for($xx = $x1; $xx <= $x2; $xx++){
		OUTER2:
		for($yy = $y1; $yy <= $y2; $yy++){
			$cval = $val[$xx][$yy];
			if($cval == -999){
				next OUTER2;
			}
			$csum += $cval;
			$csum2 += $cval * $cval;
			$ccount++;
		}
	}
	if($ccount > 0){
		$cmean = $csum/$ccount;
		$cstd =sqrt($csum2/$ccount - $cmean * $cmean);
		$cwarm = $cmean + $factor*$cstd;
		$chot  = $cmean +$hot_factor;
	}
}
	
############################################################################
###    read_bad_pix_list: read an existing bad pixel/column list	####
############################################################################

sub read_bad_pix_list{
	for($i = 0; $i < 10; $i++) {
		$name  = 'col_ccd'."$i";	# column #      for bad columns
		$name2 = 'col_ccd_rs'."$i";     # starting row #
		$name3 = 'col_ccd_rf'."$i";     # ending row #
		@{$name}  = ();		  	# easy way to change array names
		@{$name2} = ();
		@{$name3} = ();

		$name  = 'pix_ccd_x'."$i";      # column #      for bad pixels
		$name2 = 'pix_ccd_x'."$i";      # row #
		@{$name}  = ();
		@{$name2} = ();
	}

	open(FH, "$house_keeping/Defect/bad_col_list");      # a bad column list
	while(<FH>) {
		chomp $_;
		@atemp = split(//,$_);
		if($atemp[0] =~ /\d/) {
			@atemp = split(/:/,$_);
			$name  = 'col_ccd'."$atemp[0]";
			$name2 = 'col_ccd_rs'."$atemp[0]";
			$name3 = 'col_ccd_rf'."$atemp[0]";
			push(@{$name}, $atemp[1]);
			push(@{$name2},$atemp[2]);
			push(@{$name3},$atemp[3]);
		}
	}
	close(FH);

	open(FH, "$house_keeping/Defect/bad_pix_list");      # a bad pixel list
	while(<FH>) {
		chomp $_;
		@atemp = split(//,$_);
		if($atemp[0] =~ /\d/) {
			@atemp = split(/:/,$_);
			$name  = 'pix_ccd_x'."$atemp[0]";
			$name2 = 'pix_ccd_y'."$atemp[0]";
			push(@{$name}, $atemp[2]);
			push(@{$name2},$atemp[3]);
		}
	}
	close(FH);
}

####################################################################
####  rm_prev_bad_data: removing data in the list from the data####
####################################################################

sub rm_prev_bad_data {
	$bad_data = 'col_ccd'."$im";	   		# bad column list
	$bad_data_rs = 'col_ccd_rs'."$im";		# $im is ccd id from sub extract
	$bad_data_rf = 'col_ccd_rf'."$im";

	$bad_pix_x = 'pix_ccd_x'."$im";			# bad pixel list
	$bad_pix_y = 'pix_ccd_y'."$im";

	foreach $file (@today_bad_list) {
		@ntemp = split(/q/,$file);
		@mtemp = split(/_/,$ntemp[1]);
		$tquad = $mtemp[0] - 1;			# checking quad (and subtract 1)

		open(TEMP, ">./Working_dir/ztemp");
		open(FH, "$file");
		$zchk = 0;

		OUTER:
		while(<FH>) {
			chomp $_;
			@atemp = split(/\s+/,$_);	# check bad column

			if($atemp[1] > 1022){	
				next OUTER;
			}

			$atemp[0] = $atemp[0] + 256*$tquad;
			$rcnt = 0;
			foreach $comp (@{$bad_data}){		# check with known bad columns
				if($comp eq $atemp[0]
				&& ${$bad_data_rs}[$rcnt] <= $atemp[1]
				&& ${$bad_data_rf}[$rcnt] >= $atemp[1]){
					next OUTER;
				}
				$rcnt++;
			}

			$rcnt = 0;		       # check bad pixel
			foreach $comp (@{$bad_pix_x}){
				if($comp == $atemp[0]
				&& ${$bad_pix_y}[$rcnt] == $atemp[1]){
					next OUTER;
				}
				$rcnt++;
			}
					# if data is not in known bad pixel/column list
					# print out x y, value, time, mean and std of the area of obs
					# of the pixel

			print TEMP "$_\n";
			$zchk++;
		}
		close(FH);
		close(TEMP);

		system("rm -rf  $file");
		system("mv ./Working_dir/ztemp $file");
	}
}


##########################################################################
### select_bad_pix: find bad pix appears three consecutive files      ####
###                 actual finding is done in sub find_bd_pix	      ####
##########################################################################

sub select_bad_pix{
	
#
#---- read warm and hot pixel candidate file list; separate by CCDs
#
	for($ix = 0; $ix < 10; $ix++){
		@{today_warm_list.$ix} = ();
		@{today_hot_list.$ix}  = ();
	}

	open(FH, './Working_dir/today_warm_list');
	while(<FH>){
		chomp $_;
		@atemp = split(/CCD/, $_);
		@btemp = split(/\//, $atemp[1]);
		@ctemp = split(/acis/, $_);
		$ent = 'acis'."$ctemp[1]";
		$ix = $btemp[0];
		push(@{today_warm_list.$ix}, $ent);
	}
	close(FH);
	
	open(FH, './Working_dir/today_hot_list');
	while(<FH>){
		chomp $_;
		@atemp = split(/CCD/, $_);
		@btemp = split(/\//, $atemp[1]);
		@ctemp = split(/acis/, $_);
		$ent = 'acis'."$ctemp[1]";
		$ix = $btemp[0];
		push(@{today_hot_list.$ix}, $ent);
	}
	close(FH);

	for($sccd = 0; $sccd < 10; $sccd++){
		$tccd = 'CCD'."$sccd";
		$temp_file = `ls $house_keeping/Defect/$tccd`;
		@temp_file_list = split(/\s+/, $temp_file);

		@dquadmx1 = ();				# quad ind for warm pix
		@dquadmx2 = ();
		@dquadmx3 = ();
		@dquadmx4 = ();
		@dquadht1 = ();				# quad ind for hot pix
		@dquadht2 = ();
		@dquadht3 = ();
		@dquadht4 = ();
		$dmcnt1   = 0;
		$dmcnt2   = 0;
		$dmcnt3   = 0;
		$dmcnt4   = 0;
		$dhcnt1   = 0;
		$dhcnt2   = 0;
		$dhcnt3   = 0;
		$dhcnt4   = 0;

		foreach $ent (@temp_file_list){
#
#--- separate the data into each quad.
#
			chomp $_;
			@atemp = split(/_q/,$ent);
			if($atemp[1] eq '1_max'){	# warm pix
				push(@dquadmx1,$ent);
				$dmcnt1++;
			}elsif($atemp[1] eq '2_max'){
				push(@dquadmx2,$ent);
				$dmcnt2++;
			}elsif($atemp[1] eq '3_max'){
				push(@dquadmx3,$ent);
				$dmcnt3++;
			}elsif($atemp[1] eq '4_max'){
				push(@dquadmx4,$ent);
				$dmcnt4++;
			}elsif($atemp[1] eq '1_hot'){	# hot pix
				push(@dquadht1,$ent);
				$dhcnt1++;
			}elsif($atemp[1] eq '2_hot'){
				push(@dquadht2,$ent);
				$dhcnt2++;
			}elsif($atemp[1] eq '3_hot'){
				push(@dquadht3,$ent);
				$dhcnt3++;
			}elsif($atemp[1] eq '4_hot'){
				push(@dquadht4,$ent);
				$dhcnt4++;
			}
		}
#
#---- WARM PIXELS
#	
		@equadmx1 = ();
		@equadmx2 = ();
		@equadmx3 = ();
		@equadmx4 = ();
		$emcnt1 = 0;
		$emcnt2 = 0;
		$emcnt3 = 0;
		$emcnt4 = 0;

		foreach $line (@{today_warm_list.$sccd}){
			@etemp = split(/_q/,$line);
			if($etemp[1] eq '1_max'){
				push(@equadmx1,$line);
				$emcnt1++;
			}elsif($etemp[1] eq '2_max'){
				push(@equadmx2,$line);
				$emcnt2++;
			}elsif($etemp[1] eq '3_max'){
				push(@equadmx3,$line);
				$emcnt3++;
			}elsif($etemp[1] eq '4_max'){
				push(@equadmx4,$line);
				$emcnt4++;
			}
		}
	
		for($qno = 1; $qno < 5; $qno++){	# cycle quad 1 to 4
			$gtemp = 'dquadmx'."$qno";
			@dname = @{$gtemp};
			$gtemp = 'dmcnt'."$qno";
			$dcnt  = ${$gtemp};
			$gtemp = 'equadmx'."$qno";
			@ename = @{$gtemp};
			$gtemp  = 'emcnt'."$qno";
			$ecnt = ${$gtemp};
#
#--- specify a file from today's list, and find two previous data list.
#--- if there is not, drop from the warm pix file list
#
			for($i = 0; $i < $ecnt; $i++){
				$file3 = $ename[$i];		
				$ccnt = 0;			
				OUTER:				
				foreach $comp (@dname){		
					if($file3 eq $comp){	
						last OUTER;
					}
					$ccnt++;
				}
#
#--- if there are three files find a warm pix
#
				if($ccnt > 1){		
					$file2 = $dname[$ccnt-1];
					$file1 = $dname[$ccnt-2];
					$out_file = 'warm_data_list';

					find_bad_pix();		# check three files to find bad pix
				}
			}
		}

#
#--- HOT PIXELS
#

		@equadht1 = ();
		@equadht2 = ();
		@equadht3 = ();
		@equadht4 = ();
		$emcnt1 = 0;
		$emcnt2 = 0;
		$emcnt3 = 0;
		$emcnt4 = 0;

		foreach $line (@{today_hot_list.$sccd}){
			@atemp = split(/\//, $line);
			if($atemp[2] eq "$tccd"){
				@etemp = split(/_q/,$line);
				if($etemp[1] eq '1_hot'){
					push(@equadht1,$atemp[3]);
					$emcnt1++;
				}elsif($etemp[1] eq '2_hot'){
					push(@equadht2,$atemp[3]);
					$emcnt2++;
				}elsif($etemp[1] eq '3_hot'){
					push(@equadht3,$atemp[3]);
					$emcnt3++;
				}elsif($etemp[1] eq '4_hot'){
					push(@equadht4,$atemp[3]);
					$emcnt4++;
				}
			}
		}
	
		for($qno = 1; $qno < 5; $qno++){	# cycle quad 1 to 4
			$gtemp = 'dquadht'."$qno";
			@dname = @{$gtemp};
			$gtemp = 'dmcnt'."$qno";
			$dcnt  = ${$gtemp};
			$gtemp = 'equadht'."$qno";
			@ename = @{$gtemp};
			$gtemp  = 'emcnt'."$qno";
			$ecnt = ${$gtemp};
#
#--- specify a file from today's list, and find two previous data list.
#--- if there is not, drop from the hot pix file list
#
			for($i = 0; $i < $ecnt; $i++){
				$file3 = $ename[$i];		
				$ccnt = 0;			
				OUTER:				
				foreach $comp (@dname){		
					if($file3 eq $comp){	
						last OUTER;
					}
					$ccnt++;
				}
#
#--- if there are three files find a hot pix
#
				if($ccnt > 1){			
					$file2 = $dname[$ccnt-1];	
					$file1 = $dname[$ccnt-2];
					$out_file = 'hot_data_list';

					find_bad_pix();		# check 3 files for hot pix
				}
			}
		}
	}
}

###########################################################################
### find_bad_pix:  find bad pixels                                     ####
###########################################################################

sub find_bad_pix{


	@x1    = ();
	@y1    = ();
	@line1 = ();
	$cnt1  = 0;

	open(FH,"$house_keeping/Defect/$tccd/$file1");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/,$_);
		push(@x1,$atemp[0]);
		push(@y1,$atemp[1]);
		push(@line1,$_);
		$cnt1++;
	}
	close(FH);
	
	@x2    = ();
	@y2    = ();
	@line2 = ();
	$cnt2  = 0;

	open(FH,"$house_keeping/Defect/$tccd/$file2");
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/,$_);
		push(@x2,$atemp[0]);
		push(@y2,$atemp[1]);
		push(@line2,$_);
		$cnt2++;
	}
	close(FH);
#
#--- comparing first two files to see whether there are same pixels listed
#--- if they do, save the information $cnt_s will be > 0 if the results are positive
#
	@x_save    = ();			
	@y_save    = ();		
	@line_save = ();	
	$cnt_s     = 0;		

	OUTER:
	for($i1 = 0; $i1 <= $cnt1; $i1++){
		for($i2 = 0; $i2 <= $cnt2; $i2++){
			if($x1[$i1] == $x2[$i2] && $y1[$i1] == $y2[$i2] && $x1[$i1] ne ''){
				push(@x_save, $x1[$i1]);
				push(@y_save, $y1[$i1]);
				push(@line_save,$line1[$i1]);
				$cnt_s++;
				next OUTER;
			}
		}
	}

	if($cnt_s > 0){
		@x3    = ();
		@y3    = ();
		@line3 = ();
		$cnt3  = 0;

		open(FH,"$house_keeping/Defect/$tccd/$file3");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/,$_);
			push(@x3,$atemp[0]);
			push(@y3,$atemp[1]);
			push(@line3,$_);
			$cnt3++;
		}
		close(FH);
#
#--- here we compare the pix listed in first two files to those of the third file
#
		@x_conf    = ();	
		@y_conf    = ();	
		@line_conf = ();
#
#--- if the results are positive, $cnt_f > 0
#
		$cnt_f  = 0;		
		OUTER:
		for($i1 = 0; $i1 <= $cnt_s; $i1++){
			for($i3 = 0; $i3 <= $cnt3; $i3++){
				if($x_save[$i1] == $x3[$i3] && $y_save[$i1] == $y3[$i3]
					&& $x_save[$i1] ne ''){
					push(@x_conf, $x_save[$i1]);
					push(@y_conf, $y_save[$i1]);
					push(@line_conf, $line_save[$i1]);
					$cnt_f++;
					next OUTER;
				}
			}
		}

		if($cnt_f > 0){		# put the warm pixel information into $out_file
			for($ip = 0; $ip <= $cnt_f; $ip++){
				@atemp    = split(/\s+/,$line_conf[$ip]);
				@btemp    = split(/T/,$atemp[3]);
				@ctemp    = split(/-/,$btemp[0]);
				@dtemp    = split(/:/,$btemp[1]);
				$modtime1 = "$ctemp[0]"."$ctemp[1]"."$ctemp[2]";
				$modtime  = "$modtime1".'.'."$dtemp[0]"."$dtemp[1]"."$dtemp[2]";
				$qno1     = $qno - 1;

				if($x_conf[$ip] =~ /\d/){
					push(@{$out_file}, "$tccd:$qno1:$modtime:$x_conf[$ip]:$y_conf[$ip]");
				}
			}
		}
	}

	$first    = shift(@{$out_file});		# remove duplicated lines
	@new_data = ("$first");

	OUTER:
	foreach $ent (@{$out_file}){
		foreach $comp (@new_data){
			if($ent eq $comp){
				next OUTER;
			}
		}
		push(@new_data,$ent);
	}
	@{$out_file} = @new_data;
}


#################################################################
### add_to_list: adding bad pixels to lists                  ####
#################################################################

sub add_to_list {

#
#--- find out which data are currently in the output directory
#
	$temp_wdir = `ls $data_dir/Disp_dir/ccd*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@dir_ccd  = ();
	foreach $ent (@temp_wdir_list){
		if($ent !~ /cnt/){
			push(@dir_ccd, $ent);
		}
	}
	$temp_wdir = `ls $data_dir/Disp_dir/hccd*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@dir_hccd  = ();
	foreach $ent (@temp_wdir_list){
		if($ent !~ /cnt/){
			push(@dir_hccd, $ent);
		}
	}
	$temp_wdir = `ls $data_dir/Disp_dir/col*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@dir_col  = ();
	foreach $ent (@temp_wdir_list){
		if($ent !~ /cnt/){
			push(@dir_col, $ent);
		}
	}
	$temp_wdir = `ls $data_dir/Disp_dir/hcol*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@dir_hcol  = ();
	foreach $ent (@temp_wdir_list){
		if($ent !~ /cnt/){
			push(@dir_hcol, $ent);
		}
	}
#
#--- if today* lists are there,
#
	$temp_wdir = `ls $data_dir/Disp_dir/today*ccd*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);

	foreach $ent (@temp_wdir_list){
		if(${tdycnt.$dtemp[1]} > 0){
			system("rm -rf  $data_dir/Disp_dir/$ent");
		}
	}
#
#---  warm pix case
#
	@in_file = @warm_data_list;
	
	$nchk = 0;
	foreach (@in_file){
		$nchk++;
	}
	if($nchk > 0){
		for($it = 0; $it < 10; $it++){
			@{temp_ccd.$it} = ();
			${winuse.$it} = 0;
		}
		foreach $ent (@in_file){
			@dat_line = split(/:/, $ent);
			@dtemp = split(/CCD/, $dat_line[0]);
			$iccd = $dtemp[1];
			$quad = $dat_line[1];
			$xpos = $dat_line[4] + 256*$quad;
			$ypos = $dat_line[5];
			$line = "$xpos.$ypos";
			push(@{temp_ccd.$iccd},$line);
			${winuse.$iccd}++;
		}

		$switch = 'warm';
		print_bad_pix_data();			# print new output files
	}
#
#--- hot pix case
#
	@in_file = @hot_data_list;
	$nchk = 0;
	foreach (@in_file){
		$nchk++;
	}
	if($nchk > 0){
		for($it = 0; $it < 10; $it++){
			@{temp_ccd.$it} = ();
			${hinuse.$it} = 0;
		}
		foreach $ent (@in_file){
			@dat_line = split(/:/, $ent);
			@dtemp = split(/CCD/, $dat_line[0]);
			$iccd = $dtemp[1];
			$quad = $dat_line[1];
			$xpos = $dat_line[4] + 256*$quad;
			$ypos = $dat_line[5];
			$line = "$xpos.$ypos";
			push(@{temp_ccd.$iccd},$line);
			${hinuse.$iccd}++;
		}

		$switch = 'hot';
		print_bad_pix_data();
	}
}

##############################################################
### print_bad_pix_data: pinring out bad data list          ###
##############################################################

sub print_bad_pix_data{
#
#--- set today's date again and find dom
#
	if($input_type =~ /live/){
		($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
		$today_year = $uyear + 1900;
		$uyday++;
		$date_obs2  = "$today_year:$uyday";
		$dom        = ch_ydate_to_dom($date_obs2);
	}else{
		@atemp      = split(/:/, $today_time);
		if($atemp[1]   =~ /^0/){
			$atemp[1] =~ s/^0//;
		}
		$date_obs2  = "$atemp[0]:$atemp[1]";
		$dom        = ch_ydate_to_dom($today_time);
	}
	
	OUTER:
	for($ip = 0; $ip < 10; $ip++){
		system("rm -rf  $data_dir/Disp_dir/ccd$ip");
##		if(${tdycnt.$ip} == 0){
##			next OUTER;				# if there is no data for this date
##		}						# skip this ccd
#
#--- warm pixel case
#
		if($switch eq 'warm'){
#
#--- read the previous bad pix history list
#
			open(IN, "$data_dir/Disp_dir/hist_ccd$ip");
			@past_data = ();
			$ptot      = 0;
			while(<IN>){
				chomp $_;
				push(@past_data, $_);
				$ptot++;
			}
			close(IN);
#
#--- print out today's bad pix, and prepare to add that to the history list
#
			open(OUT2, ">$data_dir/Disp_dir/ccd$ip");

			$pline =  "$dom<>$date_obs2<>";
			$chk   = 0;

			if(${tdycnt.$ip} > 0){
				$first = shift(@{temp_ccd.$ip});
				@new   = ($first);
				CHK:
				foreach $chk1 (@{temp_ccd.$ip}){
					foreach $comp (@new){
						if($chk1 eq $comp){
							next CHK;
						}
					}
					push(@new, $chk1);
				}

				foreach $ent (@new){
					@pos   = split(/\./, $ent);
					if($pos[0] =~ /\d/ && $pos[1] =~ /\d/){
						$pline = "$pline".":($pos[0],$pos[1])";
						print OUT2 "$pos[0]\t$pos[1]\n";	
						$chk++;
					}
				}
			}
			close(OUT2);

			if($chk == 0){
				$pline = "$pline".':';
			}

			$chk = 0;
			@temp_save = ();
			OUTER2:
			for($i = 0; $i < $ptot; $i++){
				@atemp = split(/<>/, $past_data[$i]);
				if($dom == $atemp[0]){
					if($past_data[$i] eq $pline){
						$chk = -1;
						last OUTER2;
					}
					push(@temp_save, $pline);
					$chk++;
				}else{
					push(@temp_save, $past_data[$i]);
				}
			}
			if($chk > 0){
				@past_data = @temp_save;
			}
			if($chk == 0){
				push(@past_data, $pline);
				$chk++;
			}
			if($chk > 0){
#				$max = $dom + 100;
#				for($k = 0; $k < $max; $k++){
#					@bdate[$k]   = 'na';
#					@bpix_cnt[$k] = 0;
#					@npix_cnt[$k] = 0;
#					@ipix_cnt[$k] = 0;
#				}
				@temp = sort{$a<=>$b} @past_data;
				open(TEMP, ">$data_dir/Disp_dir/hist_ccd$ip");
				$k1 = 0;
				foreach $ent (@temp){
					print TEMP "$ent\n";
#					@gtemp = split(/<>/, $ent);
#					@htemp = split(/:/,   $gtemp[2]);
#					$tcnt = 0;
#					foreach $ent (@htemp){
#						if($ent ne ''){
#							$tcnt++;
#						}
#					}
#					$bdate[$k1]    = "$gtemp[0]<>$gtemp[1]";;
#					$bpix_cnt[$k1] = $tcnt;
#					$k1++;
				}
				close(TEMP);

#				open(OUT3, ">$data_dir/Disp_dir/imp_ccd$ip");
#				open(OUT4, ">$data_dir/Disp_dir/new_ccd$ip");
#				open(OUT5, ">$data_dir/Disp_dir/change_ccd$ip");
#				for($i = 1; $i <= $ptot; $i++){
#					$j = $i - 1;
#					@atemp = split(/<>/, $temp[$j]);
#					@btemp = split(/:/,   $atemp[2]);
#	
#					@ctemp = split(/<>/, $temp[$i]);
#					@dtemp = split(/:/,   $ctemp[2]);
	
#
#--- create improved pixel list
#
#					@imp_save = ();
#					OUTER3:
#					foreach $ent (@btemp){
#						if($ent eq ''){
#							next OUTER3;
#						}
#						foreach $comp (@dtemp){
#							if(($comp ne '') && ($ent eq $comp)){
#								next OUTER3;
#							}
#						}
#						push(@imp_save, $ent);
#					}
#					print OUT3 "$atemp[0]<>$atemp[1]<>";
#					$k2 = 0;
#					foreach $ent (@imp_save){
#						print OUT3 ":$ent";
#						$k2++;
#					}
#					print OUT3 "\n";
#					$ipix_cnt[$i] = $k2;
#
#--- create new bad pixel list
#
#					@new_save = ();
#					OUTER4:
#					foreach $ent (@dtemp){
#						if($ent eq ''){
#							next OUTER4;
#						}
#						foreach $comp (@btemp){
#							if(($comp ne '') && ($ent eq $comp)){
#								next OUTER4;
#							}
#						}
#						push(@new_save, $ent);
#					}
#					print OUT4 "$atemp[0]<>$atemp[1]<>";
#					$k3 = 0;
#					foreach $ent (@new_save){
#						print OUT4 ":$ent";
#						$k3++;
#					}
#					print OUT4 "\n";
#					$npix_cnt[$i] = $k3++;
#
#--- make a file for display
#
#					print OUT5 "$atemp[0]<>$atemp[1]\n";
#					print OUT5 "\tNew: ";
#					foreach $ent (@new_save){
#						print OUT5 "$ent ";
#					}
#					print OUT5 "\n";
#					print OUT5 "\tImp: ";
#					foreach $ent (@imp_save){
#						print OUT5 "$ent ";
#					}
#					print OUT5 "\n";
#				}
#				close(OUT3);
#				close(OUT4);
#				close(OUT5);
#
#--- print out counts of total bad pix, new bad pix, and disappeared bad pix
#
#				$name = 'ccd'."$ip".'_cnt';
#				open(OUT6, ">$data_dir/Disp_dir/$name");
#				for($k = 0; $k < $ptot; $k++){
#					print OUT6 "$bdate[$k]<>";
#					print OUT6 "$bpix_cnt[$k]:";
#					print OUT6 "$npix_cnt[$k]:";
#					print OUT6 "$ipix_cnt[$k]\n";
#				}
#				close(OUT6);
#

			}
#
#---- hot pixel case
#
		}elsif($switch eq 'hot'){
			$name = "hccd$ip";

			$date_obs2 = $date_obs;
			$date_obs2 =~ s/#Date://;
			$date_obs2 =~ s/\s+//;
			$dom       = ch_ydate_to_dom($date_obs2);

			$name = "ccd$ip";	
			open(IN, "$data_dir/Disp_dir/hist_hccd$ip");
			@past_data = ();
			$ptot      = 0;
			while(<IN>){
				chomp $_;
				push(@past_data, $_);
				$ptot++;
			}
			close(IN);
			open(OUT2, ">$data_dir/Disp_dir/hccd$ip");

			$pline =  "$dom<>$date_obs2<>";

			$first = shift(@{temp_ccd.$ip});
			@new   = ($first);
			CHK:
			foreach $chk1 (@{temp_ccd.$ip}){
				foreach $comp (@new){
					if($chk1 eq $comp){
						next CHK;
					}
				}
				push(@new, $chk1);
			}

			foreach $ent (@new){
				@pos = split(/\./,$ent);
				$pline = "$pline".":($pos[0],$pos[1])";
				print OUT2 "$pos[0]\t$pos[1]\n";	
			}

			close(OUT2);
			$chk = 0;
			@temp_save = ();
			OTUER2:
			for($i = 0; $i < $ptot; $i++){
				@atemp = split(/<>/, $past_data[$i]);
				if($dom == $atemp[0]){
					if($past_data[$i] eq $pline){
						$chk = -1;
						last OUTER2;
					}
					push(@temp_save, $pline);
					$chk++;
				}else{
					push(@temp_save, $past_data[$i]);
				}
			}
			if($chk > 0){
				@past_data = @temp_save;
			}
			if($chk == 0){
				push(@past_data, $pline);
				$chk++;
			}
			if($chk > 0){
				$max = $dom + 100;
				for($k = 0; $k < $max; $k++){
					@bdate[$k]   = 'na';
					@bpix_cnt[$k] = 0;
					@npix_cnt[$k] = 0;
					@ipix_cnt[$k] = 0;
				}
				push(@past_data, $pline);
				@temp = sort{$a<=>$b} @past_data;
				open(TEMP, ">$data_dir/Disp_dir/hist_hccd$ip");
				$k1 = 0;
				foreach $ent (@temp){
					print TEMP "$ent\n";
					@gtemp = split(/<>/, $ent);
					@htemp = split(/:/,   $gtemp[2]);
					$tcnt = 0;
					foreach (@htemp){
						$tcnt++;
					}
					$bdate[$k1]    = "$gtemp[0]<>$gtemp[1]";
					$bpix_cnt[$k1] = $tcnt;
					$k1++;
				}
				close(TEMP);

				open(OUT3, ">$data_dir/Disp_dir/imp_hccd$ip");
				open(OUT4, ">$data_dir/Disp_dir/new_hccd$ip");
				open(OUT5, ">$data_dir/Disp_dir/change_hccd$ip");
				for($i = 1; $i <= $ptot; $i++){
					$j = $i - 1;
					@atemp = split(/<>/, $temp[$j]);
					@btemp = split(/:/,   $atemp[2]);
	
					@ctemp = split(/<>/, $temp[$i]);
					@dtemp = split(/:/,   $ctemp[2]);
	
#
#--- create improved pixel list
#
					@imp_save = ();
					OTUER3:
					foreach $ent (@btemp){
						if($ent eq ''){
							next OUTER3;
						}
						foreach $comp (@dtemp){
							if($ent eq $comp){
								next OUTER3;
							}
						}
						push(@imp_save, $ent);
					}
					print OUT3 "$atemp[0]<>$atemp[1]";
					$k2 = 0;
					foreach $ent (@imp_save){
						print OUT3 ":$ent";
						$k2++;
					}
					print OUT3 "\n";
					$ipix_cnt[$i] = $k2;
#
#--- create new bad pixel list
#
					@new_save = ();
					OTUER4:
					foreach $ent (@dtemp){
						if($ent eq ''){
							next OUTER4;
						}
						foreach $comp (@btemp){
							if($ent eq $comp){
								next OUTER4;
							}
						}
						push(@new_save, $ent);
					}
					print OUT4 "$atemp[0]<>$atemp[1]<>";
					$k3 = 0;
					foreach $ent (@new_save){
						print OUT4 ":$ent";
						$k3++;
					}
					print OUT4 "\n";
					$npix_cnt[$i] = $k3++;
#
#--- make a file for display
#
					print OUT5 "$atemp[0]<>$atemp[1]\n";
					print OUT5 "\tNew: ";
					foreach $ent (@new_save){
						print OUT5 "$ent ";
					}
					print OUT5 "\n";
					print OUT5 "\tImp: ";
					foreach $ent (@imp_save){
						print OUT5 "$ent ";
					}
				}
				close(OUT3);
				close(OUT4);
				close(OUT5);
#
#--- print out counts of total bad pix, new bad pix, and disappeared bad pix
#
				$name = 'hccd'."$ip".'_cnt';
				open(OUT6, ">$data_dir/Disp_dir/$name");
				for($k = 0; $k < $ptot; $k++){
					print OUT6 "$bdate[$k]<>";
					print OUT6 "$b_pix_cnt[$k]:";
					print OUT6 "$n_pix_cnt[$k]:";
					print OUT6 "$i_pix_cnt[$k]\n";
				}
				close(OUT6);
			}
		}
	}
}

#######################################################################
###  find_bad_col: find bad columns                                 ###
#######################################################################

sub find_bad_col{
        $asum  = 0;
        $asum2 = 0;
        $fcnt  = 0;
#
#--- make an average of averaged column value; average of column is caluculated in sub extract.
#
        for($icol = 1; $icol <= 256; $icol++){		
                if($cnt[$icol] > 0){			
                        $avg[$icol] = $sum[$icol]/$cnt[$icol];
                        $asum  += $avg[$icol];
                        $asum2 += $avg[$icol] * $avg[$icol];
                        $fcnt++;
                }
        }
	if($fcnt > 0){
        	$cavg  = $asum/$fcnt;
        	$std   = sqrt($asum2/$fcnt - $cavg * $cavg);
        	$limit = $cavg + $col_factor * $std;			# setting limits
	
        	$outdir_name  = "$house_keeping/Defect/CCD"."$ccd_id".'/'."$head".'_col';
	
        	open(OUT,">>$outdir_name");
        	for($icol = 1; $icol <= 256; $icol++){
#
#--- compare to a global average
#
                	if($avg[$icol] > $limit){		

				comp_to_local_avg_col();	# compare to a local average

				if($avg[$icol] > $local_limit){
					$pind = 0;
#
#--- compare to existing bad col
#
				 	OUTER:
					foreach $bcol (@{col_ccd.$ccd_id}){
						if($icol == $bcol){
							$pind++;
							last OUTER;	
						}
					}
					if($pind == 0){
						$icol += $xlow;
                        			print OUT  "$icol\n";
					}
				}
                	}					# add to the bad column list
        	}
        	close(OUT);
	}
#
#--- clean up the duplicated lines
#
	open(IN, "$outdir_name");
	@test = ();
	while(<IN>){
		chomp $_;
		push(@test, $_);
	}
	close(IN);
	@temp  = sort{$a<=>$b} @test;
	$first = shift(@temp);
	@new   = ($first);
	OUTER:
	foreach $tent (@temp){
		foreach $comp (@new){
			if($tent eq $comp){
				next OUTER;
			}
		}
		push(@new, $tent);
	}
	open(OUT, ">$outdir_name");
	foreach $tent (@new){
		print OUT "$tent\n";
	}
	close(OUT);	
}

################################################################################
### comp_to_local_avg_col: compute  a local average col values          ########
################################################################################

sub comp_to_local_avg_col{
	$llow  = $icol - 5;			# setting a local range
	$lhigh = $icol + 5;

	if($llow < 1){				# setting lower range
		$diff  = $xlow - $llow;
		$lhigh += $diff;
		$llow   = $xlow;
	}

	if($lhigh > 256){			# setting higher range
		$diff =  $lhigh - $xhigh;
		$llow -= $diff;
		$lhigh = $xhigh;
	}

	$lsum = 0;
	$lsum2 = 0;
	$lcnt = 0;
	for($j = $llow; $j <= $lhigh; $j++){
		$lsum += $avg[$j];
		$lsum2 += $avg[$j]*$avg[$j];
		$lcnt++;
	}
	$local_limit = $limit;
	if($lcnt > 0){
		$lavg = $lsum/$lcnt;
		$lstd = sqrt($lsum2/$lcnt - $lavg*$lavg);
		$local_limit = $lavg + $col_factor*$lstd;
	}
}
		

################################################################################
### prep_col: preparing bad col test                                         ###
################################################################################

sub prep_bad_col {
#
#--- check the name of the last new_col lists
#
	$temp_wdir = `ls $data_dir/Disp_dir/today_new_col*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@today_bad_col = ();
	foreach $ent (@temp_wdir_list){
		@ctemp = split(/col/, $ent);
		push(@today_bad_col, $ctemp[1]);
	}
#
#--- check the name of the last imp_col lists
#
	$temp_wdir = `ls $data_dir/Disp_dir/today_imp_col*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@today_imp_col = ();
	foreach $ent (@temp_wdir_list){
		@ctemp = split(/col/, $ent);
		push(@today_imp_col, $ctemp[1]);
	}
#
#--- check the name of the last col lists
#
	$temp_wdir = `ls $data_dir/Disp_dir/col*`;
	@temp_wdir_list = split(/\s+/, $temp_wdir);
	@tcol_list = ();
	foreach $ent (@temp_wdir_list){
		@ctemp = split(/col/, $ent);
		push(@tcol_list, $ctemp[1]);
	}
#
#--- clean up old memories
#
	for($m = 0; $m < 10; $m++){
		@{col_data.$m} = ();
		${col_cnt.$m} = 0;
	}
#
#--- if there were bad_col lists
#
	foreach $ent (@today_bad_col){		
		if(${tdycnt.$ent} > 0){
			system("cat $data_dir/Disp_dir/today_new_col$ent >> $data_dir/Disp_dir/new_col$ent");
			system("rm  -rf  $data_dir/Disp_dir/today_new_col$ent");
		}
	}

	foreach $ent (@today_imp_col){
		if(${tdycnt.$ent} > 0){
			system("cat $data_dir/Disp_dir/today_imp_col$ent >> $data_dir/Disp_dir/imp_col$ent"); 
			system("rm -rf   $data_dir/Disp_dir/today_imp_col$ent");
		}
	}
#
#--- read the last col list data
#
	foreach $ent (@tcol_list){		
		if(${tdycnt.$ent} > 0){
			@{col_data.$ent} = ();
			${col_cnt.$ent} = 0;
			open(IN, "$data_dir/Disp_dir/col$ent");

			OUTER:
			while(<IN>){
				chomp $_;
				@ctemp = split(//, $_);
				if($ctemp[0] eq '#'){
					next OUTER;
				}
				push(@{col_data.$ent}, $_);
				${col_cnt.$ent}++;
			}
			close(IN);

			system("rm -rf  $data_dir/Disp_dir/col$ent");
		}
	}
}

################################################################################
### chk_bad_col: find and print bad columns                                  ###
################################################################################


sub chk_bad_col {

	OUTER:
	for($k = 0; $k < 10; $k++){
		if(${tdycnt.$k} == 0){			# only when today's data exists
			next OUTER;
		}

		$temp_wdir = `ls $house_keeping/Defect/CCD$k/*col`;
		@temp_wdir_list = split(/\s+/, $temp_wdir);
		@col_list = ();
		$kcnt = 0;
		foreach $ent (@temp_wdir_list){
			push(@col_list, $ent);
			$kcnt++;
		}
#
#--- if there are 3 bad col lists, use them to find bad col candidates
#
		if( $kcnt > 2){				
			$n = 0;				
			$start = $kcnt - 1;
			$end   = $kcnt - 3;
			for($m = $start; $m >= $end; $m--){
				@{list.$n} = ();
				if($m == $start){
					@atemp = split(/acis/, $col_list[$m]);
					@btemp = split(/_/, $atemp[1]);
					$time_form1 = $btemp[0];

					conv_time();		  # getting readable time format

					@ttemp = split(/:/, $time_form2);
					$today_time = "$ttemp[0]:$ttemp[1]";
				}
#
#--- bad_col of the m-th file
#
				open(FH, "$col_list[$m]");
				while(<FH>){
					chomp $_;
					push(@{list.$n}, $_);
				}
				close(FH);
				$n++;
			}
			@two_list = ();
			$test = 0;
#
#--- compare the first two lists
#
			OUTER:
			foreach $ent (@{list.0}){
				foreach $comp (@{list.1}){
					if($ent == $comp){
						push(@two_list, $ent);
						$test++;
						next OUTER;
					}
				}
			}
			
			@{bad_col_list.$k} = ();
			${bcnt.$k} = 0;
#
#--- if there are candidates, try on the thrid file
#
			if($test > 0){				
				$chk = 0;			
				@temp_list = ();
				OUTER:			
				foreach $ent (@two_list){
					foreach $comp (@{list.2}){
						if($ent == $comp){
							push(@temp_list, $ent);
							$chk++;
							next OUTER;
						}
					}
				}
#
#--- remove duplicates
#
				if($chk > 0){			
					$first = shift(@temp_list);
					${bcnt.$k}++;
					@new = ($first);
					@{bad_col_list.$k} = @new;
					OUTER:
					foreach $ent (@temp_list){
						foreach $comp (@new){
							if($ent == $comp){
								next OUTER;
							}
						}
						push(@new, $ent);
						push(@{bad_col_list.$k}, $ent);
						${bcnt.$k}++;
					}
				}
			}
		}
	}
}

########################################################################################
### print_bad_col: print out bad column list                                         ###
########################################################################################

sub print_bad_col{

#
#--- find dom
#
	$date_obs2 = $date_obs;
	$date_obs2 =~ s/#Date://;
	$date_obs2 =~ s/\s+//;
	@atemp = split(/:/, $date_obs2);
	if($atemp[1] =~ /^0/){
			$atemp[1] =~ s/^0//;
	}
	$date_obs2 = "$atemp[0]:$atemp[1]";
	$dom       = ch_ydate_to_dom($date_obs2);

	OUTER:
	for($k = 0; $k < 10; $k++){

##		if(${tdycnt.$k} == 0){			# only when today's data exists
##			next OUTER;
##		}

		if(${bcnt.$k} == 0){
			open(OUTW, ">$data_dir/Disp_dir/col$k");
			close(OUTW);

			open(OUTW, ">>$data_dir/Disp_dir/hist_col$k");
			$nline = "$dom<>$date_obs2<>:";
			print OUTW "$nline\n";
			close(OUTW);

##			open(IN, "$data_dir/Disp_dir/hist_col$k");
##			$last_line = '';
##			while(<IN>){
##				chomp $_;
##				$last_list = $_;
##			}
##			close(IN);
##			@atemp = split(/<>:/, $last_line);
##
##			open(OUTW, ">>$data_dir/Disp_dir/imp_col$k");
##			$nline = "$dom<>$date_obs2<>:$atemp[1]";
##			print OUTW "$nline\n";
##			close(OUTW);
##
##			open(OUTW, ">>$data_dir/Disp_dir/new_col$k");
##			$nline = "$dom<>$date_obs2<>:";
##			print OUTW "$nline\n";
##			close(OUTW);
##
##			open(OUTW, ">$data_dir/Disp_dir/col$k");
##			close(OUTW);

#
#--- if there are new bad cols, then...
#
		}else{
#
#--- if there are currently bad cols, then...
#
####			if(${col_cnt.$k} > 0){
##				@bad_col_new = ();
##				@bad_col_imp = ();
##				@col_hold    = ();
##				$chk_col_new = 0;
##				$chk_col_imp = 0;
##				$chk_col_hld = 0;

##				OUTER:
##				foreach $ent (@{bad_col_list.$k}){
##					@ctemp = split(//, $ent);
##					if($ctemp[0] eq '#'){
##						next OUTER;
##					}
##					foreach $comp (@{col_data.$k}){
##						if($ent == $comp){
##							push(@col_hold, $ent);
##							$chk_col_hld++;
##							next OUTER;
##						}
##					}
##					push(@bad_col_new, $ent);
##					$chk_col_new++;
##				}
##
##				OUTER:
##				foreach $ent (@{col_data.$k}){
##					@ctemp = split(//, $ent);
##					if($ctemp[0] eq '#'){
##						next OUTER;
##					}
##					foreach $comp (@{bad_col_list.$k}){
##						if($ent == $comp){
##							next OUTER;
##						}
##					}
##					push(@bad_col_imp, $ent);
##					$chk_col_imp++;
##				}
#
#---history file for col
#
				open(IN, "$data_dir/Disp_dir/hist_col$k");
				@tline = ();
				$tcnt  = 0;
				$last  = '';
				while(<IN>){
					chomp $_;
					push(@tline, $_);
					$last = $_;
					$tcnt++;
				}
				close(IN);
				@atemp    = split(/<>:/, $last);
				@last_ent = split(/:/,   $atemp[1]);
#
#--- if the new entry is older than the previously entired data, ignore
#
				@btemp    = split(/<>/,  $last);
				if($dom < $btemp[0]){
					next OUTER;
				}

				$current_col_no = 0;
				@new_col        = ();
				@imp_col        = ();
				$nline          = "$dom<>$date_obs2<>";
				$col_name       = "$data_dir".'/Disp_dir/col'."$k";

				open(OUT2,">$col_name");

				$chk = 0;
				OUTER2:
				foreach $ent (@{bad_col_list.$k}){
#					if($ent !~ /\d/ || $ent eq ''){
#						next OUTER2;
#					}
					if($ent =~ /\d/){
						$nline = "$nline:"."$ent";
						print OUT2 "$ent\n";
						$current_col_no++;
	
						foreach $comp (@last_ent){
							if($ent eq $comp){
								next OUTER2;
							}
						}
						push(@new_col, $ent);
						$chk++;
					}	
				}
				close(OUT2);
				if($chk == 0){
					$nline = "$nline:";
				}else{
					$chk2 = 0;
					@ctemp = split(//, $nline);
					foreach (@ctemp){
						$chk2++;
					}
					if($ctemp[$chk2 -1] eq ':'){
						$cline = '';
						for($i = 0; $i < $chk2 -1; $i++){
							$cline = "$cline"."$ctemp[$i]";
						}
						$nline = $cline;
					}
				}

##				OTUER2:
##				foreach $test (@last_ent){
##					foreach $comp (@{bad_col_list.$k}){
##						if($test eq $comp){
##							next OTUER2;
##						}
##					}
##					push(@imp_col, $test);
##				}
#
#---- printing a new bad col
#
##				$sline = "$dom<>$date_obs2<>";
##				foreach $ent (@new_col){
##					$sline = "$sline".":$ent";
##				}
##				$out_line = "$data_dir".'/Disp_dir/new_col'."$k";
##				open(OUT3, ">>$out_line");
##				print OUT3 "$sline\n";
##				close(OUT3);
#
#--- printing a imp col
#
##				$sline = "$dom<>$date_obs2<>";
##				foreach $ent (@imp_col){
##					$sline = "$sline".":$ent";
##				}
##				$out_line = "$data_dir".'/Disp_dir/imp_col'."$k";
##				open(OUT3, ">>$out_line");
##				print OUT3 "$sline\n";
##				close(OUT3);
##					
#
#--- cleaning up col history list
#

				push(@tline, $nline);
				@sorted_tline = sort{$a<=>$b} @tline;
				@cleaned = ("$sorted_tline[0]");
				OUTER:
				for($i = 1; $i <= $tcnt; $i++){
					if($sorted_tline[$i] eq $sorted_tline[$i-1]){
						next OUTER;
					}
					push(@cleaned, $sorted_tline[$i]);
				}
				$name = "hist_col$k";
				open(OUT, ">$data_dir/Disp_dir/$name");
				foreach $ent (@cleaned){
					print OUT "$ent\n";
				}
				close(OUT);

#
#---history file for new bad col
#
##				$name = "new_col$k";
##				open(IN, "$data_dir/Disp_dir/$name");
#
#--- cleaning up col history list
#
##				@tline = ();
##				$tcnt  = 0;
##				while(<IN>){
##					chomp $_;
##					push(@tline, $_);
##					$tcnt++;
##				}
##				close(IN);
##				$nline = "$dom<>$date_obs2<>";
##				foreach $ent (@{bad_col_new}){
##					$nline = "$nline:"."$ent";
##				}
##				push(@tline, $nline);
##				@sorted_tline = sort{$a<=>$b} @tline;
##				@cleaned = ("$sorted_tline[0]");
##				OUTER:
##				for($i = 1; $i <= $tcnt; $i++){
##					if($sorted_tline[$i] eq $sorted_tline[$i-1]){
##						next OUTER;
##					}
##					push(@cleaned, $sorted_tline[$i]);
##				}
##				$name = "new_col$k";
##				open(OUT, ">$data_dir/Disp_dir/$name");
##				foreach $ent (@cleaned){
##					print OUT "$ent\n";
##				}
##				close(OUT);
##
##
#
#---history file for disappeared  bad col
#
##				$name = "imp_col$k";
##				open(IN, "$data_dir/Disp_dir/$name");
##				@tline = ();
##				$tcnt  = 0;
##				while(<IN>){
##					chomp $_;
##					push(@tline, $_);
##					$tcnt++;
##				}
##				close(IN);
##				$nline = "$dom<>$date_obs2<>";
##				foreach $ent (@{bad_col_imp}){
##					$nline = "$nline:"."$ent";
##				}
##				push(@tline, $nline);
##				@sorted_tline = sort{$a<=>$b} @tline;
##				@cleaned = ("$sorted_tline[0]");
##				OUTER:
##				for($i = 1; $i <= $tcnt; $i++){
##					if($sorted_tline[$i] eq $sorted_tline[$i-1]){
##						next OUTER;
##					}
##					push(@cleaned, $sorted_tline[$i]);
##				}
##				open(OUT, ">$data_dir/Disp_dir/imp_col$k");
##				foreach $ent (@cleaned){
##					print OUT "$ent\n";
##				}
##				close(OUT);
#
#---- bad col count history
#
##				$name = "col$k".'_cnt';
##				open(IN, "$data_dir/Disp_dir/$name");
##				@tline = ();
##				$tcnt  = 0;
##				while(<IN>){
##					chomp $_;
##					push(@tline, $_);
##					$tcnt++;
##				}
##				close(IN);
##				$nline = "$dom<>$date_obs2<>$current_col_no".":$chk_col_new:$chk_col_imp";
##				$nline = "$dom<>$date_obs2<>$current_col_no";
##				push(@tline, $nline);
##				@sorted_tline = sort{$a<=>$b} @tline;
##				@cleaned = ("$sorted_tline[0]");
##				OUTER:
##				for($i = 1; $i <= $tcnt; $i++){
##					if($sorted_tline[$i] eq $sorted_tline[$i-1]){
##							next OUTER;
##					}
##					push(@cleaned, $sorted_tline[$i]);
##				}
##				open(OUT, ">$data_dir/Disp_dir/$name");
##				foreach $ent (@cleaned){
##					print OUT "$ent\n";
##				}
##				close(OUT);
#######			}
		}
	}
}

########################################################################
### convert time formart: change time format to yyyy:dddd:hh:mm:ss  ####
########################################################################

sub conv_time{
#	$time_form2 = `/home/ascds/DS.release/bin/axTime3 $time_form1 u s t d`;
	$time_form2 = y1999sec_to_ydate($time_form1);
}


#################################################################################
### chk_old_data: find data older than 30 days (7 days) and move to Save      ###
#################################################################################

sub chk_old_data{
	$day30 = 2592000;
	$day7  = 604800;

        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $today_year = $uyear + 1900;
                $uyday++;
                $today  = "$today_year:$uyday".":00:00:00";
#		$today_chk = `/home/ascds/DS.release/bin/axTime3 $today t d u s`;
		$today_chk = ydate_to_y1998sec($today);
        }else{
                $date_obs2  = $today_time;
                $today  = "$today_time".":00:00:00";
#		$today_chk = `/home/ascds/DS.release/bin/axTime3 $today t d u s`;
		$today_chk = ydate_to_y1998sec($today);
        }

	
	$month_ago = $today_chk - $day30;
#	$week_ago  = $today_chk - $day7;

	for($k = 0; $k < 10; $k++){
		$temp_wdir = `ls $house_keeping/Defect/CCD$k/*`;
		@temp_wdir_list = split(/\s+/, $temp_wdir);
		foreach $ent (@temp_wdir_list){
			@atemp = split(/acis/, $ent);
			@btemp = split(/_/, $atemp[1]);
			if($btemp[0] < $month_ago){
#			if($btemp[0] < $week_ago){
###				system("mv $ent $old_dir/Old_data/CCD$k/.");
###				system("gzip $old_dir/Old_data/CCD$k/$atemp[1]");
			}
		}
	}
}

################################################################
### cov_time_dom: change date (yyyy:ddd) to dom             ####
################################################################

sub conv_time_dom {
	($input_time) = @_;
	@atemp = split(/:/, $input_time);
	$tyear = $atemp[0];
	$tyday = $atemp[1];

	$totyday = 365*($tyear - 1999);
	if($tyear > 2000){
		$totyday++;
	}
	if($tyear > 2004){
		$totyday++;
	}
	if($tyear > 2008){
		$totyday++;
	}
	if($tyear > 2012){
		$totyday++;
	}

	$today_dom = $totyday + $tyday - 202;
}

################################################################
### timeconv1: chnage sec time formant to yyyy:ddd:hh:mm:ss ####
################################################################

sub timeconv1 {
	($time) = @_;
#	$normal_time = `/home/ascds/DS.release/bin/axTime3 $time u s t d`;
	$normal_time = y1999sec_to_ydate($time);
}

################################################################
### timeconv2: change: yyyy:ddd form to sec time formart    ####
################################################################

sub timeconv2 {
	($time) = @_;
#	$sec_form_time = `/home/ascds/DS.release/bin/axTime3 $time t d u s`;
	$sec_form_time = ydate_to_y1998sec($time);
}

################################################################
### today_dom: find today dom				    ####
################################################################

sub find_today_dom{

	($hsec, $hmin, $hhour, $hmday, $hmon, $hyear, $hwday, $hyday, $hisdst)= localtime(time);

	if($hyear < 1900) {
		$hyear = 1900 + $hyear;
	}
	$month = $hmon + 1;
	#$hyday++;

	if ($hyear == 1999) {
		$dom = $hyday - 202 + 1;		#  hyday adjustment---keep this way
	}elsif($hyear >= 2000){
		$dom = $hyday + 163 + 1 + 365 * ($hyear - 2000);
		if($hyear > 2000) {
			$dom++;
		}
		if($hyear > 2004) {
			$dom++;
		}
		if($hyear > 2008) {
			$dom++;
			$dom++;
		}
		if($hyear > 2012) {
			$dom++;
		}
	}
}

################################################################
### print_html: print up-dated html page for bad pixel      ####
################################################################

#
#--- html 5 conformed Oct 9, 2012
#
sub print_html{

	find_today_dom();

	open(OUT,">$web_dir/mta_bad_pixel_list.html");

        print OUT "<!DOCTYPE html> \n";
        print OUT " \n";
        print OUT "<html> \n";
        print OUT "<head> \n";
	print OUT "	   <meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
        print OUT "        <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cxc.cfa.harvard.edu/mta/REPORTS/Template/mta.css\" /> \n";
        print OUT "        <style  type='text/css'>\n";
        print OUT "        table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
        print OUT "        td{text-align:center;padding:8px}\n";
        print OUT "        a:link {color:#00CCFF;}\n";
        print OUT "        a:visited {color:yellow;}\n";
        print OUT "        span.nobr {white-space:nowrap;}\n";
        print OUT "        </style>\n";

        print OUT "        <title>ACIS Bad Pixel List  </title> \n";
        print OUT " \n";
        print OUT "        <script> \n";
        print OUT "                function WindowOpener(imgname) { \n";
        print OUT "                        msgWindow = open(\"\",\"displayname\",\"toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=1260,height=980,resize=no\"); \n";
        print OUT "                        msgWindow.document.clear(); \n";
        print OUT "                        msgWindow.document.write(\"<html><title>Trend plot:   \"+imgname+\"</title>\"); \n";
        print OUT "                        msgWindow.document.write(\"<body bgcolor='black'>\"); \n";
        print OUT "                        msgWindow.document.write(\"<img src='./Plots/\"+imgname+\"' border =0 ><p></p></body></html>\") \n";
        print OUT "                        msgWindow.document.close(); \n";
        print OUT "                        msgWindow.focus(); \n";
        print OUT "                } \n";
        print OUT "        </script> \n";
        print OUT " \n";
        print OUT "</head> \n";
        print OUT "<body> \n";
        print OUT "\n";

        print OUT "<h1 style='text-align:center;mergin-left:auto;mergin-right:auto'>ACIS Bad Pixel List</h1> \n";

        print OUT "<h2 style='text-size:110%;text-align:center;mergin-left:auto;mergin-right:auto'>Updated: ";
        print OUT "$hyear-$month-$hmday  ";
        $hyday++;                                       # hyday starts from day 0 in localtime(time) function
        print OUT "(DOY: $hyday / DOM: $dom) </h2>\n";;
        print OUT "<hr /> \n";

        $tot_warm = 0;
        $tot_hot  = 0;
        $tot_col  = 0;
        for($kccd = 0; $kccd < 10; $kccd++){
                $tot_warm += ${tot_new_pix.$kccd};
                $tot_hot  += ${tot_new_hot.$kccd};
                $tot_col  += ${tot_new_col.$kccd};
        }


        print OUT '<h3>Previously unknown bad pixels/columns appeared in the last 14 days:</h3> ',"\n";

        print OUT "<table border=1 style='border-width:2px;font-size:90%'> \n";
#
#---- warm pix
#
        print OUT '<tr><th>Warm Pixels</th>',"\n";
        if($tot_warm > 0){
                print OUT '<td>&#160;</td></tr>',"\n";
                for($kccd = 0; $kccd < 10; $kccd++){
                        if(${tot_new_pix.$kccd} > 0){
                                print OUT "<th>CCD $kccd</th>","\n";
                                print OUT '<td>';
                                open(IN,"$data_dir/Disp_dir/totally_new$kccd");
                                while(<IN>){
                                        chomp $_;
                                        print OUT "$_\n";
                                }

                                close(IN);
                                print OUT '</td></tr>',"\n";
                        }
                }
        }else{
                print OUT '<td>No New Warm Pixels</td></tr>',"\n";
        }
#
#--- hot pix
#
        print OUT '<tr><th>Hot Pixels</th>',"\n";
        if($tot_hot > 0){
                print OUT '<td>&#160;</td></tr>',"\n";
                for($kccd = 0; $kccd < 10; $kccd++){
                        if(${tot_new_hot.$kccd} > 0){
                                print OUT "<th>CCD $kccd</th>","\n";
                                print OUT '<td>';
                                open(IN,"$data_dir/Disp_dir/totally_new_hot$kccd");
                                while(<IN>){
                                        chomp $_;
                                        print OUT "$_\n";
                                }
                                close(IN);
                                print OUT '</td></tr>',"\n";
                        }
                }
        }else{
                print OUT '<td>No New Hot Pixels</td></tr>',"\n";
        }
#
#--- bad col
#
        print OUT '<tr><th>Bad Columns</th>',"\n";
        if($tot_col > 0){
                print OUT '<td>&#160;</td></tr>',"\n";
                for($kccd = 0; $kccd < 10; $kccd++){
                        if(${tot_new_col.$kccd} > 0){
                                print OUT "<th>CCD $kccd</th>","\n";
                                print OUT '<td>';
                                open(IN,"$data_dir/Disp_dir/totally_new_col$kccd");
                                while(<IN>){
                                        chomp $_;
                                        print OUT "$_\n";
                                }
                                close(IN);
                                print OUT '</td></tr>',"\n";
                        }
                }
        }else{
                print OUT '<td>No New Bad Columns</td></tr>',"\n";
        }
        print OUT '</table>',"\n";



        print OUT '<h3>Current Bad Pixels/Columns</h3>',"\n";
        print OUT "<p><strong>Click one of the cell under \"Data\" to see lists of warm pixels and other entires. \n";
        print OUT "The description of each column is found <a href=\"#col_name\">below</a>.</strong></p> \n";
        print OUT "<table border=1 style='border-width:2px;'> \n";
        print OUT '<tr>',"\n";
        print OUT '<th style="text-align:center">CCD</th>';
        print OUT '<th style="text-align:center">Data</th>';
        print OUT '<th style="text-align:center">Warm Pixel History</th>';
        print OUT '<th style="text-align:center">Hot Pixel History</th>';
        print OUT '<th style="text-align:center">Bad Column History</th>';
        print OUT '<th style="text-align:center">Data List</th>',"\n";
        print OUT '</tr>',"\n";

        $test = `ls $data_dir/Disp_dir/*`;
        for($i = 0; $i < 10; $i++) {
                print OUT '<tr><td>CCD',"$i</td>\n";

#------  data display page

                $chk = 0;
                open(CH, "$data_dir/Disp_dir/ccd$i");
                while(<CH>){
                        chomp $_;
                        if($_ =~ /\d/){
                                $chk++;
                        }
                }
                close(CH);

                open(CH, "$data_dir/Disp_dir/hccd$i");
                while(<CH>){
                        chomp $_;
                        if($_ =~ /\d/){
                                $chk++;
                        }
                }
                close(CH);

                if($chk > 0){
                        print OUT '<td><a href = "./Html_dir/ccd_data',"$i",'.html">Bad Pixels Today</a></td>',"\n";
                }else{
                        print OUT '<td><a href = "./Html_dir/ccd_data',"$i",'.html">No Bad Pixels Today</a></td>',"\n";
                }

#----- warm pix history

                if($test =~ /hist_ccd$i/){
                        print OUT '<td><a href=./Disp_dir/',"hist_ccd$i",'>Change</a></td>',"\n";
                }else{
                        print OUT '<td>No History</td>',"\n";
                }

#----- hot pix history

                if($test =~ /hist_hccd$i/){
                        print OUT '<td><a href=./Disp_dir/',"hist_hccd$i",'>Change</a></td>',"\n";
                }else{
                        print OUT '<td>No History</td>',"\n";
                }
#
#----- bad column history
#
                if($test =~ /hist_col$i/){
                        print OUT '<td><a href=./Disp_dir/',"hist_col$i",'>Change</a></td>',"\n";
                }else{
                        print OUT '<td>No History</td>',"\n";
                }
#
#----- data used
#
                print OUT '<td><a href=./Disp_dir/',"data_used.$i",'>Data Used</a></td>',"\n";
        }

        print OUT '</tr>',"\n";

        print OUT "</table> \n";

        print OUT "<div style='margin-bottom:20px'>&#160;</div> \n";
        print OUT '<h4>Bad Pixel Trend Plots</h4>',"\n";
        print OUT "<ul style='font-size:90%'>\n";

        print OUT "<li><a href=\"javascript:WindowOpener('hist_plot_front_side.gif')\">Plot for History of Warm Pixel: Front Side CCDs</a></li>\n";
        print OUT "<li><a href=\"javascript:WindowOpener('hist_plot_ccd5.gif')\">Plot for History of Warm Pixel: CCD 5</a></li>\n";
        print OUT "<li><a href=\"javascript:WindowOpener('hist_plot_ccd7.gif')\">Plot for History of Warm Pixel: CCD 7</a></li>\n";

        print OUT "<li><a href=\"javascript:WindowOpener('hist_col_plot_front_side.gif')\">Plot for History of Bad Columns: Front Side CCDs</a></li>\n";
        print OUT "<li><a href=\"javascript:WindowOpener('hist_plot_col5.gif')\">Plot for History of Bad Columns: CCD 5</a></li>\n";
        print OUT "<li><a href=\"javascript:WindowOpener('hist_plot_col7.gif')\">Plot for History of Bad Columns: CCD 7</a></li>\n";
        print OUT '</ul>',"\n";

        print OUT '<hr />',"\n\n";

        print OUT '<h4 id="col_name">Columns in Table</h4>',"\n";

        print OUT "<table style='border-width:0px;margin-left:20px'> \n";
        print OUT '<tr><td>Warm Pixel:</td><td style="text-align:left"> a list of warm pixels currently observed</td></tr>',"\n";
        print OUT '<tr><td>Flickering:</td><td style="text-align:left"> any warm pixels which were on and off 3 times or more in the last 3 months</td></tr>',"\n";
        print OUT '<tr><td>Past Warm Pixels:</td><td style="text-align:left"> a list of all pixels appeared as warm pixels in past</td></tr>',"\n";
        print OUT '<tr><td>History:</td><td style="text-align:left"> history of when a particular warm pixel was on or off</td></tr>',"\n";

        print OUT '<tr><td>Hot Pixel:</td><td style="text-align:left"> a list of hot pixels currently observed</td></tr>',"\n";
        print OUT '<tr><td>Flickering:</td><td style="text-align:left"> any hot pixels which were on and off 3 times or more in the last 3 months</td></tr>',"\n";
        print OUT '<tr><td>Past Hot Pixels:</td><td style="text-align:left"> a list of all pixels appeared as hot pixels in past</td></tr>',"\n";
        print OUT '<tr><td>History:</td><td style="text-align:left"> history of when a particular hot pixel was on or off</td></tr>',"\n";

        print OUT '<tr><td>Warm Column:</td><td style="text-align:left"> a list of warm columns currently observed</td></tr>',"\n";
        print OUT '<tr><td>Flickering:</td><td style="text-align:left"> any warm columns which were on and off 3 times or more in the last 3 months</td></tr>',"\n";
        print OUT '<tr><td>Past Warm Columns:</td><td style="text-align:left"> a list of all columns appeared as warm columns in past</td></tr>',"\n";
        print OUT '<tr><td>History:</td><td style="text-align:left"> history of when a particular warm columns was on or off</td></tr>',"\n";
        print OUT '</table>',"\n";

        print OUT '<h4>A bad pixel was selected as follows:</h4>',"\n";
        print OUT '<ul style="font:yellow;font-size:90%">',"\n";
        print OUT '<li> acis*bias0.fits in a given period were obtained</li>',"\n";
        print OUT '<li> compute an average of ADU for each CCD</li>',"\n";
        print OUT '<li> compare the value of each pixel to the CCD average, if a pixel value',"\n";
        print OUT 'was 5 sigma higher than the average, a local average (32x32) was computed</li>',"\n";
        print OUT '<li>if the pixel value was still 5 sigma higher than the local average,',"\n";
        print OUT 'it was marked as a possible candidate for a warm pixel.</li>',"\n";
        print OUT '<li> if three consecutive(sp) bias frames had the same pixel marked as a',"\n";
        print OUT 'warm pixel candidate, the pixel was listed as a warm pixel.</li>',"\n";
        print OUT '<li> if the pixels appear and disappear repeatedly during the last three months',"\n";
        print OUT 'the pixels are listed in flickering pixels</li>',"\n";
        print OUT '<li> if the pixels which appeared in "current warm pixels" list, even once in the past',"\n";
        print OUT ' the pixels are parmanently listed in "Past Warm Pixels" list</li>', "\n";
        print OUT '<li> hot pixels are defined as warm pixels with an adu value of greater than',"\n";
        print OUT ' the CCD average +1000.</li>',"\n";
        print OUT '<li> if the pixel was located at the edge of the CCD (y = 1023, 1024), it is ignored and not',"\n";
        print OUT ' included on either the list.</li>',"\n";
        print OUT '<li>for a hot pixel, a process was same, except a threshold was ',"\n";
        print OUT 'a ccd  average plus 1000 counts</li>',"\n";
        print OUT '</ul>',"\n";


        print OUT '<h4>A bad column was selected as follows:</h4>',"\n";
        print OUT '<ul style="font:yellow;font-size:90%">';
        print OUT '<li> each column was averaged out, and compared to an average for an entire ccd.</li>',"\n";
        print OUT '<li> if the average of the column was 5 sigma  higher than the average of the ccd',"\n";
        print OUT 'compare the column average to a local average (10 columns).</li>',"\n";
        print OUT '<li> if the column was still 5 sigma higher than the local average, mark it as',"\n";
        print OUT 'a bad column candidate</li>',"\n";
        print OUT '<li> if the column appeared as a bad column for a 3 consecutive frames, it was ',"\n";
        print OUT 'marked as a real bad column.</li>',"\n";
        print OUT '</ul>',"\n";

        print OUT "<hr /> \n";
        print OUT "<p style='margin-top:5px'> \n";
        print OUT "If you have any quesitons about this page, please contact ";
        print OUT "<a href='mailto:swolk\@head.cfa.harvard.edu'>swolk\@head.cfa.harvard.edu</a>. \n";
        print OUT "</p> \n";

        print OUT "</body>\n";
        print OUT "</html>\n";

        close(OUT);
}

#############################################################################
### plot_hist: plotting history of bad pixel increase                    ####
#############################################################################

sub plot_hist{
	@day_list = ();
	@new_list = ();
	@imp_list = ();
	$save_date = 'null';

############### bad columns and bad row lists are here; ################
	$ccd = 5;
	@{bad_col.$ccd} = (1,2,3,509,510,511,513,515);
	@{bad_row.$ccd} = (313);
	$ccd = 7;
	@{bad_col.$ccd} = (4,509,510,511,512,513,514,515,516);
########################################################################

#
#--- prepareing plottings
#

#
#---	Imaging CCDs
#
		
	open(FH, "$data_dir/Disp_dir/front_ccd_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;

	$ymin = -1;
	$ymax = 20;						# setting y plotting range

	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Pixels: Front Side CCDs';
	plot_diff();						# ploting routine
	
	@x = @day_list;
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Pixels: Front Side CCDs';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./, $slope);
	@btemp = split(//,   $atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";


	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;

	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 30;

	$title = 'Numbers of Warm Pixels Changes: Front CCDs';
	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 | ppmtogif > $web_dir/Plots/hist_ccd.gif");
	system("rm -rf  pgplot.ps");

#
#---	 CCD 5
#
		
	open(FH, "$data_dir/Disp_dir/ccd5_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
		
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Pixels: CCD 5';
	plot_diff();						# ploting routine
		
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Pixels: CCD 5';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Warm Pixels Changes: CCD5';
	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_ccd5.gif");
	system("rm -rf  pgplot.ps");

#
#--- CCD7
#
		
	open(FH, "$data_dir/Disp_dir/ccd7_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
		
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Pixels: CCD 7';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Pixels: CCD 7';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;

	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Warm Pixels Changes: CCD 7';
	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_ccd7.gif");
	system("rm -rf  pgplot.ps");

#
#---     Hot:
#

#
#--- 	Imaging CCDs
#

		
	open(FH, "$data_dir/Disp_dir/front_hccd_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;						# setting y plotting range

	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels

	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Hot Pixels: Front Side CCDs';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Hot Pixels: Front Side CCDs';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels

	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";


	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Hot Pixels Changes: Front CCDs';
	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_hccd.gif");
	system("rm -rf  pgplot.ps");

#
#----	 CCD 5
#
		
	open(FH, "$data_dir/Disp_dir/hccd5_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;						# setting y plotting range
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Hot Pixels: CCD 5';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Hot Pixels: CCD 5';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;
	$title = 'Numbers of Hot Pixels Changes: CCD5';

	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_hccd5.gif");
	system("rm -rf  pgplot.ps");

#
#---	 CCD7
#
		
	open(FH, "$data_dir/Disp_dir/hccd7_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Hot Pixels: CCD 7';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Hot Pixels: CCD 7';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Hot Pixels Changes: CCD 7';

	plot_diff();
	pgclos();

	system("echo ''|$gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_hccd7.gif");
	system("rm -rf  pgplot.ps");

#
#---	 Col: Front Side CCDs
#
		
	open(FH, "$data_dir/Disp_dir/front_col_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Columns: Front Side CCDs';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Columns: Front Side CCDs';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;
	
	$title = 'Numbers of Warm Column Changes: Front Side CCDs';

	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_col.gif");
	system("rm -rf  pgplot.ps");

#
#---	 Col: CCD 5
#
		
	open(FH, "$data_dir/Disp_dir/col5_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Columns: CCD 5';
	plot_diff();						# ploting routine
	
	@x = @day_list;						#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Columns: CCD 5';
	plot_diff();
	
	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $icnt -2;
	linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;
	
	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Warm Columns: CCD 5';

	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_col5.gif");
	system("rm -rf  pgplot.ps");

#
#---	 Col: CCD 7
#
		
	open(FH, "$data_dir/Disp_dir/col5_cnt");
	@new_list  = ();
	@imp_list  = ();
	@diff_list = ();
	@day_list  = ();
	$count     = 0;
	while(<FH>){
		chomp $_;
		@btemp = split(/<>/, $_);
		push(@day_list, $btemp[0]);
		@ctemp = split(/:/, $btemp[2]);
		push(@diff_list,    $ctemp[0]);
		push(@new_list,     $ctemp[1]);
		push(@imp_list,     $ctemp[2]);
		$count++;
	}
	close(FH);
	
	$xmin = $day_list[1] - 3;
	$xmax = $day_list[$count-1] + 3;
	$ymin = -1;
	$ymax = 20;
	
	pgbegin(0, "/cps",1,1);                                  # here the plotting start
	pgsubp(1,3);                                            # pg routine: panel
	pgsch(2);                                               # pg routine: charactor size
	pgslw(4);          
	
	$no_write = 0 ;						# new warm pixels
	@x = @day_list;
	@y = @new_list;
	$title = 'Numbers of New Warm Columns: CCD 7';
	plot_diff();						# ploting routine
	
	@x = @day_list;					#improved warm pixels
	@y = @imp_list;						#improved warm pixels
	$title = 'Numbers of Disappeared Warm Columns: CCD 7';
	plot_diff();

	$no_write = 1;						# relative # of warm pixels
	@x = @day_list;
	@y = @diff_list;
	$tot = $count -2;
		linr_fit();
	$xb = $x[2];
	$xe = $x[$tot];
	$yb = $int + $slope*$xb;
	$ye = $int + $slope*$xe;

	@atemp = split(/\./,$slope);
	@btemp = split(//,$atemp[1]);
	$slope = "$atemp[0]".'.'."$btemp[0]$btemp[1]$btemp[2]$btemp[3]";
	
	$ymin = -1;
	@atemp = sort{$a<=>$b} @diff_list;
	$i = $icnt - 1;
	$ymax = $atemp[$i] + 3;
	if($ymax < 20){
		$ymax = 20;
	}
	$ymax = 20;

	$title = 'Numbers of Warm Columns: CCD 7';

	plot_diff();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r125x125 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/Plots/hist_col7.gif");
	system("rm -rf  pgplot.ps");

}

#####################################################################
#####################################################################
#####################################################################

sub plot_diff {
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);


	pgpt(1, $x[1], $y[1], -1);
	for($m = 2; $m < $count - 1; $m++){
		pgdraw($x[$m],$y[$m]);
		pgpt(1, $x[$m], $y[$m], -1);
	}

	pglabel("Time (Day of Mission)", "Counts","$title");
#
#--- add extra info, if it is for the change plot
#

	if($no_write == 1) {	
		pgpt(1,$xb,$yb,-1);
		pgsci(2);
		pgdraw($xe,$ye);
		pgtext($xmin+5,$ymax-4,"Slope: $slope");
		pgsci(1);
	}
}


#####################################################################
### linr_fit: linear least sq fit routine                        ####
#####################################################################

sub linr_fit {
	$sumx  = 0;
	$sumx2 = 0;
	$sumy  = 0;
	$sumy2 = 0;
	$sumxy = 0;
	for($i = 0; $i <$tot -1; $i++){
		$sumx  += $x[$i];
		$sumx2 += $x[$i]*$x[$i];
		$sumy  += $y[$i];
		$sumy2 += $y[$i]*$y[$i];
		$sumxy += $x[$i]*$y[$i];
	}

	$int = 0;
	$slope = 0;

	$del = $tot*$sumx2 - $sumx*$sumx;
	if($del > 0){
		$int = ($sumx2*$sumy - $sumx*$sumxy)/$del;
		$slope = ($tot*$sumxy - $sumx*$sumy)/$del;
	}
}

#####################################################################
### mv_old_data: move old data from an active dir to a save dir   ###
#####################################################################

sub mv_old_data{
        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $year = $uyear + 1900;
                $uyday++;

		$uyday -= 6;
		if($uyday < 0) {
			$year--;
			$uyday = 365 + $uyday;
		}
	
		$time = "$year:$uyday:00:00:00";
		timeconv2($time);
        }else{
		$sec_form_time = $data_set_start - 518400;
        }
	
	for($dccd = 0; $dccd < 10; $dccd++){
		system("chmod 775  $house_keeping/Defect/CCD$dccd/*");
		system("ls -d $house_keeping/Defect/CCD$dccd/acis* > ./Working_dir/list");
		open(FH, './Working_dir/list');
		while(<FH>){
			chomp $_;
			@btemp = split(/acis/, $_);
			$old_file = 'acis'."$btemp[1]";
			@ctemp = split(/_/, $btemp[1]);
			if($ctemp[0] < $sec_form_time){
				system("mv  $_ $data_dir/Old_data/CCD$dccd/.");
				system("gzip   $data_dir/Old_data/CCD$dccd/$old_file");
			}
		}
		close(FH);
		system("rm -rf  ./Working_dir/list");
	}
}


#################################################################################
### flickering_check: check which pixels are flickering in the past 90 days   ###
#################################################################################


sub flickering_check{
	($ind) = @_;
	chomp $ind;
	if($ind =~ /warm/){
		$chk = 'new_ccd';
	}else{
		$chk = 'new_hccd';
	}

        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $tyear = $uyear + 1900;
                $hyday++;
        }else{
                @atemp = split(/:/, $today_time);
		$tyear = $atemp[0];
		$hyday = $atemp[1];
        }

#
#--- find date for 90 days ago
#
	$pdate = $hyday - 90;

	if ($pdate < 1){
		$pdate += 365;
		$tyear--;
	}
	$chkdate = "$tyear:$pdate";

	$dom90m = ch_ydate_to_dom($chkdate);

	for($iccd = 0; $iccd < 10; $iccd++){

		@data = ();
		@coord = ();
#
#--- read data and find which pixels appeared in the past.
#
		$name = "$chk$iccd";
		open(IN, "$data_dir/Disp_dir/$name");	
		OUTER:
		while(<IN>){			
			chomp $_;
			@etemp = split(/<>/, $_);
			if($etemp[0] < $dom90m){
				next OUTER;
			}
			push(@data, $_);
			@btemp = split(/:/,$etemp[2]);	# some intializations
			foreach $ent (@btemp){
				if($ent ne ''){
					$ent =~ s/\(//g;
					$ent =~ s/\)//g;
					$ent =~ s/\s+//g;
					@ctemp = split(/\,/, $ent);
					$pos   = "$ctemp[0].$ctemp[1]";
					${cnt.$ctemp[0].$ctemp[1]} = 0;
					push(@coord, $pos);
				}
			}
		}
		close(IN);
#
#--- possible candidates for flckering pixels
#
		@coord = sort {$a<=>$b} @coord;
		$first = shift(@coord);
		@new = ("$first");
		OUTER:
		foreach $ent (@coord){
			foreach $comp (@new){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
		}
	
#
#--- check the last 90 days and count how many times it went on and off
#	
		$rd_ind = 0;
		foreach $ent (@data){		
			@etemp = split(/<>/, $ent);
			if($etemp[0] > $dom90m){
				@btemp = split(/:/,$etemp[2]);
				foreach $ent (@btemp){
					if($ent ne ''){
						$ent =~ s/\(//g;
						$ent =~ s/\)//g;
						$ent =~ s/\s+//g;
						@ctemp = split(/\,/, $ent);
						${cnt.$ctemp[0].$ctemp[1]}++;
					}
				}
			}
		}
		
		${fck_cnt.$iccd} = 0;

		if($ind =~ /warm/i){
			open(OUT, "> $data_dir/Disp_dir/flickering$iccd");
		}else{
			open(OUT, "> $data_dir/Disp_dir/hflickering$iccd");
		}
#
#--- if pixels went on and off more than 3 times record they are flickering pixels
#
		foreach $ent (@new){		
			@ct = split(/\./, $ent);
			if(${cnt.$ct[0].$ct[1]} > 3){
				print OUT "($ct[0], $ct[1])\n";
				${fck_cnt.$iccd}++;
			}
		}
		close(OUT);
	}
}

#################################################################################
### flickering_col  : check which columns are flickering in the past 90 days  ###
#################################################################################


sub flickering_col{

        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $tyear = $uyear + 1900;
                $hyday++;
        }else{
                @atemp = split(/:/, $today_time);
		$tyear = $atemp[0];
		$hyday = $atemp[1];
        }
#
#--- find date for 90 days ago
#
	$tyear = 1900 + $hyear;
	$pdate = $hyday - 90;

	if ($pdate < 1){
		$pdate += 365;
		$tyear--;
	}
	$chkdate = "$tyear:$pdate";

	$dom90m = ch_ydate_to_dom($chkdate);

	for($iccd = 0; $iccd < 10; $iccd++){

		@data = ();
		@coord = ();
#
#--- read data and find which columns appeared in the past.
#
		open(IN, "$data_dir/Disp_dir/new_col$iccd");	
		OUTER:
		while(<IN>){			
			chomp $_;
			@etemp = split(/<>/, $_);
			if($etemp[0] < $dom90m){
				next OUTER;
			}
			push(@data, $_);
			@btemp = split(/:/,$etemp[2]);	# some intializations
			foreach $ent (@btemp){
				if($ent ne ''){
					${cnt.$ent} = 0;
					push(@coord, $ent);
				}
			}
		}
		close(IN);
#
#--- possible candidates for flckering columns
#
		@coord = sort {$a<=>$b} @coord;
		$first = shift(@coord);
		@new = ("$first");
		OUTER:
		foreach $ent (@coord){
			foreach $comp (@new){
				if($ent eq $comp){
					next OUTER;
				}
			}
			push(@new, $ent);
		}
	
#
#--- check the last 90 days and count how many times it went on and off
#	
		$rd_ind = 0;
		foreach $ent (@data){		
			@etemp = split(/<>/, $ent);
			if($etemp[0] > $dom90m){
				@btemp = split(/:/,$etemp[2]);
				foreach $ent (@btemp){
					if($ent ne ''){
						${cnt.$ent}++;
					}
				}
			}
		}
		
		${fck_col_cnt.$iccd} = 0;

		open(OUT, "> $data_dir/Disp_dir/flickering_col$iccd");
#
#--- if columns went on and off more than 3 times record they are flickering columns
#
		foreach $ent (@new){		
			if(${cnt.$ent} > 3){
				print OUT "$ent\n";
				${fck_col_cnt.$iccd}++;
			}
		}
		close(OUT);
	}
}

#####################################################################
### conv_date_form4: change date form                             ###
#####################################################################

sub conv_date_form4{
	if($month == 1){$add = 0}
	elsif($month == 2){$add  = 31}
	elsif($month == 3){$add  = 59}
	elsif($month == 4){$add  = 90}
	elsif($month == 5){$add  = 120}
	elsif($month == 6){$add  = 151}
	elsif($month == 7){$add  = 181}
	elsif($month == 8){$add  = 212}
	elsif($month == 9){$add  = 243}
	elsif($month == 10){$add = 273}
	elsif($month == 11){$add = 304}
	elsif($month == 12){$add = 334}
	
	$ychk = 4.0 * int($year/4.0);
	if($ychk == $year){
		if($month > 3){
			$add++;
		}
	}
	$ydate = $add + $day;
	if($ydate < 10){
		$ydate = int ($ydate);
		$ydate = "00$ydate";
	}elsif($ydate < 100){
		$ydate = int ($ydate);
		$ydate = "0$ydate";
	}
	$date = "$year$ydate";
}

##################################################################################
### rm_imcomplete_data: remove incomplete data so that we can fill it correctly ##
##################################################################################


sub rm_incomplete_data{
	
	
	@ttemp   = split(//, $cut_date);
	$tyear   = "$ttemp[0]$ttemp[1]$ttemp[2]$ttemp[3]";
	$tdate   = "$ttemp[4]$ttemp[5]$ttemp[6]";
	$date    = "$tyear:$tdate";
	$tdate   = "$date:00:00:00";
#	$secdate = `/home/ascds/DS.release/bin/axTime3 $tdate t d u s`;
	$secdate = ydate_to_y1998sec($tdate);
	
	foreach $file  ('bad_col_cnt','bad_col_cnt5','bad_col_cnt7',
			'bad_pix_cnt','bad_pix_cnt5','bad_pix_cnt7',
			'hot_pix_cnt','hot_pix_cnt5','hot_pix_cnt7',
			'imp_bad_col_save','imp_bad_col_save5','imp_bad_col_save7',
			'imp_bad_pix_save','imp_bad_pix_save5','imp_bad_pix_save7',
			'imp_hot_pix_save','imp_hot_pix_save5','imp_hot_pix_save7',
			'new_bad_col_save','new_bad_col_save5','new_bad_col_save7',
			'new_bad_pix_save','new_bad_pix_save5','new_bad_pix_save7',
			'new_hot_pix_save','new_hot_pix_save5','new_hot_pix_save7'){
	
		open(FH, "$data_dir/Disp_dir/$file");
		open(OUT, '>./Working_dir/temp');
		OUTER:
		while(<FH>){
			chomp $_;
			@atemp = split(/:/, $_);
			$ind = "$atemp[0]$atemp[1]";
			if($ind >= $cut_date){
				last OUTER;
			}else{
				print OUT "$_\n";
			}
		}
		close(OUT);
		close(FH);
		system("mv ./Working_dir/temp $data_dir/Disp_dir/$file");
	}
	
	for($iccd = 0; $iccd < 10; $iccd++){
		open(FH, "$data_dir/Disp_dir/date_used.$iccd");
		open(OUT, '>./Working_dir/temp');
		while(<FH>){
			chomp $_;
			@atemp = split(/:/, $_);
			$ind = "$atemp[0]$atemp[1]";
			if($ind >= $cut_date){
				last OUTER;
			}else{
				print OUT  "$_\n";
			}
		}
		close(OUT);
		close(FH);
		system("mv ./Working_dir/temp $data_dir/Disp_dir/data_used.$iccd");
	}
	
	foreach $head ('change_ccd', 'change_col', 'imp_ccd', 'new_ccd', 'imp_col', 'new_col'){
		for($iccd = 0; $iccd < 10; $iccd++){
			open(FH, "$data_dir/Disp_dir/$head$iccd");
			open(OUT,'>./Working_dir/temp');
			OUTER:
			while(<FH>){
				chomp $_;
				if($_ =~ /^\#/){
					@atemp = split(/:/, $_);
					$ind = "$atemp[1]$atemp[2]";
					if($ind >= $cut_date){
						last OUTER;
					}else{
						print OUT "$_\n";
					}
				}else{
					print OUT "$_\n";
				}
			}
			close(OUT);
			close(FH);
			system("mv ./Working_dir/temp $data_dir/Disp_dir/$head$iccd");
		}
	}

	foreach $head ('hist_ccd'){
		for($iccd = 0; $iccd < 10; $iccd++){
	
			open(FH, "$data_dir/Disp_dir/$head$iccd");
			open(OUT,'>./Working_dir/temp');
			OUTER:
			while(<FH>){
				chomp $_;
				if($_ =~ /^\#/){
					@atemp = split(/\#/, $_);
					@btemp = split(/:/, $atemp[1]);
					$ind = "$btemp[0]$btemp[1]";
					if($ind >= $cut_date){
						last OUTER;
					}else{
						print OUT "$_\n";
					}
				}else{
					print OUT "$_\n";
				}
			}
			close(OUT);
			close(FH);
			system("mv ./Working_dir/temp $data_dir/Disp_dir/$head$iccd");
		}
	}


	for($iccd = 0; $iccd < 10; $iccd++){
		$temp_wdir = `ls $house_keeping/Defect/CCD$iccd/* `;
		@temp_wdir_list = split(/\s+/, $temp_wdir);
		foreach $ent (@temp_wdir_list){
			@atemp = split(/acis/, $dir);
			@btemp = split(/\_/, $atemp[1]);
			if($btemp[0] > $secdate){
				system("rm $dir");
			}
		}
	}
}


################################################################
### sub clearnup_duplicate: remove duplicated lines          ###
################################################################

sub clearnup_duplicate {
	($in_file) = @_;
	@test = ();
	open(CL, "$in_file");
	while(<CL>){
		chomp $_;
		push(@test, $_);
	}
	close(CHL);
	@ctemp = sort{$a<=>$b} @test;
	$first = shift(@ctemp);
	@cnew  = ($first);
	COUTER:
	foreach $cent (@ctemp){
		foreach $ccomp (@cnew){
			@dtemp = split(/:/, $cent);
			@etemp = split(/:/, $ccomp);
			if($dtemp[0] == $etemp[0] && $dtemp[1] == $etemp[1]){
				next COUTER;
			}
		}
		push(@cnew, $cent);
	}

	@test = sort{$a<=>$b} @cnew;

	open(COUT, "> $in_file");
	foreach $cent (@test){
		print COUT "$cent\n";
	}
}

################################################################
### cov_time_dom: change date (yyyy:ddd) to dom             ####
################################################################

sub conv_time_to_dom {
        $tyear = $year;
        $tyday = $date;

        $totyday = 365 * ($tyear - 1999);
        if($tyear > 2000){
                $totyday++;
        }
        if($tyear > 2004){
                $totyday++;
        }
        if($tyear > 2008){
                $totyday++;
        }
        if($tyear > 2012){
                $totyday++;
        }

        $today_dom = $totyday + $tyday - 202;
}




###################################################################################
### find_more_bad_pix_info; find additional information about bad pixels        ###
###################################################################################

sub find_more_bad_pix_info{
	for($iccd = 0 ; $iccd < 10; $iccd++){
#
#---  warm pixels    
#	
		$file = "$data_dir/Disp_dir/hist_ccd$iccd";
	
		$out  = "$data_dir/Disp_dir/all_past_bad_pix$iccd";
		find_all_past_bad_pix();
		${past_cnt.$iccd} = $tot;
#
#---  hot pixels    
#	
		$file = "$data_dir/Disp_dir/hist_hccd$iccd";
	
		$out  = "$data_dir/Disp_dir/all_past_hot_pix$iccd";
		find_all_past_bad_pix();
		${past_hot_cnt.$iccd} = $tot;
	
#
#--- bad columns
#	
		$file = "$data_dir/Disp_dir/hist_col$iccd";
	
		$out  = "$data_dir/Disp_dir/all_past_bad_col$iccd";
		find_all_past_bad_col();
		${past_col_cnt.$iccd} = $tot;
	}
	
#
#---- find bad pixels and columns which has never been observered before
#

	find_totally_new();
	find_totally_new_col();
}

#################################################################################
### find_all_past_bad_pix: make a list of all bad pixels in the past         ####
#################################################################################

sub find_all_past_bad_pix {

	@hold = ();
#
#----- open pxiel change history file, and find all bad pixels in the past
#
	open(FH, "$file");
	while(<FH>){
		chomp $_;
		@ftemp = split(/<>/, $_);
		@gtemp = split(/:/, $ftemp[2]);
		foreach $ent (@gtemp){
			$tent = $ent;
			$tent =~ s/\(//g;
			$tent =~ s/\)//g;
			$tent =~ s/\,/\./g;
			push(@hold, $tent);
			%{dpix.$tent}=(pix =>["$ent"]);
		}
	}
	close(FH);
	
#
#----- remove duplicates
#
	@sorted_hold = sort {$a<=>$b}@hold;
	$first = shift(@sorted_hold);

	@new = ($first);
	$chk = $first;
	$test_cnt = 0;
	OUTER:
	foreach $ent (@sorted_hold){
		if($ent eq $chk){
			next OUTER;
		}
		push(@new, $ent);
		$chk = $ent;
		$test_cnt++;
	}
	
	$tot = 0;
	open(OUT, "> $out");
	if($test_cnt > 0){
		foreach $ent (@new){
			print OUT "${dpix.$ent}{pix}[0]\n";
			$tot++;
		}
	}
	close(OUT);
}

#################################################################################
### find_all_past_bad_col: make a list of all bad columns in the past        ####
#################################################################################

sub find_all_past_bad_col {


	@hold = ();
#
#----- open pxiel change history file, and find all bad cols in the past
#
	open(FH, "$file");
	while(<FH>){
		chomp $_;
		@ftemp = split(/<>/, $_);
		@gtemp = split(/:/, $ftemp[2]);
		foreach $ent (@gtemp){
			if($ent ne ''){
				push(@hold, $ent);
			}
		}
	}
	close(FH);
	
#
#----- remove duplicates
#
	@sorted_hold = sort {$a<=>$b}@hold;
	$first = shift(@sorted_hold);

	@new = ($first);
	$chk = $first;
	$test_cnt = 0;
	OUTER:
	foreach $ent (@sorted_hold){
		if($ent eq $chk){
			next OUTER;
		}
		push(@new, $ent);
		$chk = $ent;
		$test_cnt++;
	}
	
	$tot = 0;
	open(OUT, "> $out");
	if($test_cnt > 0){
		foreach $ent (@new){
			print OUT "$ent\n";
			$tot++;
		}
	}
	close(OUT);
}

###############################################################################
### find_totally_new: find first time bad pixels ---- calling new_pix       ###
###############################################################################

sub find_totally_new {
#
#---- warm pixels
#
	$file1 = "$data_dir/Disp_dir/totally_new*";
	$file2 = "$data_dir/Disp_dir/ccd*";
	$file3 = "$data_dir/Disp_dir/all_past_bad_pix";
	$file4 = "$data_dir/Disp_dir/totally_new";
	$out_ind = 'tot_new_pix';
	new_pix();
#
#---- hot pixels
#
	$file1 = "$data_dir/Disp_dir/totally_new_hot*";
	$file2 = "$data_dir/Disp_dir/hccd*";
	$file3 = "$data_dir/Disp_dir/all_past_hot_pix";
	$file4 = "$data_dir/Disp_dir/totally_new_hot";
	$out_ind = 'tot_new_hot';
	new_pix();
}

###############################################################################
### new_pix: find first time bad pixels --- main script                    ####
###############################################################################

sub new_pix {
#
#--- find today's date
#

        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $today_year = $uyear + 1900;
                $uyday++;
                $today        = "$today_year:$uyday";
                $dom_today    = ch_ydate_to_dom($date_obs2);
        }else{
                $today        = $today_time;
                $dom_today    = ch_ydate_to_dom($today_time);
        }


#
#--- find which ccd has the new bad pixel in past
#
	$temp_file = `ls $file1`;
	@totally_new = ();
	@totally_new = split(/\s+/, $temp_file);

	foreach $file (@totally_new){
		open(FH, "$file");
		open(OUT, '>./Working_dir/zout');
		while(<FH>){
			chomp $_;
			@atemp = split(/\[/, $_);
			$first_show = $atemp[1];
			$first_show =~ s/\]//g;
			$c_day14 = $first_show + 14;
#
#----- check whether the bad pixel is listed 14 days or more. if it is, remove
#
			if($c_day14 > $dom_today){
				print OUT "$_\n";
			}
		}
		close(OUT);
		close(FH);
		system("mv ./Working_dir/zout $file");
	}
#
#---- find today's bad pixels
#
	$temp_file = `ls $file2`;
	@ccd_list  = split(/\s+/, $temp_file);

	OUTER:
	foreach $file (@ccd_list){
		if($file =~ /_cnt/){
			next OUTER;
		}
		@atemp = split(/ccd/, $file);
		$kccd  = $atemp[1];
#
#---- first read all bad pxiels appeared in the past
#
		$comp_file = "$file3"."$kccd";

		@x_save = ();
		@y_save = ();
		$comp_cnt = 0;

		open(FH, "$comp_file");
		while(<FH>){
			chomp $_;
			@atemp = split(/\(/, $_);
			@btemp = split(/\)/, $atemp[1]);
			@ctemp = split(/\,/, $btemp[0]);
			$x = $ctemp[0];
			$x =~ s/\s+//g;
			push(@x_save, $x);
			$y = $ctemp[1];
			$y =~ s/\s+//g;
			push(@y_save, $y);
			$comp_cnt++;
		}
		close(FH);
#
#--- today's list
#
		open(FH, "$file");
		while(<FH>){
			chomp $_;
			@atemp = split(/\s+/, $_);
			$x = $atemp[0];
			$x =~ s/\s+//g;
			$y = $atemp[1];
			$y =~ s/\s+//g;
#
#--- indicator for new bad pixels
#
			$new_ind = 0;

			OUTER:
			for($k = 0; $k < $comp_cnt; $k++){
				if($x == $x_save[$k] && $y == $y_save[$k]){
					$new_ind = 1;
					last OUTER;
				}
			}
			${$out_ind.$kccd} = 0;

			if($new_ind == 0){
				$first_day = "$uyear:$uyday";
				$dom_today = ch_ydate_to_dom($first_day);
				open(OUT,">>$data_dir/Disp_dir/totally_new$kccd");
				print OUT "($x,$y)\t$first_day [$dom_today]\n";
				close(OUT);
				${$out_ind.$kccd}++;
			}
		}
	}
}

###############################################################################
### find_totally_new_col: find first time bad columns 			    ###
###############################################################################

sub find_totally_new_col {

#
#------ find today's date
#
        if($input_type =~ /live/){
                ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
                $today_year = $uyear + 1900;
                $uyday++;
                $today      = "$today_year:$uyday";
                $dom_today  = ch_ydate_to_dom($date_obs2);
        }else{
                $today      = $today_time;
                $dom_today  = ch_ydate_to_dom($today_time);
        }

#
#------- find which ccd has the new bad columns in past
#
	$temp_file = `ls $data_dir/Disp_dir/totally_new_col*`;
	@totally_new = split(/\s+/, $temp_file);

	foreach $file (@totally_new){
		open(FH, "$file");
		open(OUT, '>./Working_dir/zout');
		while(<FH>){
			chomp $_;
			@atemp = split(/\[/, $_);
			$first_show = $atemp[1];
			$first_show =~ s/\]//g;
			$c_day14 = $first_show + 14;
#
#----- check whether the bad pixel is listed 14 days or more. if it is, remove
#
			if($c_day14 > $dom_today){
				print OUT "$_\n";
			}
		}
		close(OUT);
		close(FH);
		system("mv ./Working_dir/zout $file");
	}
#
#---- find today's bad cols
#
	$temp_file = `ls $data_dir/Disp_dir/col*`;
	@col_list  = split(/\s+/, $temp_file);

	OUTER:
	foreach $file (@col_list){
		if($file =~ /_cnt/){
			next OUTER;
		}
		@atemp = split(/col/, $file);
		$kccd = $atemp[1];
#
#---- first read all bad pxiels appeared in the past
#
		$comp_file = "$data_dir/Disp_dir/all_past_bad_col"."$kccd";

		@col_save = ();
		$comp_cnt = 0;

		open(FH, "$comp_file");
		while(<FH>){
			chomp $_;
			push(@col_save, $_);
			$comp_cnt++;
		}
		close(FH);
#
#--- today's list
#
		open(FH, "$file");
		while(<FH>){
			chomp $_;
			$col = $_;
			$col =~ s/\s+//g;
#
#--- indicator for new bad pixels
#
			$new_ind = 0;

			OUTER:
			for($k = 0; $k < $comp_cnt; $k++){
				if($col == $col_save[$k]){
					$new_ind = 1;
					last OUTER;
				}
			}
			${tot_new_col.$kccd} = 0;

			if($new_ind == 0){
				$first_day = "$uyear:$uyday";
				$dom_today = ch_ydate_to_dom($first_day);
				if($dom_today > 0){
					open(OUT,">>$data_dir/Disp_dir/totally_new_col$kccd");
					print OUT "$col\t$first_day [$dom_today]\n";
					close(OUT);
					${tot_new_col.$kccd}++;
				}
			}
		}
		close(FH);
	}
}

##################################################################################
### ch_ydate_to_dom: change yyyy:ddd to dom (date from 1999:202)               ###
##################################################################################

sub ch_ydate_to_dom{
        ($in_date) = @_;
        chomp $in_date;
        @htemp     = split(/:/, $in_date);
        $hyear     = $htemp[0];
        $hyday     = $htemp[1];
        $hdiff     = $hyear - 1999;
        $acc_date  = $hdiff * 365;

        $hdiff    += 2;
        $leap_corr = int(0.25 * $hdiff);

        $acc_date += $leap_corr;
        $acc_date += $hyday;
        $acc_date -= 202;
        return($acc_date);
}

######################################################################################
### ydate_to_y1998sec: 20009:033:00:00:00 format to 349920000 fromat               ###
######################################################################################

sub ydate_to_y1998sec{
#
#---- this script computes total seconds from 1998:001:00:00:00
#---- to whatever you input in the same format. it is equivalent of
#---- axTime3 2008:001:00:00:00 t d m s
#---- there is no leap sec corrections.
#

	my($date, $atemp, $year, $ydate, $hour, $min, $sec, $yi);
	my($leap, $ysum, $total_day);

	($date)= @_;
	
	@atemp = split(/:/, $date);
	$year  = $atemp[0];
	$ydate = $atemp[1];
	$hour  = $atemp[2];
	$min   = $atemp[3];
	$sec   = $atemp[4];
	
	$leap  = 0;
	$ysum  = 0;
	for($yi = 1998; $yi < $year; $yi++){
		$chk = 4.0 * int(0.25 * $yi);
		if($yi == $chk){
			$leap++;
		}
		$ysum++;
	}
	
	$total_day = 365 * $ysum + $leap + $ydate -1;
	
	$total_sec = 86400 * $total_day + 3600 * $hour + 60 * $min + $sec;
	
	return($total_sec);
}

######################################################################################
### y1999sec_to_ydate: format from 349920000 to 2009:33:00:00:00 format            ###
######################################################################################

sub y1999sec_to_ydate{
#
#----- this chage the seconds from 1998:001:00:00:00 to (e.g. 349920000)
#----- to 2009:033:00:00:00.
#----- it is equivalent of axTime3 349920000 m s t d
#

	my($date, $in_date, $day_part, $rest, $in_hr, $hour, $min_part);
	my($in_min, $min, $sec_part, $sec, $year, $tot_yday, $chk, $hour);
	my($min, $sec);

	($date) = @_;

	$in_day   = $date/86400;
	$day_part = int ($in_day);
	
	$rest     = $in_day - $day_part;
	$in_hr    = 24 * $rest;
	$hour     = int ($in_hr);
	
	$min_part = $in_hr - $hour;
	$in_min   = 60 * $min_part;
	$min      = int ($in_min);
	
	$sec_part = $in_min - $min;
	$sec      = int(60 * $sec_part);
	
	OUTER:
	for($year = 1998; $year < 2100; $year++){
		$tot_yday = 365;
		$chk = 4.0 * int(0.25 * $year);
		if($chk == $year){
			$tot_yday = 366;
		}
		if($day_part < $tot_yday){
			last OUTER;
		}
		$day_part -= $tot_yday;
	}
	
	$day_part++;
	if($day_part < 10){
		$day_part = '00'."$day_part";
	}elsif($day_part < 100){
		$day_part = '0'."$day_part";
	}
	
	if($hour < 10){
		$hour = '0'."$hour";
	}
	
	if($min  < 10){
		$min  = '0'."$min";
	}
	
	if($sec  < 10){
		$sec  = '0'."$sec";
	}
	
	$time = "$year:$day_part:$hour:$min:$sec";
	
	return($time);
}
		
