// Sequence loops (setLoops), captured as note onsets.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 9)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SoundSequence* seq[2];
static int update(void* ud) {
    frames++;
    if (frames == 15) pd->sound->sequence->play(seq[0], NULL, NULL);
    if (frames == 150) pd->sound->sequence->play(seq[1], NULL, NULL);
    if (frames == 260 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch = pd->sound->getDefaultChannel();
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, fx);
        static const float notes[2] = { 69.0f, 76.0f };   // A4 at step 0, E5 at step 4
        for (int k = 0; k < 2; k++) {
            PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
            PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, kWaveformSine);
            pd->sound->instrument->addVoice(inst, s, 0.0f, 127.0f, 0.0f);
            pd->sound->channel->addSource(ch, (SoundSource*)inst);
            SequenceTrack* t = pd->sound->track->newTrack(); pd->sound->track->setInstrument(t, inst);
            for (int j = 0; j < 2; j++) pd->sound->track->addNoteEvent(t, (uint32_t)(4 * j), 2, notes[j], 0.5f);
            seq[k] = pd->sound->sequence->newSequence(); pd->sound->sequence->setTrackAtIndex(seq[k], t, 0);
            pd->sound->sequence->setTempo(seq[k], 8.0f);
        }
        pd->sound->sequence->setLoops(seq[0], 0, 8, 3);
        pd->sound->sequence->setLoops(seq[1], 4, 8, 2);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
