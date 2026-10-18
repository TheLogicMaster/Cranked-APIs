// sequence->allNotesOff. A sequence with one track (sine synth voices, release 0.2 s) plays two long
// notes; after 60 blocks the capture effect calls allNotesOff (so at the same block in both). The track's instrument
// is in the capture's channel.
#include "pd_api.h"
static PlaydateAPI* pd;
#define PER (44100 * 2)
static int32_t cap[PER];
static int captured = 0, frames = 0, written = 0;
static SoundSequence* seq;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    if (captured == 256 * 60) pd->sound->sequence->allNotesOff(seq);
    for (int i = 0; i < n && captured < PER; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int update(void* ud) {
    frames++;
    if (frames == 70 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, (unsigned)PER * 4);
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch = pd->sound->channel->newChannel();
        pd->sound->addChannel(ch);
        PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
        for (int v = 0; v < 2; v++) {
            PDSynth* s = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(s, kWaveformSine);
            pd->sound->synth->setReleaseTime(s, 0.2f);
            pd->sound->instrument->addVoice(inst, s, 0, 127, 0);
        }
        pd->sound->channel->addSource(ch, (SoundSource*)inst);
        seq = pd->sound->sequence->newSequence();
        SequenceTrack* t = pd->sound->sequence->addTrack(seq);
        pd->sound->track->setInstrument(t, inst);
        pd->sound->track->addNoteEvent(t, 0, 400, 60, 0.7f);
        pd->sound->track->addNoteEvent(t, 2, 400, 67, 0.5f);
        pd->sound->sequence->setTempo(seq, 8.0f);
        SoundEffect* c = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, c);
        pd->sound->sequence->play(seq, NULL, NULL);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
