// Capture synth waveforms at several frequencies (band-limiting study).
#include "pd_api.h"
#include <math.h>
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t capL[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) capL[captured] = (bufactive && left) ? (int16_t)(left[i] >> 8) : 0;
    return bufactive;
}
#define NN 60
static PDSynth* syn[NN];
static SoundWaveform wave = kWaveformSquare;
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t0 = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < NN; i++) pd->sound->synth->playNote(syn[i], 20.0f * powf(2.0f, i / 6.0f), 0.5f, 0.1f, t0 + i * 5512);
    }
    if (frames == 5 + 30 * 8 + 20 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, capL, captured * 2);
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
            syn[i] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[i], wave);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
