#!/usr/bin/perl 


$pattern = '2013-02-';

$input = `ls ccd*`;
@list  = split(/\n+/, $input);

@id_list = ();

foreach $ent (@list){
	open(FH, "$ent");
	open(OUT, "> ./temp");
	while(<FH>){
		chomp $_;
		if($_ =~ /$pattern/){
			@atemp = split(/\s+/, $_);
			push(@id_list, $atemp[1]);
		}else{
			print OUT "$_\n";
		}
	}
	close(OUT);
	close(FH);

	system("mv ./temp $ent");
}

@temp = sort{$a<=>$b} @id_list;

$first = shift(@temp);
@new = ($first);

OUTER:
foreach $ent (@temp){
	foreach $comp (@new){
		if($ent == $comp){
			next OUTER;
		}
	}
	push(@new, $ent);
}

open(OUT, ">./test_obid_list");
foreach $ent (@new){
	print OUT "$ent\n";
}
close(OUT);
