// Teenage Engineering generators (POPhase, PODigital, POVosim), parameters and modulators.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 12)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
#define N 12
static PDSynth* syn[N];
static const float freq[N] = { 220, 330, 220, 220, 440, 220, 150, 440, 300, 220, 220, 331 };
static PDSynthLFO* lfo(LFOType t, float rate, float c, float d) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(t); pd->sound->lfo->setRate(l, rate); pd->sound->lfo->setCenter(l, c); pd->sound->lfo->setDepth(l, d); return l;
}
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < N; i++) {
            int slot = i < 11 ? i : 10; // the last two play together
            pd->sound->synth->playNote(syn[i], freq[i], 0.5f, 0.5f, t + slot * 44100);
        }
    }
    if (frames == 5 + 30 * 12 && !written) {
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
        static const SoundWaveform w[N] = { kWaveformPOPhase, kWaveformPOPhase, kWaveformPOPhase, kWaveformPODigital, kWaveformPODigital,
            kWaveformPOVosim, kWaveformPOVosim, kWaveformPOPhase, kWaveformPOVosim, kWaveformPODigital, kWaveformPOPhase, kWaveformPOPhase };
        for (int i = 0; i < N; i++) {
            syn[i] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[i], w[i]);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->sound->synth->setParameter(syn[1], 1, 0.2f); pd->sound->synth->setParameter(syn[1], 2, 0.9f);
        pd->sound->synth->setParameter(syn[9], 1, 0.9f); pd->sound->synth->setParameter(syn[9], 2, 0.1f);
        pd->sound->synth->setParameterModulator(syn[2], 1, (PDSynthSignalValue*)lfo(kLFOTypeSine, 2, 0.5f, 0.5f));
        pd->sound->synth->setParameterModulator(syn[2], 2, (PDSynthSignalValue*)lfo(kLFOTypeSawtoothUp, 1, 0.5f, 0.4f));
        pd->sound->synth->setParameterModulator(syn[4], 1, (PDSynthSignalValue*)lfo(kLFOTypeTriangle, 3, 0.5f, 0.5f));
        pd->sound->synth->setParameterModulator(syn[4], 2, (PDSynthSignalValue*)lfo(kLFOTypeSine, 1.5f, 0.4f, 0.4f));
        pd->sound->synth->setParameterModulator(syn[6], 1, (PDSynthSignalValue*)lfo(kLFOTypeSawtoothUp, 2, 0.5f, 0.5f));
        pd->sound->synth->setParameterModulator(syn[6], 2, (PDSynthSignalValue*)lfo(kLFOTypeTriangle, 1, 0.5f, 0.5f));
        pd->sound->synth->setFrequencyModulator(syn[7], (PDSynthSignalValue*)lfo(kLFOTypeSine, 4, 0, 0.5f));
        pd->sound->synth->setFrequencyModulator(syn[8], (PDSynthSignalValue*)lfo(kLFOTypeTriangle, 3, 0, 1));
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
