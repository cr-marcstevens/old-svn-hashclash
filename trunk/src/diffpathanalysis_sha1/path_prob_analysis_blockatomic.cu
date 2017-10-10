#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <cuda.h>

#include <iostream>
#include <vector>
#include <map>
#include <stdexcept>

//#include <cutil_inline.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_types.h> // contains the Error Codes
//#include <cutil.h>

#include <hashutil5/rng.hpp>
#include <hashutil5/timer.hpp>

#include "path_prob_analysis.hpp"

using namespace std;
using namespace hashutil;

#define DEBUG_CUDA(q) { cudaError_t cudaerr; cudaerr = q; if (cudaerr != 0) { cerr << "CUDA ERROR: " << cudaerr << " @ " << __LINE__ << endl; throw; } }

__device__ inline uint32 sha1_f1(uint32 b, uint32 c, uint32 d)
{ return d ^ (b & (c ^ d)); }
__device__ inline uint32 sha1_f2(uint32 b, uint32 c, uint32 d)
{ return b ^ c ^ d; }
__device__ inline uint32 sha1_f3(uint32 b, uint32 c, uint32 d)
{ return (b & (c | d)) | (c & d); }
__device__ inline uint32 sha1_f4(uint32 b, uint32 c, uint32 d)
{ return b ^ c ^ d; }
template<int r> __device__ uint32 sha1_ff(uint32 b, uint32 c, uint32 d);
template<> __device__ uint32 sha1_ff<1>(uint32 b, uint32 c, uint32 d) { return d ^ (b & (c ^ d)); }
template<> __device__ uint32 sha1_ff<2>(uint32 b, uint32 c, uint32 d) { return b ^ c ^ d; }
template<> __device__ uint32 sha1_ff<3>(uint32 b, uint32 c, uint32 d) { return (b & (c | d)) | (c & d); }
template<> __device__ uint32 sha1_ff<4>(uint32 b, uint32 c, uint32 d) { return b ^ c ^ d; }
template<int r> struct sha1_rndconstant { static const uint32 cnst = r<3? (r==1?0x5A827999:0x6ED9EBA1) : (r==3?0x8F1BBCDC:0xCA62C1D6); };

struct random_type {
	uint32 rnd1[MAXTHREADS];
	uint32 rnd2[MAXTHREADS];
	uint32 rndd[MAXTHREADS];
};

struct constants_type {
	uint32 idm;//, dmt, dft, dftp1, dftp2, dqtp1, qtp1mask, qtp1set, qtp1prev, qtp1prev2;
	uint32 dqt[85];
	uint32 qtmask[85];
	uint32 qtset[85];
	uint32 qtprev[85];
	uint32 qtprev2[85];
	uint32 dmtt[80];
	uint32 dftt[80];
	uint32 dihv[5];	
	uint32 SAMPLESIZE;
	uint32 LOOPSIZE;
};

__device__ samples_type samples1, samples2;
__device__ uint32 okcnt[MAXTHREADS];
__device__ uint32 tokcnt[81*256];
__device__ random_type random_seed;
__constant__ constants_type cnsts;

__shared__ uint32 rand1[512], rand2[512], randd[512];
__device__ inline void init_rndgen()
{
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	rand1[threadIdx.x] = random_seed.rnd1[idx];
	rand2[threadIdx.x] = random_seed.rnd2[idx];
	randd[threadIdx.x] = random_seed.rndd[idx];

}
__device__ inline void exit_rndgen()
{
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	random_seed.rnd1[idx] = rand1[threadIdx.x];
	random_seed.rnd2[idx] = rand2[threadIdx.x];
	random_seed.rndd[idx] = randd[threadIdx.x];
}
 __device__ inline uint32 rnd_gen64()
{ 
	uint32 t = rand1[threadIdx.x] ^ (rand1[threadIdx.x] << 10); 
	rand1[threadIdx.x] = rand2[threadIdx.x];
	rand2[threadIdx.x] = (rand2[threadIdx.x]^(rand2[threadIdx.x]>>10))^(t^(t>>13));
	return rand1[threadIdx.x] + (randd[threadIdx.x] += 789456123);
}

__shared__ volatile unsigned int warpqueue[512/16], warpcnt[512/16], okcntshared[512];
__shared__ volatile unsigned int blockbound, blockboundstart, blockboundmax;
__shared__ volatile unsigned int inbegin, inbound;

