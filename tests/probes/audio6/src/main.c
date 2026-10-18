// Impulse responses of the effects with memory, captured after the effect.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 8)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SamplePlayer* sp; static SoundChannel* ch; static SoundEffect* fx; static SoundEffect* effects[8];
static void use(int k) {
    for (int i = 0; i < 8; i++) pd->sound->channel->removeEffect(ch, effects[i]);
    pd->sound->channel->removeEffect(ch, fx);
    pd->sound->channel->addEffect(ch, effects[k]); pd->sound->channel->addEffect(ch, fx);
}
static int update(void* ud) {
    frames++;
    for (int k = 0; k < 8; k++)
        if (frames == 15 + 20 * k) { use(k); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 190 && !written) {
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
        static const float res[4] = { 0.0f, 0.25f, 0.75f, 0.9f };
        static const float par[4] = { -0.9f, -0.5f, 0.2f, 0.9f };
        for (int k = 0; k < 4; k++) {
            TwoPoleFilter* lp = pd->sound->effect->twopolefilter->newFilter(); pd->sound->effect->twopolefilter->setType(lp, kFilterTypeLowPass);
            pd->sound->effect->twopolefilter->setFrequency(lp, 1000.0f); pd->sound->effect->twopolefilter->setResonance(lp, res[k]);
            effects[k] = (SoundEffect*)lp;
            OnePoleFilter* op = pd->sound->effect->onepolefilter->newFilter(); pd->sound->effect->onepolefilter->setParameter(op, par[k]);
            effects[4 + k] = (SoundEffect*)op;
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
