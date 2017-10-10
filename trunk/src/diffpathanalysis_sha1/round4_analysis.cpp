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

#include <hashutil5/saveload_gz.hpp>
#include <hashutil5/sdr.hpp>
#include <hashutil5/timer.hpp>
#include <hashutil5/rng.hpp>
#include <hashutil5/progress_display.hpp>
#include <hashutil5/sha1messagespace.hpp>

#include "main.hpp"
#include "sha1_localcollision.hpp"
#include "path_prob_analysis.hpp"
#include "sha1_path_lc_analysis.hpp"

using namespace hashutil;
using namespace std;
namespace po = boost::program_options;
namespace fs = boost::filesystem;

struct dqt_sort {
	uint32 data[5];

	bool operator< (const dqt_sort& r) const
	{
		if (data[4] < r.data[4]) return true;
		if (data[4] > r.data[4]) return false;
		if (data[3] < r.data[3]) return true;
		if (data[3] > r.data[3]) return false;
		if (data[2] < r.data[2]) return true;
		if (data[2] > r.data[2]) return false;
		if (data[1] < r.data[1]) return true;
		if (data[1] > r.data[1]) return false;
		if (data[0] < r.data[0]) return true;
		return false;
	}
	bool operator== (const dqt_sort& r) const
	{
		for (int i = 4; i >= 0; --i)
			if (data[i] != r.data[i]) return false;
		return true;
	}

	template<class Archive>
	void serialize(Archive& ar, const unsigned int file_version)
	{			
		ar & boost::serialization::make_nvp("data", data);
	}
};


// defined below
void analyze_indepsection_prob(sha1messagespace& mespace, int tbegin, const uint32 dmmask[80], vector<dqt_sort>& target_dihvs);


	void round4_analysis(cuda_device& cd, const parameters_type& parameters)
	{
		cerr << "Implementation not available." << endl;
		// This code section needs thorough inspection and cleanup before release
		exit(1);
	}


