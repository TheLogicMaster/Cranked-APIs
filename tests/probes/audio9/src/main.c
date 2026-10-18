// LFO shapes, seen as the amplitude envelope of a sine note they modulate.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 8)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static PDSynth* syn[6]; static PDSynthLFO* lfo[6];
static const LFOType types[6] = { kLFOTypeSquare, kLFOTypeTriangle, kLFOTypeSine, kLFOTypeSampleAndHold, kLFOTypeSawtoothUp, kLFOTypeSawtoothDown };
static int update(void* ud) {
    frames++;
    for (int k = 0; k < 6; k++) if (frames == 15 + 33 * k) pd->sound->synth->playNote(syn[k], 440.0f, 0.5f, 0.8f, 0);
    if (frames == 230 && !written) {
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
        for (int k = 0; k < 6; k++) {
            syn[k] = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn[k], kWaveformSine);
            lfo[k] = pd->sound->lfo->newLFO(types[k]);
            pd->sound->lfo->setRate(lfo[k], 5.0f); pd->sound->lfo->setDepth(lfo[k], 0.5f);
            pd->sound->synth->setAmplitudeModulator(syn[k], (PDSynthSignalValue*)lfo[k]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
