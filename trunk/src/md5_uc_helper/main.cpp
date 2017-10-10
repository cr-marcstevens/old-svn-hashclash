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
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <array>

#include <boost/lexical_cast.hpp>
#include <boost/program_options.hpp>
#include <boost/filesystem/operations.hpp>

#include "main.hpp"

#include <hashutil5/saveload_gz.hpp>
#include <hashutil5/sdr.hpp>
#include <hashutil5/timer.hpp>
#include <hashutil5/differentialpath.hpp>
#include <hashutil5/md5detail.hpp>
#include <hashutil5/booleanfunction.hpp>

using namespace hashutil;
using namespace std;
namespace po = boost::program_options;
namespace fs = boost::filesystem;

boost::mutex mut;
std::string workdir;

vector< vector<int> > msgdiff(16);


int MSBstate(const parameters_type& params)
{
	differentialpath path;
	vector<differentialpath> vecpath;
	const int t = params.t;
	if (t < 0 || t >= 64)
		throw std::runtime_error("t out of range");
	path[t-3] = sdr(0,1<<31);
	path[t-2] = sdr(0,1<<31);
	path[t-1] = sdr(0,1<<31);
	path[t] = sdr(0,1<<31);
	vecpath.push_back(path);
	path[t-2] = sdr(1<<31,0);
	path[t-1] = sdr(0,1<<31);
	vecpath.push_back(path);
	path[t-2] = sdr(0,1<<31);
	path[t-1] = sdr(1<<31,0);
	vecpath.push_back(path);
	path[t-2] = sdr(1<<31,0);
	path[t-1] = sdr(1<<31,0);
	vecpath.push_back(path);
	cout << "Saving " << params.outfile1 << "..." << flush;
	save_gz(vecpath, binary_archive, params.outfile1);
	cout << "done." << endl;
	return 0;
}

int Zstate(const parameters_type& params)
{
	differentialpath path;
	vector<differentialpath> vecpath;
	const int t = params.t;
	if (t < 0 || t >= 64)
		throw std::runtime_error("t out of range");
	path[t-3] = sdr(0);
	path[t-2] = sdr(0);
	path[t-1] = sdr(0);
	path[t] = sdr(0);
	vecpath.push_back(path);
	cout << "Saving " << params.outfile1 << "..." << flush;
	save_gz(vecpath, binary_archive, params.outfile1);
	cout << "done." << endl;
	return 0;
}

void filterbest(vector<differentialpath>& paths)
{
	unsigned minconds = 85*32;
	for (size_t i = 0; i < paths.size(); ++i)
	{
		unsigned cond = 0;
		for (int t = paths[i].tbegin()+1; t < paths[i].tend()-1; ++t)
			cond += paths[i][t].hw();
		if (cond < minconds)
			minconds = cond;
	}
	for (size_t i = 0; i < paths.size(); )
	{
		unsigned cond = 0;
		for (int t = paths[i].tbegin()+1; t < paths[i].tend()-1; ++t)
			cond += paths[i][t].hw();
		if (cond == minconds)
		{
			++i;
		}
		else
		{	
			swap(paths[i], paths.back());
			paths.pop_back();
		}
	}

	minconds = 85*32;
	for (size_t i = 0; i < paths.size(); ++i)
	{
		unsigned cond = 0;
		for (int t = paths[i].tbegin(); t < paths[i].tend(); ++t)
			cond += paths[i][t].hw();
		if (cond < minconds)
			minconds = cond;
	}
	for (size_t i = 0; i < paths.size(); )
	{
		unsigned cond = 0;
		for (int t = paths[i].tbegin(); t < paths[i].tend(); ++t)
			cond += paths[i][t].hw();
		if (cond == minconds)
		{
			++i;
		}
		else
		{	
			swap(paths[i], paths.back());
			paths.pop_back();
		}
	}
}

