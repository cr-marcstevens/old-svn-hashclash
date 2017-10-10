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

#include "config.h"

#ifndef BUFFERSIZE
#define BUFFERSIZE      1024
#endif

#ifndef MAIN_HPP
typedef unsigned int uint32;
typedef vector unsigned int vec_uint32;
typedef vec_uint32* vec_uint32_ptr;
#else
typedef uint32 vec_uint32_ptr;
struct vec_uint32 {
	uint32 v[4];
	uint32& operator[](unsigned i) { return v[i]; }
	vec_uint32& operator=(const vec_uint32& rhs) { v[0]=rhs.v[0]; v[1]=rhs.v[1];v[2]=rhs.v[2];v[3]=rhs.v[3]; return *this; }
};
vec_uint32* getptr(vec_uint32_ptr ptr) { return reinterpret_cast<vec_uint32*>(ptr); }
vec_uint32_ptr putptr(vec_uint32* ptr) { return uint32(reinterpret_cast<uint64>(ptr)); }
#endif


typedef struct {
	vec_uint32 ihv1[4];
	vec_uint32 ihv2[4];
	vec_uint32 ihv2mod[4];
	vec_uint32 m1[16];
	vec_uint32 m2[16];
	vec_uint32 astart, bstart, cstart, a, b, c, len;
	vec_uint32 rngx, rngy, rngz, rngw;
	vec_uint32 id;
	vec_uint32 dpmask, maxlen,hybridmask;
	vec_uint32 astart2, bstart2, cstart2, a2, b2, c2, len2;

	uint32 collisiondata; 
	vec_uint32_ptr buffer;

	uint32 padding1[22];
} spu_program_data;

#define SPE_BIRTHDAY_INITIALIZED 0x01236666
#define SPE_BIRTHDAY_START 	 0x01237777
#define SPE_BIRTHDAY_STARTMOD 	 0x01238888
#define SPE_BIRTHDAY_FINISHED 	 0x01239999
#define SPE_BIRTHDAY_QUIT	 0x01230000
