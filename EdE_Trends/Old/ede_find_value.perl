#!/usr/bin/env /usr/local/bin/perl
 
 BEGIN
 {
         $ENV{SYBASE} = "/soft/SYBASE15.7";
 }
 
###### BEGIN { $ENV{'SYBASE'} = "/soft/SYBASE_OCS15"; }
use DBI;
use DBD::Sybase;

#########################################################################################
#											#
#	ede_find_value.perl: this script finds ede values for a given line and grating.	#
#											#
#	author:	t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: May 08, 2017							#
#											#
#########################################################################################
#
#--- check whether this is a test case
#
OUTER:
for($i = 0; $i < 10; $i++){
	if($ARGV[$i] =~ /test/i){
		$comp_test = 'test';
		last OUTER;
	}elsif($ARGV[$i] eq ''){
		$comp_test = '';
		last OUTER;
	}
}
#----------------
#--- read directory lists
#

open(FH, "/data/mta/Script/Grating/EdE/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

#-----------------------

$line  = $ARGV[0];		# such as 1.022. 1.02 gives more data, but include 1.019< line < 1.03
$grat  = $ARGV[1];		# htg, mtg, or ltg
$dfile = $ARGV[2];
chomp $line;
chomp $gart;
chomp $dfile;
#
#--- read in the past data
#
@past_obsid = ();
open(FH, "$dfile");
while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	if($atemp[0] =~ /\d/){
		push(@past_obsid, $atemp[0]);
	}
}
close(FH);
#
#--- check the line around the specified range; assume that the accuracy of the line given
#--- is 0.001 
#
$line1   = $line - 0.002;
$line2   = $line - 0.001;
$line3   = $line + 0.001;
$line4   = $line + 0.002;

#
#--- get data from a different database  depending on which grating is used
#
if($comp_test =~ /test/i){
	if($grat =~ /htg/i){
		system("cp $house_keeping/Test_prep/htg temp");
	}elsif($grat =~ /mtg/i){
		system("cp $house_keeping/Test_prep/mtg temp");
	}elsif($grat =~ /ltg/i){
		system("cp $house_keeping/Test_prep/ltg temp");
	}
}else{
	if($grat =~ /htg/i){
		system("ls /data/mta/www/mta_grat/*/*/obsid_*_L1.5_S1HEGp1_linelist.txt > temp");
	}elsif($grat =~ /mtg/i){
		system("ls /data/mta/www/mta_grat/*/*/obsid_*_L1.5_S1MEGp1_linelist.txt > temp");
	}elsif($grat =~ /ltg/i){
		system("ls /data/mta/www/mta_grat/*/*/obsid_*_L1.5_S1LEGp1_linelist.txt > temp");
	}else{
		print "Grating choice is wrong. Please try agin\n";
		exit 1;
	}
}

