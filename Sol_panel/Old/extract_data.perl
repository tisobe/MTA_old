#!/usr/bin/perl

foreach $name ('tpc_fsse_avg','tfssbkt1_avg','tfssbkt2_avg',
#		'afsspc1v_avg',
#		'afsspc2v_avg','aocssi1_avg','aocssi2_avg','aocssi3_avg','aocssi4_avg',
#		'aospacs1b_avg','aospacs2b_avg','aospacs3b_avg','aospacs4b_avg',
#		'aospbcs1b_avg','aospbcs2b_avg','aospbcs3b_avg','aospbcs4b_avg'
		){
	$out = $name;
	$out =~ s/avg/data/;
	open(OUT, ">$out");
	for($year = 2000; $year < 2008; $year++){
		$file = './Cdata/sensor'."$year".'.fits[cols time,'."$name".']';
		system("dmlist \"$file\" opt=data > zout");
		open(FH, "zout");
		@time = ();
		@data = ();
		OUTER:
		while(<FH>){
			chomp @_;
			@atemp = split(/\s+/, $_);
			if($atemp[1] =~ /\d/){
				if($atemp[3] !~ /\d/){
					next OUTER;
				}
				print OUT "$atemp[2]\t$atemp[3]\n";
			}
		}
		close(FH);
	}
	close(OUT);
}
