// Capture synth waveforms at several frequencies (band-limiting study).
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t capL[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) capL[captured] = (bufactive && left) ? (int16_t)(left[i] >> 8) : 0;
    return bufactive;
}
static const float freqs[] = { 30, 100, 200, 440, 1000, 2000, 4000, 8000 };
static const SoundWaveform waves[] = { kWaveformSawtooth, kWaveformSquare, kWaveformTriangle };
#define NW 3
#define NF 8
static PDSynth* syn[NW * NF + 2];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t0 = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < NW * NF; i++) pd->sound->synth->playNote(syn[i], freqs[i % NF], 0.5f, 0.2f, t0 + i * 11025);
        // noise: two notes on one synth
        pd->sound->synth->playNote(syn[NW * NF], 440.0f, 0.5f, 0.1f, t0 + 24 * 11025);
        pd->sound->synth->playNote(syn[NW * NF + 1], 440.0f, 0.5f, 0.1f, t0 + 25 * 11025);
    }
    if (frames == 5 + 30 * 7) pd->sound->synth->playNote(syn[NW * NF], 440.0f, 0.5f, 0.1f, 0); // second noise note
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
        for (int i = 0; i < NW * NF + 2; i++) {
            syn[i] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[i], i < NW * NF ? waves[i / NF] : kWaveformNoise);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
