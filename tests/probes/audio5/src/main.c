// Measure memoryless effects (overdrive, bitcrusher) on a sine, captured after the effect.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 6)
static int16_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static PDSynth* syn; static SoundChannel* ch; static Overdrive* od; static BitCrusher* bc; static SoundEffect* fx;
static int update(void* ud) {
    frames++;
    if (frames == 15) { pd->sound->channel->addEffect(ch, (SoundEffect*)od); pd->sound->channel->removeEffect(ch, fx); pd->sound->channel->addEffect(ch, fx);
                        pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 45) { pd->sound->channel->removeEffect(ch, (SoundEffect*)od); pd->sound->channel->removeEffect(ch, fx);
                        pd->sound->channel->addEffect(ch, (SoundEffect*)bc); pd->sound->channel->addEffect(ch, fx);
                        pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 75) { pd->sound->effect->bitcrusher->setAmount(bc, 0.0f); pd->sound->effect->bitcrusher->setUndersampling(bc, 0.5f);
                        pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 110 && !written) {
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
        syn = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn, kWaveformSine);
        od = pd->sound->effect->overdrive->newOverdrive(); pd->sound->effect->overdrive->setGain(od, 2.0f); pd->sound->effect->overdrive->setLimit(od, 0.5f);
        bc = pd->sound->effect->bitcrusher->newBitCrusher(); pd->sound->effect->bitcrusher->setAmount(bc, 0.5f); pd->sound->effect->bitcrusher->setUndersampling(bc, 0.0f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
