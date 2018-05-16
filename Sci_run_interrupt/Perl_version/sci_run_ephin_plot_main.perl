#!/usr/bin/perl

#########################################################################################
#											#
# 	sci_run_ephin_plot_main.perl: a drving script to extract and plot ephin data.	#
#											#
#		author: t. isobe (tisobe@cfa.harvard.edu)				#
#											#
#		this script needs another script: get_ephin.perl			#
#											#
#		last update: Jun 10, 2011						#
#											#
#########################################################################################

#################################################################
#
#--- setting directories
#

open(FH, '/data/mta/Script/Interrupt/house_keeping/dir_list');
@list = ();
while(<FH>){
        chomp $_;
        push(@list, $_);
}
close(FH);

$bin_dir       = $list[0];
$data_dir      = $list[1];
$web_dir       = $list[2];
$house_keeping = $list[3];

################################################################

#
#--- if the next input is given as arguments, use it, otherwise, ask
#--- a user to type it in.
#

$data_file      = $ARGV[0];          #---- radiation data

if($data_file =~ /\w/){
	$usr   = `cat $data_dir/.dare`;
	$pword = `cat $data_dir/.hakama`;
}else{

#
#-- input file name
#

	print "Input file: ";
	$data_file = <STDIN>;

#
#--- arc4gl user name
#

	print "User: ";
	$usr = <STDIN>;

#
#--- arc4gl password
#

	print "PSWD: ";
	$pword = <STDIN>;
}

chomp $data_file;
chomp $usr;
chomp $pword;

open(FH, "$data_file");
@name  = ();
@start = ();
@stop  = ();
$total = 0;

while(<FH>){
	chomp $_;
	@atemp = split(/\s+/, $_);
	push(@name,$atemp[0]);
	push(@start, $atemp[1]);
	push(@end, $atemp[2]);
	$total++;
}
close(FH);

for($k = 0; $k < $total; $k++){

#
#--- call get_ephin.perl which actually extracts ephin data from archieve
#

	system("/opt/local/bin/perl $bin_dir/sci_run_get_ephin.perl $start[$k] $end[$k] $usr $pword $name[$k]");

	$data_file_name = "$web_dir".'/Data_dir/'."$name[$k]".'_eph.txt';
	system("mv ephin_data.txt $data_file_name");

	$gif_name       = "$web_dir".'/Ephin_plot/'."$name[$k]".'_eph.gif';
	$ps_name        = "$web_dir".'/Ps_dir/'."$name[$k]".'_eph.ps';

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $gif_name");

	system("mv pgplot.ps $ps_name");
}
