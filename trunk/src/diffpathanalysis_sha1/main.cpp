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

#include <boost/lexical_cast.hpp>
#include <boost/program_options.hpp>
#include <boost/thread.hpp>
#include <hashutil5/sdr.hpp>
#include <hashutil5/timer.hpp>
#include <hashutil5/rng.hpp>
#include <hashutil5/progress_display.hpp>

#include "main.hpp"
#include "sha1_localcollision.hpp"
#include "path_prob_analysis.hpp"
#include "sha1_path_lc_analysis.hpp"
#include "sha1_lctobitconditions.hpp"

using namespace hashutil;
using namespace std;
namespace po = boost::program_options;
namespace fs = boost::filesystem;

std::string workdir;

void boost_thread_yield()
{
	boost::this_thread::yield();
//	boost::this_thread::sleep( boost::posix_time::nanoseconds(1) );
}

unsigned global_windowsize;
double me_frac_range;
int main(int argc, char** argv) 
{
	hashutil::timer runtime(true);

	try {
		parameters_type parameters;
		vector< vector<unsigned> > msgmask(16);
		unsigned msgoffset = 0;
		bool msglcext = false;
		unsigned samplesize = 0, loopsize = 0;
		bool dornd4 = false;
				
		// Define program options
		po::options_description 
			cmds("Allowed commands"),
			desc("Allowed options"), 
			msg("Define message differences (as +bitnr and -bitnr, bitnr=1-32)"), 
			all("Allowed options");

		cmds.add_options()
			("help,h",				"Show options\n")
			;
		desc.add_options()
			("workdir,w"
				, po::value<string>(&workdir)->default_value("./data")
				, "Set working directory.")
			("samplesize,s"
				, po::value<unsigned>(&samplesize)->default_value(20)
				, "Set sample size to 2^(val).")
			("loopsize,l"
				, po::value<unsigned>(&loopsize)->default_value(20)
				, "Set loop size to 2^(val).")
			("windowsize"
				, po::value<unsigned>(&global_windowsize)->default_value(6)
				, "Set windowsize to 5 (faster), 6 (more accurate)\nor even higher (slow).")
			("me_frac_range"
				, po::value<double>(&me_frac_range)->default_value(0.92)
				, "Derive msgspace over m\nwhere prob(m) >= <val>*max(prob(m))")
			("rnd4analysis"
				, po::bool_switch(&dornd4)
				, "Do round 4 special analysis\ninstead of round 2-4 normal analysis")
			;

		msg.add_options()	
			("diffm0", po::value< vector<unsigned> >(&msgmask[0]), "mask m0")
			("diffm1", po::value< vector<unsigned> >(&msgmask[1]), "mask m1")
			("diffm2", po::value< vector<unsigned> >(&msgmask[2]), "mask m2")
			("diffm3", po::value< vector<unsigned> >(&msgmask[3]), "mask m3")
			("diffm4", po::value< vector<unsigned> >(&msgmask[4]), "mask m4")
			("diffm5", po::value< vector<unsigned> >(&msgmask[5]), "mask m5")
			("diffm6", po::value< vector<unsigned> >(&msgmask[6]), "mask m6")
			("diffm7", po::value< vector<unsigned> >(&msgmask[7]), "mask m7")
			("diffm8", po::value< vector<unsigned> >(&msgmask[8]), "mask m8")
			("diffm9", po::value< vector<unsigned> >(&msgmask[9]), "mask m9")
			("diffm10", po::value< vector<unsigned> >(&msgmask[10]), "mask m10")
			("diffm11", po::value< vector<unsigned> >(&msgmask[11]), "mask m11")
			("diffm12", po::value< vector<unsigned> >(&msgmask[12]), "mask m12")
			("diffm13", po::value< vector<unsigned> >(&msgmask[13]), "mask m13")
			("diffm14", po::value< vector<unsigned> >(&msgmask[14]), "mask m14")
			("diffm15", po::value< vector<unsigned> >(&msgmask[15]), "mask m15")
			("diffoffset", po::value< unsigned >(&msgoffset), "mask offset")
//			("difflcext", po::bool_switch(&msglcext), "extend to local coll.") // we need the disturbance vector mask, not the full message expansion mask
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
			std::ifstream ifs("sha1diffpathanalysis.cfg");
			if (ifs) po::store(po::parse_config_file(ifs, all), vm);
		}
		po::notify(vm);

		// Process program options
		if (vm.count("help")) {
			cout << cmds << desc << endl;
			return 0;
		}
		if (global_windowsize < 5)
			throw std::runtime_error("windowsize < 5!");
		if (global_windowsize > 7) throw std::runtime_error("windowsize > 7!"); // not necessary but to protect the user

		uint32 me[16];
		for (unsigned k = 0; k < 16; ++k) {			
			me[k] = 0;
			for (unsigned j = 0; j < msgmask[k].size(); ++j)
				me[k] |= 1<<msgmask[k][j];
		}
		sha1_me_generalised(parameters.m_mask, me, msgoffset);
/*		// we need the disturbance vector mask, not the full message expansion mask
		if (msglcext) {
			uint32 met[16];
			uint32 mex[80];
			for (unsigned i = 0; i < 16; ++i)
				met[i] = rotate_left(me[i],5);
			sha1_me_generalised(mex, met, msgoffset+1);
			for (unsigned i = 0; i < 80; ++i)
				parameters.m_mask[i] ^= mex[i];

			sha1_me_generalised(mex, me, msgoffset+2);
			for (unsigned i = 0; i < 80; ++i)
				parameters.m_mask[i] ^= mex[i];

			for (unsigned i = 0; i < 16; ++i)
				met[i] = rotate_left(me[i],30);
			for (unsigned j = 3; j < 6; ++j) {
				sha1_me_generalised(mex, met, msgoffset+j);
				for (unsigned i = 0; i < 80; ++i)
					parameters.m_mask[i] ^= mex[i];
			}			
		}
*/
		lc_to_me checkme(parameters.m_mask);
		for (unsigned i = 0; i < 80; ++i)
			cout << "m[" << i << "]=\t" << sdr(0,checkme.lcme(i)) << "\t " << sdr(0,checkme.fullme(i)) << endl;

		// Start job with given parameters
		std::vector< std::vector<localcollision_vector> > lcmat;
		initialize_localcollision_matrix(lcmat);

		localcollision_combiner lccombiner(parameters.m_mask, lcmat);
		vector<int8> lcidxs(lccombiner.melcidx.size(),-1);
		lccombiner.set_lc_indices(lcidxs);

		cuda_device cd(1<<samplesize, 1<<loopsize);
#if 1
		// optional: pre-initialize CUDA and run (very) simple benchmark
		if (!cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft))
		{
			cout << "CUDA INIT FAILED!" << endl;
			return 1;
		}
		cout << "CUDA Bench: " << flush;
		for (unsigned i = 0; i < 10; ++i)
			double tmptest = cd.path_analysis(0,80,false,false);
		timer cdbench(true);
		double cudatest = 0;
		for (unsigned i = 0; i < 10; ++i)
			cudatest = cd.path_analysis(0,80,false,false);
		cout << (cdbench.time()/10.0) << "s" << endl;
		if (cudatest != 1.0) {
			cout << "CUDA error ?!: " << cudatest << " != 1.0" << endl;
			cudatest = cd.path_analysis(0,80,false,true);
			return 1;
		}
