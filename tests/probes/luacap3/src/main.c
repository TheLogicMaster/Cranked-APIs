// A capture effect for Lua games. Lua calls captureSave(name) to write what was captured.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 8)
static int16_t cap[MAXF];
static int captured = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static int captureSave(lua_State* L) {
    const char* name = pd->lua->getArgString(1);
    SDFile* f = pd->file->open(name, kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
    pd->lua->pushInt(captured);
    return 1;
}
static int captureFrames(lua_State* L) { pd->lua->pushInt(captured); return 1; }
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInitLua) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        const char* err;
        pd->lua->addFunction(captureSave, "captureSave", &err);
        pd->lua->addFunction(captureFrames, "captureFrames", &err);
    }
    return 0;
}
