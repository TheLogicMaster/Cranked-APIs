// Sample players with rate modulators; otherwise as audsp: play ranges, reverse, ping-pong, loops, stop and pause fades, offsets, rate changes,
// and loop and finish callbacks. Actions are driven from the capture effect, one per audio block, so both
// environments apply them at the same block.
#include "pd_api.h"
#include <math.h>
static PlaydateAPI* pd;
#define MAXF (44100 * 14)
static int32_t cap[MAXF];
static int captured = 0, written = 0, block = 0;
#define NC 5
static SamplePlayer* sp[NC];
static AudioSample *mono, *stereo;
static int loops[NC], finishes[NC];
static char logbuf[4096]; static int logn = 0;
static void lg(const char* s) { int l = (int)strlen(s); if (logn + l < (int)sizeof logbuf) { memcpy(logbuf + logn, s, l); logn += l; } }
static void onLoop(SoundSource* s, void* ud) { loops[(int)(intptr_t)ud]++; }
static void onFinish(SoundSource* s, void* ud) { finishes[(int)(intptr_t)ud]++; }
static void act(int c, int r) {
    SamplePlayer* p = sp[c];
    switch (c) {
    case 0: if (r == 0) pd->sound->sampleplayer->play(p, 0, 1.0f); if (r == 150) pd->sound->sampleplayer->stop(p); break;
    case 1: if (r == 0) pd->sound->sampleplayer->play(p, 0, 1.0f); if (r == 150) pd->sound->sampleplayer->stop(p); break;
    case 2: if (r == 0) { pd->sound->sampleplayer->setPlayRange(p, 1000, 6000); pd->sound->sampleplayer->play(p, -1, -1.0f); } if (r == 150) pd->sound->sampleplayer->stop(p); break;
    case 3: if (r == 0) pd->sound->sampleplayer->play(p, 0, 0.8f); if (r == 150) pd->sound->sampleplayer->stop(p); break;
    case 4: if (r == 0) pd->sound->sampleplayer->play(p, 2, 1.2f); break;
    }
    if (r == 5 || r == 40 || r == 150) {
        char* b; pd->system->formatString(&b, "c%d r%d off %d playing %d\n", c, r, (int)(pd->sound->sampleplayer->getOffset(p) * 1000000), pd->sound->sampleplayer->isPlaying(p)); lg(b); pd->system->realloc(b, 0);
    }
}
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    int rel = block - 20;
    if (rel >= 0 && rel / 200 < NC) act(rel / 200, rel % 200);
    block++;
    return bufactive;
}
static int update(void* ud) {
    if (block > 20 + NC * 200 + 10 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 4); pd->file->close(f);
        for (int c = 0; c < NC; c++) { char* b; pd->system->formatString(&b, "c%d loops %d finishes %d\n", c, loops[c], finishes[c]); lg(b); pd->system->realloc(b, 0); }
        f = pd->file->open("log.txt", kFileWrite); pd->file->write(f, logbuf, logn); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        static int16_t m[11025], st[2 * 6000];
        for (int i = 0; i < 11025; i++) m[i] = (int16_t)(((i * 640) % 16000) - 8000 + ((i * 37) % 3000) + (i % 1000) * 4); // integer only, so both builds agree
        for (int i = 0; i < 6000; i++) { st[2 * i] = (int16_t)(((i * 450) % 18000) - 9000); st[2 * i + 1] = (int16_t)(((i * 611) % 14000) - 7000); }
        mono = pd->sound->sample->newSampleFromData((uint8_t*)m, kSound16bitMono, 44100, sizeof m, 0);
        stereo = pd->sound->sample->newSampleFromData((uint8_t*)st, kSound16bitStereo, 44100, sizeof st, 0);
        for (int c = 0; c < NC; c++) {
            sp[c] = pd->sound->sampleplayer->newPlayer();
            pd->sound->sampleplayer->setSample(sp[c], c == 4 ? stereo : mono);
            pd->sound->sampleplayer->setVolume(sp[c], 0.6f, 0.6f);
            pd->sound->sampleplayer->setLoopCallback(sp[c], onLoop, (void*)(intptr_t)c);
            pd->sound->sampleplayer->setFinishCallback(sp[c], onFinish, (void*)(intptr_t)c);
            static const LFOType types[NC] = { kLFOTypeSine, kLFOTypeSquare, kLFOTypeSawtoothUp, kLFOTypeSampleAndHold, kLFOTypeTriangle };
            PDSynthLFO* l = pd->sound->lfo->newLFO(types[c]);
            pd->sound->lfo->setRate(l, 3.0f + c); pd->sound->lfo->setCenter(l, 1.0f); pd->sound->lfo->setDepth(l, 0.3f + 0.05f * c);
            pd->sound->sampleplayer->setRateModulator(sp[c], (PDSynthSignalValue*)l);
        }
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
