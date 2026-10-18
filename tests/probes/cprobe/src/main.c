// C API probe for differential testing: Simulator (host build) vs an emulator (device build).
// Writes one "name<TAB>result" line per case to outc.txt in the game's data folder.
#include <stdint.h>
#include <stdarg.h>
#include <stddef.h>
#include <string.h>
#include "pd_api.h"

static PlaydateAPI* pd;
static char out[8192];
static int olen;

// ---------- output helpers (no printf dependency) ----------
static void S(const char* s) { if (!s) s = "(null)"; while (*s && olen < (int)sizeof(out) - 2) out[olen++] = *s++; out[olen] = 0; }
static void C1(char c) { if (olen < (int)sizeof(out) - 2) { out[olen++] = c; out[olen] = 0; } }
static void I(long long v) {
    char t[24]; int n = 0; int neg = v < 0; unsigned long long u = neg ? (unsigned long long)(-v) : (unsigned long long)v;
    do { t[n++] = (char)('0' + u % 10); u /= 10; } while (u);
    if (neg) C1('-');
    while (n) C1(t[--n]);
}
static void F(float f) {
    if (f != f) { S("nan"); return; }
    if (f < 0) { C1('-'); f = -f; }
    long long whole = (long long)f;
    long long frac = (long long)((f - (float)whole) * 1000.0f + 0.5f);
    if (frac >= 1000) { whole++; frac -= 1000; }
    I(whole); C1('.');
    C1((char)('0' + frac / 100)); C1((char)('0' + (frac / 10) % 10)); C1((char)('0' + frac % 10));
}
static void SEP(void) { S(" | "); }
static void RECT(PDRect r) { S("R("); F(r.x); C1(','); F(r.y); C1(','); F(r.width); C1(','); F(r.height); C1(')'); }
static void PIX(LCDBitmap* b) {
    // Reads through getBitmapPixel so drawing is judged independently of the bitmap memory layout.
    if (!b) { S("nil"); return; }
    int w, h, rb; uint8_t *mask = NULL, *data = NULL;
    pd->graphics->getBitmapData(b, &w, &h, &rb, &mask, &data);
    S("PIX:"); I(w); C1('x'); I(h); C1(':');
    for (int y = 0; y < h; y++) {
        if (y) C1('/');
        for (int x = 0; x < w; x++) { LCDSolidColor c = pd->graphics->getBitmapPixel(b, x, y); C1(c == kColorWhite ? '1' : (c == kColorBlack ? '0' : 'x')); }
    }
}
static void RAW(LCDBitmap* b) {
    // Raw memory layout: rowbytes, then each row's bytes in hex for the data plane.
    int w, h, rb; uint8_t *mask = NULL, *data = NULL;
    pd->graphics->getBitmapData(b, &w, &h, &rb, &mask, &data);
    S("rb="); I(rb); S(" mask="); I(mask != NULL); C1(' ');
    static const char hx[] = "0123456789abcdef";
    for (int y = 0; y < h; y++) { if (y) C1('/'); for (int x = 0; x < rb; x++) { C1(hx[data[y * rb + x] >> 4]); C1(hx[data[y * rb + x] & 15]); } }
}
static LCDBitmap* canvas(int w, int h) { return pd->graphics->newBitmap(w, h, kColorWhite); }
static void reset(void) {
    pd->graphics->setDrawMode(kDrawModeCopy); pd->graphics->setDrawOffset(0, 0); pd->graphics->clearClipRect();
    pd->graphics->setLineCapStyle(kLineCapStyleButt); pd->graphics->setTextTracking(0); pd->graphics->setTextLeading(0);
}
#define DRAW(w, h, body) do { LCDBitmap* _c = canvas(w, h); pd->graphics->pushContext(_c); body; pd->graphics->popContext(); PIX(_c); pd->graphics->freeBitmap(_c); } while (0)

// ---------- system ----------
static void t_sys_time_types(void) { unsigned int ms = 0; unsigned int s = pd->system->getSecondsSinceEpoch(&ms); I(s > 700000000u); SEP(); I(ms < 1000); SEP(); I(pd->system->getCurrentTimeMilliseconds() > 0); }
static void t_sys_language(void) { I(pd->system->getLanguage()); }
static void t_sys_flags(void) { I(pd->system->getFlipped()); SEP(); I(pd->system->getReduceFlashing()); SEP(); I(pd->system->shouldDisplay24HourTime()); SEP(); I(pd->system->isCrankDocked()); }
static void t_sys_crank(void) { F(pd->system->getCrankAngle()); SEP(); F(pd->system->getCrankChange()); }
static void t_sys_crank_sounds(void) { int a = pd->system->setCrankSoundsDisabled(1); int b = pd->system->setCrankSoundsDisabled(0); I(a); SEP(); I(b); }
static void t_sys_buttons(void) { PDButtons c = 1, p = 1, r = 1; pd->system->getButtonState(&c, &p, &r); I(c); SEP(); I(p); SEP(); I(r); }
static void t_sys_buttons_null(void) { PDButtons c = 9; pd->system->getButtonState(&c, NULL, NULL); I(c); }
static void t_sys_accel(void) { float x = 9, y = 9, z = 9; pd->system->setPeripheralsEnabled(kAccelerometer); pd->system->getAccelerometer(&x, &y, &z); F(x); SEP(); F(y); SEP(); F(z); pd->system->setPeripheralsEnabled(kNone); }
static void t_sys_elapsed(void) { pd->system->resetElapsedTime(); float t = pd->system->getElapsedTime(); I(t >= 0 && t < 1); }
static void t_sys_battery(void) { float p = pd->system->getBatteryPercentage(); float v = pd->system->getBatteryVoltage(); I(p >= 0 && p <= 100); SEP(); I(v >= 0); }
static void t_sys_timezone(void) { int32_t o = pd->system->getTimezoneOffset(); I(o > -86400 && o < 86400); }
static void t_sys_epoch_zero(void) { struct PDDateTime d; memset(&d, 0, sizeof d); pd->system->convertEpochToDateTime(0, &d); I(d.year); C1('-'); I(d.month); C1('-'); I(d.day); C1(' '); I(d.hour); C1(':'); I(d.minute); C1(':'); I(d.second); S(" wd"); I(d.weekday); }
static void t_sys_epoch_day(void) { struct PDDateTime d; memset(&d, 0, sizeof d); pd->system->convertEpochToDateTime(86400 * 366 + 3661, &d); I(d.year); C1('-'); I(d.month); C1('-'); I(d.day); C1(' '); I(d.hour); C1(':'); I(d.minute); C1(':'); I(d.second); S(" wd"); I(d.weekday); }
static void t_sys_epoch_roundtrip(void) { struct PDDateTime d = { .year = 2024, .month = 3, .day = 4, .weekday = 1, .hour = 5, .minute = 6, .second = 7 }; uint32_t e = pd->system->convertDateTimeToEpoch(&d); I(e); }
static void t_sys_format(void) { char* s = NULL; int n = pd->system->formatString(&s, "%d|%5d|%-4d|%x|%s|%c|%%", 42, -7, 3, 255, "hi", 'Z'); I(n); SEP(); S(s); pd->system->realloc(s, 0); }
static void t_sys_format_float(void) { char* s = NULL; int n = pd->system->formatString(&s, "%.2f|%g|%e", 3.14159, 0.5, 12345.0); I(n); SEP(); S(s); pd->system->realloc(s, 0); }
static void t_sys_format_long(void) { char big[1501]; memset(big, 'a', 1500); big[1500] = 0; char* s = NULL; int n = pd->system->formatString(&s, "%s!", big); I(n); SEP(); I(s ? (int)strlen(s) : -1); pd->system->realloc(s, 0); }
static void t_sys_format_wide(void) { char* s = NULL; int n = pd->system->formatString(&s, "%lld|%u|%ld", (long long)1 << 40, 4000000000u, -5L); I(n); SEP(); S(s); pd->system->realloc(s, 0); }
static void t_sys_parse(void) { int a = 0, b = 0; char w[16] = { 0 }; int n = pd->system->parseString("12 34 word", "%d %d %15s", &a, &b, w); I(n); SEP(); I(a); SEP(); I(b); SEP(); S(w); }
static void t_sys_realloc(void) {
    uint8_t* p = pd->system->realloc(NULL, 16);
    for (int i = 0; i < 16; i++) p[i] = (uint8_t)i;
    p = pd->system->realloc(p, 100000);
    int ok = 1; for (int i = 0; i < 16; i++) ok &= p[i] == i;
    I(p != NULL); SEP(); I(ok); SEP(); I(((uintptr_t)p & 3) == 0);
    pd->system->realloc(p, 0);
}
static void t_sys_realloc_zero(void) { void* p = pd->system->realloc(NULL, 0); I(p == NULL); }
static void menu_cb(void* ud) { (void)ud; }
static int ud_value = 1234;
static void t_menu_userdata(void) { PDMenuItem* m = pd->system->addMenuItem("A", menu_cb, &ud_value); void* u = pd->system->getMenuItemUserdata(m); I(u == &ud_value); SEP(); S(pd->system->getMenuItemTitle(m)); pd->system->removeAllMenuItems(); }
static void t_menu_set_userdata(void) { PDMenuItem* m = pd->system->addMenuItem("A", menu_cb, NULL); pd->system->setMenuItemUserdata(m, &ud_value); I(pd->system->getMenuItemUserdata(m) == &ud_value); pd->system->removeAllMenuItems(); }
static void t_menu_checkmark(void) { PDMenuItem* m = pd->system->addCheckmarkMenuItem("C", 1, menu_cb, &ud_value); int a = pd->system->getMenuItemValue(m); pd->system->setMenuItemValue(m, 0); I(a); SEP(); I(pd->system->getMenuItemValue(m)); SEP(); I(pd->system->getMenuItemUserdata(m) == &ud_value); pd->system->removeAllMenuItems(); }
static void t_menu_options(void) { const char* opts[] = { "x", "y", "z" }; PDMenuItem* m = pd->system->addOptionsMenuItem("O", opts, 3, menu_cb, NULL); pd->system->setMenuItemValue(m, 2); I(pd->system->getMenuItemValue(m)); pd->system->removeAllMenuItems(); }
static void t_menu_title(void) { PDMenuItem* m = pd->system->addMenuItem("A", menu_cb, NULL); pd->system->setMenuItemTitle(m, "Bee"); S(pd->system->getMenuItemTitle(m)); pd->system->removeMenuItem(m); }
static void t_menu_fourth(void) { pd->system->addMenuItem("1", menu_cb, NULL); pd->system->addMenuItem("2", menu_cb, NULL); pd->system->addMenuItem("3", menu_cb, NULL); PDMenuItem* m = pd->system->addMenuItem("4", menu_cb, NULL); I(m == NULL); pd->system->removeAllMenuItems(); }
static void t_sys_launchargs(void) { const char* path = NULL; const char* a = pd->system->getLaunchArgs(&path); I(a == NULL); }
static void t_sys_power(void) { PDPowerStatus s = pd->system->getPowerStatus(); I((int)s >= 0); }
static void t_sys_volume(void) { float v = pd->system->getVolume(); I(v >= 0 && v <= 1); }
static void t_sys_info(void) { const struct PDInfo* i = pd->system->getSystemInfo(); I(i != NULL); }
static void t_sys_localized(void) { char* t = pd->system->getLocalizedText("no_such_key", kPDLanguageEnglish); S(t ? t : "NULL"); }
static void t_sys_delay(void) { unsigned int a = pd->system->getCurrentTimeMilliseconds(); pd->system->delay(20); unsigned int b = pd->system->getCurrentTimeMilliseconds(); I(b - a >= 15); }

// ---------- display ----------
static void t_display_size(void) { I(pd->display->getWidth()); SEP(); I(pd->display->getHeight()); }
static void t_display_scale(void) { pd->display->setScale(2); int w = pd->display->getWidth(); pd->display->setScale(1); I(w); SEP(); I(pd->display->getWidth()); }
static void t_display_refresh(void) { pd->display->setRefreshRate(20); F(pd->display->getRefreshRate()); pd->display->setRefreshRate(30); }
static void t_display_misc(void) { pd->display->setInverted(1); pd->display->setInverted(0); pd->display->setMosaic(1, 1); pd->display->setMosaic(0, 0); pd->display->setFlipped(0, 0); pd->display->setOffset(2, 2); pd->display->setOffset(0, 0); S("ok"); }

