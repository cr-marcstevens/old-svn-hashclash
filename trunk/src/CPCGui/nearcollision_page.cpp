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

#include <iostream>
#include <boost/lexical_cast.hpp>
#include <boost/filesystem.hpp>
#include <hashutil5/sdr.hpp>
#include "startnearcollision.hpp"
#include "nearcollision_page.hpp"
#include "mainwindow.hpp"

unsigned connect_nr_cores = 0;

NearCollisionPage::NearCollisionPage(unsigned idx, bool autostart) 
	: buttonbox(Gtk::BUTTONBOX_START, 10)
	, button_reset("Reset N.C."), button_forward("Run Forward"), button_backward("Run Backward"), button_connect("Run Connect"), button_collfind("Run Coll.Find"), button_abort("Abort")
	, label_eta("")
	, console_forward(current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(idx)) / "forward.log")
	, console_backward(current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(idx)) / "backward.log")
	, console_connect(current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(idx)) / "connect.log")
	, console_collfind(current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(idx)) / "collfind.log")
	, index(idx)
	, started_collfind(false)
	, auto_step(-1)
{
	if (autostart)
		auto_step = 10;
	set_border_width(10);
	set_spacing(10);
	pack_start(boxtop, false, true);
	pack_start(consoles, true, true);
	buttonbox.set_spacing(10);
	buttonbox.pack_start(button_reset, false, true);
	buttonbox.pack_start(button_forward, false, true);
	buttonbox.pack_start(button_backward, false, true);
	buttonbox.pack_start(button_connect, false, true);
	buttonbox.pack_start(button_collfind, false, true);
	buttonbox.pack_start(button_abort, false, true);
	boxtop.set_spacing(10);
	boxtop.pack_start(buttonbox, false, true);
	boxtop.pack_start(label_eta, false, true);
	button_reset.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_reset_clicked) );
	button_forward.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_doforward_clicked) );
	button_backward.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_dobackward_clicked) );
	button_connect.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_doconnect_clicked) );
	button_collfind.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_docollfind_clicked) );
	button_abort.signal_clicked().connect( sigc::mem_fun(*this, &NearCollisionPage::button_abort_clicked) );
	button_connect.set_sensitive(false);
	button_collfind.set_sensitive(false);
	consoles.append_page(console_forward, "Forward");
	consoles.append_page(console_backward, "Backward");
	consoles.append_page(console_connect, "Connect");
	consoles.append_page(console_collfind, "Coll.Find");
	consoles.set_tab_pos(Gtk::POS_LEFT);
	console_forward.set_shadow_type(Gtk::SHADOW_IN);
	console_backward.set_shadow_type(Gtk::SHADOW_IN);
	console_connect.set_shadow_type(Gtk::SHADOW_IN);
	console_collfind.set_shadow_type(Gtk::SHADOW_IN);
	show_all();
	timer = Glib::signal_timeout().connect( sigc::mem_fun(*this, &NearCollisionPage::update), 100);
}

NearCollisionPage::~NearCollisionPage() 
{
}

void NearCollisionPage::button_abort_clicked()
{
	auto_step = -1; // stop auto mode on this page
	connect_nr_cores = 0;
	do_abort();	
}

void NearCollisionPage::do_abort()
{
	connect_runtime.stop();
	run_forward.kill();
	run_backward.kill();
	run_connect.kill();
	run_collfind.kill();
}

void NearCollisionPage::button_reset_clicked()
{
	button_abort_clicked();
	startnearcollision(index);
}

