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

## `srlua`

Build with the makefile --- it should work.

[]( vi: set ts=4 sts=4 sw=4 et ai ft=markdown: )
