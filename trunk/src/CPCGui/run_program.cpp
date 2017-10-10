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
#include <vector>
#include <set>
#include "run_program.hpp"

#ifdef WIN32
#include <windows.h>
#include <Tlhelp32.h>
#else
#include <sys/types.h>  
#include <unistd.h> 
#endif

class ChildProcessManager {
public:	
#ifdef WIN32
	typedef DWORD pid_type;
#else
	typedef std::pid_t pid_type;
#endif
	ChildProcessManager(): islocked(false), running_children(0) {}

	// lock so no other children will be started. if block is true blocks until lock comes free.
	// if block is false then returns false when lock is not free.
	bool lock_newchild(bool block = true);
	// returns -1 if no new child is found within the timeout, otherwise returns id (not related to OS process id).
	int getlatestchild(/*boost::date_time::time_duration timeout = boost::posix_time::seconds(0)*/);
	// frees lock so other children can be started
	void unlock_newchild();

	int getlatestchildsafe() {
		lock_newchild(true);
		int ret = getlatestchild();
		unlock_newchild();
		return ret;
	}

	void child_started() {
		mut.lock();
		++running_children;
		mut.unlock();
	}
	void child_stopped() {
		mut.lock();
		if (running_children) --running_children;
		mut.unlock();
	}
	unsigned get_nr_running_children() {
		mut.lock();
		unsigned ret = running_children;
		mut.unlock();
		return ret;
	}
	
	void kill_child(int id);
	void kill_allchildren();
private:
	boost::mutex mut;
	bool islocked;
	unsigned running_children;
	std::vector<pid_type> children;
};
ChildProcessManager gcpm;

unsigned get_free_threads()
{
	if (current_project_data) {
		int freethreads = current_project_data->max_threads;
		freethreads -= int(gcpm.get_nr_running_children());
		if (freethreads < 0) freethreads = 0;
		return unsigned(freethreads);
	} else return 0;
}
bool children_running()
{
	unsigned nrch = gcpm.get_nr_running_children();
	return (nrch != 0);
}

