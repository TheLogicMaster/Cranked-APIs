// Part 2 of audout (the cases before the Simulator's stream gap): default channel, volume 0.5
// with pan 0.4, four loud notes at once, and a synth with unequal volumes (a stereo channel) panned -0.5.
// Part 1: the final output mix (compared through the Simulator's SDL disk driver file, after its volume
// slider is raised). Six notes at fixed audio times, each on its own channel: 0 default channel, 1 pan modulated by a
// sine LFO, 2 volume by a sine LFO, 3 pan by a square LFO, 4 volume 0.5 and pan 0.4, 5 four loud notes at once.
#include "pd_api.h"
static PlaydateAPI* pd;
static int update(void* ud) { return 1; }
static PDSynth* note(SoundChannel* ch, float freq, float vel, float when) {
    PDSynth* s = pd->sound->synth->newSynth();
    pd->sound->synth->setWaveform(s, kWaveformSine);
    if (ch) pd->sound->channel->addSource(ch, (SoundSource*)s);
    uint32_t t = (uint32_t)((when + 6.0f) * 44100); // after the Simulator's dialogs and volume slider are dealt with
    pd->sound->synth->playNote(s, freq, vel, 0.4f, t);
    return s;
}
static PDSynthLFO* lfo(LFOType t, float rate, float depth, float center) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(t);
    pd->sound->lfo->setRate(l, rate); pd->sound->lfo->setDepth(l, depth); pd->sound->lfo->setCenter(l, center);
    return l;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch[6];
        for (int k = 1; k < 6; k++) { ch[k] = pd->sound->channel->newChannel(); pd->sound->addChannel(ch[k]); }
        note(NULL, 330, 0.5f, 1.0f);
        pd->sound->channel->setVolume(ch[4], 0.5f); pd->sound->channel->setPan(ch[4], 0.4f); note(ch[4], 330, 0.5f, 1.6f);
        for (int k = 0; k < 4; k++) note(ch[5], 330 + 110 * k, 1.0f, 2.2f);
        PDSynth* st = note(ch[1], 330, 0.5f, 2.8f); pd->sound->synth->setVolume(st, 0.9f, 0.3f); pd->sound->channel->setPan(ch[1], -0.5f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