template<int r1, int r2, bool checkft, bool checkftp1, bool usebc>
__global__ void sha1_stat_init_new(int t) // outuse1 = true;
{
//	samples_type* out = outuse1 ? &samples1 : &samples2;

	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	blockboundmax = ((blockIdx.x+1) * cnsts.SAMPLESIZE) / gridDim.x;
	
	okcntshared[threadIdx.x] = 0;
	okcnt[idx] = 0;
	if (threadIdx.x == 0)
		blockboundstart = blockbound = (blockIdx.x * cnsts.SAMPLESIZE) / gridDim.x;
	if ((threadIdx.x&15)==0) 
		warpcnt[threadIdx.x>>4] = 0;
	__syncthreads();
	
	__shared__ uint32 outqtm4[512], outqtm4b[512], outqtm3b[512];
	init_rndgen();
	for (int k = blockboundmax-(blockbound+threadIdx.x); k > 0; k-=blockDim.x) {
		outqtm4[threadIdx.x] = rnd_gen64();
		if (usebc) { outqtm4[threadIdx.x] &= (cnsts.qtmask[4+t-4] | cnsts.qtprev[4+t-4] | cnsts.qtprev2[4+t-4]); outqtm4[threadIdx.x] |= cnsts.qtset[4+t-4]; }

		uint32 outqtm3 = rnd_gen64();
		if (usebc) { outqtm3 &= (cnsts.qtmask[4+t-3] | cnsts.qtprev2[4+t-3]); outqtm3 |= cnsts.qtset[4+t-3]; outqtm3 ^= outqtm4[threadIdx.x]&cnsts.qtprev[4+t-3]; }

		outqtm4b[threadIdx.x] = rotate_left(outqtm4[threadIdx.x] + cnsts.dqt[4+t-4],30);
		outqtm4[threadIdx.x] = rotate_left(outqtm4[threadIdx.x],30);
		uint32 outqtm2 = rnd_gen64();
		if (usebc) { outqtm2 &= cnsts.qtmask[4+t-2]; outqtm2 |= cnsts.qtset[4+t-2]; outqtm2 ^= outqtm3&cnsts.qtprev[4+t-2]; outqtm2 ^= outqtm4[threadIdx.x]&cnsts.qtprev2[4+t-2]; }

		outqtm3b[threadIdx.x] = rotate_left(outqtm3 + cnsts.dqt[4+t-3],30); 
		outqtm3 = rotate_left(outqtm3,30);
		uint32 outqtm1 = rnd_gen64();
		if (usebc) { outqtm1 &= cnsts.qtmask[4+t-1]; outqtm1 |= cnsts.qtset[4+t-1]; outqtm1 ^= outqtm2&cnsts.qtprev[4+t-1]; outqtm1 ^= outqtm3&cnsts.qtprev2[4+t-1]; }

		uint32 outqtm2b = rotate_left(outqtm2 + cnsts.dqt[4+t-2],30); 
		outqtm2 = rotate_left(outqtm2,30);
		uint32 outqt = rnd_gen64();
		if (usebc) { outqt &= cnsts.qtmask[4+t]; outqt |= cnsts.qtset[4+t]; outqt ^= outqtm1&cnsts.qtprev[4+t]; outqt ^= outqtm2&cnsts.qtprev2[4+t]; }

		uint32 outqtm1b = outqtm1 + cnsts.dqt[4+t-1];
		uint32 outqtb = outqt + cnsts.dqt[4+t];

		bool ok = true;
		if (checkft) {
			uint32 ft = sha1_ff<r1>(outqtm1b,outqtm2b,outqtm3b[threadIdx.x]) - sha1_ff<r1>(outqtm1,outqtm2,outqtm3);
			if (ft != cnsts.dftt[t]) ok = false;
		}
		if (checkftp1) {
			uint32 ftp1 = sha1_ff<r2>(outqtb,rotate_left(outqtm1b,30),outqtm2b) - sha1_ff<r2>(outqt,rotate_left(outqtm1,30),outqtm2);
			if (ftp1 != cnsts.dftt[t+1]) ok = false;
		}

		const int warpidx = threadIdx.x>>4;
		unsigned int so;
		if (0) {//__all(ok)) {
			so = threadIdx.x&31;
			if (so == 0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, 32);
				warpqueue[warpidx+1] = warpqueue[warpidx];
				__threadfence_block();
			}
		} else {
			if (ok)
					so = atomicInc((unsigned int*)&warpcnt[warpidx], (unsigned int)(1<<30));
			//__syncthreads();
			if ((threadIdx.x&15)==0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, warpcnt[warpidx]);				
				__threadfence_block();
				warpcnt[warpidx] = 0;
			}
		}
		if (ok) {
			so += warpqueue[warpidx];
			++okcntshared[threadIdx.x];			
			samples1.qt[so] = outqt;
			samples1.qtm1[so] = outqtm1;
			samples1.qtm2[so] = outqtm2;
			samples1.qtm3[so] = outqtm3;
			samples1.qtm4[so] = outqtm4[threadIdx.x];
			samples1.qtb[so] = outqtb;
			samples1.qtm1b[so] = outqtm1b;
			samples1.qtm2b[so] = outqtm2b;
			samples1.qtm3b[so] = outqtm3b[threadIdx.x];
			samples1.qtm4b[so] = outqtm4b[threadIdx.x];
		}
	}
	__syncthreads();
	exit_rndgen();
	okcnt[idx] = okcntshared[threadIdx.x];
	if (threadIdx.x < 32) {
		uint32 totok = 0;
		for (unsigned i = threadIdx.x; i < blockDim.x; i+=32)
			totok += okcntshared[i];
		okcntshared[threadIdx.x] = totok;
		__threadfence_block();
		if (threadIdx.x == 0) {
			totok = 0;
			for (unsigned i = 0; i < 32; ++i)
				totok += okcntshared[i];
			tokcnt[80*gridDim.x + blockIdx.x] = totok;
			if (blockbound < blockboundmax)
				samples1.bound[blockIdx.x] = blockbound;
			else
				samples1.bound[blockIdx.x] = blockboundmax;
		}
	}
}

