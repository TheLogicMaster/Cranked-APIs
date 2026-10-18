// Probe: printf-style formatting through the C API, compared with the host's snprintf (cases.h)
#include <string.h>
#include "pd_api.h"
#include "../cases.h"
static PlaydateAPI *pd;
static int update(void *u) { (void) u; return 0; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e != kEventInit) return 0;
  pd = p;
  int k = 0;
#define RUN(fmt, ...) { char *out = NULL; int n = pd->system->formatString(&out, fmt, __VA_ARGS__); \
    pd->system->logToConsole("fmtq%d %d [%s]", k, n, out ? out : "(null)"); pd->system->logToConsole("fmtl%d " fmt, k, __VA_ARGS__); \
    if (out) pd->system->realloc(out, 0); k++; }
  CASES(RUN)
  pd->system->setUpdateCallback(update, NULL);
  return 0;
}
