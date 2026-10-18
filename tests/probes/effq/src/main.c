// Probe: a custom effect's process callback (five arguments, the fifth on the stack). Logs what it receives
// for the first calls: e matches, left non-null, right NULL (mono channel), nsamples, bufactive (0 or 1), and
// whether SP was 8-byte aligned at the call (AAPCS)
#include "pd_api.h"
static PlaydateAPI *pd;
static SoundEffect *fx;
static int calls;
static int proc(SoundEffect *e, int32_t *left, int32_t *right, int nsamples, int bufactive) {
  int marker; // its address tells SP's alignment at the call, give or take the frame (compared, not absolute)
  if (calls < 4)
    pd->system->logToConsole("effq call%d same=%d left=%d right=%d n=%d active=%d sp8=%d", calls, e == fx, left != NULL, right != NULL,
                             nsamples, bufactive, (int) (((uintptr_t) &marker) & 7));
  calls++;
  return 0;
}
static int update(void *u) { (void) u; return 1; }
int eventHandler(PlaydateAPI *p, PDSystemEvent ev, uint32_t arg) {
  (void) arg;
  if (ev != kEventInit) return 0;
  pd = p;
  fx = pd->sound->effect->newEffect(proc, NULL);
  pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
  PDSynth *s = pd->sound->synth->newSynth();
  pd->sound->synth->playNote(s, 440, 1, 0.5f, 0);
  pd->system->setUpdateCallback(update, NULL);
  return 0;
}