template<int r1, int r2, bool checkqtp1, bool checkftp2, bool usebc, bool usedihv> 
__global__ void sha1_stat_work_new_outuse1true(int t)
{
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
//	const unsigned int blockboundmax = ((blockIdx.x+1) * SAMPLESIZE) / gridDim.x;
	blockboundmax = ((blockIdx.x+1) * cnsts.SAMPLESIZE) / gridDim.x;
	
//	samples_type* out = outuse1 ? &samples1 : &samples2;
//	samples_type* in = outuse1 ? &samples2 : &samples1;
	
	okcntshared[threadIdx.x] = 0;
	okcnt[idx] = 0;
	tokcnt[t*gridDim.x + blockIdx.x] = 0;
	if (threadIdx.x == 0) {
		blockbound = (blockIdx.x * cnsts.SAMPLESIZE) / gridDim.x;		
		inbegin = blockbound;
		inbound = samples2.bound[blockIdx.x] & ~uint32(31);
		samples1.bound[blockIdx.x] = blockbound;
	}
	if ((threadIdx.x&15)==0) warpcnt[threadIdx.x>>4] = 0;	
	__syncthreads();

	unsigned int si = inbegin+threadIdx.x;
	if (si >= inbound)
		return;

	init_rndgen();
	// fill output with samples
	for (int k = (((blockIdx.x+1)*cnsts.LOOPSIZE)/gridDim.x) - ((blockIdx.x*cnsts.LOOPSIZE)/gridDim.x + threadIdx.x); k > 0; k -= blockDim.x)
	{
		uint32 outqtb = sha1_ff<r1>(samples2.qtm1b[si],samples2.qtm2b[si],samples2.qtm3b[si]) - sha1_ff<r1>(samples2.qtm1[si],samples2.qtm2[si],samples2.qtm3[si])
			+ rotate_left(samples2.qtb[si],5) - rotate_left(samples2.qt[si],5) + samples2.qtm4b[si] - samples2.qtm4[si] /*+ outqt*/ + cnsts.dmtt[t];

		uint32 outqt = rnd_gen64();
		uint32 outqtm2 = rotate_left(samples2.qtm1[si],30);		
		if (usebc)
			outqt = ((outqt & cnsts.qtmask[4+t+1]) | cnsts.qtset[4+t+1]) ^ (samples2.qt[si] & cnsts.qtprev[4+t+1]) ^ (outqtm2 & cnsts.qtprev2[4+t+1]);
		outqtb += outqt;		
		
		bool ok = true;
		if (checkqtp1 && outqtb-outqt != cnsts.dqt[4+t+1]) 
				ok = false;
		if (usedihv && (rotate_left(outqtb,30)-rotate_left(outqt,30)) != cnsts.dihv[t-75])
				ok = false;
		uint32 outqtm2b = rotate_left(samples2.qtm1b[si],30);
		if (checkftp2 && cnsts.dftt[t+2] != sha1_ff<r2>(outqtb,rotate_left(samples2.qtb[si],30),outqtm2b) - sha1_ff<r2>(outqt,rotate_left(samples2.qt[si],30),outqtm2))
				ok = false;

		const int warpidx = threadIdx.x>>4;
		unsigned int so = blockbound;
		if (0) {//__all(ok)) {
			so = threadIdx.x&31;
			if (so == 0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, 32);
				warpqueue[warpidx+1] = warpqueue[warpidx];
				__threadfence_block();
			}
		} else {
			if (ok && so < blockboundmax)
				so = atomicInc((unsigned int*)&warpcnt[warpidx], (unsigned int)(1<<30));
			if ((threadIdx.x&15)==0 && warpcnt[warpidx]>0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, warpcnt[warpidx]);
				__threadfence_block();
				warpcnt[warpidx] = 0;
			}
		}
		if (ok) {
			so += warpqueue[warpidx];
			++okcntshared[threadIdx.x];
			if (so < blockboundmax) {				
				samples1.qt[so] = outqt;
				samples1.qtm1[so] = samples2.qt[si];
				samples1.qtm2[so] = outqtm2;
				samples1.qtm3[so] = samples2.qtm2[si];
				samples1.qtm4[so] = samples2.qtm3[si];
				samples1.qtb[so] = outqtb;
				samples1.qtm1b[so] = samples2.qtb[si];
				samples1.qtm2b[so] = outqtm2b;
				samples1.qtm3b[so] = samples2.qtm2b[si];
				samples1.qtm4b[so] = samples2.qtm3b[si];
			}
		}
		//__syncthreads();
		si += blockDim.x; // increase w/ # threads in this block
		if (si >= inbound)
			si -= (inbound-inbegin);

	}
	__syncthreads();
	exit_rndgen();
	okcnt[idx] = okcntshared[threadIdx.x];
	if (threadIdx.x < 32) {
		uint32 totok = 0;
		for (unsigned i = threadIdx.x; i < blockDim.x; i+=32)
			totok += okcntshared[i];
		okcntshared[threadIdx.x] = totok;
		__threadfence_block();
		if (threadIdx.x == 0) {
			totok = 0;
			for (unsigned i = 0; i < 32; ++i)
				totok += okcntshared[i];
			tokcnt[t*gridDim.x + blockIdx.x] = totok;
			if (blockbound < blockboundmax)
				samples1.bound[blockIdx.x] = blockbound;
			else
				samples1.bound[blockIdx.x] = blockboundmax;
		}
	}
}

