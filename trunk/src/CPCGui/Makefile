# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

DEST            = ../cpcgui
OBJECTS         = birthdaysearch_page.o  main.o  mainwindow.o  nearcollision_page.o  project_configurator.o  project_data.o  run_program.o  startnearcollision.o  startpage.o  startprojectdialog.o  textviewfollowfile.o
HEADERS         = birthdaysearch_page.hpp  mainwindow.hpp  nearcollision_page.hpp  project_configurator.hpp  project_data.hpp  run_program.hpp  startnearcollision.hpp  startpage.hpp  startprojectdialog.hpp  textviewfollowfile.hpp
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

test:
	@(echo "#include <gtkmm.h>" | $(CPP) $(CPPFLAGS) $(DESTFLAGS) -I. -I.. -x c++ -c - 2>/dev/null >/dev/null) || echo "Not building cpcgui: GTKMM not found." && false