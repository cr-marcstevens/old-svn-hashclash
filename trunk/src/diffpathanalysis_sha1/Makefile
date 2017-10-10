# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

DEST            = ../sha1diffpathanalysis_cuda
OBJECTS         = main.o round4_analysis.o sha1_lctobitconditions.o sha1_localcollision.o sha1_path_lc_analysis.o path_prob_analysis_blockatomic.cuda13.o
HEADERS         = 
DESTFLAGS	=  
LIBS            ?= -lhashutil5-mt -lboost_iostreams -lboost_serialization -lboost_filesystem -lboost_program_options -lboost_system -lboost_thread -lpthread -lbz2 -lz -lrt
MKPROPER	= *~


all: $(DEST)

run: all
	./$(DEST)

clean:
	rm -f $(DEST) $(OBJECTS)

proper: clean
	rm -f $(MKPROPER)

%.o: %.cpp
	$(CPP) $(CPPFLAGS) $(DESTFLAGS) -I. -I.. -c $<
%.cuda10.o: %.cu
	$(CUDA_CPP) $(CUDA_CPPFLAGS_10) $(DESTFLAGS)  -I. -I.. -c $< -o $@ || $(CUDA_CPP) $(CUDA_FIX) $(CUDA_CPPFLAGS_10) $(DESTFLAGS)  -I. -I.. -c $< -o $@
%.cuda11.o: %.cu
	$(CUDA_CPP) $(CUDA_CPPFLAGS_11) $(DESTFLAGS)  -I. -I.. -c $< -o $@ || $(CUDA_CPP) $(CUDA_FIX) $(CUDA_CPPFLAGS_11) $(DESTFLAGS)  -I. -I.. -c $< -o $@
%.cuda13.o: %.cu
	$(CUDA_CPP) $(CUDA_CPPFLAGS_13) $(DESTFLAGS)  -I. -I.. -c $< -o $@ || $(CUDA_CPP) $(CUDA_FIX) $(CUDA_CPPFLAGS_13) $(DESTFLAGS)  -I. -I.. -c $< -o $@
%.cuda20.o: %.cu
	$(CUDA_CPP) $(CUDA_CPPFLAGS_20) $(DESTFLAGS)  -I. -I.. -c $< -o $@ || $(CUDA_CPP) $(CUDA_FIX) $(CUDA_CPPFLAGS_20) $(DESTFLAGS)  -I. -I.. -c $< -o $@

$(DEST): $(OBJECTS)
	$(CPP)  $(DESTFLAGS) -o $(DEST) $(OBJECTS) $(LINKFLAGS) $(CUDA_LINKFLAGS) $(LIBS) $(LINKFLAGS) $(CUDA_LINKFLAGS) $(LIBS)
