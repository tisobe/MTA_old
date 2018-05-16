############################
# Change the task name!
############################
TASK = Acis_sci_run

include /data/mta/MTA/include/Makefile.MTA

BIN  = acis_sci_run_err3x3.perl acis_sci_run_err5x5.perl acis_sci_run_get_data.perl acis_sci_run_high_evnt3x3.perl acis_sci_run_high_evnt5x5.perl acis_sci_run_plot.perl acis_sci_run_plot_long_term.perl acis_sci_run_print_html.perl acis_sci_run_rm_dupl.perl acis_sci_run_script acis_sci_run_te3x3.perl acis_sci_run_te5x5.perl acis_sci_run_wrap_script
DOC  = README
DATA = col_list2004

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
