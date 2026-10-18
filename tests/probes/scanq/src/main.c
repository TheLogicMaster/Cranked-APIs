// Probe: parseString with scanf-only syntax (suppressed assignments, sets), logged
#include <string.h>
#include "pd_api.h"
static PlaydateAPI *pd;
static int update(void *u) { (void) u; return 0; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e != kEventInit) return 0;
  pd = p;
  int a = -1, b = -1; char w[16] = "-", v[16] = "-";
  int n = pd->system->parseString("12 34 56", "%*d %d %d", &a, &b);
  pd->system->logToConsole("scanq1 %d %d %d", n, a, b);
  a = -1; n = pd->system->parseString("abc,def 7", "%[^,],%15s %d", w, v, &a);
  pd->system->logToConsole("scanq2 %d %s %s %d", n, w, v, a);
  a = -1; strcpy(w, "-"); n = pd->system->parseString("aabbz 9", "%[ab]z %d", w, &a);
  pd->system->logToConsole("scanq3 %d %s %d", n, w, a);
  a = -1; b = -1; n = pd->system->parseString("x=5;y=6", "x=%d;%*c=%d", &a, &b);
  pd->system->logToConsole("scanq4 %d %d %d", n, a, b);
  strcpy(w, "-"); strcpy(v, "-"); n = pd->system->parseString("abcdef  gh", "%3s%s %s", w, v, v);
  pd->system->logToConsole("scanq5 %d %s %s", n, w, v);
  pd->system->setUpdateCallback(update, NULL);
  return 0;
}