struct CPMHelper {
	CPMHelper(int* child_id_ptr): cid(child_id_ptr) { *cid = -1; }
	int* cid;
	void operator()() {
		*cid = gcpm.getlatestchild();
		gcpm.unlock_newchild();
	}
};
bool ChildProcessManager::lock_newchild(bool block) {
	while (true) {
		mut.lock();
		if (islocked == false) {
			islocked = true;
			break;
		}
		mut.unlock();		
		if (!block) return false;
		boost::this_thread::sleep(boost::posix_time::microseconds(1));
	}
	mut.unlock();
	return true;
}
void ChildProcessManager::unlock_newchild() {
	mut.lock();
	islocked = false;
	mut.unlock();
}
#ifdef WIN32
int ChildProcessManager::getlatestchild(/*boost::date_time::time_duration timeout*/)
{
	std::cout << "ChildProcessManager::getlatestchild(): starting..." << std::endl;
	for (unsigned j = 0; j < 100; ++j) {
		std::set<pid_type> children_tmp;
		DWORD mypid = GetCurrentProcessId();
		HANDLE h = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
		if (h == INVALID_HANDLE_VALUE) {
			std::cerr << "CreateToolhelp32Snapshot failed" << std::endl;
			return -1;
		}
		PROCESSENTRY32 data;
		data.dwSize = sizeof(PROCESSENTRY32);
		BOOL ok = Process32First(h, &data);
		while (ok == TRUE) {
			if (data.th32ParentProcessID == mypid)
				children_tmp.insert(data.th32ProcessID);
			ok = Process32Next(h, &data);
		}
		CloseHandle(h);
		std::cout << "ChildProcessManager::getlatestchild(): Found " << children_tmp.size() << " children." << std::endl;
		for (unsigned i = 0; i < children.size(); ++i)
			if (children[i]!=0 && children_tmp.find(children[i]) == children_tmp.end())
				children[i] = 0;
		for (unsigned i = 0; i < children.size(); ++i)
			children_tmp.erase(children[i]);
		if (children_tmp.size() > 0) {
			DWORD newchild = *children_tmp.begin();
			std::cout << "ChildProcessManager::getlatestchild(): new child PID=" << newchild << std::endl;
			children.push_back(newchild);
			return children.size()-1;
		}	
		boost::this_thread::sleep(boost::posix_time::milliseconds(10));
	}
	std::cerr << "ChildProcessManager::getlatestchild(): Failed to find new child!" << std::endl;
	return -1;
}
void get_pid_ppid_list(std::vector< std::pair<DWORD, DWORD> >& pid_ppid_list) {
	pid_ppid_list.clear();
	HANDLE h = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (h == INVALID_HANDLE_VALUE) {
		return;
	}
	PROCESSENTRY32 data;
	data.dwSize = sizeof(PROCESSENTRY32);
	BOOL ok = Process32First(h, &data);
	while (ok == TRUE) {
		pid_ppid_list.push_back( std::pair<DWORD, DWORD>(data.th32ProcessID, data.th32ParentProcessID) );
		ok = Process32Next(h, &data);
	}
	CloseHandle(h);
}
void kill_pid(DWORD pid) {
	if (pid == 0) return;
	std::cout << "kill_pid(): pid = " << pid << std::endl;
	HANDLE h = OpenProcess(PROCESS_TERMINATE,FALSE,pid);
	if (h != NULL) {
		TerminateProcess(h, 1);
	}
	CloseHandle(h);
}
void ChildProcessManager::kill_child(int id)
{
	std::cout << "ChildProcessManager::kill_child(): cid=" << id << std::endl;
	if (id < 0 || id >= children.size()) return;
	std::cout << "ChildProcessManager::kill_child(): pid=" << children[id] << std::endl;
	if (children[id] == 0) return;
	std::vector<DWORD> pids;
	std::vector< std::pair<DWORD, DWORD> > pid_ppid_list;
	get_pid_ppid_list(pid_ppid_list);
	//pids.insert(children[id]);
	for (unsigned i = 0; i < pid_ppid_list.size(); ++i)
		if (pid_ppid_list[i].first == children[id] && pid_ppid_list[i].second == GetCurrentProcessId())
			pids.push_back(children[id]);
	while (true) {
		unsigned oldpidssize = pids.size();
		for (unsigned i = 0; i < pid_ppid_list.size(); ++i) {
			for (unsigned j = 0; j < pids.size(); ++j) {
				if (pids[j] == pid_ppid_list[i].second) {
					bool notinpids = true;
					for (unsigned k = 0; k < pids.size(); ++k)
						if (pids[k] == pid_ppid_list[i].first) {
							notinpids = false;
							break;
						}
					if (notinpids)
						pids.push_back(pid_ppid_list[i].first);
					break;
				}
			}
		}
		if (oldpidssize == pids.size())
			break;
	}
	for (int j = pids.size()-1; j >= 0; --j)
		kill_pid(pids[j]);
}
void ChildProcessManager::kill_allchildren()
{
	std::cout << "ChildProcessManager::kill_allchildren()" << std::endl;
	std::set<DWORD> pids;
	std::vector< std::pair<DWORD, DWORD> > pid_ppid_list;
	get_pid_ppid_list(pid_ppid_list);
	for (unsigned i = 0; i < pid_ppid_list.size(); ++i)
		if (pid_ppid_list[i].second == GetCurrentProcessId())
			pids.insert(pid_ppid_list[i].first);
	while (true) {
		unsigned oldpidssize = pids.size();
		for (unsigned i = 0; i < pid_ppid_list.size(); ++i)
			if (pids.find(pid_ppid_list[i].second) != pids.end())
				pids.insert(pid_ppid_list[i].first);
		if (oldpidssize == pids.size())
			break;
	}
	for (std::set<DWORD>::const_iterator cit = pids.begin(); cit != pids.end(); ++cit)
		kill_pid(*cit);
}
#else
int ChildProcessManager::getlatestchild(/*boost::date_time::time_duration timeout*/)
{
	return -1;
}
void get_pid_ppid_list(std::vector< std::pair<DWORD, DWORD> >& pid_ppid_list) {
	pid_ppid_list.clear();
}
void kill_pid(DWORD pid) {
}
void ChildProcessManager::kill_child(int id)
{
}
void ChildProcessManager::kill_allchildren()
{
}
#endif

