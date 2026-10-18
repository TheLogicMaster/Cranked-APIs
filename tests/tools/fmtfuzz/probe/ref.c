#include <stdio.h>
#include "cases.h"
int main(void) { int k = 0; char out[512];
#define RUN(fmt, ...) { int n = snprintf(out, sizeof out, fmt, __VA_ARGS__); printf("fmtq%d %d [%s]\n", k, n, out); printf("fmtl%d " fmt "\n", k, __VA_ARGS__); k++; }
  CASES(RUN) }
