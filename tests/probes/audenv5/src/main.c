// Envelopes as synth modulators (frequency, amplitude, parameter), with scale, offset, velocity
// sensitivity, sharing, retrigger, curvature, note-off retrigger and legato.
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
            case 5: pd->sound->synth->playNote(s, 330, 0.8f, 0.3f, at); pd->sound->synth->playNote(s, 440, 0.6f, 0.3f, at + 9000); break;
            case 9: pd->sound->synth->playNote(s, 330, 0.7f, 0.3f, at); pd->sound->synth->playNote(s, 392, 0.9f, 0.3f, at + 6000); break;
            default: pd->sound->synth->playNote(s, 330, i == 3 ? 0.5f : 0.8f, 0.5f, at); break;
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
            PDSynthEnvelope* m = pd->sound->envelope->newEnvelope(0.1f, 0.2f, 0.5f, 0.2f);
            PDSynthSignalValue* mv = (PDSynthSignalValue*)m;
            switch (i) {
            case 0: pd->sound->synth->setFrequencyModulator(syn[i], mv); break;
            case 1: pd->sound->synth->setAmplitudeModulator(syn[i], mv); break;
            case 2: pd->sound->envelope->setVelocitySensitivity(m, 0.0f); pd->sound->synth->setFrequencyModulator(syn[i], mv); break;
            case 3: pd->sound->envelope->setVelocitySensitivity(m, 0.5f); pd->sound->synth->setAmplitudeModulator(syn[i], mv); break;
            case 4: pd->sound->synth->setFrequencyModulator(syn[i], mv); pd->sound->synth->setAmplitudeModulator(syn[i], mv); break;
            case 5: pd->sound->envelope->setRetrigger(m, 1); pd->sound->synth->setFrequencyModulator(syn[i], mv); break;
            case 6: pd->sound->synth->setWaveform(syn[i], kWaveformSquare); pd->sound->synth->setParameterModulator(syn[i], 1, mv); break;
            case 7: pd->sound->envelope->setCurvature(m, 0.5f); pd->sound->synth->setAmplitudeModulator(syn[i], mv); break;
            case 8: pd->sound->envelope->setVelocitySensitivity(m, 0.3f); pd->sound->synth->setFrequencyModulator(syn[i], mv); break;
            case 9: pd->sound->envelope->setLegato(m, 1); pd->sound->synth->setAmplitudeModulator(syn[i], mv); break;
            }
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
