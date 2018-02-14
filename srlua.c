// Changes by cxw42 Copyright (c) 2018 Chris White.  CC-BY-SA 3.0 or, at your
// option, any later version under the terms in sec. 4b of CC-BY-SA 3.0.

#ifndef _WIN32
#error We only support WIN32 at the moment.  Sorry!
#endif

#if defined(_WIN32) || defined(__MINGW32__)
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
  #include <objbase.h>
  #include <direct.h>
  #include <rpc.h>
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

// statically-linked checks
extern int luaopen_checks( lua_State *L);

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

// ***********************************************************************
// Package `swiss`

/// Absolute path to the extracted payload
char payload_fullname[_PATH_MAX+1];

/// Directory containing the extracted payload, with trailing separator
char payload_dir[_PATH_MAX+1];

/// Create a temporary directory in #payload_dir.
/// @return throws on failure, or the dir name on success
int swiss_make_temp_dir(lua_State *L)
{
    GUID guid;
    //char str_guid[256];
    if(FAILED(CoCreateGuid(&guid)))
        return luaL_error(L, "Could not create unique directory name");

    //int ok = StringFromGUID2(&guid, str_guid, sizeof(str_guid));
    unsigned char *str_guid;
    RPC_STATUS ok = UuidToString(&guid, &str_guid);
    if(ok != RPC_S_OK)
        return luaL_error(L, "Could not get unique directory name");

    char dirname[_PATH_MAX+1];
    if( (strlen(payload_dir) + 4 + strlen((const char *)str_guid) + 1) > sizeof(dirname)) {
        RpcStringFree(&str_guid);
        return luaL_error(L, "Unique directory name is too long (!?)");
    }

    strcpy(dirname, payload_dir);
    strcat(dirname, "SWI-");
    strcat(dirname, (const char *)str_guid);

    RpcStringFree(&str_guid);

    if(_mkdir(dirname) == -1)
        return luaL_error(L, "Could not create unique directory %s", dirname);

    lua_pushstring(L, dirname);
    return 1;
} //swiss_make_temp_dir

/// Load package `swiss`
LUALIB_API int luaopen_swiss(lua_State* L)
{
    lua_newtable(L);
    lua_pushstring(L, payload_fullname);
    lua_setfield(L, -2, "payload_fullname");

    lua_pushstring(L, payload_dir);
    lua_setfield(L, -2, "payload_dir");

    lua_pushcfunction(L, swiss_make_temp_dir);
    lua_setfield(L, -2, "make_temp_dir");

    return 1;
} //luaopen_swiss

/*************************************************************************/

#if 0
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
#endif


static void fatal(const char* progname, const char* message)
{
#ifdef GUI
    MessageBox(NULL,message,progname,MB_ICONERROR | MB_OK);
#else
    fprintf(stderr,"%s: %s\n",progname,message);
#endif
    exit(EXIT_FAILURE);
}


/// Extract the payload glued onto the EXE (if any) to a temporary file.
/// Fills in #dest_filename_buf on success.
/// Aborts on failure.
static void extract_payload(lua_State *L,
        const char *from_filename,
        char *dest_filename_buf,
        size_t dest_filename_buflen,
        char *dest_path_buf,
        size_t dest_path_buflen)
{
#define cannot(x) do { if(sourcefd) fclose(sourcefd); \
        if(destfd) fclose(destfd); \
        luaL_error(L,"cannot %s %s: %s",x,from_filename,strerror(errno)); } while(0)

    Glue t;
    //State S;
    DWORD dw;
    UINT ui;
    FILE *sourcefd=NULL;
    FILE *destfd=NULL;

    if(dest_filename_buflen <= _PATH_MAX || dest_path_buflen <= _PATH_MAX) {
        cannot("extract with insufficient buffer space");
    }

    sourcefd=fopen(from_filename,"rb");
    if (sourcefd==NULL) cannot("open");
    if (fseek(sourcefd,-sizeof(t),SEEK_END)!=0) cannot("seek");
    if (fread(&t,sizeof(t),1,sourcefd)!=1) cannot("read");
    if (memcmp(t.sig,GLUESIG,GLUELEN)!=0) {
        luaL_error(L,"no payload found in %s",from_filename);
    }
    if (fseek(sourcefd,t.size1,SEEK_SET)!=0) cannot("seek");
    //S.f=sourcefd; S.size=t.size2;

    // Get temporary path name - modified from
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363875(v=vs.85).aspx
    dw = GetTempPathA(dest_path_buflen, dest_path_buf);
    if((dw>dest_path_buflen) || (dw==0)) {
        strcpy(dest_path_buf,".\\");
    }