void NearCollisionPage::button_doforward_clicked()
{
	if (run_forward.is_running()) return;
	if (current_project_data->diffpathforward_config.size() == 0) return;
	std::vector< std::string > command_chain;
	for (unsigned i = 0; i < current_project_data->diffpathforward_config.size(); ++i) {
		diffpathforward_config_type& config = current_project_data->diffpathforward_config[i];
		boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(index));
		std::string args;
		args += " --workdir \"" + ncdir.string() + "\"";
		if (i == 0)
			args += " --inputfile \"" + (ncdir / "lowerpath.txt.gz").string() + "\"";
		args += " --tstep " + boost::lexical_cast<std::string>(config.t_step);
		args += " --trange " + boost::lexical_cast<std::string>(config.t_range);
		args += " --maxconditions " + boost::lexical_cast<std::string>(config.max_conditions);
		args += " --condtbegin " + boost::lexical_cast<std::string>(config.cond_tbegin);
		if (config.include_naf) args += " --includenaf";
		if (config.half_naf_weight) args += " --halfnafweight";
		args += " --maxweight " + boost::lexical_cast<std::string>(config.max_sdr_weight);
		args += " --minweight " + boost::lexical_cast<std::string>(config.min_sdr_weight);
		args += " --maxsdrs " + boost::lexical_cast<std::string>(config.max_sdrs);
		args += " --autobalance " + boost::lexical_cast<std::string>(config.ab_nr_diffpaths);
		args += " --fillfraction " + boost::lexical_cast<std::string>(config.fill_fraction);
		args += " --estimate " + boost::lexical_cast<std::string>(config.ab_estimate_factor);
		args += " --nafestimate " + boost::lexical_cast<std::string>(config.ab_naf_estimate);
		if (config.no_verify) args += " --noverify";
		if (config.normalt01) args += " --normalt01";
		args += " --minQ456tunnel " + boost::lexical_cast<std::string>(config.min_Q456_tunnel);
		args += " --minQ91011tunnel " + boost::lexical_cast<std::string>(config.min_Q91011_tunnel);
		args += " --minQ314tunnel " + boost::lexical_cast<std::string>(config.min_Q314_tunnel);
		args += " --threads " + boost::lexical_cast<std::string>(current_project_data->max_threads);
		int dm11 = 0;
		hashutil::sdr dm11naf = hashutil::naf(current_project_data->delta_m11[index]);
		for (int b = 0; b < 32; ++b) {
			if (dm11naf.get(b) == +1)
				dm11 = +(b+1);
			else if (dm11naf.get(b) == -1)
				dm11 = -(b+1);
		}
		args += " --diffm11 " + boost::lexical_cast<std::string>(dm11);
		if (i == 0)
			args += " > \"" + (ncdir / "forward.log").string() + "\"";
		else
			args += " >> \"" + (ncdir / "forward.log").string() + "\"";
		args += " 2>&1";
		std::cout << "diffpathforward.exe " + args << std::endl;
		command_chain.push_back("diffpathforward.exe " + args);
	}
	boost::filesystem::remove("./md5diffpathforward.cfg");
	run_forward.run(command_chain);
	button_forward.set_sensitive(false);
	consoles.set_current_page(0);
	auto_step = 0;
}

void NearCollisionPage::button_dobackward_clicked()
{
	if (run_backward.is_running()) return;
	if (current_project_data->diffpathbackward_config.size() == 0) return;
	std::vector< std::string > command_chain;
	for (unsigned i = 0; i < current_project_data->diffpathbackward_config.size(); ++i) {
		diffpathbackward_config_type& config = current_project_data->diffpathbackward_config[i];
		boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(index));
		std::string args;
		args += " --workdir \"" + ncdir.string() + "\"";
		if (i == 0)
			args += " --inputfile \"" + (ncdir / "upperpath.txt.gz").string() + "\"";
		args += " --tstep " + boost::lexical_cast<std::string>(config.t_step);
		args += " --trange " + boost::lexical_cast<std::string>(config.t_range);
		args += " --maxconditions " + boost::lexical_cast<std::string>(config.max_conditions);
		args += " --condtend " + boost::lexical_cast<std::string>(config.cond_tend);
		if (config.include_naf) args += " --includenaf";
		if (config.half_naf_weight) args += " --halfnafweight";
		args += " --maxweight " + boost::lexical_cast<std::string>(config.max_sdr_weight);
		args += " --minweight " + boost::lexical_cast<std::string>(config.min_sdr_weight);
		args += " --maxsdrs " + boost::lexical_cast<std::string>(config.max_sdrs);
		args += " --autobalance " + boost::lexical_cast<std::string>(config.ab_nr_diffpaths);
		args += " --fillfraction " + boost::lexical_cast<std::string>(config.fill_fraction);
		args += " --estimate " + boost::lexical_cast<std::string>(config.ab_estimate_factor);
		args += " --nafestimate " + boost::lexical_cast<std::string>(config.ab_naf_estimate);
		if (config.no_verify) args += " --noverify";
		args += " --maxQ26upcond " + boost::lexical_cast<std::string>(config.max_Q26up_cond);
		args += " --threads " + boost::lexical_cast<std::string>(current_project_data->max_threads);
		int dm11 = 0;
		hashutil::sdr dm11naf = hashutil::naf(current_project_data->delta_m11[index]);
		for (int b = 0; b < 32; ++b) {
			if (dm11naf.get(b) == +1)
				dm11 = +(b+1);
			else if (dm11naf.get(b) == -1)
				dm11 = -(b+1);
		}
		args += " --diffm11 " + boost::lexical_cast<std::string>(dm11);
		if (i == 0)
			args += " > \"" + (ncdir / "backward.log").string() + "\"";
		else
			args += " >> \"" + (ncdir / "backward.log").string() + "\"";
		args += " 2>&1";
		std::cout << "diffpathbackward.exe " + args << std::endl;
		command_chain.push_back("diffpathbackward.exe " + args);
	}
	boost::filesystem::remove("./md5diffpathbackward.cfg");
	run_backward.run(command_chain);
	button_backward.set_sensitive(false);
	consoles.set_current_page(1);
	auto_step = 1;
}