// ---------- files ----------
static void t_file_write_read(void) {
    SDFile* f = pd->file->open("c1.txt", kFileWrite); int w = pd->file->write(f, "hello\nworld", 11); pd->file->close(f);
    f = pd->file->open("c1.txt", kFileReadData); char b[32] = { 0 }; int r = pd->file->read(f, b, 31); pd->file->close(f);
    I(w); SEP(); I(r); SEP(); S(b);
}
static void t_file_seek_tell(void) {
    SDFile* f = pd->file->open("c1.txt", kFileReadData);
    pd->file->seek(f, 3, SEEK_SET); int a = pd->file->tell(f);
    pd->file->seek(f, 2, SEEK_CUR); int b = pd->file->tell(f);
    pd->file->seek(f, -1, SEEK_END); int c = pd->file->tell(f);
    char ch = 0; pd->file->read(f, &ch, 1); pd->file->close(f);
    I(a); SEP(); I(b); SEP(); I(c); SEP(); C1(ch);
}
static void t_file_append(void) {
    SDFile* f = pd->file->open("c2.txt", kFileWrite); pd->file->write(f, "a", 1); pd->file->close(f);
    f = pd->file->open("c2.txt", kFileAppend); pd->file->write(f, "b", 1); pd->file->close(f);
    f = pd->file->open("c2.txt", kFileReadData); char b[8] = { 0 }; pd->file->read(f, b, 7); pd->file->close(f); S(b);
}
static void t_file_read_eof(void) { SDFile* f = pd->file->open("c2.txt", kFileReadData); char b[8]; pd->file->read(f, b, 8); int r = pd->file->read(f, b, 8); pd->file->close(f); I(r); }
static void t_file_open_missing(void) { SDFile* f = pd->file->open("nope/none.txt", kFileReadData); I(f == NULL); SEP(); const char* e = pd->file->geterr(); I(e != NULL && e[0] != 0); }
static void t_file_stat(void) { FileStat st; memset(&st, 0, sizeof st); int r = pd->file->stat("c1.txt", &st); I(r); SEP(); I(st.isdir); SEP(); I(st.size); SEP(); I(st.m_year > 2000); SEP(); I(st.m_month >= 1 && st.m_month <= 12); }
static void t_file_stat_missing(void) { FileStat st; I(pd->file->stat("zzz", &st)); }
static int list_count; static char list_names[256]; static int list_len;
static void list_cb(const char* path, void* ud) { (void)ud; list_count++; int n = (int)strlen(path); if (list_len + n + 2 < (int)sizeof list_names) { if (list_len) list_names[list_len++] = ','; memcpy(list_names + list_len, path, n); list_len += n; list_names[list_len] = 0; } }
static void t_file_mkdir_list(void) {
    pd->file->mkdir("cd"); pd->file->mkdir("cd/sub");
    SDFile* f = pd->file->open("cd/x.txt", kFileWrite); pd->file->write(f, "1", 1); pd->file->close(f);
    list_count = 0; list_len = 0; list_names[0] = 0;
    int r = pd->file->listfiles("cd", list_cb, NULL, 0);
    I(r); SEP(); I(list_count); SEP(); S(list_names);
}
static void t_file_rename_unlink(void) {
    SDFile* f = pd->file->open("rn1.txt", kFileWrite); pd->file->write(f, "1", 1); pd->file->close(f);
    int a = pd->file->rename("rn1.txt", "rn2.txt"); FileStat st; int b = pd->file->stat("rn1.txt", &st); int c = pd->file->stat("rn2.txt", &st);
    int d = pd->file->unlink("rn2.txt", 0); I(a); SEP(); I(b); SEP(); I(c); SEP(); I(d);
}
static void t_file_unlink_dir(void) { int a = pd->file->unlink("cd", 0); int b = pd->file->unlink("cd", 1); FileStat st; I(a); SEP(); I(b); SEP(); I(pd->file->stat("cd", &st)); }
static void t_file_flush(void) { SDFile* f = pd->file->open("fl.txt", kFileWrite); pd->file->write(f, "x", 1); int r = pd->file->flush(f); pd->file->close(f); I(r); }
static void t_file_read_pdx(void) { SDFile* f = pd->file->open("pdxinfo", kFileRead); I(f != NULL); if (f) { char b[6] = { 0 }; pd->file->read(f, b, 5); SEP(); S(b); pd->file->close(f); } }

