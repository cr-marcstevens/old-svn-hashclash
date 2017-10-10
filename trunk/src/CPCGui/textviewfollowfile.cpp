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

#include <cstdio>
#include <iostream>
#include <string>
#include <fstream>
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include "textviewfollowfile.hpp"

using namespace boost::filesystem;

TextViewFollowFile::TextViewFollowFile(const path_type& filepath)
	: file(filepath), lastmodtime(0), lastfilesize(0)
{
	timer = Glib::signal_timeout().connect( sigc::mem_fun(*this, &TextViewFollowFile::update_content), 1000);
	add(textview);
	set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS);
	textview.set_editable(false);
	textview.set_wrap_mode(Gtk::WRAP_NONE);
	textview.get_buffer()->create_tag("monospace")->property_family() = "monospace";
}

TextViewFollowFile::~TextViewFollowFile()
{
	timer.disconnect();
}

void TextViewFollowFile::set_file(const path_type& filepath)
{
	file = filepath;
	textview.get_buffer()->set_text("");
	update_content();
}

bool TextViewFollowFile::update_content()
{
	//if (!is_visible()) return true;
	try {
		if (file.empty()) return true;
		if (!is_regular_file(file)) {
			textview.get_buffer()->set_text("");
			return true;
		}
		static std::string content;
		static char buffer[65536];
		
		std::time_t modtime = last_write_time(file);
		boost::uintmax_t filesize = file_size(file);
		if (modtime != lastmodtime || filesize != lastfilesize) {
			lastmodtime = modtime;
			lastfilesize = filesize;
			std::ifstream ifs(file.string().c_str());
			content.clear();
			while (ifs) {
				ifs.read(buffer, 65536);
				content.append(buffer, ifs.gcount());
			}
			content.append("\n\n\n");
			textview.get_buffer()->set_text(content);
			textview.get_buffer()->apply_tag_by_name("monospace", textview.get_buffer()->begin(), textview.get_buffer()->end());
			get_vadjustment()->set_value(get_vadjustment()->get_upper());
			std::cout << "." << std::flush;
		}
	} 
	catch (std::exception& e) { std::cerr << "TextViewFollowFile::update(): " << e.what() << std::endl; textview.get_buffer()->set_text(""); }
	catch (...) { std::cerr << "TextViewFollowFile::update(): unknown error!" << std::endl; textview.get_buffer()->set_text(""); }
	return true;
}

