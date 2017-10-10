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

#include <hashutil5/saveload_bz2.hpp>
#include <hashutil5/saveload_gz.hpp>
#include <iostream>
#include <fstream>
#include <utility>
#include <boost/cstdint.hpp>
#include <boost/lexical_cast.hpp>
#include <hashutil5/md5detail.hpp>
#include <hashutil5/rng.hpp>
#include <hashutil5/differentialpath.hpp>
#include <hashutil5/booleanfunction.hpp>
#include "project_data.hpp"
#include "startnearcollision.hpp"

using namespace std;
using namespace hashutil;

unsigned load_block(std::istream& i, uint32 block[])
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
				i.setstate(std::ios::failbit);
				return len;
			}
		}
	return len;
}

void save_block(std::ostream& o, uint32 block[])
{
	for (unsigned k = 0; k < 16; ++k)
		for (unsigned c = 0; c < 4; ++c)
			o << (unsigned char)((block[k]>>(c*8))&0xFF);
}

#define HASHUTIL5_MD5COMPRESS_STEP(f, a, b, c, d, m, ac, rc) \
        a += f(b, c, d) + m + ac; a = rotate_left(a,rc); a += b;

double testnearcollprob(uint32 dm11, uint32 diffcd, uint32 diffb) {
        uint32 count = 0;
        for (unsigned k = 0; k < (1<<18); ++k)
        {
                uint32 a = xrng64(), b = xrng64()+xrng64()*11, c = xrng64(), d = xrng64()+xrng64()*11;
                uint32 a2 = a, b2 = b, c2 = c, d2 = d;
                uint32 m11 = xrng64(), m2 = xrng64(), m9 = xrng64();
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d, a, b, c, m11, 0xbd3af235, 10);
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c, d, a, b, m2, 0x2ad7d2bb, 15);
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, b, c, d, a, m9, 0xeb86d391, 21);
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d2, a2, b2, c2, m11+dm11, 0xbd3af235, 10);
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c2, d2, a2, b2, m2, 0x2ad7d2bb, 15);
                HASHUTIL5_MD5COMPRESS_STEP(md5_ii, b2, c2, d2, a2, m9, 0xeb86d391, 21);
                if (d2-d==diffcd && c2-c==diffcd && b2-b==diffb)
                        ++count;
        }
        return double(count)/double(1<<18);
}

void constructupperpath(differentialpath& path, uint32 dm11, uint32 diffcd, uint32 diffb)
{
	path.clear();
	differentialpath tmp;
	for (unsigned kk = 0; kk < (1<<20); ++kk) {
		uint32 a,b,c,d,a2,b2,c2,d2,oa,ob,oc,od,m11,m2,m9;
		while (true) {
					a = xrng64(); b = xrng64()+xrng64()*11; c = xrng64(); d = xrng64()+xrng64()*11;
					a2 = a; b2 = b; c2 = c; d2 = d;
					oa = a; ob = b; oc = c; od = d;
					m11 = xrng64(); m2 = xrng64(); m9 = xrng64();
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d, a, b, c, m11, 0xbd3af235, 10);
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c, d, a, b, m2, 0x2ad7d2bb, 15);
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, b, c, d, a, m9, 0xeb86d391, 21);
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d2, a2, b2, c2, m11+dm11, 0xbd3af235, 10);
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c2, d2, a2, b2, m2, 0x2ad7d2bb, 15);
					HASHUTIL5_MD5COMPRESS_STEP(md5_ii, b2, c2, d2, a2, m9, 0xeb86d391, 21);
					if (d2-d==diffcd && c2-c==diffcd && b2-b==diffb)
                		break;
			}
		for (unsigned i = 58; i <= 64; ++i)
			tmp[i].clear();
		tmp[62] = sdr(d,d2);
		tmp[63] = sdr(c,c2);
		tmp[64] = naf(b2-b);

		a2 = oa; b2 = ob; c2 = oc; d2 = od;
		a = oa; b = ob; c = oc; d = od;
		HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d, a, b, c, m11, 0xbd3af235, 10);
		HASHUTIL5_MD5COMPRESS_STEP(md5_ii, d2, a2, b2, c2, m11+dm11, 0xbd3af235, 10);
		sdr dF62 = sdr(md5_ii(d,a,b),md5_ii(d2,a2,b2));
		HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c, d, a, b, m2, 0x2ad7d2bb, 15);
		HASHUTIL5_MD5COMPRESS_STEP(md5_ii, c2, d2, a2, b2, m2, 0x2ad7d2bb, 15);
		sdr dF63 = sdr(md5_ii(c,d,a),md5_ii(c2,d2,a2));

		for (unsigned b = 0; b < 32; ++b) {
			bitcondition f62 = bc_constant, f63 = bc_constant;
			if (dF62.get(b) == +1) f62 = bc_plus;
			if (dF62.get(b) == -1) f62 = bc_minus;
			if (dF63.get(b) == +1) f63 = bc_plus;
			if (dF63.get(b) == -1) f63 = bc_minus;
			bf_conditions bc1 = MD5_I_data.forwardconditions(tmp[62][b], bc_constant, bc_constant, f62);
			bf_conditions bc2 = MD5_I_data.forwardconditions(tmp[63][b], bc1.first, bc1.second, f63);
			tmp.setbitcondition(60, b, bc1.third);
			tmp.setbitcondition(61, b, bc2.third);
			tmp.setbitcondition(62, b, bc2.second);
			tmp.setbitcondition(63, b, bc2.first);
		}
		if (path.path.size() == 0 || tmp.nrcond() < path.nrcond())
			path = tmp;
		// if we probably found the optimal upperpath then we can stop
		if (2*kk > path.nrcond())
			break;
	}
}