@o_list = ();
@t_list = ();
#
#---- now start reading the data
#
open(FH, './temp');
OUTER2:
while(<FH>){
	chomp $_;
	$file = $_;
#
#--- skip the file which we already examined in the past
#
	@atemp = split(/obsid_/, $_);
	@btemp = split(/_/, $atemp[1]);
	$obsid = $btemp[0];
	foreach $comp (@past_obsid){
		if($obsid == $comp){
			next OUTER2;
		}
	}
#
#--- skip the duplicated data
#
	foreach $comp (@o_list){
		if($obsid == $comp){
			next OUTER2;
		}
	}
	push(@o_list, $obsid);

	open(IN, "$file");
	OUTER:
	while(<IN>){
		chomp $_;
		if($_ =~ /\*/){
			next OUTER;
#			$_ =~ s/\*//g;
		}
		@atemp = split(/\s+/, $_);
		if($atemp[1] =~ /\d/){
#
#---- the line of the energy and +/- 0.002 are extracted
#
			if($atemp[3] =~ /^$line/ || $atemp[3] =~ /^$line2/ || $atemp[3] =~ /^$line3/
						 || $atemp[3] =~ /^$line1/ || $atemp[3] =~ /^$line4/
					){
#
#---- if ede is too large, ignore it. here we set the limit to ede = 2000
#
				if($atemp[6] > 2000){
					next OUTER;
				}
#
#--- obtain a few descriptive data for the obsid
#
				read_databases();
#
#---- skip if it is ACIS LETG
#
				if($grat =~ /ltg/ && $instrument =~/acis/i){
					next OUTER;
				}
#
#--- find out DOM from the given date format
#
				@ctemp = split(/\s+/, $soe_st_sched_date);
				$year = $ctemp[2];
				$month = $ctemp[0];
				$date  = $ctemp[1];
				if($ctemp[3]=~ /AM/i){
					@dtemp = split(/AM/, $ctemp[3]);
					@ftemp = split(/:/, $dtemp[0]);
					$fin   = $ftemp[0]/24 + $ftemp[1]/1440;
					$ftime = sprintf "%3.2f", $fin;
				}else{
					@dtemp = split(/PM/, $ctemp[3]);
					@ftemp = split(/:/, $dtemp[0]);
					$fin   = ($ftemp[0]+ 12)/24 + $ftemp[1]/1440;
					$ftime = sprintf "%3.2f", $fin;
				}
#
#--- save the data so that we can sort it by date later
#
				$acc_date = conv_date_dom($year, $month, $date);
				$leng = sprintf "%1.5f", $atemp[3];
				$dom  = $acc_date + $ftime;
				$domp = sprintf "%7.2f", $dom;
				$sig  = sqrt(($atemp[6] * $atemp[6]) * ($atemp[5] * $atemp[5])/($atemp[4] * $atemp[4]));
				$err  = sprintf "%5.1f", $sig;
				$ede  = sprintf "%5.1f", $atemp[6];
				$line = "$obsid\t$leng\t\t$atemp[4]\t$atemp[5]\t$ede\t$err\t$soe_st_sched_date\t$domp";
				push(@t_list, $dom);
				%{data.$dom}= (data => ["$line"]);
			}
		}
	}
	close(IN);
}
close(FH);
#
#--- sort by date before print out the data
#
@temp = sort{$a<=>$b} @t_list;

open(OUT, ">>$dfile");
$dfile2 = "$dfile".'_new';
open(OUT2, ">$dfile2");

foreach $time (@temp){
	print OUT  "${data.$time}{data}[0]\n";
	print OUT2 "${data.$time}{data}[0]\n";
}

system("rm -rf temp");


################################################################################
### sub read_databases: read out values from databases                       ###
################################################################################

sub read_databases{

#------------------------------------------------
#-------  database username, password, and server
#------------------------------------------------

#        $db_user="browser";
#        $server="ocatsqlsrv";
#       $db_user="browser";
#       $server="sqlbeta";
        $server="ocatsqlsrv";
        $db_user   = "mtaops_internal_web";
        $db_passwd =`cat /data/mta4/CUS/www/Usint/Pass_dir/.targpass_internal`;
        chomp $db_passwd;

#--------------------------------------
#-------- open connection to sql server
#--------------------------------------

        my $db = "server=$server;database=axafocat";
        $dsn1 = "DBI:Sybase:$db";
        $dbh1 = DBI->connect($dsn1, $db_user, $db_passwd, { PrintError => 0, RaiseError => 1});

#------------------------------------------------------
#---------------  get stuff from target table, clean up
#------------------------------------------------------

        $sqlh1 = $dbh1->prepare(qq(select
                obsid,targid,seq_nbr,targname,obj_flag,object,si_mode,photometry_flag,
                vmagnitude,ra,dec,est_cnt_rate,forder_cnt_rate,y_det_offset,z_det_offset,
                raster_scan,dither_flag,approved_exposure_time,pre_min_lead,pre_max_lead,
                pre_id,seg_max_num,aca_mode,phase_constraint_flag,ocat_propid,acisid,
                hrcid,grating,instrument,rem_exp_time,soe_st_sched_date,type,lts_lt_plan,
                mpcat_star_fidlight_file,status,data_rights,tooid,description,
                total_fld_cnt_rate, extended_src,uninterrupt, multitelescope,observatories,
                tooid, constr_in_remarks, group_id, obs_ao_str, roll_flag, window_flag
        from target where obsid=$obsid));
        $sqlh1->execute();
        @targetdata = $sqlh1->fetchrow_array;
        $sqlh1->finish;

#--------------------------------------------------------------------------
#------- fill values from target table
#------- doing this the long way so I can see what I'm doing and make sure
#------- everything is accounted for
#--------------------------------------------------------------------------

        $targid =$targetdata[1];
        $seq_nbr =$targetdata[2];
        $targname =$targetdata[3];
        $obj_flag =$targetdata[4];
        $object = $targetdata[5];
        $si_mode =$targetdata[6];
        $photometry_flag =$targetdata[7];
        $vmagnitude =$targetdata[8];
        $ra =$targetdata[9];
        $dec =$targetdata[10];
        $est_cnt_rate =$targetdata[11];
        $forder_cnt_rate =$targetdata[12];
        $y_det_offset = $targetdata[13];
        $z_det_offset = $targetdata[14];
        $raster_scan = $targetdata[15];
        $dither_flag = $targetdata[16];
        $approved_exposure_time = $targetdata[17];
        $pre_min_lead = $targetdata[18];
        $pre_max_lead = $targetdata[19];
        $pre_id = $targetdata[20];
        $seg_max_num =$targetdata[21];
        $aca_mode = $targetdata[22];
        $phase_constraint_flag = $targetdata[23];
        $proposal_id = $targetdata[24];
        $acisid = $targetdata[25];
        $hrcid = $targetdata[26];
        $grating =$targetdata[27];
        $instrument =$targetdata[28];
        $rem_exp_time =$targetdata[29];
        $soe_st_sched_date =$targetdata[30];
        $type = $targetdata[31];
        $lts_lt_plan =$targetdata[32];
        $mpcat_star_fidlight_file = $targetdata[33];
        $status = $targetdata[34];
        $data_rights =$targetdata[35];
        $tooid  =$targetdata[36];
        $description  =$targetdata[37];
        $total_fld_cnt_rate  =$targetdata[38];
        $extended_src  =$targetdata[39];
        $uninterrupt =$targetdata[40];
        $multitelescope = $targetdata[41];
        $observatories = $targetdata[42];
        $tooid = $targetdata[43];
        $constr_in_remarks = $targetdata[44];
        $group_id = $targetdata[45];
        $obs_ao_str = $targetdata[46];
        $roll_flag = $targetdata[47];
        $window_flag = $targetdata[48];
}