void NearCollisionPage::button_doconnect_clicked()
{
	if (run_connect.is_running()) return;
	connect_runtime.start();
	std::string args;
	diffpathconnect_config_type& config = current_project_data->diffpathconnect_config;
	boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(index));
	args += " --index 0 --mod 1";
	args += " --workdir \"" + ncdir.string() + "\"";
	args += " --inputfilelow \"" + (ncdir / ("paths" + boost::lexical_cast<std::string>(config.t_step-1) + "_0of1.bin.gz")).string() + "\"";
	args += " --inputfilehigh \"" + (ncdir / ("paths" + boost::lexical_cast<std::string>(config.t_step+4) + "_0of1.bin.gz")).string() + "\"";
	args += " --maxcomplexity " + boost::lexical_cast<std::string>(config.max_complexity);
	args += " --Qcondstart " + boost::lexical_cast<std::string>(config.Qcond_start);
	args += " --tstep " + boost::lexical_cast<std::string>(config.t_step);
	args += " --threads " + boost::lexical_cast<std::string>(current_project_data->max_threads);
	connect_nr_cores = current_project_data->max_threads;
	if (config.no_enhance_path) args += " --noenhancepath";
	if (config.no_verify) args += " --noverify";
	if (config.show_statistics) args += " --showstatistics";
	int dm11 = 0;
	hashutil::sdr dm11naf = hashutil::naf(current_project_data->delta_m11[index]);
	for (int b = 0; b < 32; ++b) {
		if (dm11naf.get(b) == +1)
			dm11 = +(b+1);
		else if (dm11naf.get(b) == -1)
			dm11 = -(b+1);
	}
	args += " --diffm11 " + boost::lexical_cast<std::string>(dm11);
	args += " > \"" + (ncdir / ("connect.log")).string() + "\"";
	args += " 2>&1";
	std::cout << "diffpathconnect.exe " + args << std::endl;
	run_connect.run("diffpathconnect.exe " + args);
	button_connect.set_sensitive(false);
	consoles.set_current_page(2);
	auto_step = 2;
}

void NearCollisionPage::button_docollfind_clicked()
{
	if (run_collfind.is_running()) return;
	std::string args;
	boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(index));
	args += " --threads " + boost::lexical_cast<std::string>(current_project_data->max_threads);
	args += " --findcollision";
	int dm11 = 0;
	hashutil::sdr dm11naf = hashutil::naf(current_project_data->delta_m11[index]);
	for (int b = 0; b < 32; ++b) {
		if (dm11naf.get(b) == +1)
			dm11 = +(b+1);
		else if (dm11naf.get(b) == -1)
			dm11 = -(b+1);
	}
	args += " --diffm11 " + boost::lexical_cast<std::string>(dm11);
	args += " --inputfile1 \"" + (ncdir / "bestpaths.bin.gz").string() + "\"";
	args += " --workdir \"" + ncdir.string() + "\"";		
	args += " > \"" + (ncdir / ("collfind.log")).string() + "\"";
	args += " 2>&1";
	std::cout << "diffpathhelper.exe " + args << std::endl;
	run_collfind.run("diffpathhelper.exe " + args);
	started_collfind = true;
	button_collfind.set_sensitive(false);
	consoles.set_current_page(3);
	auto_step = 3;
}

