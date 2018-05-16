############################
# Change the task name!
############################
TASK = ACIS_bad_pix

include /data/mta/MTA/include/Makefile.MTA

BIN  = acis_bad_pix_create_data_table.perl acis_bad_pix_find_bad_pix.perl  acis_bad_pix_main_script acis_bad_pix_wrap_script acis_bias_compute_avg.perl acis_bias_get_info.perl acis_bias_plot_bias.perl acis_bias_plot_sub_info.perl acis_bias_print_today_data.perl acis_bias_html_update.perl acis_bad_pix_clean_up.perl acis_bias_run_all_ccd.perl acis_bias_moving_avg.perl find_moving_avg.perl cleanup.perl acis_bad_pix_clean_up_hist.perl create_new_and_imp_ccd_list.perl create_new_and_imp_col_list.perl fill_ccd_hist.perl fill_col_hist.perl create_pot_warm_pix.perl create_pot_warm_col.perl plot_ccd_history.perl plot_col_history.perl plot_front_ccd_history.perl plot_front_col_history.perl create_flk_col_hist.perl create_flk_pix_hist.perl acis_bad_pix_new_plot_set.perl

DOC  = README

install:
ifdef BIN
	rsync --times --cvs-exclude $(BIN) $(INSTALL_BIN)/
endif
ifdef DATA
	mkdir -p $(INSTALL_DATA)
	rsync --times --cvs-exclude $(DATA) $(INSTALL_DATA)/
endif
ifdef DOC
	mkdir -p $(INSTALL_DOC)
	rsync --times --cvs-exclude $(DOC) $(INSTALL_DOC)/
endif
ifdef IDL_LIB
	mkdir -p $(INSTALL_IDL_LIB)
	rsync --times --cvs-exclude $(IDL_LIB) $(INSTALL_IDL_LIB)/
endif
ifdef CGI_BIN
	mkdir -p $(INSTALL_CGI_BIN)
	rsync --times --cvs-exclude $(CGI_BIN) $(INSTALL_CGI_BIN)/
endif
ifdef PERLLIB
	mkdir -p $(INSTALL_PERLLIB)
	rsync --times --cvs-exclude $(PERLLIB) $(INSTALL_PERLLIB)/
endif
ifdef WWW
	mkdir -p $(INSTALL_WWW)
	rsync --times --cvs-exclude $(WWW) $(INSTALL_WWW)/
endif
