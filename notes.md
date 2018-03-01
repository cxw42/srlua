# Building swiss

`srlua` and `swiss` both refer to the directory where the srlua sources are.

## Lua

Download Lua 5.3 and extract it into a directory.

### Editing

Edit the appropriate lines in `lua53/Makefile` to be as follows:

    PLAT=mingw
    INSTALL_TOP=/mingw

### Building

    cd lua53
    make install

## Luarocks

Grab the Unix version, the .tar.gz.

TODO resume here

## Setting up cmake/mingw32-make environment

In `cmd`:

    path %path%;c:\MinGW\bin;"c:\Program Files (x86)\CMake\bin"

Leave this shell open while building the rest.  The remaining steps are in
an MSYS shell, unless `cmd` is specified.

## Lua

## Static build of zlib

This is so `-lz` will get the static version.  Grab zlib from [TODO]().

### Setup

    tar xvJf zlib-1.2.11.tar.xz
    cd zlib-1.2.11

Edit `win32/Makefile.gcc` to add, before the `STATICLIB` line,

    INCLUDE_PATH=/mingw/include
    BINARY_PATH=/mingw/bin
    LIBRARY_PATH=/mingw/lib

Also change the `prefix ?=` assignment to

    prefix ?= /mingw

### Build

In `zlib-1.2.11`, do

    make -fwin32/Makefile.gcc install

If you have a dynamically-linked zlib installed, rename it so the static
version will win:

    cd /mingw/lib
    mv libz.dll.a libzdynamic.dll.a

## libzip

Get libzip from [TODO]().  Libzip builds with CMake, so be sure you have
the **Windows** version of CMake installed and in your PATH.

### Editing <stdio.h> (!)

