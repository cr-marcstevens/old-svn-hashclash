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

#ifndef PROJECT_DATA_HEADER
#define PROJECT_DATA_HEADER

#include <boost/cstdint.hpp>
#include <boost/filesystem.hpp>
#include <string>
#include <utility>
#include <vector>

struct birthdaysearch_config_type {
	birthdaysearch_config_type()
		: hybridbits(0), path_type_range(2), max_blocks(9), max_memory(100), cell_nr_spu_threads(6)
		, log_traillength(-1)
		, mem_hardlimit(false), use_cuda(true), use_cell(true)
	{}
	unsigned hybridbits, path_type_range, max_blocks, max_memory, cell_nr_spu_threads;
	int log_traillength;
	bool mem_hardlimit, use_cuda, use_cell;
};

struct diffpathforward_config_type {
	diffpathforward_config_type()
		: t_step(0), t_range(0), max_conditions(9999), min_sdr_weight(0), max_sdr_weight(32), max_sdrs(2000), ab_nr_diffpaths(0), ab_naf_estimate(8), min_Q456_tunnel(0), min_Q91011_tunnel(0), min_Q314_tunnel(0)
		, cond_tbegin(1), fill_fraction(1), ab_estimate_factor(2), include_naf(false), half_naf_weight(true), no_verify(false), normalt01(true)
	{}
	unsigned t_step, t_range, max_conditions, min_sdr_weight, max_sdr_weight, max_sdrs, ab_nr_diffpaths, ab_naf_estimate, min_Q456_tunnel, min_Q91011_tunnel, min_Q314_tunnel;
	int cond_tbegin;
	double fill_fraction, ab_estimate_factor;
	bool include_naf, half_naf_weight, no_verify, normalt01;
};

struct diffpathbackward_config_type {
	diffpathbackward_config_type()
		: t_step(79), t_range(0), max_conditions(9999), min_sdr_weight(0), max_sdr_weight(32), max_sdrs(2000), ab_nr_diffpaths(0), ab_naf_estimate(8), max_Q26up_cond(0)
		, cond_tend(64), fill_fraction(1), ab_estimate_factor(2), include_naf(false), half_naf_weight(true), no_verify(false)
	{}
	unsigned t_step, t_range, max_conditions, min_sdr_weight, max_sdr_weight, max_sdrs, ab_nr_diffpaths, ab_naf_estimate, max_Q26up_cond;
	int cond_tend;
	double fill_fraction, ab_estimate_factor;
	bool include_naf, half_naf_weight, no_verify;
};

struct diffpathconnect_config_type {
	diffpathconnect_config_type()
		: t_step(0), Qcond_start(18), max_complexity(-9999), no_verify(false), no_enhance_path(false), show_statistics(false), abortafterXmin(-1)
	{}
	unsigned t_step;
	int Qcond_start, max_complexity;
	bool no_verify, no_enhance_path, show_statistics;
	int abortafterXmin;
};

//namespace boost { namespace serialization { class access; } }
class project_data {
public:
	typedef boost::filesystem::path path_type;
	project_data()
		: max_threads(1) 
		, mode_automatic(false)
	{}
	project_data(const project_data& copy_config)
		: max_threads(copy_config.max_threads)
		, mode_automatic(copy_config.mode_automatic)
		, birthdaysearch_config(copy_config.birthdaysearch_config)
		, diffpathforward_config(copy_config.diffpathforward_config)
		, diffpathbackward_config(copy_config.diffpathbackward_config)
		, diffpathconnect_config(copy_config.diffpathconnect_config)		
	{}

	void set_max_threads(unsigned nr_threads) { if (nr_threads > 0) max_threads = nr_threads; else max_threads = 1; }
	unsigned get_max_threads() const { return max_threads; }

	const path_type& get_filename1() const { return filename1; }
	const path_type& get_filename2() const { return filename2; }
	const path_type& get_workdir() const { return workdir; }
	
	void init_load_config(const path_type& existing_workdir);
	void init_load_default_config();
	void save_config() const;
	void save_default_config() const;
/* for save and load purposes */
	template<class Archive>
	void serialize(Archive& ar, const unsigned int version);

	unsigned max_threads;
	path_type filename1, filename2, workdir;
	std::vector< std::pair<path_type, path_type> > intermediate_collfiles;
	std::vector< boost::uint32_t > delta_m11;
	birthdaysearch_config_type birthdaysearch_config;
	std::vector< diffpathforward_config_type > diffpathforward_config;
	std::vector< diffpathbackward_config_type > diffpathbackward_config;
	diffpathconnect_config_type diffpathconnect_config;
	bool mode_automatic;
};

extern project_data default_project_data;
extern project_data* current_project_data;

#endif // PROJECT_DATA_HEADER
