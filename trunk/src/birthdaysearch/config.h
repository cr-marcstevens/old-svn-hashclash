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

#ifndef CONFIG_H
#define CONFIG_H

#if ! defined(__SPU__)
#if ! ( defined(_MT) || defined(__MT__) || defined(_REENTRANT) || defined(_PTHREADS) )
#error "Threads required!"
#endif
#endif

#ifdef CUDA
#ifdef __GNUC__
#warning "CUDA enabled."
#else
#pragma message("CUDA enabled.")
#endif
#endif

#if defined(__SPU__) || defined(__PPU__) || defined(__PPC__)
#ifdef USE_CELL

#define CELL
#ifdef __GNUC__
#warning "Cell processing enabled."
#else // __GNUC__
#pragma message("Cell processing enabled.")
#endif // __GNUC__

#else // USE_CELL

#ifdef __GNUC__
#warning "Cell processing might be possible but is NOT enabled."
#else // __GNUC__
#pragma message("Cell processing might be possible but is NOT enabled.")
#endif // __GNUC__

#endif // USE_CELL
#else
#ifdef USE_CELL
#error "Cell processing not supported!"
#endif
#endif // __SPU__ __PPU__

#endif // CONFIG_H
