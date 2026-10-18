// native code that never returns from its update callback (the emulator must stop it, not hang)
#include "pd_api.h"
static PlaydateAPI *pd;
static volatile int sink;
static int frames;
static int update(void *ud) {
  frames++;
  pd->system->logToConsole("frame %d", frames);
  if (frames == 3) for (;;) sink++; // never returns
  return 1;
}
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  if (e == kEventInit) { pd = p; pd->system->setUpdateCallback(update, NULL); }
  return 0;
}
