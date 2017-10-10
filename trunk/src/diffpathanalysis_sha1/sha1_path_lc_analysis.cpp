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

#include <set>
#include <boost/lexical_cast.hpp>
#include <hashutil5/progress_display.hpp>
#include <hashutil5/saveload_bz2.hpp>
#include <hashutil5/rng.hpp>
#include <hashutil5/sha1messagespace.hpp>

#include "sha1_path_lc_analysis.hpp"
#include "sha1_lctobitconditions.hpp"
#include "main.hpp"

using namespace hashutil;
using namespace std;

namespace hash {

	vector< set< vector<int8> > > checkdme_helpvec;
	void expand_checkdme(localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend, const vector<int8>& in, vector< vector<int8> >& out)
	{
		static vector<int8> lcidxs;
		static vector<int8> indices;
		lcidxs = in;
		lcidxs.resize(lccombiner.melc.size(), -1);
		indices.clear();
		uint64 cnt = 1;
		for (unsigned i = 0; i < lcidxs.size(); ++i) {
			if (lccombiner.met[i] >= tbegin && lccombiner.met[i] < tend)
			{
				indices.push_back(i);
				cnt *= lccombiner.melc[i].size();
			}
		}
		for (uint64 c = 0; c < cnt; ++c) {
			uint64 cc = c;
			for (unsigned i = 0; i < indices.size(); ++i) {
				const unsigned k = indices[i];
				lcidxs[k] = cc % lccombiner.melc[k].size();
				cc /= lccombiner.melc[k].size();
			}
			if (lccombiner.checkdme(lcidxs))
				out.push_back(lcidxs);
		}
	}