template<int r1, int r2, bool checkqtp1, bool checkftp2, bool usebc, bool usedihv> 
__global__ void sha1_stat_work_new_outuse1false(int t)
{
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
//	const unsigned int blockboundmax = ((blockIdx.x+1) * SAMPLESIZE) / gridDim.x;
	blockboundmax = ((blockIdx.x+1) * cnsts.SAMPLESIZE) / gridDim.x;
	
//	samples_type* out = outuse1 ? &samples1 : &samples2;
//	samples_type* in = outuse1 ? &samples2 : &samples1;
	
	okcntshared[threadIdx.x] = 0;
	okcnt[idx] = 0;
	tokcnt[t*gridDim.x + blockIdx.x] = 0;
	if (threadIdx.x == 0) {
		blockbound = (blockIdx.x * cnsts.SAMPLESIZE) / gridDim.x;		
		inbegin = blockbound;
		inbound = samples1.bound[blockIdx.x] & ~uint32(31);
		samples2.bound[blockIdx.x] = blockbound;
	}
	if ((threadIdx.x&15)==0) warpcnt[threadIdx.x>>4] = 0;	
	__syncthreads();

	unsigned int si = inbegin+threadIdx.x;
	if (si >= inbound)
		return;

	init_rndgen();
	// fill output with samples
	for (int k = (((blockIdx.x+1)*cnsts.LOOPSIZE)/gridDim.x) - ((blockIdx.x*cnsts.LOOPSIZE)/gridDim.x) - threadIdx.x; k > 0; k -= blockDim.x)
	{
		uint32 outqtb = sha1_ff<r1>(samples1.qtm1b[si],samples1.qtm2b[si],samples1.qtm3b[si]) - sha1_ff<r1>(samples1.qtm1[si],samples1.qtm2[si],samples1.qtm3[si])
			+ rotate_left(samples1.qtb[si],5) - rotate_left(samples1.qt[si],5) + samples1.qtm4b[si] - samples1.qtm4[si] /*+ outqt*/ + cnsts.dmtt[t];

		uint32 outqt = rnd_gen64();
		uint32 outqtm2 = rotate_left(samples1.qtm1[si],30);		
		if (usebc)
			outqt = ((outqt & cnsts.qtmask[4+t+1]) | cnsts.qtset[4+t+1]) ^ (samples1.qt[si] & cnsts.qtprev[4+t+1]) ^ (outqtm2 & cnsts.qtprev2[4+t+1]);
		outqtb += outqt;

		bool ok = true;
		if (checkqtp1 && outqtb-outqt != cnsts.dqt[4+t+1]) 
				ok = false;
		if (usedihv && (rotate_left(outqtb,30)-rotate_left(outqt,30)) != cnsts.dihv[t-75])
				ok = false;

		uint32 outqtm2b = rotate_left(samples1.qtm1b[si],30);
		if (checkftp2 && cnsts.dftt[t+2] != sha1_ff<r2>(outqtb,rotate_left(samples1.qtb[si],30),outqtm2b) - sha1_ff<r2>(outqt,rotate_left(samples1.qt[si],30),outqtm2))
				ok = false;

		const int warpidx = threadIdx.x>>4;
		unsigned int so = blockbound;
		if (0) {//__all(ok)) {
			so = threadIdx.x&31;
			if (so == 0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, 32);
				warpqueue[warpidx+1] = warpqueue[warpidx];
				__threadfence_block();
			}
		} else {
			if (ok && so < blockboundmax)
				so = atomicInc((unsigned int*)&warpcnt[warpidx], (unsigned int)(1<<30));
			if ((threadIdx.x&15)==0 && warpcnt[warpidx]>0) {
				warpqueue[warpidx] = atomicAdd((unsigned int*)&blockbound, warpcnt[warpidx]);
				__threadfence_block();
				warpcnt[warpidx] = 0;
			}
		}
		if (ok) {
			so += warpqueue[warpidx];
			++okcntshared[threadIdx.x];
			if (so < blockboundmax) {				
				samples2.qt[so] = outqt;
				samples2.qtm1[so] = samples1.qt[si];
				samples2.qtm2[so] = outqtm2;
				samples2.qtm3[so] = samples1.qtm2[si];
				samples2.qtm4[so] = samples1.qtm3[si];
				samples2.qtb[so] = outqtb;
				samples2.qtm1b[so] = samples1.qtb[si];
				samples2.qtm2b[so] = outqtm2b;
				samples2.qtm3b[so] = samples1.qtm2b[si];
				samples2.qtm4b[so] = samples1.qtm3b[si];
			} 
		}
		//__syncthreads();
		si += blockDim.x; // increase w/ # threads in this block
		if (si >= inbound)
			si -= inbound-inbegin;
	}
	__syncthreads();
	exit_rndgen();
	okcnt[idx] = okcntshared[threadIdx.x];
	if (threadIdx.x < 32) {
		uint32 totok = 0;
		for (unsigned i = threadIdx.x; i < blockDim.x; i+=32)
			totok += okcntshared[i];
		okcntshared[threadIdx.x] = totok;
		__threadfence_block();
		if (threadIdx.x == 0) {
			totok = 0;
			for (unsigned i = 0; i < 32; ++i)
				totok += okcntshared[i];
			tokcnt[t*gridDim.x + blockIdx.x] = totok;
			if (blockbound < blockboundmax)
				samples2.bound[blockIdx.x] = blockbound;
			else
				samples2.bound[blockIdx.x] = blockboundmax;
		}
	}
}


