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

#include "main.hpp"

#ifndef CELL

void cell_fill_trail_buffer(uint32 id, uint64 seed,
							vector<trail_type>& trail_buffer,
							vector< pair<trail_type,trail_type> >& collisions)
{
	trail_buffer.clear();
}
void cell_config()
{
}

#else // CELL

#include <iostream>
#include <vector>
#include <time.h>
#include <errno.h>
#include <stdexcept>

#include <boost/thread/thread.hpp>
#include <boost/lexical_cast.hpp>
#include <hashutil5/timer.hpp>
#include <libspe.h>
#include "spu_program_data.hpp"

extern spe_program_handle_t SPE_HANDLE;
extern uint32 ihv1[4];
extern uint32 ihv2[4];
extern uint32 ihv2mod[4];
extern uint32 msg1[16];
extern uint32 msg2[16];
extern uint32 distinguishedpointmask;
extern uint32 maximumpathlength;
extern uint32 hybridmask;
extern unsigned maxblocks;

vector<bool> initialized(64, false);
vector<vec_uint32*> buffers(64);
vector<speid_t> program_id(64);
spu_program_data program_data[64] __attribute__((aligned(128)));  //aligned for transfer	

void generate_trail(trail_type& trail);
void find_collision(const trail_type& trail1, const trail_type& trail2);
void birthday_step(uint32& a, uint32& b, uint32& c);

void thread_wait(unsigned sec = 1) {
	static uint64 totalwait = 0;
	totalwait += sec;
	cout << "Totalwait: " << sec << endl;
	boost::this_thread::sleep(boost::posix_time::seconds(sec));
}

void spe_wait_init(uint32 id) {
	timer sw(true);
	while (true) {
		if (sw.time() > 60) throw std::runtime_error("spe_wait_init(): time out on initialization of SPU thread!");
		boost::this_thread::sleep(boost::posix_time::millisec(1));
		if (0 != spe_stat_out_mbox(program_id[id]))
			if (SPE_BIRTHDAY_INITIALIZED == spe_read_out_mbox(program_id[id]))
				break;
	}
}

void spe_do_run(uint32 id) {
	if (maxblocks != 1)
		spe_write_in_mbox(program_id[id], SPE_BIRTHDAY_START);
	else
		spe_write_in_mbox(program_id[id], SPE_BIRTHDAY_STARTMOD);
	while (true) {
		boost::this_thread::sleep(boost::posix_time::millisec(1));
		if (0 != spe_stat_out_mbox(program_id[id]))
			if (SPE_BIRTHDAY_FINISHED == spe_read_out_mbox(program_id[id]))
				break;
	}
}

// assuming collisions.size() is a multiple of 4
// any remainder will be lost
unsigned fill_buffer_with_coll(vec_uint32* buffer, uint32 buffersize,
						   vector< pair<trail_type,trail_type> >& collisions)
{
	vec_uint32 a1, b1, c1, len1, a2, b2, c2, len2;

	// calculate how many collisions we are going to store
	uint32 maxcoll = uint32(buffersize / 8) << 2;
	if (maxcoll > collisions.size())
		maxcoll = collisions.size();

	vec_uint32* bufferptr = buffer;
	for (unsigned i = collisions.size()-maxcoll; i+3 < collisions.size(); i += 4)
	{			
		for (unsigned j = 0; j < 4; ++j)
		{
			a1[j] = collisions[i+j].first.start[0];
			b1[j] = collisions[i+j].first.start[1];
			c1[j] = collisions[i+j].first.start[2];
			len1[j] = collisions[i+j].first.len;
			a2[j] = collisions[i+j].second.start[0];
			b2[j] = collisions[i+j].second.start[1];
			c2[j] = collisions[i+j].second.start[2];
			len2[j] = collisions[i+j].second.len;
		}
		bufferptr[0] = a1;
		bufferptr[1] = b1;
		bufferptr[2] = c1;
		bufferptr[3] = len1;
		bufferptr[4] = a2;
		bufferptr[5] = b2;
		bufferptr[6] = c2;
		bufferptr[7] = len2;
		bufferptr += 8;
	}
	// delete the inserted collisions
	collisions.resize(collisions.size()-maxcoll);
	return maxcoll;
}

