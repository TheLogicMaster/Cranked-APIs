// Legato envelopes. The audenv3 cases with setLegato(1), plus notes without a length.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 12)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
#define N 10
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < N; i++) {
            uint32_t at = t + i * 44100;
            PDSynth* s = syn[i];
            switch (i) {
            case 0: case 1: pd->sound->synth->playNote(s, 330, 0.8f, 0.3f, at); pd->sound->synth->playNote(s, 440, 0.5f, 0.3f, at + 8820); break;
            case 2: case 3: pd->sound->synth->playNote(s, 330, 0.8f, 0.2f, at); pd->sound->synth->playNote(s, 440, 0.5f, 0.3f, at + 11025); break;
            case 4: case 5: pd->sound->synth->playNote(s, 330, 0.4f, 0.2f, at); pd->sound->synth->playNote(s, 440, 0.9f, 0.3f, at + 11025); break;
            case 6: pd->sound->synth->playNote(s, 330, 0.8f, 0.05f, at); pd->sound->synth->playNote(s, 440, 0.6f, 0.3f, at + 3000); break;
            case 7: pd->sound->synth->playNote(s, 330, 0.8f, -1, at); pd->sound->synth->playNote(s, 440, 0.6f, -1, at + 6000); pd->sound->synth->noteOff(s, at + 15000); break;
            case 8: pd->sound->synth->playNote(s, 330, 0.7f, 0.25f, at); pd->sound->synth->playNote(s, 392, 0.7f, 0.25f, at + 13230); pd->sound->synth->playNote(s, 494, 0.7f, 0.2f, at + 24000); break;
            case 9: pd->sound->synth->playNote(s, 330, 0.8f, 0.2f, at); pd->sound->synth->playNote(s, 440, 0.5f, 0.3f, at + 9000); break;
            }
        }
    }
    if (frames == 5 + 30 * 11 && !written) {
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
        for (int i = 0; i < N; i++) {
            syn[i] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[i], kWaveformSine);
            pd->sound->synth->setAttackTime(syn[i], 0.1f); pd->sound->synth->setDecayTime(syn[i], 0.15f);
            pd->sound->synth->setSustainLevel(syn[i], 0.5f); pd->sound->synth->setReleaseTime(syn[i], 0.2f);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
            PDSynthEnvelope* e = pd->sound->synth->getEnvelope(syn[i]);
            pd->sound->envelope->setLegato(e, 1);
            if (i == 1 || i == 3 || i == 5) pd->sound->envelope->setRetrigger(e, 1);
            if (i == 4 || i == 5 || i == 9) pd->sound->envelope->setVelocitySensitivity(e, 0.5f);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
