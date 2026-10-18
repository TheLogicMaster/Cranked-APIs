// Impulse responses of the remaining two-pole types, a ring modulator on a sine, and a delay tap.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 7)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SamplePlayer* sp; static PDSynth* syn; static SoundChannel* ch; static SoundEffect* fx; static SoundEffect* effects[7];
static DelayLine* dl; static DelayLineTap* tap;
static void use(int k) {
    for (int i = 0; i < 7; i++) if (effects[i]) pd->sound->channel->removeEffect(ch, effects[i]);
    pd->sound->channel->removeEffect(ch, fx);
    if (effects[k]) pd->sound->channel->addEffect(ch, effects[k]);
    pd->sound->channel->addEffect(ch, fx);
}
static int update(void* ud) {
    frames++;
    for (int k = 0; k < 5; k++) if (frames == 15 + 20 * k) { use(k); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 115) { use(5); pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 140) { use(6); pd->sound->channel->addSource(ch, (SoundSource*)tap); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 175 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        ch = pd->sound->getDefaultChannel();
        fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, fx);
        AudioSample* s = pd->sound->sample->load("assets/impulse");
        sp = pd->sound->sampleplayer->newPlayer(); pd->sound->sampleplayer->setSample(sp, s);
        syn = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn, kWaveformSine);
        static const TwoPoleFilterType types[5] = { kFilterTypeBandPass, kFilterTypeNotch, kFilterTypePEQ, kFilterTypeLowShelf, kFilterTypeHighShelf };
        for (int k = 0; k < 5; k++) {
            TwoPoleFilter* f = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(f, types[k]);
            pd->sound->effect->twopolefilter->setFrequency(f, 1000.0f); pd->sound->effect->twopolefilter->setResonance(f, 0.5f);
            pd->sound->effect->twopolefilter->setGain(f, 6.0f);
            effects[k] = (SoundEffect*)f;
        }
        RingModulator* rm = pd->sound->effect->ringmodulator->newRingmod(); pd->sound->effect->ringmodulator->setFrequency(rm, 100.0f);
        effects[5] = (SoundEffect*)rm;
        dl = pd->sound->effect->delayline->newDelayLine(4410, 0); pd->sound->effect->setMix((SoundEffect*)dl, 0.0f);
        tap = pd->sound->effect->delayline->addTap(dl, 1000);
        effects[6] = (SoundEffect*)dl;
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