// ---------- graphics ----------
static void t_gfx_bitmap_data(void) { LCDBitmap* b = pd->graphics->newBitmap(10, 3, kColorBlack); int w, h, rb; uint8_t *m = (uint8_t*)1, *d = NULL; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); I(w); SEP(); I(h); SEP(); I(rb); SEP(); I(m == NULL); SEP(); I(d[0]); pd->graphics->freeBitmap(b); }
static void t_gfx_bitmap_clear_color(void) { LCDBitmap* b = pd->graphics->newBitmap(4, 2, kColorClear); PIX(b); pd->graphics->freeBitmap(b); }
static void t_gfx_bitmap_pixel(void) { LCDBitmap* b = pd->graphics->newBitmap(4, 4, kColorWhite); pd->graphics->pushContext(b); pd->graphics->setPixel(1, 2, kColorBlack); pd->graphics->popContext(); I(pd->graphics->getBitmapPixel(b, 1, 2)); SEP(); I(pd->graphics->getBitmapPixel(b, 0, 0)); SEP(); I(pd->graphics->getBitmapPixel(b, 9, 9)); pd->graphics->freeBitmap(b); }
static void t_gfx_clear_bitmap(void) { LCDBitmap* b = pd->graphics->newBitmap(4, 2, kColorWhite); pd->graphics->clearBitmap(b, kColorBlack); PIX(b); pd->graphics->freeBitmap(b); }
static void t_gfx_copy_bitmap(void) { LCDBitmap* b = pd->graphics->newBitmap(3, 2, kColorBlack); LCDBitmap* c = pd->graphics->copyBitmap(b); PIX(c); pd->graphics->freeBitmap(b); pd->graphics->freeBitmap(c); }
static void t_gfx_clear(void) { DRAW(4, 4, pd->graphics->clear(kColorBlack)); }
static void t_gfx_fillrect(void) { DRAW(12, 8, pd->graphics->fillRect(2, 1, 6, 4, kColorBlack)); }
static void t_gfx_fillrect_negative(void) { DRAW(12, 8, pd->graphics->fillRect(8, 6, -5, -3, kColorBlack)); }
static void t_gfx_drawrect(void) { DRAW(12, 8, pd->graphics->drawRect(2, 1, 6, 4, kColorBlack)); }
static void t_gfx_drawline(void) { DRAW(16, 16, pd->graphics->drawLine(1, 1, 14, 9, 1, kColorBlack)); }
static void t_gfx_drawline_wide(void) { DRAW(16, 12, pd->graphics->drawLine(2, 5, 13, 5, 3, kColorBlack)); }
static void t_gfx_drawline_cap(void) { DRAW(20, 12, pd->graphics->setLineCapStyle(kLineCapStyleRound); pd->graphics->drawLine(4, 5, 15, 5, 5, kColorBlack)); }
static void t_gfx_triangle(void) { DRAW(24, 24, pd->graphics->fillTriangle(2, 20, 12, 2, 21, 18, kColorBlack)); }
static void t_gfx_ellipse(void) { DRAW(24, 24, pd->graphics->drawEllipse(2, 2, 18, 18, 1, 0, 0, kColorBlack)); }
static void t_gfx_ellipse_wide(void) { DRAW(24, 24, pd->graphics->drawEllipse(2, 2, 18, 18, 3, 0, 0, kColorBlack)); }
static void t_gfx_ellipse_arc(void) { DRAW(32, 32, pd->graphics->drawEllipse(2, 2, 27, 27, 1, 30, 200, kColorBlack)); }
static void t_gfx_fillellipse(void) { DRAW(24, 24, pd->graphics->fillEllipse(2, 2, 18, 18, 0, 0, kColorBlack)); }
static void t_gfx_fillellipse_arc(void) { DRAW(32, 32, pd->graphics->fillEllipse(2, 2, 27, 27, 30, 200, kColorBlack)); }
static void t_gfx_roundrect(void) { DRAW(24, 16, pd->graphics->drawRoundRect(2, 2, 19, 11, 4, 1, kColorBlack)); }
static void t_gfx_roundrect_wide(void) { DRAW(24, 16, pd->graphics->drawRoundRect(2, 2, 19, 11, 4, 3, kColorBlack)); }
static void t_gfx_fillroundrect(void) { DRAW(24, 16, pd->graphics->fillRoundRect(2, 2, 19, 11, 4, kColorBlack)); }
static void t_gfx_polygon_evenodd(void) { int pts[] = { 16, 1, 25, 30, 1, 11, 31, 11, 7, 30 }; DRAW(32, 32, pd->graphics->fillPolygon(5, pts, kColorBlack, kPolygonFillEvenOdd)); }
static void t_gfx_polygon_nonzero(void) { int pts[] = { 16, 1, 25, 30, 1, 11, 31, 11, 7, 30 }; DRAW(32, 32, pd->graphics->fillPolygon(5, pts, kColorBlack, kPolygonFillNonZero)); }
static uint8_t checker[16] = { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
static void t_gfx_pattern_color(void) { DRAW(16, 16, pd->graphics->fillRect(0, 0, 16, 16, (LCDColor)checker)); }
static void t_gfx_offset(void) { DRAW(16, 16, pd->graphics->setDrawOffset(3, 2); pd->graphics->fillRect(0, 0, 4, 4, kColorBlack)); }
static void t_gfx_clip(void) { DRAW(16, 16, pd->graphics->setClipRect(4, 4, 6, 6); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack)); }
static void t_gfx_clip_offset(void) { DRAW(16, 16, pd->graphics->setDrawOffset(2, 2); pd->graphics->setClipRect(4, 4, 6, 6); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack)); }
static void t_gfx_screenclip(void) { DRAW(16, 16, pd->graphics->setDrawOffset(2, 2); pd->graphics->setScreenClipRect(4, 4, 6, 6); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack)); }
static void t_gfx_drawmode_return(void) { LCDBitmapDrawMode a = pd->graphics->setDrawMode(kDrawModeXOR); LCDBitmapDrawMode b = pd->graphics->setDrawMode(kDrawModeCopy); I(a); SEP(); I(b); }
static LCDBitmap* srcbmp(void) {
    LCDBitmap* b = pd->graphics->newBitmap(8, 6, kColorClear);
    pd->graphics->pushContext(b); pd->graphics->fillRect(0, 0, 4, 6, kColorBlack); pd->graphics->fillRect(4, 0, 2, 6, kColorWhite); pd->graphics->popContext();
    return b;
}
static void drawmode_case(LCDBitmapDrawMode m) { LCDBitmap* s = srcbmp(); DRAW(12, 10, pd->graphics->fillRect(0, 5, 12, 5, kColorBlack); pd->graphics->setDrawMode(m); pd->graphics->drawBitmap(s, 2, 2, kBitmapUnflipped)); pd->graphics->freeBitmap(s); }
static void t_gfx_mode_copy(void) { drawmode_case(kDrawModeCopy); }
static void t_gfx_mode_whitetr(void) { drawmode_case(kDrawModeWhiteTransparent); }
static void t_gfx_mode_blacktr(void) { drawmode_case(kDrawModeBlackTransparent); }
static void t_gfx_mode_fillwhite(void) { drawmode_case(kDrawModeFillWhite); }
static void t_gfx_mode_fillblack(void) { drawmode_case(kDrawModeFillBlack); }
static void t_gfx_mode_xor(void) { drawmode_case(kDrawModeXOR); }
static void t_gfx_mode_nxor(void) { drawmode_case(kDrawModeNXOR); }
static void t_gfx_mode_inverted(void) { drawmode_case(kDrawModeInverted); }
static void t_gfx_flip(void) { LCDBitmap* s = srcbmp(); DRAW(12, 10, pd->graphics->drawBitmap(s, 2, 2, kBitmapFlippedX)); pd->graphics->freeBitmap(s); }
static void t_gfx_tile(void) { LCDBitmap* s = srcbmp(); DRAW(20, 14, pd->graphics->tileBitmap(s, 1, 1, 18, 12, kBitmapUnflipped)); pd->graphics->freeBitmap(s); }
static void t_gfx_scaled(void) { LCDBitmap* s = srcbmp(); DRAW(20, 16, pd->graphics->drawScaledBitmap(s, 1, 1, 2, 1)); pd->graphics->freeBitmap(s); }
static void t_gfx_scaled_negative(void) { LCDBitmap* s = srcbmp(); DRAW(20, 16, pd->graphics->drawScaledBitmap(s, 18, 1, -2, 1)); pd->graphics->freeBitmap(s); }
static void t_gfx_rotated(void) { LCDBitmap* s = srcbmp(); DRAW(20, 20, pd->graphics->drawRotatedBitmap(s, 10, 10, 90, 0.5f, 0.5f, 1, 1)); pd->graphics->freeBitmap(s); }
static void t_gfx_rotated_bitmap(void) { LCDBitmap* s = srcbmp(); int alloced = -1; LCDBitmap* r = pd->graphics->rotatedBitmap(s, 90, 1, 1, &alloced); PIX(r); SEP(); I(alloced > 0); pd->graphics->freeBitmap(s); pd->graphics->freeBitmap(r); }
static void t_gfx_rotated_bitmap_null(void) { LCDBitmap* s = srcbmp(); LCDBitmap* r = pd->graphics->rotatedBitmap(s, 45, 1, 1, NULL); I(r != NULL); pd->graphics->freeBitmap(s); if (r) pd->graphics->freeBitmap(r); }
static void t_gfx_mask(void) { LCDBitmap* b = pd->graphics->newBitmap(4, 2, kColorBlack); LCDBitmap* m = pd->graphics->newBitmap(4, 2, kColorBlack); pd->graphics->pushContext(m); pd->graphics->fillRect(0, 0, 2, 2, kColorWhite); pd->graphics->popContext(); int r = pd->graphics->setBitmapMask(b, m); I(r); SEP(); PIX(b); SEP(); PIX(pd->graphics->getBitmapMask(b)); pd->graphics->freeBitmap(b); pd->graphics->freeBitmap(m); }
static void t_gfx_mask_none(void) { LCDBitmap* b = pd->graphics->newBitmap(4, 2, kColorBlack); I(pd->graphics->getBitmapMask(b) == NULL); pd->graphics->freeBitmap(b); }
static void t_gfx_mask_collision(void) { LCDBitmap* a = pd->graphics->newBitmap(4, 4, kColorBlack); LCDRect r = { 0, 400, 0, 240 }; I(pd->graphics->checkMaskCollision(a, 0, 0, kBitmapUnflipped, a, 2, 2, kBitmapUnflipped, r)); SEP(); I(pd->graphics->checkMaskCollision(a, 0, 0, kBitmapUnflipped, a, 10, 10, kBitmapUnflipped, r)); pd->graphics->freeBitmap(a); }
static void t_gfx_mask_collision_clear(void) { LCDBitmap* a = pd->graphics->newBitmap(4, 4, kColorClear); LCDBitmap* b = pd->graphics->newBitmap(4, 4, kColorBlack); LCDRect r = { 0, 400, 0, 240 }; I(pd->graphics->checkMaskCollision(a, 0, 0, kBitmapUnflipped, b, 1, 1, kBitmapUnflipped, r)); pd->graphics->freeBitmap(a); pd->graphics->freeBitmap(b); }
static void t_gfx_stencil(void) { LCDBitmap* st = pd->graphics->newBitmap(32, 16, kColorBlack); pd->graphics->pushContext(st); pd->graphics->fillRect(0, 0, 8, 16, kColorWhite); pd->graphics->popContext(); DRAW(16, 16, pd->graphics->setStencilImage(st, 0); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack); pd->graphics->setStencilImage(NULL, 0)); pd->graphics->freeBitmap(st); }
static void t_gfx_load_missing_err(void) { const char* err = NULL; LCDBitmap* b = pd->graphics->loadBitmap("assets/none", &err); I(b == NULL); SEP(); I(err != NULL); }
static void t_gfx_load_missing_null(void) { LCDBitmap* b = pd->graphics->loadBitmap("assets/none", NULL); I(b == NULL); }
static void t_gfx_load(void) { const char* err = NULL; LCDBitmap* b = pd->graphics->loadBitmap("assets/img10x6", &err); PIX(b); if (b) pd->graphics->freeBitmap(b); }
static void t_gfx_load_into(void) { LCDBitmap* b = pd->graphics->newBitmap(2, 2, kColorWhite); const char* err = NULL; pd->graphics->loadIntoBitmap("assets/img10x6", b, &err); PIX(b); pd->graphics->freeBitmap(b); }
static void t_gfx_table_new(void) { LCDBitmapTable* t = pd->graphics->newBitmapTable(3, 8, 6); int count = -1, w = -1; pd->graphics->getBitmapTableInfo(t, &count, &w); LCDBitmap* b = pd->graphics->getTableBitmap(t, 1); int bw = -1, bh = -1, rb; uint8_t *m, *d; if (b) pd->graphics->getBitmapData(b, &bw, &bh, &rb, &m, &d); I(count); SEP(); I(w); SEP(); I(b != NULL); SEP(); I(bw); SEP(); I(bh); pd->graphics->freeBitmapTable(t); }
static void t_gfx_table_load(void) { const char* err = NULL; LCDBitmapTable* t = pd->graphics->loadBitmapTable("assets/tiles", &err); int count = -1, w = -1; pd->graphics->getBitmapTableInfo(t, &count, &w); I(count); SEP(); I(w); SEP(); PIX(pd->graphics->getTableBitmap(t, 1)); SEP(); I(pd->graphics->getTableBitmap(t, 3) == NULL); }
static void t_gfx_table_load_missing_null(void) { LCDBitmapTable* t = pd->graphics->loadBitmapTable("assets/none", NULL); I(t == NULL); }
static void t_gfx_frame_buffers(void) { uint8_t* f = pd->graphics->getFrame(); uint8_t* d = pd->graphics->getDisplayFrame(); I(f != NULL); SEP(); I(d != NULL); SEP(); I(f != d); }
static void t_gfx_display_buffer_bitmap(void) { LCDBitmap* b = pd->graphics->getDisplayBufferBitmap(); int w, h, rb; uint8_t *m, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); I(w); SEP(); I(h); SEP(); I(rb); }
static void t_gfx_copy_frame(void) { LCDBitmap* b = pd->graphics->copyFrameBufferBitmap(); int w, h, rb; uint8_t *m, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); I(w); SEP(); I(h); SEP(); I(rb); pd->graphics->freeBitmap(b); }
static void t_gfx_frame_write(void) { uint8_t* f = pd->graphics->getFrame(); memset(f, 0xff, LCD_ROWSIZE * LCD_ROWS); f[0] = 0x0f; pd->graphics->markUpdatedRows(0, 0); LCDBitmap* b = pd->graphics->copyFrameBufferBitmap(); I(pd->graphics->getBitmapPixel(b, 0, 0)); SEP(); I(pd->graphics->getBitmapPixel(b, 7, 0)); pd->graphics->freeBitmap(b); }
static void t_gfx_debug_bitmap(void) { I(pd->graphics->getDebugBitmap != NULL); }
static void t_gfx_font_height(void) { LCDFont* f = pd->graphics->loadFont("/System/Fonts/Asheville-Sans-14-Light.pft", NULL); I(f != NULL); if (f) { SEP(); I(pd->graphics->getFontHeight(f)); } }
static void t_gfx_text_width(void) { I(pd->graphics->getTextWidth(NULL, "Hello world", 11, kASCIIEncoding, 0)); SEP(); I(pd->graphics->getTextWidth(NULL, "Hello world", 11, kASCIIEncoding, 2)); }
static void t_gfx_text_width_utf8(void) { I(pd->graphics->getTextWidth(NULL, "caf\xc3\xa9", 5, kUTF8Encoding, 0)); }
static void t_gfx_text_draw(void) { DRAW(64, 20, pd->graphics->drawText("Hi 12", 5, kASCIIEncoding, 1, 1)); }
static void t_gfx_text_draw_return(void) { LCDBitmap* c = canvas(64, 20); pd->graphics->pushContext(c); int w = pd->graphics->drawText("Hi 12", 5, kASCIIEncoding, 1, 1); pd->graphics->popContext(); pd->graphics->freeBitmap(c); I(w); }
static void t_gfx_text_tracking(void) { pd->graphics->setTextTracking(3); I(pd->graphics->getTextTracking()); pd->graphics->setTextTracking(0); }
static void t_gfx_text_in_rect(void) { DRAW(48, 48, pd->graphics->drawTextInRect("one two three four", 18, kASCIIEncoding, 1, 1, 46, 46, kWrapWord, kAlignTextLeft)); }
static void t_gfx_text_in_rect_center(void) { DRAW(48, 48, pd->graphics->drawTextInRect("one two three", 13, kASCIIEncoding, 1, 1, 46, 46, kWrapWord, kAlignTextCenter)); }
static void t_gfx_text_height(void) { I(pd->graphics->getTextHeightForMaxWidth(NULL, "one two three four", 18, 40, kASCIIEncoding, kWrapWord, 0, 0)); }
static void t_gfx_glyph(void) { LCDFont* f = pd->graphics->loadFont("/System/Fonts/Asheville-Sans-14-Light.pft", NULL); LCDBitmap* b = NULL; int adv = -1; LCDFontGlyph* g = f ? pd->graphics->getFontGlyph(f, 'A', &b, &adv) : NULL; I(g != NULL); SEP(); I(adv); SEP(); I(b != NULL); }
static void t_gfx_page_glyph(void) { LCDFont* f = pd->graphics->loadFont("/System/Fonts/Asheville-Sans-14-Light.pft", NULL); LCDFontPage* p = f ? pd->graphics->getFontPage(f, 'A') : NULL; LCDBitmap* b = NULL; int adv = -1; LCDFontGlyph* g = p ? pd->graphics->getPageGlyph(p, 'A', &b, &adv) : NULL; I(p != NULL); SEP(); I(g != NULL); SEP(); I(adv); SEP(); I(g ? pd->graphics->getGlyphKerning(g, 'A', 'V') : -99); }

static void t_gfx_raw_layout(void) { LCDBitmap* b = pd->graphics->newBitmap(10, 3, kColorWhite); pd->graphics->pushContext(b); pd->graphics->fillRect(0, 1, 3, 1, kColorBlack); pd->graphics->fillRect(9, 2, 1, 1, kColorBlack); pd->graphics->popContext(); RAW(b); pd->graphics->freeBitmap(b); }
static void t_gfx_raw_write(void) { LCDBitmap* b = pd->graphics->newBitmap(10, 3, kColorWhite); int w, h, rb; uint8_t *m, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); d[rb * 1] = 0x0f; PIX(b); pd->graphics->freeBitmap(b); }
static void t_gfx_raw_mask_layout(void) { LCDBitmap* b = pd->graphics->newBitmap(10, 2, kColorClear); int w, h, rb; uint8_t *m = NULL, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); I(rb); SEP(); I(m != NULL); if (m) { SEP(); I(m[0]); SEP(); I(m[rb]); } pd->graphics->freeBitmap(b); }

// ---------- tilemap and video ----------
static LCDBitmapTable* table3(void) {
    LCDBitmapTable* t = pd->graphics->newBitmapTable(3, 8, 8);
    LCDBitmap* b;
    b = pd->graphics->getTableBitmap(t, 0); if (b) pd->graphics->clearBitmap(b, kColorWhite);
    b = pd->graphics->getTableBitmap(t, 1); if (b) pd->graphics->clearBitmap(b, kColorBlack);
    b = pd->graphics->getTableBitmap(t, 2); if (b) { pd->graphics->clearBitmap(b, kColorWhite); pd->graphics->pushContext(b); for (int i = 0; i < 8; i++) pd->graphics->setPixel(i, i, kColorBlack); pd->graphics->popContext(); }
    return t;
}
static void t_tilemap_basic(void) {
    LCDTileMap* m = pd->graphics->tilemap->newTilemap(); pd->graphics->tilemap->setImageTable(m, table3());
    uint16_t tiles[] = { 0, 1, 2, 1, 0, 1 }; pd->graphics->tilemap->setTiles(m, tiles, 6, 3);
    int w = -1, h = -1; uint32_t pw = 0, ph = 0; pd->graphics->tilemap->getSize(m, &w, &h); pd->graphics->tilemap->getPixelSize(m, &pw, &ph);
    pd->graphics->tilemap->setTileAtPosition(m, 0, 1, 2);
    I(w); SEP(); I(h); SEP(); I(pw); SEP(); I(ph); SEP(); I(pd->graphics->tilemap->getTileAtPosition(m, 1, 0)); SEP(); I(pd->graphics->tilemap->getTileAtPosition(m, 0, 1)); SEP(); I(pd->graphics->tilemap->getTileAtPosition(m, 9, 9));
}
static void t_tilemap_draw(void) { LCDTileMap* m = pd->graphics->tilemap->newTilemap(); pd->graphics->tilemap->setImageTable(m, table3()); uint16_t tiles[] = { 0, 1, 2, 1, 0, 1 }; pd->graphics->tilemap->setTiles(m, tiles, 6, 3); DRAW(24, 16, pd->graphics->tilemap->drawAtPoint(m, 0, 0)); }
static void t_video_load(void) { LCDVideoPlayer* v = pd->graphics->video->loadVideo("video/appear_frames"); I(v != NULL); if (v) { int w, h, fc, cf; float fr; pd->graphics->video->getInfo(v, &w, &h, &fr, &fc, &cf); SEP(); I(w); SEP(); I(h); SEP(); F(fr); SEP(); I(fc); pd->graphics->video->freePlayer(v); } }
static void t_video_missing(void) { LCDVideoPlayer* v = pd->graphics->video->loadVideo("video/none"); I(v == NULL); }