#endif

		if (!dornd4) {
			sha1differentialpath path;
			try { load_bz2(path, workdir + "/path_t20", text_archive); } catch (exception& ) { path.clear(); } catch (...) { path.clear(); }
			cout << "Constructing optimized path for t=[15,80)..." << endl;
			const unsigned windowsize = global_windowsize;
			unsigned tbegin = 15;
			unsigned tend = 80;
			// scan for first localcollision within range [tbegin,tend)
			for (unsigned i = 0; i < lccombiner.met.size(); ++i)
				if (lccombiner.met[i] >= tbegin) {
					tbegin = lccombiner.met[i];
					// scan for first localcollision gap
					for (unsigned j = i+1; j < lccombiner.met.size(); ++j)
						if (lccombiner.met[j] > lccombiner.met[j-1]+5) {
							tend = lccombiner.met[j-1]+6;
							if (tend > 80) tend = 80;
							break;
						}					
					break;
				}
			lcidxs.assign(lccombiner.met.size(), -1);
			while (true) {
				vector< vector<int8> > best_lcidxs;
				cout << "Optimizing for t=[" << tbegin << "," << tend << ")..." << endl;
				retrieve_optimal_lcss(cd, lccombiner, tbegin, tend, best_lcidxs, me_frac_range, windowsize);
				for (unsigned i = 0; i < lccombiner.melcidx.size(); ++i)
					if (lccombiner.melcidx[i] >= 0)
						lcidxs[i] = lccombiner.melcidx[i];
				if (tend == 80) break;
				tbegin = tend;
				tend = 80;
				// scan for first localcollision within range [tbegin,tend)
				for (unsigned i = 0; i < lccombiner.met.size(); ++i)
					if (lccombiner.met[i] >= tbegin) {
						tbegin = lccombiner.met[i];
						// scan for first localcollision gap
						for (unsigned j = i+1; j < lccombiner.met.size(); ++j)
							if (lccombiner.met[j] > lccombiner.met[j-1]+5) {
								tend = lccombiner.met[j-1]+6;
								if (tend > 80) tend = 80;
								break;
							}					
						break;
					}
			}

			// determine example diff path (conditions only optimal for round 1)
			lccombiner.set_lc_indices(lcidxs);
			determine_bitconditions(cd, lccombiner, path, 15, 80);
			show_path(path);
			save_bz2(path, workdir + "/path_t20", text_archive);
			sha1differentialpath tmppath;
			for (int t = path.tbegin(); t < path.tend(); ++t)
				if (t <= 21) {
					tmppath[t] = path[t];
					tmppath.getme(t) = path.getme(t);
				}
			save_bz2(tmppath, workdir + "/path_t20trunc", text_archive);

			// show probabilities from low t up to step t=79
			lccombiner.set_lc_indices(lcidxs);
			cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft);
			vector<double> probv(80,1);
			bool outuse1 = true;
			cd.init_samples(15, true, true); 
			outuse1 = !outuse1;
			for (unsigned t = 15; t < 80; ++t)
			{
				probv[t] = cd.run_step(t, true, bool(80>t+2), outuse1);
				outuse1 = !outuse1;
			}
			for (int t = 15; t < 30; ++t)
			{
				double cumprob = 1;
				for (int tt = t; tt < int(80); ++tt)
					cumprob *= probv[tt];
				cout << "[" << t << ":" << log(cumprob)/log(2.0) << "] ";
			}
			cout << endl;
			return 0;
		} else {
			cout << "Analyzing round 4..." << endl;
			round4_analysis(cd, parameters);
			return 0;
		}
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



unsigned load_block(istream& i, uint32 block[])
{	
	for (unsigned k = 0; k < 16; ++k)
		block[k] = 0;

	unsigned len = 0;
	char uc;
	for (unsigned k = 0; k < 16; ++k)
		for (unsigned c = 0; c < 4; ++c)
		{
			i.get(uc);
			if (i) {
				++len;
				block[k] += uint32((unsigned char)(uc)) << (c*8);
			} else {
				i.putback(uc);
				i.setstate(ios::failbit);
				return len;
			}
		}
	return len;
}

void save_block(ostream& o, uint32 block[])
{
	for (unsigned k = 0; k < 16; ++k)
		for (unsigned c = 0; c < 4; ++c)
			o << (unsigned char)((block[k]>>(c*8))&0xFF);
}
