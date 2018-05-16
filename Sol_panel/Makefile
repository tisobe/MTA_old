############################
# Change the task name!
############################
TASK = Solar_panel_temp

include /data/mta/MTA/include/Makefile.MTA

BIN  = extract_data_from_dataseek.perl find_env_scelec.perl find_env_sensor.perl find_env_solar_pan.perl find_moving_avg.perl fit_sin_for_scelec.perl fit_sin_for_sol_pan.perl plot_elbi_sada.perl plot_scelec_env.perl plot_sensor_env.perl plot_solar_array_env.perl scelec_angle_comb.perl sensor_angle_comb.perl sep_col_scelec.perl sep_col_sensor.perl sep_col_solar_pan.perl sin_wave_scelec.perl sin_wave_sol_panel.perl solar_angle_main_script solar_angle_master.perl solar_angle_wrap_script solar_panel_angle_comb.perl

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
