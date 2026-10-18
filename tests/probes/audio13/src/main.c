// Sequence playback timing and velocity, captured from the default channel.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 5)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SoundSequence* seq;
static int update(void* ud) {
    frames++;
    if (frames == 15) pd->sound->sequence->play(seq, NULL, NULL);
    if (frames == 110 && !written) {
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
        PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
        PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, kWaveformSine);
        pd->sound->instrument->addVoice(inst, s, 0.0f, 127.0f, 0.0f);
        pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)inst);
        SequenceTrack* t = pd->sound->track->newTrack();
        pd->sound->track->setInstrument(t, inst);
        static const float vel[4] = { 1.0f, 0.5f, 0.25f, 1.0f };
        for (int k = 0; k < 4; k++) pd->sound->track->addNoteEvent(t, (uint32_t)(4 * k), 2, 69.0f, vel[k]);
        seq = pd->sound->sequence->newSequence();
        pd->sound->sequence->setTrackAtIndex(seq, t, 0);
        pd->sound->sequence->setTempo(seq, 8.0f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