// ---------- sprites ----------
static LCDSprite* box(float x, float y, float w, float h) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(x, y, w, h)); pd->sprite->setCollideRect(s, PDRectMake(0, 0, w, h)); pd->sprite->addSprite(s); return s; }
static void t_sprite_bounds(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(5, 6, 7, 8)); float x, y; pd->sprite->getPosition(s, &x, &y); RECT(pd->sprite->getBounds(s)); SEP(); F(x); SEP(); F(y); pd->sprite->freeSprite(s); }
static void t_sprite_move(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setSize(s, 10, 6); pd->sprite->moveTo(s, 50, 40); pd->sprite->moveBy(s, 1, 2); float x, y; pd->sprite->getPosition(s, &x, &y); F(x); SEP(); F(y); SEP(); RECT(pd->sprite->getBounds(s)); pd->sprite->freeSprite(s); }
static void t_sprite_center(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setSize(s, 10, 6); pd->sprite->setCenter(s, 0, 0); pd->sprite->moveTo(s, 50, 40); float cx, cy; pd->sprite->getCenter(s, &cx, &cy); RECT(pd->sprite->getBounds(s)); SEP(); F(cx); SEP(); F(cy); pd->sprite->freeSprite(s); }
static void t_sprite_image_size(void) { LCDSprite* s = pd->sprite->newSprite(); LCDBitmap* b = srcbmp(); pd->sprite->setImage(s, b, kBitmapUnflipped); RECT(pd->sprite->getBounds(s)); SEP(); I(pd->sprite->getImage(s) == b); pd->sprite->freeSprite(s); }
static void t_sprite_props(void) {
    LCDSprite* s = pd->sprite->newSprite();
    pd->sprite->setZIndex(s, -7); pd->sprite->setTag(s, 200); pd->sprite->setVisible(s, 0); pd->sprite->setUpdatesEnabled(s, 0); pd->sprite->setCollisionsEnabled(s, 0); pd->sprite->setImageFlip(s, kBitmapFlippedY);
    I(pd->sprite->getZIndex(s)); SEP(); I(pd->sprite->getTag(s)); SEP(); I(pd->sprite->isVisible(s)); SEP(); I(pd->sprite->updatesEnabled(s)); SEP(); I(pd->sprite->collisionsEnabled(s)); SEP(); I(pd->sprite->getImageFlip(s));
    pd->sprite->freeSprite(s);
}
static void t_sprite_defaults(void) { LCDSprite* s = pd->sprite->newSprite(); I(pd->sprite->getZIndex(s)); SEP(); I(pd->sprite->isVisible(s)); SEP(); I(pd->sprite->updatesEnabled(s)); SEP(); I(pd->sprite->collisionsEnabled(s)); SEP(); RECT(pd->sprite->getBounds(s)); SEP(); RECT(pd->sprite->getCollideRect(s)); pd->sprite->freeSprite(s); }
static void t_sprite_userdata(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setUserdata(s, &ud_value); I(pd->sprite->getUserdata(s) == &ud_value); pd->sprite->freeSprite(s); }
static void t_sprite_copy(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(1, 2, 3, 4)); pd->sprite->setTag(s, 9); LCDSprite* c = pd->sprite->copy(s); RECT(pd->sprite->getBounds(c)); SEP(); I(pd->sprite->getTag(c)); pd->sprite->freeSprite(s); pd->sprite->freeSprite(c); }
static void t_sprite_count(void) { pd->sprite->removeAllSprites(); LCDSprite* a = pd->sprite->newSprite(); LCDSprite* b = pd->sprite->newSprite(); pd->sprite->addSprite(a); pd->sprite->addSprite(b); int n1 = pd->sprite->getSpriteCount(); pd->sprite->removeSprite(a); int n2 = pd->sprite->getSpriteCount(); LCDSprite* arr[] = { b }; pd->sprite->removeSprites(arr, 1); I(n1); SEP(); I(n2); SEP(); I(pd->sprite->getSpriteCount()); }
static void t_sprite_collide_rect(void) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(20, 20, 10, 10)); pd->sprite->setCollideRect(s, PDRectMake(1, 2, 3, 4)); RECT(pd->sprite->getCollideRect(s)); pd->sprite->clearCollideRect(s); SEP(); RECT(pd->sprite->getCollideRect(s)); pd->sprite->freeSprite(s); }
static void colinfo(SpriteCollisionInfo* c, int n) { for (int i = 0; i < n; i++) { if (i) C1(';'); I(c[i].responseType); C1(','); I(c[i].overlaps); S(",ti"); F(c[i].ti); S(",move("); F(c[i].move.x); C1(','); F(c[i].move.y); S("),n("); I(c[i].normal.x); C1(','); I(c[i].normal.y); S("),touch("); F(c[i].touch.x); C1(','); F(c[i].touch.y); C1(')'); } }
static void t_sprite_move_collisions_default(void) {
    pd->sprite->removeAllSprites(); LCDSprite* a = box(0, 0, 10, 10); box(20, 0, 10, 10);
    pd->sprite->setCenter(a, 0, 0); pd->sprite->moveTo(a, 0, 0);
    float x, y; int n = 0; SpriteCollisionInfo* c = pd->sprite->moveWithCollisions(a, 15, 3, &x, &y, &n);
    F(x); SEP(); F(y); SEP(); I(n); SEP(); colinfo(c, n); if (c) pd->system->realloc(c, 0); pd->sprite->removeAllSprites();
}
static SpriteCollisionResponseType resp_slide(LCDSprite* s, LCDSprite* o) { (void)s; (void)o; return kCollisionTypeSlide; }
static SpriteCollisionResponseType resp_overlap(LCDSprite* s, LCDSprite* o) { (void)s; (void)o; return kCollisionTypeOverlap; }
static SpriteCollisionResponseType resp_bounce(LCDSprite* s, LCDSprite* o) { (void)s; (void)o; return kCollisionTypeBounce; }
static void move_resp(LCDSpriteCollisionFilterProc* f) {
    pd->sprite->removeAllSprites(); LCDSprite* a = box(0, 0, 10, 10); box(20, 0, 10, 10);
    pd->sprite->setCenter(a, 0, 0); pd->sprite->moveTo(a, 0, 0); pd->sprite->setCollisionResponseFunction(a, f);
    float x, y; int n = 0; SpriteCollisionInfo* c = pd->sprite->moveWithCollisions(a, 15, 3, &x, &y, &n);
    F(x); SEP(); F(y); SEP(); I(n); SEP(); colinfo(c, n); if (c) pd->system->realloc(c, 0); pd->sprite->removeAllSprites();
}
static void t_sprite_move_slide(void) { move_resp(resp_slide); }
static void t_sprite_move_overlap(void) { move_resp(resp_overlap); }
static void t_sprite_move_bounce(void) { move_resp(resp_bounce); }
static void t_sprite_check_collisions(void) { pd->sprite->removeAllSprites(); LCDSprite* a = box(0, 0, 10, 10); box(20, 0, 10, 10); pd->sprite->setCenter(a, 0, 0); pd->sprite->moveTo(a, 0, 0); float x, y; int n = 0; SpriteCollisionInfo* c = pd->sprite->checkCollisions(a, 15, 0, &x, &y, &n); float px, py; pd->sprite->getPosition(a, &px, &py); F(x); SEP(); I(n); SEP(); F(px); if (c) pd->system->realloc(c, 0); pd->sprite->removeAllSprites(); }
static void q_setup(void) { pd->sprite->removeAllSprites(); box(0, 0, 10, 10); box(5, 5, 10, 10); box(30, 30, 10, 10); }
static void t_sprite_query_point(void) { q_setup(); int n = -1; pd->sprite->querySpritesAtPoint(7, 7, &n); I(n); pd->sprite->removeAllSprites(); }
static void t_sprite_query_rect(void) { q_setup(); int n = -1, m = -1; pd->sprite->querySpritesInRect(5, 5, 10, 10, &n); pd->sprite->querySpritesInRect(100, 100, 5, 5, &m); I(n); SEP(); I(m); pd->sprite->removeAllSprites(); }
static void t_sprite_query_line(void) { q_setup(); int n = -1; pd->sprite->querySpritesAlongLine(0, 2, 50, 2, &n); I(n); pd->sprite->removeAllSprites(); }
static void t_sprite_query_all_overlapping(void) { q_setup(); int n = -1; pd->sprite->allOverlappingSprites(&n); I(n); pd->sprite->removeAllSprites(); }
static void t_sprite_query_info_line(void) { q_setup(); int n = -1; SpriteQueryInfo* q = pd->sprite->querySpriteInfoAlongLine(0, 2, 50, 2, &n); I(n); if (q && n > 0) { SEP(); F(q[0].ti1); C1(','); F(q[0].ti2); C1(','); F(q[0].entryPoint.x); C1(','); F(q[0].exitPoint.x); } pd->sprite->removeAllSprites(); }
static void t_sprite_overlapping(void) { pd->sprite->removeAllSprites(); LCDSprite* a = box(0, 0, 10, 10); box(5, 5, 10, 10); box(50, 50, 5, 5); int n = 0; void* r = pd->sprite->overlappingSprites(a, &n); if (r) pd->system->realloc(r, 0); I(n); pd->sprite->removeAllSprites(); }
static char order_log[64]; static int order_len;
static void upd(LCDSprite* s) { int z = pd->sprite->getZIndex(s); if (order_len < 60) { if (order_len) order_log[order_len++] = ','; order_log[order_len++] = (char)('0' + z); order_log[order_len] = 0; } }
static PDRect last_bounds, last_draw; static int draw_calls;
static void drw(LCDSprite* s, PDRect bounds, PDRect drawrect) { (void)s; last_bounds = bounds; last_draw = drawrect; draw_calls++; }
static void t_sprite_update_order(void) {
    pd->sprite->removeAllSprites(); order_len = 0; order_log[0] = 0;
    int zs[] = { 3, 1, 2 };
    for (int i = 0; i < 3; i++) { LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setZIndex(s, (int16_t)zs[i]); pd->sprite->setUpdateFunction(s, upd); pd->sprite->addSprite(s); }
    pd->sprite->updateAndDrawSprites(); S(order_log); pd->sprite->removeAllSprites();
}
static void t_sprite_draw_callback(void) {
    pd->sprite->removeAllSprites(); draw_calls = 0;
    LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(5, 6, 10, 8)); pd->sprite->setDrawFunction(s, drw); pd->sprite->addSprite(s);
    pd->sprite->setAlwaysRedraw(1); pd->sprite->updateAndDrawSprites(); pd->sprite->setAlwaysRedraw(0);
    I(draw_calls > 0); SEP(); RECT(last_bounds); SEP(); RECT(last_draw); pd->sprite->removeAllSprites();
}
static void t_sprite_tilemap(void) { LCDTileMap* m = pd->graphics->tilemap->newTilemap(); pd->graphics->tilemap->setImageTable(m, table3()); uint16_t tiles[] = { 0, 1, 2, 1 }; pd->graphics->tilemap->setTiles(m, tiles, 4, 2); LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setTilemap(s, m); I(pd->sprite->getTilemap(s) == m); SEP(); RECT(pd->sprite->getBounds(s)); pd->sprite->freeSprite(s); }
static void t_sprite_misc(void) { LCDSprite* s = pd->sprite->newSprite(); uint8_t pat[8] = { 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0 }; pd->sprite->setStencilPattern(s, pat); pd->sprite->clearStencil(s); pd->sprite->setOpaque(s, 1); pd->sprite->setIgnoresDrawOffset(s, 1); pd->sprite->setDrawMode(s, kDrawModeXOR); LCDRect r = { 0, 10, 0, 10 }; pd->sprite->setClipRect(s, r); pd->sprite->clearClipRect(s); pd->sprite->markDirty(s); pd->sprite->markDirtyRect(s, PDRectMake(0, 0, 1, 1)); pd->sprite->addDirtyRect(r); pd->sprite->setClipRectsInRange(r, 0, 10); pd->sprite->clearClipRectsInRange(0, 10); pd->sprite->resetCollisionWorld(); pd->sprite->freeSprite(s); S("ok"); }

