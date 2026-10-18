// LFO behavior beyond single fresh notes: running phase across notes, retrigger and start phase,
// delay and ramp, arpeggios, a shared LFO, a global LFO. All notes scheduled on the audio clock.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 11)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
#define S 13230 /* 0.3 s */
static PDSynth* mk(void) { PDSynth* s = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(s, kWaveformSine); pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)s); return s; }
static PDSynth *a, *b, *c, *d, *e1, *e2, *f, *g;
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        // 1: no retrigger, three notes: the phase keeps running between notes
        for (int i = 0; i < 3; i++) pd->sound->synth->playNote(a, 440.0f, 0.5f, 0.2f, t + i * S);
        t += 3 * S + 2205;
        // 2: retrigger with start phase 0.25
        for (int i = 0; i < 3; i++) pd->sound->synth->playNote(b, 440.0f, 0.5f, 0.2f, t + i * S);
        t += 3 * S + 2205;
        // 3: delay 0.1 s, ramp 0.15 s, two notes
        for (int i = 0; i < 2; i++) pd->sound->synth->playNote(c, 440.0f, 0.5f, 0.5f, t + i * 26460);
        t += 2 * 26460 + 2205;
        // 4: arpeggio
        pd->sound->synth->playNote(d, 440.0f, 0.5f, 0.8f, t);
        t += 35280 + 2205;
        // 5: one LFO shared by two synths, notes at once and offset
        pd->sound->synth->playNote(e1, 440.0f, 0.5f, 0.5f, t);
        pd->sound->synth->playNote(e2, 330.0f, 0.5f, 0.5f, t + 4000);
        t += 26460 + 2205;
        // 6: global LFO on amplitude, two notes
        for (int i = 0; i < 2; i++) pd->sound->synth->playNote(f, 440.0f, 0.5f, 0.3f, t + i * 17640);
        t += 2 * 17640 + 2205;
        // 7: amplitude LFO with delay and ramp, no retrigger, three notes
        for (int i = 0; i < 3; i++) pd->sound->synth->playNote(g, 440.0f, 0.5f, 0.25f, t + i * S);
    }
    if (frames == 5 + 30 * 10 && !written) {
        written = 1;
        SDFile* fl = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(fl, cap, captured * 4);
        pd->file->close(fl);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        PDSynthLFO* l;
        a = mk(); l = pd->sound->lfo->newLFO(kLFOTypeTriangle); pd->sound->lfo->setRate(l, 3.3f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->synth->setFrequencyModulator(a, (PDSynthSignalValue*)l);
        b = mk(); l = pd->sound->lfo->newLFO(kLFOTypeTriangle); pd->sound->lfo->setRate(l, 3.3f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->lfo->setRetrigger(l, 1); pd->sound->lfo->setStartPhase(l, 0.25f); pd->sound->synth->setFrequencyModulator(b, (PDSynthSignalValue*)l);
        c = mk(); l = pd->sound->lfo->newLFO(kLFOTypeSine); pd->sound->lfo->setRate(l, 4.0f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->lfo->setDelay(l, 0.1f, 0.15f); pd->sound->synth->setFrequencyModulator(c, (PDSynthSignalValue*)l);
        d = mk(); l = pd->sound->lfo->newLFO(kLFOTypeSquare); { float steps[4] = { 0, 4, 7, 12 }; pd->sound->lfo->setArpeggiation(l, 4, steps); } pd->sound->lfo->setRate(l, 2.5f); pd->sound->synth->setFrequencyModulator(d, (PDSynthSignalValue*)l);
        e1 = mk(); e2 = mk(); l = pd->sound->lfo->newLFO(kLFOTypeSine); pd->sound->lfo->setRate(l, 3.0f); pd->sound->lfo->setDepth(l, 0.4f); pd->sound->synth->setFrequencyModulator(e1, (PDSynthSignalValue*)l); pd->sound->synth->setFrequencyModulator(e2, (PDSynthSignalValue*)l);
        f = mk(); l = pd->sound->lfo->newLFO(kLFOTypeSawtoothUp); pd->sound->lfo->setRate(l, 2.0f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setGlobal(l, 1); pd->sound->synth->setAmplitudeModulator(f, (PDSynthSignalValue*)l);
        g = mk(); l = pd->sound->lfo->newLFO(kLFOTypeSquare); pd->sound->lfo->setRate(l, 6.0f); pd->sound->lfo->setDepth(l, 0.5f); pd->sound->lfo->setCenter(l, 0.5f); pd->sound->lfo->setDelay(l, 0.05f, 0.1f); pd->sound->synth->setAmplitudeModulator(g, (PDSynthSignalValue*)l);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