bool NearCollisionPage::update()
{
	if (current_project_data->diffpathconnect_config.abortafterXmin >= 0 
		&& connect_runtime.isrunning() 
		&& run_connect.is_running()
		&& connect_runtime.time()*connect_nr_cores > double(current_project_data->diffpathconnect_config.abortafterXmin)*60.0
		)
	{
		do_abort();
		return true;
	}
	bool childsrunning = children_running() | run_forward.is_running() | run_backward.is_running() | run_connect.is_running() | run_collfind.is_running();
	const Gtk::ReliefStyle relnormal = Gtk::RELIEF_NORMAL, relrun = Gtk::RELIEF_NORMAL, relnorun = Gtk::RELIEF_NONE;
	if (childsrunning) {
		button_forward.set_relief(run_forward.is_running() ? relrun : relnorun);
		button_backward.set_relief(run_backward.is_running() ? relrun : relnorun);
		button_connect.set_relief(run_connect.is_running() ? relrun : relnorun);
		button_collfind.set_relief(run_collfind.is_running() ? relrun : relnorun);
		button_reset.set_relief(relnorun);
	} else {
		button_forward.set_relief(relnormal);
		button_backward.set_relief(relnormal);
		button_connect.set_relief(relnormal);
		button_collfind.set_relief(relnormal);
		button_reset.set_relief(relnormal);
	}
	if (auto_step >= 0 && current_project_data->mode_automatic && !childsrunning) {
		++auto_step;
		switch (auto_step) {
			case 1:
				if (0 != run_forward.get_returnvalue()) {
					auto_step = -1;
					break;
				}
				button_dobackward_clicked();
				break;
			case 2:
				if (0 != run_backward.get_returnvalue()) {
					auto_step = -1;
					break;
				}
				button_doconnect_clicked();
				break;
			case 3:
				if (0 != run_connect.get_returnvalue()
					&& !(current_project_data->diffpathconnect_config.abortafterXmin >= 0 && connect_runtime.time()*connect_nr_cores > double(current_project_data->diffpathconnect_config.abortafterXmin)*60.0)
					)
				{
					auto_step = -1;
					break;
				}
				button_docollfind_clicked();
				break;
			case 11:
				button_doforward_clicked();
				break;
			default:
				auto_step = -1;
				break;
		}
		return true;
	}
	if (!is_visible()) return true;
	button_forward.set_sensitive(!childsrunning);
	button_backward.set_sensitive(!childsrunning);
	button_connect.set_sensitive(!childsrunning);
	button_collfind.set_sensitive(!childsrunning);
	button_abort.set_sensitive(run_forward.is_running() || run_backward.is_running() || run_connect.is_running() || run_collfind.is_running());
	button_reset.set_sensitive(!childsrunning);

	if (!run_collfind.is_running() && started_collfind) {
		started_collfind = false;
		boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<std::string>(index));
		for (boost::filesystem::directory_iterator dit(ncdir); dit != boost::filesystem::directory_iterator(); ++dit) {
			if (dit->path().filename().substr(0,6) == "coll1_") {
				std::string fn1 = dit->path().filename(), fn2 = fn1;
				fn2.replace(4, 1, "2");
				if (boost::filesystem::is_regular_file(ncdir / fn2)) {
					if (startnearcollision(index+1, ncdir / fn1, ncdir / fn2)) {
						boost::filesystem::remove(ncdir / fn1);
						boost::filesystem::remove(ncdir / fn2);
						button_abort_clicked();
						if (mainworkspace->get_n_pages() <= 3+index+1) {
							mainworkspace->append_page(*Gtk::manage(new NearCollisionPage(index+1,current_project_data->mode_automatic)), "N.C. "+boost::lexical_cast<std::string>(index+1));
						} else {
							if (current_project_data->mode_automatic)
								dynamic_cast<NearCollisionPage*>(mainworkspace->get_nth_page(3+index+1))->setautostart();
						}
						mainworkspace->set_current_page(3+index+1);
					}
				}
			}
		}
	}
	return true;
}