// ---------- JSON ----------
static char jbuf[512]; static int jlen;
static void jwrite(void* ud, const char* str, int len) { (void)ud; for (int i = 0; i < len && jlen < (int)sizeof(jbuf) - 1; i++) jbuf[jlen++] = str[i]; jbuf[jlen] = 0; }
static void encode_sample(int pretty) {
    json_encoder e; jlen = 0; jbuf[0] = 0; pd->json->initEncoder(&e, jwrite, NULL, pretty);
    e.startTable(&e);
    e.addTableMember(&e, "a", 1); e.writeInt(&e, 1);
    e.addTableMember(&e, "b", 1); e.startArray(&e); e.addArrayMember(&e); e.writeInt(&e, 2); e.addArrayMember(&e); e.writeDouble(&e, 2.5); e.addArrayMember(&e); e.writeString(&e, "q\"x", 3); e.endArray(&e);
    e.addTableMember(&e, "c", 1); e.writeTrue(&e);
    e.addTableMember(&e, "d", 1); e.writeFalse(&e);
    e.addTableMember(&e, "e", 1); e.writeNull(&e);
    e.endTable(&e);
}
static void t_json_encode(void) { encode_sample(0); S(jbuf); }
static void t_json_encode_pretty(void) { encode_sample(1); for (int i = 0; jbuf[i]; i++) { if (jbuf[i] == '\n') S("\\n"); else if (jbuf[i] == '\t') S("\\t"); else C1(jbuf[i]); } }
static char dlog[1024]; static int dlen;
static void dl(const char* s) { while (*s && dlen < (int)sizeof(dlog) - 1) dlog[dlen++] = *s++; dlog[dlen] = 0; }
static void dl_int(int v) { char t[16]; int n = 0; int neg = v < 0; unsigned u = neg ? (unsigned)(-v) : (unsigned)v; do { t[n++] = (char)('0' + u % 10); u /= 10; } while (u); if (neg) dl("-"); char r[2] = { 0, 0 }; while (n) { r[0] = t[--n]; dl(r); } }
static void dl_val(json_value v) { dl_int(v.type); dl(":"); if (v.type == kJSONInteger) dl_int(v.data.intval); else if (v.type == kJSONFloat) dl_int((int)(v.data.floatval * 100)); else if (v.type == kJSONString) dl(v.data.stringval); }
static void d_err(json_decoder* d, const char* e, int line) { (void)d; dl("ERR("); dl(e ? "msg" : "nomsg"); dl(","); dl_int(line); dl(")"); }
static void d_will(json_decoder* d, const char* name, json_value_type t) { (void)d; dl("will("); dl(name ? name : "-"); dl(","); dl_int(t); dl(")"); }
static void d_table(json_decoder* d, const char* key, json_value v) { (void)d; dl("tv("); dl(key); dl("="); dl_val(v); dl(")"); }
static void d_array(json_decoder* d, int pos, json_value v) { (void)d; dl("av("); dl_int(pos); dl("="); dl_val(v); dl(")"); }
static void* d_did(json_decoder* d, const char* name, json_value_type t) { (void)d; dl("did("); dl(name ? name : "-"); dl(","); dl_int(t); dl(")"); return NULL; }
static int decode(const char* s) {
    json_decoder d; memset(&d, 0, sizeof d); dlen = 0; dlog[0] = 0;
    d.decodeError = d_err; d.willDecodeSublist = d_will; d.didDecodeTableValue = d_table; d.didDecodeArrayValue = d_array; d.didDecodeSublist = d_did;
    json_value v; memset(&v, 0, sizeof v);
    int r = pd->json->decodeString(&d, s, &v);
    return r;
}
static void t_json_decode_table(void) { int r = decode("{\"a\":1,\"b\":[2,3.5,\"s\"],\"c\":{\"d\":true},\"e\":null}"); I(r); SEP(); S(dlog); }
static void t_json_decode_array(void) { int r = decode("[1,[2],{}]"); I(r); SEP(); S(dlog); }
static void t_json_decode_bare(void) { int r = decode("42"); I(r); SEP(); S(dlog); }
static void t_json_decode_invalid(void) { int r = decode("{bad"); I(r); SEP(); S(dlog); }
static void t_json_decode_escapes(void) { int r = decode("{\"k\":\"a\\nb\\u0041\"}"); I(r); SEP(); for (int i = 0; dlog[i]; i++) { if (dlog[i] == '\n') S("\\n"); else C1(dlog[i]); } }
static int skip_b(json_decoder* d, const char* key) { (void)d; return key[0] != 'b'; }
static void t_json_decode_filter(void) {
    json_decoder d; memset(&d, 0, sizeof d); dlen = 0; dlog[0] = 0;
    d.decodeError = d_err; d.willDecodeSublist = d_will; d.didDecodeTableValue = d_table; d.didDecodeArrayValue = d_array; d.didDecodeSublist = d_did; d.shouldDecodeTableValueForKey = skip_b;
    json_value v; I(pd->json->decodeString(&d, "{\"a\":1,\"b\":2,\"c\":3}", &v)); SEP(); S(dlog);
}

// ---------- sound ----------
static void t_snd_time(void) { uint32_t t = pd->sound->getCurrentTime(); I(t < 44100u * 600u); }
static void t_snd_headphone(void) { int h = -1, m = -1; pd->sound->getHeadphoneState(&h, &m, NULL); I(h); SEP(); I(m); }
static void t_snd_default_channel(void) { I(pd->sound->getDefaultChannel() != NULL); }
static void t_snd_sample_buffer(void) { AudioSample* s = pd->sound->sample->newSampleBuffer(44100 * 2); F(pd->sound->sample->getLength(s)); uint8_t* d = NULL; SoundFormat f = 99; uint32_t rate = 0, len = 0; pd->sound->sample->getData(s, &d, &f, &rate, &len); SEP(); I(d != NULL); SEP(); I(f); SEP(); I(rate); SEP(); I(len); pd->sound->sample->freeSample(s); }
static void t_snd_sample_load(void) { AudioSample* s = pd->sound->sample->load("assets/beep"); I(s != NULL); if (s) { SEP(); F(pd->sound->sample->getLength(s)); uint8_t* d; SoundFormat f; uint32_t rate, len; pd->sound->sample->getData(s, &d, &f, &rate, &len); SEP(); I(f); SEP(); I(rate); SEP(); I(len); pd->sound->sample->freeSample(s); } }
static void t_snd_sample_load_into(void) { AudioSample* s = pd->sound->sample->newSampleBuffer(16); int r = pd->sound->sample->loadIntoSample(s, "assets/beep"); I(r); SEP(); F(pd->sound->sample->getLength(s)); pd->sound->sample->freeSample(s); }
static uint8_t pcm[2000];
static void t_snd_sample_from_data(void) { AudioSample* s = pd->sound->sample->newSampleFromData(pcm, kSound16bitMono, 22050, 2000, 0); I(s != NULL); if (s) { SEP(); F(pd->sound->sample->getLength(s)); pd->sound->sample->freeSample(s); } }
static void t_snd_sampleplayer(void) {
    AudioSample* s = pd->sound->sample->newSampleFromData(pcm, kSound16bitMono, 22050, 2000, 0);
    SamplePlayer* p = pd->sound->sampleplayer->newPlayer(); if (s) pd->sound->sampleplayer->setSample(p, s);
    pd->sound->sampleplayer->setVolume(p, 0.25f, 0.5f); float l = -1, r = -1; pd->sound->sampleplayer->getVolume(p, &l, &r);
    pd->sound->sampleplayer->setRate(p, 2); float rate = pd->sound->sampleplayer->getRate(p);
    int pl = pd->sound->sampleplayer->play(p, 1, 1); int ip = pd->sound->sampleplayer->isPlaying(p); pd->sound->sampleplayer->stop(p);
    F(pd->sound->sampleplayer->getLength(p)); SEP(); F(l); SEP(); F(r); SEP(); F(rate); SEP(); I(pl); SEP(); I(ip); SEP(); I(pd->sound->sampleplayer->isPlaying(p));
    pd->sound->sampleplayer->freePlayer(p); if (s) pd->sound->sample->freeSample(s);
}
static void t_snd_fileplayer(void) {
    FilePlayer* p = pd->sound->fileplayer->newPlayer(); int r = pd->sound->fileplayer->loadIntoPlayer(p, "assets/beep");
    pd->sound->fileplayer->setVolume(p, 0.3f, 0.6f); float l = -1, rr = -1; pd->sound->fileplayer->getVolume(p, &l, &rr);
    pd->sound->fileplayer->setRate(p, 1.5f);
    int pl = pd->sound->fileplayer->play(p, 1); int ip = pd->sound->fileplayer->isPlaying(p); pd->sound->fileplayer->stop(p);
    I(r); SEP(); F(pd->sound->fileplayer->getLength(p)); SEP(); F(l); SEP(); F(rr); SEP(); F(pd->sound->fileplayer->getRate(p)); SEP(); I(pl); SEP(); I(ip);
    pd->sound->fileplayer->freePlayer(p);
}
static void t_snd_synth(void) {
    PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, kWaveformSquare); pd->sound->synth->setVolume(s, 0.25f, 0.75f);
    float l = -1, r = -1; pd->sound->synth->getVolume(s, &l, &r);
    pd->sound->synth->playNote(s, 440, 1, 0.1f, 0); int ip = pd->sound->synth->isPlaying(s); pd->sound->synth->stop(s);
    F(l); SEP(); F(r); SEP(); I(ip); SEP(); I(pd->sound->synth->isPlaying(s)); SEP(); I(pd->sound->synth->getEnvelope(s) != NULL); SEP(); I(pd->sound->synth->getParameterCount(s));
    pd->sound->synth->freeSynth(s);
}
static void t_snd_synth_copy(void) { PDSynth* s = pd->sound->synth->newSynth(); PDSynth* c = pd->sound->synth->copy(s); I(c != NULL); pd->sound->synth->freeSynth(s); if (c) pd->sound->synth->freeSynth(c); }
static void t_snd_channel(void) {
    SoundChannel* ch = pd->sound->channel->newChannel(); int added = pd->sound->addChannel(ch);
    pd->sound->channel->setVolume(ch, 0.5f); float v = pd->sound->channel->getVolume(ch);
    PDSynth* s = pd->sound->synth->newSynth(); int a = pd->sound->channel->addSource(ch, (SoundSource*)s); int b = pd->sound->channel->removeSource(ch, (SoundSource*)s);
    I(added); SEP(); F(v); SEP(); I(a); SEP(); I(b); SEP(); I(pd->sound->channel->getDryLevelSignal(ch) != NULL); SEP(); I(pd->sound->channel->getOutputAsSource(ch) != NULL);
    pd->sound->removeChannel(ch); pd->sound->synth->freeSynth(s);
}
static void t_snd_lfo_env(void) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSine); pd->sound->lfo->setRate(l, 2); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->lfo->setCenter(l, 0.25f);
    PDSynthEnvelope* e = pd->sound->envelope->newEnvelope(0.1f, 0.2f, 0.5f, 0.3f);
    F(pd->sound->lfo->getValue(l)); SEP(); F(pd->sound->envelope->getValue(e));
    pd->sound->lfo->freeLFO(l); pd->sound->envelope->freeEnvelope(e);
}
static void t_snd_instrument(void) {
    PDSynthInstrument* i = pd->sound->instrument->newInstrument(); int a = pd->sound->instrument->addVoice(i, pd->sound->synth->newSynth(), 0, 127, 0);
    pd->sound->instrument->setVolume(i, 0.4f, 0.6f); float l = -1, r = -1; pd->sound->instrument->getVolume(i, &l, &r);
    PDSynth* n = pd->sound->instrument->playMIDINote(i, 60, 1, 0.1f, 0); int active = pd->sound->instrument->activeVoiceCount(i); pd->sound->instrument->allNotesOff(i, 0);
    I(a); SEP(); F(l); SEP(); F(r); SEP(); I(n != NULL); SEP(); I(active);
    pd->sound->instrument->freeInstrument(i);
}
static void t_snd_sequence(void) {
    SoundSequence* q = pd->sound->sequence->newSequence(); pd->sound->sequence->setTempo(q, 8);
    SequenceTrack* t = pd->sound->sequence->addTrack(q);
    I(pd->sound->sequence->getTrackCount(q)); SEP(); I(t != NULL); SEP(); I(pd->sound->sequence->getTrackAtIndex(q, 0) == t); SEP(); F(pd->sound->sequence->getTempo(q)); SEP(); I(pd->sound->sequence->getLength(q));
    pd->sound->sequence->freeSequence(q);
}
static void t_snd_track(void) {
    SequenceTrack* t = pd->sound->track->newTrack();
    pd->sound->track->addNoteEvent(t, 0, 4, 60, 1); pd->sound->track->addNoteEvent(t, 4, 2, 62, 0.5f);
    uint32_t step = 99, len = 99; MIDINote note = 0; float vel = -1;
    int ok = pd->sound->track->getNoteAtIndex(t, 1, &step, &len, &note, &vel);
    I(pd->sound->track->getLength(t)); SEP(); I(pd->sound->track->getIndexForStep(t, 4)); SEP(); I(ok); SEP(); I(step); SEP(); I(len); SEP(); F(note); SEP(); F(vel);
    pd->sound->track->removeNoteEvent(t, 0, 60); SEP(); I(pd->sound->track->getLength(t));
    pd->sound->track->freeTrack(t);
}
static void t_snd_sequence_midi_missing(void) { SoundSequence* q = pd->sound->sequence->newSequence(); I(pd->sound->sequence->loadMIDIFile(q, "none.mid")); pd->sound->sequence->freeSequence(q); }
static void t_snd_effects(void) {
    TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(f, kFilterTypeLowPass); pd->sound->effect->twopolefilter->setFrequency(f, 1000);
    BitCrusher* b = pd->sound->effect->bitcrusher->newBitCrusher(); pd->sound->effect->bitcrusher->setAmount(b, 0.5f);
    DelayLine* d = pd->sound->effect->delayline->newDelayLine(4410, 0); DelayLineTap* tap = pd->sound->effect->delayline->addTap(d, 100);
    I(f != NULL); SEP(); I(b != NULL); SEP(); I(d != NULL); SEP(); I(tap != NULL);
}

