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

#ifndef GTKMM_MAINWINDOW_HEADER
#define GTKMM_MAINWINDOW_HEADER

#include <gtkmm.h>
#include <string>
#include <iostream>
#include "startpage.hpp"

class MainWindow
	: public Gtk::Window
{
public:
	MainWindow();
	virtual ~MainWindow();

protected:
	void openfile1();
	void openfile2();

	Gtk::VBox box_main;
	Gtk::Notebook workspace;
	Gtk::Image image_logo;
	StartPage myStartPage;
};

extern Gtk::Notebook* mainworkspace;

inline void show_exception(const std::exception& e) {
	std::cout << "Caught exception: " << e.what() << std::endl;
	Gtk::MessageDialog dlg("Caught exception:\n" + std::string(e.what()),false,Gtk::MESSAGE_ERROR, Gtk::BUTTONS_CLOSE, true);
	dlg.run();
}

#endif // GTKMM_MAINWINDOW_HEADER