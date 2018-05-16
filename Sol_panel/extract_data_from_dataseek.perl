#!/usr/bin/env /usr/local/bin/perl

#########################################################################################################
#													#
#	extract_data_from_dataseek.perl: extract data for a study of  Solar Panel/Electric Power/Fine	#
#					 Sensor Time Evolutions and Solar Angles			#
#													#
#				 	 This script must be run on mta					#
#													#
#		author: t. isobe (tisobe@cfa.harvard.edu)						#
#													#
#		last update: JUn 05, 2013								#
#													#
#########################################################################################################

#
#--- test case; set this "test"
#

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- set directory
#
if($comp_test =~ /test/i){
    $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list_test';
}else{
    $dir_list = '/data/mta/Script/Sol_panel/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#
#--- create a dummy file "test". this will be used by dataseeker
#

open(OUT, '>test');
close(OUT);

#
#--- find today date
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
$this_year = 1900 + $uyear;
$uyday++;

#
#--- if this is a test case, extract the data of 2010
#

if($comp_test =~ /test/i){
        $this_year = 2010;
        $uyday     = 365;
}

#
#--- create a list of files to find the last entry date
#
if($comp_test =~ /test/i){
#
#--- if it is a test, the data start from 2010,  Jan 1, 00:00:00
#
        $last_ydate = '2010:001:00:00:00';

}else{

	$input = `ls $data_dir/Ind_data_files/angle*.dat`;
	@list  = split(/\s+/, $input);
	$last  = pop (@list);
	
	open(FH, "$last");
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[0] =~ /\d/){		#---- this is format dependent; make sure that you do not change it!!
			if($atemp[1] < 48902399){
				next OUTER;
			}
			$last_date = $atemp[1];
		}elsif($atemp[2] =~ /\d/){
			if($atemp[2] < 48902399){
				next OUTER;
			}
			$last_date = $atemp[2];
		}
	}
	close(FH);

#
#--- convert the last entry date (in sec from 1998) to yyyy:ddd:hh:mm:ss format
#

	$last_ydate = time1998_to_ydate($last_date);
}

@btemp      = split(/:/, $last_ydate);

#
#--- set starting date
#

$start = $last_ydate;
$chk   = 0;
$ychk  = 0;			#---- checking whether we need to extract data over two different years.

#
#--- if the last update was in the last year, fill up the rest of the year
#

if($btemp[0] < $this_year){

#
#--- set stop time
#
	$stop  = "$this_year".":001:00:00:00";
	$yname = $btemp[0];			#---- $yname is used in extract_data to create file names
#
#--- sub to extract all data we need from dataseeker
#
	$ychk = 1;
	extract_data();

#
#---now set starting time of the beginning of this year
#
	$start = "$this_year".":001:00:00:00";
	$chk++;
}

#
#--- fill up the data for this year upto today.
#

$stop  = "$this_year".":$uyday".":00:00:00";
$yname = $this_year;

#
#--- just in a case, check whether the file for this year exits or not
#

$zip_file = "$data_dir".'/Ind_data_files/angle'."$yname".'.fits.gz';
$file_chk = `ls $data_dir/Ind_data_files/angle*fits.gz`;
$file_chk =~ s/\s+//g;
if($file_chk !~ /$zip_file/){
	$start = "$this_year".":001:00:00:00";
	$chk++;
}
$ychk = 0;
extract_data();

system("rm -rf test");

#################################################################################################
### extract_data: extract data from dataseeker                                                ###
#################################################################################################

