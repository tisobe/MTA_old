############################
# Change the task name!
############################
TASK = ACIS_CTI

include /data/mta/MTA/include/Makefile.MTA

BIN  = acis_cti_adjust_cti.perl acis_cti_comp_adjusted_cti.perl acis_cti_det_adjust_cti.perl acis_cti_det_comp_adjusted_cti.perl acis_cti_det_plot_only.perl acis_cti_detrend_factor.perl acis_cti_find_new_entry.perl acis_cti_find_outlayer.perl acis_cti_find_time_temp_range.perl acis_cti_get_data.perl acis_cti_make_detrend_data.perl acis_cti_manual_cti.perl acis_cti_new_det_plot_only.perl acis_cti_new_det_plot_only_part.perl acis_cti_new_plot_only.perl acis_cti_plot_only.perl acis_cti_plot_script acis_cti_run_all_script.perl acis_cti_wrap_script

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