// ---------- network and scoreboards (no traffic) ----------
static void t_net_status(void) { I(pd->network->getStatus()); }


// ---------- other C functions ----------
static PDSynthSignalValue* lfoval(void) { return (PDSynthSignalValue*)pd->sound->lfo->newLFO(kLFOTypeSine); }
#define MODPAIR(setter, getter, obj) do { PDSynthSignalValue* _m = lfoval(); setter(obj, _m); I(getter(obj) == _m); } while (0)
static void t2_synth_setters(void) {
    PDSynth* s = pd->sound->synth->newSynth();
    pd->sound->synth->setAttackTime(s, 0.1f); pd->sound->synth->setDecayTime(s, 0.1f); pd->sound->synth->setSustainLevel(s, 0.5f); pd->sound->synth->setReleaseTime(s, 0.2f); pd->sound->synth->setTranspose(s, 2); pd->sound->synth->clearEnvelope(s);
    MODPAIR(pd->sound->synth->setFrequencyModulator, pd->sound->synth->getFrequencyModulator, s); SEP();
    MODPAIR(pd->sound->synth->setAmplitudeModulator, pd->sound->synth->getAmplitudeModulator, s); SEP();
    I(pd->sound->synth->setParameter(s, 0, 0.5f)); SEP();
    PDSynthSignalValue* m = lfoval(); pd->sound->synth->setParameterModulator(s, 0, m); I(pd->sound->synth->getParameterModulator(s, 0) == m);
    pd->sound->synth->freeSynth(s);
}
static void t2_synth_midi(void) { PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->playMIDINote(s, 60, 1, -1, 0); int a = pd->sound->synth->isPlaying(s); pd->sound->synth->noteOff(s, 0); I(a); pd->sound->synth->stop(s); pd->sound->synth->freeSynth(s); }
static void t2_synth_sample(void) { AudioSample* smp = pd->sound->sample->newSampleBuffer(4096); PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setSample(s, smp, 0, 0); I(pd->sound->synth->setWavetable(s, smp, 8, 2, 1)); pd->sound->synth->freeSynth(s); }
static void t2_fileplayer_more(void) {
    FilePlayer* p = pd->sound->fileplayer->newPlayer(); pd->sound->fileplayer->loadIntoPlayer(p, "assets/beep");
    pd->sound->fileplayer->setBufferLength(p, 0.5f); pd->sound->fileplayer->setOffset(p, 0.25f); float o = pd->sound->fileplayer->getOffset(p);
    pd->sound->fileplayer->setLoopRange(p, 0, 0.3f); pd->sound->fileplayer->setStopOnUnderrun(p, 0);
    pd->sound->fileplayer->play(p, 1); pd->sound->fileplayer->pause(p); int ip = pd->sound->fileplayer->isPlaying(p); pd->sound->fileplayer->stop(p);
    MODPAIR(pd->sound->fileplayer->setRateModulator, pd->sound->fileplayer->getRateModulator, p);
    SEP(); F(o); SEP(); I(ip); SEP(); I(pd->sound->fileplayer->didUnderrun(p));
    pd->sound->fileplayer->fadeVolume(p, 0, 0, 100, NULL, NULL); pd->sound->fileplayer->freePlayer(p);
}
static void t2_sampleplayer_more(void) {
    AudioSample* smp = pd->sound->sample->newSampleFromData(pcm, kSound16bitMono, 22050, 2000, 0);
    SamplePlayer* p = pd->sound->sampleplayer->newPlayer(); if (smp) pd->sound->sampleplayer->setSample(p, smp);
    pd->sound->sampleplayer->setOffset(p, 0.01f); float o = pd->sound->sampleplayer->getOffset(p);
    pd->sound->sampleplayer->setPlayRange(p, 10, 500); pd->sound->sampleplayer->play(p, 1, 1); pd->sound->sampleplayer->setPaused(p, 1); int ip = pd->sound->sampleplayer->isPlaying(p); pd->sound->sampleplayer->stop(p);
    MODPAIR(pd->sound->sampleplayer->setRateModulator, pd->sound->sampleplayer->getRateModulator, p);
    SEP(); F(o); SEP(); I(ip);
    pd->sound->sampleplayer->freePlayer(p);
}
static void t2_source(void) { PDSynth* s = pd->sound->synth->newSynth(); SoundSource* src = (SoundSource*)s; pd->sound->source->setVolume(src, 0.2f, 0.4f); float l = -1, r = -1; pd->sound->source->getVolume(src, &l, &r); F(l); SEP(); F(r); SEP(); I(pd->sound->source->isPlaying(src)); pd->sound->synth->freeSynth(s); }
static void t2_channel_more(void) {
    SoundChannel* ch = pd->sound->channel->newChannel(); pd->sound->addChannel(ch);
    TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter();
    I(pd->sound->channel->addEffect(ch, (SoundEffect*)f)); SEP(); I(pd->sound->channel->removeEffect(ch, (SoundEffect*)f)); SEP();
    pd->sound->channel->setPan(ch, -0.5f);
    MODPAIR(pd->sound->channel->setVolumeModulator, pd->sound->channel->getVolumeModulator, ch); SEP();
    MODPAIR(pd->sound->channel->setPanModulator, pd->sound->channel->getPanModulator, ch); SEP();
    I(pd->sound->channel->getWetLevelSignal(ch) != NULL);
    pd->sound->removeChannel(ch); pd->sound->channel->freeChannel(ch);
}
static int cb_source(void* ctx, int16_t* left, int16_t* right, int len) { (void)ctx; (void)left; (void)right; (void)len; return 0; }
static void t2_callback_source(void) { SoundChannel* ch = pd->sound->channel->newChannel(); SoundSource* s = pd->sound->channel->addCallbackSource(ch, cb_source, NULL, 0); I(s != NULL); SoundSource* g = pd->sound->addSource(cb_source, NULL, 1); SEP(); I(g != NULL); if (g) { SEP(); I(pd->sound->removeSource(g)); } pd->sound->channel->freeChannel(ch); }
static void t2_lfo_more(void) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSquare); pd->sound->lfo->setType(l, kLFOTypeTriangle); pd->sound->lfo->setPhase(l, 0.25f); pd->sound->lfo->setStartPhase(l, 0.25f);
    float steps[] = { 0, 4, 7 }; pd->sound->lfo->setArpeggiation(l, 3, steps); pd->sound->lfo->setDelay(l, 0, 0); pd->sound->lfo->setRetrigger(l, 1); pd->sound->lfo->setGlobal(l, 0); pd->sound->lfo->setRandomSeed(l, 7);
    F(pd->sound->lfo->getValue(l)); pd->sound->lfo->freeLFO(l);
}
static void t2_envelope_more(void) {
    PDSynthEnvelope* e = pd->sound->envelope->newEnvelope(0, 0, 1, 0);
    pd->sound->envelope->setAttack(e, 0.1f); pd->sound->envelope->setDecay(e, 0.1f); pd->sound->envelope->setSustain(e, 0.6f); pd->sound->envelope->setRelease(e, 0.1f);
    pd->sound->envelope->setLegato(e, 1); pd->sound->envelope->setRetrigger(e, 1); pd->sound->envelope->setCurvature(e, 0.5f); pd->sound->envelope->setVelocitySensitivity(e, 0.5f); pd->sound->envelope->setRateScaling(e, 0.5f, 36, 84);
    F(pd->sound->envelope->getValue(e)); pd->sound->envelope->freeEnvelope(e);
}
static void t2_effects_more(void) {
    BitCrusher* b = pd->sound->effect->bitcrusher->newBitCrusher();
    pd->sound->effect->bitcrusher->setUndersampling(b, 0.5f); pd->sound->effect->bitcrusher->setExponential(b, 1); pd->sound->effect->bitcrusher->setDepth(b, 0.5f); pd->sound->effect->bitcrusher->setDownsampling(b, 0.5f);
    MODPAIR(pd->sound->effect->bitcrusher->setAmountModulator, pd->sound->effect->bitcrusher->getAmountModulator, b); SEP();
    MODPAIR(pd->sound->effect->bitcrusher->setUndersampleModulator, pd->sound->effect->bitcrusher->getUndersampleModulator, b); SEP();
    MODPAIR(pd->sound->effect->bitcrusher->setDepthModulator, pd->sound->effect->bitcrusher->getDepthModulator, b); SEP();
    MODPAIR(pd->sound->effect->bitcrusher->setDownsamplingModulator, pd->sound->effect->bitcrusher->getDownsamplingModulator, b); SEP();
    pd->sound->effect->bitcrusher->freeBitCrusher(b);
    Overdrive* o = pd->sound->effect->overdrive->newOverdrive(); pd->sound->effect->overdrive->setGain(o, 2); pd->sound->effect->overdrive->setLimit(o, 0.8f); pd->sound->effect->overdrive->setOffset(o, 0.1f);
    MODPAIR(pd->sound->effect->overdrive->setLimitModulator, pd->sound->effect->overdrive->getLimitModulator, o); SEP();
    MODPAIR(pd->sound->effect->overdrive->setOffsetModulator, pd->sound->effect->overdrive->getOffsetModulator, o); SEP();
    pd->sound->effect->overdrive->freeOverdrive(o);
    RingModulator* r = pd->sound->effect->ringmodulator->newRingmod(); pd->sound->effect->ringmodulator->setFrequency(r, 200);
    MODPAIR(pd->sound->effect->ringmodulator->setFrequencyModulator, pd->sound->effect->ringmodulator->getFrequencyModulator, r); SEP();
    pd->sound->effect->ringmodulator->freeRingmod(r);
    OnePoleFilter* f1 = pd->sound->effect->onepolefilter->newFilter(); pd->sound->effect->onepolefilter->setParameter(f1, 0.3f);
    MODPAIR(pd->sound->effect->onepolefilter->setParameterModulator, pd->sound->effect->onepolefilter->getParameterModulator, f1); SEP();
    pd->sound->effect->onepolefilter->freeFilter(f1);
    TwoPoleFilter* f2 = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setGain(f2, 1); pd->sound->effect->twopolefilter->setResonance(f2, 0.5f);
    MODPAIR(pd->sound->effect->twopolefilter->setFrequencyModulator, pd->sound->effect->twopolefilter->getFrequencyModulator, f2); SEP();
    MODPAIR(pd->sound->effect->twopolefilter->setResonanceModulator, pd->sound->effect->twopolefilter->getResonanceModulator, f2);
    pd->sound->effect->twopolefilter->freeFilter(f2);
}
static void t2_delayline(void) {
    DelayLine* d = pd->sound->effect->delayline->newDelayLine(4410, 1); pd->sound->effect->delayline->setLength(d, 2205); pd->sound->effect->delayline->setFeedback(d, 0.3f);
    DelayLineTap* t = pd->sound->effect->delayline->addTap(d, 100); pd->sound->effect->delayline->setTapDelay(t, 200); pd->sound->effect->delayline->setTapChannelsFlipped(t, 1);
    MODPAIR(pd->sound->effect->delayline->setTapDelayModulator, pd->sound->effect->delayline->getTapDelayModulator, t);
    pd->sound->effect->delayline->freeTap(t); pd->sound->effect->delayline->freeDelayLine(d);
}
static int ud2 = 77;
static int effproc(SoundEffect* e, int32_t* l, int32_t* r, int len, int bufactive) { (void)e; (void)l; (void)r; (void)len; (void)bufactive; return 0; }
static void t2_custom_effect(void) {
    SoundEffect* e = pd->sound->effect->newEffect(effproc, &ud2); I(e != NULL);
    if (e) { SEP(); I(pd->sound->effect->getUserdata(e) == &ud2); pd->sound->effect->setUserdata(e, NULL); SEP(); I(pd->sound->effect->getUserdata(e) == NULL); pd->sound->effect->setMix(e, 0.5f); SEP(); MODPAIR(pd->sound->effect->setMixModulator, pd->sound->effect->getMixModulator, e); pd->sound->effect->freeEffect(e); }
}
static float stepper(void* ud, int* ioframes, float* ifval) { (void)ud; (void)ioframes; (void)ifval; return 0.75f; }
static void t2_signal(void) {
    PDSynthSignal* s = pd->sound->signal->newSignal(stepper, NULL, NULL, NULL, NULL); I(s != NULL);
    if (s) { pd->sound->signal->setValueScale(s, 2); pd->sound->signal->setValueOffset(s, 0.5f); SEP(); F(pd->sound->signal->getValue(s)); pd->sound->signal->freeSignal(s); }
    PDSynthSignal* v = pd->sound->signal->newSignalForValue(lfoval()); SEP(); I(v != NULL);
}
static void t2_control_signal(void) {
    ControlSignal* c = pd->sound->controlsignal->newSignal(); pd->sound->controlsignal->addEvent(c, 0, 0.5f, 0); pd->sound->controlsignal->addEvent(c, 4, 1, 1); pd->sound->controlsignal->removeEvent(c, 4);
    I(pd->sound->controlsignal->getMIDIControllerNumber(c)); pd->sound->controlsignal->clearEvents(c); pd->sound->controlsignal->freeSignal(c);
}
static void t2_sequence_more(void) {
    SoundSequence* q = pd->sound->sequence->newSequence(); SequenceTrack* t = pd->sound->sequence->addTrack(q);
    if (t) pd->sound->track->addNoteEvent(t, 0, 4, 60, 1);
    pd->sound->sequence->setTempo(q, 8); pd->sound->sequence->setLoops(q, 0, 4, 1); pd->sound->sequence->setTime(q, 100); uint32_t tm = pd->sound->sequence->getTime(q);
    pd->sound->sequence->play(q, NULL, NULL); int ip = pd->sound->sequence->isPlaying(q); pd->sound->sequence->setCurrentStep(q, 2, 0, 0); int off = -1; int st = pd->sound->sequence->getCurrentStep(q, &off);
    pd->sound->sequence->stop(q); pd->sound->sequence->allNotesOff(q);
    SequenceTrack* t2 = pd->sound->track->newTrack(); pd->sound->sequence->setTrackAtIndex(q, t2, 3);
    I(tm); SEP(); I(ip); SEP(); I(st); SEP(); I(pd->sound->sequence->getTrackCount(q)); SEP(); I(pd->sound->sequence->getTempo_deprecated(q));
    pd->sound->sequence->freeSequence(q);
}
static void t2_track_more(void) {
    SequenceTrack* t = pd->sound->track->newTrack(); PDSynthInstrument* ins = pd->sound->instrument->newInstrument(); pd->sound->track->setInstrument(t, ins);
    pd->sound->track->addNoteEvent(t, 0, 4, 60, 1); pd->sound->track->clearNotes(t); pd->sound->track->setMuted(t, 1);
    ControlSignal* cs = pd->sound->track->getSignalForController(t, 7, 1);
    I(pd->sound->track->getInstrument(t) == ins); SEP(); I(pd->sound->track->getLength(t)); SEP(); I(cs != NULL); SEP(); I(pd->sound->track->getControlSignalCount(t)); SEP(); I(pd->sound->track->getControlSignal(t, 0) == cs); SEP(); I(pd->sound->track->getPolyphony(t)); SEP(); I(pd->sound->track->activeVoiceCount(t));
    pd->sound->track->clearControlEvents(t); pd->sound->track->freeTrack(t);
}
static void t2_instrument_more(void) {
    PDSynthInstrument* i = pd->sound->instrument->newInstrument(); pd->sound->instrument->addVoice(i, pd->sound->synth->newSynth(), 0, 127, 0);
    pd->sound->instrument->setPitchBend(i, 0.5f); pd->sound->instrument->setPitchBendRange(i, 2); pd->sound->instrument->setTranspose(i, 1);
    PDSynth* s = pd->sound->instrument->playNote(i, 440, 1, -1, 0); int a = pd->sound->instrument->activeVoiceCount(i); pd->sound->instrument->noteOff(i, 69, 0);
    I(s != NULL); SEP(); I(a); pd->sound->instrument->freeInstrument(i);
}
static void t2_sound_misc(void) { pd->sound->setOutputsActive(1, 1); const char* e = pd->sound->getError(); I(e == NULL); }
static void t2_sample_decompress(void) { AudioSample* s = pd->sound->sample->newSampleBuffer(1024); I(pd->sound->sample->decompress(s)); pd->sound->sample->freeSample(s); }
static void t2_gfx_more(void) {
    pd->graphics->setBackgroundColor(kColorBlack); pd->graphics->setBackgroundColor(kColorWhite);
    pd->graphics->setFont(NULL); pd->graphics->display(); S("ok");
}
static void t2_gfx_leading(void) { DRAW(48, 48, pd->graphics->setTextLeading(6); pd->graphics->drawTextInRect("aa bb", 5, kASCIIEncoding, 1, 1, 20, 46, kWrapWord, kAlignTextLeft); pd->graphics->setTextLeading(0)); }
static void t2_gfx_clear_clip(void) { DRAW(16, 16, pd->graphics->setClipRect(4, 4, 6, 6); pd->graphics->clearClipRect(); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack)); }
static void t2_gfx_stencil_deprecated(void) { LCDBitmap* st = pd->graphics->newBitmap(32, 16, kColorBlack); pd->graphics->pushContext(st); pd->graphics->fillRect(0, 0, 8, 16, kColorWhite); pd->graphics->popContext(); DRAW(16, 16, pd->graphics->setStencil(st); pd->graphics->fillRect(0, 0, 16, 16, kColorBlack); pd->graphics->setStencil(NULL)); pd->graphics->freeBitmap(st); }
static void t2_gfx_color_to_pattern(void) { LCDBitmap* b = pd->graphics->newBitmap(8, 8, kColorWhite); pd->graphics->pushContext(b); pd->graphics->fillRect(0, 0, 4, 8, kColorBlack); pd->graphics->popContext(); LCDColor c = 0; pd->graphics->setColorToPattern(&c, b, 0, 0); I(c != 0); if (c) { SEP(); DRAW(8, 8, pd->graphics->fillRect(0, 0, 8, 8, c)); } }
static void t2_gfx_load_into_table(void) { LCDBitmapTable* t = pd->graphics->newBitmapTable(3, 8, 8); const char* err = NULL; pd->graphics->loadIntoBitmapTable("assets/tiles", t, &err); int count = -1, w = -1; pd->graphics->getBitmapTableInfo(t, &count, &w); I(count); SEP(); I(err == NULL); }
static void t2_tilemap_more(void) { LCDTileMap* m = pd->graphics->tilemap->newTilemap(); LCDBitmapTable* t = table3(); pd->graphics->tilemap->setImageTable(m, t); pd->graphics->tilemap->setSize(m, 4, 2); int w = -1, h = -1; pd->graphics->tilemap->getSize(m, &w, &h); I(pd->graphics->tilemap->getImageTable(m) == t); SEP(); I(w); SEP(); I(h); SEP(); I(pd->graphics->tilemap->getTileAtPosition(m, 0, 0)); pd->graphics->tilemap->freeTilemap(m); }
static void t2_sprite_more(void) {
    pd->sprite->removeAllSprites(); LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setImage(s, srcbmp(), kBitmapUnflipped); pd->sprite->moveTo(s, 20, 20); pd->sprite->addSprite(s);
    LCDBitmap* st = pd->graphics->newBitmap(32, 32, kColorWhite); pd->sprite->setStencilImage(s, st, 0); pd->sprite->setStencil(s, NULL);
    pd->sprite->drawSprites(); pd->sprite->removeAllSprites(); S("ok");
}
static void t2_display_fps(void) { float f = pd->display->getFPS(); I(f >= 0); }
static void t2_sys_more(void) {
    pd->system->logToConsole("probe %d", 1); pd->system->setAutoLockDisabled(1); pd->system->setAutoLockDisabled(0);
    pd->system->clearICache(); pd->system->drawFPS(0, 0);
    LCDBitmap* img = pd->graphics->newBitmap(400, 240, kColorWhite); pd->system->setMenuImage(img, 0); pd->system->setMenuImage(NULL, 0);
    S("ok");
}
static int btn_cb(PDButtons b, int down, uint32_t when, void* ud) { (void)b; (void)down; (void)when; (void)ud; return 0; }
static void serial_cb(const char* d) { (void)d; }
static void t2_sys_callbacks(void) { pd->system->setButtonCallback(btn_cb, NULL, 8); pd->system->setButtonCallback(NULL, NULL, 0); pd->system->setSerialMessageCallback(serial_cb); S("ok"); }
static int vfmt(char** out, const char* fmt, ...) { va_list ap; va_start(ap, fmt); int n = pd->system->vaFormatString(out, fmt, ap); va_end(ap); return n; }
static void t2_sys_vaformat(void) { char* s = NULL; int n = vfmt(&s, "%d-%s-%.1f", 7, "x", 2.5); I(n); SEP(); S(s); pd->system->realloc(s, 0); }
static void t2_sys_vaformat_long(void) { char big[1501]; memset(big, 'b', 1500); big[1500] = 0; char* s = NULL; int n = vfmt(&s, "%s", big); I(n); SEP(); I(s ? (int)strlen(s) : -1); pd->system->realloc(s, 0); }
static void t2_sys_mirror(void) { uint8_t d[1] = { 0 }; I(pd->system->sendMirrorData(0, d, 1)); }
static int json_read_pos;
static const char* json_src = "{\"a\":[1,2]}";
static int jreader(void* ud, uint8_t* buf, int size) { (void)ud; int n = 0; while (n < size && json_src[json_read_pos]) buf[n++] = (uint8_t)json_src[json_read_pos++]; return n; }
static void t2_json_decode_reader(void) {
    json_decoder d; memset(&d, 0, sizeof d); dlen = 0; dlog[0] = 0; json_read_pos = 0;
    d.decodeError = d_err; d.willDecodeSublist = d_will; d.didDecodeTableValue = d_table; d.didDecodeArrayValue = d_array; d.didDecodeSublist = d_did;
    json_reader r = { .read = jreader, .userdata = NULL }; json_value v;
    I(pd->json->decode(&d, r, &v)); SEP(); S(dlog);
}
static void t2_video_more(void) { LCDVideoPlayer* v = pd->graphics->video->loadVideo("video/appear_frames"); I(v != NULL); if (v) { LCDBitmap* ctx = pd->graphics->newBitmap(400, 240, kColorWhite); SEP(); I(pd->graphics->video->setContext(v, ctx)); SEP(); I(pd->graphics->video->getContext(v) == ctx); SEP(); I(pd->graphics->video->renderFrame(v, 10)); SEP(); I(pd->graphics->video->renderFrame(v, 100000)); SEP(); I(pd->graphics->video->getError(v) != NULL); pd->graphics->video->useScreenContext(v); pd->graphics->video->freePlayer(v); } }
static void t2_videostream(void) { LCDStreamPlayer* p = pd->graphics->videostream->newPlayer(); I(p != NULL); if (p) { pd->graphics->videostream->setBufferSize(p, 8, 8); SEP(); I(pd->graphics->videostream->getVideoPlayer(p) != NULL); SEP(); I(pd->graphics->videostream->getFilePlayer(p) != NULL); SEP(); I(pd->graphics->videostream->getBufferedFrameCount(p)); SEP(); I(pd->graphics->videostream->getBytesRead(p)); pd->graphics->videostream->freePlayer(p); } }
static void net_cb(PDNetErr e) { (void)e; }
static void t2_network_objects(void) {
    HTTPConnection* h = pd->network->http->newConnection("example.com", 80, false); I(h != NULL);
    if (h) { pd->network->http->setUserdata(h, &ud2); SEP(); I(pd->network->http->getUserdata(h) == &ud2); pd->network->http->setConnectTimeout(h, 100); pd->network->http->setKeepAlive(h, false); pd->network->http->setByteRange(h, 0, 10); pd->network->http->setReadTimeout(h, 100); pd->network->http->setReadBufferSize(h, 1024); SEP(); I(pd->network->http->getResponseStatus(h)); SEP(); I(pd->network->http->getBytesAvailable(h)); SEP(); I(pd->network->http->getError(h)); HTTPConnection* r = pd->network->http->retain(h); SEP(); I(r == h); pd->network->http->release(h); pd->network->http->close(h); pd->network->http->release(h); }
    TCPConnection* t = pd->network->tcp->newConnection("example.com", 80, false); SEP(); I(t != NULL);
    if (t) { pd->network->tcp->setUserdata(t, &ud2); SEP(); I(pd->network->tcp->getUserdata(t) == &ud2); pd->network->tcp->setConnectTimeout(t, 100); pd->network->tcp->setReadTimeout(t, 100); pd->network->tcp->setReadBufferSize(t, 1024); SEP(); I(pd->network->tcp->getBytesAvailable(t)); SEP(); I(pd->network->tcp->getSentBytesPending(t)); SEP(); I(pd->network->tcp->getError(t)); pd->network->tcp->close(t); pd->network->tcp->release(t); }
    pd->network->setEnabled(true, net_cb);
}

