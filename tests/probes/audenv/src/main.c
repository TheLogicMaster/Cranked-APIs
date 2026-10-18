// Envelope timing with a 1 Hz square (constant level, so each sample shows the amplitude).
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t capL[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) capL[captured] = (bufactive && left) ? (int16_t)(left[i] >> 8) : 0;
    return bufactive;
}
#define NN 24
static PDSynth* syn[NN];
// case: 0 default, 1 R=0.1, 2 A=.05 D=.05 S=.5 R=.05, 3 R=0.005 set, 4 R=0, 5 no waveform set (440 Hz)
static const int kase[NN] = { 0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,0,0 };
static const float lens[NN] = { 0.2f,0.2f,0.1f,0.0123f, 0.2f,0.2f,0.1f,0.0123f, 0.2f,0.2f,0.1f,0.0123f, 0.2f,0.2f,0.1f,0.0123f, 0.2f,0.2f,0.1f,0.0123f, 0.2f,0.2f, 0.003f, 0.25f };
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t0 = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < NN; i++) pd->sound->synth->playNote(syn[i], kase[i] == 5 ? 440.0f : 1.0f, 0.5f, lens[i], t0 + i * 15000 + i * 37);
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
            PDSynth* s = syn[i] = pd->sound->synth->newSynth();
            if (kase[i] != 5) pd->sound->synth->setWaveform(s, kWaveformSquare);
            if (kase[i] == 1) pd->sound->synth->setReleaseTime(s, 0.1f);
            if (kase[i] == 2) { pd->sound->synth->setAttackTime(s, 0.05f); pd->sound->synth->setDecayTime(s, 0.05f); pd->sound->synth->setSustainLevel(s, 0.5f); pd->sound->synth->setReleaseTime(s, 0.05f); }
            if (kase[i] == 3) pd->sound->synth->setReleaseTime(s, 0.005f);
            if (kase[i] == 4) pd->sound->synth->setReleaseTime(s, 0.0f);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)s);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
