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
#include <map>
#include <vector>

#include <hashutil5/rng.hpp>
#include <hashutil5/sdr.hpp>
#include <hashutil5/saveload_bz2.hpp>
#include <hashutil5/progress_display.hpp>

#include "sha1_localcollision.hpp"

using namespace std;

namespace hash {

	void findlocalcollisions(unsigned t, unsigned b, localcollision_vector& results, double minp = (double(1)/double(32))*0.9)
	{
		const int offset = 4;
		results.clear();
		uint32 Q[85];
		uint32 Q2[85];
		uint32 m[80];
		uint32 m2[80];
		static localcollision_vector lcvec;	
		lcvec.clear();
		lcvec.reserve(1<<22);
		localcollision lc;	
		for (unsigned count = 0; count < (1<<22); ++count)
		{
			lc.mdiff[0] = 1<<b;
			m2[t] = m[t] = xrng64();
			m2[t] += (1<<b);
			Q2[offset+t] = Q[offset+t] = xrng64();
			Q2[offset+t-1] = Q[offset+t-1] = xrng64();
			Q2[offset+t-2] = Q[offset+t-2] = xrng64();
			Q2[offset+t-3] = Q[offset+t-3] = xrng64();
			Q2[offset+t-4] = Q[offset+t-4] = xrng64();
			sha1_step(t, Q, m);
			sha1_step(t, Q2, m2);
			for (unsigned k = t+1; k < t+6 && k < 80; ++k)
			{
				m2[k] = m[k] = xrng64();
				sha1_step(k, Q, m);
				sha1_step(k, Q2, m2);
				m2[k] -= Q2[offset+k+1] - Q[offset+k+1];
				lc.mdiff[k-t] = m2[k]-m[k];
				Q2[offset+k+1] = Q[offset+k+1];
			}
			lcvec.push_back(lc);
		}
		sort(lcvec.begin(), lcvec.end());
		localcollision tmp;
		unsigned i0 = 0;
		while (i0 < lcvec.size())
		{
			unsigned e0 = i0;
			while (e0 < lcvec.size() && lcvec[e0].mdiff[0] == lcvec[i0].mdiff[0])
				++e0;
			tmp.mdiff[0] = lcvec[i0].mdiff[0];
			tmp.mmask[0] = naf(tmp.mdiff[0]).mask;
			tmp.pcond[0] = double(e0-i0)/double(lcvec.size());
			
			unsigned i1 = i0;
			while (i1 < e0)
			{
				unsigned e1 = i1;
				while (e1 < e0 && lcvec[e1].mdiff[1] == lcvec[i1].mdiff[1])
					++e1;
				tmp.mdiff[1] = lcvec[i1].mdiff[1];
				tmp.mmask[1] = naf(tmp.mdiff[1]).mask;
				tmp.pcond[1] = double(e1-i1)/double(lcvec.size());

				unsigned i2 = i1;
				while (i2 < e1)
				{
					unsigned e2 = i2;
					while (e2 < e1 && lcvec[e2].mdiff[2] == lcvec[i2].mdiff[2])
						++e2;
					tmp.mdiff[2] = lcvec[i2].mdiff[2];
					tmp.mmask[2] = naf(tmp.mdiff[2]).mask;
					tmp.pcond[2] = double(e2-i2)/double(lcvec.size());

					unsigned i3 = i2;
					while (i3 < e2)
					{
						unsigned e3 = i3;
						while (e3 < e2 && lcvec[e3].mdiff[3] == lcvec[i3].mdiff[3])
							++e3;
						tmp.mdiff[3] = lcvec[i3].mdiff[3];
						tmp.mmask[3] = naf(tmp.mdiff[3]).mask;
						tmp.pcond[3] = double(e3-i3)/double(lcvec.size());

						unsigned i4 = i3;
						while (i4 < e3)
						{
							unsigned e4 = i4;
							while (e4 < e3 && lcvec[e4].mdiff[4] == lcvec[i4].mdiff[4])
								++e4;
							tmp.mdiff[4] = lcvec[i4].mdiff[4];
							tmp.mmask[4] = naf(tmp.mdiff[4]).mask;
							tmp.pcond[4] = double(e4-i4)/double(lcvec.size());

							unsigned i5 = i4;
							while (i5 < e4)
							{
								unsigned e5 = i5;
								while (e5 < e4 && lcvec[e5].mdiff[5] == lcvec[i5].mdiff[5])
									++e5;
								tmp.mdiff[5] = lcvec[i5].mdiff[5];
								tmp.mmask[5] = naf(tmp.mdiff[5]).mask;
								tmp.pcond[5] = double(e5-i5)/double(lcvec.size());
								if (tmp.pcond[5] >= minp)
									results.push_back(tmp);

								i5 = e5;
							}

							i4 = e4;
						}

						i3 = e3;
					}

					i2 = e2;
				}

				i1 = e1;
			}

			i0 = e0;
		}	
	}