int highbest(const parameters_type& params)
{
	vector<differentialpath> high;

	cout << "Loading " << params.infile1 << "..." << flush;
	load_gz(high, binary_archive, params.infile1);
	cout << "done: " << high.size() << endl;
	if (high.empty())
		throw std::runtime_error("inputfile1 empty");

	const int tb = high.front().tbegin();

	filterbest(high);

	map<differentialpath, differentialpath> DWS_high;
	differentialpath DWS;
	for (auto it = high.begin(); it != high.end(); ++it)
	{
		for (int i = tb; i < tb + 4; ++i)
			DWS[i] = (*it)[i];
		DWS_high[DWS] = std::move(*it);
	}
	
	vector<differentialpath> ret;
	for (auto it = DWS_high.begin(); it != DWS_high.end(); ++it)
	{
		ret.push_back(it->second);
		cout << "===================" << endl;
		show_path(ret.back(),params.m_diff);
	}
	if (!params.outfile1.empty())
	{
		cout << "Saving " << params.outfile1 << "..." << flush;
		save_gz(ret, binary_archive, params.outfile1);
		cout << "done." << endl;
	}
	
	return 0;
}

int combine(const parameters_type& params)
{
	vector<differentialpath> low,high;

	cout << "Loading " << params.infile1 << "..." << flush;
	load_gz(low, binary_archive, params.infile1);
	cout << "done: " << low.size() << endl;

	cout << "Loading " << params.infile2 << "..." << flush;
	load_gz(high, binary_archive, params.infile2);
	cout << "done: " << high.size() << endl;

	if (low.empty() || high.empty())
		throw std::runtime_error("inputfile1 or inputfile2 empty");
	if (low.front().tbegin() > high.front().tbegin())
		swap(low,high);
		

	filterbest(low);
	filterbest(high);
	show_path(low.front(), params.m_diff);		
	show_path(high.front(), params.m_diff);

	if (low.front().tend() != high.front().tbegin()+4)
		throw std::runtime_error("overlap between low and high parts is not exactly 4 Qt");
	const int tb = high.front().tbegin();
	
	map< differentialpath, vector<differentialpath> > DWS_low, DWS_high;
	differentialpath DWS;
	
	for (auto it = low.begin(); it != low.end(); ++it)
	{
		for (int i = tb; i < tb + 4; ++i)
			DWS[i] = (*it)[i];
		DWS_low[DWS].emplace_back( std::move(*it) );
	}

	for (auto it = high.begin(); it != high.end(); ++it)
	{
		for (int i = tb; i < tb + 4; ++i)
			DWS[i] = (*it)[i];
		DWS_high[DWS].emplace_back( std::move(*it) );
	}
	
	vector<differentialpath> combined;
	
	for (auto lit = DWS_low.begin(); lit != DWS_low.end(); ++lit)
	{
		for (auto hit = DWS_high.begin(); hit != DWS_high.end(); ++hit)
		{
			const differentialpath& l = lit->second.front();
			const differentialpath& h = hit->second.front();
			if (l[tb].diff() != h[tb].diff()) continue;
			if (l[tb+1].getsdr() != h[tb+1].getsdr()) continue;
			if (l[tb+2].getsdr() != h[tb+2].getsdr()) continue;
			if (l[tb+3].diff() != h[tb+3].diff()) continue;
			
			bool ok = true;
			for (int i = tb+1; i < tb + 3; ++i)
			{
				for (unsigned b = 0; b < 32; ++b)
				{
					bitcondition lb = l(i,b), hb = h(i,b);
					if (lb == bc_constant || hb == bc_constant || lb == hb) continue;
					ok = false;
				}
			}
			if (ok)
			{
				differentialpath tmp = l;
				for (int i = tb + 1; i < tb + 3; ++i)
				{
					for (unsigned b = 0; b < 32; ++b)
					{
						if (h(i,b) != bc_constant)
							tmp.setbitcondition(i,b,h(i,b));
					}
				}
				for (int i = tb + 3; i < h.tend(); ++i)
					tmp[i] = h[i];
				combined.push_back(tmp);
				cout << "===================" << endl;
				show_path(tmp,params.m_diff);
			}
		}
	}

	if (!params.outfile1.empty())
	{
		cout << "Saving " << params.outfile1 << "..." << flush;
		save_gz(combined, binary_archive, params.outfile1);
		cout << "done." << endl;
	}
	
	return 0;
}

string dBname()
{
	//vector< vector<int> > msgdiff(16);
	string ret;
	for (unsigned t = 0; t < 16; ++t)
	{
		for (unsigned i = 0; i < msgdiff[t].size(); ++i)
		{
			if (!ret.empty())
				ret += '_';
			int b = msgdiff[t][i];
			if (b < 0)
				ret += "m" + boost::lexical_cast<string>(t) + "b-" + boost::lexical_cast<string>(-b-1);
			else
				ret += "m" + boost::lexical_cast<string>(t) + "b" + boost::lexical_cast<string>(b-1);
		}
	} 
	return ret;
}

