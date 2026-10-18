// MIDI playback with a one-voice and a two-voice instrument (voice allocation for a chord).
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (active && left) ? left[i] : 0;
    return active;
}
static SoundSequence* seq[2];
static int update(void* ud) {
    frames++;
    if (frames == 15) pd->sound->sequence->play(seq[0], NULL, NULL);
    if (frames == 110) pd->sound->sequence->play(seq[1], NULL, NULL); // after the first has finished (so the comparison does not depend on frame timing)
    if (frames == 210 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 4)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch = pd->sound->getDefaultChannel();
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, fx);
        for (int k = 0; k < 2; k++) {
            seq[k] = pd->sound->sequence->newSequence();
            pd->sound->sequence->loadMIDIFile(seq[k], "song.mid");
            PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
            for (int v = 0; v <= k; v++) {
                PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, kWaveformSine);
                pd->sound->instrument->addVoice(inst, s, 0.0f, 127.0f, 0.0f);
            }
            pd->sound->channel->addSource(ch, (SoundSource*)inst);
            pd->sound->track->setInstrument(pd->sound->sequence->getTrackAtIndex(seq[k], 0), inst);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