	void build_check_dme(localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend)
	{
		// small tbegin is not necessary
		if (tbegin < 10) throw;
		cout << "Building check dme data structure..." << endl;
		try {
			checkdme_helpvec.clear();
			load_bz2(checkdme_helpvec, workdir + "/checkdme_helpvec_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(tend), binary_archive);
		} catch (exception& e) { checkdme_helpvec.clear(); } catch (...) { checkdme_helpvec.clear(); }
		if (checkdme_helpvec.size()) return;

		vector<int8> lcidxs;
		lcidxs.assign(lccombiner.melc.size(),-1);
		best_lcs helper;
		helper.set(lccombiner, tbegin-5, tbegin, true);
		unsigned oldiwbegin = helper.iwbegin();
		checkdme_helpvec.clear();
		checkdme_helpvec.resize(80);
		checkdme_helpvec[tbegin-1].insert(helper.make_key(lcidxs));

		vector< vector<int8> > lcidxsval;
		for (unsigned t = tbegin; t < tend; ++t) {
			cout << "====== " << t << " =======" << endl;
			helper.set(lccombiner, t+1-5, t+1, true);
			lcidxs.assign(lccombiner.melc.size(),-1);
			cout << "#in: " << checkdme_helpvec[t-1].size() << endl;
			for (set< vector<int8> >::const_iterator cit = checkdme_helpvec[t-1].begin(); cit != checkdme_helpvec[t-1].end(); ++cit) {
				for (unsigned i = 0; i < cit->size(); ++i)
					lcidxs[oldiwbegin+i] = (*cit)[i];
				lcidxsval.clear();
				expand_checkdme(lccombiner, t, t+1, lcidxs, lcidxsval);
				for (vector< vector<int8> >::const_iterator cit2 = lcidxsval.begin(); cit2 != lcidxsval.end(); ++cit2)
					checkdme_helpvec[t].insert( helper.make_key(*cit2) );
			}
			cout << "#out: " << checkdme_helpvec[t].size() << endl;
			oldiwbegin = helper.iwbegin();
		}
		for (unsigned t = tend-2; t >= tbegin; --t) {
			helper.set(lccombiner, t+1-5, t+1, true);
			oldiwbegin = helper.iwbegin();
			helper.set(lccombiner, t+2-5, t+2, false);
			lcidxs.assign(lccombiner.melc.size(),-1);
			cout << "#before: " << checkdme_helpvec[t].size() << endl;
			for (set< vector<int8> >::const_iterator cit = checkdme_helpvec[t].begin(); cit != checkdme_helpvec[t].end(); /* ++cit */) {
				for (unsigned i = 0; i < cit->size(); ++i)
					lcidxs[oldiwbegin+i] = (*cit)[i];
				lcidxsval.clear();
				expand_checkdme(lccombiner, t+1, t+2, lcidxs, lcidxsval);
				bool valisok = false;
				for (vector< vector<int8> >::const_iterator cit2 = lcidxsval.begin(); cit2 != lcidxsval.end(); ++cit2)
					if (checkdme_helpvec[t+1].find( helper.make_key(*cit2) ) != checkdme_helpvec[t+1].end()) {
						valisok = true;
						break;
					}
				if (!valisok)
					checkdme_helpvec[t].erase(cit++);
				else
					++cit;
			}
			cout << "#after: " << checkdme_helpvec[t].size() << endl;
		}
		cout << "Finished building check dme data structure..." << endl;
		try {
			save_bz2(checkdme_helpvec, workdir + "/checkdme_helpvec_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(tend), binary_archive);
		} catch (exception&) {} catch (...) {}
	}

	void expand_lcs(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend,
					const vector<int8>& in, vector< vector<int8> >& out, vector<double>& outprob, bool verbose)
	{
		const unsigned tendanalysis = tend+6 < 80 ? tend+6 : 80;
		out.clear(); outprob.clear();
		static vector<int8> lcidxs, lcidxs2;
		static vector<int8> indices, indices2;
		static vector< vector<int8> > lcidxsval;

		lcidxs = in;
		indices.clear(); 
		lcidxsval.clear();

		unsigned iwbegin = 0, iwend = lccombiner.melc.size();
		for (unsigned i = 0; i < lcidxs.size(); ++i)
			if (lccombiner.met[i] >= tend - 5) {
				iwbegin = i;
				break;
			}
		for (unsigned i = 0; i < lcidxs.size(); ++i)
			if (lccombiner.met[i] < tend)
				iwend = i+1;

		uint64 cnt = 1, cnt2 = 1;
		unsigned lasttind = iwend;
		for (unsigned i = 0; i < lcidxs.size(); ++i)
		{
			if (lccombiner.met[i] >= tbegin && lccombiner.met[i] < tend)
			{
				indices.push_back(i);
				cnt *= lccombiner.melc[i].size();
				lasttind = i+1;
			}
		}
		progress_display pd(cnt, false);
		if (verbose) {
			cout << cnt << "x" << cnt2 << endl;
			pd.redraw(true);
		}
		for (uint64 c = 0; c < cnt; ++c) {
			uint64 cc = c;
			for (unsigned i = 0; i < indices.size(); ++i) {
				const unsigned k = indices[i];
				lcidxs[k] = cc % lccombiner.melc[k].size();
				cc /= lccombiner.melc[k].size();
			}
			lcidxs2.assign( lcidxs.begin() + iwbegin, lcidxs.begin() + iwend);
			if (lccombiner.checkdme(lcidxs) && checkdme_helpvec[tend-1].find(lcidxs2) != checkdme_helpvec[tend-1].end()) {
				lcidxs2.assign( lcidxs.begin(), lcidxs.begin() + lasttind );
				lcidxsval.push_back(lcidxs2);
			}
			if (verbose) ++pd;
		}
		unsigned okcnt = 0;
		double bestp = 0;
		if (verbose) {
			cout << lcidxsval.size() << endl;
			pd.restart(lcidxsval.size());
			pd.redraw(true);
		}
		for (vector< vector<int8> >::iterator it = lcidxsval.begin(); it != lcidxsval.end(); ++it)
		{
			lcidxs = *it; lcidxs.resize(lccombiner.melc.size(),-1);
			lccombiner.set_lc_indices(lcidxs);
			cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft);
			unsigned tbeginanalysis = 0;
			for (unsigned i = 0; i < lcidxs.size(); ++i)
				if (lcidxs[i] >= 0) {
					tbeginanalysis = lccombiner.met[i];
					break;
				}
			double pr = cd.path_analysis(tbeginanalysis,tendanalysis);
			if (pr > 0) {
				out.push_back(lcidxs);
				outprob.push_back(pr);
				++okcnt;
				
				if (pr > bestp)
					bestp = pr;
			}
			if (verbose) ++pd;
		}
		if (verbose)
			cout << "Done: " << okcnt << " " << log(bestp)/log(2.0) << endl << endl;
	}



	vector<best_lcs> global_best_lcs_history;
	localcollision_combiner global_lccombiner;
	vector<unsigned> fixed_indices;
	vector<int8> optimal_indices;
	void retrieve_optimal_lcs(int index,  const vector<int8>& lci, double lcp, double minp, vector< vector<int8> >& out, vector< double >& out_prob)
	{
		best_lcs& I = global_best_lcs_history[index];	
		vector<int8> key = I.make_key(lci);
		vector<int8> tmp = lci;
		best_lcs::const_iterator it = I.find(key);
		if (it != I.end()) 
		{
			double p = lcp / it->second.first;
			const vector< pair<double, vector<int8> > >& fulldata = I.find_full(key)->second;
			for (unsigned j = 0; j < fulldata.size(); ++j)
				if (p * fulldata[j].first >= minp)
				{
					if (index == 0) {
						for (unsigned k = 0; k < I.iwbegin(); ++k)
							if (fulldata[j].second[k] != -1)
								tmp[k] = fulldata[j].second[k];
						out.push_back(tmp);
						out_prob.push_back(p * fulldata[j].first);
						if (hw(uint32(out.size())) == 1)
							cout << out.size() << " " << flush;
					} else {
						for (unsigned k = 0; k < I.iwbegin(); ++k)
							if (fulldata[j].second[k] != -1)
								tmp[k] = fulldata[j].second[k];
						bool ok = true;
						for (unsigned k = 0; k < fixed_indices.size(); ++k)
							if (fixed_indices[k] >= I.iwbegin() && tmp[fixed_indices[k]] != optimal_indices[fixed_indices[k]])
								ok = false;
						if (!ok) continue;
						retrieve_optimal_lcs(index-1, tmp, p*fulldata[j].first, minp, out, out_prob);
					}
				}
		}
	}


	void optimize_lcs(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend, unsigned windowsize)
	{
		build_check_dme(lccombiner,tbegin,tend);
		const unsigned startwindowsize = global_windowsize;

		best_lcs in, out2;
		vector< vector<int8> > lvin, lvout;
		vector< double > lpin, lpout;

		vector<int8> lcidxs(lccombiner.melcidx.size(), -1);
		try {
			load_bz2(lvout, workdir + "/lvout0" + "_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive);
			load_bz2(lpout, workdir + "/lpout0" + "_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive);
		} catch (exception&) {
			lvout.clear(); lpout.clear();
		} catch (...) {
			lvout.clear(); lpout.clear();
		}
		
		if (lvout.size() == 0) {
			cout << "Step " << tbegin+startwindowsize-1 << " (startwindow)" << endl;
			expand_lcs(cd, lccombiner, tbegin, tbegin+startwindowsize, lcidxs, lvout, lpout, true);
			try {save_bz2(lvout, workdir + "/lvout0" + "_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive);}catch (exception&) {} catch (...) {}
			try {save_bz2(lpout, workdir + "/lpout0" + "_" + boost::lexical_cast<string>(tbegin) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive);}catch (exception&) {} catch (...) {}
		} else 
			cout << "Loaded step " << tbegin+startwindowsize-1 << " (startwindow)" << endl;

		in.set(lccombiner, tbegin+startwindowsize-windowsize, tbegin+startwindowsize);
		in.insert(lvout, lpout);
		double bestp;
		vector<best_lcs>& best_lcs_history = global_best_lcs_history;
		best_lcs_history.clear();

		global_lccombiner = lccombiner;
		
		best_lcs_history.push_back(in);
		for (unsigned t = tbegin+startwindowsize; t < tend; ++t) {
			cout << "Step " << t << ": " << in.size() << endl;
			unsigned j = 0;
			if (0)
				for (best_lcs::const_iterator it = in.begin(); it != in.end() && j < 5; ++it,++j)
				{
					cout << j << "\t: ";
					for (unsigned i = 0; i < it->first.size(); ++i)
						cout << it->first[i] << " ";
					cout << endl;
				}
			bool outloaded = true;
			best_lcs out;
			try {
				load_bz2(out, workdir + "/best_lcsout" + boost::lexical_cast<string>(tbegin) + "-" + boost::lexical_cast<string>(t) + "_" + boost::lexical_cast<string>(windowsize) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive);
				cout << "Loaded step " << t << endl;
			} catch (exception& e) { outloaded = false; } catch (...) { outloaded = false; }
			if (!outloaded) {
				out.set(lccombiner, t+1-windowsize, t+1);
				unsigned cnt = 1;
				for (unsigned i = 0; i < lccombiner.melc.size(); ++i)
					if (lccombiner.met[i] == t)
						cnt *= lccombiner.melc[i].size();
				cout << "x" << cnt << endl;
				progress_display pd(in.size());
				if (out.iwend() == in.iwend()) {
					for (best_lcs::const_iterator it = in.begin(); it != in.end(); ++it,++pd)
						out.insert(it->second.second, it->second.first);
				} else {
					for (best_lcs::const_iterator it = in.begin(); it != in.end(); ++it,++pd)
					{
						expand_lcs(cd, lccombiner, t, t+1, it->second.second, lvout, lpout, false);
						out.insert(lvout, lpout);
					}
				}
				try {save_bz2(out, workdir + "/best_lcsout" + boost::lexical_cast<string>(tbegin) + "-" + boost::lexical_cast<string>(t) + "_" + boost::lexical_cast<string>(windowsize) + "_" + boost::lexical_cast<string>(startwindowsize), binary_archive); } catch (exception&) {} catch (...) {}
			}
			bestp = 0;
			for (best_lcs::const_iterator it = out.begin(); it != out.end(); ++it)
				if (it->second.first > bestp) {
					bestp = it->second.first;
					lcidxs = it->second.second;
				}
			cout << "bestp: " << log(bestp)/log(2.0) << endl << endl;
			best_lcs_history.push_back(out);
			in = out;
		}

		lccombiner.set_lc_indices(lcidxs);
		cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft);
		vector<double> probv(80,1);
		bool outuse1 = true;
		cd.init_samples(tbegin, true, bool(tend>tbegin+1)); 
		outuse1 = !outuse1;
		for (unsigned t = tbegin; t < tend; ++t)
		{
			probv[t] = cd.run_step(t, true, bool(tend>t+2), outuse1);
			outuse1 = !outuse1;
		}
		for (int t = 15; t < 30; ++t)
		{
			double cumprob = 1;
			for (int tt = t; tt < int(tend); ++tt)
				cumprob *= probv[tt];
			cout << "[" << t << ":" << log(cumprob)/log(2.0) << "] ";
		}
		cout << endl;
	}

	void retrieve_optimal_lcss(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend, vector< vector<int8> >& out, double pmarge, unsigned windowsize)
	{
		optimize_lcs(cd, lccombiner, tbegin, tend, windowsize);
		//expects optimize_lcs to leave generated best_lcs_history in global_best_lcs_history;
		vector<int8> lcidxs = lccombiner.melcidx;
		vector<double> out_prob;
		fixed_indices.clear();
		optimal_indices = lcidxs;

		best_lcs& in = global_best_lcs_history[global_best_lcs_history.size()-1];
		double bestp = 0;
		uint64 lastsize = 0;
		for (best_lcs::const_iterator it = in.begin(); it != in.end(); ++it)
			if (it->second.first > bestp) 
				bestp = it->second.first;
		for (double pmarge2 = 1.0; pmarge2 + 0.0025 >= pmarge; pmarge2 -= 0.005) {
			out.clear();
			out_prob.clear();
			for (best_lcs::const_iterator it = in.begin(); it != in.end(); ++it)
				retrieve_optimal_lcs(global_best_lcs_history.size()-2, it->second.second, it->second.first, bestp*pmarge2, out, out_prob);
			cout << "pmarge=" << pmarge2 << ": out.size(): " << out.size() << endl;
#if 1
			if (out.size() > (1<<20)) { cout << "out.size() > (1<<20)!!" << endl; break; }
			if (out.size() != lastsize && 
				(int(log(double(out.size()))/log(2.0))!=int(log(double(lastsize))/log(2.0)) || abs(pmarge2 - pmarge) <= 0.004)
				)
			{
				cout << "Generating message space..." << flush;
				sha1messagespace newspace;
				vector< vector<sdr> > lcidxsval_mesdr;
				vector<sdr> tmpsdrme;
				lcidxsval_mesdr.reserve(out.size());
				progress_display pdme(out.size());
				int outsize = 0;
				for (unsigned j = 0; j < out.size(); ++j,++pdme) {
					lccombiner.set_lc_indices(out[j]);
					lccombiner.get_me_sdr(tmpsdrme);
					for (unsigned k = 0; k < tmpsdrme.size(); ++k)
						if (k < tbegin || k >= tend)
							tmpsdrme[k] = sdr();
					lcidxsval_mesdr.push_back(tmpsdrme);
					if (j == 0) {
						for (unsigned jj = 0; jj < 80; ++jj)
							outsize += hw(~tmpsdrme[jj].mask); // count all bits not involved or without XOR difference
					}
				}
				cout << lcidxsval_mesdr.size() << flush;
				sort(lcidxsval_mesdr.begin(), lcidxsval_mesdr.end());
				lcidxsval_mesdr.erase( unique(lcidxsval_mesdr.begin(), lcidxsval_mesdr.end()), lcidxsval_mesdr.end());
				cout << " " << lcidxsval_mesdr.size() << flush;
				derive_sha1messagespace(newspace, tbegin, tend, lcidxsval_mesdr);
				outsize = newspace.basis.size() - outsize;				
				save_bz2(newspace, workdir + "/mespace_"+ boost::lexical_cast<string>(tbegin) +"_"+ boost::lexical_cast<string>(tend) +"_"+ boost::lexical_cast<string>(pmarge2) +"_"+ boost::lexical_cast<string>(outsize), text_archive);
				save_bz2(newspace, workdir + "/mespace_"+ boost::lexical_cast<string>(tbegin) +"_"+ boost::lexical_cast<string>(tend) +"_"+ boost::lexical_cast<string>(pmarge2) +"_"+ boost::lexical_cast<string>(outsize), binary_archive);
				cout << "done." << endl;
			}
			lastsize = out.size();
#endif
		}
		lccombiner.set_lc_indices(lcidxs);
	}

}
