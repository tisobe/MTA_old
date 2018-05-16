#!/usr/bin/env /usr/local/bin/perl

#################################################################################################
#												#
#	acis_bad_pix_create_data_table.perl: create a data display html sub pages 		#
#												#
#	author: t. isobe	(tisobe@cfa.harvard.edu)					#
#	last update: Apr 15, 2013								#
#												#
#################################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

#
#--- html5 conforming (Oct 5, 2012)
#
#######################################
#
#--- setting a few paramters
#

#--- output directory

if($comp_test =~ /test/i){
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list_test';
}else{
	$dir_list = '/data/mta/Script/ACIS/Bad_pixels/house_keeping/dir_list';
}
open(FH, $dir_list);

while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);



#######################################

for($iccd = 0; $iccd < 10; $iccd++){

#
#---- set pathes to directories, and other initializations
#
	$bad_pix = "$data_dir".'/Disp_dir/ccd'."$iccd";
	$hot_pix = "$data_dir".'/Disp_dir/hccd'."$iccd";
	$bad_col = "$data_dir".'/Disp_dir/col'."$iccd";

	$flickering_bad = "$data_dir".'/Disp_dir/flickering'."$iccd";
	$flichering_hot = "$data_dir".'/Disp_dir/hflickering'."$iccd";
	$flickering_col = "$data_dir".'/Disp_dir/flickering_col'."$iccd";

	$past_bad_pix = "$data_dir".'/Disp_dir/all_past_bad_pix'."$iccd";
	$past_hot_pix = "$data_dir".'/Disp_dir/all_past_hot_pix'."$iccd";
	$past_bad_col = "$data_dir".'/Disp_dir/all_past_bad_col'."$iccd";

	@bad_pix_list = ();
	@hot_pix_list = ();
	@bad_col_list = ();
	$bad_pix_cnt  = 0;
	$hot_pix_cnt  = 0;
	$bad_col_cnt  = 0;

	@flickering_bad_list = ();
	@flickering_hot_list = ();
	@flickering_col_list = ();
	$flickering_bad_cnt  = 0;
	$flickering_hot_cnt  = 0;
	$flickering_col_cnt  = 0;

	@past_bad_list = ();
	@past_hot_list = ();
	@past_col_list = ();
	$past_bad_cnt  = 0;
	$past_hot_cnt  = 0;
	$past_col_cnt  = 0;

#
#----- read data
#
	open(FH, "$bad_pix");
	while(<FH>){
		chomp $_;
		push(@bad_pix_list, $_);
		$bad_pix_cnt++;
	}
	close(FH);

	open(FH, "$hot_pix");
	while(<FH>){
		chomp $_;
		push(@hot_pix_list, $_);
		$hot_pix_cnt++;
	}
	close(FH);

	open(FH, "$bad_col");
	while(<FH>){
		chomp $_;
		push(@bad_col_list, $_);
		$bad_col_cnt++;
	}
	close(FH);

	open(FH, "$flickering_bad");
	while(<FH>){
		chomp $_;
		push(@flickering_bad_list, $_);
		$flickering_bad_cnt++;
	}
	close(FH);

	open(FH, "$flickering_hot");
	while(<FH>){
		chomp $_;
		push(@flickering_hot_list, $_);
		$flickering_hot_cnt++;
	}
	close(FH);

	open(FH, "$flickering_col");
	while(<FH>){
		chomp $_;
		push(@flickering_col_list, $_);
		$flickering_col_cnt++;
	}
	close(FH);

	open(FH, "$past_bad_pix");
	while(<FH>){
		chomp $_;
		push(@past_bad_list, $_);
		$past_bad_cnt++;
	}
	close(FH);

	open(FH, "$past_hot_pix");
	while(<FH>){
		chomp $_;
		push(@past_hot_list, $_);
		$past_hot_cnt++;
	}
	close(FH);

	open(FH, "$past_bad_col");
	while(<FH>){
		chomp $_;
		push(@past_col_list, $_);
		$past_col_cnt++;
	}
	close(FH);

#
#---- start printing the html pages
#
	$file_name = "$web_dir".'/Html_dir/ccd_data'."$iccd".'.html';

	open(OUT, ">$file_name");
	print OUT "<!DOCTYPE html>\n";
	print OUT "<html>\n";

	print OUT "<head>\n";
	print OUT "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />\n";
	print OUT "<style  type='text/css'>\n";
	print OUT "table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n";
	print OUT "td{text-align:center;padding:8px}\n";
	print OUT "a:link {color:#00CCFF;}\n";
	print OUT "a:visited {color:yellow;}\n";
	print OUT "span.nobr {white-space:nowrap;}\n";
	print OUT "</style>\n";

	print OUT '<title> ACIS Bad Pixel List:',"CCD$iccd",'</title>',"\n";
	print OUT "</head>\n";

	print OUT '<body style="color:#FFFFFF;background-color:#000000;">',"\n";

	print OUT '<h3>CCD',"$iccd",'</h3>',"\n";
	print OUT '<br /><br /><a href ="./mta_bad_pixel_list.html">Back to the main page</a>',"\n";
	print OUT '<br /><br />',"\n";

	print OUT '<table border=1 style="border-width:2px;text-align:top">',"\n";
	print OUT '<tr>',"\n";

	print OUT '<th>Current Warm Pixels</th>';
	print OUT '<th>Flickering Warm Pixels</th>';
	print OUT '<th>Past Warm Pixels</th>',"\n";

	print OUT '<th>Current Hot Pixels</th>';
	print OUT '<th>Flickering Hot Pixels</th>';
	print OUT '<th>Past Hot Pixels</th>',"\n";

	print OUT '<th>Current Warm Columns</th>';
	print OUT '<th>Flickering Warm Columns</th>';
	print OUT '<th>Past Warm Columns</th>',"\n";

	print OUT '</tr><tr>',"\n";;
#
#----- warm pixel cases
#
	print OUT '<td style="vertical-align:text-top;">',"\n";
	if($bad_pix_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $bad_pix_cnt; $i++){
			print OUT "<span class='nobr'>($bad_pix_list[$i])</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td style="vertical-align:text-top;">',"\n";
	if($flickering_bad_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $flickering_bad_cnt; $i++){
			print OUT "<span class='nobr'>$flickering_bad_list[$i]</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td style="vertical-align:text-top;">',"\n";
	if($past_bad_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $past_bad_cnt; $i++){
			print OUT "<span class='nobr'>$past_bad_list[$i]</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

#
#---- hot pixel cases
#
	print OUT '<td style="vertical-align:text-top;">',"\n";
	if($hot_pix_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $hot_pix_cnt; $i++){
			print OUT "<span class='nobr'>($hot_pix_list[$i])</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td>',"\n";
	if($flickering_hot_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $flickering_hot_cnt; $i++){
			print OUT "<span class='nobr'>$flickering_hot_list[$i]</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td style="vertical-align:text-top;">',"\n";
	if($past_hot_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $past_hot_cnt; $i++){
			print OUT "<span class='nobr'>$past_hot_list[$i]</span> <br />\n";
		}
	}
	print OUT '</td>',"\n";

#
#--- bad column cases
#

	print OUT '<td style="text-align:center;vertical-align:text-top;">',"\n";
	if($bad_col_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $bad_col_cnt; $i++){
			print OUT "$bad_col_list[$i] <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td style="text-align:center;vertical-align:text-top;">',"\n";
	if($flickering_col_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $flickering_col_cnt; $i++){
			print OUT "$flickering_col_list[$i] <br />\n";
		}
	}
	print OUT '</td>',"\n";

	print OUT '<td style="text-align:center;vertical-align:text-top;">',"\n";
	if($past_col_cnt == 0){
		print OUT '&#160;',"\n";
	}else{
		for($i = 0; $i < $past_col_cnt; $i++){
			print OUT "$past_col_list[$i] <br />\n";
		}
	}
	print OUT '</td>',"\n";


	print OUT '</tr>',"\n";
	print OUT '</table>',"\n";
	print OUT "</body>\n";
	print OUT "</html>\n";
	close(OUT);
}

