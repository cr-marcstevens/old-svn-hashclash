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

#include <boost/lexical_cast.hpp>
#include <boost/filesystem/operations.hpp>
#include "startpage.hpp"
#include "startprojectdialog.hpp"
#include "project_data.hpp"
#include "mainwindow.hpp"
#include "birthdaysearch_page.hpp"
#include "nearcollision_page.hpp"

StartPage::StartPage()
	: default_project_configurator(default_project_data, false)
	, buttonbox_projectoperations(Gtk::BUTTONBOX_START, 10)
	, button_new_project("New Project")
	, button_open_project("Open Project")
	, button_save_project("Save Project")
	, button_close_project("Close current project")
	, button_quit("Quit") 
{
	set_border_width(10);
	buttonbox_projectoperations.add(button_new_project);
	buttonbox_projectoperations.add(button_open_project);
	buttonbox_projectoperations.add(button_save_project);
	buttonbox_projectoperations.add(button_close_project);
	buttonbox_projectoperations.add(button_quit);

	button_new_project.signal_clicked().connect( sigc::mem_fun(*this, &StartPage::button_new_project_clicked) );
	button_open_project.signal_clicked().connect( sigc::mem_fun(*this, &StartPage::button_open_project_clicked) );
	button_save_project.signal_clicked().connect( sigc::mem_fun(*this, &StartPage::button_save_project_clicked) );
	button_close_project.signal_clicked().connect( sigc::mem_fun(*this, &StartPage::button_close_project_clicked) );
	button_quit.signal_clicked().connect( sigc::mem_fun(*this, &StartPage::button_quit_clicked) );

	button_save_project.set_sensitive(false);
	button_close_project.set_sensitive(false);

	pack_start(buttonbox_projectoperations, false, false, 10);
	pack_start(*Gtk::manage(new Gtk::VSeparator()), false, true, 0);
	pack_start(default_project_configurator, true, true);
}

StartPage::~StartPage() 
{
}

void StartPage::button_new_project_clicked()
{
	if (current_project_data != 0) {
		button_new_project.set_sensitive(false);
		button_open_project.set_sensitive(false);
		button_save_project.set_sensitive(true);
		button_close_project.set_sensitive(true);
		return;
	}
	StartProjectDialog dlg;
	if (Gtk::RESPONSE_OK == dlg.run()) {
		current_project_data = new project_data(default_project_data);
		current_project_data->filename1 = dlg.get_filename1();
		current_project_data->filename2 = dlg.get_filename2();
		current_project_data->workdir = dlg.get_workdir();
		current_project_data->save_config();
		boost::filesystem::create_directory(current_project_data->workdir / "work_birthdaysearch");
		mainworkspace->append_page(*Gtk::manage(new ProjectConfigurator(*current_project_data)), "Configuration");
		mainworkspace->append_page(*Gtk::manage(new BirthdaySearchPage()), "Birthday Search");
		mainworkspace->show_all();
		mainworkspace->set_current_page(1);
		button_new_project.set_sensitive(false);
		button_open_project.set_sensitive(false);
		button_save_project.set_sensitive(true);
		button_close_project.set_sensitive(true);
	}
}

void StartPage::button_open_project_clicked()
{
	if (current_project_data != 0) {
		button_new_project.set_sensitive(false);
		button_open_project.set_sensitive(false);
		button_save_project.set_sensitive(true);
		button_close_project.set_sensitive(true);
		return;
	}
	Gtk::FileChooserDialog dlg("Open project", Gtk::FILE_CHOOSER_ACTION_OPEN);
	Gtk::FileFilter projectconfig_filter;
	projectconfig_filter.set_name("project.config");
	projectconfig_filter.add_pattern("project.config");
	dlg.add_filter(projectconfig_filter);
	dlg.add_button(Gtk::Stock::CANCEL, Gtk::RESPONSE_CANCEL);
	dlg.add_button(Gtk::Stock::OK, Gtk::RESPONSE_OK);
	if (Gtk::RESPONSE_OK == dlg.run()) {
		current_project_data = new project_data(default_project_data);
		try {
			current_project_data->init_load_config( 
				project_data::path_type(dlg.get_filename().c_str()).parent_path() );
		} catch (std::exception& e) {
			delete current_project_data;
			current_project_data = 0;
			show_exception(e);
			return;
		}
		if (!boost::filesystem::is_directory(current_project_data->workdir / "work_birthdaysearch"))
			boost::filesystem::create_directory(current_project_data->workdir / "work_birthdaysearch");
		mainworkspace->append_page(*Gtk::manage(new ProjectConfigurator(*current_project_data)), "Configuration");
		mainworkspace->append_page(*Gtk::manage(new BirthdaySearchPage()), "Birthday Search");
		for (unsigned i = 0; i < current_project_data->intermediate_collfiles.size(); ++i)
			mainworkspace->append_page(*Gtk::manage(new NearCollisionPage(i)), "N.C. " + boost::lexical_cast<std::string>(i));
		mainworkspace->show_all();
		mainworkspace->set_current_page(1);
		button_new_project.set_sensitive(false);
		button_open_project.set_sensitive(false);
		button_save_project.set_sensitive(true);
		button_close_project.set_sensitive(true);
	}
}

void StartPage::button_save_project_clicked()
{
	if (current_project_data == 0) {
		button_new_project.set_sensitive(true);
		button_open_project.set_sensitive(true);
		button_save_project.set_sensitive(false);
		button_close_project.set_sensitive(false);
		return;
	}
	try {
		current_project_data->save_config();
	} catch (std::exception& e) {
		show_exception(e);
	}
}

void StartPage::button_close_project_clicked()
{
	if (current_project_data == 0) {
		button_new_project.set_sensitive(true);
		button_open_project.set_sensitive(true);
		button_save_project.set_sensitive(false);
		button_close_project.set_sensitive(false);
		return;
	}
	try {
		current_project_data->save_config();
	} catch (std::exception& e) {
		show_exception(e);
	}
	Gtk::Notebook& workspace(*dynamic_cast<Gtk::Notebook*>(get_parent()));
	while (workspace.get_n_pages() > 1)
		workspace.pages().pop_back();
	current_project_data->save_config();
	delete current_project_data;
	current_project_data = 0;
	button_new_project.set_sensitive(true);
	button_open_project.set_sensitive(true);
	button_save_project.set_sensitive(false);
	button_close_project.set_sensitive(false);
}

void StartPage::button_quit_clicked()
{
	button_close_project_clicked();
	Gtk::Main::quit();
}