string mdiffstr()
{
	string ret;
	for (unsigned t = 0; t < 16; ++t)
	{
		for (unsigned i = 0; i < msgdiff[t].size(); ++i)
		{
			ret += "diffm" + boost::lexical_cast<string>(t) + " = " + boost::lexical_cast<string>(msgdiff[t][i]) + "\n";
		}
	} 
	return ret;
}

int dBanalysis(const parameters_type& params)
{
	if (params.te > 64)
		throw std::runtime_error("te > 64!");
	if (params.tb < 4)
		throw std::runtime_error("tb < 4!");
	vector<int> ts;
	for (int t = params.tb; t < params.te; ++t)
	{
		bool ok = true;
		for (int i = t; i < t+3 && i < 64; ++i)
			if (params.m_diff[md5_wt[i]] != 0)
				ok = false;
		if (ok)
			ts.push_back(t);
	}
	size_t i = 0;
	while (i < ts.size())
	{
		size_t ie = i+1;
		while (ie < ts.size() && ts[ie]-1==ts[ie-1])
			++ie;
		int tfirst = ts[i], tlast = ts[ie-1];
		int t = (tfirst+tlast)>>1;
		if (t < 32)
		{
			if (tlast < 32)
				t = tlast;
			else
				t = 32;
		}
		if (t >= 48)
		{
			if (tfirst >= 48)
				t = tfirst;
			else
				t = 47;
		}
		ts.erase(ts.begin()+i+1, ts.begin()+ie);
		ts[i] = t;
		++i;
	}
	
	parameters_type tmpparam(params);
	for (i = 0; i < ts.size(); ++i)
	{
		int t = ts[i];
		for (int MSB = 0; MSB < 2; ++MSB)
		{
			string workdir = dBname()+"__i"+boost::lexical_cast<string>(t)+"_dWSi";
			if (MSB == 0)
				workdir += "0";
			else
				workdir += "MSB";
			::fs::create_directories(workdir+"/data");
			
			// create empty paths
			tmpparam.t = t;
//			tmpparam.outfile1 = workdir+"/data/paths"+boost::lexical_cast<string>(t)+"_0of1.bin.gz";
//			if (MSB == 0)
//				Zstate(tmpparam);
//			else
//				MSBstate(tmpparam);
			tmpparam.outfile1 = workdir+"/data/dWS"+boost::lexical_cast<string>(t)+".bin.gz";
			if (MSB == 0)
				Zstate(tmpparam);
			else
				MSBstate(tmpparam);
				
			// create default configuration files
			ofstream fwcfg(workdir+"/md5diffpathforward.cfg",ios::trunc), bwcfg(workdir+"/md5diffpathbackward.cfg")
				, hcfg(workdir+"/md5diffpathhelper.cfg",ios::trunc);
			fwcfg
				<< mdiffstr() << endl
				<< "tstep = " << t << endl
				<< "trange = " << (params.te-t-1) << endl
				<< "condtbegin = " << (t-2) << endl
				<< "inputfile = data/dWS" << t << ".bin.gz" << endl
				;
			bwcfg
				<< mdiffstr() << endl
				<< "tstep = " << (t-1) << endl
				<< "trange = " << (t-params.tb-1) << endl
//				<< "condtend = " << (t) << endl
				;
			hcfg
				<< mdiffstr() << endl
				;
		}
	}
	
	return 0;
}

