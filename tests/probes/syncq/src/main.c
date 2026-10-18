// Probe: other state the C API and Lua might share: the elapsed-time timer, the refresh rate, the sprite
// list, the drawn frame and the display's inversion and scale.
#include "pd_api.h"
static PlaydateAPI *pd;
#define ARGI(n) pd->lua->getArgInt(n)
static int creset(lua_State *L) { (void) L; pd->system->resetElapsedTime(); return 0; }
static int celapsed(lua_State *L) { (void) L; pd->lua->pushFloat(pd->system->getElapsedTime()); return 1; }
static int crate(lua_State *L) { (void) L; pd->display->setRefreshRate((float) ARGI(1)); return 0; }
static int cspritecount(lua_State *L) { (void) L; pd->lua->pushInt(pd->sprite->getSpriteCount()); return 1; }
static int caddsprite(lua_State *L) { (void) L; LCDSprite *s = pd->sprite->newSprite(); pd->sprite->addSprite(s); return 0; }
static int cframebyte(lua_State *L) { (void) L; uint8_t *f = pd->graphics->getFrame(); pd->lua->pushInt(f[ARGI(1) * LCD_ROWSIZE + ARGI(2)]); return 1; }
static int cinverted(lua_State *L) { (void) L; pd->display->setInverted(ARGI(1)); return 0; }
static int cscale(lua_State *L) { (void) L; pd->display->setScale(ARGI(1)); return 0; }
static int cwidth(lua_State *L) { (void) L; pd->lua->pushInt(pd->display->getWidth()); return 1; }
int eventHandler(PlaydateAPI *p, PDSystemEvent e, uint32_t arg) {
  (void) arg;
  if (e == kEventInitLua) {
    pd = p;
    pd->lua->addFunction(creset, "creset", NULL); pd->lua->addFunction(celapsed, "celapsed", NULL);
    pd->lua->addFunction(crate, "crate", NULL); pd->lua->addFunction(cspritecount, "cspritecount", NULL);
    pd->lua->addFunction(caddsprite, "caddsprite", NULL); pd->lua->addFunction(cframebyte, "cframebyte", NULL);
    pd->lua->addFunction(cinverted, "cinverted", NULL); pd->lua->addFunction(cscale, "cscale", NULL);
    pd->lua->addFunction(cwidth, "cwidth", NULL);
  }
  return 0;
}
