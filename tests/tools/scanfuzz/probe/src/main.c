// Probe: random parseString cases (cases.inc from gen.py), each result line logged
#include <string.h>
#include "pd_api.h"
static PlaydateAPI *pd;
static char line[1024]; static int used;
static void OUT(const char *fmt, ...) {
  if (fmt[0] == '\n') { pd->system->logToConsole("%s", line); used = 0; line[0] = 0; return; }
  char *piece = NULL; va_list a; va_start(a, fmt); int n = pd->system->vaFormatString(&piece, fmt, a); va_end(a);
  if (piece) { if (n > 0 && used + n < (int) sizeof line) { memcpy(line + used, piece, n + 1); used += n; } pd->system->realloc(piece, 0); }
}
#define SCAN(n, input, fmt, reffmt, ...) n = pd->system->parseString(input, fmt, ##__VA_ARGS__)
static int update(void *u) { (void) u; return 0; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e != kEventInit) return 0;
  pd = p;
#include "cases.inc"
  pd->system->setUpdateCallback(update, NULL);
  return 0;
}