// assuming collisions.size() is a multiple of 4
// any remainder will be lost
void cell_fill_trail_buffer(uint32 id, uint64 seed,
							vector<trail_type>& trail_buffer,
							vector< pair<trail_type,trail_type> >& collisions)
{	
	if (id >= buffers.size())
		return;	

	spu_program_data& pd = program_data[id];

	trail_buffer.clear();

	if (!initialized[id]) {
		initialized[id] = true;
		vec_uint32* bufferptr = new vec_uint32[BUFFERSIZE+8];
		// align buffer to 128 byte cache line of the Cell Broadband Architecture
		buffers[id] = reinterpret_cast<vec_uint32*>((reinterpret_cast<uint64>(bufferptr)+127)&~uint64(0x7f));

		for (unsigned j = 0; j < 4; ++j)
		{
			pd.rngx[j] = uint32(seed>>32) ^ 0x01017F7F ^ (4*id+j*2+1);
			pd.rngy[j] = uint32(seed) ^ 0x30303030 ^ (16*id+j*2+1);
			pd.rngz[j] = uint32(seed>>32) ^ 0x55550000 ^ (128*id+j*2+1);
			pd.rngw[j] = uint32(seed) ^ 0x0000FFFF ^ (512*id+j*2+1);

			pd.id[j] = 13*id + 2*j + 512;

			// insert instance data based on seed and id
			pd.a[j] = uint32(seed*(id+j+1));
			pd.b[j] = uint32(seed>>32) ^ (123529*id + 42314*j + 256) ^ 0x11114444;
			pd.c[j] = (uint32(seed>>11) ^ (11*id + 577105*j) ^ 0x33335555) & hybridmask;
			pd.len[j] = 0;			
			pd.a2[j] = uint32(seed*(id+j+5));
			pd.b2[j] = uint32(seed>>32) ^ (123529*id + 42319*j + 256) ^ 0x11224444;
			pd.c2[j] = (uint32(seed>>11) ^ (11*id + 577110*j) ^ 0x33445555) & hybridmask;
			pd.len2[j] = 0;			

			// insert global data
			for (unsigned i = 0; i < 4; ++i)
			{
				pd.ihv1[i][j] = ihv1[i];
				pd.ihv2[i][j] = ihv2[i];
				pd.ihv2mod[i][j] = ihv2mod[i];
			}
			for (unsigned i = 0; i < 16; ++i)
			{
				pd.m1[i][j] = msg1[i];
				pd.m2[i][j] = msg2[i];
			}
			pd.maxlen[j] = maximumpathlength;
			pd.dpmask[j] = distinguishedpointmask;
			pd.hybridmask[j] = hybridmask;
		}
		pd.astart = pd.a;
		pd.bstart = pd.b;
		pd.cstart = pd.c;
		pd.astart2 = pd.a2;
		pd.bstart2 = pd.b2;
		pd.cstart2 = pd.c2;

		pd.collisiondata = 0;
		pd.buffer = putptr(buffers[id]);
		program_id[id] = spe_create_thread(0, &SPE_HANDLE, &pd, NULL, -1, 0);
		if (program_id[id] == 0)
			throw runtime_error(("Cannot start SPE-thread" + boost::lexical_cast<string>(id) + "!").c_str() );
		spe_wait_init(id);
	}

	// insert pointer to buffer
	pd.collisiondata = 0;

	if (collisions.size() > 0)
	{	
		while (collisions.size() > 0)
		{
			unsigned colls = fill_buffer_with_coll(buffers[id], BUFFERSIZE, collisions);
			pd.collisiondata = colls>>2;

			spe_do_run(id);

			trail_type trail1, trail2;
			trail1.end[0] = 0; trail2.end[0] = 0;
			vec_uint32* bufferptr = buffers[id];
			for (unsigned i = 0; i+3 < colls; i += 4)
			{
				for (unsigned j = 0; j < 4; ++j)
				{
					trail1.start[0] = bufferptr[0][j];
					trail1.start[1] = bufferptr[1][j];
					trail1.start[2] = bufferptr[2][j];
					trail1.len = bufferptr[3][j];
					trail2.start[0] = bufferptr[4][j];
					trail2.start[1] = bufferptr[5][j];
					trail2.start[2] = bufferptr[6][j];
					trail2.len = bufferptr[7][j];

					// sanity check
					uint32 a1=trail1.start[0], b1=trail1.start[1], c1=trail1.start[2];
					uint32 a2=trail2.start[0], b2=trail2.start[1], c2=trail2.start[2];
					birthday_step(a1, b1, c1);
					birthday_step(a2, b2, c2);
					if (!(a1==a2 && b1==b2 && c1==c2)) {
						cout << "B" << flush;
						// something strange happened, prevent further excessive work
						trail1.len = 1;
						trail2.len = 1;
					}
					find_collision(trail1, trail2);
				}
				bufferptr += 8;
			}
		}
		// signal to thread that collisions were processed
		collisions.resize(1);
		return;
	}

	spe_do_run(id);

	// transfer data from buffer to trail_buffer
	trail_type trail;
	for (unsigned i = 0; i < BUFFERSIZE; i += 2)
	{
		vec_uint32 ablen = buffers[id][i];
		vec_uint32 abstart = buffers[id][i+1];
		uint32 astart = abstart[0];
		uint32 bstart = abstart[1];
		uint32 cstart = abstart[2];
		uint32 a = ablen[0];
		uint32 b = ablen[1];
		uint32 c = ablen[2];
		uint32 len = ablen[3];

		if (len == 0 || len > maximumpathlength) 
		{
			cerr << id << ": " << (i>>1) << " of " << (BUFFERSIZE>>1) << ": len = 0 || len > maxlen!           " << endl;
			continue;
		}
		if (0 != (a & distinguishedpointmask))
		{
			cerr << id << ": " << (i>>1) << " of " << (BUFFERSIZE>>1) << ": endpoint not distinguished point!           " << endl;
			continue;
		}

		trail.start[0] = astart;
		trail.start[1] = bstart;
		trail.start[2] = cstart;
		trail.end[0] = a;
		trail.end[1] = b;
		trail.end[2] = c;
		trail.len = len;

		trail_buffer.push_back(trail);
	}	
};



void cell_config()
{
	cout << "Cell: Number of physical SPU's: " << spe_count_physical_spes() << endl;
}

#endif // CELL

