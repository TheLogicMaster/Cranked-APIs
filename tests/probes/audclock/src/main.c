// The audio clock (sound->getCurrentTime) seen by each of the first 60 updates, and by init.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
static int frames = 0;
static uint32_t t[61];
static int update(void* ud) {
    if (frames < 60) t[++frames] = pd->sound->getCurrentTime();
    else if (frames == 60) {
        frames++;
        SDFile* f = pd->file->open("out.txt", kFileWrite);
        for (int i = 0; i <= 60; i++) { char* line; int n = pd->system->formatString(&line, "%d %u\n", i, t[i]); pd->file->write(f, line, n); pd->system->realloc(line, 0); }
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) { pd = p; t[0] = pd->sound->getCurrentTime(); pd->system->setUpdateCallback(update, NULL); }
    return 0;
}