sub extract_data{

#
#--- Sun Angle: set a few file names ----------------------------------------------------
#
	$out_file = "$data_dir".'/Ind_data_files/angle'."$yname".'.fits';
	$zip_file = "$data_dir".'/Ind_data_files/angle'."$yname".'.fits.gz';
	$old_file = "$data_dir".'/Ind_data_files/angle'."$yname".'.fits.gz~';
	$txt_file = "$data_dir".'/Ind_data_files/angle'."$yname".'.dat';
#
#--- extract data using dataseeker
#
	system("dataseeker.pl infile=test outfile=temp.fits  search_crit=\"columns=pt_suncent_ang timestart=$start timestop=$stop\" loginFile=$house_keeping/loginfile "); 
#
#--- check whether there is any new data, first check whether the actually the data file is created
#
	$dat_yes = 0;
	$test = `ls `;
	if($test !~ /temp.fits/){
#
#--- if the period is over two years, check second year before exiting
#
		if($ychk == 0){
			open(OUT2,">extract_test");
			print OUT2 "0";
			close(OUT2);
			exit 1;
		}
	}
	system("dmlist temp.fits opt=data > test_out");
	open(FH, "test_out");
	OUTER:
	while(<FH>){
		chomp $_;
		@atemp = split(/\s+/, $_);
		if($atemp[2] =~ /\d/){
			$data_yes++;
			last OUTER;
		}
	}	
	close(FH);
	system("rm -rf test_out");

#
#--- notify the main script that there is no new data
#
	if($data_yes == 0){
		if($ychk == 0){
			open(OUT2,">extract_test");
			print OUT2 "0";
			close(OUT2);
			system("rm -rf test");
			exit 1;
		}
#
#--- if there are new data, continue the analysis
#
	}else{
		system("dmcopy \"temp.fits[cols time,pt_suncent_ang]\" outfile=temp2.fits");
		if($chk == 0){
			system("cp $zip_file $old_file");
			system("gzip -d $zip_file");
			system("dmmerge \"$out_file,temp2.fits\" zout.fits outBlock='' columnList=''");
			system("mv zout.fits $out_file");
			system("rm -rf temp.fits temp2.fits");
		}else{
			system("mv temp2.fits $out_file");
			system("rm -rf temp.fits");
		}

#
#--- convert the file into ascii file
#
		$line = "$out_file".'[cols time,pt_suncent_ang]';
		system("dmlist \"$line\" opt=data > $txt_file");
		system("gzip $out_file");

#
#--- Solar Panel: set a few file names ----------------------------------------------------
#
		$out_file = "$data_dir".'/Ind_data_files/solar_panel'."$yname".'.fits';
		$zip_file = "$data_dir".'/Ind_data_files/solar_panel'."$yname".'.fits.gz';
		$old_file = "$data_dir".'/Ind_data_files/solar_panel'."$yname".'.fits.gz~';
		$txt_file = "$data_dir".'/Ind_data_files/solar_panel'."$yname".'.dat';
#
#--- extract data using dataseeker
#
		system("dataseeker.pl infile=test outfile=temp.fits search_crit=\"columns=_tmysada_avg,_tpysada_avg,_tsamyt_avg,_tsapyt_avg timestart=$start timestop=$stop\" loginFile=$house_keeping/loginfile"); 
		system("dmcopy \"temp.fits[cols time,tmysada_avg,tpysada_avg,tsamyt_avg,tsapyt_avg]\" outfile=temp2.fits");
		if($chk == 0){
			system("cp $zip_file $old_file");
			system("gzip -d $zip_file");
			system("dmmerge \"$out_file,temp2.fits\" zout.fits outBlock='' columnList=''");
			system("mv zout.fits $out_file");
			system("rm -rf temp.fits temp2.fits");
		}else{
			system("mv temp2.fits $out_file");
			system("rm -rf temp.fits");
		}

#
#--- convert the file into ascii file
#
		$line = "$out_file".'[cols time,tmysada_avg,tpysada_avg,tsamyt_avg,tsapyt_avg]';
		system("dmlist \"$line\" opt=data > $txt_file");
		system("gzip $out_file");

#
#--- SC Electric Power: set a few file names ----------------------------------------------------
#
		$out_file = "$data_dir".'/Ind_data_files/scelec_'."$yname".'.fits';
		$zip_file = "$data_dir".'/Ind_data_files/scelec_'."$yname".'.fits.gz';
		$old_file = "$data_dir".'/Ind_data_files/scelec_'."$yname".'.fits.gz~';
		$txt_file = "$data_dir".'/Ind_data_files/scelec_'."$yname".'_data';
#
#--- extract data using dataseeker
#
		system("dataseeker.pl infile=test outfile=temp.fits search_crit=\"columns=_elbi_avg,_elbv_avg,_obattpwr_avg,_ohrmapwr_avg,_oobapwr_avg  timestart=$start timestop=$stop\" loginFile=$house_keeping/loginfile "); 
		system("dmcopy \"temp.fits[cols time,elbi_avg,elbv_avg,obattpwr_avg,ohrmapwr_avg,oobapwr_avg]\" outfile=temp2.fits");
		if($chk == 0){
			system("cp $zip_file $old_file");
			system("gzip -d $zip_file");
			system("dmmerge \"$out_file,temp2.fits\" zout.fits outBlock='' columnList=''");
			system("mv zout.fits $out_file");
			system("rm -rf temp.fits temp2.fits");
		}else{
			system("mv temp2.fits $out_file");
			system("rm -rf temp.fits");
		}

#
#--- convert the file into ascii file
#
		$line = "$out_file".'[cols time,elbi_avg,elbv_avg,obattpwr_avg,ohrmapwr_avg,oobapwr_avg]';
		system("dmlist \"$line\" opt=data > $txt_file");
		system("gzip $out_file");
	
#
#--- Fine Sensor: set a few file names ----------------------------------------------------
#
		$out_file = "$data_dir".'/Ind_data_files/sensor'."$yname".'.fits';
		$zip_file = "$data_dir".'/Ind_data_files/sensor'."$yname".'.fits.gz';
		$old_file = "$data_dir".'/Ind_data_files/sensor'."$yname".'.fits.gz~';
		$txt_file = "$data_dir".'/Ind_data_files/sensor'."$yname".'.dat';
#
#--- extract data using dataseeker
#
		system("dataseeker.pl infile=test outfile=temp.fits search_crit=\"columns=_tfssbkt1_avg,_tfssbkt2_avg,_tpc_fsse_avg  timestart=$start timestop=$stop\" loginFile=$house_keeping/loginfile "); 
		system("dmcopy \"temp.fits[cols time,tfssbkt1_avg,tfssbkt2_avg,tpc_fsse_avg]\" outfile=temp2.fits");
		if($chk == 0){
			system("cp $zip_file $old_file");
			system("gzip -d $zip_file");
			system("dmmerge \"$out_file,temp2.fits\" zout.fits outBlock='' columnList=''");
			system("mv zout.fits $out_file");
			system("rm -rf temp.fits temp2.fits");
		}else{
			system("mv temp2.fits $out_file");
			system("rm -rf temp.fits");
		}
#
#--- convert the file into ascii file
#
		$line = "$out_file".'[cols time,tfssbkt1_avg,tfssbkt2_avg,tpc_fsse_avg]';
		system("dmlist \"$line\" opt=data > $txt_file");
		system("gzip $out_file");
#
#--- notify the main script that there are new data
#
		open(OUT2,">extract_test");
		print OUT2 "10000";
		close(OUT2);
	}
}

##############################################################################
### time1998_to_ydate: change sec from 1998 to year:ydate:hh:mm:ss         ###
##############################################################################

sub time1998_to_ydate{

        my ($date, $time, $chk, $year, $month, $hour, $min, $sec);

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