	void initialize_localcollision_matrix(vector< vector<localcollision_vector> >& lcmat)
	{
		lcmat.clear();
		try {
			cout << "Loading localcollision matrix..." << flush;
			load_bz2(lcmat, "localcollisionmatrix", text_archive);
		} catch (...) {
			lcmat.clear();
		}
		if (lcmat.size() != 0) {
			cout << "done." << endl;
			return;
		}
		cout << "failed!" << endl << "Generating localcollision matrix...";

		lcmat.clear();
		save_bz2(lcmat, "localcollisionmatrix", text_archive);
		lcmat.resize(80);
		progress_display pd(80*32);
		for (unsigned t = 0; t < 80; ++t)
		{
			lcmat[t].resize(32);
			double maxp = 0;
			double maxp1 = 0, maxp2 = 0, maxp3 = 0, maxp4 = 0;
			for (unsigned b = 0; b < 32; ++b,++pd)
			{
				findlocalcollisions(t, b, lcmat[t][b]);			
				for (unsigned i = 0; i < lcmat[t][b].size(); ++i)
					if (lcmat[t][b][i].pcond[5] > maxp)
					{
						maxp4 = maxp3;
						maxp3 = maxp2;
						maxp2 = maxp1;
						maxp1 = maxp;
						maxp=lcmat[t][b][i].pcond[5];
					}
			}
		}
		save_bz2(lcmat, "localcollisionmatrix", text_archive);
	}


	void lc_to_me::set(const uint32 lcme[80]) {
		uint32 fullme[80];
		uint32 tmpme[80]; 
		for (unsigned j = 0; j < 80; ++j)
				fullme[j] = lcme[j];

		for (unsigned j = 1; j < 80; ++j)
				tmpme[j] = rotate_left(lcme[j-1],5);
		for (int j = 0; j >= 0; --j)
				tmpme[j] = rotate_right(tmpme[j+16], 1) ^ tmpme[j+13] ^ tmpme[j+8] ^ tmpme[j+2];
		for (unsigned j = 0; j < 80; ++j)
				fullme[j] ^= tmpme[j];   

		for (unsigned j = 2; j < 80; ++j)
				tmpme[j] = lcme[j-2];
		for (int j = 1; j >= 0; --j)
				tmpme[j] = rotate_right(tmpme[j+16], 1) ^ tmpme[j+13] ^ tmpme[j+8] ^ tmpme[j+2];
		for (unsigned j = 0; j < 80; ++j)
				fullme[j] ^= tmpme[j];   

		for (int k = 3; k < 6; ++k) {
				for (unsigned j = k; j < 80; ++j)
						tmpme[j] = rotate_left(lcme[j-k],30);
				for (int j = k-1; j >= 0; --j)
						tmpme[j] = rotate_right(tmpme[j+16], 1) ^ tmpme[j+13] ^ tmpme[j+8] ^ tmpme[j+2];
				for (unsigned j = 0; j < 80; ++j)
						fullme[j] ^= tmpme[j];   
		}
		mesdrs.clear();
		mesdrs.resize(80);
		mesdrs2.clear();
		mesdrs2.resize(80);
		for (unsigned j = 0; j < 80; ++j)
		{
			_fullme[j] = fullme[j];
			_lcme[j] = lcme[j];
			fill_sdrs(mesdrs[j], mesdrs2[j], _fullme[j]);
		}
	}

	void lc_to_me::fill_sdrs(std::vector<uint32>& out, std::vector<sdr>& out2, uint32 maskin) {
		out.clear();
		out2.clear();
		sdr m;
		m.mask = maskin;
		m.sign = 0;
		do {
			out.push_back(m.adddiff());
			out2.push_back(m);
			m.sign += 1 + ~maskin;
			m.sign &= maskin;
		} while (m.sign != 0);   
		sort(out.begin(), out.end());
		out.erase( unique(out.begin(),out.end()), out.end());
		sort(out2.begin(), out2.end());
		out2.erase( unique(out2.begin(),out2.end()), out2.end());

	}		

