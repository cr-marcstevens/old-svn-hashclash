include Makefile.local

.PHONY: libhashutil5 birthdaysearch birthdaysearch_cuda diffpathforward diffpathbackward diffpathconnect diffpathhelper cpcgui md5_uc_helper
.PHONY: diffpathforward_sha1 diffpathbackward_sha1 diffpathconnect_sha1 diffpathhelper_sha1 diffpathcollfind_sha1 diffpathanalysis_sha1 collfind_sha1
.PHONY: all test proper clean boost boost-wget-untar boost-build boost-strip

all: libhashutil5 birthdaysearch diffpathforward diffpathbackward diffpathconnect diffpathhelper diffpathforward_sha1 diffpathbackward_sha1 diffpathconnect_sha1 diffpathhelper_sha1 diffpathcollfind_sha1 collfind_sha1 birthdaysearch_cuda diffpathanalysis_sha1 cpcgui md5_uc_helper

libhashutil5: test
	@cd libhashutil5 && $(MAKE)

birthdaysearch: libhashutil5
	@cd birthdaysearch && $(MAKE)

birthdaysearch_cuda: libhashutil5
	@(cd birthdaysearch && test -n "$(CUDA_TK)" && $(MAKE) -f Makefile.cuda || echo) || echo "Not building birthdaysearch_cuda: CUDA Disabled."
	
diffpathforward: libhashutil5
	@cd diffpathforward && $(MAKE)

diffpathbackward: libhashutil5
	@cd diffpathbackward && $(MAKE)

diffpathconnect: libhashutil5
	@cd diffpathconnect && $(MAKE)

diffpathhelper: libhashutil5
	@cd diffpathhelper && $(MAKE)

md5_uc_helper: libhashutil5
	@cd md5_uc_helper && $(MAKE)
	
cpcgui: libhashutil5
	@(cd CPCGui && $(MAKE) test && $(MAKE) || echo) || echo "Not building cpcgui: GTKMM not found."

diffpathforward_sha1: libhashutil5
	@cd diffpathforward_sha1 && $(MAKE)

diffpathbackward_sha1: libhashutil5
	@cd diffpathbackward_sha1 && $(MAKE)

diffpathconnect_sha1: libhashutil5
	@cd diffpathconnect_sha1 && $(MAKE)

diffpathhelper_sha1: libhashutil5
	@cd diffpathhelper_sha1 && $(MAKE)

diffpathanalysis_sha1: libhashutil5
	@(cd diffpathanalysis_sha1 && test -n "$(CUDA_TK)" && $(MAKE) || echo) || echo "Not building diffpathanalysis_sha1: CUDA Disabled."
	
diffpathcollfind_sha1: libhashutil5
	@cd diffpathcollfind_sha1 && $(MAKE)
	
collfind_sha1: libhashutil5
	@cd diffpathcollfind_sha1 && $(MAKE) -f Makefile.collfind
	
proper clean:
	cd libhashutil5 && $(MAKE) $@
	cd birthdaysearch && $(MAKE) $@
	cd birthdaysearch && $(MAKE) -f Makefile.cuda $@
	cd diffpathforward && $(MAKE) $@
	cd diffpathbackward && $(MAKE) $@
	cd diffpathconnect && $(MAKE) $@
	cd diffpathhelper && $(MAKE) $@
	cd md5_uc_helper && $(MAKE) $@
	cd diffpathforward_sha1 && $(MAKE) $@
	cd diffpathbackward_sha1 && $(MAKE) $@
	cd diffpathconnect_sha1 && $(MAKE) $@
	cd diffpathanalysis_sha1 && $(MAKE) $@
	cd diffpathhelper_sha1 && $(MAKE) $@
	cd diffpathcollfind_sha1 && $(MAKE) $@
	cd diffpathcollfind_sha1 && $(MAKE) -f Makefile.collfind $@

boost-once:
	[ -d boost_$(BOOST_LIBVER)/stage/lib ] || $(MAKE) boost
	
boost: boost-wget-untar boost-build boost-strip

boost-wget-untar:
	[ -f boost_$(BOOST_LIBVER).tar.bz2 ] || \
	   wget -c https://hashclash.googlecode.com/files/boost_$(BOOST_LIBVER).tar.bz2 || \
	   wget -c http://sourceforge.net/projects/boost/files/boost/`echo $(BOOST_LIBVER) | tr '_' '.'`/boost_$(BOOST_LIBVER).tar.bz2 || \
	   (echo "ERROR: manually download boost_$(BOOST_LIBVER).tar.bz2 !!"; false)
	tar -xjvf boost_$(BOOST_LIBVER).tar.bz2

boost-build:
	cd boost_$(BOOST_LIBVER) && \
	./bootstrap.sh --with-libraries=date_time,filesystem,iostreams,program_options,serialization,system,thread && \
	./bjam cxxflags="$(CPPFLAGS)" release threading=multi

boost-strip:
	cd boost_$(BOOST_LIBVER) && \
	rm -rf `ls | grep -v boost | grep -v stage` && \
	rm boost* 2>/dev/null || true

test:
	@cd libhashutil5 && \
	(echo "#include <boost/cstdint.hpp>" | $(CPP) $(CPPFLAGS) -x c++ -c - -o /dev/null 2>/dev/null >/dev/null) || \
	(echo "ERROR: Cannot compile with your current configuration in Makefile.local:" && (echo "#include <boost/cstdint.hpp>" | $(CPP) $(CPPFLAGS) -x c++ -c - -o /dev/null ))