struct threadrun {
	std::string command;
	RunProgram* parent;
	threadrun(RunProgram& p, const std::string& cmd): parent(&p), command(cmd) {}
	void operator()() {
		{ parent->mut.lock();
			parent->running = true;
			parent->returnvalue = 0;
		parent->mut.unlock();}
		gcpm.lock_newchild(true);
		boost::thread* tmp = new boost::thread(CPMHelper(&(parent->cid)));
		gcpm.child_started();
		int retval = system(command.c_str());
		gcpm.child_stopped();
		tmp->join();
		delete tmp;
		{ parent->mut.lock();
			parent->cid = -1;
			parent->running = false;
			parent->returnvalue = retval;
		parent->mut.unlock();}
	}
};

RunProgram::RunProgram()
	: child(0), running(false), returnvalue(0), cid(-1)
{}
RunProgram::~RunProgram()
{
	if (child) {
		if (running && child->joinable()) {
			std::cerr << "RunProgram::~RunProgram(): child still running!" << std::endl;
			kill();
			child->join();
		} else
			child->join();
		delete child;
	}
}
void RunProgram::run(const std::string& command)
{
	try {
		if (current_project_data)
			current_project_data->save_config();
	} catch (...) {}
	if (child) {
		if (running && child->joinable()) {
			std::cerr << "RunProgram::run(): previous child still running!" << std::endl;
			child->join();
		} else
			child->join();
		delete child;
	}
	running = true;
	returnvalue = 0;
	cid = -1;
	child = new boost::thread( threadrun(*this,command) );
}
void RunProgram::kill()
{
	gcpm.kill_child(cid);
}

struct threadrun_chain {
	std::vector<std::string> commands;
	RunProgramChain* parent;
	threadrun_chain(RunProgramChain& p, const std::vector<std::string>& cmds): parent(&p), commands(cmds) {}
	void operator()() {
		{ parent->mut.lock();
			parent->running = true;
			parent->returnvalue = 0;
		parent->mut.unlock();}
		int retval = 0;
		for (unsigned i = 0; i < commands.size(); ++i) {
			gcpm.lock_newchild(true);
			boost::thread tmp(CPMHelper(&parent->cid));
			gcpm.child_started();
			retval = system(commands[i].c_str());
			gcpm.child_stopped();
			tmp.join();
			if (retval != 0)
				break;
		}
		{ parent->mut.lock();
			parent->cid = -1;
			parent->running = false;
			parent->returnvalue = retval;
		parent->mut.unlock();}
	}
};

RunProgramChain::RunProgramChain()
	: running(false), returnvalue(0), child(0), cid(-1)
{}
RunProgramChain::~RunProgramChain()
{
	if (child) {
		if (running && child->joinable()) {
			std::cerr << "RunProgramChain::~RunProgramChain(): child still running!" << std::endl;
			kill();
			child->join();
		} else
			child->join();
		delete child;
	}
}
void RunProgramChain::run(const std::vector<std::string>& command_chain)
{
	try {
		if (current_project_data)
			current_project_data->save_config();
	} catch (...) {}
	if (child) {
		if (running && child->joinable()) {
			std::cerr << "RunProgramChain::run(): previous child still running!" << std::endl;
			child->join();
		} else
			child->join();
		delete child;
	}
	running = true;
	returnvalue = 0;
	cid = -1;
	child = new boost::thread( threadrun_chain(*this,command_chain) );
}
void RunProgramChain::kill()
{
	gcpm.kill_child(cid);
}