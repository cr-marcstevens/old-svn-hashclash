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

#ifndef SHA1_LOCALCOLLISION_HPP
#define SHA1_LOCALCOLLISION_HPP

#include <vector>
#include <utility>
#include <map>
#include <hashutil5/sha1detail.hpp>
#include <hashutil5/sdr.hpp>

namespace hash {

	class lc_to_me {
	public:
		// takes as input the message expansion with per local collision only the bit set where it starts: "disturbance vector mask"
		// generates full message expansion mask
		// per message word mask it generates all the possible 32-bit differences that arise from the possible binary signed digit representations having the given message word mask
		lc_to_me() {}
		lc_to_me(const uint32 lcme[80]) { set(lcme); }
		void set(const uint32 lcme[80]);

		inline bool checkme(unsigned t, uint32 met) {
				return binary_search(mesdrs[t].begin(), mesdrs[t].end(), met);
		}
		inline uint32 lcme(unsigned t) const { return _lcme[t]; }
		inline uint32 fullme(unsigned t) const { return _fullme[t]; }

		std::vector< std::vector<uint32> > mesdrs;
		std::vector< std::vector<sdr> > mesdrs2;

	private:
		void fill_sdrs(std::vector<uint32>& out, std::vector<sdr>& out2, uint32 maskin);

		uint32 _lcme[80];
		uint32 _fullme[80];		
	};


	struct localcollision {
		uint32 mdiff[6];
		uint32 mmask[6];
		double pcond[6];

		localcollision()
		{
			for (unsigned k = 0; k < 6; ++k) {
				mdiff[k] = 0;
				mmask[k] = 0;
				pcond[k] = 0;
			}
		}
		bool operator< (const localcollision& r) const
		{
			for (unsigned k = 0; k < 6; ++k) {
				if (this->mdiff[k] < r.mdiff[k]) return true;
				if (this->mdiff[k] > r.mdiff[k]) return false;
			}
			return false;
		}
		bool operator== (const localcollision& r) const
		{
			for (unsigned k = 0; k < 6; ++k)
				if (mdiff[k] != r.mdiff[k])
					return false;
			return true;
		}
		bool operator!= (const localcollision& r) const
		{ return !(*this == r); }
	};

	typedef std::vector< localcollision > localcollision_vector;
	typedef std::vector< std::vector< localcollision_vector > > localcollisionvec_matrix;
	typedef std::pair< std::vector<uint32>, std::vector<double> > localcollision_mask;


	void initialize_localcollision_matrix(localcollisionvec_matrix& lcmat);

	class localcollision_combiner {
	public:
		localcollision_combiner() {}
		localcollision_combiner(const uint32 me[80], const localcollisionvec_matrix& lcmat) { setlcme(me, lcmat); }
	
		// take disturbance vector mask, determine where localcollisions start and store all valid localcollisions (taken from lcmat) for each position (t,b)
		void setlcme(const uint32 lcme[80], const localcollisionvec_matrix& lcmat);
		// for each position (met[i],meb[i]) give the index of the chosen localcollision in the vector of valid localcollisions (melc[i])
		// index value of -1 (or out of range) signifies ignored
		// combine the selected localcollision to set dme, dft, dqt
		void set_lc_indices(const std::vector<int8>& lcidx);
		// check dme against lcme for specified interval tbegin <= i < tend  (whether the resulting dme can actually occur from the message expansion mask)
		// when ignoring localcollisions exclude their interval! otherwise it will return false
		bool checkdme(unsigned tbegin, unsigned tend);
		// checks dme against lcme for all t's except those t in range of ignored localcollisions
		bool checkdme(); 
		bool checkdme(const std::vector<int8>& lcidx);
		// returns the message bitdifferences conforming to the combination of local collisions for all t's out of range of ignored local collisions
		void get_me_sdr(std::vector<sdr>& mesdr);

		// variables set by setlcme		
		lc_to_me lcme;
		std::vector< unsigned > met, meb;
		std::vector< localcollision_vector > melc;
		// set by set_lc_indices
		std::vector< int8 > melcidx;
		uint32 dme[80];
		uint32 dft[80];
		uint32 dqt[85];
	};

