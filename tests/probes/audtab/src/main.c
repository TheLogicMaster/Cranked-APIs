// Play synth notes whose phase steps land on exact wavetable entries; rec.py reads the sampled waveform back from a capture.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t capL[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) capL[captured] = (bufactive && left) ? (int16_t)(left[i] >> 8) : 0;
    return bufactive;
}
// phase step in table entries (256-entry tables): 1.5 x 2^(k-1), plus 1 from level 3 up
static const float steps[] = { 0.75f, 1.5f, 3.0f, 7.0f, 13.0f, 25.0f, 49.0f, 97.0f };
#define NS 8
#define NN (NS * 2 + 1)
static PDSynth* syn[NN];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t0 = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < NN; i++) {
            float f = i < NN - 1 ? steps[i % NS] / 256.0f * 44100.0f : 44100.0f / 1024.0f; // last: sine, 1024 entries
            pd->sound->synth->playNote(syn[i], f, 1.0f, 0.2f, t0 + i * 11025);
        }
    }
    if (frames == 5 + 30 * 7 && !written) {
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
            pd->sound->synth->setWaveform(syn[i], i < NS ? kWaveformSawtooth : i < 2 * NS ? kWaveformTriangle : kWaveformSine);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
