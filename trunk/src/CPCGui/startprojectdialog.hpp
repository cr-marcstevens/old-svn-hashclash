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

#ifndef GTKMM_STARTPROJECTDIALOG_HEADER
#define GTKMM_STARTPROJECTDIALOG_HEADER

#include <gtkmm.h>
#include "project_data.hpp"

class StartProjectDialog
	: public Gtk::Dialog
{
public:
	StartProjectDialog();
	virtual ~StartProjectDialog();

	project_data::path_type get_filename1() const { return entry_filename1.get_text().c_str(); }
	project_data::path_type get_filename2() const { return entry_filename2.get_text().c_str(); }
	project_data::path_type get_workdir() const { return entry_workdir.get_text().c_str(); }

protected:
	void openfile1();
	void openfile2();
	void openworkdir();
	void entries_changed();

	Gtk::Table table_entries_buttons;
	Gtk::Frame frame_filesworkdir;
	Gtk::Entry entry_filename1, entry_filename2, entry_workdir;
	Gtk::Button button_openfile1, button_openfile2, button_selectworkdir;
};

#endif // GTKMM_STARTPROJECTDIALOG_HEADER