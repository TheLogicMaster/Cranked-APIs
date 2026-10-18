// Hybrid Lua/C probe for the Lua C API.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
static char buf[1024]; static int blen;
static void S(const char* s) { if (!s) s = "(null)"; while (*s && blen < (int)sizeof buf - 1) buf[blen++] = *s++; buf[blen] = 0; }
static void I(long v) { char t[24]; int n = 0, neg = v < 0; unsigned long u = neg ? -v : v; do { t[n++] = '0' + u % 10; u /= 10; } while (u); if (neg) S("-"); char c[2] = { 0, 0 }; while (n) { c[0] = t[--n]; S(c); } }
static void F(float f) { if (f < 0) { S("-"); f = -f; } long w = (long)f; long fr = (long)((f - w) * 1000 + 0.5f); if (fr >= 1000) { w++; fr -= 1000; } I(w); S("."); char c[4] = { '0' + fr / 100, '0' + fr / 10 % 10, '0' + fr % 10, 0 }; S(c); }
static int c_describe(lua_State* L) {
    (void)L; blen = 0; buf[0] = 0;
    int n = pd->lua->getArgCount(); S("n="); I(n);
    for (int i = 1; i <= n; i++) {
        const char* cls = NULL; enum LuaType t = pd->lua->getArgType(i, &cls);
        S(" ["); I(i); S("]t="); I(t); if (cls) { S(":"); S(cls); }
        S(",nil="); I(pd->lua->argIsNil(i)); S(",b="); I(pd->lua->getArgBool(i)); S(",i="); I(pd->lua->getArgInt(i)); S(",f="); F(pd->lua->getArgFloat(i));
        if (t == kTypeString) { size_t len = 0; const char* b = pd->lua->getArgBytes(i, &len); S(",s="); S(pd->lua->getArgString(i)); S(",len="); I((long)len); S(",b0="); I(b ? b[0] : -1); }
    }
    pd->lua->pushString(buf); return 1;
}
static int c_push_all(lua_State* L) { (void)L; pd->lua->pushNil(); pd->lua->pushBool(1); pd->lua->pushInt(42); pd->lua->pushFloat(3.5f); pd->lua->pushString("str"); pd->lua->pushBytes("a\0b", 3); return 6; }
static int c_push_bitmap(lua_State* L) { (void)L; pd->lua->pushBitmap(pd->graphics->newBitmap(3, 2, kColorBlack)); return 1; }
static int c_get_bitmap(lua_State* L) { (void)L; LCDBitmap* b = pd->lua->getBitmap(1); if (!b) { pd->lua->pushNil(); return 1; } int w, h, rb; uint8_t *m, *d; pd->graphics->getBitmapData(b, &w, &h, &rb, &m, &d); pd->lua->pushInt(w * 1000 + h); return 1; }
static int c_push_sprite(lua_State* L) { (void)L; LCDSprite* s = pd->sprite->newSprite(); pd->sprite->setBounds(s, PDRectMake(1, 2, 30, 40)); pd->lua->pushSprite(s); return 1; }
static int c_get_sprite(lua_State* L) { (void)L; LCDSprite* s = pd->lua->getSprite(1); if (!s) { pd->lua->pushNil(); return 1; } PDRect r = pd->sprite->getBounds(s); pd->lua->pushFloat(r.width); return 1; }
static int answer(lua_State* L) { (void)L; pd->lua->pushInt(99); return 1; }
static int c_push_function(lua_State* L) { (void)L; pd->lua->pushFunction(answer); return 1; }
static int c_call_lua(lua_State* L) { (void)L; const char* err = NULL; pd->lua->pushInt(2); pd->lua->pushInt(3); int ok = pd->lua->callFunction("lua_add", 2, &err); pd->lua->pushInt(ok); pd->lua->pushBool(err == NULL); return 2; }
static int c_call_missing(lua_State* L) { (void)L; const char* err = NULL; int ok = pd->lua->callFunction("no_such_function", 0, &err); pd->lua->pushInt(ok); pd->lua->pushBool(err != NULL); return 2; }
static int c_stop_start(lua_State* L) { (void)L; pd->lua->stop(); pd->lua->start(); pd->lua->pushString("ok"); return 1; }
// class
typedef struct { int value; } Obj;
static int gc_count;
static int obj_new(lua_State* L) { (void)L; Obj* o = pd->system->realloc(NULL, sizeof(Obj)); o->value = pd->lua->getArgCount() >= 1 ? pd->lua->getArgInt(1) : 7; pd->lua->pushObject(o, "probeobj", 1); return 1; }
static int obj_value(lua_State* L) { (void)L; Obj* o = pd->lua->getArgObject(1, "probeobj", NULL); pd->lua->pushInt(o ? o->value : -1); return 1; }
static int obj_wrongtype(lua_State* L) { (void)L; Obj* o = pd->lua->getArgObject(1, "otherclass", NULL); pd->lua->pushBool(o == NULL); return 1; }
static int obj_setuv(lua_State* L) { (void)L; LuaUDObject* ud = NULL; pd->lua->getArgObject(1, "probeobj", &ud); pd->lua->setUserValue(ud, 1); return 0; }
static int obj_getuv(lua_State* L) { (void)L; LuaUDObject* ud = NULL; pd->lua->getArgObject(1, "probeobj", &ud); pd->lua->getUserValue(ud, 1); return 1; }
static int obj_retain(lua_State* L) { (void)L; LuaUDObject* ud = NULL; pd->lua->getArgObject(1, "probeobj", &ud); LuaUDObject* r = pd->lua->retainObject(ud); pd->lua->pushBool(r == ud); pd->lua->releaseObject(ud); return 1; }
static int obj_twice(lua_State* L) { (void)L; Obj* o = pd->lua->getArgObject(1, "probeobj", NULL); pd->lua->pushObject(o, "probeobj", 1); pd->lua->pushObject(o, "probeobj", 1); return 2; }
static int obj_setuv2(lua_State* L) { (void)L; LuaUDObject* ud = NULL; pd->lua->getArgObject(1, "probeobj", &ud); int before = pd->lua->getArgCount(); pd->lua->pushString("v2"); pd->lua->setUserValue(ud, 1); pd->lua->pushInt(before); return 1; }
static LuaUDObject* kept;
static int obj_keep(lua_State* L) { (void)L; LuaUDObject* ud = NULL; pd->lua->getArgObject(1, "probeobj", &ud); kept = pd->lua->retainObject(ud); return 0; }
static int c_kept_uv(lua_State* L) { (void)L; if (!kept) { pd->lua->pushString("none"); return 1; } pd->lua->getUserValue(kept, 1); return 1; }
static int c_kept_set(lua_State* L) { (void)L; if (!kept) return 0; pd->lua->pushString("late"); pd->lua->setUserValue(kept, 1); return 0; }
static int c_kept_release(lua_State* L) { (void)L; if (kept) pd->lua->releaseObject(kept); kept = NULL; pd->lua->pushBool(1); return 1; }
static int c_badpos(lua_State* L) { (void)L; int m = pd->lua->getArgInt(1); const char* cls = NULL; int t = 0;
    if (m == 0) t = pd->lua->getArgType(0, &cls); else if (m == 1) t = pd->lua->getArgInt(-50); else if (m == 2) t = pd->lua->argIsNil(-1000); else if (m == 3) t = pd->lua->getArgBool(-3);
    else if (m == 4) t = pd->lua->getArgString(1000) != NULL; else if (m == 5) t = pd->lua->getArgObject(-40, "probeobj", NULL) != NULL; else if (m == 6) t = pd->lua->getArgInt(30); else if (m == 7) t = pd->lua->getArgInt(-2);
    else if (m == 8) t = pd->lua->getArgInt(-1001000); else if (m == 9) t = pd->lua->getArgInt(-1001001); else if (m == 10) t = pd->lua->getArgInt(-1001300); else if (m == 11) t = pd->lua->getArgInt(200);
    pd->lua->pushString("survived"); pd->lua->pushInt(t); return 2; }
