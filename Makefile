# makefile for srlua, modified by cxw

# change these to reflect your Lua installation
LUA= /mingw
LUAINC= $(LUA)/include
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin

G=-g

# these will probably work if Lua has been installed globally
#LUA= /usr/local
#LUAINC= $(LUA)/include
#LUALIB= $(LUA)/lib
#LUABIN= $(LUA)/bin

# probably no need to change anything below here
CC= gcc
CFLAGS= $(INCS) $(WARN) -O2 $G -std=c11 -U__STRICT_ANSI__
	# -U__STRICT_ANSI__ is to expose the definition of _fileno().
	# Thanks to https://stackoverflow.com/a/21035923/2877364 by
	# https://stackoverflow.com/users/1250772/kaz
WARN= -ansi -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
GENERATED_INCS= print_r.h
OBJS= srlua.o lfs.o
LIBS= luazip.a -L$(LUALIB) -lzip -lz -llua -lm #-ldl
EXPORT= -Wl,--export-all-symbols
# for Mac OS X comment the previous line above or do 'make EXPORT='

GLUE= glue.exe
T= a.exe
S= srlua.exe
TEST= test.lua

all:	test

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

srlua.o: srlua.c $(GENERATED_INCS)
	$(CC) -c $< $(CFLAGS) -o $@

# Convert Lua source to a C string literal we can statically compile.
# It is important to preserve the line breaks, since otherwise the first `--`
# comment will wipe out the rest of the file.
# We also strip leading and trailing whitespace, and omit lines that are
# entirely comments.  The `$0 !~ /^--[^\[\]]/` check is to (hopefully) not
# blow away block comments.
%.h: %.in.lua Makefile
	gawk -- 'BEGIN { print "static char *PRINT_R = " } { sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$$/,""); } ($$0 !~ /^--[^\[\]]/) && /./ { gsub(/"/, "\\\""); print "\"" $$0 "\\n\""} END { print ";" }' $< > $@

clean:
	rm -f $(OBJS) $T $S core core.* a.out *.o $(GLUE) $(GENERATED_INCS)

# eof
