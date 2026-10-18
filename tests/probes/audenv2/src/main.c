// Envelope curvature, velocity sensitivity, rate scaling and legato on synth envelopes.
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
            if (i == 6) { pd->sound->synth->playMIDINote(syn[i], 40, 0.8f, -1, at); pd->sound->synth->noteOff(syn[i], at + 22050); }
            else if (i == 7) { pd->sound->synth->playMIDINote(syn[i], 90, 0.8f, 0.5f, at); }
            else if (i == 8) { pd->sound->synth->playNote(syn[i], 330, 0.6f, -1, at); pd->sound->synth->playNote(syn[i], 440, 0.9f, -1, at + 8000); pd->sound->synth->noteOff(syn[i], at + 22050); }
            else pd->sound->synth->playNote(syn[i], 330, i == 2 || i == 3 ? 0.4f : 0.8f, 0.5f, at);
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
            switch (i) {
            case 0: break; // reference: linear
            case 1: pd->sound->envelope->setCurvature(e, 0.5f); break;
            case 2: pd->sound->envelope->setVelocitySensitivity(e, 0.0f); break;
            case 3: pd->sound->envelope->setVelocitySensitivity(e, 0.5f); break;
            case 4: pd->sound->envelope->setCurvature(e, 1.0f); break;
            case 5: pd->sound->envelope->setCurvature(e, 0.2f); pd->sound->envelope->setVelocitySensitivity(e, 0.3f); break;
            case 6: pd->sound->envelope->setRateScaling(e, 2.0f, 36, 84); break;
            case 7: pd->sound->envelope->setRateScaling(e, 0.5f, 36, 84); break;
            case 8: pd->sound->envelope->setLegato(e, 1); break;
            case 9: pd->sound->envelope->setVelocitySensitivity(e, 0.5f); pd->sound->envelope->setCurvature(e, 0.7f); break;
            }
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