static LCDBitmap* twiceBmp; static LCDSprite* twiceSpr;
static int c_push_twice(lua_State* L) { (void)L; if (!twiceBmp) twiceBmp = pd->graphics->newBitmap(2, 2, kColorBlack); if (!twiceSpr) twiceSpr = pd->sprite->newSprite(); pd->lua->pushBitmap(twiceBmp); pd->lua->pushBitmap(twiceBmp); pd->lua->pushSprite(twiceSpr); pd->lua->pushSprite(twiceSpr); return 4; }
static int obj_gc(lua_State* L) { (void)L; Obj* o = pd->lua->getArgObject(1, "probeobj", NULL); gc_count++; if (o) pd->system->realloc(o, 0); return 0; }
static int c_gc_count(lua_State* L) { (void)L; pd->lua->pushInt(gc_count); return 1; }
static int c_register_results(lua_State* L) { (void)L; return 0; }
static int reg_ok, cls_ok, add_err_null, cls_err_null;
static int c_registration(lua_State* L) { (void)L; pd->lua->pushInt(reg_ok); pd->lua->pushInt(cls_ok); pd->lua->pushBool(add_err_null); pd->lua->pushBool(cls_err_null); return 4; }
static const lua_reg objregs[] = { { "new", obj_new }, { "value", obj_value }, { "wrongtype", obj_wrongtype }, { "setuv", obj_setuv }, { "getuv", obj_getuv }, { "retain", obj_retain }, { "twice", obj_twice }, { "setuv2", obj_setuv2 }, { "keep", obj_keep }, { "__gc", obj_gc }, { NULL, NULL } };
static const lua_val objvals[] = { { "kAnswer", kInt, { .intval = 42 } }, { "kHalf", kFloat, { .floatval = 0.5f } }, { "kName", kStr, { .strval = "probe" } }, { NULL, kInt, { 0 } } };