bool copyappendnearcollision(boost::filesystem::path in, boost::filesystem::path nc, boost::filesystem::path out) {
	cout << in << " + " << nc << " => " << out << "..." << flush;
	ofstream of(out.string().c_str(), ios::binary);
	if (!of) {
		cerr << "copyappendnearcollision(): Error: cannot open outputfile '" << out << "'!" << endl;
		return false;
	}
	ifstream if1(in.string().c_str(), ios::binary);
	if (!if1) {
		cerr << "copyappendnearcollision(): Error: cannot open inputfile 1 '" << in << "'!" << endl;
		return false;
	}
	ifstream if2(nc.string().c_str(), ios::binary);
	if (!if2) {
		cerr << "copyappendnearcollision(): Error: cannot open inputfile 2 '" << nc << "'!" << endl;
		return false;
	}
	uint32 msg1[16];
	unsigned blocks = 0;
	while (load_block(if1, msg1) > 0) {
		++blocks;
		save_block(of, msg1);
	}
	while (load_block(if2, msg1) > 0) {
		++blocks;
		save_block(of, msg1);
	}
	cout << "done. (" << blocks << " blocks)" << endl;
	return true;
}
bool startnearcollision(unsigned index, boost::filesystem::path collfile1, boost::filesystem::path collfile2)
{
	if (!current_project_data) return false;
	if (index == 0) return startnearcollision(index);
	boost::filesystem::path prefile1 = current_project_data->workdir / ("file1_" + boost::lexical_cast<string>(index-1) + ".bin");
	boost::filesystem::path prefile2 = current_project_data->workdir / ("file2_" + boost::lexical_cast<string>(index-1) + ".bin");
	boost::filesystem::path file1 = current_project_data->workdir / ("file1_" + boost::lexical_cast<string>(index) + ".bin");
	boost::filesystem::path file2 = current_project_data->workdir / ("file2_" + boost::lexical_cast<string>(index) + ".bin");

	if (!copyappendnearcollision(prefile1, collfile1, file1)) return false;
	if (!copyappendnearcollision(prefile2, collfile2, file2)) return false;
	return startnearcollision(index);
}