namespace hash {

	class cuda_device_detail {
	public:
		uint32 okcnt[MAXTHREADS];
		uint32 dme[80];
		uint32 dqt[85];
		uint32 dft[80];
		uint32 qtmask[85];
		uint32 qtset[85];
		uint32 qtprev[85];
		uint32 qtprev2[85];
		uint32 dihv[5];

		uint32 blocks;
		uint32 threadsperblock;
		uint32 cores;
	};

	uint32 cuda_global_SAMPLESIZE = 0, cuda_global_LOOPSIZE = 0;
	cuda_device_detail* detail = 0;
	samples_type mysamples;

	unsigned hw2(unsigned mask) {
		unsigned cnt = 0;
		while (mask) { // at least one bit set
			++cnt; // increase counter
			mask &= mask-1; // unset lowest bit set
		}
		return cnt;
	}
	cuda_device::cuda_device(unsigned SAMPLESIZE, unsigned LOOPSIZE) {
		if (cuda_global_SAMPLESIZE != 0 || cuda_global_LOOPSIZE != 0)
			throw std::runtime_error("Runtime switching of SAMPLESIZE or LOOPSIZE not allowed!");
		if (hw2(SAMPLESIZE)!=1)
			throw std::runtime_error("SAMPLESIZE must be a power of 2!");
		if (hw2(LOOPSIZE)!=1)
			throw std::runtime_error("LOOPSIZE must be a power of 2!");
		if (LOOPSIZE < SAMPLESIZE)
			throw std::runtime_error("LOOPSIZE < SAMPLESIZE!");
		if (SAMPLESIZE > MAXSAMPLESIZE)
			throw std::runtime_error("SAMPLESIZE > MAXSAMPLESIZE!");
		cuda_global_SAMPLESIZE = SAMPLESIZE;
		cuda_global_LOOPSIZE = LOOPSIZE;
	}
	bool cuda_device::init(const uint32 _dme[80], const uint32 _dqt[85], const uint32* _dft, const uint32* _qtmask, const uint32* _qtset, const uint32* _qtprev, const uint32* _qtprev2, const uint32* _dihv)
	{
		if (detail == 0) {
			int deviceCount;
			cudaError_t cudaerr = cudaGetDeviceCount(&deviceCount);
			if (cudaerr != 0) {
				const char* errorstr = cudaGetErrorString(cudaerr);
				if (errorstr == 0)
					cout << "Error during CUDA initialization.\nFailed to get CUDA device count.\nCUDA ERROR: " << cudaerr << endl;
				else
					cout << "Error during CUDA initialization.\nFailed to get CUDA device count.\nCUDA ERROR: " << cudaerr << ": " << errorstr << endl;				
			}
			if (deviceCount == 0) {
				cout << "There is no device supporting CUDA!" << endl;
				return false;
			}
			int device = -1;
			int cores = 0;
			cudaDeviceProp deviceProp;
			// select with highest number of cores
			for (int i = 0; i < deviceCount; ++i) {
				DEBUG_CUDA( cudaGetDeviceProperties(&deviceProp, i) );
				cout << "device " << i << ": " << deviceProp.major << "." << deviceProp.minor << " (" << deviceProp.multiProcessorCount*8 << " cores)" << endl;
				if (deviceProp.major < 1) continue;
				if (deviceProp.major == 1 && deviceProp.minor < 3) continue;
				if (deviceProp.multiProcessorCount > cores) {
					device = i;
					cores = deviceProp.multiProcessorCount;
				}
			}
			if (device == -1) {
				cout << "No acceptable CUDA device found!" << endl;
				return false;
			}

			DEBUG_CUDA( cudaGetDeviceProperties(&deviceProp, device) );
			if (deviceProp.major == 9999) {
				cout << "Emulation device found." << endl;
				return false;
			}
			cout << "CUDA device: " << deviceProp.name << " (" << 8 * deviceProp.multiProcessorCount << " cores)" << endl;
			DEBUG_CUDA( cudaSetDevice(device) );
			DEBUG_CUDA( cudaSetDeviceFlags( cudaDeviceScheduleSpin) );

			DEBUG_CUDA( cudaMallocHost(&detail, sizeof(cuda_device_detail)) );
			
			detail->cores = deviceProp.multiProcessorCount;
			detail->blocks =  BLOCKSPERCORE * deviceProp.multiProcessorCount;
			detail->threadsperblock = THREADSPERBLOCK;

			random_type* rnddata = new random_type;
			for (unsigned i = 0; i < MAXTHREADS; ++i)
				rnddata->rnd1[i] = xrng64();
			for (unsigned i = 0; i < MAXTHREADS; ++i)
				rnddata->rnd2[i] = xrng64();
			for (unsigned i = 0; i < MAXTHREADS; ++i)
				rnddata->rndd[i] = xrng64();
			DEBUG_CUDA( cudaMemcpyToSymbol(random_seed, rnddata, sizeof(random_type)) );
			delete rnddata;
		}
		memcpy(detail->dme, _dme, sizeof(uint32)*80);
		memcpy(detail->dqt, _dqt, sizeof(uint32)*85);
		if (_dft)
			memcpy(detail->dft, _dft, sizeof(uint32)*80);
		if (_qtmask) 
			memcpy(detail->qtmask, _qtmask, sizeof(uint32)*85);
		if (_qtset) 
			memcpy(detail->qtset, _qtset, sizeof(uint32)*85);
		if (_qtprev) 
			memcpy(detail->qtprev, _qtprev, sizeof(uint32)*85);
		if (_qtprev2) 
			memcpy(detail->qtprev2, _qtprev2, sizeof(uint32)*85);
		if (_dihv) {
			memcpy(detail->dihv, _dihv, sizeof(uint32)*5);
			detail->dqt[83] = _dihv[3];
			detail->dqt[84] = _dihv[4];
		}
		if (detail->blocks * detail->threadsperblock > MAXTHREADS)
		{
			cout << "HARD-CODED CUDA MEMORY LIMIT REACHED!!" << endl;
			unsigned oldblocks = detail->blocks;
			detail->blocks = MAXTHREADS / detail->threadsperblock;
			cout << "Reducing # CUDA blocks from " << oldblocks << " to " << detail->blocks << "!" << endl;
			return true;
//			return false;
		}
		return true;
	}

