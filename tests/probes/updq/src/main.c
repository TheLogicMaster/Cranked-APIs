// Probe: a C update callback set in kEventInitLua, in a game with a Lua playdate.update. Which run, and in
// what order? The C callback records its calls in a Lua global through pd->lua.
#include "pd_api.h"
static PlaydateAPI *pd;
static int cCalls;
static int cupdate(void *u) {
  (void) u;
  cCalls++;
  pd->lua->pushInt(cCalls);
  pd->lua->callFunction("noteC", 1, NULL);
  return 1;
}
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInitLua) { pd = p; pd->system->setUpdateCallback(cupdate, NULL); }
  return 0;
}