bool startnearcollision(unsigned index) 
{
	if (!current_project_data) return false;
	boost::filesystem::path file1 = current_project_data->workdir / ("file1_" + boost::lexical_cast<string>(index) + ".bin");
	boost::filesystem::path file2 = current_project_data->workdir / ("file2_" + boost::lexical_cast<string>(index) + ".bin");
	boost::filesystem::path ncdir = current_project_data->workdir / ("work_nc" + boost::lexical_cast<string>(index));
	//try { boost::filesystem::remove_all(ncdir); } catch (...) {}
	try { boost::filesystem::create_directory(ncdir); } catch (...) {}
	cout << file1 << endl;
	cout << file2 << endl;
	cout << ncdir << endl;
	uint32 ihv1[4];
	uint32 ihv2[4];
	uint32 msg1[16];
	uint32 msg2[16];
	{
		ifstream if1(file1.string().c_str(), ios::binary);
		if (!if1) {
			cerr << "startnearcollision(): Error: cannot open inputfile 1 '" << file1 << "'!" << endl;
			return false;
		}
		ifstream if2(file2.string().c_str(), ios::binary);
		if (!if2) {
			cerr << "startnearcollision(): Error: cannot open inputfile 2 '" << file2 << "'!" << endl;
			return false;
		}
		
		for (unsigned k = 0; k < 4; ++k)
			ihv1[k] = ihv2[k] = md5_iv[k];

		// load, md5 and save inputfile1
		unsigned file1blocks = 0;
		while (load_block(if1, msg1) > 0) {
			md5compress(ihv1, msg1);
			++file1blocks;
		}
		// load, md5 and save inputfile2
		unsigned file2blocks = 0;
		while (load_block(if2, msg2) > 0) {
			md5compress(ihv2, msg2);			
			++file2blocks;
		}
		if (file1blocks != file2blocks) {
			cerr << "startnearcollision(): Error: inputfile 1 and 2 are not of equal size" << endl;
			return false;
		}
	}

	cout << "IHV1   = {" << ihv1[0] << "," << ihv1[1] << "," << ihv1[2] << "," << ihv1[3] << "}" << endl;
	cout << "IHV1   = " << hex;
	for (unsigned k = 0; k < 4; ++k)
		for (unsigned c = 0; c < 4; ++c)
		{
			cout.width(2); cout.fill('0');
			cout << ((ihv1[k]>>(c*8))&0xFF);
		}
	cout << dec << endl << endl;

	cout << "IHV2   = {" << ihv2[0] << "," << ihv2[1] << "," << ihv2[2] << "," << ihv2[3] << "}" << endl;
	cout << "IHV2   = " << hex;
	for (unsigned k = 0; k < 4; ++k)
		for (unsigned c = 0; c < 4; ++c)
		{
			cout.width(2); cout.fill('0');
			cout << ((ihv2[k]>>(c*8))&0xFF);
		}
	cout << dec << endl << endl;

	uint32 dihv[4] = { ihv2[0] - ihv1[0], ihv2[1] - ihv1[1], ihv2[2] - ihv1[2], ihv2[3] - ihv1[3] };
	cout << "dIHV   = {" << dihv[0] << "," << dihv[1] << "," << dihv[2] << "," << dihv[3] << "}" << endl;

	if (dihv[0]==0 && dihv[1]==0 && dihv[2]==0 && dihv[3]==0)
	{
		cerr << "startnearcollision(): dIHV is zero!" << endl;
		return false;
	}
	if (dihv[0] != 0 || dihv[2] != dihv[3])
	{
		cerr << "startnearcollision(): Error: dIHV is not of the required form dIHV[0]=0, dIHV[2]=dIHV[3]" << endl;
		return false;
	}

	sdr diffcd = naf(0-dihv[3]);
	sdr diffb  = naf(dihv[3] - dihv[1]);
	vector< pair<uint32,uint32> > ncdiff;
	unsigned bb = 0;
	while (bb < 32) {
		if (diffcd.get(bb) != 0) {
			unsigned bend=bb+1;
			while (bend < 32 && bend<=bb+current_project_data->birthdaysearch_config.path_type_range && diffcd.get(bend)==0)
				++bend;
			uint32 diff1 = 1<<bb;
			if (diffcd.get(bb) == -1)
				diff1 = -(1<<bb);
			uint32 diff2 = diff1;
			for (unsigned b2 = bb; b2 < bend; ++b2)
				if (diffb.get((b2+21)%32) == +1)
					diff2 += 1<<((b2+21)%32);
				else if (diffb.get((b2+21)%32) == -1)
					diff2 -= 1<<((b2+21)%32);
			ncdiff.push_back( pair<uint32,uint32>(diff1,diff2) );
			bb = bend;
		} else if (diffb.get((bb+21)%32) != 0) {
			uint32 diff1 = 0, diff2 = 0;
			unsigned bend=bb+1;
			unsigned tempinc=0;
			if (bb+1 < 32 && diffcd.get(bb+1) != 0) {
				if (diffcd.get(bb+1) == +1)
					diff1 += 1<<bb;
				else
					diff1 -= 1<<bb;
				ncdiff.push_back( pair<uint32,uint32>(diff1,diff1) );
				bend=bb+2;
				tempinc=1;				
			} else {
				diff1 = 1<<bb;
				if (diffb.get((bb+21)%32) == +1)
					diff1 = 0-(1<<bb);
				ncdiff.push_back( pair<uint32,uint32>(0-diff1,0-diff1) );
			}
			diff2 = diff1;
			while (bend < 32 && bend<=bb+current_project_data->birthdaysearch_config.path_type_range+tempinc && diffcd.get(bend)==0)
				++bend;
			for (unsigned b2 = bb; b2 < bend; ++b2)
				if (diffb.get((b2+21)%32) == +1)
					diff2 += 1<<((b2+21)%32);
				else if (diffb.get((b2+21)%32) == -1)
					diff2 -= 1<<((b2+21)%32);
			ncdiff.push_back( pair<uint32,uint32>(diff1,diff2) );
			bb = bend;
		} else ++bb;
	}
	if (ncdiff.size()> 1 && 0!=naf(ncdiff[ncdiff.size()-1].first).get(31) && 0!=(ncdiff[0].first&1)) {
		ncdiff[0].first += ncdiff[ncdiff.size()-1].first;
		ncdiff[0].second += ncdiff[ncdiff.size()-1].second;
		ncdiff.pop_back();
	}
	uint32 temp1 = 0, temp2 = 0;
	for (unsigned i = 0; i < ncdiff.size(); ++i)
	{
		cout << "NC" << i << ": delta c = delta d = " << naf(ncdiff[i].first) << endl;
		cout << "NC" << i << ": delta b           = " << naf(ncdiff[i].second) << endl;
		temp1 += ncdiff[i].first;
		temp2 += ncdiff[i].second;
	}
	if (dihv[3] != uint32(0-temp1) || dihv[1] != uint32(0-temp2)) {
		cerr << "startnearcollision(): Internal error in determining near-collision blocks:" << endl;
		cerr << dihv[3] << "=?" << uint32(0-temp1) << endl;
		cerr << dihv[1] << "=?" << uint32(0-temp2) << endl;
		return false;
	}
	vector<uint32> dm11(ncdiff.size(),0);
	vector<double> prob(ncdiff.size(),0);
	for (unsigned i = 0; i < ncdiff.size(); ++i)
	{
		sdr fnaf = naf(ncdiff[i].first);
		for (unsigned b = 0; b < 32; ++b)
			if (fnaf.get(b) == +1) {
				dm11[i] = uint32(1)<<((b-10)%32);
				break;
			} else if (fnaf.get(b) == -1) {
				dm11[i] = 0-(uint32(1)<<((b-10)%32));
				break;
			}
		if (fnaf.get(0) != 0 && fnaf.get(31) != 0) {
			if (fnaf.get(0) == +1)
				dm11[i] = uint32(1)<<21;
			else
				dm11[i] = 0-(uint32(1)<<21);
		}
		prob[i] = testnearcollprob(dm11[i], ncdiff[i].first, ncdiff[i].second);
		cout << "NC" << i << ": prob=" << log(prob[i])/log(double(2)) << endl;
	}

	/* select NC with highest probability */
	unsigned j = 0;
	for (unsigned i = 0; i < ncdiff.size(); ++i)
		if (prob[i] > prob[j]) j = i;
	current_project_data->delta_m11.resize(index+1);
	current_project_data->delta_m11[index] = dm11[j];
	current_project_data->intermediate_collfiles.resize(index+1);
	current_project_data->intermediate_collfiles[index].first = file1;
	current_project_data->intermediate_collfiles[index].second = file2;
	cout << "NC" << j << ": prob=" << log(prob[j])/log(2.0) << endl;
	unsigned b = 0;
	int m11sign = +1;
	for (bb = 0; bb < 32; ++bb)
		if (naf(dm11[j]).get(bb) != 0) {
			b = bb;
			if (naf(dm11[j]).get(bb) == -1) 
				m11sign = -1;
			break;
		}

	cout << "delta m_11 = " << naf(dm11[j]) << endl;
	uint32 m_diff[16] = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 };
	m_diff[11] = dm11[j];

	/*** Construct lower diff. path ***/
	differentialpath lowerpath;
	uint32 Q1[4] = { ihv1[0], ihv1[3], ihv1[2], ihv1[1] };
	uint32 Q2[4] = { ihv2[0], ihv2[3], ihv2[2], ihv2[1] };
	for (int i = 0; i < 4; ++i)
		for (unsigned k = 0; k < 32; ++k)
		{
			if ((Q1[i]>>k)&1) {
				if ((Q2[i]>>k)&1)
					lowerpath.setbitcondition(i-3,k,bc_one);
				else
					lowerpath.setbitcondition(i-3,k,bc_minus);
			} else {
				if ((Q2[i]>>k)&1)
					lowerpath.setbitcondition(i-3,k,bc_plus);
				else
					lowerpath.setbitcondition(i-3,k,bc_zero);
			}
		}
	uint32 dF = 0;
	for (unsigned k = 0; k < 32; ++k)
	{
		bf_outcome outcome = MD5_F_data.outcome(lowerpath(0,k), lowerpath(-1,k), lowerpath(-2,k));
		if (outcome.size()) {
			if (outcome[0] == bc_plus) 			dF += 1<<k;
			else if (outcome[0] == bc_minus)	dF -= 1<<k;
		}
	}
	uint32 dQtm3 = lowerpath[-3].diff();
	uint32 dT = dQtm3 + dF;
	std::vector<std::pair<uint32,double> > rotateddiff;
	rotate_difference(dT, md5_rc[0], rotateddiff);
	double bestrot = 0;
	differentialpath lowerpathtmp = lowerpath;
	// do not simply pick the simplest (and usually most probable) rotation as Q_0 is completely fixed
	// pick the dQ_1 with the actual highest probability
	for (unsigned i = 0; i < rotateddiff.size(); ++i)
	{
		lowerpathtmp[1] = naf(lowerpath[0].diff() + rotateddiff[i].first);
		double rotprob = test_path(lowerpathtmp, m_diff);
		if (rotprob > bestrot)
			lowerpath = lowerpathtmp;
	}

	/*** Show and store lower diff. path ***/
	show_path(lowerpath, m_diff);
	try {
		vector<differentialpath> temp;
		temp.push_back(lowerpath);
		boost::filesystem::path file = ncdir / "lowerpath";
		save_gz(temp, file.string(), text_archive);
		cout << "Saved lower diff. path to '" << (ncdir / "lowerpath.txt.gz").string() << "'." << endl;
	} catch (std::exception& e) {
		cerr << "Error: could not write '" << (ncdir / "lowerpath.txt.gz").string() << "':" << endl;
		cerr << e.what() << endl;
		return false;
	} catch (...) {
		cerr << "Error: could not write '" << (ncdir / "lowerpath.txt.gz").string() << "'." << endl;
		return false;
	}
	cout << endl;
	
	/*** Construct upper diff. path ***/
	differentialpath upperpath;
	constructupperpath(upperpath, dm11[j], ncdiff[j].first, ncdiff[j].second);
	upperpath.get(32);

	/*** Show and store upper diff. path ***/
	show_path(upperpath, m_diff);
	try {
		vector<differentialpath> temp;
		temp.push_back(upperpath);
		boost::filesystem::path file = ncdir / "upperpath";
		save_gz(temp, file.string(), text_archive);
		cout << "Saved upper diff. path to '" << (ncdir / "upperpath.txt.gz").string() << "'." << endl;
	} catch (std::exception& e) {
		cerr << "Error: could not write '" << (ncdir / "upperpath.txt.gz").string() << "':" << endl;
		cerr << e.what() << endl;
		return false;
	} catch (...) {
		cerr << "Error: could not write '" << (ncdir / "upperpath.txt.gz").string() << "'." << endl;
		return false;
	}
	try {
		current_project_data->save_config();
	} catch (...) {}
	return true;
}
