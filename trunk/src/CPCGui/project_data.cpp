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
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/utility.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/filesystem/fstream.hpp>

#include "project_data.hpp"

project_data default_project_data;
project_data* current_project_data = 0;

BOOST_CLASS_VERSION(birthdaysearch_config_type, 1);
BOOST_CLASS_VERSION(diffpathforward_config_type, 1);
BOOST_CLASS_VERSION(diffpathbackward_config_type, 1);
BOOST_CLASS_VERSION(diffpathconnect_config_type, 2);
BOOST_CLASS_VERSION(project_data, 2);

namespace boost {
	namespace serialization {

		template<class Archive>
		void serialize(Archive& ar, birthdaysearch_config_type& c, const unsigned int version)
		{
			ar & make_nvp("cell_nr_spu_threads", c.cell_nr_spu_threads);
			ar & make_nvp("hybridbits", c.hybridbits);
			ar & make_nvp("log_traillength", c.log_traillength);
			ar & make_nvp("max_blocks", c.max_blocks);
			ar & make_nvp("max_memory", c.max_memory);
			ar & make_nvp("mem_hardlimit", c.mem_hardlimit);
			ar & make_nvp("path_type_range", c.path_type_range);
			ar & make_nvp("use_cell", c.use_cell);
			ar & make_nvp("use_cuda", c.use_cuda);
			if (version >= 2) { /* future parameters */ }
		}

		template<class Archive>
		void serialize(Archive& ar, diffpathforward_config_type& c, const unsigned int version)
		{
			ar & make_nvp("ab_estimate_factor", c.ab_estimate_factor);
			ar & make_nvp("ab_naf_estimate", c.ab_naf_estimate);
			ar & make_nvp("ab_nr_diffpaths", c.ab_nr_diffpaths);
			ar & make_nvp("cond_tbegin", c.cond_tbegin);
			ar & make_nvp("fill_fraction", c.fill_fraction);
			ar & make_nvp("half_naf_weight", c.half_naf_weight);
			ar & make_nvp("include_naf", c.include_naf);
			ar & make_nvp("max_conditions", c.max_conditions);
			ar & make_nvp("max_sdr_weight", c.max_sdr_weight);
			ar & make_nvp("max_sdrs", c.max_sdrs);
			ar & make_nvp("min_Q314_tunnel", c.min_Q314_tunnel);
			ar & make_nvp("min_Q456_tunnel", c.min_Q456_tunnel);
			ar & make_nvp("min_Q91011_tunnel", c.min_Q91011_tunnel);
			ar & make_nvp("min_sdr_weight", c.min_sdr_weight);
			ar & make_nvp("no_verify", c.no_verify);
			ar & make_nvp("normalt01", c.normalt01);
			ar & make_nvp("t_range", c.t_range);
			ar & make_nvp("t_step", c.t_step);
			if (version >= 2) { /* future parameters */ }
		}

		template<class Archive>
		void serialize(Archive& ar, diffpathbackward_config_type& c, const unsigned int version)
		{
			ar & make_nvp("ab_estimate_factor", c.ab_estimate_factor);
			ar & make_nvp("ab_naf_estimate", c.ab_naf_estimate);
			ar & make_nvp("ab_nr_diffpaths", c.ab_nr_diffpaths);
			ar & make_nvp("cond_tend", c.cond_tend);
			ar & make_nvp("fill_fraction", c.fill_fraction);
			ar & make_nvp("half_naf_weight", c.half_naf_weight);
			ar & make_nvp("include_naf", c.include_naf);
			ar & make_nvp("max_conditions", c.max_conditions);
			ar & make_nvp("max_Q26up_cond", c.max_Q26up_cond);
			ar & make_nvp("max_sdr_weight", c.max_sdr_weight);
			ar & make_nvp("max_sdrs", c.max_sdrs);
			ar & make_nvp("min_sdr_weight", c.min_sdr_weight);
			ar & make_nvp("no_verify", c.no_verify);
			ar & make_nvp("t_range", c.t_range);
			ar & make_nvp("t_step", c.t_step);
			if (version >= 2) { /* future parameters */ }
		}

