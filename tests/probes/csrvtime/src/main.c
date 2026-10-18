// C getServerTime without a network, and getLaunchArgs' path. Writes out.txt.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
static int frames = 0, cbFrame = -1;
static char result[200] = "no callback";
static void cb(const char* time, const char* err) {
    cbFrame = frames;
    char* s; pd->system->formatString(&s, "time=%s err=%s", time ? time : "NULL", err ? err : "NULL");
    strncpy(result, s, sizeof result - 1); pd->system->realloc(s, 0);
}
static int update(void* ud) {
    if (++frames == 30) {
        const char* path = "unset"; const char* args = pd->system->getLaunchArgs(&path);
        char* s; int n = pd->system->formatString(&s, "%s at frame %d\nlaunch args=%s path=%s\n", result, cbFrame, args ? args : "NULL", path ? path : "NULL");
        SDFile* f = pd->file->open("out.txt", kFileWrite); pd->file->write(f, s, n); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) { pd = p; pd->system->getServerTime(cb); pd->system->setUpdateCallback(update, NULL); }
    return 0;
}
