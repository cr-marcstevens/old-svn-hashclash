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

#ifndef STARTPAGE_HEADER
#define STARTPAGE_HEADER

#include <gtkmm.h>
#include "project_configurator.hpp"

class StartPage
	: public Gtk::HBox
{
public:
	StartPage();
	virtual ~StartPage();

protected:
	ProjectConfigurator default_project_configurator;
	Gtk::VButtonBox buttonbox_projectoperations;
	Gtk::Button button_new_project, button_open_project, button_save_project, button_close_project, button_quit;

	void button_new_project_clicked();
	void button_open_project_clicked();
	void button_save_project_clicked();
	void button_close_project_clicked();
	void button_quit_clicked();
};

#endif // GTKMM_MAINWINDOW_HEADER