static void t3_parse_float(void) { float f = -1; int i = -1; char w[16] = { 0 }; int n = pd->system->parseString("1.5 7 abc", "%f %d %15s", &f, &i, w); I(n); SEP(); F(f); SEP(); I(i); SEP(); S(w); }

static void t3_synth_params(void) { PDSynth* d = pd->sound->synth->newSynth(); I(pd->sound->synth->getParameterCount(d)); pd->sound->synth->freeSynth(d);
    for (int w = 0; w < 8; w++) { PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, (SoundWaveform)w); SEP(); I(pd->sound->synth->getParameterCount(s)); pd->sound->synth->freeSynth(s); } }

// ---------- registry ----------
typedef struct { const char* name; void (*fn)(void); } Case;
#define T(x) { #x, x }
static const Case cases[] = {
    T(t_sys_time_types), T(t_sys_language), T(t_sys_flags), T(t_sys_crank), T(t_sys_crank_sounds), T(t_sys_buttons), T(t_sys_buttons_null), T(t_sys_accel), T(t_sys_elapsed), T(t_sys_battery), T(t_sys_timezone),
    T(t_sys_epoch_zero), T(t_sys_epoch_day), T(t_sys_epoch_roundtrip), T(t_sys_format), T(t_sys_format_float), T(t_sys_format_long), T(t_sys_format_wide), T(t_sys_parse), T(t_sys_realloc), T(t_sys_realloc_zero),
    T(t_menu_userdata), T(t_menu_set_userdata), T(t_menu_checkmark), T(t_menu_options), T(t_menu_title), T(t_menu_fourth), T(t_sys_launchargs), T(t_sys_power), T(t_sys_volume), T(t_sys_info), T(t_sys_localized), T(t_sys_delay),
    T(t_display_size), T(t_display_scale), T(t_display_refresh), T(t_display_misc),
    T(t_file_write_read), T(t_file_seek_tell), T(t_file_append), T(t_file_read_eof), T(t_file_open_missing), T(t_file_stat), T(t_file_stat_missing), T(t_file_mkdir_list), T(t_file_rename_unlink), T(t_file_unlink_dir), T(t_file_flush), T(t_file_read_pdx),
    T(t_gfx_bitmap_data), T(t_gfx_bitmap_clear_color), T(t_gfx_bitmap_pixel), T(t_gfx_clear_bitmap), T(t_gfx_copy_bitmap), T(t_gfx_clear), T(t_gfx_fillrect), T(t_gfx_fillrect_negative), T(t_gfx_drawrect), T(t_gfx_drawline), T(t_gfx_drawline_wide), T(t_gfx_drawline_cap),
    T(t_gfx_triangle), T(t_gfx_ellipse), T(t_gfx_ellipse_wide), T(t_gfx_ellipse_arc), T(t_gfx_fillellipse), T(t_gfx_fillellipse_arc), T(t_gfx_roundrect), T(t_gfx_roundrect_wide), T(t_gfx_fillroundrect), T(t_gfx_polygon_evenodd), T(t_gfx_polygon_nonzero),
    T(t_gfx_pattern_color), T(t_gfx_offset), T(t_gfx_clip), T(t_gfx_clip_offset), T(t_gfx_screenclip), T(t_gfx_drawmode_return),
    T(t_gfx_mode_copy), T(t_gfx_mode_whitetr), T(t_gfx_mode_blacktr), T(t_gfx_mode_fillwhite), T(t_gfx_mode_fillblack), T(t_gfx_mode_xor), T(t_gfx_mode_nxor), T(t_gfx_mode_inverted),
    T(t_gfx_flip), T(t_gfx_tile), T(t_gfx_scaled), T(t_gfx_scaled_negative), T(t_gfx_rotated), T(t_gfx_rotated_bitmap), T(t_gfx_rotated_bitmap_null), T(t_gfx_mask), T(t_gfx_mask_none), T(t_gfx_mask_collision), T(t_gfx_mask_collision_clear), T(t_gfx_stencil),
    T(t_gfx_load_missing_err), T(t_gfx_load_missing_null), T(t_gfx_load), T(t_gfx_load_into), T(t_gfx_table_new), T(t_gfx_table_load), T(t_gfx_table_load_missing_null),
    T(t_gfx_frame_buffers), T(t_gfx_display_buffer_bitmap), T(t_gfx_copy_frame), T(t_gfx_frame_write), T(t_gfx_debug_bitmap),
    T(t_gfx_font_height), T(t_gfx_text_width), T(t_gfx_text_width_utf8), T(t_gfx_text_draw), T(t_gfx_text_draw_return), T(t_gfx_text_tracking), T(t_gfx_text_in_rect), T(t_gfx_text_in_rect_center), T(t_gfx_text_height), T(t_gfx_glyph), T(t_gfx_page_glyph),
    T(t_gfx_raw_layout), T(t_gfx_raw_write), T(t_gfx_raw_mask_layout), T(t_tilemap_basic), T(t_tilemap_draw), T(t_video_load), T(t_video_missing),
    T(t_sprite_bounds), T(t_sprite_move), T(t_sprite_center), T(t_sprite_image_size), T(t_sprite_props), T(t_sprite_defaults), T(t_sprite_userdata), T(t_sprite_copy), T(t_sprite_count), T(t_sprite_collide_rect),
    T(t_sprite_move_collisions_default), T(t_sprite_move_slide), T(t_sprite_move_overlap), T(t_sprite_move_bounce), T(t_sprite_check_collisions), T(t_sprite_query_point), T(t_sprite_query_rect), T(t_sprite_query_line), T(t_sprite_query_all_overlapping), T(t_sprite_query_info_line), T(t_sprite_overlapping),
    T(t_sprite_update_order), T(t_sprite_draw_callback), T(t_sprite_tilemap), T(t_sprite_misc),
    T(t_json_encode), T(t_json_encode_pretty), T(t_json_decode_table), T(t_json_decode_array), T(t_json_decode_bare), T(t_json_decode_invalid), T(t_json_decode_escapes), T(t_json_decode_filter),
    T(t_snd_time), T(t_snd_headphone), T(t_snd_default_channel), T(t_snd_sample_buffer), T(t_snd_sample_load), T(t_snd_sample_load_into), T(t_snd_sample_from_data), T(t_snd_sampleplayer), T(t_snd_fileplayer),
    T(t_snd_synth), T(t_snd_synth_copy), T(t_snd_channel), T(t_snd_lfo_env), T(t_snd_instrument), T(t_snd_sequence), T(t_snd_track), T(t_snd_sequence_midi_missing), T(t_snd_effects),
    T(t2_synth_setters), T(t2_synth_midi), T(t2_synth_sample), T(t2_fileplayer_more), T(t2_sampleplayer_more), T(t2_source), T(t2_channel_more), T(t2_callback_source), T(t2_lfo_more), T(t2_envelope_more), T(t2_effects_more), T(t2_delayline), T(t2_custom_effect), T(t2_signal), T(t2_control_signal), T(t2_sequence_more), T(t2_track_more), T(t2_instrument_more), T(t2_sound_misc), T(t2_sample_decompress),
    T(t2_gfx_more), T(t2_gfx_leading), T(t2_gfx_clear_clip), T(t2_gfx_stencil_deprecated), T(t2_gfx_color_to_pattern), T(t2_gfx_load_into_table), T(t2_tilemap_more), T(t2_sprite_more), T(t2_display_fps), T(t2_sys_more), T(t2_sys_callbacks), T(t2_sys_vaformat), T(t2_sys_vaformat_long), T(t2_sys_mirror), T(t2_json_decode_reader), T(t2_video_more), T(t2_videostream), T(t2_network_objects),
    T(t3_parse_float), T(t3_synth_params), T(t_net_status),
};