As of 2018/03/01, GCC barfs on something in the mingw definition of `sprintf`.
There is a fix, thanks to [Cooper](https://forums.wxwidgets.org/memberlist.php?mode=viewprofile&u=34639&sid=ea9ee0d2e0089c8347838f930cbfb782) in
[this post](https://forums.wxwidgets.org/viewtopic.php?f=19&t=43756#p179001).

Edit `/mingw/include/stdio.h` and comment out line 345, which is

    extern int __mingw_stdio_redirect__(snprintf)(char*, size_t, const char*, ...);

#### Error message

If you don't do this, the preprocessed line

    extern int __attribute__((__cdecl__)) __attribute__((__nothrow__)) __Wformat__snprintf __mingw__snprintf(char*, size_t, const char*, ...);

triggers the error

    c:\mingw\include\stdio.h:345:12: error: expected '=', ',', ';', 'asm' or '__attribute__' before '__mingw__snprintf'
     extern int __mingw_stdio_redirect__(snprintf)(char*, size_t, const char*, ...);
                ^

### Build

In `cmd`:

    cd libzip-1.4.0
    mkdir build-static
    cd build-static
    cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/mingw -DBUILD_SHARED_LIBS=off -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=TRUE ..
    mingw32-make -j4 VERBOSE=1 install

That puts the static `libzip.a` in `/mingw/lib`.

If you have libbz2 and want bzip2 support, leave off the `...DISABLE..BZip2`
argument to `cmake`.

## lua-zip

Grab `brimworks.zip`.

### Edit `CMakeLists.txt`

Add just just after the `CMAKE_MINIMUM_REQUIRED` line:

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_COMPAT_APIINTCASTS")
    FIND_LIBRARY(LIBZ_LIBRARY NAMES z)

Thanks to [this comment](https://github.com/diegonehab/luasocket/issues/124#issuecomment-73495211) by
[siffiejoe](https://github.com/siffiejoe) and
[this answer](https://stackoverflow.com/a/10087100/2877364) by
[fraser](https://stackoverflow.com/users/2556117/fraser).

Edit the `TARGET_LINK_LIBRARIES` entry in `CMakeLists.txt` as follows:

    TARGET_LINK_LIBRARIES(cmod_zip ${LUA_LIBRARIES} ${LIBZIP_LIBRARY} ${LIBZ_LIBRARY})

(add `${LIBZ_LIBRARY}`).  That adds `-lz` to the linker command line.

### Build

In `cmd`:

    cd lua-zip
    mkdir build-static
    cd build-static
    cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DINSTALL_CMOD=./installed ..
    mingw32-make -j4 VERBOSE=1 install
    copy CMakeFiles\cmod_zip.dir\objects.a <wherever srlua is>\srlua\luazip.a

That also gives you a DLL in `./installed`, but you don't care about that.
The static `luazip.a` you copied into srlua is what you want.

## fltk

### Build

    ./configure --prefix=/mingw --enable-localzlib --enable-localjpeg --enable-localpng
    make -j4
    make install

Wait... a build that works without changes???!!!?!??

This makes static libraries in /mingw/lib, not dynamic

## fltk4lua

Uses cxw's fork with `Window.xid`

### Build

    luarocks unpack fltk4lua
    cd fltk4lua-0.1-1/lua-fltk4lua
    luarocks make fltk4lua-0.1-1.rockspec FLTK_INCDIR=/mingw/include FLTK_LIBDIR=/mingw/lib

Note: the `make` will also install fltk4lua as a rock.

    ar r libfltk4lua.a src/fltk4lua.o src/f4l_enums.o src/f4l_ask.o src/f4l_image.o src/f4l_shared_image.o src/f4l_widget.o src/f4l_box.o src/f4l_button.o src/f4l_chart.o src/f4l_clock.o src/f4l_group.o src/f4l_browserx.o src/f4l_browser.o src/f4l_file_browser.o src/f4l_check_browser.o src/f4l_input_choice.o src/f4l_color_chooser.o src/f4l_pack.o src/f4l_scroll.o src/f4l_spinner.o src/f4l_tabs.o src/f4l_tile.o src/f4l_window.o src/f4l_wizard.o src/f4l_input.o src/f4l_menu.o src/f4l_choice.o src/f4l_menu_bar.o src/f4l_menu_button.o src/f4l_progress.o src/f4l_valuator.o src/f4l_adjuster.o src/f4l_counter.o src/f4l_dial.o src/f4l_roller.o src/f4l_slider.o src/f4l_value_input.o src/f4l_value_output.o moon/moon.o compat-5.3/c-api/compat-5.3.o

(or whatever `.o` files were listed on the `gcc -shared` command at the end of
the `luarocks make` process)

    cp libfltk4lua.a <the srlua directory>

## winreg

### Build (stable)

Similar to the fltk4lua process above.

    luarocks unpack winreg
    cd winreg-1.0.0-1/lua-winreg-1.0.0
    luarocks make winreg-1.0.0-1.rockspec

This will install winreg as a rock.

    ar r libwinreg.a src/l52util.o src/lua_int64.o src/lua_mtutil.o src/lua_tstring.o src/luawin_dllerror.o src/win_privileges.o src/win_registry.o src/win_trace.o src/winreg.o

Or whatever `.o` files are linked by `luarocks make`

    cp libwinreg.a <srlua dir>

### Build (latest --- with better 32/64 support)

    git clone https://github.com/moteus/lua-winreg.git
    cd lua-winreg
    luarocks make rockspecs/winreg-scm-0.rockspec
    ar r libwinreg.a src/l52util.o src/lua_int64.o src/lua_mtutil.o src/lua_tstring.o src/luawin_dllerror.o src/win_privileges.o src/win_registry.o src/win_trace.o src/winreg.o

(or whatever list of `.o` files was used in the `luarocks make` link line)

    cp libwinreg.a <srlua dir>

## `srlua`

    make gui-test

## Notes

I wanted to try IUP, since I think it may use native widgets.  However, I had
problems with freetype, which CD depends on, which IUP depends on.
To figure out later.

## luaprompt (disregard)

Not required, but nice for debugging.  But it requires sys/ioctl.h, which I
don't have.

### Dependencies

Install `readline` in `/mingw`.  I got it from
[gnuwin32](http://gnuwin32.sourceforge.net/packages/readline.htm).

### Mods

 - `luarocks unpack luaprompt`
 - Edit `luaprompt-0.7-1.rockspec`:
   - Remove the `supported_platforms` line
 - Run `luarocks --verbose make luaprompt-0.7-1.rockspec READLINE_DIR=/mingw HISTORY_DIR=/mingw`


<!-- vi: set ts=4 sts=4 sw=4 et ai ft=markdown: -->
