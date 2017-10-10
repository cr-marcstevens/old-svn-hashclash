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

#ifndef BIRTHDAYSEARCH_PAGE_HPP
#define BIRTHDAYSEARCH_PAGE_HPP

#include <gtkmm.h>
#include "textviewfollowfile.hpp"
#include "run_program.hpp"

class BirthdaySearchPage
	: public Gtk::VBox
{
public:
	BirthdaySearchPage();
	virtual ~BirthdaySearchPage();
private:
	void button_start_clicked();
	void button_abort_clicked();
	void button_clear_clicked();
	bool update();
	sigc::connection timer;
	Gtk::HBox boxtop;
	Gtk::HButtonBox buttonbox;
	Gtk::Button button_start, button_abort, button_clear;
	Gtk::Label label_eta;
	TextViewFollowFile console;
	RunProgram runprogram;
	bool isaborted;
};

#endif // BIRTHDAYSEARCH_PAGE_HPP
