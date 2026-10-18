// Probe: which graphics state the C API and Lua share. C functions for Lua: setters and a fill and text draw.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI *pd;
#define ARGI(n) pd->lua->getArgInt(n)
static int coffset(lua_State *L) { (void) L; pd->graphics->setDrawOffset(ARGI(1), ARGI(2)); return 0; }
static int cclip(lua_State *L) { (void) L; pd->graphics->setClipRect(ARGI(1), ARGI(2), ARGI(3), ARGI(4)); return 0; }
static int cclearclip(lua_State *L) { (void) L; pd->graphics->clearClipRect(); return 0; }
static int cfill(lua_State *L) { (void) L; pd->graphics->fillRect(ARGI(1), ARGI(2), ARGI(3), ARGI(4), kColorBlack); return 0; }
static int cmode(lua_State *L) { (void) L; pd->lua->pushInt(pd->graphics->setDrawMode((LCDBitmapDrawMode) ARGI(1))); return 1; }
static int ctracking(lua_State *L) { (void) L; pd->graphics->setTextTracking(ARGI(1)); return 0; }
static int ctextwidth(lua_State *L) { (void) L; const char *s = pd->lua->getArgString(1);
  pd->lua->pushInt(pd->graphics->getTextWidth(NULL, s, strlen(s), kASCIIEncoding, 0)); return 1; }
static int ctext(lua_State *L) { (void) L; const char *s = pd->lua->getArgString(1);
  pd->lua->pushInt(pd->graphics->drawText(s, strlen(s), kASCIIEncoding, ARGI(2), ARGI(3))); return 1; }
static int cline(lua_State *L) { (void) L; pd->graphics->drawLine(ARGI(1), ARGI(2), ARGI(3), ARGI(4), ARGI(5), kColorBlack); return 0; }
static int ccap(lua_State *L) { (void) L; pd->graphics->setLineCapStyle((LCDLineCapStyle) ARGI(1)); return 0; }
static int csetfont(lua_State *L) { (void) L; const char *err; LCDFont *f = pd->graphics->loadFont(pd->lua->getArgString(1), &err);
  if (f) pd->graphics->setFont(f); pd->lua->pushBool(f != NULL); return 1; }
static LCDBitmap *stencil;
static int cstencil(lua_State *L) { (void) L;
  if (!stencil) { stencil = pd->graphics->newBitmap(400, 240, kColorBlack); pd->graphics->pushContext(stencil); pd->graphics->fillRect(0, 0, 200, 240, kColorWhite); pd->graphics->popContext(); }
  pd->graphics->setStencilImage(ARGI(1) ? stencil : NULL, 0); return 0; }
static int cbg(lua_State *L) { (void) L; pd->graphics->setBackgroundColor((LCDSolidColor) ARGI(1)); return 0; }
static int cpush(lua_State *L) { (void) L; pd->graphics->pushContext(NULL); return 0; }
static int cpop(lua_State *L) { (void) L; pd->graphics->popContext(); return 0; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInitLua) {
    pd = p;
    pd->lua->addFunction(coffset, "coffset", NULL); pd->lua->addFunction(cclip, "cclip", NULL);
    pd->lua->addFunction(cclearclip, "cclearclip", NULL); pd->lua->addFunction(cfill, "cfill", NULL);
    pd->lua->addFunction(cmode, "cmode", NULL); pd->lua->addFunction(ctracking, "ctracking", NULL);
    pd->lua->addFunction(ctextwidth, "ctextwidth", NULL); pd->lua->addFunction(ctext, "ctext", NULL);
    pd->lua->addFunction(cline, "cline", NULL); pd->lua->addFunction(cpush, "cpush", NULL); pd->lua->addFunction(cpop, "cpop", NULL); pd->lua->addFunction(ccap, "ccap", NULL); pd->lua->addFunction(csetfont, "csetfont", NULL); pd->lua->addFunction(cstencil, "cstencil", NULL); pd->lua->addFunction(cbg, "cbg", NULL);
  }
  return 0;
}
