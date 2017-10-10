/**************************************************************************\
|
|    Copyright (C) 2009 Marc Stevens
|
|    This program is free software: you can redistribute it and/or modify
|    it under the terms of the GNU General Public License as published by
|    the Free Software Foundation, either version 3 of the License, or
|    (at your option) any later version.
|
|    This program is distributed in the hope that it will be useful,
|    but WITHOUT ANY WARRANTY; without even the implied warranty of
|    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
|    GNU General Public License for more details.
|
|    You should have received a copy of the GNU General Public License
|    along with this program.  If not, see <http://www.gnu.org/licenses/>.
|
\**************************************************************************/

#ifndef PROJECT_CONFIGURATOR_HEADER
#define PROJECT_CONFIGURATOR_HEADER

#include <string>
#include <iostream>
#include <gtkmm.h>
#include <boost/thread.hpp>
#include "project_data.hpp"

class BirthdaySearchOptions
	: public Gtk::Frame
{
public:
	BirthdaySearchOptions(birthdaysearch_config_type& birthdaysearchconfig
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~BirthdaySearchOptions();
	void load_all_changes() { load_changes(); }
private:
	void save_changes();
	void load_changes();
	void update_estimations();
	birthdaysearch_config_type& birthdaysearch_config;
	Gtk::Table table_options;
	Gtk::Entry label_complexity, label_cpuhours;
	Gtk::SpinButton cfg_hybridbits, cfg_path_type_range, cfg_max_blocks, cfg_max_memory, cfg_cell_nr_spu_threads, cfg_log_traillength;
	Gtk::CheckButton cfg_mem_hardlimit, cfg_use_cuda, cfg_use_cell;
};

class DiffPathConnectOptions
	: public Gtk::Frame
{
public:
	DiffPathConnectOptions(diffpathconnect_config_type& config
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~DiffPathConnectOptions();
	void load_all_changes() { load_changes(); }
private:
	void save_changes();
	void load_changes();
	diffpathconnect_config_type& diffpathconnect_config;
	Gtk::Table table_options;
	Gtk::SpinButton cfg_t_step, cfg_Qcond_start, cfg_max_complexity, cfg_abort_after_X_min;
	Gtk::CheckButton cfg_no_verify, cfg_no_enhance_path, cfg_show_statistics;
};

class DiffPathForwardChainOptions;
class DiffPathForwardOptions
	: public Gtk::Frame
{
public:
	DiffPathForwardOptions(diffpathforward_config_type& config
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~DiffPathForwardOptions();
	void load_all_changes() { load_changes(); }
	void set_chainparent(DiffPathForwardChainOptions* p) { chainparent = p; }
private:
	void save_changes();
	void save_changes_trange();
	void load_changes();
	DiffPathForwardChainOptions* chainparent;
	diffpathforward_config_type& diffpathforward_config;
	Gtk::Table table_options;
	Gtk::SpinButton cfg_max_conditions, cfg_min_sdr_weight, cfg_max_sdr_weight, cfg_max_sdrs
		, cfg_ab_nr_diffpaths, cfg_ab_naf_estimate, cfg_min_Q456_tunnel, cfg_min_Q91011_tunnel, cfg_min_Q314_tunnel
		, cfg_cond_tbegin, cfg_fill_fraction, cfg_ab_estimate_factor
		, cfg_t_step, cfg_t_range;
	Gtk::CheckButton cfg_include_naf, cfg_half_naf_weight, cfg_no_verify, cfg_normalt01;
};

class DiffPathForwardChainOptions
	: public Gtk::VBox
{
public:
	DiffPathForwardChainOptions(std::vector<diffpathforward_config_type>& chain_config
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~DiffPathForwardChainOptions();
	void load_all_changes();
	void update_tabs();
private:
	void add_page();
	void delete_page();
	void fill_notebook();
	void clear_notebook();
	Gtk::Notebook notebook;
	Gtk::HButtonBox buttonbox;
	Gtk::Button button_add, button_delete;
	std::vector<diffpathforward_config_type>& vec_diffpathforward_config;
	std::vector<DiffPathForwardOptions*> vec_diffpathforward_options;
	Glib::RefPtr<Gtk::SizeGroup> sg_labels, sg_options;
};

class DiffPathBackwardChainOptions;
class DiffPathBackwardOptions
	: public Gtk::Frame
{
public:
	DiffPathBackwardOptions(diffpathbackward_config_type& config
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~DiffPathBackwardOptions();
	void load_all_changes() { load_changes(); }
	void set_chainparent(DiffPathBackwardChainOptions* p) { chainparent = p; }
private:
	void save_changes();
	void save_changes_trange();
	void load_changes();
	DiffPathBackwardChainOptions* chainparent;
	diffpathbackward_config_type& diffpathbackward_config;
	Gtk::Table table_options;
	Gtk::SpinButton cfg_max_conditions, cfg_min_sdr_weight, cfg_max_sdr_weight, cfg_max_sdrs
		, cfg_ab_nr_diffpaths, cfg_ab_naf_estimate
		, cfg_cond_tend, cfg_fill_fraction, cfg_ab_estimate_factor
		, cfg_max_Q26up_cond
		, cfg_t_step, cfg_t_range;
	Gtk::CheckButton cfg_include_naf, cfg_half_naf_weight, cfg_no_verify;
};

class DiffPathBackwardChainOptions
	: public Gtk::VBox
{
public:
	DiffPathBackwardChainOptions(std::vector<diffpathbackward_config_type>& chain_config
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels
		, Glib::RefPtr<Gtk::SizeGroup> sizegroup_options);
	virtual ~DiffPathBackwardChainOptions();
	void load_all_changes();
	void update_tabs();
private:
	void add_page();
	void delete_page();
	void fill_notebook();
	void clear_notebook();
	Gtk::Notebook notebook;
	Gtk::HButtonBox buttonbox;
	Gtk::Button button_add, button_delete;
	std::vector<diffpathbackward_config_type>& vec_diffpathbackward_config;
	std::vector<DiffPathBackwardOptions*> vec_diffpathbackward_options;
	Glib::RefPtr<Gtk::SizeGroup> sg_labels, sg_options;
};

class ProjectConfigurator
	: public Gtk::Frame
{
public:
	ProjectConfigurator(project_data& projectdata, bool show_project_details = true);
	virtual ~ProjectConfigurator();
	void load_all_changes();
private:
	void save_changes();
	void load_changes();
	project_data& project;
	Glib::RefPtr<Gtk::SizeGroup> sizegroup_labels, sizegroup_options;
	Gtk::Notebook box_main;
	Gtk::Frame frame_project_details;
	Gtk::VBox vbox_tables;
	Gtk::Table table_project_details, table_project_configuration;
	Gtk::Entry cfg_filename1, cfg_filename2, cfg_workdir;
	BirthdaySearchOptions frame_birthdaysearch_options;
	DiffPathConnectOptions frame_diffpathconnect_options;
	DiffPathForwardChainOptions frame_diffpathforward_options;
	DiffPathBackwardChainOptions frame_diffpathbackward_options;
	Gtk::SpinButton cfg_nr_threads;	
	Gtk::CheckButton cfg_mode_automatic;
};

#endif // PROJECT_CONFIGURATOR_HEADER
