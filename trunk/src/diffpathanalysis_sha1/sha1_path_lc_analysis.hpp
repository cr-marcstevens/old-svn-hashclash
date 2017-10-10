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

#ifndef SHA1_PATH_LC_ANALYSIS_HPP
#define SHA1_PATH_LC_ANALYSIS_HPP

#include <vector>
#include <utility>
#include <hashutil5/sha1detail.hpp>
#include <hashutil5/sdr.hpp>
#include "sha1_localcollision.hpp"
#include "path_prob_analysis.hpp"

namespace hash {

	void expand_lcs(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend,
					const std::vector<int8>& in, std::vector< std::vector<int8> >& out, std::vector<double>& outprob, bool verbose = true);

	void optimize_lcs(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend, unsigned windowsize = 6);

	void retrieve_optimal_lcss(cuda_device& cd, localcollision_combiner& lccombiner, unsigned tbegin, unsigned tend, std::vector< std::vector<int8> >& out, double pmarge = 0.9, unsigned windowsize = 6);

} // namespace hash

#ifndef NOSERIALIZATION
namespace boost {
	namespace serialization {

	}
}

#endif // NOSERIALIZATION

#endif // SHA1_PATH_LC_ANALYSIS_HPP
