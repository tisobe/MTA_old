#!/usr/bin/perl 

open(FH, './zzz');
while(<FH>){
    chomp $_;
    if($_ =~ /:/){
        next;
    }
    if($_ =~ /#/){
        next;
    }
    print "$_\n";
}
close(FH);