	void cuda_device::set_consts()
	{
		static constants_type* constants = 0;
		if (constants == 0)
			DEBUG_CUDA( cudaMallocHost(&constants, sizeof(constants_type)) );
			
		memcpy(constants->dqt, detail->dqt, sizeof(uint32)*85);
		memcpy(constants->qtmask, detail->qtmask, sizeof(uint32)*85);
		memcpy(constants->qtset, detail->qtset, sizeof(uint32)*85);
		memcpy(constants->qtprev, detail->qtprev, sizeof(uint32)*85);
		memcpy(constants->qtprev2, detail->qtprev2, sizeof(uint32)*85);
		memcpy(constants->dftt, detail->dft, sizeof(uint32)*80);
		memcpy(constants->dmtt, detail->dme, sizeof(uint32)*80);
		memcpy(constants->dihv, detail->dihv, sizeof(uint32)*5);
		constants->idm = detail->blocks * detail->threadsperblock;
		constants->SAMPLESIZE = cuda_global_SAMPLESIZE;
		constants->LOOPSIZE = cuda_global_LOOPSIZE;
		DEBUG_CUDA( cudaMemcpyToSymbol(cnsts, constants, sizeof(constants_type)) );
	}

	template<bool checkft, bool checkftp1, bool usebitcond> 
	void run_sha1_stat_init(unsigned blocks, int t, unsigned tpb = THREADSPERBLOCK)
	{
		if (t+1 < 20)					sha1_stat_init_new<1,1,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t+1 == 20)				sha1_stat_init_new<1,2,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t >= 20 && t+1 < 40)	sha1_stat_init_new<2,2,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t+1 == 40)				sha1_stat_init_new<2,3,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t >= 40 && t+1 < 60)	sha1_stat_init_new<3,3,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t+1 == 60)				sha1_stat_init_new<3,4,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t >= 60 && t+1 < 80)	sha1_stat_init_new<4,4,checkft,checkftp1,usebitcond><<<blocks, tpb>>>(t);
		else if (t+1 == 80)				sha1_stat_init_new<4,4,checkft,false,usebitcond><<<blocks, tpb>>>(t);
		else throw;
	}
	void cuda_device::init_samples_fast(unsigned t, bool checkft, bool checkftp1, bool usebitcond)
	{
		set_consts();
		if (checkft && checkftp1 && usebitcond)			run_sha1_stat_init<true,true,true>(detail->blocks,int(t),detail->threadsperblock);
		else if (checkft && !checkftp1 && usebitcond)	run_sha1_stat_init<true,false,true>(detail->blocks,int(t),detail->threadsperblock);
		else if (!checkft && checkftp1 && usebitcond)	run_sha1_stat_init<false,true,true>(detail->blocks,int(t),detail->threadsperblock);
		else if (!checkft && !checkftp1 && usebitcond)	run_sha1_stat_init<false,false,true>(detail->blocks,int(t),detail->threadsperblock);
		else if (checkft && checkftp1 && !usebitcond)	run_sha1_stat_init<true,true,false>(detail->blocks,int(t),detail->threadsperblock);
		else if (checkft && !checkftp1 && !usebitcond)	run_sha1_stat_init<true,false,false>(detail->blocks,int(t),detail->threadsperblock);
		else if (!checkft && checkftp1 && !usebitcond)	run_sha1_stat_init<false,true,false>(detail->blocks,int(t),detail->threadsperblock);
		else if (!checkft && !checkftp1 && !usebitcond)	run_sha1_stat_init<false,false,false>(detail->blocks,int(t),detail->threadsperblock);
		else throw;
	}
	double cuda_device::init_samples(unsigned t, bool checkft, bool checkftp1, bool usebitcond)
	{
		init_samples_fast(t, checkft, checkftp1, usebitcond);
		const unsigned nrthreads = detail->blocks*detail->threadsperblock;
		DEBUG_CUDA( cudaMemcpyFromSymbol(detail->okcnt, okcnt, sizeof(uint32)*nrthreads) );
		uint64 cnt = 0;
		for (unsigned i = 0; i < nrthreads; ++i)
			cnt += detail->okcnt[i];
		return double(cnt)/double(cuda_global_SAMPLESIZE);
	}

	template<bool checkqtp1, bool checkftp2, bool usebitcond, bool usedihv> 
	void run_sha1_stat_work(unsigned blocks, int t, bool outuse1, unsigned tpb = THREADSPERBLOCK)
	{
		if (outuse1) {
			if (t+2 < 20)					sha1_stat_work_new_outuse1true<1,1,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 20 && t+2 >= 20)	sha1_stat_work_new_outuse1true<1,2,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 20 && t+2 < 40)	sha1_stat_work_new_outuse1true<2,2,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 40 && t+2 >= 40)	sha1_stat_work_new_outuse1true<2,3,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 40 && t+2 < 60)	sha1_stat_work_new_outuse1true<3,3,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 60 && t+2 >= 60)	sha1_stat_work_new_outuse1true<3,4,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 60 && t+2 < 80)	sha1_stat_work_new_outuse1true<4,4,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 80 && t+2 >= 80)	sha1_stat_work_new_outuse1true<4,4,checkqtp1,false,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else throw;
		} else {
			if (t+2 < 20)					sha1_stat_work_new_outuse1false<1,1,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 20 && t+2 >= 20)	sha1_stat_work_new_outuse1false<1,2,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 20 && t+2 < 40)	sha1_stat_work_new_outuse1false<2,2,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 40 && t+2 >= 40)	sha1_stat_work_new_outuse1false<2,3,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 40 && t+2 < 60)	sha1_stat_work_new_outuse1false<3,3,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 60 && t+2 >= 60)	sha1_stat_work_new_outuse1false<3,4,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t >= 60 && t+2 < 80)	sha1_stat_work_new_outuse1false<4,4,checkqtp1,checkftp2,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else if (t < 80 && t+2 >= 80)	sha1_stat_work_new_outuse1false<4,4,checkqtp1,false,usebitcond,usedihv><<<blocks, tpb>>>(t);
			else throw;
		}
	}
	void cuda_device::run_step_fast(unsigned t, bool checkqtp1, bool checkftp2, bool outuse1, bool usebitcond, bool usedihv)
	{
		if (t < 75) usedihv = false;
		if (t >= 78 && usedihv) { usedihv = false; checkqtp1 = true; } // last 2 steps don't rotate so dihv == dqt
		if (usedihv) {
			if (checkqtp1 && checkftp2 && usebitcond)			run_sha1_stat_work<true,true,true,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && !checkftp2 && usebitcond)		run_sha1_stat_work<true,false,true,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && checkftp2 && usebitcond)		run_sha1_stat_work<false,true,true,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && !checkftp2 && usebitcond)	run_sha1_stat_work<false,false,true,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && checkftp2 && !usebitcond)		run_sha1_stat_work<true,true,false,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && !checkftp2 && !usebitcond)	run_sha1_stat_work<true,false,false,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && checkftp2 && !usebitcond)	run_sha1_stat_work<false,true,false,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && !checkftp2 && !usebitcond)	run_sha1_stat_work<false,false,false,true>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else throw;
		} else {
			if (checkqtp1 && checkftp2 && usebitcond)			run_sha1_stat_work<true,true,true,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && !checkftp2 && usebitcond)		run_sha1_stat_work<true,false,true,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && checkftp2 && usebitcond)		run_sha1_stat_work<false,true,true,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && !checkftp2 && usebitcond)	run_sha1_stat_work<false,false,true,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && checkftp2 && !usebitcond)		run_sha1_stat_work<true,true,false,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (checkqtp1 && !checkftp2 && !usebitcond)	run_sha1_stat_work<true,false,false,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && checkftp2 && !usebitcond)	run_sha1_stat_work<false,true,false,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else if (!checkqtp1 && !checkftp2 && !usebitcond)	run_sha1_stat_work<false,false,false,false>(detail->blocks,int(t),outuse1,detail->threadsperblock);
			else throw;
		}
	}
	double cuda_device::run_step(unsigned t, bool checkqtp1, bool checkftp2, bool outuse1, bool usebitcond, bool usedihv)
	{
		set_consts();
		run_step_fast(t, checkqtp1, checkftp2, outuse1, usebitcond, usedihv);
		const unsigned nrthreads = detail->blocks * detail->threadsperblock;
		DEBUG_CUDA( cudaMemcpyFromSymbol(detail->okcnt, okcnt, sizeof(uint32)*nrthreads) );
		uint64 cnt = 0;
		for (unsigned i = 0; i < nrthreads; ++i)
			cnt += detail->okcnt[i];
		return double(cnt)/double(cuda_global_LOOPSIZE);
	}

	void cuda_device::gather_samples(samples_type& samples, bool use1)
	{
		static samples_type* tmp = 0;
		if (tmp == 0)
			DEBUG_CUDA( cudaMallocHost(&tmp, sizeof(samples_type)) );

		if (use1) {
			DEBUG_CUDA( cudaMemcpyFromSymbol(tmp, samples1, sizeof(samples_type)) );
		} else {
			DEBUG_CUDA( cudaMemcpyFromSymbol(tmp, samples2, sizeof(samples_type)) );
		}
		memcpy(&samples, tmp, sizeof(samples_type));
		samples.nrblocks = detail->blocks;
		samples.SAMPLESIZE = cuda_global_SAMPLESIZE;
	}

	double cuda_device::get_prob(unsigned tbegin, unsigned tend)
	{
		DEBUG_CUDA( cudaMemcpyFromSymbol(detail->okcnt, tokcnt, sizeof(uint32)*81*detail->blocks) );
		uint32 okcnt = 0;
		for (unsigned i = 0; i < detail->blocks; ++i) 
			okcnt += detail->okcnt[80 * detail->blocks + i];
		double prob = double(okcnt)/double(cuda_global_SAMPLESIZE);
		for (unsigned t = tbegin; t < tend; ++t) {
			okcnt = 0;
			for (unsigned i = 0; i < detail->blocks; ++i) 
				okcnt += detail->okcnt[t * detail->blocks + i];
			prob *= double(okcnt)/double(cuda_global_LOOPSIZE);
		}
		return prob;	
	}
	double cuda_device::path_analysis(unsigned tbegin, unsigned tend, bool usebitcond, bool verbose, bool usedihv)
	{
		// init_samples always uses outuse1 = true
		init_samples_fast(tbegin, true, bool(tend>tbegin+1), usebitcond); 
		bool outuse1 = false;
		for (unsigned t = tbegin; t < tend; ++t) {
			run_step_fast(t, true, bool(tend>t+2), outuse1, usebitcond, usedihv); 
			outuse1 = !outuse1;
		}
		DEBUG_CUDA( cudaMemcpyFromSymbol(detail->okcnt, tokcnt, sizeof(uint32)*81*detail->blocks) );
		if (verbose) cout << "[";
		uint32 okcnt = 0;
		for (unsigned i = 0; i < detail->blocks; ++i) 
			okcnt += detail->okcnt[80 * detail->blocks + i];
		double prob = double(okcnt)/double(cuda_global_SAMPLESIZE);
		if (verbose) cout << log(prob)/log(2.0) << " ";
		for (unsigned t = tbegin; t < tend; ++t) {
			okcnt = 0;
			for (unsigned i = 0; i < detail->blocks; ++i) 
				okcnt += detail->okcnt[t * detail->blocks + i];
			double p = double(okcnt)/double(cuda_global_LOOPSIZE);
			prob *= p;
			if (verbose) cout << "(" << log(prob)/log(2.0) << " " << log(p)/log(2.0) << ") ";
		}
		if (verbose) cout << "]";
		return prob;
	}
	

	void cuda_device::test_optimal_constants(unsigned tbegin, unsigned tend, bool usebitcond)
	{
		cout << "Determining optimal constants..." << flush;
		detail->blocks = 1*detail->cores;
		detail->threadsperblock = 256;
		double okavg = 0;
		try {
			for (unsigned i = 0; i < 100; ++i) {
				cout << "." << flush;
				okavg += path_analysis(tbegin, tend, usebitcond, false);
			}
		} catch (std::exception& e) { okavg = 0; } catch (...) { okavg = 0; }
		cout << " (targetp=" << log(okavg/100.0)/log(2.0) << ")" << endl;
		unsigned bestblocks = 0;
		unsigned bestthreads = 0;
		double besttime = 65536;
		
		for (unsigned blocks = 1; blocks <= 2; ++blocks)
			for (unsigned tpbi = 0; tpbi < 4; ++ tpbi)
			{
				detail->blocks = blocks*detail->cores;
				switch (tpbi) {
					case 0: detail->threadsperblock = 256-32; break;
//					case 1: detail->threadsperblock = 256-16; break;
					case 1: detail->threadsperblock = 256; break;
					case 2: detail->threadsperblock = 512-32; break;
//					case 4: detail->threadsperblock = 512-16; break;
					case 3: detail->threadsperblock = 512; break;
				}
				if (detail->blocks * detail->threadsperblock > MAXTHREADS)
					continue;
				try {
					for (unsigned i = 0; i < 25; ++i)
						path_analysis(tbegin, tend, usebitcond, false);
				} catch (std::exception& e) {} catch (...) {}
				hashutil::timer sw(true);
				double avg = 0;
				try {
					for (unsigned i = 0; i < 100; ++i)
						avg += path_analysis(tbegin, tend, usebitcond, false);
				} catch (std::exception& e) { avg = 0; } catch (...) { avg = 0; }
				double time = sw.time();
				if (avg != 0)
					cout << detail->blocks/detail->cores << "x" << detail->threadsperblock << ": " << time << " \t(" << log(avg/100.0)/log(2.0) << ")" << ((avg < 0.95*okavg || avg > 1.05*okavg)?"bad":"") << endl;
				if (avg < 0.95*okavg || avg > 1.05*okavg) avg = 0;
				if (avg != 0 && time < besttime) {
					bestblocks = detail->blocks;
					bestthreads = detail->threadsperblock;
					besttime = time;
				}
			}
		cout << "Optimal result: " << bestblocks/detail->cores << "x" << bestthreads << endl;
		detail->blocks = bestblocks;
		detail->threadsperblock = bestthreads;
	}

} // namespace hash
