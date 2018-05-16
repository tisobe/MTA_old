#!/usr/bin/env /usr/local/bin/perl

use DBI;
use DBD::Sybase;

#########################################################################################
#											#
#	find_ar_lac.perl: this script finds AR LAC obsid from a recent observations	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		last update: Mar 06, 2013						#
#											#
#########################################################################################

#
#--- check whether this is a test case
#
$comp_test = $ARGV[0];
chomp $comp_test;

################################################################
#
#--- setting directories
#
open(FH, "/data/mta/Script/HRC/Gain/house_keeping/dir_list");
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

################################################################

#
#--- prepere for test
#
if($comp_test =~ /test/i){
	system("mkdir $test_web_dir");
	system("mkdir $test_data_dir");
	system("mkdir $test_web_dir/Plots");
	system("cp $house_keeping/Test_prep/hrc_obsid_list $test_web_dir/.");
	system("cp $house_keeping/Test_prep/fitting_results $test_web_dir/.");
}

if($comp_test =~ /test/i){
	open(FH, "$test_web_dir/hrc_obsid_list");
}else{
	open(FH, "$house_keeping/hrc_obsid_list");
}

while(<FH>){
	chomp $_;
	push(@obsid_list, $_);
}
close(FH);	

@data_list = ();
if($comp_test =~ /test/i){
	open(FH, "$house_keeping/Test_prep/candidate");
	while(<FH>){
		chomp $_;
		push(@data_list, $_);
	}
	close(FH);
}else{
	open(FH,'/data/mta_www/mp_reports/events/mta_events.html');
	while(<FH>){
        	chomp $_;
        	if($_ =~ /HRC/i && $_ =~/Obsid/i){
			@atemp = split(/Obsid:/, $_);
			@btemp = split(/\'/, $atemp[1]);
                	push(@data_list, $btemp[0]);
        	}
	}
	close(FH);
}

#-------------------------------------------------
#------ open up database and read target name etc
#-------------------------------------------------

#------------------------------------------------
#-------  database username, password, and server
#------------------------------------------------

$db_user="browser";
$server="ocatsqlsrv";
$db_passwd =`cat /data/mta/MTA/data/.targpass`;
chop $db_passwd;


#--------------------------------------
#------ output is save in ./Working_dir
#---------------------------------------

open(OUT, '>./candidate_list');
if($comp_test =~ /test/i){
	open(OUT2, ">> $test_web_dir/hrc_obsid_list");
}else{
	open(OUT2, ">> $house_keeping/hrc_obsid_list");
}

$ent_cnt = 0;

OUTER:
foreach $obsid (@data_list){
        foreach $comp (@obsid_list){
                if($obsid == $comp){
                        next OUTER;
                }
        }


#--------------------------------------
#-------- open connection to sql server
#--------------------------------------

        my $db = "server=$server;database=axafocat";
        $dsn1 = "DBI:Sybase:$db";
        $dbh1 = DBI->connect($dsn1, $db_user, $db_passwd, { PrintError => 0, RaiseError => 1});

        $sqlh1 = $dbh1->prepare(qq(select
                obsid,targid,seq_nbr,targname,grating,instrument
        from target where obsid=$obsid));
        $sqlh1->execute();
        @targetdata = $sqlh1->fetchrow_array;
        $sqlh1->finish;

        $targid     = $targetdata[1];
        $seq_nbr    = $targetdata[2];
        $targname   = $targetdata[3];
        $grating    = $targetdata[4];
        $instrument = $targetdata[5];

        $targid     =~ s/\s+//g;
        $seq_nbr    =~ s/\s+//g;
        $targname   =~ s/\s+//g;
        $grating    =~ s/\s+//g;
        $instrument =~ s/\s+//g;

	if($targname =~ /ARLAC/i){
		print OUT "$obsid\n";
		print OUT2 "$obsid\n";
	}
}
close(OUT);
close(OUT2);


