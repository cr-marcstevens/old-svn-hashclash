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

#include <iostream>
#include "sha1_lctobitconditions.hpp"
#include <hashutil5/saveload_bz2.hpp>
#include <hashutil5/progress_display.hpp>

using namespace std;
namespace hash {


	void path_to_qtmask(const sha1differentialpath& path, uint32* qtmask, uint32* qtset1, uint32* qtprev, uint32* qtprev2)
	{
		memset(qtmask, ~uint32(0), sizeof(uint32)*85);
		memset(qtset1, 0, sizeof(uint32)*85);
		memset(qtprev, 0, sizeof(uint32)*85);
		memset(qtprev2, 0, sizeof(uint32)*85);
		for (int t = path.tbegin(); t < path.tend(); ++t) {
			qtmask[4+t] = ~ path[t].mask();
			qtset1[4+t] = path[t].set1() | path[t].prevn() | path[t].prev2n();
			qtprev[4+t] = path[t].prev() | path[t].prevn();
			qtprev2[4+t] = path[t].prev2() | path[t].prev2n();
		}
	}

	double path_prob(cuda_device& cd, const localcollision_combiner& lccombiner, const sha1differentialpath& path, int tbegin, int tend)
	{
		static uint32 qtmask[85];
		static uint32 qtset1[85];
		static uint32 qtprev[85];
		static uint32 qtprev2[85];
		path_to_qtmask(path, qtmask, qtset1, qtprev, qtprev2);
		cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft, qtmask, qtset1, qtprev, qtprev2);
		return cd.path_analysis(tbegin, tend, true);
	}

	void determine_Dft_conditions(cuda_device& cd, const localcollision_combiner& lccombiner, sha1differentialpath& path, int tbegin, int tend, int t, sdr dFt)
	{
		map<sdr, uint32> sdrcnt;
		samples_type::const_iterator cit, citend;
		booleanfunction* f = 0;
		if (t < 20) f = &SHA1_F1_data;
		else if (t < 40) f = &SHA1_F2_data;
		else if (t < 60) f = &SHA1_F3_data;
		else f = &SHA1_F4_data;
		for (unsigned b = 0; b < 32; ++b)
		{
			bitcondition qtm1 = path(t-1,b), qtm2 = path(t-2,(b+2)&31), qtm3 = path(t-3,(b+2)&31);
			if (qtm1 == bc_prev || qtm1 == bc_prevn)
			{
				bitcondition qtm1b = bc_constant;
				bf_outcome bo = f->outcome(qtm1, qtm2, qtm3);
				if (bo.size() == 1) continue;

				cout << t << "," << b << ":\t UNIMPLEMENTED CASE: ^ or ! on path(t-1,b)" << endl;

			} else {
				bf_outcome bo = f->outcome(qtm1, qtm2, qtm3);
				if (bo.size() == 1) continue;
				if (b == 31 && bo.size() == 2 && bo(0,31) == bo(1,31)) continue;
				if (b == 31 && bo.size() == 3) {
					bf_conditions bf = f->backwardconditions(qtm1, qtm2, qtm3, bc_constant);
					if (bf.second != qtm2 && bf.first == qtm1 && bf.third == qtm3) {
						if (bf.second == bc_prev) {							
							path.setbitcondition(t-1, b, bf.first);
							path.setbitcondition(t-2, (b+2)&31, bc_prevn);
							path.setbitcondition(t-3, (b+2)&31, bf.third);
							//cout << t << "," << b << ":\t" << qtm1 << qtm2 << qtm3 << "=>" << bf.first << bc_prevn << bf.third << endl;
						} else if (bf.second == bc_prevn) {							
							path.setbitcondition(t-1, b, bf.first);
							path.setbitcondition(t-2, (b+2)&31, bc_prev);
							path.setbitcondition(t-3, (b+2)&31, bf.third);
							//cout << t << "," << b << ":\t" << qtm1 << qtm2 << qtm3 << "=>" << bf.first << bc_prev << bf.third << endl;
						}
					}
				}
				
				bf_conditions bf;
				if (dFt[b] == -1) bf = f->backwardconditions(qtm1, qtm2, qtm3, bc_minus);
				if (dFt[b] == +1) bf = f->backwardconditions(qtm1, qtm2, qtm3, bc_plus);
				if (dFt[b] ==  0) bf = f->backwardconditions(qtm1, qtm2, qtm3, bc_constant);								
				if (bf.first == bc_prev || bf.first == bc_prevn) {
					path.setbitcondition(t-1, b, bc_zero);
					path.setbitcondition(t-2, (b+2)&31, bf.first == bc_prev ? bc_zero : bc_one);
					path.setbitcondition(t-3, (b+2)&31, bf.third);
					double gain_zero = path_prob(cd, lccombiner, path, tbegin, tend);
					path.setbitcondition(t-1, b, bc_one);
					path.setbitcondition(t-2, (b+2)&31, bf.first == bc_prevn ? bc_zero : bc_one);
					path.setbitcondition(t-3, (b+2)&31, bf.third);
					double gain_one = path_prob(cd, lccombiner, path, tbegin, tend);
					if (gain_zero > gain_one) {
						path.setbitcondition(t-1, b, bc_zero);
						path.setbitcondition(t-2, (b+2)&31, bf.first == bc_prev ? bc_zero : bc_one);
						path.setbitcondition(t-3, (b+2)&31, bf.third);
						//cout << t << "," << b << ":\t" << qtm1 << qtm2 << qtm3 << "=>" << bc_zero << (bc_prev ? bc_zero : bc_one) << bf.third << endl;
					} else {
						path.setbitcondition(t-1, b, bc_one);
						path.setbitcondition(t-2, (b+2)&31, bf.first == bc_prevn ? bc_zero : bc_one);
						path.setbitcondition(t-3, (b+2)&31, bf.third);
						//cout << t << "," << b << ":\t" << qtm1 << qtm2 << qtm3 << "=>" << bc_one << (bc_prevn ? bc_zero : bc_one) << bf.third << endl;
					}
				} else {
					path.setbitcondition(t-1, b, bf.first);
					path.setbitcondition(t-2, (b+2)&31, bf.second);
					path.setbitcondition(t-3, (b+2)&31, bf.third);
					//cout << t << "," << b << ":\t" << qtm1 << qtm2 << qtm3 << "=>" << bf.first << bf.second << bf.third << endl;
				}
			}
		}
	}

	void determine_Dft(cuda_device& cd, const localcollision_combiner& lccombiner, sha1differentialpath& path, int tbegin, int tend, bool verbose)
	{
		map<sdr, uint32> sdrcnt;
		samples_type::const_iterator cit, citend;
		static uint32 qtmask[85];
		static uint32 qtset1[85];
		static uint32 qtprev[85];
		static uint32 qtprev2[85];
		static uint32 qtmasktmp[85];
		static uint32 qtset1tmp[85];
		static uint32 qtprevtmp[85];
		static uint32 qtprev2tmp[85];
		std::ostream nullstream(0);
		progress_display pd(tend-tbegin,true,verbose?cout:nullstream);
		for (int tt = tend-1; tt >= tbegin; --tt,++pd) {
			path_to_qtmask(path, qtmask, qtset1, qtprev, qtprev2);
			cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft, qtmask, qtset1, qtprev, qtprev2);

			bool outuse1 = true; // for init_samples always: outuse1 = true
			cd.init_samples(tbegin, true, bool(tend>tbegin+1), true); 
			outuse1 = !outuse1;
			for (unsigned t = tbegin; t <= tt; ++t) {
				cd.run_step(t, true, bool(tend>t+2), outuse1, true); 
				outuse1 = !outuse1;
			}
			cd.gather_samples(mysamples, !outuse1);
			sdrcnt.clear();
			cit = mysamples.begin(); citend = mysamples.end();
			if (tt < 20) {
				for (; cit != citend; ++cit) {
					uint32 f1 = sha1_f1(rotate_right(cit.qtm2(),30), cit.qtm3(), cit.qtm4());
					uint32 f2 = sha1_f1(rotate_right(cit.qtm2b(),30), cit.qtm3b(), cit.qtm4b());
					++sdrcnt[ sdr(f1,f2) ];
				}
			} else if (tt < 40) {
				for (; cit != citend; ++cit) {
					uint32 f1 = sha1_f2(rotate_right(cit.qtm2(),30), cit.qtm3(), cit.qtm4());
					uint32 f2 = sha1_f2(rotate_right(cit.qtm2b(),30), cit.qtm3b(), cit.qtm4b());
					++sdrcnt[ sdr(f1,f2) ];
				}
			} else if (tt < 60) {
				for (; cit != citend; ++cit) {
					uint32 f1 = sha1_f3(rotate_right(cit.qtm2(),30), cit.qtm3(), cit.qtm4());
					uint32 f2 = sha1_f3(rotate_right(cit.qtm2b(),30), cit.qtm3b(), cit.qtm4b());
					++sdrcnt[ sdr(f1,f2) ];
				}
			} else if (tt < 80) {
				for (; cit != citend; ++cit) {
					uint32 f1 = sha1_f4(rotate_right(cit.qtm2(),30), cit.qtm3(), cit.qtm4());
					uint32 f2 = sha1_f4(rotate_right(cit.qtm2b(),30), cit.qtm3b(), cit.qtm4b());
					++sdrcnt[ sdr(f1,f2) ];
				}
			}
			double best_prob = -262144;
			sha1differentialpath best_path;
			for (map<sdr, uint32>::const_iterator it = sdrcnt.begin(); it != sdrcnt.end(); ++it)
			{
				sha1differentialpath tmppath = path;
				determine_Dft_conditions(cd, lccombiner, tmppath, tbegin, tend, tt, it->first);
				if (sdrcnt.size() == 1) {
					best_prob = 0;
					best_path = tmppath;
					break;
				}
				double pathprob = log(path_prob(cd, lccombiner, tmppath, tbegin, tend))/log(2.0) - double(tmppath.nrcond());
				if (pathprob > best_prob) {
					best_prob = pathprob;
					best_path = tmppath;
				}
			}
			path = best_path;
		}
	}

	void determine_Dqt(cuda_device& cd, const localcollision_combiner& lccombiner, sha1differentialpath& path, int tbegin, int tend, bool verbose)
	{
		path.clear();
		map<sdr, uint32> sdrcnt;
		samples_type::const_iterator cit, citend;
		static uint32 qtmask[85];
		static uint32 qtset1[85];
		static uint32 qtprev[85];
		static uint32 qtprev2[85];
		static uint32 qtmasktmp[85];
		static uint32 qtset1tmp[85];
		static uint32 qtprevtmp[85];
		static uint32 qtprev2tmp[85];
		memset(qtmask, ~uint32(0), sizeof(qtmask));
		memset(qtset1, 0, sizeof(qtset1));
		memset(qtprev, 0, sizeof(qtprev));
		memset(qtprev2, 0, sizeof(qtprev2));
		for (int tt = tbegin; tt < tend; ++tt) 
			path.getme(tt) = naf(lccombiner.dme[tt]);

		std::ostream nullstream(0);
		progress_display pd((tend+1) - (tbegin-4),true,verbose?cout:nullstream);
		for (int tt = tbegin-4; tt < tend+1; ++tt,++pd) 
			if (lccombiner.dqt[4+tt] != 0)
			{
				cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft, qtmask, qtset1, qtprev, qtprev2);
				double prob = 0;

				bool outuse1 = true; // for init_samples always: outuse1 = true
				cd.init_samples_fast(tbegin, true, bool(tend>tbegin+1), true); 
				outuse1 = !outuse1;
				for (unsigned t = tbegin; t < tend && tt+4>t; ++t) {
					cd.run_step_fast(t, true, bool(tend>t+2), outuse1, true); 
					outuse1 = !outuse1;
				}
				cd.gather_samples(mysamples, !outuse1);
				sdrcnt.clear();
				cit = mysamples.begin(); citend = mysamples.end();
				if (tt < tend-3) {
					for (; cit != citend; ++cit)
						++sdrcnt[ sdr(cit.qtm4(),cit.qtm4b()).rotate_left(2) ];
				} else if (tt < tend-2) {
					for (; cit != citend; ++cit)
						++sdrcnt[ sdr(cit.qtm3(),cit.qtm3b()).rotate_left(2) ];
				} else if (tt < tend-1) { 
					for (; cit != citend; ++cit)
						++sdrcnt[ sdr(cit.qtm2(),cit.qtm2b()).rotate_left(2) ];
				} else if (tt < tend) {
					for (; cit != citend; ++cit)
						++sdrcnt[ sdr(cit.qtm1(),cit.qtm1b()) ];
				} else if (tt < tend+1) {
					for (; cit != citend; ++cit)
						++sdrcnt[ sdr(cit.qt(),cit.qtb()) ];
				}
				double best_gain = -100;
				sdr best_sdr;
				if (sdrcnt.size() == 1) {
					best_gain = 1;
					best_sdr = sdrcnt.begin()->first;
				} else {
					prob = cd.path_analysis(tbegin, tend, true);
					for (map<sdr, uint32>::const_iterator it = sdrcnt.begin(); it != sdrcnt.end(); ++it)
					{
						if (it->first.adddiff() != lccombiner.dqt[4+tt]) continue;
						memcpy(qtmasktmp, qtmask, sizeof(qtmask));
						memcpy(qtset1tmp, qtset1, sizeof(qtset1));
						memcpy(qtprevtmp, qtprev, sizeof(qtprev));
						memcpy(qtprev2tmp, qtprev2, sizeof(qtprev2));
						qtmasktmp[4+tt] = ~it->first.mask;
						qtset1tmp[4+tt] = it->first.set1conditions();
						cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft, qtmasktmp, qtset1tmp, qtprevtmp, qtprev2tmp);
						double gain = (log(cd.path_analysis(tbegin, tend, true)/prob)/log(2.0))-double(hw(it->first.mask));
						if (gain > best_gain) {
							best_gain = gain;
							best_sdr = it->first;
						}
					}
				}
				if (best_gain == -100) {
					throw runtime_error("best_gain == -100");
				}
				//cout << tt << " " << sdrcnt.size() << " " << log(prob)/log(2.0) << endl;
				if (lccombiner.dqt[4+tt] != best_sdr.adddiff())
				{
					cout << tt << ": " << naf(lccombiner.dqt[4+tt]) << "!=" << best_sdr << endl;

					prob = cd.path_analysis(tbegin, tend, true);
					for (map<sdr, uint32>::const_iterator it = sdrcnt.begin(); it != sdrcnt.end(); ++it)
					{
						memcpy(qtmasktmp, qtmask, sizeof(qtmask));
						memcpy(qtset1tmp, qtset1, sizeof(qtset1));
						memcpy(qtprevtmp, qtprev, sizeof(qtprev));
						memcpy(qtprev2tmp, qtprev2, sizeof(qtprev2));
						qtmasktmp[4+tt] = ~it->first.mask;
						qtset1tmp[4+tt] = it->first.set1conditions();
						cd.init(lccombiner.dme, lccombiner.dqt, lccombiner.dft, qtmasktmp, qtset1tmp, qtprevtmp, qtprev2tmp);
						double gain = (log(cd.path_analysis(tbegin, tend, true)/prob)/log(2.0))-double(hw(it->first.mask));
						cout << it->first << ": " << gain << endl;
						if (gain > best_gain) {
							best_gain = gain;
							best_sdr = it->first;
						}
					}

					throw;
				}
				qtmask[4+tt] = ~best_sdr.mask;
				qtset1[4+tt] = best_sdr.set1conditions();
				path[tt].set( best_sdr );
				//cout << tt << ": " << path[tt] << endl;
			}
	}

	void determine_bitconditions(cuda_device& cd, const localcollision_combiner& lccombiner, sha1differentialpath& path, unsigned tbegin, unsigned tend, bool verbose)
	{
		if (verbose) {
			cout << "Converting local collisions into differential path..." << endl;
			cout << " * Determining DQt:" << endl;
		}
		determine_Dqt(cd, lccombiner, path, tbegin, tend, verbose);
		if (verbose)
			cout << " * Determining DFt and bitconditions:" << endl;
		determine_Dft(cd, lccombiner, path, tbegin, tend, verbose);
		if (verbose)
			show_path(path);
		double pathprob = path_prob(cd, lccombiner, path, tbegin, tend);
		if (verbose)
			cout << "path prob: " << log(pathprob)/log(2.0) << endl;

		for (int t = tbegin-4; t < tend+1; ++t)
			for (unsigned b = 0; b < 32; ++b)
				if (path(t,b) > bc_minus) {
					bitcondition backup = path(t,b);
					path.setbitcondition(t,b,bc_constant);
					if (path_prob(cd, lccombiner, path, 20, tend) == pathprob) {
						if (verbose)
							cout << "deleted " << t << "," << b << endl;
					} else
						path.setbitcondition(t,b,backup);
				}
		path.compress();
		if (verbose) {
			show_path(path);
			pathprob = path_prob(cd, lccombiner, path, 20, tend);
			cout << "path prob: " << log(pathprob)/log(2.0) << endl;
		}
	}

} // namespace hash