// ---------- resumable runner ----------
static char done[16384]; static int donelen;
static void load_names(const char* path) {
    SDFile* f = pd->file->open(path, kFileReadData);
    if (!f) return;
    static char tmp[65536]; int n = pd->file->read(f, tmp, sizeof(tmp) - 1); pd->file->close(f);
    if (n <= 0) return;
    tmp[n] = 0;
    char* p = tmp;
    while (*p) {
        char* tab = strchr(p, '\t'); char* nl = strchr(p, '\n');
        if (!nl) nl = p + strlen(p);
        if (tab && tab < nl && donelen + (tab - p) + 2 < (int)sizeof done) { memcpy(done + donelen, p, tab - p); donelen += (int)(tab - p); done[donelen++] = '\n'; done[donelen] = 0; }
        p = *nl ? nl + 1 : nl;
    }
}
static int is_done(const char* name) {
    int n = (int)strlen(name); const char* p = done;
    while ((p = strstr(p, name))) { if ((p == done || p[-1] == '\n') && p[n] == '\n') return 1; p += n; }
    return 0;
}
static int update(void* ud) { (void)ud; return 0; }

#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg) {
    (void)arg;
    if (event == kEventInit) {
        pd = playdate;
        load_names("outc.txt"); load_names("skipc.txt");
        SDFile* f = pd->file->open("outc.txt", kFileAppend);
        for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
            if (is_done(cases[i].name)) continue;
            olen = 0; out[0] = 0;
            S(cases[i].name); C1('\t');
            reset();
            cases[i].fn();
            C1('\n');
            pd->file->write(f, out, (unsigned)olen);
            pd->file->flush(f);
        }
        pd->file->close(f);
        SDFile* d = pd->file->open("donec.txt", kFileWrite); pd->file->write(d, "done\n", 5); pd->file->close(d);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