// indexMetatable: a class whose __index first consults the metatable, then supplies a computed field
static int idx_new(lua_State* L) { (void)L; int* p = pd->system->realloc(NULL, sizeof(int)); *p = 3; pd->lua->pushObject(p, "probeidx", 0); return 1; }
static int idx_m(lua_State* L) { (void)L; int* p = pd->lua->getArgObject(1, "probeidx", NULL); pd->lua->pushInt(p ? *p : -1); return 1; }
static int idx_index(lua_State* L) {
    (void)L;
    if (pd->lua->indexMetatable() == 1) return 1;
    const char* key = pd->lua->getArgString(2);
    if (key && strcmp(key, "custom") == 0) { pd->lua->pushInt(5); return 1; }
    pd->lua->pushNil(); return 1;
}
static const lua_reg idxregs[] = { { "new", idx_new }, { "m", idx_m }, { "__index", idx_index }, { NULL, NULL } };
static const lua_val idxvals[] = { { "kVal", kInt, { .intval = 9 } }, { NULL, kInt, { 0 } } };
static int c_call_deprecated(lua_State* L) { (void)L; pd->lua->pushInt(4); pd->lua->pushInt(6); pd->lua->callFunction_deprecated("lua_add", 2); pd->lua->pushString("called"); return 1; }

#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg) {
    (void)arg;
    if (event == kEventInit) pd = playdate;
    if (event == kEventInitLua) {
        pd = playdate;
        const char* err = NULL; int ok = 1;
        ok &= pd->lua->addFunction(c_describe, "c_describe", &err); add_err_null = err == NULL;
        ok &= pd->lua->addFunction(c_push_all, "c_push_all", &err);
        ok &= pd->lua->addFunction(c_push_bitmap, "c_push_bitmap", &err);
        ok &= pd->lua->addFunction(c_get_bitmap, "c_get_bitmap", &err);
        ok &= pd->lua->addFunction(c_push_sprite, "c_push_sprite", &err);
        ok &= pd->lua->addFunction(c_get_sprite, "c_get_sprite", &err);
        ok &= pd->lua->addFunction(c_push_function, "c_push_function", &err);
        ok &= pd->lua->addFunction(c_call_lua, "c_call_lua", &err);
        ok &= pd->lua->addFunction(c_call_missing, "c_call_missing", &err);
        ok &= pd->lua->addFunction(c_stop_start, "c_stop_start", &err);
        ok &= pd->lua->addFunction(c_gc_count, "c_gc_count", &err);
        ok &= pd->lua->addFunction(c_kept_uv, "c_kept_uv", &err);
        ok &= pd->lua->addFunction(c_push_twice, "c_push_twice", &err);
        ok &= pd->lua->addFunction(c_badpos, "c_badpos", &err);
        ok &= pd->lua->addFunction(c_kept_set, "c_kept_set", &err);
        ok &= pd->lua->addFunction(c_kept_release, "c_kept_release", &err);
        ok &= pd->lua->addFunction(c_registration, "c_registration", &err);
        ok &= pd->lua->addFunction(c_register_results, "util.nested.fn", &err);
        reg_ok = ok;
        const char* ierr = NULL; pd->lua->registerClass("probeidx", idxregs, idxvals, 0, &ierr);
        pd->lua->addFunction(c_call_deprecated, "c_call_deprecated", &err);
        const char* cerr = NULL; cls_ok = pd->lua->registerClass("probeobj", objregs, objvals, 0, &cerr); cls_err_null = cerr == NULL;
    }
    return 0;
}
