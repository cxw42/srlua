// Changes by cxw42 Copyright (c) 2018 Chris White.  CC-BY-SA 3.0 or, at your
// option, any later version under the terms in sec. 4b of CC-BY-SA 3.0.

/* Heavily modified from:
* srlua.c
* Lua interpreter for self-running programs
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 27 Apr 2012 09:24:34
* This code is hereby placed in the public domain.
*/

#if defined(_WIN32) || defined(__MINGW32__)
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
  #define _PATH_MAX MAX_PATH
#else
  #define _PATH_MAX PATH_MAX
#endif

#if defined (__CYGWIN__)
  #include <sys/cygwin.h>
#endif

#if defined(__linux__) || defined(__sun)
  #include <unistd.h> /* readlink */
#endif

#if defined(__APPLE__)
  #include <sys/param.h>
  #include <mach-o/dyld.h>
#endif

#if defined(__FreeBSD__)
  #include <sys/types.h>
  #include <sys/sysctl.h>
#endif

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "glue.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

/*************************************************************************/
/* statically-linked lua-zip */
LUALIB_API int luaopen_brimworks_zip(lua_State* L);

/* statically-linked luafilesystem */
LUALIB_API int luaopen_lfs(lua_State* L);

/// The source of the module to be loaded by luaopen_Module_source().
/// A hack since luaL_requiref doesn't provide a void* that goes to the
/// loader function.  Using a C global is simpler than using the Lua
/// registry to pass the data.
static const char *Module_source = NULL;

/// Load the Lua source pointed to by Module_source
LUALIB_API int luaopen_Module_source(lua_State* L)
{
    const char *module_name = lua_tostring(L, -1);
    if(!Module_source || !*Module_source) {
        return luaL_error(L, "No module source provided for module %s", module_name);
    }
    if(luaL_loadstring(L, Module_source) != LUA_OK) {
        return luaL_error(L, "Cannot load embedded module %s", module_name);
    }
    if(lua_pcall(L, 0, 1, 0) != LUA_OK) {
        return luaL_error(L, "Cannot evaluate embedded module %s", module_name);
    }
    return 1;
} //luaopen_Module_source

/// Load compiled-in module #name, with source code #source.
/// Returns on success; doesn't return on error.
/// Call from within a Lua context.
void load_embedded_module(lua_State *L, const char *name, const char *source)
{
    Module_source = source;
    luaL_requiref(L, name, luaopen_Module_source, 0);
    lua_pop(L,1);	/* don't leave a copy of the module on the stack*/
    Module_source = NULL;
} //load_embedded_module()

// statically-linked Lua sources
#include "gen/generated_incs.h"

/*************************************************************************/

typedef struct
{
    FILE *f;
    size_t size;
    char buff[512];
} State;

static const char *myget(lua_State *L, void *data, size_t *size)
{
    State* s=data;
    size_t n;
    (void)L;
    n=(sizeof(s->buff)<=s->size)? sizeof(s->buff) : s->size;
    n=fread(s->buff,1,n,s->f);
    s->size-=n;
    *size=n;
    return (n>0) ? s->buff : NULL;
}

#define cannot(x) luaL_error(L,"cannot %s %s: %s",x,name,strerror(errno))

static void load(lua_State *L, const char *name)
{
    Glue t;
    State S;
    FILE *f=fopen(name,"rb");
    int c;
    if (f==NULL) cannot("open");
    if (fseek(f,-sizeof(t),SEEK_END)!=0) cannot("seek");
    if (fread(&t,sizeof(t),1,f)!=1) cannot("read");
    if (memcmp(t.sig,GLUESIG,GLUELEN)!=0) luaL_error(L,"no Lua program found in %s",name);
    if (fseek(f,t.size1,SEEK_SET)!=0) cannot("seek");
    S.f=f; S.size=t.size2;
    c=getc(f);
    if (c=='#')	/* skip shebang line */
        while (--S.size>0 && c!='\n') c=getc(f);
    else
        ungetc(c,f);
#if LUA_VERSION_NUM <= 501
    if (lua_load(L,myget,&S,"=")!=0) lua_error(L);
#else
    if (lua_load(L,myget,&S,"=",NULL)!=0) lua_error(L);
#endif
    fclose(f);
}

