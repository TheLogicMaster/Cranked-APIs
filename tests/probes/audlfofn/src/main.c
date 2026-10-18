// Function LFOs (setFunction), with and without interpolation, as frequency and duty modulators.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 6)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int calls[4];
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static float fn(PDSynthLFO* l, void* ud) { int k = (int)(intptr_t)ud; calls[k]++; return (float)((calls[k] % 5) - 2) * 0.25f; }
#define N 4
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < N; i++) pd->sound->synth->playNote(syn[i], 330, 0.5f, 1.0f, t + i * 44100 + (uint32_t)(i * 37));
    }
    if (frames == 5 + 30 * 5 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 4); pd->file->close(f);
        char* b; pd->system->formatString(&b, "calls %d %d %d %d\n", calls[0], calls[1], calls[2], calls[3]);
        f = pd->file->open("log.txt", kFileWrite); pd->file->write(f, b, (unsigned)strlen(b)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int i = 0; i < N; i++) {
            syn[i] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[i], i < 2 ? kWaveformSine : kWaveformSquare);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
            PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSine);
            pd->sound->lfo->setFunction(l, fn, (void*)(intptr_t)i, i == 1);
            pd->sound->lfo->setRate(l, 6.0f + i);
            if (i < 2) pd->sound->synth->setFrequencyModulator(syn[i], (PDSynthSignalValue*)l);
            else { pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setDepth(l, 0.4f); pd->sound->synth->setParameterModulator(syn[i], 1, (PDSynthSignalValue*)l); }
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
