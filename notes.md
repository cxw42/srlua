## Setting up cmake/mingw32-make environment

 - Run `cmd`
 - `path %path%;c:\MinGW\bin;"c:\Program Files (x86)\CMake\bin"`

## Static build of zlib

Do one!  Then `-lz` will get the static version.

## Static build of libzip

In `cmd`:

 - `cd libzip-1.4.0\build-static`
 - `C:\MinGW\msys\1.0\home\ChrisW\src\libzip-1.4.0\build-static>cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=./installed -DBUILD_SHARED_LIBS=off ..`
 - `mingw32-make VERBOSE=1 install`

That puts the static libzip.a in /mingw/lib.

## Static build of lua-zip

### Edit `CMakeLists.txt`

Add just just after the `CMAKE_MINIMUM_REQUIRED` line:

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_COMPAT_APIINTCASTS")
    FIND_LIBRARY(LIBZ_LIBRARY NAMES z)

Thanks to https://github.com/diegonehab/luasocket/issues/124#issuecomment-73495211 by https://github.com/siffiejoe and https://stackoverflow.com/a/10087100/2877364 by https://stackoverflow.com/users/2556117/fraser

Edit the `TARGET_LINK_LIBRARIES` entry in `CMakeLists.txt` as follows:

    TARGET_LINK_LIBRARIES(cmod_zip ${LUA_LIBRARIES} ${LIBZIP_LIBRARY} ${LIBZ_LIBRARY})

(add `${LIBZ_LIBRARY}`).  That adds `-lz` to the linker command line.

### Build

In `cmd`:

 - `cd lua-zip\build-static`
 - `C:\MinGW\msys\1.0\home\ChrisW\src\libzip-1.4.0\build-static>cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DINSTALL_CMOD=./installed ..`
 - `mingw32-make VERBOSE=1 install`

That gives you a DLL in `./installed`, but you don't care about that.  Instead,
grab `./CMakeFiles/cmod_zip.dir/objects.a`.  Copy it to `srlua/luazip.a`.

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
