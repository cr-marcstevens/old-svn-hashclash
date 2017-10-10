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

#include <string>
#include <iostream>
#include <boost/lexical_cast.hpp>
#include <hashutil5/timer.hpp>
#include "mainwindow.hpp"
#include "birthdaysearch_page.hpp"
#include "startnearcollision.hpp"
#include "nearcollision_page.hpp"

BirthdaySearchPage::BirthdaySearchPage()
	: buttonbox(Gtk::BUTTONBOX_START), button_start("Start"), button_abort("Abort"), button_clear("Clear"), console(current_project_data->workdir / "work_birthdaysearch" / "birthdaysearch.log")
{
	set_border_width(10);
	set_spacing(10);
	pack_start(boxtop, false, true);
	pack_start(console, true, true);
	buttonbox.set_spacing(10);
	buttonbox.pack_start(button_start, false, true);
	buttonbox.pack_start(button_abort, false, true);
//	buttonbox.pack_start(button_clear, false, true);
	boxtop.set_spacing(10);
	boxtop.pack_start(buttonbox, false, true);
	boxtop.pack_start(label_eta, false, true);
	button_start.signal_clicked().connect( sigc::mem_fun(*this, &BirthdaySearchPage::button_start_clicked) );
	button_abort.signal_clicked().connect( sigc::mem_fun(*this, &BirthdaySearchPage::button_abort_clicked) );
	button_clear.signal_clicked().connect( sigc::mem_fun(*this, &BirthdaySearchPage::button_clear_clicked) );
	button_abort.set_sensitive(false);
	console.set_shadow_type(Gtk::SHADOW_IN);
	show_all();
	timer = Glib::signal_timeout().connect( sigc::mem_fun(*this, &BirthdaySearchPage::update), 100);
	isaborted = false;
}
BirthdaySearchPage::~BirthdaySearchPage()
{
	timer.disconnect();
}
bool BirthdaySearchPage::update() {
	static bool hasstarted = false;
	static hashutil::timer sw(false);
	if (runprogram.is_running()) {
		if (!sw.isrunning()) sw.start();
		label_eta.set_text("");
		hasstarted = true;
//		static timer sw(true);
//		if (!sw.is_running()) sw.start();
		button_start.set_sensitive(false);
		button_abort.set_sensitive(true);
		button_clear.set_sensitive(false);
try {
		std::string tmp = console.get_buffer()->get_text();
		std::string::size_type pos = tmp.find("Estimated complexity on trails: 2^("); //35.5953)
		if (pos == std::string::npos) return true;
		pos += std::string("Estimated complexity on trails: 2^(").size();
		std::string::size_type pos2 = tmp.find(")", pos+1);
		if (pos2 == std::string::npos) return true;
		double estcomplexity = boost::lexical_cast<double>(tmp.substr(pos,pos2-pos));
		pos = tmp.rfind("Work: 2^("); // 28.662), Coll.: 0(uf=0,nuf=0,?=0,q=0,rh=0), Blocks: 64
		if (pos == std::string::npos) return true;
		pos += std::string("Work: 2^(").size();
		pos2 = tmp.find(")", pos+1);
		if (pos2 == std::string::npos) return true;
		double work = boost::lexical_cast<double>(tmp.substr(pos,pos2-pos));
		double proc = pow(double(2), work) / pow(double(2), estcomplexity);
		double eta = (sw.time()/proc) * (1.0 - proc);
		boost::uint64_t minutes = boost::uint64_t(eta) / 60;
		boost::uint64_t hours = minutes / 60; minutes -= hours * 60;
		boost::uint64_t days = hours / 24; hours -= days * 24;
		static std::string etatime;
		static double oldproc = 0;
		if (oldproc != proc) {
			oldproc = proc;
			etatime = "";
			if (days)
				etatime = boost::lexical_cast<std::string>(days) + " days ";
			if (hours || days)
				etatime += boost::lexical_cast<std::string>(hours) + "h ";
			etatime += boost::lexical_cast<std::string>(minutes) + "m";
			if (days > 9999) etatime = "-"; // very large eta or negative eta
		}
		std::string donetime;
		minutes = sw.time()/60.0;
		hours = minutes / 60; minutes -= hours * 60;
		days = hours / 24; hours -= days * 24;
		if (days) donetime = boost::lexical_cast<std::string>(days) + " days ";
		if (hours || days) donetime += boost::lexical_cast<std::string>(hours) + "h ";
		donetime += boost::lexical_cast<std::string>(minutes) + "m";
		label_eta.set_text(boost::lexical_cast<std::string>(int(proc*100.0)) + "% done of estimated work, Time: " + donetime + ", ETA: " + etatime);
} catch (std::exception&) {} catch (...) {}
	} else {
		if (sw.isrunning()) sw.stop();
		bool chrun = children_running();
		button_start.set_sensitive(!chrun);
		button_abort.set_sensitive(false);
		button_clear.set_sensitive(!chrun);
		if (hasstarted && !isaborted) {			
			startnearcollision(0);
			if (mainworkspace->get_n_pages() <= 3) {
				mainworkspace->append_page(*Gtk::manage(new NearCollisionPage(0,current_project_data->mode_automatic)), "N.C. 0");
			} else {
				if (current_project_data->mode_automatic)
					dynamic_cast<NearCollisionPage*>(mainworkspace->get_nth_page(3))->setautostart();
			}
			mainworkspace->set_current_page(3);
			hasstarted = false;
		}
	}
	return true;
}
void BirthdaySearchPage::button_start_clicked()
{
	if (runprogram.is_running()) return;
	std::string args;
	args += " --threads " + boost::lexical_cast<std::string>(current_project_data->max_threads);
	if (current_project_data->birthdaysearch_config.use_cell)
		args += " --sputhreads " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.cell_nr_spu_threads);
	args += " --hybridbits " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.hybridbits);
	args += " --logtraillength " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.log_traillength);
	args += " --maxblocks " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.max_blocks);
	args += " --maxmemory " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.max_memory);
	args += " --pathtyperange " + boost::lexical_cast<std::string>(current_project_data->birthdaysearch_config.path_type_range);
	if (current_project_data->birthdaysearch_config.mem_hardlimit)
		args += " --memhardlimit";
	if (current_project_data->birthdaysearch_config.use_cuda)
		args += " --cuda_enable";

	args += " --workdir \"" + (current_project_data->workdir / "work_birthdaysearch").string() + "\"";
	args += " --inputfile1 \"" + (current_project_data->filename1).string() + "\"";
	args += " --inputfile2 \"" + (current_project_data->filename2).string() + "\"";
	args += " --outputfile1 \"" + (current_project_data->workdir / "file1_0.bin").string() + "\"";
	args += " --outputfile2 \"" + (current_project_data->workdir / "file2_0.bin").string() + "\"";
	args += " > \"" + (current_project_data->workdir / "work_birthdaysearch" / "birthdaysearch.log").string() + "\"";
	args += " 2>&1";
	std::cout << "birthdaysearch_cuda.exe " + args << std::endl;
	boost::filesystem::remove("./md5birthdaysearch.cfg");
	boost::filesystem::create_directory(current_project_data->workdir / "work_birthdaysearch");
	runprogram.run("birthdaysearch_cuda.exe " + args);
	button_start.set_sensitive(false);
	isaborted = false;
}
void BirthdaySearchPage::button_abort_clicked()
{
	isaborted = true;
	runprogram.kill();
}
void BirthdaySearchPage::button_clear_clicked()
{
	if (runprogram.is_running()) return;
	try {
	boost::filesystem::remove_all(current_project_data->workdir / "work_birthdaysearch");
	} catch (std::exception& e) { std::cerr << e.what() << std::endl; } catch (...) {}
}
