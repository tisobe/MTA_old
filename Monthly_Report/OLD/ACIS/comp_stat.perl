#!/usr/bin/perl

#########################################################################################
#											#
#	comp_stat.perl: compute satistics for each node of I2/3 and S2/3		#
#											#
#	Takashi Isobe (tisobe@cfa.harvard.edu)						#
#											#
#	this must be run uder ascds (use ftool, and dm tools)				#
#											#
#	Input: fits image file								#
#	Outout: stat_result file							#
#											#
#	Aug. 8, 2000:	first version							#
#											#
#########################################################################################

print "Data file: ";
$input = <STDIN>;
chomp $input;

open(OUT,">./stat_result");
print OUT "$input\n";
print OUT "I2\n";
close(OUT);

$line = "$input".'[264:520,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[520:776,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[776:1032,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1032:1288,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

open(OUT,">>./stat_result");
print OUT "I3\n";
close(OUT);

$line = "$input".'[1310:1566,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1566:1822,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1822:2078,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[2078:2334,1414:2435]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

open(OUT,">>./stat_result");
print OUT "S2\n";
close(OUT);

$line = "$input".'[78:334,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[334:590,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[590:846,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[846:1102,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

open(OUT,">>./stat_result");
print OUT "S3\n";
close(OUT);

$line = "$input".'[1120:1376,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1376:1632,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1632:1888,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

$line = "$input".'[1888:2144,56:1076]';
`dmcopy "$line" temp.fits`;
`fimgstat temp.fits I/INDEF I/INDEF >> result`;
`rm temp.fits`;
print_stat();

###########################################################################
###  sub print_stat: get a avg, dev, min, and max from fimgstat output  ###
###########################################################################

sub print_stat{
	open(IN,"./result");
	while(<IN>) {
		chomp $_;
		@atemp = split(/=/,$_);
		if($atemp[0] eq 'The mean of the selected image                '){
			$mean = $atemp[1];
		}elsif($atemp[0] eq 'The standard deviation of the selected image  '){
			$dev = $atemp[1];
		}elsif($atemp[0] eq 'The minimum of selected image                 '){
			$min = $atemp[1];
		}elsif($atemp[0] eq 'The maximum of selected image                 ') {
			$max = $atemp[1];
		}
	}
	close(IN);
	open(OUT,">>./stat_result");
	print OUT "$mean\t$dev\t$min\t$max\n";
	close(OUT);
	`rm result`;
}
