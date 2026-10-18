// Synth frequency and amplitude modulators (LFOs), notes scheduled on the audio clock.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
#define NN 12
static PDSynth* syn[NN];
static const LFOType types[6] = { kLFOTypeSquare, kLFOTypeTriangle, kLFOTypeSine, kLFOTypeSampleAndHold, kLFOTypeSawtoothUp, kLFOTypeSawtoothDown };
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t0 = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < NN; i++) pd->sound->synth->playNote(syn[i], 440.0f, 0.5f, 0.5f, t0 + i * 26460 + i * 37);
    }
    if (frames == 5 + 30 * 8 + 20 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 4);
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int i = 0; i < NN; i++) {
            syn[i] = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn[i], kWaveformSine);
            PDSynthLFO* l = pd->sound->lfo->newLFO(types[i % 6]);
            pd->sound->lfo->setRate(l, 5.0f); pd->sound->lfo->setDepth(l, 0.5f);
            if (i < 6) pd->sound->synth->setFrequencyModulator(syn[i], (PDSynthSignalValue*)l);
            else { pd->sound->lfo->setCenter(l, 0.5f); pd->sound->synth->setAmplitudeModulator(syn[i], (PDSynthSignalValue*)l); }
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
