############################
# Change the task name!
############################
TASK = Sci_run_interrupt

include /data/mta4/MTA/include/Makefile.MTA

BIN  = compute_ephin_avg.perl  extract_ace.perl  extract_ephin.perl  extract_ephin_pre2011.perl  extract_goes.perl  extract_goes_pre2011.perl  plot_first_page_fig.perl  sci_run_add_to_rad_zone_list.perl  sci_run_compute_gap.perl  sci_run_ephin_plot_main.perl  sci_run_find_hardness.perl  sci_run_get_ephin.perl  sci_run_get_rad_zone_info.perl  sci_run_get_radiation_data.perl  sci_run_main_run.perl  sci_run_print_html.perl  sci_run_print_top_html.perl  sci_run_rad_plot.perl  sub_html_template  sub_html_template_2011

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
