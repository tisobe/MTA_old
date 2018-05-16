#!/usr/bin/perl

#########################################################################################################################################
#																	#
#	acis_dose_correct_drop_rate.perl: create an image file which corrcts missing part of exposure map				#
#					  correction is made only on CCD s3								#
#																	#
#																	#
#	input format: 															#
#	obsid	name			start time	month	Int time	Inst	CCD	Grating	Tot Cnt		Drop Rate	#
#	1998    CRAB_NEBULA             353:72900.092   dec     25.8            ACIS-S  S1      NONE    403.922         39.3		#
#																	#
#	this is dirctly from Acis science run high drop rate warming file								#
#																	#
#		author: t. isobe (tiosbe@cfa.harvard.edu)										#
#																	#
#		last update: 08/22/05													#
#																	#
#########################################################################################################################################

###############################################################################
#---- set directories

$bin_dir  = '/data/mta/MTA/bin/';
$dat_dir  = '/data/mta/MTA/data/';

###############################################################################


$user   = `cat $dat_dir/.dare`;
$hakama = `cat $dat_dir/.hakama`;
chomp $user;
chomp $hakama;

if($user eq '' || $hakama eq ''){
	print "something is wrong. are you on rhodes?\n";
	exit 1;
}

$file = $ARGV[0];						# see input file format above

open(FH, "$file");
@obsid_list = ();
OUTER:
while(<FH>){
	chomp $_;
	if($_ =~ /#/){
		next OUTER;
	}
	@atemp = split(/\s+/, $_);
	push(@obsid_list, $atemp[0]);
	$ratio = $atemp[8]/100;
#	$ratio = $atemp[9]/100;					# recording drop rate
	%{data.$atemp[0]} = (drop => ["$ratio"]);
}
close(FH);

system('rm zdata_list');
foreach $obsid (@obsid_list){					# get an evt1 file list
	open(OUT, ">./input_line");
	print OUT "operation=browse\n";
	print OUT "dataset=flight\n";
	print OUT "detector=acis\n";
	print OUT "level=1\n";
	print OUT "filetype=evt1\n";
	print OUT "obsid=$obsid\n";
	print OUT "go\n";
	close(OUT);

	`echo $hakama |arc4gl -U$user -Sarcocc -iinput_line >> zdata_list`;
}
open(FH, './zdata_list');
@data_list = ();

while(<FH>){
	chomp $_;
	if($_ =~ /acisf/){
		@atemp = split(/\s+/, $_);
		push(@data_list, $atemp[0]);
	}
}
close(FH);

system("mkdir Save");

@name_list = ();
$name_cnt  = 0;
foreach $file (@data_list){				# now extract each evt1 file
	open(OUT, ">./input_line");
	print OUT "operation=retrieve\n";
	print OUT "dataset=flight\n";
	print OUT "detector=acis\n";
	print OUT "level=1\n";
	print OUT "filetype=evt1\n";
#	print OUT "obsid=$obsid\n";
	print OUT "filename=$file\n";
	print OUT "go\n";
	close(OUT);

	`echo $hakama |arc4gl -U$user -Sarcocc -iinput_line`;
	system("rm input_line");

	system("gzip -d -f  *gz");


	@atemp = split(/acisf/, $file);						# setting out put file names
	@btemp = split(/_/, $atemp[1]);						# img_part is only correction part

	if($btemp[2] =~ /evt1/){						# img_full is observed + correction
		$name  = 'acisf'."$btemp[0]".'_img_part.fits';			
		$name2 = 'acisf'."$btemp[0]".'_img_full.fits';
	}else{
		$name  = 'acisf'."$btemp[0]"."_$btemp[2]".'_img_part.fits';
		$name2 = 'acisf'."$btemp[0]"."_$btemp[2]".'_img_full.fits';
	}

	push(@name_list, $name);
	$name_cnt++;

	$obsid = '';
	@ctemp = split(//, $btemp[0]);
	$chk = 0;

	OUTER:
	foreach $ent (@ctemp){
		if($ent ==  0 && $chk == 0){
			next OUTER;
		}else{
			$chk = 1;
			$obsid = "$obsid"."$ent";
		}
	}

#
#--- extract CCD s3
#
	$line = "$file".'[ccd_id=7]';
	system("dmcopy \"$line\" temp.fits");
#
#--- count how many data line exists in the data
#
	$line = 'temp.fits[cols ccd_id]';
	system("dmstat \"$line\" > zout");

	open(FH, './zout');
	while(<FH>){
		chomp $_;
		if($_ =~ /The number of points/){
				@atemp = split(/is/, $_);
			$line_no = $atemp[1];
			$line_no =~ s/\s+//g;
		}
	}
	close(FH);
	system("rm zout");

	$line_no *= ${data.$obsid}{drop}[0];
	
	$line = "temp.fits".'[#row=1:'."$line_no".']';				# extract correction part
	system("dmcopy \"$line\" temp2.fits");

	$line = "temp2.fits".'[EVENTS][bin tdetx=2800:5200:1, tdety=1650:4150:1][option type=i4]';
	system("dmcopy \"$line\" out.fits  option=image clobber=yes");

	$line = 'out.fits[opt type=i4,null=-99]';
	system("dmcopy infile=\"$line\" outfile=total.fits clobber=yes");

	system("rm temp2.fits out.fits");
	system("mv total.fits $name");
	
	$line = "temp.fits".'[EVENTS][bin tdetx=2800:5200:1, tdety=1650:4150:1][option type=i4]';
	system("dmcopy \"$line\" out.fits  option=image clobber=yes");

	$line = 'out.fits[opt type=i4,null=-99]';
	system("dmcopy infile=\"$line\" outfile=total.fits clobber=yes");

	system("rm temp.fits  out.fits");
	
	system("dmimgcalc infile=$name infile2=$total.fits outfile=$name2 operation=add  clobber=yes");
	system("rm file");

	system("mv $name $name2 Save/");
	system("rm total.fits $file");
}

if($name_cnt == 0){
	print "NO DATA\n";
	exit 1;
}elsif($name_cnt == 1){
	system("./Save/$name_list[0] conv_list");
}else{
	$first = shift(@name_list);

	open(OUT, '>./conv_list');
	foreach $ent (@name_list){
		print OUT "./Save/$ent,0,0\n";
	}
	close(OUT);

	system("dmimgcalc infile=./Save/$first infile2=./Save/$ent outfile=comb_out.fits operation=add clobber=yes");

	system("rm conv_list");
}
