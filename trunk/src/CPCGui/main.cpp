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

#include <stdexcept>
#include <iostream>
#include <gtkmm.h>
#include <boost/thread.hpp>
#include <cstdlib>
#include "mainwindow.hpp"
#include "project_data.hpp"

int main(int argc, char** argv)
{
	try {
		default_project_data.init_load_default_config();
	} catch (std::exception& e) { std::cerr << e.what() << std::endl; } catch (...) {}
	try {
		default_project_data.max_threads = boost::thread::hardware_concurrency();
		std::cout << "Number of CPU cores: " << boost::thread::hardware_concurrency() << std::endl;
		Gtk::Main process_commandline(argc, argv);
		MainWindow window;
		Gtk::Main::run(window);
	} catch (std::exception& e) { std::cerr << e.what() << std::endl; } catch (...) { std::cerr << "Unknown exception caught..." << std::endl; }
	try {
		default_project_data.workdir = ".";
		default_project_data.save_default_config();
	} catch (std::exception& e) { std::cerr << e.what() << std::endl; } catch (...) {}	
	if (current_project_data != 0) {
		try {
			current_project_data->save_config();
		} catch (std::exception& e) { std::cerr << e.what() << std::endl; } catch (...) {}	
	}
	return 0;
}

// Windows platform specific
#if defined(WIN32) || defined (_WIN32) || defined(WIN64) || defined(_WIN64)
#include <windows.h>
int __stdcall WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
	return main(__argc,__argv);
}
#endif
