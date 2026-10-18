// Which channels are mixed. Each has a capture effect and a note at 0.25 s: 0 made with newChannel
// but never added, 1 added, 2 added and removed at frame 10 (about 0.33 s), 3 added twice (the second add's result is
// written to result.txt with removeChannel's results).
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 4
#define PER (44100 * 1)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0, results[4];
static SoundChannel* ch[N];
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int update(void* ud) {
    if (++frames == 10) { results[2] = pd->sound->removeChannel(ch[2]); results[3] = pd->sound->removeChannel(ch[0]); }
    if (frames == 60 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
        pd->file->close(f);
        f = pd->file->open("result.txt", kFileWrite);
        char* line; pd->system->formatString(&line, "%d %d %d %d\n", results[0], results[1], results[2], results[3]);
        pd->file->write(f, line, 8); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        for (int k = 0; k < N; k++) {
            ch[k] = pd->sound->channel->newChannel();
            if (k > 0) pd->sound->addChannel(ch[k]);
            pd->sound->channel->addEffect(ch[k], pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k));
            PDSynth* s = pd->sound->synth->newSynth();
            pd->sound->channel->addSource(ch[k], (SoundSource*)s);
            pd->sound->synth->playNote(s, 330 + 110 * k, 0.5f, 0.3f, (uint32_t)(0.25f * 44100));
        }
        results[0] = pd->sound->addChannel(ch[1]);
        results[1] = pd->sound->addChannel(ch[3]);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
