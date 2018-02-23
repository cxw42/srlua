#include <windows.h>
#include <stdlib.h> /* declaration of __argc and __argv */

extern int srlua_main(int, char **);

int APIENTRY WinMain(HINSTANCE hinst, HINSTANCE hprev, LPSTR cmdline, int ncmdshow)
{
  // TODO respect ncmdshow
  (void)hinst; (void)hprev; (void)cmdline; (void)ncmdshow;

  int rc;

  //MessageBoxW (NULL, L"Hello World!", L"hello", MB_OK | MB_ICONINFORMATION);
  //MessageBox(NULL, "WinMain", "gui-srlua", MB_OK);
  rc = srlua_main(_argc, _argv);
    // Note: if something calls srlua.c:fatal(), srlua_main() never returns.

  return rc;
}
// vi: set ts=4 sts=4 sw=4 et ai: //