void analyze_indepsection_prob(sha1messagespace& mespace, int tbegin, const uint32 dmmask[80], vector<dqt_sort>& target_dihvs)
{
	const unsigned int tend = 80;
	cout << "Analyzing probability for t=[" << tbegin << "-" << tend << ")." << endl;

	vector< vector<uint32> > pathbitrelations16;
	vector< vector< vector<uint32> > > pathbitrelationsmatrix;
	mespace.tobitrelations_16(pathbitrelations16);
	cout << "Bitrelations: " << pathbitrelations16.size() << endl;
	pathbitrelationsmatrix.resize(16);
	for (unsigned i = 0; i < 16; ++i)
		pathbitrelationsmatrix[i].resize(32);
	for (unsigned i = 0; i < pathbitrelations16.size(); ++i) {
		int lastcol = -1;
		for (int col = 16*32-1; col >= 0; --col)
			if (pathbitrelations16[i][col>>5]&(1<<(col&31))) {
				lastcol = col;
				unsigned t = lastcol>>5;
				unsigned b = lastcol&31;
				pathbitrelationsmatrix[t][b] = pathbitrelations16[i];
				break;
			}
		if (lastcol == -1) throw;
	}

	const int offset = 4;
	uint32 Q[85];
	uint32 Q2[85];
	uint32 m[80];
	uint32 m2[80];

	bool forceddihvs = false;
	vector<dqt_sort> target_dihvs2;
	if (target_dihvs.size()) {
		forceddihvs = true;
		sort(target_dihvs.begin(), target_dihvs.end());
		cout << "Forcing target dIHVs (#=" << target_dihvs.size() << ")." << endl;
	}

	if (1) //target_dihvs.size() == 0)
	{
		cout << "Determining target dIHVs..." << endl;
		uint64 oksize = 1;
		while (true) {
			if (oksize >= (1<<27)) break;
			bool oksizeok = true;
			try {
				vector<dqt_sort> tmpdihvs(oksize*2);
			} catch (std::exception&) {oksizeok = false;} catch(...) {oksizeok = false;}
			if (!oksizeok)
				break;
			oksize *= 2;
		}
		uint64 bufsize = oksize;
		cout << "Maximum size temporary dIHV buffer: " << bufsize << endl;
		vector<dqt_sort> dihvs(bufsize);
		progress_display pd(dihvs.size());
		for (unsigned i = 0; i < dihvs.size(); ++i,++pd) {
			for (int t = 0; t < 16; ++t) {
				uint32 metmask = 0;
				uint32 metset1 = 0;
				for (unsigned b = 0; b < 32; ++b) {
					if (pathbitrelationsmatrix[t][b].size()) {
						metmask |= pathbitrelationsmatrix[t][b][t];
						uint32 v = pathbitrelationsmatrix[t][b][16]&1;
						for (int t1 = 0; t1 < t; ++t1)
							v ^= m[t1]&pathbitrelationsmatrix[t][b][t1];
						if (hw(v)&1)
							metset1 |= 1<<b;
					}
				}
				m[t] = (xrng128() & ~metmask) | metset1;
				m2[t] = m[t] ^ dmmask[t];
			}
			for (int t = 16; t < 80; ++t) {
				m[t]=rotate_left(m[t-3] ^ m[t-8] ^ m[t-14] ^ m[t-16], 1);
				m2[t]=rotate_left(m2[t-3] ^ m2[t-8] ^ m2[t-14] ^ m2[t-16], 1);
			}
			for (int t = tbegin-4; t <= tbegin; ++t)
				Q2[offset+t] = Q[offset+t] = xrng128();
			for (int t = tbegin; t < 60; ++t) {
				sha1_step_round3(t, Q, m);
				sha1_step_round3(t, Q2, m2);
			}
			for (int t = (tbegin<60?60:tbegin); t < 80; ++t) {
				sha1_step_round4(t, Q, m);
				sha1_step_round4(t, Q2, m2);
			}
			dihvs[i].data[0] = rotate_left(Q2[offset+80-4],30)-rotate_left(Q[offset+80-4],30);
			dihvs[i].data[1] = rotate_left(Q2[offset+80-3],30)-rotate_left(Q[offset+80-3],30);
			dihvs[i].data[2] = rotate_left(Q2[offset+80-2],30)-rotate_left(Q[offset+80-2],30);
			dihvs[i].data[3] = Q2[offset+80-1]-Q[offset+80-1];
			dihvs[i].data[4] = Q2[offset+80]-Q[offset+80];
		}
		sort(dihvs.begin(), dihvs.end());
		unsigned i = 0;
		vector<unsigned> bestcnts;
		while (i < dihvs.size()) {
			unsigned j = i+1;
			while (j < dihvs.size() && dihvs[j] == dihvs[i]) ++j;
			bestcnts.push_back(j-i);
			i = j;
		}
		cout << "Prob t=[" << tbegin << "-" << 80 << "): " << flush;
		sort(bestcnts.begin(),bestcnts.end());
		unsigned bestcnt = bestcnts[bestcnts.size()-1];
		if (bestcnt == 1) {
			cerr << "Warning: bestcount = 1: no best dIHVs discernable!" << endl;
			exit(0);
		}

		i = 0;
		while (i < dihvs.size()) {
			unsigned j = i+1;
			while (j < dihvs.size() && dihvs[j] == dihvs[i]) ++j;
			if (forceddihvs) {
				if (binary_search(target_dihvs.begin(), target_dihvs.end(), dihvs[i])) {
					cout << "\tprob=" << log(double(j-i)/double(dihvs.size()))/log(2.0) << ":\t";
					for (unsigned k = 0; k < 5; ++k)
						cout << naf(dihvs[i].data[k]) << " ";
					cout << endl;
				} else if ((j-i)*2 >= bestcnt) {
					cout << "N.I.\tprob=" << log(double(j-i)/double(dihvs.size()))/log(2.0) << ":\t";
					for (unsigned k = 0; k < 5; ++k)
						cout << naf(dihvs[i].data[k]) << " ";
					cout << endl;
					target_dihvs2.push_back(dihvs[i]);
					sort(target_dihvs2.begin(), target_dihvs2.end());
				}
			} else {
				if ((j-i)*2 >= bestcnt) {
 					cout << "\tprob=" << log(double(j-i)/double(dihvs.size()))/log(2.0) << ":\t";
					for (unsigned k = 0; k < 5; ++k)
						cout << naf(dihvs[i].data[k]) << " ";
					cout << endl;
					target_dihvs.push_back(dihvs[i]);
				}
			}
			i = j;
		}
		{ vector<dqt_sort> tmptmp(1); dihvs.swap(tmptmp); } // free memory
		sort(target_dihvs.begin(), target_dihvs.end());
	}
	
	cout << "Checking cumulative probability target dIHVs: " << flush;
	uint64 cnt = 0, okcnt = 0, okcnt2 = 0;
	dqt_sort dihv;
	while (true) {
		for (int t = 0; t < 16; ++t) {
			uint32 metmask = 0;
			uint32 metset1 = 0;
			for (unsigned b = 0; b < 32; ++b) {
				if (pathbitrelationsmatrix[t][b].size()) {
					metmask |= pathbitrelationsmatrix[t][b][t];
					uint32 v = pathbitrelationsmatrix[t][b][16]&1;
					for (int t1 = 0; t1 < t; ++t1)
						v ^= m[t1]&pathbitrelationsmatrix[t][b][t1];
					if (hw(v)&1)
						metset1 |= 1<<b;
				}
			}
			m[t] = (xrng128() & ~metmask) | metset1;
			m2[t] = m[t] ^ dmmask[t];
		}
		for (int t = 16; t < 80; ++t) {
			m[t]=rotate_left(m[t-3] ^ m[t-8] ^ m[t-14] ^ m[t-16], 1);
			m2[t]=rotate_left(m2[t-3] ^ m2[t-8] ^ m2[t-14] ^ m2[t-16], 1);
		}
		for (int t = tbegin-4; t <= tbegin; ++t)
			Q2[offset+t] = Q[offset+t] = xrng64();
		for (int t = tbegin; t < 60; ++t) {
			sha1_step_round3(t, Q, m);
			sha1_step_round3(t, Q2, m2);
		}
		for (int t = (tbegin<60?60:tbegin); t < 80; ++t) {
			sha1_step_round4(t, Q, m);
			sha1_step_round4(t, Q2, m2);
		}
		dihv.data[0] = rotate_left(Q2[offset+80-4],30)-rotate_left(Q[offset+80-4],30);
		dihv.data[1] = rotate_left(Q2[offset+80-3],30)-rotate_left(Q[offset+80-3],30);
		dihv.data[2] = rotate_left(Q2[offset+80-2],30)-rotate_left(Q[offset+80-2],30);
		dihv.data[3] = Q2[offset+80-1]-Q[offset+80-1];
		dihv.data[4] = Q2[offset+80]-Q[offset+80];
		++cnt;
		if (binary_search(target_dihvs.begin(), target_dihvs.end(), dihv)) {
			++okcnt;
			if (forceddihvs)
				++okcnt2;
		} else {
			if (forceddihvs && binary_search(target_dihvs2.begin(), target_dihvs2.end(), dihv))
				++okcnt2;
		}
		if (hw(cnt)+hw(cnt>>32)==1 && okcnt > 1) {
			cout << "[" << cnt << ":p=" << log(double(okcnt)/double(cnt))/log(2.0);
			if (forceddihvs)
				cout << "|p2=" << log(double(okcnt2)/double(cnt))/log(2.0);
			cout << "]" << flush;
			if (okcnt >= (1<<7))
				break;
		}
	}
	cout << endl;
}
