#!/usr/bin/env /usr/local/bin/perl

#########################################################################
#									#
#	alignment_sim_twist_remove_dupl.perl: this script removes 	#
#				duplicated data line from data		#
#									#
#	author: t. isobe (tisobe@cfa.harvard.edu)			#
#									#
#	last update: Aug 04, 2014					#
#									#
#########################################################################

#
#--- checking whether this is a test
#
$comp_test = $ARGV[0];
chomp $comp_test;

############################################################
#---- set directries
if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ALIGNMENT/Sim_twist/house_keeping/dir_list';
}
open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);

############################################################

if($comp_test =~ /test/i){
	$line  = `cat $house_keeping/test_data_interval`;
	@atemp = split(/\//, $line);
	$year  = $atemp[0];
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);
	$umon++;
	$year = $uyear + 1900;
	
	if($umon <= 1){
		$year--;
	}
}


$name  = 'data_info_'."$year";
$list  = `ls $data_dir/$name `;
@list  = split(/\s+/, $list);

foreach $file (@list){
	open(FH, "$file");
	@orig = ();
	while(<FH>){
		chomp $_;
		push(@orig, $_);
	}
	close(FH);
	@sorted_orig = sort @orig;
	$comp = shift(@orig);
    $comp = $sorted_orig[0];
	@new = ($comp);
	OUTER:
	foreach $ent (@sorted_orig){
		if($ent eq $comp){
			next OUTER;
		}else{
			push(@new, $ent);
			$comp = $ent;
		}
	}

	open(OUT, ">$file");
	foreach $ent (@new){
		print OUT "$ent\n";
	}
}

$name  = 'data_extracted_'."$year";
$list = `ls $data_dir/H-* $data_dir/I-* $data_dir/S-* $data_dir/$name `;
@list = split(/\s+/, $list);

foreach $file (@list){
	open(FH, "$file");
	@orig = ();
	while(<FH>){
		chomp $_;
		push(@orig, $_);
	}
	close(FH);
	@sorted_orig = sort{$a<=>$b} @orig;
	$comp = shift(@orig);
	@new = ($comp);
	OUTER:
	foreach $ent (@orig){
		if($ent eq $comp){
			next OUTER;
		}else{
			push(@new, $ent);
			$comp = $ent;
		}
	}

	open(OUT, ">$file");
	foreach $ent (@new){
		print OUT "$ent\n";
	}
}
