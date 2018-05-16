#!/usr/bin/perl

foreach $name ('aoalpang_avg','aobetang_avg'){
	$out = $name;
	$out =~ s/avg/data/;
	open(OUT, ">$out");
	for($year = 2000; $year < 2008; $year++){
		$file = './Cdata/pitch_'."$year".'.fits[cols time,'."$name".']';
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