int main(int argc, char** argv) 
{
	hashutil::timer runtime(true);

        cout <<
                "MD5 differential path toolbox\n"
                "Copyright (C) 2009 Marc Stevens\n"
                "http://homepages.cwi.nl/~stevens/\n"
                << endl;

	try {
		parameters_type parameters;
				
		// Define program options
		po::options_description 
			cmds("Allowed commands"),
			desc("Allowed options"), 
			msg("Define message differences (as +bitnr and -bitnr, bitnr=1-32)"), 
			all("Allowed options");

		cmds.add_options()
			("help,h",				"Show options\n")
			("MSBstate", "Create file with paths with MSB diffs")
			("Zstate",   "Create file with paths with zero diffs")
			("combine",  "Merge partial paths from 2 files and output the best one")
			("dBanalysis", "Create working dirs for candidate (dB,i,dWSi) given dB")
			("highbest", "Keep best paths with distinct starting conditions")
			;
		desc.add_options()
			("if1"
				, po::value<string>(&parameters.infile1)->default_value("")
				, "Set inputfile 1.")
			("if2"
				, po::value<string>(&parameters.infile2)->default_value("")
				, "Set inputfile 1.")
			("of1"
				, po::value<string>(&parameters.outfile1)->default_value("")
				, "Set outputfile 1.")
			("of2"
				, po::value<string>(&parameters.outfile2)->default_value("")
				, "Set outputfile 2.")
			("t,t"
				, po::value<int>(&parameters.t)->default_value(-4)
				, "Step t")
			("tb"
				, po::value<int>(&parameters.tb)->default_value(16)
				, "steps for dBanalysis: [tb,te)")
			("te"
				, po::value<int>(&parameters.te)->default_value(64)
				, "steps for dBanalysis: [tb,te)")
			;

		msg.add_options()	
			("diffm0", po::value< vector<int> >(&msgdiff[0]), "delta m0")
			("diffm1", po::value< vector<int> >(&msgdiff[1]), "delta m1")
			("diffm2", po::value< vector<int> >(&msgdiff[2]), "delta m2")
			("diffm3", po::value< vector<int> >(&msgdiff[3]), "delta m3")
			("diffm4", po::value< vector<int> >(&msgdiff[4]), "delta m4")
			("diffm5", po::value< vector<int> >(&msgdiff[5]), "delta m5")
			("diffm6", po::value< vector<int> >(&msgdiff[6]), "delta m6")
			("diffm7", po::value< vector<int> >(&msgdiff[7]), "delta m7")
			("diffm8", po::value< vector<int> >(&msgdiff[8]), "delta m8")
			("diffm9", po::value< vector<int> >(&msgdiff[9]), "delta m9")
			("diffm10", po::value< vector<int> >(&msgdiff[10]), "delta m10")
			("diffm11", po::value< vector<int> >(&msgdiff[11]), "delta m11")
			("diffm12", po::value< vector<int> >(&msgdiff[12]), "delta m12")
			("diffm13", po::value< vector<int> >(&msgdiff[13]), "delta m13")
			("diffm14", po::value< vector<int> >(&msgdiff[14]), "delta m14")
			("diffm15", po::value< vector<int> >(&msgdiff[15]), "delta m15")
			;
		all.add(cmds).add(desc).add(msg);
	
		// Parse program options
		po::positional_options_description p;
		p.add("inputfile1", 1);
		p.add("inputfile2", 1);
		p.add("outputfile1", 1);
		p.add("outputfile2", 1);
		po::variables_map vm;
		po::store(po::command_line_parser(argc, argv)
			.options(all).positional(p).run(), vm);
		{
			std::ifstream ifs("md5diffpathhelper.cfg");
			if (ifs) po::store(po::parse_config_file(ifs, all), vm);
		}
		po::notify(vm);

		// Process program options
		if (vm.count("help")
			|| 0 == vm.count("MSBstate")
					+vm.count("Zstate")
					+vm.count("combine")
					+vm.count("dBanalysis")
					+vm.count("highbest")
					) {
			cout << cmds << desc << endl;
			return 0;
		}

		for (unsigned k = 0; k < 16; ++k)
		{
			parameters.m_diff[k] = 0;
			for (unsigned j = 0; j < msgdiff[k].size(); ++j)
				if (msgdiff[k][j] > 0)
					parameters.m_diff[k] += 1<<(msgdiff[k][j]-1);
				else
					parameters.m_diff[k] -= 1<<(-msgdiff[k][j]-1);
		}

		if (vm.count("dBanalysis"))
			return dBanalysis(parameters);
		if (vm.count("highbest"))
			return highbest(parameters);
		if (vm.count("MSBstate"))
			return MSBstate(parameters);
		if (vm.count("Zstate"))
			return Zstate(parameters);
		if (vm.count("combine"))
			return combine(parameters);

		// Start job with given parameters
	} catch (exception& e) {
		cout << "Runtime: " << runtime.time() << endl;
		cerr << "Caught exception!!:" << endl << e.what() << endl;
		throw;
	} catch (...) {
		cout << "Runtime: " << runtime.time() << endl;
		cerr << "Unknown exception caught!!" << endl;
		throw;
	}
	cout << "Runtime: " << runtime.time() << endl;
	return 0;
}