#ifdef _DEBUG
    printf("Temp path is %s\n", dest_path_buf);
#endif

    ui = GetTempFileNameA(dest_path_buf, "SWI", 0, dest_filename_buf);
    if(ui==0) cannot("create temporary file");

#ifdef _DEBUG
    printf("Temp filename is %s\n", dest_filename_buf);
#endif

    destfd = fopen(dest_filename_buf, "wb");
    if(destfd==NULL) cannot("create output file");

    // Copy the data out
    unsigned char buf[512];
    long bytes, total_bytes=0;

    while(total_bytes < t.size2) {
        bytes=t.size2 - total_bytes;
        if(bytes>(long)sizeof(buf)) bytes=sizeof(buf);

        fread(buf, 1, bytes, sourcefd);
        if(ferror(sourcefd)) cannot("read source file");

        fwrite(buf, 1, bytes, destfd);
        if(ferror(destfd)) cannot("write destination file");

        total_bytes += bytes;
    }

    printf("Extracted payload to %s\n", dest_filename_buf);

#if 0
    int c;
    c=getc(sourcefd);
    if (c=='#')	/* skip shebang line */
        while (--S.size>0 && c!='\n') c=getc(sourcefd);
    else
        ungetc(c,sourcefd);
#if LUA_VERSION_NUM <= 501
    if (lua_load(L,myget,&S,"=")!=0) lua_error(L);
#else
    if (lua_load(L,myget,&S,"=",NULL)!=0) lua_error(L);
#endif

#endif

    fclose(sourcefd);
    fclose(destfd);
#undef cannot
} //extract_payload()

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
    luaL_requiref(L, "lfs", luaopen_lfs, 1);
    lua_pop(L,1);	// don't leave a copy of the module on the stack

    // And checks
    luaL_requiref(L, "checks", luaopen_checks, 1);
    lua_pop(L,1);	// don't leave a copy of the module on the stack

    // Tell Lua about compiled-in source modules
    register_lsources(L);

    // Extract the payload into its own file
    extract_payload(L, argv[0], payload_fullname, sizeof(payload_fullname),
            payload_dir, sizeof(payload_dir));

    // Tell Lua about the extracted payload by putting values in package "swiss"
    luaL_requiref(L,"swiss", luaopen_swiss, 0);
    lua_pop(L,1);

#ifndef LSOURCE_HAVE_MAIN
#error "Need a MAIN lua source compiled in"
#endif

    // Load the compiled-in Lua main program
    load_main_lsource(L);

#if 0
    // Load the glued-on Lua script
    load(L,argv[0]);
#endif

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

    lua_call(L,argc-1,0);  // Invoked the compiled-in Lua source

    return 0;
} //pmain

/// Get the filename of the running executable.
/// progdir must have at least _PATH_MAX+1 bytes
char* getprog(char *progdir)
{
    int nsize = _PATH_MAX + 1;
    //char* progdir = malloc(nsize * sizeof(char));
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
} //getprog()

static char progbuf[_PATH_MAX+1];

int srlua_main(int argc, char *argv[])
{
    lua_State *L;

    argv[0] = getprog(progbuf);
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
} //srlua_main()

#ifndef GUI
// Can't define main(int,char**) in GUI mode or we get an automatic WinMain
// that is used instead of the one from wmain.c.
int main(int argc, char *argv[]) { return srlua_main(argc, argv); }
#endif

///////////////////////////////////////////////////////////////////////////

/* Heavily modified from:
* srlua.c
* Lua interpreter for self-running programs
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 27 Apr 2012 09:24:34
* This code is hereby placed in the public domain.
*/

// vi: set ts=4 sts=4 sw=4 et ai: //
