# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

DEST            = ../md5diffpathbackward
OBJECTS         = main.o dostep.o backward.o
HEADERS         = main.hpp
DESTFLAGS       =  
LIBS            ?= -lhashutil5-mt -lpthread -lboost_serialization$(SBL) -lboost_filesystem$(SBL) -lboost_program_options$(SBL) -lboost_iostreams$(SBL) -lboost_system$(SBL) -lboost_thread$(SBL) -lbz2 -lz -lrt
MKPROPER        = *~


all: $(DEST)

run: all
	time ./$(DEST)

clean:
	rm -f $(DEST) $(OBJECTS)

proper: clean
	rm -f $(MKPROPER)

%.o: %.cpp $(HEADERS)
	$(CPP) $(CPPFLAGS) $(DESTFLAGS) -c $<

$(DEST): $(OBJECTS)
	$(CPP) $(CPPFLAGS) $(DESTFLAGS) -o $(DEST) $(OBJECTS) $(LIBS)