###########################################################################
###      conv_date_dom: modify data/time format                       #####
###########################################################################

sub conv_date_dom {

#############################################################
#       Input:  $year: year in a format of 2004
#               $month: month in a formt of  5 or 05
#               $day:   day in a formant fo 5 05
#
#       Output: acc_date: day of mission returned
#############################################################

        my($year, $month, $day, $chk, $acc_date);

        ($year, $month, $day) = @_;

	if($month !~ /\d/){
		if($month =~ /JAN/i){
			$month = 1;
		}elsif($month =~ /FEB/i){
			$month = 2;
		}elsif($month =~ /MAR/i){
			$month = 3;
		}elsif($month =~ /APR/i){
			$month = 4;
		}elsif($month =~ /MAY/i){
			$month = 5;
		}elsif($month =~ /JUN/i){
			$month = 6;
		}elsif($month =~ /JUL/i){
			$month = 7;
		}elsif($month =~ /AUG/i){
			$month = 8;
		}elsif($month =~ /SEP/i){
			$month = 9;
		}elsif($month =~ /OCT/i){
			$month = 10;
		}elsif($month =~ /NOV/i){
			$month = 11;
		}elsif($month =~ /DEC/i){
			$month = 12;
		}
	}

        $acc_date = ($year - 1999) * 365;

        if($year > 2000 ) {
                $acc_date++;
        }elsif($year >  2004 ) {
                $acc_date += 2;
        }elsif($year > 2008) {
                $acc_date += 3;
        }elsif($year > 2012) {
                $acc_date += 4;
        }elsif($year > 2016) {
                $acc_date += 5;
        }

        $acc_date += $day - 1;
        if ($month == 2) {
                $acc_date += 31;
        }elsif ($month == 3) {
                $chk = 4.0 * int(0.25 * $year);
                if($year == $chk) {
                        $acc_date += 59;
                }else{
                        $acc_date += 58;
                }
        }elsif ($month == 4) {
                $acc_date += 90;
        }elsif ($month == 5) {
                $acc_date += 120;
        }elsif ($month == 6) {
                $acc_date += 151;
        }elsif ($month == 7) {
                $acc_date += 181;
        }elsif ($month == 8) {
                $acc_date += 212;
        }elsif ($month == 9) {
                $acc_date += 243;
        }elsif ($month == 10) {
                $acc_date += 273;
        }elsif ($month == 11) {
                $acc_date += 304;
        }elsif ($month == 12) {
                $acc_date += 334;
        }
        $acc_date -= 202;
        return $acc_date;
}

