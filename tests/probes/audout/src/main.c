// The final output mix (compared through the Simulator's SDL disk driver file, after its volume
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
        pd->sound->channel->setPanModulator(ch[1], (PDSynthSignalValue*)lfo(kLFOTypeSine, 5, 0.8f, 0.0f)); note(ch[1], 330, 0.5f, 1.6f);
        pd->sound->channel->setVolumeModulator(ch[2], (PDSynthSignalValue*)lfo(kLFOTypeSine, 7, 0.4f, 0.5f)); note(ch[2], 330, 0.5f, 2.2f);
        pd->sound->channel->setPanModulator(ch[3], (PDSynthSignalValue*)lfo(kLFOTypeSquare, 6, 0.6f, 0.1f)); note(ch[3], 330, 0.5f, 2.8f);
        pd->sound->channel->setVolume(ch[4], 0.5f); pd->sound->channel->setPan(ch[4], 0.4f); note(ch[4], 330, 0.5f, 3.4f);
        for (int k = 0; k < 4; k++) note(ch[5], 330 + 110 * k, 1.0f, 4.0f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