	class best_lcs {
	public:
		typedef std::map< std::vector<int8>, std::pair< double, std::vector<int8> > > container_type;
		typedef std::map< std::vector<int8>, std::vector< std::pair< double, std::vector<int8> > > > container2_type;
		typedef std::map< std::vector<int8>, std::pair< double, std::vector<int8> > >::const_iterator const_iterator;
		typedef std::map< std::vector<int8>, std::vector< std::pair< double, std::vector<int8> > > >::const_iterator const_iterator_full;
		typedef std::map< std::vector<int8>, std::pair< double, std::vector<int8> > >::iterator iterator;
		typedef std::map< std::vector<int8>, std::vector< std::pair< double, std::vector<int8> > > >::iterator iterator_full;

		void set(const localcollision_combiner& lccombiner, unsigned twindowbegin, unsigned twindowend, bool verbose = true);
		std::vector<int8>& make_key(const std::vector<int8>& in) { _key.assign(in.begin() + _iwbegin, in.begin() + _iwend); return _key; }
		void insert(const std::vector<int8>& lcidxs, double p);
		void insert(const std::vector< std::vector<int8> >& lcidxsval, const std::vector<double>& pval);

		const_iterator begin() const { return _data.begin(); }
		const_iterator end() const { return _data.end(); }
		const_iterator find(const std::vector<int8>& key) const { return _data.find(key); }
		const_iterator_full begin_full() const { return _fulldata.begin(); }
		const_iterator_full end_full() const { return _fulldata.end(); }
		const_iterator_full find_full(const std::vector<int8>& key) const { return _fulldata.find(key); }
		iterator begin() { return _data.begin(); }
		iterator end() { return _data.end(); }
		iterator find(const std::vector<int8>& key) { return _data.find(key); }
		iterator_full begin_full() { return _fulldata.begin(); }
		iterator_full end_full() { return _fulldata.end(); }
		iterator_full find_full(const std::vector<int8>& key) { return _fulldata.find(key); }
		std::map< std::vector<int8>, std::pair< double, std::vector<int8> > >::size_type size() const { return _data.size(); }
		void erase(const std::vector<int8>& key) {
			iterator it = find(key);
			iterator_full it2 = find_full(key);
			if (it != _data.end())
				_data.erase(it);
			if (it2 != _fulldata.end())
				_fulldata.erase(it2);
		}

		void swap(best_lcs& r) {
			std::swap(_twbegin, r._twbegin);
			std::swap(_twend, r._twend);
			std::swap(_iwbegin, r._iwbegin);
			std::swap(_iwend, r._iwend);
			_data.swap(r._data);
			_fulldata.swap(r._fulldata);
		}

#ifndef NOSERIALIZATION
		template<class Archive>
		void serialize(Archive& ar, const unsigned int file_version)
		{
			ar & boost::serialization::make_nvp("twbegin", _twbegin);
			ar & boost::serialization::make_nvp("twend", _twend);
			ar & boost::serialization::make_nvp("iwbegin", _iwbegin);
			ar & boost::serialization::make_nvp("iwend", _iwend);
			ar & boost::serialization::make_nvp("_data", _data);
			ar & boost::serialization::make_nvp("_fulldata", _fulldata);
			ar & boost::serialization::make_nvp("_key", _key);
		}
#endif

		unsigned twbegin() const { return _twbegin; }
		unsigned twend() const { return _twend; }
		unsigned iwbegin() const { return _iwbegin; }
		unsigned iwend() const { return _iwend; }

	private:
		unsigned _twbegin, _twend;
		unsigned _iwbegin, _iwend;
		container_type _data;
		container_type::iterator _it, _ite;
		container2_type _fulldata;

		std::vector<int8> _key;
	};

} // namespace hash

#ifndef NOSERIALIZATION
namespace boost {
	namespace serialization {

		template<class Archive>
		void serialize(Archive& ar, hashutil::localcollision& lc, const unsigned int file_version)
		{
			for (unsigned k = 0; k < 6; ++k)
			{
				ar & make_nvp("diff", lc.mdiff[k]);
				ar & make_nvp("mask", lc.mmask[k]);
				ar & make_nvp("prob", lc.pcond[k]);
			}
		}

	}
}

#endif // NOSERIALIZATION

#endif // SHA1_LOCALCOLLISION_HPP