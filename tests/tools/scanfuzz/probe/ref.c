// the same cases through the host's sscanf (with the reference format: %ld written as %d, as long is 32-bit on the device)
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
static char line[1024]; static int used;
static void OUT(const char *fmt, ...) {
  if (fmt[0] == '\n') { printf("%s\n", line); used = 0; line[0] = 0; return; }
  va_list a; va_start(a, fmt); used += vsnprintf(line + used, sizeof line - used, fmt, a); va_end(a);
}
#define SCAN(n, input, fmt, reffmt, ...) n = sscanf(input, reffmt, ##__VA_ARGS__)
int main(void) {
#include "cases.inc"
}
