// Baseline for audfxmod (the same channels and notes, no effects). One channel per case, each with its own capture;
// notes are scheduled in audio time.
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 7
#define MAXF (44100 * 9)
static int32_t cap[N][MAXF / N];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < MAXF / N; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        for (int k = 0; k < N; k++) pd->sound->synth->playNote(syn[k], 220.0f, 0.8f, 0.8f, t);
    }
    if (frames == 5 + 30 * 7 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)(MAXF / N) * 4);
        pd->file->close(f);
    }
    return 1;
}
static PDSynthLFO* lfo(float rate, float center, float depth) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSine);
    pd->sound->lfo->setRate(l, rate); pd->sound->lfo->setCenter(l, center); pd->sound->lfo->setDepth(l, depth);
    return l;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            syn[k] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[k], kWaveformSine);
            pd->sound->channel->addSource(ch, (SoundSource*)syn[k]);
            SoundEffect* fx = NULL;
            switch (k) {
            case 0: { Overdrive* o = pd->sound->effect->overdrive->newOverdrive(); pd->sound->effect->overdrive->setGain(o, 3.0f);
                      pd->sound->effect->overdrive->setLimitModulator(o, (PDSynthSignalValue*)lfo(2.0f, 0.4f, 0.3f)); fx = (SoundEffect*)o; break; }
            case 1: { Overdrive* o = pd->sound->effect->overdrive->newOverdrive(); pd->sound->effect->overdrive->setGain(o, 2.0f); pd->sound->effect->overdrive->setLimit(o, 0.3f);
                      fx = (SoundEffect*)o; pd->sound->effect->setMixModulator(fx, (PDSynthSignalValue*)lfo(3.0f, 0.0f, 0.8f)); break; }
            case 2: { BitCrusher* b = pd->sound->effect->bitcrusher->newBitCrusher(); pd->sound->effect->bitcrusher->setAmount(b, 0.8f);
                      pd->sound->effect->bitcrusher->setAmountModulator(b, (PDSynthSignalValue*)lfo(2.0f, 0.5f, 0.5f)); fx = (SoundEffect*)b; break; }
            case 3: { RingModulator* r = pd->sound->effect->ringmodulator->newRingmod(); pd->sound->effect->ringmodulator->setFrequency(r, 200.0f);
                      pd->sound->effect->ringmodulator->setFrequencyModulator(r, (PDSynthSignalValue*)lfo(1.5f, 0.0f, 0.01f)); fx = (SoundEffect*)r; break; }
            case 4: { TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(f, kFilterTypeLowPass);
                      pd->sound->effect->twopolefilter->setFrequency(f, 1000.0f); pd->sound->effect->twopolefilter->setResonance(f, 0.5f);
                      pd->sound->effect->twopolefilter->setFrequencyModulator(f, (PDSynthSignalValue*)lfo(2.5f, 0.0f, 0.04f)); fx = (SoundEffect*)f; break; }
            case 5: { TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(f, kFilterTypeBandPass);
                      pd->sound->effect->twopolefilter->setFrequency(f, 800.0f);
                      pd->sound->effect->twopolefilter->setResonanceModulator(f, (PDSynthSignalValue*)lfo(2.0f, 0.5f, 0.4f)); fx = (SoundEffect*)f; break; }
            case 6: { OnePoleFilter* f = pd->sound->effect->onepolefilter->newFilter(); pd->sound->effect->onepolefilter->setParameter(f, -0.5f);
                      pd->sound->effect->onepolefilter->setParameterModulator(f, (PDSynthSignalValue*)lfo(2.0f, 0.0f, 0.45f)); fx = (SoundEffect*)f; break; }
            }
            (void) fx; // baseline: no effect
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
