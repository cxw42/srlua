# makefile for srlua, modified by cxw

# change these to reflect your Lua installation
LUA= /mingw
LUA_VER= 5.3
LUAINC= $(LUA)/include
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin
LUASHARE= $(LUA)/share/lua/$(LUA_VER)

G=-g

# probably no need to change anything below here

# Debugging, thanks to
# https://www.cmcrossroads.com/article/tracing-rule-execution-gnu-make
#OLD_SHELL := $(SHELL)
#SHELL = $(warning Building $@)$(OLD_SHELL)

.PHONY: all test regen
all:	regen test

# Make sure our intermediate directory exists, unless we're running clean
regen:
ifeq (,$(filter clean clean-%,$(MAKECMDGOALS)))
	mkdir -p gen
endif

CC= gcc
CFLAGS= $(INCS) $(WARN) -O2 $G -std=c11 -U__STRICT_ANSI__
	# -U__STRICT_ANSI__ is to expose the definition of _fileno().
	# Thanks to https://stackoverflow.com/a/21035923/2877364 by
	# https://stackoverflow.com/users/1250772/kaz
WARN= -ansi -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
OBJS= srlua.o lfs.o
LIBS= luazip.a -L$(LUALIB) -lzip -lz -llua -lm #-ldl
EXPORT= -Wl,--export-all-symbols
# for Mac OS X comment the previous line above or do 'make EXPORT='

GLUE= glue.exe
T= a.exe
S= srlua.exe
TEST= test.lua

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

# Convert Lua source to a C string literal we can statically compile.
# It is important to preserve the line breaks, since otherwise the first `--`
# comment will wipe out the rest of the file.
# We also strip leading and trailing whitespace, and omit lines that are
# entirely comments.  The `$0 !~ /^--[^\[\]]/` check is to (hopefully) not
# blow away block comments.

# No default rule for lua->h
#%.h: %.lua

GEN_INC_RECIPE=gawk -- '"'"'BEGIN { print "static char *PRINT_R = " } { sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$$$$/,""); } ($$$$0 !~ /^--[^\[\]]/) && /./ { gsub(/"/, "\\\""); print "\"" $$$$0 "\\n\""} END { print ";" }'"'"' $$< > $$@

##$(GENERATED_INCS): %.h: %
##	gawk -- 'BEGIN { print "static char *PRINT_R = " } { sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$$/,""); } ($$0 !~ /^--[^\[\]]/) && /./ { gsub(/"/, "\\\""); print "\"" $$0 "\\n\""} END { print ";" }' $< > $@

GEN_INC_FILE := gen/generated_incs.mk
GENERATED_INCS=

clean:
	rm -f $(OBJS) $T $S core core.* a.out *.o $(GLUE) $(GEN_INC_FILE) $(GENERATED_INCS)
	-rmdir gen

#######################################################################
# Lua source-embedding support

# TODO use a loop, or a filter on the output of `luarocks show`.
# Don't make GEN_INC_FILE if we're running `make clean`
# Thanks to http://make.mad-scientist.net/constructed-include-files/
$(GEN_INC_FILE): Makefile regen
ifeq (,$(filter clean clean-%,$(MAKECMDGOALS)))
	@echo Building $@
	@-rm -f $@
	@echo 'GENERATED_INCS += gen/print_r.h' >> $@
	@echo 'gen/print_r.h: $(LUASHARE)/print_r.lua Makefile' >> $@
	@echo '	$(GEN_INC_RECIPE)' >> $@
	@echo 'srlua.o: gen/print_r.h' >> $@
	@echo >> $@
	@echo 'GENERATED_INCS += gen/pl.h' >> $@
	@echo 'gen/pl.h: $(LUASHARE)/pl/init.lua Makefile' >> $@
	@echo '	$(GEN_INC_RECIPE)' >> $@
	@echo 'srlua.o: gen/pl.h' >> $@
	@echo >> $@
endif

-include $(GEN_INC_FILE)

# eof
