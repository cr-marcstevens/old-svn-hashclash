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

#include <spu_mfcio.h>

//Struct for communication with the PPE
#include "spu_program_data.hpp"

/* spe_asm.S */
extern vec_uint32* generate_trails(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* reduce_trails(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* reduce_trails2(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* find_coll(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern void pre_compute(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16]);

extern vec_uint32* generate_trailsmod(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* reduce_trailsmod(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* reduce_trails2mod(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

extern vec_uint32* find_collmod(
			vec_uint32 ihv1[4], vec_uint32 ihv2[4], 
			vec_uint32 msg1[16], vec_uint32 msg2[16],
			vec_uint32 a_b_c_len[4], 
			vec_uint32 buffer[], vec_uint32 bufferend[]);

/* */

/* program_data struct for communication with the PPE */
spu_program_data pd					__attribute__((aligned(16)));

/* buffer to be filled with trails by spe_asm.S */
vec_uint32 buffer[BUFFERSIZE+16]	__attribute__((aligned(128)));

/* temporary storage for spe_asm.S */
vec_uint32 regstore[128]			__attribute__((aligned(16)));
vec_uint32 workingstate1[4]			__attribute__((aligned(16)));
vec_uint32 workingstate2[4]			__attribute__((aligned(16)));

/* md5 addition constants for spe_asm.S */
const uint32 md5_acvec[]			__attribute__((aligned(16))) = {
        0xd76aa478,0xd76aa478,0xd76aa478,0xd76aa478,
        0xe8c7b756,0xe8c7b756,0xe8c7b756,0xe8c7b756,
        0x242070db,0x242070db,0x242070db,0x242070db,
        0xc1bdceee,0xc1bdceee,0xc1bdceee,0xc1bdceee,
        0xf57c0faf,0xf57c0faf,0xf57c0faf,0xf57c0faf,
        0x4787c62a,0x4787c62a,0x4787c62a,0x4787c62a,
        0xa8304613,0xa8304613,0xa8304613,0xa8304613,
        0xfd469501,0xfd469501,0xfd469501,0xfd469501,
        0x698098d8,0x698098d8,0x698098d8,0x698098d8,
        0x8b44f7af,0x8b44f7af,0x8b44f7af,0x8b44f7af,
        0xffff5bb1,0xffff5bb1,0xffff5bb1,0xffff5bb1,
        0x895cd7be,0x895cd7be,0x895cd7be,0x895cd7be,
        0x6b901122,0x6b901122,0x6b901122,0x6b901122,
        0xfd987193,0xfd987193,0xfd987193,0xfd987193,
        0xa679438e,0xa679438e,0xa679438e,0xa679438e,
        0x49b40821,0x49b40821,0x49b40821,0x49b40821,
        0xf61e2562,0xf61e2562,0xf61e2562,0xf61e2562,
        0xc040b340,0xc040b340,0xc040b340,0xc040b340,
        0x265e5a51,0x265e5a51,0x265e5a51,0x265e5a51,
        0xe9b6c7aa,0xe9b6c7aa,0xe9b6c7aa,0xe9b6c7aa,
        0xd62f105d,0xd62f105d,0xd62f105d,0xd62f105d,
        0x2441453,0x2441453,0x2441453,0x2441453,
        0xd8a1e681,0xd8a1e681,0xd8a1e681,0xd8a1e681,
        0xe7d3fbc8,0xe7d3fbc8,0xe7d3fbc8,0xe7d3fbc8,
        0x21e1cde6,0x21e1cde6,0x21e1cde6,0x21e1cde6,
        0xc33707d6,0xc33707d6,0xc33707d6,0xc33707d6,
        0xf4d50d87,0xf4d50d87,0xf4d50d87,0xf4d50d87,
        0x455a14ed,0x455a14ed,0x455a14ed,0x455a14ed,
        0xa9e3e905,0xa9e3e905,0xa9e3e905,0xa9e3e905,
        0xfcefa3f8,0xfcefa3f8,0xfcefa3f8,0xfcefa3f8,
        0x676f02d9,0x676f02d9,0x676f02d9,0x676f02d9,
        0x8d2a4c8a,0x8d2a4c8a,0x8d2a4c8a,0x8d2a4c8a,
        0xfffa3942,0xfffa3942,0xfffa3942,0xfffa3942,
        0x8771f681,0x8771f681,0x8771f681,0x8771f681,
        0x6d9d6122,0x6d9d6122,0x6d9d6122,0x6d9d6122,
        0xfde5380c,0xfde5380c,0xfde5380c,0xfde5380c,
        0xa4beea44,0xa4beea44,0xa4beea44,0xa4beea44,
        0x4bdecfa9,0x4bdecfa9,0x4bdecfa9,0x4bdecfa9,
        0xf6bb4b60,0xf6bb4b60,0xf6bb4b60,0xf6bb4b60,
        0xbebfbc70,0xbebfbc70,0xbebfbc70,0xbebfbc70,
        0x289b7ec6,0x289b7ec6,0x289b7ec6,0x289b7ec6,
        0xeaa127fa,0xeaa127fa,0xeaa127fa,0xeaa127fa,
        0xd4ef3085,0xd4ef3085,0xd4ef3085,0xd4ef3085,
        0x4881d05,0x4881d05,0x4881d05,0x4881d05,
        0xd9d4d039,0xd9d4d039,0xd9d4d039,0xd9d4d039,
        0xe6db99e5,0xe6db99e5,0xe6db99e5,0xe6db99e5,
        0x1fa27cf8,0x1fa27cf8,0x1fa27cf8,0x1fa27cf8,
        0xc4ac5665,0xc4ac5665,0xc4ac5665,0xc4ac5665,
        0xf4292244,0xf4292244,0xf4292244,0xf4292244,
        0x432aff97,0x432aff97,0x432aff97,0x432aff97,
        0xab9423a7,0xab9423a7,0xab9423a7,0xab9423a7,
        0xfc93a039,0xfc93a039,0xfc93a039,0xfc93a039,
        0x655b59c3,0x655b59c3,0x655b59c3,0x655b59c3,
        0x8f0ccc92,0x8f0ccc92,0x8f0ccc92,0x8f0ccc92,
        0xffeff47d,0xffeff47d,0xffeff47d,0xffeff47d,
        0x85845dd1,0x85845dd1,0x85845dd1,0x85845dd1,
        0x6fa87e4f,0x6fa87e4f,0x6fa87e4f,0x6fa87e4f,
        0xfe2ce6e0,0xfe2ce6e0,0xfe2ce6e0,0xfe2ce6e0,
        0xa3014314,0xa3014314,0xa3014314,0xa3014314,
        0x4e0811a1,0x4e0811a1,0x4e0811a1,0x4e0811a1,
        0xf7537e82,0xf7537e82,0xf7537e82,0xf7537e82,
        0xbd3af235,0xbd3af235,0xbd3af235,0xbd3af235,
        0x2ad7d2bb,0x2ad7d2bb,0x2ad7d2bb,0x2ad7d2bb,
        0xeb86d391,0xeb86d391,0xeb86d391,0xeb86d391};


int main2(unsigned long long spe_id, unsigned long long program_data_ea, unsigned long long env) 
{
	unsigned tagid = spe_id&31;
	uint32 i,j;

	// get program data
	mfc_get(&pd, program_data_ea, sizeof(spu_program_data), tagid, 0, 0);
	mfc_write_tag_mask(1<<tagid);
	mfc_read_tag_status_all();

	// precompute partial working states based on ihv & partial msg block
	pre_compute(pd.ihv1, pd.ihv2, pd.m1, pd.m2);

	if (pd.collisiondata > 0)
	{
		j = pd.collisiondata*8;
		vec_uint32* bufferptr = &buffer[j];

		// get the trail buffer
		for (i = 0; i < j; i += 128)
			mfc_get(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
		mfc_write_tag_mask(1<<tagid);
		mfc_read_tag_status_all();

		// process collision trails
		
		reduce_trails(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);
		reduce_trails2(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);
		find_coll(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);

		// store the trail buffer
		for (i = 0; i < j; i += 128)
			mfc_put(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
		mfc_write_tag_mask(1<<tagid);
		mfc_read_tag_status_all();
	} else {
		// fill the trail buffer in steps and do intermediate DMA transfers
		vec_uint32* bufferptr = &buffer[0];
		for (i = 0; i < BUFFERSIZE; i += 256)
		{
			bufferptr = generate_trails(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, bufferptr, &buffer[i+256]);
			mfc_put(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
			mfc_put(&buffer[i+128], &pd.buffer[i+128], sizeof(vec_uint32)*128, tagid, 0, 0);
		}
	}
	// transfer the current program data back
	mfc_put(&pd, program_data_ea, sizeof(spu_program_data), tagid, 0, 0);

	// wait for dma transfers to complete
	mfc_write_tag_mask(1<<tagid);
	mfc_read_tag_status_all();
	return 0;
}

int main2mod(unsigned long long spe_id, unsigned long long program_data_ea, unsigned long long env) 
{
	unsigned tagid = spe_id&31;
	uint32 i,j;

	// get program data
	mfc_get(&pd, program_data_ea, sizeof(spu_program_data), tagid, 0, 0);
	mfc_write_tag_mask(1<<tagid);
	mfc_read_tag_status_all();

	// precompute partial working states based on ihv & partial msg block
	pre_compute(pd.ihv1, pd.ihv2, pd.m1, pd.m2);

	if (pd.collisiondata > 0)
	{
		j = pd.collisiondata*8;
		vec_uint32* bufferptr = &buffer[j];

		// get the trail buffer
		for (i = 0; i < j; i += 128)
			mfc_get(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
		mfc_write_tag_mask(1<<tagid);
		mfc_read_tag_status_all();

		// process collision trails
		
		reduce_trailsmod(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);
		reduce_trails2mod(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);
		find_collmod(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, &buffer[0], bufferptr);

		// store the trail buffer
		for (i = 0; i < j; i += 128)
			mfc_put(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
		mfc_write_tag_mask(1<<tagid);
		mfc_read_tag_status_all();
	} else {
		// fill the trail buffer in steps and do intermediate DMA transfers
		vec_uint32* bufferptr = &buffer[0];
		for (i = 0; i < BUFFERSIZE; i += 256)
		{
			bufferptr = generate_trailsmod(pd.ihv1, pd.ihv2mod, pd.m1, pd.m2, &pd.astart, bufferptr, &buffer[i+256]);
			mfc_put(&buffer[i], &pd.buffer[i], sizeof(vec_uint32)*128, tagid, 0, 0);
			mfc_put(&buffer[i+128], &pd.buffer[i+128], sizeof(vec_uint32)*128, tagid, 0, 0);
		}
	}
	// transfer the current program data back
	mfc_put(&pd, program_data_ea, sizeof(spu_program_data), tagid, 0, 0);

	// wait for dma transfers to complete
	mfc_write_tag_mask(1<<tagid);
	mfc_read_tag_status_all();
	return 0;
}

int main(unsigned long long spe_id, unsigned long long program_data_ea, unsigned long long env) 
{
	spu_write_out_mbox(SPE_BIRTHDAY_INITIALIZED);
	while (1) {
		unsigned int msg = spu_read_in_mbox();
		switch (msg) {
		case SPE_BIRTHDAY_START:
			main2(spe_id, program_data_ea, env);
			spu_write_out_mbox(SPE_BIRTHDAY_FINISHED);
			break;
		case SPE_BIRTHDAY_STARTMOD:
			main2mod(spe_id, program_data_ea, env);
			spu_write_out_mbox(SPE_BIRTHDAY_FINISHED);
			break;
		case SPE_BIRTHDAY_QUIT:
			return 0;
		}
	}
}
