// Frequency modulation units (square LFO on a synth's frequency).
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 6)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static PDSynth* syn[3]; static const float depths[3] = { 0.5f, 1.0f, 0.1f };
static int update(void* ud) {
    frames++;
    for (int k = 0; k < 3; k++) if (frames == 15 + 36 * k) pd->sound->synth->playNote(syn[k], 440.0f, 0.5f, 1.0f, 0);
    if (frames == 150 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int k = 0; k < 3; k++) {
            syn[k] = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn[k], kWaveformSine);
            PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSquare); pd->sound->lfo->setRate(l, 2.0f); pd->sound->lfo->setDepth(l, depths[k]);
            pd->sound->synth->setFrequencyModulator(syn[k], (PDSynthSignalValue*)l);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
