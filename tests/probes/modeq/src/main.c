// Probe: is the C API's draw mode the same state as Lua's image draw mode? A Lua function calls
// graphics->setDrawMode and returns the previous mode it saw.
#include "pd_api.h"
static PlaydateAPI *pd;
static int cmode(lua_State *L) {
  (void) L;
  int newMode = pd->lua->getArgInt(1);
  int prev = pd->graphics->setDrawMode((LCDBitmapDrawMode) newMode);
  pd->lua->pushInt(prev);
  return 1;
}
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInitLua) { pd = p; pd->lua->addFunction(cmode, "cmode", NULL); }
  return 0;
}
