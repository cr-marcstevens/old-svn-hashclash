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

#ifndef NEARCOLLISION_PAGE_HPP
#define NEARCOLLISION_PAGE_HPP

#include <gtkmm.h>
#include <hashutil5/timer.hpp>
#include "textviewfollowfile.hpp"
#include "run_program.hpp"

class NearCollisionPage
	: public Gtk::VBox
{
public:
	NearCollisionPage(unsigned idx, bool autostart = false);
	virtual ~NearCollisionPage();
	void setautostart() { 
		if (current_project_data && current_project_data->mode_automatic) 
			auto_step = 10; 
	}
private:
	unsigned index;
	void button_reset_clicked();
	void button_doforward_clicked();
	void button_dobackward_clicked();
	void button_doconnect_clicked();
	void button_docollfind_clicked();
	void button_abort_clicked();
	void do_abort();
	bool update();
	sigc::connection timer;
	Gtk::Notebook consoles;
	Gtk::HBox boxtop;
	Gtk::HButtonBox buttonbox;
	Gtk::Button button_reset, button_forward, button_backward, button_connect, button_collfind, button_abort;
	Gtk::Label label_eta;
	TextViewFollowFile console_forward, console_backward, console_connect, console_collfind;
	RunProgramChain run_forward, run_backward;
	RunProgram run_connect, run_collfind;
	bool started_collfind;
	hashutil::timer connect_runtime;
	int auto_step;
};

#endif // NEARCOLLISION_PAGE_HPP