		template<class Archive>
		void serialize(Archive& ar, diffpathconnect_config_type& c, const unsigned int version)
		{			
			ar & make_nvp("max_complexity", c.max_complexity);
			ar & make_nvp("no_enhance_path", c.no_enhance_path);
			ar & make_nvp("no_verify", c.no_verify);
			ar & make_nvp("Qcond_start", c.Qcond_start);
			ar & make_nvp("show_statistics", c.show_statistics);
			ar & make_nvp("t_step", c.t_step);
			if (version >= 2) { 
				/* future parameters */ 
				ar & make_nvp("abortafterXmin", c.abortafterXmin);
			}
		}

		template<class Archive, class String, class Traits> 
		void serialize(Archive& ar, boost::filesystem::basic_path<String, Traits>& p, const unsigned int version) 
		{ 
			String s; 
			if (Archive::is_saving::value) 
				s = p.string(); 
			ar & boost::serialization::make_nvp("string", s); 
			if (Archive::is_loading::value) 
				p = s; 
		} 

	} // namespace serialization
} // namespace boost

template<class Archive>
void project_data::serialize(Archive& ar, const unsigned int version)
{			
	ar & boost::serialization::make_nvp("birthdaysearch_config", birthdaysearch_config);
	ar & boost::serialization::make_nvp("diffpathbackward_config", diffpathbackward_config);
	ar & boost::serialization::make_nvp("diffpathconnect_config", diffpathconnect_config);
	ar & boost::serialization::make_nvp("diffpathforward_config", diffpathforward_config);
	ar & boost::serialization::make_nvp("filename1", filename1);
	ar & boost::serialization::make_nvp("filename2", filename2);
	ar & boost::serialization::make_nvp("intermediate_collfiles", intermediate_collfiles);
	ar & boost::serialization::make_nvp("delta_m11", delta_m11);
	ar & boost::serialization::make_nvp("max_threads", max_threads);
	ar & boost::serialization::make_nvp("workdir", workdir);
	if (version >= 2) { 
		ar & boost::serialization::make_nvp("mode_automatic", mode_automatic);
		/* future parameters */ 
	}
}

void project_data::init_load_config(const project_data::path_type& existing_workdir)
{
	std::cout << path_type(existing_workdir / "project.config").string() << std::endl;
	std::ifstream ifs(path_type(existing_workdir / "project.config").string().c_str());
	if (!ifs) throw std::runtime_error("project_data::init_load_config(): could not open file!");
	boost::archive::xml_iarchive ia(ifs);
	ia >> boost::serialization::make_nvp("project_config", *this);
	if (!ifs) throw std::runtime_error("project_data::init_load_config(): read error!");
	if (!boost::filesystem::equivalent(existing_workdir,workdir)) {
		std::cout << "Work directory changed:" << std::endl
			<< "Old dir: " << workdir << std::endl
 			<< "New dir: " << existing_workdir << std::endl;
		throw std::runtime_error("project_data::init_load_config(): work directory changed ?!?");
	}
}
void project_data::init_load_default_config()
{
	std::ifstream ifs(path_type("cpcgui_default_config.xml").string().c_str());
	if (!ifs) throw std::runtime_error("project_data::init_load_default_config(): could not open file!");
	boost::archive::xml_iarchive ia(ifs);
	ia >> boost::serialization::make_nvp("project_config", *this);
	if (!ifs) throw std::runtime_error("project_data::init_load_default_config(): read error!");
}

void project_data::save_config() const
{
	std::ofstream ofs(path_type(workdir / "project.config").string().c_str());
	if (!ofs) throw std::runtime_error("project_data::save_config(): could not open file!");
	boost::archive::xml_oarchive oa(ofs);
	oa << boost::serialization::make_nvp("project_config", *this);
	if (!ofs) throw std::runtime_error("project_data::save_config(): write error!");
}

void project_data::save_default_config() const
{
	std::ofstream ofs(path_type("cpcgui_default_config.xml").string().c_str());
	if (!ofs) throw std::runtime_error("project_data::save_default_config(): could not open file!");
	boost::archive::xml_oarchive oa(ofs);
	oa << boost::serialization::make_nvp("project_config", *this);
	if (!ofs) throw std::runtime_error("project_data::save_default_config(): write error!");
}
