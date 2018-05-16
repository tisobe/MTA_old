############################
# Change the task name!
############################
TASK = Acis_hist

include /data/mta/MTA/include/Makefile.MTA

BIN  = acis_dose_extract_stat_data.perl acis_dose_extract_stat_data_month.perl acis_dose_get_data.perl acis_dose_make_cum.perl acis_dose_make_data_html.perl acis_dose_plot_exposure_stat.perl hrc_dose_extract_stat_data.perl hrc_dose_extract_stat_data_month.perl hrc_dose_get_data.perl hrc_dose_make_data_html.perl hrc_dose_plot_exposure_stat.perl hrc_dose_get_data_full_rage.perl hrc_dose_plot_exposure_stat_section.perl hrc_dose_make_data_html_full_range.perl hrc_dose_dff_comp_stat_month.perl hrc_dose_acc_comp_stat_month.perl hrc_dose_make_cum_add_to_last.perl dose_plot_html_for_plot.perl acis_dose_seprate_ccd.perl hrc_does_update_html.perl hrc_dose_conv_to_png.perl mta_conv_fits_img.perl hrc_create_full_dose_map.perl hrc_create_center_dose_map.perl hrc_does_wrap_script hrc_dose_main_script hrc_dose_update_main_html.perl hrc_dose_copy_data_to_may.perl hrc_dose_set_dir.perl acis_dose_correct_drop_rate.perl change_update_date.perl hrc_dose_monthly_plot_stat.perl hrc_dose_mays_script hrc_dose_mays_wrap_script full_exposure_section_plot_html_page

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
