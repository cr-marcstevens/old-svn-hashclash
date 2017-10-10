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

#ifndef PATH_PROB_ANALYSIS_HPP
#define PATH_PROB_ANALYSIS_HPP

#include <vector>

/**************************
 helper function that must be declared outside
 **************************/
void boost_thread_yield(); 

namespace hash {

#define MAXSAMPLESIZE (1<<23)
#define MAXTHREADS 262144
#define BLOCKSPERCORE 1
#define THREADSPERBLOCK 512

// NOTE THAT MAXBLOCKS = MAXTHREADS/THREADSPERBLOCK = 262144/512 = 512 AND THAT MAXSAMPLESIZE*(MAXBLOCKS-1) = 2^23 * (2^9 - 1) = 2^32 - 2^23 < 2^32 SO NO MULTIPLICATION OVERFLOW


	struct samples_type {
		uint32 bound[MAXTHREADS];
		uint32 qtm4[MAXSAMPLESIZE], qtm4b[MAXSAMPLESIZE];
		uint32 qtm3[MAXSAMPLESIZE], qtm3b[MAXSAMPLESIZE];
		uint32 qtm2[MAXSAMPLESIZE], qtm2b[MAXSAMPLESIZE];
		uint32 qtm1[MAXSAMPLESIZE], qtm1b[MAXSAMPLESIZE];
		uint32 qt[MAXSAMPLESIZE], qtb[MAXSAMPLESIZE];
//		int nrthreads;
		int nrblocks;
		unsigned SAMPLESIZE;
//		int padding[16-2];

		class const_iterator {
		public:
			const_iterator(): data(0) {}
			const_iterator(const const_iterator& r)
				: data(r.data), nrblocks(r.nrblocks), curblock(r.curblock), curidx(r.curidx)
			{}
			const_iterator(const samples_type& s, unsigned block, unsigned idx)
				: data(&s), nrblocks(s.nrblocks), curblock(block), curidx(idx)
			{}

			bool operator==(const const_iterator& r) const {
				if (data != r.data || nrblocks != r.nrblocks) return false;
				if (curblock >= nrblocks && r.curblock >= nrblocks) return true;
				return curblock == r.curblock && curidx == r.curidx;
			}
			bool operator!=(const const_iterator& r) const {
				return !(*this == r);
			}
			const_iterator& operator++() {
				if (data) {
					++curidx;
					while (curblock < nrblocks && curidx >= data->bound[curblock]) {
						++curblock;
						curidx = (curblock * data->SAMPLESIZE) / nrblocks;
					}
				}
				return *this;
			}
			const uint32& qtm4() { return data->qtm4[curidx]; }
			const uint32& qtm3() { return data->qtm3[curidx]; }
			const uint32& qtm2() { return data->qtm2[curidx]; }
			const uint32& qtm1() { return data->qtm1[curidx]; }
			const uint32& qt() { return data->qt[curidx]; }
			const uint32& qtm4b() { return data->qtm4b[curidx]; }
			const uint32& qtm3b() { return data->qtm3b[curidx]; }
			const uint32& qtm2b() { return data->qtm2b[curidx]; }
			const uint32& qtm1b() { return data->qtm1b[curidx]; }
			const uint32& qtb() { return data->qtb[curidx]; }
//		private:
			const samples_type* data;
			unsigned nrblocks;
			unsigned curblock;
			unsigned curidx;
		};
		const_iterator begin() {
			unsigned curblock = 0;
			unsigned curidx = 0;
			while (curblock < nrblocks && curidx >= bound[curblock]) {
				++curblock;
				curidx = (curblock * SAMPLESIZE)/nrblocks;
			}
			return const_iterator(*this, curblock, curidx);
		}
		const_iterator end() {
			return const_iterator(*this, nrblocks, SAMPLESIZE);
		}
	};

	class cuda_device_detail;
	class cuda_device {
	public:
		cuda_device(unsigned SAMPLESIZE, unsigned LOOPSIZE);

		bool init(const uint32 dme[80], const uint32 dqt[85], const uint32* _dft = 0, const uint32* _qtmask = 0, const uint32* _qtset = 0, const uint32* _qtprev = 0, const uint32* _qtprev2 = 0, const uint32* _dihv = 0);

		double path_analysis(unsigned tbegin, unsigned tend, bool usebitcond = false, bool verbose = false, bool usedihv = false);
		double init_samples(unsigned t, bool checkft, bool checkftp1, bool usebitcond = false);
		double run_step(unsigned t, bool checkqtp1, bool checkftp2, bool outuse1, bool usebitcond = false, bool usedihv = false);

		void init_samples_fast(unsigned t, bool checkft, bool checkftp1, bool usebitcond = false);
		void run_step_fast(unsigned t, bool checkqtp1, bool checkftp2, bool outuse1, bool usebitcond = false, bool usedihv = false);
		double get_prob(unsigned tbegin, unsigned tend);

		void gather_samples(samples_type& samples, bool use1);

		void test_optimal_constants(unsigned tbegin, unsigned tend, bool usebitcond = false);
	private:
		
		void set_consts();
	};
	extern cuda_device_detail* detail;
	extern samples_type mysamples;

}

#endif // PATH_PROB_ANALYSIS_HPP
