# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

DEST              = libhashutil5-mt.a # libhashutil.a libhashutil5-d.a libhashutil5-mtd.a
HUFLAGS           = -DHASHUTIL5_BUILD
HEADERS           = autolink.hpp booleanfunction.hpp cpuperformance.hpp md5detail.hpp rng.hpp saveload_gz.hpp sdr.hpp sha1differentialpath.hpp timer.hpp bestof.hpp conditions.hpp differentialpath.hpp progress_display.hpp saveload_bz2.hpp saveload.hpp sha1detail.hpp sha1messagespace.hpp types.hpp
OBJECTS           = booleanfunction-st.o conditions-st.o differentialpath-st.o md5detail-st.o rng-st.o sdr-st.o timer-st.o sha1detail-st.o sha1differentialpath-st.o sha1messagespace-st.o
OBJECTS_MT        = booleanfunction-mt.o conditions-mt.o differentialpath-mt.o md5detail-mt.o rng-mt.o sdr-mt.o timer-mt.o sha1detail-mt.o sha1differentialpath-mt.o sha1messagespace-mt.o
OBJECTS_D         = booleanfunction-std.o conditions-std.o differentialpath-std.o md5detail-std.o rng-std.o sdr-std.o timer-std.o sha1detail-std.o sha1differentialpath-std.o sha1messagespace-std.o
OBJECTS_MTD       = booleanfunction-mtd.o conditions-mtd.o differentialpath-mtd.o md5detail-mtd.o rng-mtd.o sdr-mtd.o timer-mtd.o sha1detail-mtd.o sha1differentialpath-mtd.o sha1messagespace-mtd.o

all: $(DEST)
	
clean:
	rm -f $(OBJECTS) $(OBJECTS_MT) $(OBJECTS_D) $(OBJECTS_MTD) $(DEST)
	
proper: clean
	rm -f *~

libhashutil5.a: $(OBJECTS)
	ar rcs $@ $(OBJECTS)

libhashutil5-mt.a: $(OBJECTS_MT)
	ar rcs $@ $(OBJECTS_MT)

libhashutil5-d.a: $(OBJECTS_D)
	ar rcs $@ $(OBJECTS_D)

libhashutil5-mtd.a: $(OBJECTS_MTD)
	ar rcs $@ $(OBJECTS_MTD)

%-st.o: hashutil5/%.cpp
	$(CPP) $(CPPFLAGS) $(HUFLAGS) -c $< -o $@

%-mt.o: hashutil5/%.cpp
	$(CPP) $(CPPFLAGS) $(HUFLAGS) -pthread -c $< -o $@

%-std.o: hashutil5/%.cpp
	$(CPP) $(CPPFLAGSD) $(HUFLAGS) -c $< -o $@

%-mtd.o: hashutil5/%.cpp
	$(CPP) $(CPPFLAGSD) $(HUFLAGS) -pthread -c $< -o $@
