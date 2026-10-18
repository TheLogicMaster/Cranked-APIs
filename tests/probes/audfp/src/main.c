// File players at rates other than 1 and with rate modulators. One channel and capture each:
// 0 44.1k mono rate 1, 1 rate 1.1, 2 rate 0.7, 3 22.05k mono, 4 32k mono, 5 44.1k stereo rate 1.3,
// 6, 7 rate 1 (a sine LFO rate modulator stops the Simulator with SIGFPE)
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 8
#define PER (44100 * 5)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static FilePlayer* fp[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) for (int k = 0; k < N; k++) pd->sound->fileplayer->play(fp[k], 1);
    if (frames == 5 + 30 * 5 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        static const char* files[N] = {"assets/m44", "assets/m44", "assets/m44", "assets/m22", "assets/m32", "assets/s44", "assets/m44", "assets/m44"};
        static const float rates[N] = {1, 1.1f, 0.7f, 1, 1, 1.3f, 1, 1};
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            fp[k] = pd->sound->fileplayer->newPlayer();
            pd->sound->fileplayer->loadIntoPlayer(fp[k], files[k]);
            pd->sound->fileplayer->setRate(fp[k], rates[k]);
            pd->sound->channel->addSource(ch, (SoundSource*)fp[k]);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
