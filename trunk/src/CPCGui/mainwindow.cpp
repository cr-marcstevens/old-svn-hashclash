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
#include "mainwindow.hpp"

using namespace std;
MainWindow::MainWindow()
{
	this->set_title("HashClash: Chosen-Prefix Collision GUI");
	this->set_default_icon_from_file("icon.png");
	set_border_width(10);

	Glib::RefPtr<Gdk::Pixbuf> logo_data = Gdk::Pixbuf::create_from_file("logo.png");
	image_logo.set_alignment(Gtk::ALIGN_LEFT, Gtk::ALIGN_CENTER);
	image_logo.set(logo_data);
	box_main.pack_start(image_logo, false, false, 0);
	box_main.pack_start(*Gtk::manage( new Gtk::HSeparator() ), false, true, 10 );
	box_main.pack_start(workspace, true, true, 0);
	workspace.set_border_width(0);
	workspace.append_page(myStartPage, "Start page");
	mainworkspace = &workspace;
	add(box_main);
	show_all();
}

MainWindow::~MainWindow()
{
}

Gtk::Notebook* mainworkspace = 0;