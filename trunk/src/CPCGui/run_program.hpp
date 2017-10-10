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

#ifndef RUN_PROGRAM_HPP
#define RUN_PROGRAM_HPP

#include <boost/thread.hpp>
#include "project_data.hpp"

unsigned get_free_threads();
bool children_running();

struct threadrun;
class RunProgram {
friend struct threadrun;
public:
	RunProgram();
	~RunProgram();
	void run(const std::string& command);
	bool is_running() { mut.lock(); bool ret = running; mut.unlock(); return ret; }
	int get_returnvalue() const { return returnvalue; }
	void kill();
private:
	boost::mutex mut;
	bool running;
	int returnvalue;
	boost::thread* child;
	int cid;
};

struct threadrun_chain;
class RunProgramChain {
friend struct threadrun_chain;
public:
	RunProgramChain();
	~RunProgramChain();
	void run(const std::vector<std::string>& command_chain);
	bool is_running() { mut.lock(); bool ret = running; mut.unlock(); return ret; }
	int get_returnvalue() const { return returnvalue; }
	void kill();
private:
	boost::mutex mut;
	bool running;
	int returnvalue;
	boost::thread* child;
	int cid;
};

#endif // RUN_PROGRAM_HPP