static int pmain(lua_State *L)
{
    int argc=lua_tointeger(L,1);
    char** argv=lua_touserdata(L,2);
    int i;

    lua_gc(L,LUA_GCSTOP,0);
    luaL_openlibs(L);
    lua_gc(L,LUA_GCRESTART,0);

    // Set up Lua to call luaopen_brimworks_zip() to get the package for
    // brimworks.zip.  Thanks for the Lua 5.3 illustration to
    // https://github.com/philanc/slua/blob/master/src/lua/linit.c
    luaL_requiref(L, "brimworks.zip", luaopen_brimworks_zip, 0);
    lua_pop(L,1);	/* don't leave a copy of the module on the stack*/

    // Ditto for LFS
    luaL_requiref(L, "lfs", luaopen_lfs, 0);
    lua_pop(L,1);	// don't leave a copy of the module on the stack

    // Tell Lua about compiled-in source modules
    register_lsources(L);

#ifdef LSOURCE_HAVE_MAIN
    // Run the compiled-in Lua main program
    run_main_lsource(L);
#else
    // Load the glued-on Lua script
    load(L,argv[0]);

    // Stuff the arguments in global table `arg`
    lua_createtable(L,argc,0);
    for (i=0; i<argc; i++)
    {
        lua_pushstring(L,argv[i]);
        lua_rawseti(L,-2,i);
    }
    lua_setglobal(L,"arg");
    luaL_checkstack(L,argc-1,"too many arguments to script");

    // Also make argv the arguments to the function
    for (i=1; i<argc; i++)
    {
        lua_pushstring(L,argv[i]);
    }

    lua_call(L,argc-1,0);  // Invoked the glued-on Lua source
#endif
    return 0;
}

static void fatal(const char* progname, const char* message)
{
#ifdef GUI
    MessageBox(NULL,message,progname,MB_ICONERROR | MB_OK);
#else
    fprintf(stderr,"%s: %s\n",progname,message);
#endif
    exit(EXIT_FAILURE);
}

char* getprog() {
    int nsize = _PATH_MAX + 1;
    char* progdir = malloc(nsize * sizeof(char));
    char *lb;
    int n = 0;
#if defined(__CYGWIN__)
    char win_buff[_PATH_MAX + 1];
    GetModuleFileNameA(NULL, win_buff, nsize);
    cygwin_conv_path(CCP_WIN_A_TO_POSIX, win_buff, progdir, nsize);
    n = strlen(progdir);
#elif defined(_WIN32)
    n = GetModuleFileNameA(NULL, progdir, nsize);
#elif defined(__linux__)
    n = readlink("/proc/self/exe", progdir, nsize);
    if (n > 0) progdir[n] = 0;
#elif defined(__sun)
    pid_t pid = getpid();
    char linkname[256];
    sprintf(linkname, "/proc/%d/path/a.out", pid);
    n = readlink(linkname, progdir, nsize);
    if (n > 0) progdir[n] = 0;
#elif defined(__FreeBSD__)
    int mib[4];
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PATHNAME;
    mib[3] = -1;
    size_t cb = nsize;
    sysctl(mib, 4, progdir, &cb, NULL, 0);
    n = cb;
#elif defined(__BSD__)
    n = readlink("/proc/curproc/file", progdir, nsize);
    if (n > 0) progdir[n] = 0;
#elif defined(__APPLE__)
    uint32_t nsize_apple = nsize;
    if (_NSGetExecutablePath(progdir, &nsize_apple) == 0)
        n = strlen(progdir);
#else
    // FALLBACK
    // Use 'lsof' ... should work on most UNIX systems (incl. OSX)
    // lsof will list open files, this captures the 1st file listed (usually the executable)
    int pid;
    FILE* fd;
    char cmd[80];
    pid = getpid();

    sprintf(cmd, "lsof -p %d | awk '{if ($5==\"REG\") { print $9 ; exit}}' 2> /dev/null", pid);
    fd = popen(cmd, "r");
    n = fread(progdir, 1, nsize, fd);
    pclose(fd);

    // remove newline
    if (n > 1) progdir[--n] = '\0';
#endif
    if (n == 0 || n == nsize || (lb = strrchr(progdir, (int)LUA_DIRSEP[0])) == NULL)
        return NULL;
    return (progdir);
}

int srlua_main(int argc, char *argv[])
{
    lua_State *L;

    argv[0] = getprog();
    if (argv[0]==NULL) fatal("srlua","cannot locate this executable");

#ifdef GUI
    //MessageBox(NULL, "Hello, world! from srlua", argv[0], MB_OK);
#endif

    L = luaL_newstate();
    if (L==NULL) fatal(argv[0],"not enough memory for state");
    lua_pushcfunction(L,&pmain);
    lua_pushinteger(L,argc);
    lua_pushlightuserdata(L,argv);
    if (lua_pcall(L,2,0,0)!=0) {
        fatal(argv[0],lua_tostring(L,-1));
    }
    lua_close(L);
    return EXIT_SUCCESS;
}

#ifndef GUI
// Can't define main(int,char**) in GUI mode or we get an automatic WinMain
// that is used instead of the one from wmain.c.
int main(int argc, char *argv[]) { return srlua_main(argc, argv); }
#endif

// vi: set ts=4 sts=4 sw=4 et ai: //
