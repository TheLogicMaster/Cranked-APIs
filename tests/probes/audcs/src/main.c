// Control signals as modulators. Each case is a sequence with one track whose controller signal
// drives its synth's amplitude or frequency, or a filter on its channel; one case loops. One channel and capture each.
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 4
#define MAXF (44100 * 9)
static int32_t cap[N][MAXF / N];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < MAXF / N; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static SoundSequence* seq[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) for (int k = 0; k < N; k++) pd->sound->sequence->play(seq[k], NULL, NULL);
    if (frames == 5 + 30 * 7 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)(MAXF / N) * 4);
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            seq[k] = pd->sound->sequence->newSequence();
            pd->sound->sequence->setTempo(seq[k], 48.0f);
            SequenceTrack* t = pd->sound->sequence->addTrack(seq[k]);
            PDSynthInstrument* inst = pd->sound->instrument->newInstrument();
            PDSynth* s = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(s, kWaveformSine);
            pd->sound->instrument->addVoice(inst, s, 0, 127, 0);
            pd->sound->track->setInstrument(t, inst);
            pd->sound->channel->addSource(ch, (SoundSource*)inst);
            pd->sound->track->addNoteEvent(t, 0, 180, 57, 0.8f);
            ControlSignal* cs = pd->sound->track->getSignalForController(t, 20, 1);
            PDSynthSignalValue* v = (PDSynthSignalValue*)cs;
            switch (k) {
            case 0: case 3:
                pd->sound->controlsignal->addEvent(cs, 0, 0.2f, 1); pd->sound->controlsignal->addEvent(cs, 24, 1.0f, 0);
                pd->sound->controlsignal->addEvent(cs, 48, 0.5f, 1); pd->sound->controlsignal->addEvent(cs, 96, 0.1f, 0);
                pd->sound->synth->setAmplitudeModulator(s, v);
                if (k == 3) pd->sound->sequence->setLoops(seq[k], 0, 59, 2);
                break;
            case 1:
                pd->sound->controlsignal->addEvent(cs, 0, 0.0f, 1); pd->sound->controlsignal->addEvent(cs, 48, 1.0f, 0);
                pd->sound->controlsignal->addEvent(cs, 72, -0.5f, 0);
                pd->sound->synth->setFrequencyModulator(s, v);
                break;
            case 2: {
                pd->sound->controlsignal->addEvent(cs, 0, 0.0f, 1); pd->sound->controlsignal->addEvent(cs, 96, 0.08f, 1);
                pd->sound->controlsignal->addEvent(cs, 144, 0.0f, 0);
                TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(f, kFilterTypeLowPass);
                pd->sound->effect->twopolefilter->setFrequency(f, 300.0f); pd->sound->effect->twopolefilter->setFrequencyModulator(f, v);
                pd->sound->channel->addEffect(ch, (SoundEffect*)f);
                pd->sound->synth->setWaveform(s, kWaveformSawtooth);
                break;
            }
            }
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