	// take disturbance vector mask, determine where localcollisions start and store all valid localcollisions (taken from lcmat) for each position (t,b)
	void localcollision_combiner::setlcme(const uint32 mme[80], const localcollisionvec_matrix& lcmat)
	{
		lcme.set(mme);
		uint32 me[80];
		met.clear(); meb.clear(); melc.clear(); melcidx.clear();
		for (unsigned t = 0; t < 80; ++t)
		{
			me[t] = mme[t];
			for (unsigned b = 0; b < 2; ++b)
				if ((me[t]>>b)&1)
				{
					unsigned b2 = b+1;
					while (b2 < 2 && ((me[t]>>b2)&1)) ++b2;
					met.push_back(t); meb.push_back(b);					
					me[t] &= ~((1<<b2)-(1<<b));
				}
			for (unsigned b = 2; b < 32-5; ++b)
				if ((me[t]>>b)&1)
				{
					unsigned b2 = b+1;
					while (b2 < 32-5 && ((me[t]>>b2)&1)) ++b2;
					met.push_back(t); meb.push_back(b);
					me[t] &= ~((1<<b2)-(1<<b));
				}
			for (unsigned b = 32-5; b < 32; ++b)
				if ((me[t]>>b)&1)
				{
					unsigned b2 = b+1;
					while (b2 < 32 && ((me[t]>>b2)&1)) ++b2;
					met.push_back(t); meb.push_back(b);
					if (b2 == 32)
						me[t] &= ~uint32(-(1<<b));
					else
						me[t] &= ~((1<<b2)-(1<<b));
				}
		}
		melc.resize(met.size());		
		for (unsigned i = 0; i < met.size(); ++i)
		{
			unsigned t = met[i];
			unsigned b = meb[i];
			for (unsigned k = 0; k < lcmat[t][b].size(); ++k)
			{
				if (lcmat[t][b][k].mmask[0] != (1<<b)) continue;
				if (t+1 < 80 && lcmat[t][b][k].mmask[1] != (1<<((b+5)%32))) continue;
				if (t+2 < 80 && lcmat[t][b][k].mmask[2] != (1<<(b))) continue;
				if (t+3 < 80 && lcmat[t][b][k].mmask[3] != (1<<((b-2)%32))) continue;
				if (t+4 < 80 && lcmat[t][b][k].mmask[4] != (1<<((b-2)%32))) continue;
				if (t+5 < 80 && lcmat[t][b][k].mmask[5] != (1<<((b-2)%32))) continue;
				melc[i].push_back(lcmat[t][b][k]);
#if 1 // only disable for testing!! this adds necessary freedoms !!
				localcollision tmp = lcmat[t][b][k];
				for (unsigned j = 0; j < 6; ++j)
					tmp.mdiff[j] = uint32(0) - tmp.mdiff[j];
				if (tmp.mdiff[0] != lcmat[t][b][k].mdiff[0])
					melc[i].push_back(tmp);
#endif
			}
		}
		
		melcidx.resize(met.size(),-1);
		for (unsigned t = 0; t < 80; ++t)
			dqt[t] = dme[t] = dft[t] = 0;
		for (unsigned t = 80; t < 85; ++t)
			dqt[t] = 0;
	}

	// for each position (met[i],meb[i]) give the index of the chosen localcollision in the vector of valid localcollisions (melc[i])
	// index value of -1 signifies ignored
	// combine the selected localcollision to set dme, dft, dqt
	void localcollision_combiner::set_lc_indices(const std::vector<int8>& lcidx)
	{
		memset(dqt, 0, sizeof(dqt));
		memset(dme, 0, sizeof(dme));
		memset(dft, 0, sizeof(dft));
		
		melcidx = lcidx;
		melcidx.resize(met.size(),-1); // sanitize
		for (unsigned i = 0; i < melc.size(); ++i)
		{
			if (melcidx[i] < 0 || melcidx[i] >= int(melc[i].size())) continue;
			unsigned t = met[i], b = meb[i];
			localcollision& tmp = melc[i][melcidx[i]];
			dqt[4+t+1] += tmp.mdiff[0];
			for (unsigned tt = t; tt < 80 && tt < t+6; ++tt)
				dme[tt] += tmp.mdiff[tt-t];
			for (unsigned tt = t + 2; tt < 80 && tt < t+5; ++tt)
				dft[tt] -= tmp.mdiff[tt-t];
		}
	}
	
