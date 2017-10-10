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

#ifndef TEXTVIEWFOLLOWFILE_HPP
#define TEXTVIEWFOLLOWFILE_HPP

#include <gtkmm.h>
#include <boost/filesystem.hpp>

class TextViewFollowFile
	: public Gtk::ScrolledWindow
{
public:
	typedef boost::filesystem::path path_type;
	TextViewFollowFile(const path_type& filepath = "");
	virtual ~TextViewFollowFile();
	void set_file(const path_type& filepath);
	Glib::RefPtr< Gtk::TextBuffer > get_buffer() { return textview.get_buffer(); }
	Glib::RefPtr< const Gtk::TextBuffer > get_buffer() const { return textview.get_buffer(); }
protected:
	Gtk::TextView textview;
	bool update_content();
	sigc::connection timer;
	path_type file;
	std::time_t lastmodtime;
	boost::uintmax_t lastfilesize;
};

#endif // TEXTVIEWFOLLOWFILE_HPP
