// Probe: native speed. MODE 0: register-only loop; 1: stores to a heap buffer; 2: stores to the frame buffer;
// 3: stores to a stack buffer; 4: stores to a static buffer. Each update runs 4 million iterations.
#include "pd_api.h"
#ifndef MODE
#define MODE 7
#endif
static PlaydateAPI *pd;
static volatile unsigned sink;
static unsigned char sbuf[12000];
static unsigned char *hbuf;
typedef int (*fn_t)(void);
static int smcCheck(void) {
    // writes a Thumb function into the heap, runs it, rewrites its constant, runs it again (several times each)
    unsigned short *code = pd->system->realloc(NULL, 64);
    int results[6];
    for (int round = 0; round < 3; round++) {
        code[0] = (unsigned short) (0x2000 | (5 + round)); code[1] = 0x4770; // movs r0, #(5 + round); bx lr
#ifdef __arm__
        __asm__ volatile ("dsb\n isb" ::: "memory");
#endif
        fn_t f = (fn_t) ((unsigned) code | 1);
        int a = 0; for (int i = 0; i < 100; i++) a = f();
        results[round * 2] = a;
        code[0] = (unsigned short) (0x2000 | (40 + round)); // patch the constant of a function that has run
#ifdef __arm__
        __asm__ volatile ("dsb\n isb" ::: "memory");
#endif
        results[round * 2 + 1] = f();
    }
    pd->system->logToConsole("smc %d %d %d %d %d %d", results[0], results[1], results[2], results[3], results[4], results[5]);
    return 0;
}
static void padReport(const char *label, LCDBitmap *b) {
    int w, h, rb; uint8_t *mask, *data;
    pd->graphics->getBitmapData(b, &w, &h, &rb, &mask, &data);
    char buf[200]; int n = 0;
    n += snprintf(buf + n, sizeof buf - n, "%s w=%d rb=%d data:", label, w, rb);
    for (int i = w / 8; i < rb; i++) n += snprintf(buf + n, sizeof buf - n, " %02x", data[i]);
    if (mask) { n += snprintf(buf + n, sizeof buf - n, " mask:"); for (int i = w / 8; i < rb; i++) n += snprintf(buf + n, sizeof buf - n, " %02x", mask[i]); }
    pd->system->logToConsole("%s", buf);
    static SDFile *f; if (!f) f = pd->file->open("pad.txt", kFileWrite);
    if (f) { pd->file->write(f, buf, n); pd->file->write(f, "\n", 1); pd->file->flush(f); }
}
static void padRow(const char *label, LCDBitmap *b, int row) {
    int w, h, rb; uint8_t *mask, *data;
    pd->graphics->getBitmapData(b, &w, &h, &rb, &mask, &data);
    char buf[200]; int n = snprintf(buf, sizeof buf, "%s row %d data:", label, row);
    for (int i = w / 8; i < rb; i++) n += snprintf(buf + n, sizeof buf - n, " %02x", data[row * rb + i]);
    if (mask) { n += snprintf(buf + n, sizeof buf - n, " mask:"); for (int i = w / 8; i < rb; i++) n += snprintf(buf + n, sizeof buf - n, " %02x", mask[row * rb + i]); }
    pd->system->logToConsole("%s", buf);
    static SDFile *f; if (!f) f = pd->file->open("pad2.txt", kFileWrite);
    if (f) { pd->file->write(f, buf, n); pd->file->write(f, "\n", 1); pd->file->flush(f); }
}
static void padCheck2(void) {
    static LCDPattern stripes = { 0x0f, 0x1e, 0x3c, 0x78, 0xf0, 0xe1, 0xc3, 0x87, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
    LCDBitmap *e = pd->graphics->newBitmap(100, 100, kColorClear);
    pd->graphics->pushContext(e);
    pd->graphics->fillEllipse(0, 0, 100, 100, 0, 0, (LCDColor) stripes);
    pd->graphics->drawEllipse(0, 0, 100, 100, 1, 0, 0, kColorBlack);
    pd->graphics->popContext();
    for (int r = 0; r < 100; r += 7) padRow("ellipse", e, r);
    LCDBitmap *m = pd->graphics->getBitmapMask(e);
    LCDBitmap *t = pd->graphics->newBitmap(100, 100, kColorBlack);
    pd->graphics->pushContext(t); pd->graphics->drawBitmap(m, 0, 0, kBitmapUnflipped); pd->graphics->popContext();
    for (int r = 0; r < 100; r += 7) padRow("mask drawn", t, r);
    LCDBitmap *f = pd->graphics->newBitmap(100, 10, kColorBlack);
    pd->graphics->pushContext(f); pd->graphics->fillRect(0, 0, 100, 10, (LCDColor) stripes); pd->graphics->popContext();
    padRow("pattern rect", f, 3);
}
static void padCheck(void) {
    padCheck2();
    LCDBitmap *b = pd->graphics->newBitmap(100, 4, kColorBlack); padReport("new black", b);
    LCDBitmap *w = pd->graphics->newBitmap(100, 4, kColorWhite); padReport("new white", w);
    LCDBitmap *c = pd->graphics->newBitmap(100, 4, kColorClear); padReport("new clear", c);
    pd->graphics->clearBitmap(b, kColorWhite); padReport("clear white", b);
    pd->graphics->clearBitmap(b, kColorBlack); padReport("clear black", b);
    pd->graphics->pushContext(b); pd->graphics->fillRect(0, 0, 400, 10, kColorWhite); pd->graphics->popContext(); padReport("fill white", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(w, 0, 0, kBitmapUnflipped); pd->graphics->popContext(); padReport("draw white img", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(c, 0, 0, kBitmapUnflipped); pd->graphics->popContext(); padReport("draw clear img", b);
    LCDBitmap *cw = pd->graphics->newBitmap(100, 4, kColorClear);
    pd->graphics->pushContext(cw); pd->graphics->fillRect(10, 0, 50, 4, kColorWhite); pd->graphics->popContext(); padReport("clear+fill", cw);
    LCDBitmap *m = pd->graphics->getBitmapMask(cw); if (m) padReport("its mask", m);
    LCDBitmap *cp = pd->graphics->copyBitmap(cw); padReport("copy", cp);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->setDrawMode(kDrawModeWhiteTransparent); pd->graphics->drawBitmap(w, 0, 0, kBitmapUnflipped); pd->graphics->setDrawMode(kDrawModeCopy); pd->graphics->popContext(); padReport("draw white wt", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(w, 0, 0, kBitmapFlippedX); pd->graphics->popContext(); padReport("draw white flipx", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(w, 3, 0, kBitmapUnflipped); pd->graphics->popContext(); padReport("draw white at 3", b);
    LCDBitmap *r = pd->graphics->rotatedBitmap(w, 90, 1, 1, NULL); padReport("rotated", r);
    padReport("framebuffer copy", pd->graphics->copyFrameBufferBitmap());
    padReport("display buffer", pd->graphics->getDisplayBufferBitmap());
    { const char *err = NULL; LCDFont *f = pd->graphics->loadFont("/System/Fonts/Asheville-Sans-14-Bold.pft", &err);
      if (f) { LCDFontPage *pg = pd->graphics->getFontPage(f, 'A'); LCDBitmap *gb = NULL; int adv = 0;
        if (pg) { pd->graphics->getPageGlyph(pg, 'A', &gb, &adv); if (gb) padReport("glyph A", gb); } } }
    LCDBitmap *big = pd->graphics->newBitmap(37, 3, kColorWhite); padReport("new 37", big);
    padReport("rotated 37", pd->graphics->rotatedBitmap(big, 0, 1, 1, NULL));
    padReport("rotated 37 x2", pd->graphics->rotatedBitmap(big, 0, 2, 1, NULL));
    LCDBitmap *w30 = pd->graphics->newBitmap(30, 4, kColorWhite);
    LCDBitmap *b30 = pd->graphics->newBitmap(30, 4, kColorBlack);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(w30, 90, 0, kBitmapUnflipped); pd->graphics->popContext(); padReport("white past edge", b);
    pd->graphics->clearBitmap(b, kColorWhite);
    pd->graphics->pushContext(b); pd->graphics->drawBitmap(b30, 90, 0, kBitmapUnflipped); pd->graphics->popContext(); padReport("black past edge", b);
    pd->graphics->clearBitmap(b, kColorWhite);
    pd->graphics->pushContext(b); pd->graphics->setDrawMode(kDrawModeWhiteTransparent); pd->graphics->drawBitmap(b30, 90, 0, kBitmapUnflipped); pd->graphics->setDrawMode(kDrawModeCopy); pd->graphics->popContext(); padReport("black past edge wt", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->fillRect(90, 0, 30, 4, kColorWhite); pd->graphics->popContext(); padReport("fillrect past edge", b);
    pd->graphics->clearBitmap(b, kColorBlack);
    pd->graphics->pushContext(b); pd->graphics->drawLine(90, 1, 120, 1, 1, kColorWhite); pd->graphics->popContext(); padReport("line past edge", b);
    LCDBitmap *inv = pd->graphics->newBitmap(100, 4, kColorBlack);
    pd->graphics->pushContext(inv); pd->graphics->fillRect(0, 0, 100, 4, kColorWhite); pd->graphics->popContext(); padReport("filled all", inv);
}
static void padCheck(void);
static void fontCheck(void) {
    // makeFontFromData on a pft's contents after its 16-byte header, against the same font loaded from its file
    SDFile *f = pd->file->open("bitmore.pft", kFileRead);
    char out[300]; int n = 0;
    if (!f) { pd->system->logToConsole("fontq no file"); return; }
    static uint8_t buf[200000]; int len = pd->file->read(f, buf, sizeof buf); pd->file->close(f);
    const char *err = NULL;
    LCDFont *loaded = pd->graphics->loadFont("bitmore", &err);
    LCDFont *made = pd->graphics->makeFontFromData((LCDFontData *) (buf + 16), 0, len - 16);
    LCDFont *madeOld = pd->graphics->makeFontFromData_deprecated((LCDFontData *) (buf + 16), 0);
    n += snprintf(out + n, sizeof out - n, "fontq len=%d loaded=%d made=%d old=%d", len, loaded != NULL, made != NULL, madeOld != NULL);
    LCDFont *fonts[3] = { loaded, made, madeOld };
    for (int k = 0; k < 3; k++) {
        if (!fonts[k]) continue;
        LCDBitmap *b = pd->graphics->newBitmap(120, 20, kColorWhite);
        pd->graphics->pushContext(b); pd->graphics->setFont(fonts[k]); pd->graphics->drawText("Hello, Font 42!", 15, kASCIIEncoding, 2, 2); pd->graphics->popContext();
        int w, h, rb; uint8_t *m, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d);
        unsigned sum = 0; for (int i = 0; i < rb * h; i++) sum = sum * 31 + d[i];
        n += snprintf(out + n, sizeof out - n, " sum%d=%08x width%d=%d h=%d", k, sum, k, pd->graphics->getTextWidth(fonts[k], "Hello, Font 42!", 15, kASCIIEncoding, 0), pd->graphics->getFontHeight(fonts[k]));
    }
    pd->system->logToConsole("%s", out);
    SDFile *o = pd->file->open("font.txt", kFileWrite); if (o) { pd->file->write(o, out, n); pd->file->write(o, "\n", 1); pd->file->close(o); }
}
static int update(void *ud) {
#if MODE == 7
    fontCheck(); pd->system->setUpdateCallback(NULL, NULL); return 0;
#endif
#if MODE == 6
    padCheck(); pd->system->setUpdateCallback(NULL, NULL); return 0;
#endif
#if MODE == 5
    smcCheck(); pd->system->setUpdateCallback(NULL, NULL); return 0;
#endif
    unsigned a = 1, b = 2;
    unsigned char local[1024];
    unsigned char *fb = pd->graphics->getFrame();
    for (int i = 0; i < 4000000; i++) {
#if MODE == 0
        a = a * 1664525u + b; b ^= a >> 3;
#elif MODE == 1
        a = a * 1664525u + b; hbuf[i % 12000] = (unsigned char) a;
#elif MODE == 2
        a = a * 1664525u + b; fb[i % 12000] = (unsigned char) a;
#elif MODE == 3
        a = a * 1664525u + b; local[i & 1023] = (unsigned char) a;
#else
        a = a * 1664525u + b; sbuf[i % 12000] = (unsigned char) a;
#endif
    }
    sink = a + local[5] + sbuf[3];
    pd->graphics->markUpdatedRows(0, 239);
    return 1;
}
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
    if (e == kEventInit) { pd = p; if (MODE == 6) padCheck(); hbuf = pd->system->realloc(NULL, 12000); pd->display->setRefreshRate(0); pd->system->setUpdateCallback(update, NULL); }
    return 0;
}
