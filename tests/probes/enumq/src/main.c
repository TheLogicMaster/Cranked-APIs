// Probe: API outputs of enum type are one byte in games built with the SDK (ARM EABI short enums). Each output
// is followed by guard bytes, which must stay untouched.
#include "pd_api.h"
static PlaydateAPI *pd;
struct out { PDButtons b; uint8_t guard[3]; };
static int frame;
static int update(void *u) {
  (void) u;
  if (++frame == 3) {
    struct out cur = { 0, { 0xAA, 0xBB, 0xCC } }, push = { 0, { 0xAA, 0xBB, 0xCC } }, rel = { 0, { 0xAA, 0xBB, 0xCC } };
    pd->system->getButtonState(&cur.b, &push.b, &rel.b);
    pd->system->logToConsole("enumq size=%d buttons guards %02x%02x%02x %02x%02x%02x %02x%02x%02x", (int) sizeof(PDButtons),
                             cur.guard[0], cur.guard[1], cur.guard[2], push.guard[0], push.guard[1], push.guard[2], rel.guard[0], rel.guard[1], rel.guard[2]);
    AudioSample *s = pd->sound->sample->newSampleBuffer(100);
    uint8_t *data; struct { SoundFormat f; uint8_t guard[3]; } fmt = { 0, { 0xAA, 0xBB, 0xCC } }; uint32_t rate = 0, len = 0;
    pd->sound->sample->getData(s, &data, &fmt.f, &rate, &len);
    pd->system->logToConsole("enumq size=%d format=%d guards %02x%02x%02x rate=%u", (int) sizeof(SoundFormat), (int) fmt.f, fmt.guard[0], fmt.guard[1], fmt.guard[2], (unsigned) rate);
  }
  return 0;
}
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInit) { pd = p; pd->system->setUpdateCallback(update, NULL); }
  return 0;
}
