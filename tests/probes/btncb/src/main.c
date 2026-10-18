// Probe: system->setButtonCallback. Logs each callback (button, down, frame) and the update count.
#include "pd_api.h"
static PlaydateAPI *pd;
static int frame;
static int cb(PDButtons button, int down, uint32_t when, void *ud) {
  (void) when;
  pd->system->logToConsole("btncb frame=%d button=%d down=%d ud=%d", frame, (int) button, down, ud == (void *) 0x1234);
  return 0;
}
static int update(void *u) { (void) u; frame++; return 0; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInit) { pd = p; pd->system->setButtonCallback(cb, (void *) 0x1234, 5); pd->system->setUpdateCallback(update, NULL); }
  return 0;
}
