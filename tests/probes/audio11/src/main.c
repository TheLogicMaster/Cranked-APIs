// An LFO on a two-pole filter's frequency, probed with impulses every 0.25 s.
#include "pd_api.h"
static PlaydateAPI* pd;
#ifndef DEPTH
#define DEPTH 0.01f  // LFO depth: the filter frequency swings by DEPTH * 22050 Hz
#endif
#define MAXF (44100 * 4)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SamplePlayer* sp;
static int update(void* ud) {
    frames++;
    if (frames == 15) pd->sound->sampleplayer->play(sp, 1, 1.0f);
    if (frames == 100 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch = pd->sound->getDefaultChannel();
        TwoPoleFilter* lp = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(lp, kFilterTypeLowPass);
        pd->sound->effect->twopolefilter->setFrequency(lp, 1000.0f); pd->sound->effect->twopolefilter->setResonance(lp, 0.5f);
        PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSquare); pd->sound->lfo->setRate(l, 2.0f); pd->sound->lfo->setDepth(l, DEPTH);
        pd->sound->effect->twopolefilter->setFrequencyModulator(lp, (PDSynthSignalValue*)l);
        pd->sound->channel->addEffect(ch, (SoundEffect*)lp);
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, fx);
        AudioSample* s = pd->sound->sample->load("assets/impulses");
        sp = pd->sound->sampleplayer->newPlayer(); pd->sound->sampleplayer->setSample(sp, s);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
