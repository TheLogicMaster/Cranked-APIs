// drawRotatedBitmap with a center other than (0.5, 0.5) at scales whose result passes 4 megapixels
// (only the visible part is drawn) and below (the whole rotated image). Writes each frame's pixels to out.raw, and
// "done" to out.txt after a scale of 1e30 (which must neither allocate the result nor take long).
#include "pd_api.h"
static PlaydateAPI* pd;
static LCDBitmap* bmp;
static int frame = 0;
static const float cases[][5] = { // angle, cx, cy, scale x, scale y
    { 30, 0, 0, 3, 3 }, { 30, 0, 0, 110, 110 }, { 200, 1, 1, 120, 90 }, { 75, 0.3f, 0.8f, 105, 140 },
    { 75, 0.3f, 0.8f, 6, 4 }, { 330, 0, 1, -115, 112 }, { 45, 0.2f, 0.1f, 1e30f, 1e30f },
};
static SDFile* raw;
static int update(void* ud) {
    int n = sizeof(cases) / sizeof(cases[0]);
    if (frame < n) {
        const float* c = cases[frame];
        pd->graphics->clear(kColorWhite);
        pd->graphics->drawRotatedBitmap(bmp, 200, 120, c[0], c[1], c[2], c[3], c[4]);
        pd->graphics->markUpdatedRows(0, 239);
        pd->file->write(raw, pd->graphics->getFrame(), 52 * 240);
    } else if (frame == n) {
        pd->file->close(raw);
        SDFile* f = pd->file->open("out.txt", kFileWrite); pd->file->write(f, "done\n", 5); pd->file->close(f);
    }
    frame++;
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        bmp = pd->graphics->newBitmap(21, 17, kColorWhite);
        pd->graphics->pushContext(bmp);
        pd->graphics->fillRect(0, 0, 10, 8, kColorBlack); pd->graphics->fillRect(11, 9, 10, 8, kColorBlack);
        pd->graphics->drawLine(0, 16, 20, 0, 1, kColorBlack);
        pd->graphics->popContext();
        raw = pd->file->open("out.raw", kFileWrite);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
