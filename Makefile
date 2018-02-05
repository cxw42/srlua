# makefile for srlua

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
CFLAGS= $(INCS) $(WARN) -O2 $G -std=c11
WARN= -ansi -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
OBJS= srlua.o
LIBS= luazip.a -L$(LUALIB) -lzip -lz -llua -lm #-ldl
EXPORT= -Wl,--export-all-symbols
# for Mac OS X comment the previous line above or do 'make EXPORT='

GLUE= glue.exe
T= a.exe
S= srlua.exe
TEST= test.lua

all:	test

test:	$T
	./$T *

$T:	$S $(TEST) $(GLUE) Makefile
	./$(GLUE) $S $(TEST) $T
	chmod +x $T

$S:	$(OBJS) Makefile
	$(CC) -o $@ $(EXPORT) $(OBJS) $(LIBS)

$(GLUE):	glue.c Makefile
	$(CC) -o $@ $(CFLAGS) $< $(EXPORT) $(LIBS)

srlua.o: srlua.c print_r.h
	$(CC) -c $< $(CFLAGS) -o $@

# Convert Lua source to a C string literal we can statically compile.
# It is important to preserve the line breaks, since otherwise the first `--`
# comment will wipe out the rest of the file.
print_r.h: print_r.in.lua Makefile
	awk -- 'BEGIN { print "static char *PRINT_R = " } { gsub(/"/, "\\\""); print "\"" $$0 "\\n\""} END { print ";" }' $< > $@


clean:
	rm -f $(OBJS) $T $S core core.* a.out *.o $(GLUE) print_r.h

# eof
