# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

DEST            = ../md5diffpathconnect
OBJECTS         = main.o dostep.o connect.o
HEADERS         = main.hpp
DESTFLAGS       =  
LIBS            ?= -lhashutil5-mt -lpthread -lboost_serialization$(SBL) -lboost_filesystem$(SBL) -lboost_program_options$(SBL) -lboost_iostreams$(SBL) -lboost_system$(SBL) -lboost_thread$(SBL) -lbz2 -lz -lrt
MKPROPER        = *~


all: $(DEST)

run: all
	./$(DEST)

clean:
	rm -f $(DEST) $(OBJECTS)

proper: clean
	rm -f $(MKPROPER)

%.o: %.cpp $(HEADERS)
	$(CPP) $(CPPFLAGS) $(DESTFLAGS)  -I. -I.. -c $<

$(DEST): $(OBJECTS)
	$(CPP) $(CPPFLAGS) $(DESTFLAGS) -I. -I.. -o $(DEST) $(OBJECTS) $(LIBS)
