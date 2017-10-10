# Use local settings for CPP, CPPFLAGS
include ../Makefile.local

### CELL specific defines
PPU_AR = ar
PPU_OBJDUMP = objdump
PPU_LIBS = -lspe
SPU_CC = spu-elf-gcc -O2 -s    
SPU_AS = spu-elf-gcc -c -O3 -s
SPU_LINK = spu-elf-gcc -s
SPU_STRIP = spu-elf-strip
SPU_OBJDUMP = spu-elf-objdump
SPU_TIMING = spu_timing
EMBED_SPU = powerpc-unknown-linux-gnu-embedspu -m64
SDEST = spe_birthday
SOBJECTS = spe_md5.o spe_asm.o spe_asm2.o spe_asm3.o spe_asmmod.o spe_asm2mod.o spe_asm3mod.o
SHEADERS = spu_program_data.hpp

DEST            = ../md5birthdaysearch
OBJECTS         = main.o dostep.o birthday.o storage.o ppe_main.o
HEADERS         = config.h birthday_types.hpp distribution.hpp main.hpp spu_program_data.hpp storage.hpp
DESTFLAGS       =
LIBS            ?= -lhashutil5-mt -lpthread -lboost_iostreams$(SBL) -lboost_serialization$(SBL) -lboost_filesystem$(SBL) -lboost_program_options$(SBL) -lboost_thread$(SBL) -lboost_system$(SBL) -lbz2 -lz -lrt
MKPROPER        = *~


all: $(DEST)$(CELLSUFFIX)

run: all
	time ./$(DEST)$(CELLSUFFIX)

clean:
	rm -f $(DEST) $(DEST)$(CELLSUFFIX) $(OBJECTS) $(SOBJECTS) $(SDEST).{elf,stripped,a} *.S.asm *.S.timing *.S.txt

proper: clean
	rm -f $(MKPROPER)

%.o: %.cpp $(HEADERS)
	$(CPP) $(CPPFLAGS) -DSPE_HANDLE=$(SDEST) $(DESTFLAGS) -c $<

$(DEST): $(OBJECTS)
	$(CPP) $(CPPFLAGS) $(DESTFLAGS) -o $(DEST) $(OBJECTS) $(LIBS)

### CELL specific targets
$(DEST)_cell: $(OBJECTS) $(SDEST).a
	$(CPP) -o $@ $^ $(LIBS) $(PPU_LIBS)

$(SDEST).a: $(SOBJECTS)
	$(SPU_LINK) -o $(SDEST) $^
	$(SPU_STRIP) $(SDEST) -o $(SDEST).stripped
	$(EMBED_SPU) $(SDEST) $(SDEST).stripped $(SDEST).elf
	$(PPU_AR) r $(SDEST).a $(SDEST).elf

spe_%.o: spe_%.S
	$(SPU_AS) $< -o $@

spe_%.o: spe_%.c $(SHEADERS)
	$(SPU_CC) -c $<

spe_%.S.asm: spe_%.o
	$(SPU_OBJDUMP) -d $< > $@
spe_%.S.timing: spe_%.o
	$(SPU_OBJDUMP) --no-show-raw-insn -d $< | cut -d: -f2- | grep -v "file format" | $(SPU_TIMING) > $@ && less $@
spe_%.S.txt: spe_%.o
	$(SPU_OBJDUMP) --no-show-raw-insn -d $< | cut -d: -f2- | grep -v "file format" | cut -d'#' -f1 > $@
