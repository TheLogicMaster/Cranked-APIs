// Load a large font through the C API.
#include "pd_api.h"
static PlaydateAPI* pd;
static int update(void* ud) { return 0; }
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        const char* err = NULL;
        LCDFont* f = pd->graphics->loadFont("fonts/GreatVibes-Regular-109", &err);
        SDFile* o = pd->file->open("bfc.txt", kFileWrite);
        char* s; int n = pd->system->formatString(&s, "font %s err %s\n", f ? "ok" : "NULL", err ? err : "none");
        pd->file->write(o, s, (unsigned)n); pd->file->close(o);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
