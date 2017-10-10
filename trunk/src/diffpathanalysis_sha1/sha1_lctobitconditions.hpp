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

#ifndef SHA1_LCTOBITCONDITIONS_HPP
#define SHA1_LCTOBITCONDITIONS_HPP

#include <vector>
#include <utility>
#include <hashutil5/sdr.hpp>
#include <hashutil5/sha1detail.hpp>
#include <hashutil5/sha1differentialpath.hpp>
#include "path_prob_analysis.hpp"
#include "sha1_localcollision.hpp"

namespace hash {

	void determine_bitconditions(cuda_device& cd, const localcollision_combiner& lccombiner, sha1differentialpath& path, unsigned tbegin, unsigned tend, bool verbose = true);

} // namespace hash

#endif // SHA1_LCTOBITCONDITIONS_HPP