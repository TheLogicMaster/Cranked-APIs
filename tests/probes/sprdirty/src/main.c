// sprite->markDirtyRect (SDK 3.1). Logs the bounds and draw rect each draw callback receives.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
static SDFile* logFile;
static int frames = 0;
static LCDSprite *a, *b;
static void logLine(const char* fmt, double v0, double v1, double v2, double v3, double v4) {
    char* line; pd->system->formatString(&line, fmt, v0, v1, v2, v3, v4);
    pd->file->write(logFile, line, (unsigned)strlen(line)); pd->system->realloc(line, 0);
}
static void draw(LCDSprite* s, PDRect bounds, PDRect drawrect) {
    logLine("f%.0f draw %.0f: %.1f %.1f", frames, s == a ? 1 : 2, bounds.x, bounds.y, 0);
    logLine(" rect %.1f %.1f %.1f %.1f\n", drawrect.x, drawrect.y, drawrect.width, drawrect.height, 0);
    pd->graphics->fillRect((int)bounds.x, (int)bounds.y, (int)bounds.width, (int)bounds.height, kColorBlack);
}
static int update(void* ud) {
    frames++;
    if (frames == 3) { PDRect r = {10.7f, 5.2f, 20.9f, 8.0f}; pd->sprite->markDirtyRect(a, r); }
    if (frames == 4) { PDRect r = {-30, -10, 50, 40}; pd->sprite->markDirtyRect(a, r); }
    if (frames == 5) { PDRect r = {5, 5, 10, 10}; pd->sprite->markDirtyRect(b, r); } // b is not in the display list
    if (frames == 6) { pd->sprite->moveTo(a, 120.5f, 90.25f); }
    if (frames == 7) { PDRect r = {0, 0, 4, 4}; pd->sprite->markDirtyRect(a, r); }
    pd->sprite->updateAndDrawSprites();
    if (frames == 10) pd->file->close(logFile);
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        logFile = pd->file->open("log.txt", kFileWrite);
        a = pd->sprite->newSprite(); b = pd->sprite->newSprite();
        PDRect bounds = {50, 40, 100, 60};
        pd->sprite->setBounds(a, bounds); pd->sprite->setBounds(b, bounds);
        pd->sprite->setDrawFunction(a, draw); pd->sprite->setDrawFunction(b, draw);
        pd->sprite->addSprite(a);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
