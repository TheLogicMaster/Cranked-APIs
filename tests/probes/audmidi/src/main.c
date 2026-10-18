// MIDI pitch bend through a sequence: RPN 0 sets the track's range, which the instrument gets when set
// on the track (0 when the file has no RPN); bends are applied per block. Case 2 sets the range after setInstrument.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 12)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static SoundSequence* seq[3];
static int update(void* ud) {
    frames++;
    if (frames == 5) pd->sound->sequence->play(seq[0], NULL, NULL);
    if (frames == 5 + 30 * 3) pd->sound->sequence->play(seq[1], NULL, NULL);
    if (frames == 5 + 30 * 6) pd->sound->sequence->play(seq[2], NULL, NULL);
    if (frames == 5 + 30 * 10 && !written) {
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
        for (int i = 0; i < 3; i++) {
            seq[i] = pd->sound->sequence->newSequence();
            pd->sound->sequence->loadMIDIFile(seq[i], i == 0 ? "song.mid" : "song2.mid");
            SequenceTrack* t = pd->sound->sequence->getTrackAtIndex(seq[i], 0);
            PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
            PDSynth* s = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(s, kWaveformSine);
            pd->sound->instrument->addVoice(inst, s, 0, 127, 0);
            pd->sound->track->setInstrument(t, inst);
            if (i == 2) pd->sound->instrument->setPitchBendRange(inst, 5.0f);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)inst);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
