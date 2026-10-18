// Wavetable synths (setWavetable, parameters 1-4), notes scheduled on the audio clock.
#include "pd_api.h"
#include <math.h>
static PlaydateAPI* pd;
#define MAXF (44100 * 10)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int16_t wt[2 * 4 * 64];
#define N 8
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        static const float freq[N] = { 220, 220, 330, 220, 2000, 440, 110, 220 };
        for (int i = 0; i < N; i++) pd->sound->synth->playNote(syn[i], freq[i], 0.5f, 0.5f, t + i * 44100);
    }
    if (frames == 5 + 30 * 9 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 4); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int r = 0; r < 2; r++) for (int c = 0; c < 4; c++) for (int i = 0; i < 64; i++) {
            int k = (r * 4 + c);
            float x = i / 64.0f;
            float v = k == 0 ? sinf(6.2831853f * x) : k == 1 ? (x < 0.5f ? 1 : -1) : k == 2 ? 2 * x - 1 : k == 3 ? (x < 0.5f ? 4 * x - 1 : 3 - 4 * x)
                    : k == 4 ? sinf(12.566f * x) : k == 5 ? (x < 0.25f ? 1 : -0.3f) : k == 6 ? 1 - 2 * x * x : sinf(6.2831853f * x) * x;
            wt[k * 64 + i] = (int16_t)(v * 20000);
        }
        AudioSample* s1 = pd->sound->sample->newSampleFromData((uint8_t*)wt, kSound16bitMono, 44100, sizeof wt, 0);
        for (int i = 0; i < N; i++) { syn[i] = pd->sound->synth->newSynth(); pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]); }
        PDSynthLFO* l;
        pd->sound->synth->setWavetable(syn[0], s1, 6, 4, 1); l = pd->sound->lfo->newLFO(kLFOTypeTriangle); pd->sound->lfo->setRate(l, 2.0f); pd->sound->lfo->setCenter(l, 1.5f); pd->sound->lfo->setDepth(l, 1.5f); pd->sound->synth->setParameterModulator(syn[0], 1, (PDSynthSignalValue*)l);
        pd->sound->synth->setWavetable(syn[1], s1, 6, 4, 2); l = pd->sound->lfo->newLFO(kLFOTypeSine); pd->sound->lfo->setRate(l, 3.0f); pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->synth->setParameterModulator(syn[1], 4, (PDSynthSignalValue*)l);
        pd->sound->synth->setWaveform(syn[2], kWaveformSquare); l = pd->sound->lfo->newLFO(kLFOTypeSine); pd->sound->lfo->setRate(l, 2.0f); pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setDepth(l, 0.3f); pd->sound->synth->setParameterModulator(syn[2], 1, (PDSynthSignalValue*)l);
        pd->sound->synth->setWavetable(syn[3], s1, 6, 4, 1); l = pd->sound->lfo->newLFO(kLFOTypeSawtoothUp); pd->sound->lfo->setRate(l, 1.0f); pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->synth->setParameterModulator(syn[3], 2, (PDSynthSignalValue*)l);
        for (int i = 4; i < N; i++) pd->sound->synth->setWavetable(syn[i], s1, 6, 4, 1);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
