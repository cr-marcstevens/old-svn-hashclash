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

#ifndef HASHUTIL5_AUTOLINK_HPP
#define HASHUTIL5_AUTOLINK_HPP
#ifndef HASHUTIL5_NOAUTOLINK

#define HASHUTIL5_QUIET

#ifndef HASHUTIL5_QUIET
#ifndef BOOST_LIB_DIAGNOSTIC
#define BOOST_LIB_DIAGNOSTIC
#endif
#endif

#include <boost/config.hpp>
#include <boost/version.hpp>

#ifndef HASHUTIL5_QUIET
#ifdef __GNUC__
#warning "Library HashUtil version 5"
#else
#pragma message("Library HashUtil version 5 (Boost version " BOOST_LIB_VERSION ")")
#endif
#endif

#ifndef HASHUTIL5_BUILD
#ifdef WIN32
#ifdef _DEBUG

#if defined(_MT) || defined(__MT__)
#ifdef _DLL
#pragma comment(lib, "hashutil5-mt-gd.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-mt-gd.lib")
#endif
#else
#pragma comment(lib, "hashutil5-mt-sgd.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-mt-sgd.lib")
#endif
#endif
#else
#pragma comment(lib, "hashutil5-sgd.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-sgd.lib")
#endif
#endif // MT

#else // _DEBUG

#if defined(_MT) || defined(__MT__)
#ifdef _DLL
#pragma comment(lib, "hashutil5-mt.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-mt.lib")
#endif
#else
#pragma comment(lib, "hashutil5-mt-s.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-mt-s.lib")
#endif
#endif
#else
#pragma comment(lib, "hashutil5-s.lib")
#ifndef HASHUTIL5_QUIET
#pragma message("Linking to lib file: hashutil5-s.lib")
#endif
#endif // MT

#endif // _DEBUG
#endif // WIN32
#endif // HASHUTIL5_BUILD

#endif // HASHUTIL5_NOAUTOLINK
#endif // HASHUTIL5_AUTOLINK_HPP
