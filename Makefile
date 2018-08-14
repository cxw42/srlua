# makefile for srlua, modified by cxw

# change these to reflect your Lua installation
LUA= /mingw
LUA_VER= 5.3
LUAINC= $(LUA)/include
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin
LUASHARE= $(LUA)/share/lua/$(LUA_VER)

# Set to -g to enable debugging
G=-g -D_DEBUG -O0

# probably no need to change anything below here

# Debugging, thanks to
# https://www.cmcrossroads.com/article/tracing-rule-execution-gnu-make
#OLD_SHELL := $(SHELL)
#SHELL = $(warning Building $@)$(OLD_SHELL)

.PHONY: all test regen gui-test gui
all:	regen gui-test

# Make sure our intermediate directory exists, unless we're running clean
regen:
ifeq (,$(filter clean clean-%,$(MAKECMDGOALS)))
	mkdir -p gen
endif

CC= g++
CFLAGS= $(INCS) $(WARN) $G -std=gnu++11 -U__STRICT_ANSI__ -Wno-overlength-strings
	# -U__STRICT_ANSI__ is to expose the definition of _fileno().
	# Thanks to https://stackoverflow.com/a/21035923/2877364 by
	# https://stackoverflow.com/users/1250772/kaz
WARN= -ansi -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
GUI_INCS = $(INCS) \
	   -I/mingw/include -I/mingw/include/FL/images -DWIN32 -DUSE_OPENGL32 \
	   -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
GUI_CFLAGS= $(GUI_INCS) $(WARN) $G -std=gnu++11 -U__STRICT_ANSI__ -Wno-overlength-strings

OBJS= srlua.o lfs.o checks.o
GUI_OBJS= gui-srlua.o wmain.o lfs.o gui-srlua-res.o checks.o

LIBS= luazip.a libwinreg.a -L$(LUALIB) -lzip -lz -llua -lm \
	  -ladvapi32 -lrpcrt4 -lole32 -lkernel32 -luser32 \
	  -static-libgcc -static-libstdc++ #-ldl

# Statically link fltk and fltk4lua
GUI_LIBS= luazip.a libfltk4lua.a libwinreg.a \
	/mingw/lib/libfltk_images.a /mingw/lib/libfltk_jpeg.a \
	/mingw/lib/libfltk_png.a /mingw/lib/libfltk_z.a /mingw/lib/libfltk.a \
	-L$(LUALIB) -lzip -lz -llua -lm \
	-ladvapi32 -lcomctl32 -lgdi32 -lrpcrt4 -lole32 -luuid -lshell32 \
	-lkernel32 -luser32 \
	-static-libgcc -static-libstdc++

EXPORT= -Wl,--export-all-symbols
# for Mac OS X comment the previous line above or do 'make EXPORT='

GLUE= glue.exe
T= a.exe
S= srlua.exe
TEST= test2.zip		#test.lua

# Empty the LUA_PATH and LUA_CPATH before testing so that we don't
# accidentally pull any modules we haven't expressly bundled in.
test:	$T
	export LUA_PATH= ; export LUA_CPATH= ; ./$T *

$T:	$S $(TEST) $(GLUE) Makefile
	./$(GLUE) $S $(TEST) $T
	chmod +x $T

$S:	$(OBJS) Makefile
	$(CC) -o $@ $(EXPORT) $(OBJS) $(LIBS)

$(GLUE):	glue.c Makefile
	$(CC) -o $@ $(CFLAGS) $< $(EXPORT) $(LIBS)

srlua.o: srlua.c
	$(CC) -c $< $(CFLAGS) -o $@

# GUI version ======================

gui-test: gui-$T
	export LUA_PATH= ; export LUA_CPATH= ; ./gui-$T *

gui: gui-$T

gui-$T:	gui-$S $(TEST) $(GLUE) Makefile
	./$(GLUE) gui-$S $(TEST) gui-$T
	chmod +x gui-$T

gui-$S:	$(GUI_OBJS) Makefile
	$(CC) -mwindows -o $@ $(EXPORT) $(GUI_OBJS) $(GUI_LIBS)

gui-srlua.o: srlua.c
	$(CC) -c $< $(GUI_CFLAGS) -DGUI -o $@

gui-srlua-res.o: srlua.rc
	windres -i $< -o $@

#######################################################################
# Lua source-embedding support

GEN_INC_FILE := gen/generated_incs.mk
GEN_HDR := gen/generated_incs.h
GENERATED_INCS=

clean:
	rm -f $(OBJS) $T $S core core.* a.out *.o $(GLUE) \
		$(GEN_INC_FILE) $(GEN_HDR) $(GENERATED_INCS)
	-rmdir gen

# TODO use a loop, or a filter on the output of `luarocks show`.
# Don't make GEN_INC_FILE if we're running `make clean`
# Thanks to http://make.mad-scientist.net/constructed-include-files/
$(GEN_INC_FILE): Makefile gen-inc.sh source-libraries.txt
ifeq (,$(filter clean clean-%,$(MAKECMDGOALS)))
	mkdir -p gen
	@ # ^^ expressly, since a dependency on regen causes an infinite loop
	./gen-inc.sh "$(GEN_INC_FILE)" source-libraries.txt "$(GEN_HDR)"
endif

# Making GEN_INC_FILE produces GEN_HDR as well
$(GEN_HDR): $(GEN_INC_FILE) ;

-include $(GEN_INC_FILE)

# eof
