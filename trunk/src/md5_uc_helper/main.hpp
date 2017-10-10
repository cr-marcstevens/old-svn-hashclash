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
#include <boost/thread.hpp>

#include <hashutil5/sdr.hpp>
#include <hashutil5/saveload_gz.hpp>
#include <hashutil5/differentialpath.hpp>
#include <hashutil5/rng.hpp>

using namespace hashutil;
using namespace std;

struct parameters_type {
	uint32 m_diff[16];
	string infile1, infile2, outfile1, outfile2;
	vector<string> files;
	int t, tb, te;
	
	void show_mdiffs()
	{
		for (unsigned k = 0; k < 16; ++k)
			if (m_diff[k] != 0)
				cout << "delta_m[" << k << "] = " << naf(m_diff[k]) << endl;
	}
};

#endif // MAIN_HPP
