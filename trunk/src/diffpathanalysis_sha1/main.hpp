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

#ifndef MAIN_HPP
#define MAIN_HPP

#include <iostream>
#include <vector>
#include <string>

#include <boost/filesystem/operations.hpp>

#include <hashutil5/sdr.hpp>
#include <hashutil5/saveload_bz2.hpp>
#include <hashutil5/sha1differentialpath.hpp>

#include "path_prob_analysis.hpp"

using namespace hashutil;
using namespace std;

extern std::string workdir;
extern unsigned global_windowsize;
extern double me_frac_range;
unsigned load_block(istream& i, uint32 block[]);
void save_block(ostream& o, uint32 block[]);

struct parameters_type {
	uint32 m_mask[80];
	string infile1, infile2, outfile1, outfile2;
	int cpuaffinity;
	unsigned split;
	vector<string> files;

	void show_mdiffs()
	{
	}
};

void round4_analysis(cuda_device& cd, const parameters_type& parameters);
//void round123_analysis(const parameters_type& parameters);

#endif // MAIN_HPP
