#
# race-od for the RetroFW
#
# by pingflood; 2019
#

TARGET = race-od/race-od.dge

CHAINPREFIX := /opt/mipsel-RetroFW-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC			:= $(CROSS_COMPILE)gcc
LD			:= $(CROSS_COMPILE)g++

SYSROOT     := $(shell $(CC) --print-sysroot)
SDL_CFLAGS  := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS    := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)


F_OPTS = -falign-functions -falign-loops -falign-labels -falign-jumps \
		-ffast-math -fsingle-precision-constant -funsafe-math-optimizations \
		-fomit-frame-pointer -fno-builtin -fno-common \
		-fstrict-aliasing  -fexpensive-optimizations \
		-finline -finline-functions -fpeel-loops

CC_OPTS		= -O3 -mips32 -G0 -D_OPENDINGUX_ $(F_OPTS)
CFLAGS      = -Iemu -Iopendingux $(SDL_CFLAGS) -DOPENDINGUX -DCZ80 -DTARGET_OD -D_MAX_PATH=2048 -DHOST_FPS=60 $(CC_OPTS)
CXXFLAGS	= $(CFLAGS)
LDFLAGS     = $(SDL_LIBS) $(CC_OPTS) -lstdc++ -lSDL -lSDL_image -lSDL_mixer -lSDL_ttf -lpng -lz

BUILD_EMUL  =	emu/cz80.o \
				emu/cz80_support.o \
				emu/input.o \
				emu/neopopsound.o \
				emu/ngpBios.o \
				emu/tlcs900h.o \
				emu/memory.o \
				emu/flash.o \
				emu/graphics.o \
				emu/main.o \
				emu/state.o \
				emu/sound.o

BUILD_MZ = emu/ioapi.o emu/unzip.o
BUILD_PORT = opendingux/main.o opendingux/menu.o

OBJS = $(BUILD_EMUL) $(BUILD_PORT)


# Rules to make executable
all: $(OBJS) $(BUILD_MZ)
	$(LD) -o $(TARGET) $^ $(LDFLAGS)

$(OBJS): %.o : %.cpp
	$(CC) $(CXXFLAGS) -c -o $@ $<

$(BUILD_MZ): %.o : %.c
	$(CC) $(CXXFLAGS) -c -o $@ $<

ipk: all
	@rm -rf /tmp/.race-od-ipk/ && mkdir -p /tmp/.race-od-ipk/root/home/retrofw/emus/race-od /tmp/.race-od-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators /tmp/.race-od-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators.systems
	@cp -r race-od/race-od.dge race-od/race-od.png race-od/backdrop.png race-od/skin.png race-od/race-od.man.txt /tmp/.race-od-ipk/root/home/retrofw/emus/race-od
	@cp race-od/race-od.lnk /tmp/.race-od-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators
	@cp race-od/ngp.race-od.lnk /tmp/.race-od-ipk/root/home/retrofw/apps/gmenu2x/sections/emulators.systems
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" race-od/control > /tmp/.race-od-ipk/control
	@cp race-od/conffiles /tmp/.race-od-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.race-od-ipk/control.tar.gz -C /tmp/.race-od-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.race-od-ipk/data.tar.gz -C /tmp/.race-od-ipk/root/ .
	@echo 2.0 > /tmp/.race-od-ipk/debian-binary
	@ar r race-od/race-od.ipk /tmp/.race-od-ipk/control.tar.gz /tmp/.race-od-ipk/data.tar.gz /tmp/.race-od-ipk/debian-binary

opk: all
	@mksquashfs \
	race-od/default.retrofw.desktop \
	race-od/ngp.retrofw.desktop \
	race-od/race-od.dge \
	race-od/race-od.png \
	race-od/race-od.man.txt \
	race-od/backdrop.png \
	race-od/skin.png \
	race-od/race-od.opk \
	-all-root -noappend -no-exports -no-xattrs

clean:
	rm -f $(TARGET) *.o emu/*.o opendingux/*.o
