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
#include <gtkmm.h>
#include <boost/filesystem/operations.hpp>

#include "startprojectdialog.hpp"

void StartProjectDialog::openfile1()
{
	Gtk::FileChooserDialog dialog("Please choose a file", Gtk::FILE_CHOOSER_ACTION_OPEN);
	dialog.set_transient_for(*this);

	dialog.add_button(Gtk::Stock::CANCEL, Gtk::RESPONSE_CANCEL);
	dialog.add_button(Gtk::Stock::OPEN, Gtk::RESPONSE_OK);

	if (Gtk::RESPONSE_OK == dialog.run())
			entry_filename1.set_text(dialog.get_filename());
}

void StartProjectDialog::openfile2()
{
	Gtk::FileChooserDialog dialog("Please choose a file", Gtk::FILE_CHOOSER_ACTION_OPEN);
	dialog.set_transient_for(*this);

	dialog.add_button(Gtk::Stock::CANCEL, Gtk::RESPONSE_CANCEL);
	dialog.add_button(Gtk::Stock::OPEN, Gtk::RESPONSE_OK);

	if (Gtk::RESPONSE_OK == dialog.run())
			entry_filename2.set_text(dialog.get_filename());
}

void StartProjectDialog::openworkdir()
{
	Gtk::FileChooserDialog dialog("Please create a new workdirectory", Gtk::FILE_CHOOSER_ACTION_CREATE_FOLDER);
	dialog.set_transient_for(*this);

	dialog.add_button(Gtk::Stock::CANCEL, Gtk::RESPONSE_CANCEL);
	dialog.add_button(Gtk::Stock::OPEN, Gtk::RESPONSE_OK);

	if (Gtk::RESPONSE_OK == dialog.run())
			entry_workdir.set_text(dialog.get_filename());
}

void StartProjectDialog::entries_changed()
{
	bool sensitive = false;
	if (entry_filename1.get_text().size() > 0
		&& entry_filename2.get_text().size() > 0
		&& entry_workdir.get_text().size() > 0)
	{
		if (boost::filesystem::is_regular_file(boost::filesystem::path(entry_filename1.get_text().c_str()))
			&& boost::filesystem::is_regular_file(boost::filesystem::path(entry_filename2.get_text().c_str()))
			&& boost::filesystem::is_directory(boost::filesystem::path(entry_workdir.get_text().c_str())))			
				sensitive = true;
	}
	if (sensitive) {
		if (!boost::filesystem::is_empty(boost::filesystem::path(entry_workdir.get_text().c_str()))) {
			entry_workdir.set_text("Specify empty directory");
			sensitive = false;
		}
	}
	set_response_sensitive(Gtk::RESPONSE_OK, sensitive);
}

StartProjectDialog::StartProjectDialog()
	: frame_filesworkdir("Select input files and new work directory")
	, table_entries_buttons(3, 3, false)
	, button_openfile1(Gtk::Stock::OPEN)
	, button_openfile2(Gtk::Stock::OPEN)
	, button_selectworkdir(Gtk::Stock::SAVE)
{
	set_title("New Project...");
	entry_filename1.set_max_length(1023);
	entry_filename2.set_max_length(1023);
	entry_workdir.set_max_length(1023);
	entry_workdir.set_width_chars(64);
	table_entries_buttons.attach( *Gtk::manage(new Gtk::Label("Input file 1", Gtk::ALIGN_LEFT, Gtk::ALIGN_CENTER)), 0,1, 0,1, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.attach( *Gtk::manage(new Gtk::Label("Input file 2", Gtk::ALIGN_LEFT, Gtk::ALIGN_CENTER)), 0,1, 1,2, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.attach( *Gtk::manage(new Gtk::Label("Select work directory", Gtk::ALIGN_LEFT, Gtk::ALIGN_CENTER)), 0,1, 2,3, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.attach(entry_filename1, 1, 2, 0, 1, Gtk::FILL | Gtk::EXPAND, Gtk::SHRINK);
	table_entries_buttons.attach(entry_filename2, 1, 2, 1, 2, Gtk::FILL | Gtk::EXPAND, Gtk::SHRINK);
	table_entries_buttons.attach(entry_workdir, 1, 2, 2, 3, Gtk::FILL | Gtk::EXPAND, Gtk::SHRINK);
	table_entries_buttons.attach(button_openfile1, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.attach(button_openfile2, 2, 3, 1, 2, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.attach(button_selectworkdir, 2, 3, 2, 3, Gtk::FILL, Gtk::SHRINK);
	table_entries_buttons.set_spacings(10);
	table_entries_buttons.set_border_width(10);
	frame_filesworkdir.set_border_width(10);
	frame_filesworkdir.add(table_entries_buttons);
	get_vbox()->add(frame_filesworkdir);

	button_openfile1.signal_clicked().connect( sigc::mem_fun(*this, &StartProjectDialog::openfile1) );
	button_openfile2.signal_clicked().connect( sigc::mem_fun(*this, &StartProjectDialog::openfile2) );
	button_selectworkdir.signal_clicked().connect( sigc::mem_fun(*this, &StartProjectDialog::openworkdir) );
	entry_filename1.signal_changed().connect( sigc::mem_fun(*this, &StartProjectDialog::entries_changed) );
	entry_filename2.signal_changed().connect( sigc::mem_fun(*this, &StartProjectDialog::entries_changed) );
	entry_workdir.signal_changed().connect( sigc::mem_fun(*this, &StartProjectDialog::entries_changed) );
	add_button(Gtk::Stock::CANCEL, Gtk::RESPONSE_CANCEL);
	add_button(Gtk::Stock::OK, Gtk::RESPONSE_OK);
	set_response_sensitive(Gtk::RESPONSE_OK, false);
	show_all();
}

StartProjectDialog::~StartProjectDialog()
{
}

