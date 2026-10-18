// Probe: fused multiply-add and float maths. The device build of a game fuses a*b+c into one
// rounding (vfma); the Simulator's x86 build rounds twice. This logs both forms for random inputs,
// plus sinf/cosf/atan2f/sqrtf, so the device CPU emulation can be checked against a host fmaf().
#include <math.h>
#include <stdarg.h>
#include "pd_api.h"
static PlaydateAPI* pd;
static SDFile* out;
static void put(const char* fmt, ...) { char* t; va_list ap; va_start(ap, fmt); int n = pd->system->vaFormatString(&t, fmt, ap); va_end(ap); pd->system->logToConsole("%s", t); if (out) { pd->file->write(out, t, n); pd->file->write(out, "\n", 1); } pd->system->realloc(t, 0); }
static uint32_t rng = 7;
static uint32_t rnd(void) { rng = rng * 1103515245u + 12345u; return rng; }
static float rf(void) { union { uint32_t u; float f; } x; do { x.u = rnd() ^ (rnd() << 13); } while ((x.u & 0x7F800000) == 0x7F800000); return x.f; }
static float smallf(void) { return (float)(int32_t)rnd() / 1e7f; }
static uint32_t bits(float f) { union { float f; uint32_t u; } x = { f }; return x.u; }
#ifdef TARGET_PLAYDATE
static float fused(float a, float b, float c) { __asm__("vfma.f32 %0, %1, %2" : "+t"(c) : "t"(a), "t"(b)); return c; }
#else
static float fused(float a, float b, float c) { return fmaf(a, b, c); }
#endif
static int update(void* ud) {
    static int done;
    if (done++) return 0;
    out = pd->file->open("out.txt", kFileWrite);
    uint32_t h1 = 0, h2 = 0, h3 = 0;
    for (int i = 0; i < 2000; i++) {
        float a = i & 1 ? rf() : smallf(), b = i & 1 ? rf() : smallf(), c = i & 1 ? rf() : smallf();
        volatile float p = a * b; volatile float s = p + c;
        float f = fused(a, b, c);
        h1 = h1 * 31 + bits(f); h2 = h2 * 31 + bits(s);
        if (i < 6) put("FMA %08x %08x %08x -> fused %08x split %08x", bits(a), bits(b), bits(c), bits(f), bits(s));
        float x = smallf();
        h3 = h3 * 31 + bits(sinf(x)) + 3 * bits(cosf(x)) + 7 * bits(atan2f(x, smallf())) + 11 * bits(sqrtf(fabsf(x)));
    }
    put("FMAHASH fused=%08x split=%08x libm=%08x", h1, h2, h3);
    if (out) pd->file->close(out);
    return 1;
}
int eventHandler(PlaydateAPI* api, PDSystemEvent e, uint32_t arg) {
    if (e == kEventInit) { pd = api; pd->system->setUpdateCallback(update, NULL); }
    return 0;
}
