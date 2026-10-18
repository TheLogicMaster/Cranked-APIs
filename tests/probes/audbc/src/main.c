// Bitcrusher settings from SDK 3.1 on a sine note (0.5 s, 330 Hz, decaying envelope). One channel and
// capture each: 0 depth 0.5, 1 depth 0.9 exponential, 2 downsampling 0.5, 3 amount 0.4 exponential,
// 4 depth 0.3 + amount 0.2 + undersampling 0.3, 5 depth modulated by a sine LFO (depth 0.4), 6 setAmount(2) (clamped)
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 7
#define PER (44100 * 1)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int update(void* ud) {
    frames++;
    if (frames == 45 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
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
            PDSynth* s = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(s, kWaveformSine);
            pd->sound->synth->setAttackTime(s, 0.01f); pd->sound->synth->setDecayTime(s, 0.4f); pd->sound->synth->setSustainLevel(s, 0.05f);
            pd->sound->channel->addSource(ch, (SoundSource*)s);
            BitCrusher* b = pd->sound->effect->bitcrusher->newBitCrusher();
            const struct playdate_sound_effect_bitcrusher* bc = pd->sound->effect->bitcrusher;
            if (k == 0) bc->setDepth(b, 0.5f);
            if (k == 1) { bc->setDepth(b, 0.9f); bc->setExponential(b, 1); }
            if (k == 2) bc->setDownsampling(b, 0.5f);
            if (k == 3) { bc->setAmount(b, 0.4f); bc->setExponential(b, 1); }
            if (k == 4) { bc->setDepth(b, 0.3f); bc->setAmount(b, 0.2f); bc->setUndersampling(b, 0.3f); }
            if (k == 5) {
                PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSine);
                pd->sound->lfo->setRate(l, 3.0f); pd->sound->lfo->setDepth(l, 0.4f); pd->sound->lfo->setCenter(l, 0.0f);
                bc->setDepth(b, 0.5f); bc->setDepthModulator(b, (PDSynthSignalValue*)l);
            }
            if (k == 6) bc->setAmount(b, 2.0f);
            pd->sound->channel->addEffect(ch, (SoundEffect*)b);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
            pd->sound->synth->playNote(s, 330.0f, 0.8f, 0.5f, 0);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