	// check dme against lcme for specified interval tbegin <= i < tend  (whether the resulting dme can actually occur from the message expansion mask)
	// when ignoring localcollisions exclude their interval! otherwise it will return false
	bool localcollision_combiner::checkdme(unsigned tbegin, unsigned tend)
	{
		for (unsigned t = tbegin; t < tend; ++t)
			if (!lcme.checkme(t, dme[t]))
				return false;
		return true;
	}
	bool localcollision_combiner::checkdme()
	{
		vector<bool> checkt(80,true);
		for (unsigned i = 0; i < melc.size(); ++i)
			if (melcidx[i] < 0 || melcidx[i] >= int(melc[i].size()))
			{
				unsigned t = met[i];
				for (unsigned tt = t; tt < 80 && tt < t+6; ++tt)
					checkt[tt] = false;
			}
		for (unsigned t = 0; t < 80; ++t)
			if (checkt[t])
				if (!lcme.checkme(t, dme[t]))
					return false;
		return true;
	}
	bool localcollision_combiner::checkdme(const std::vector<int8>& lcidx)
	{
		static vector<bool> checkt;
		checkt.assign(80,true);
		if (lcidx.size() > melc.size()) throw std::runtime_error("huhuhuhu?!?!?@@@@@@@@@@@@@@@@@");;
		unsigned i = 0;
		while (i < lcidx.size()) {
			while (i < lcidx.size() && lcidx[i] >= 0 && lcidx[i] < int(melc[i].size()))
				++i;
			if ( i >= lcidx.size() ) break;
			unsigned j = i+1;
			while (j < lcidx.size() && (lcidx[j] < 0 || lcidx[j] >= int(melc[j].size())))
				++j;
			unsigned tbegin = met[i];
			unsigned tend = met[j-1]+6;
			if (80 < tend) tend = 80;
			for (unsigned tt = tbegin; tt < tend; ++tt)
				checkt[tt] = false;
			i = j;
		}
		memset(dme, 0, sizeof(dme));
		i = 0;
		for (unsigned t = 0; t < 80; ++t)
			if (checkt[t])
			{
				while (i < lcidx.size() && met[i]+5 < t)
					++i;
				for (; i < lcidx.size() && met[i]<=t; ++i)
				{
					if (lcidx[i] < 0 || lcidx[i] >= int(melc[i].size())) throw std::runtime_error("huhuhuhu?!?!?");
					unsigned ti = met[i];
					localcollision& tmp = melc[i][lcidx[i]];
					for (unsigned tt = ti; tt < 80 && tt < ti+6; ++tt)
						dme[tt] += tmp.mdiff[tt-ti];
				}
				if (!lcme.checkme(t, dme[t]))
					return false;
			}
		return true;
	}

	void localcollision_combiner::get_me_sdr(vector<sdr>& mesdr)
	{
		vector<bool> checkt(80,true);
		for (unsigned i = 0; i < melc.size(); ++i)
			if (melcidx[i] < 0 || melcidx[i] >= int(melc[i].size()))
			{
				unsigned t = met[i];
				for (unsigned tt = t; tt < 80 && tt < t+6; ++tt)
					checkt[tt] = false;
			}
		mesdr.clear();
		mesdr.resize(80);
		for (unsigned t = 0; t < 80; ++t)
			if (checkt[t]) {
				if (!lcme.checkme(t, dme[t])) throw std::runtime_error("localcollision_combiner::get_me_sdr(): dme invalid!");
				for (vector<sdr>::const_iterator cit = lcme.mesdrs2[t].begin(); cit != lcme.mesdrs2[t].end(); ++cit)
					if (cit->adddiff() == dme[t]) {
						mesdr[t] = *cit;
						break;
					}		
			}
	}

	void best_lcs::set(const localcollision_combiner& lccombiner, unsigned twindowbegin, unsigned twindowend, bool verbose)
	{
		_twbegin = twindowbegin;
		_twend = twindowend;
		_data.clear();
		_fulldata.clear();
		_key.clear();
		_iwbegin = lccombiner.melc.size();
		_iwend = 0;
		for (unsigned i = 0; i < lccombiner.melc.size(); ++i) {
			if (lccombiner.met[i] >= _twbegin && lccombiner.met[i] < _twend) {
				if (i < _iwbegin) _iwbegin = i;
				if (i+1 > _iwend) _iwend = i+1;
			}
		}
		if (_iwend < _iwbegin) _iwend = _iwbegin;
		if (verbose)
			cout << "init: " << _twbegin << " " << _twend << " " << _iwbegin << " " << _iwend << endl;
	}	
	void best_lcs::insert(const vector<int8>& lcidxs, double p)
	{
		make_key(lcidxs);
		_it = _data.find(_key);
		if (_it != _data.end()) {
			if (p > _it->second.first) {
				_it->second.first = p;
				_it->second.second = lcidxs;
			}
		} else
			_data[_key] = make_pair(p, lcidxs);
		_fulldata[_key].push_back( make_pair(p,lcidxs) );
	}
	void best_lcs::insert(const vector< vector<int8> >& lcidxsval, const vector<double>& pval)
	{
		for (unsigned i = 0; i < lcidxsval.size() && i < pval.size(); ++i)
			insert(lcidxsval[i], pval[i]);
	}

	vector<uint32> xorv(const vector<uint32>& v1, const vector<uint32> v2)
	{
		vector<uint32> tmp(v1);
		for (unsigned i = 0; i < tmp.size() && i < v2.size(); ++i)
			tmp[i] ^= v2[i];
		return tmp;
	}
	bool iszero(const vector<uint32>& v)
	{
		for (unsigned i = 0; i < v.size(); ++i)
			if (v[i]) return false;
		return true;
	}

} // namespace hash
