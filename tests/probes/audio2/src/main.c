// Capture the main channel mix while playing a timed list of synth notes.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static PDSynth* synths[8];
// Start frame (at 30 fps), waveform, length in seconds, and whether to set an explicit envelope.
static const int startFrame[] = { 15, 30, 45, 60, 75, 90, 135, 0 };
static const int wave[]       = { kWaveformSquare, kWaveformSine, kWaveformTriangle, kWaveformSawtooth, kWaveformNoise, kWaveformSquare, kWaveformSquare };
static const float len[]      = { 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f, 0.3f };
static int update(void* ud) {
    frames++;
    for (int i = 0; i < 7; i++)
        if (frames == startFrame[i]) pd->sound->synth->playNote(synths[i], 440.0f, 0.5f, len[i], 0);
    if (frames == 240 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 2); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int i = 0; i < 7; i++) { synths[i] = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(synths[i], (SoundWaveform)wave[i]); }
        pd->sound->synth->setAttackTime(synths[6], 0.05f); pd->sound->synth->setDecayTime(synths[6], 0.1f);
        pd->sound->synth->setSustainLevel(synths[6], 0.5f); pd->sound->synth->setReleaseTime(synths[6], 0.2f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
