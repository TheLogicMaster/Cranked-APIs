// Channel volume and pan, captured after the channel by routing its output into another channel.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 7)
static int16_t cap[MAXF * 2];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) {
        int32_t l = (active && left) ? left[i] : 0, r = (active && right) ? right[i] : l;
        cap[captured * 2] = (int16_t)(l >> 8); cap[captured * 2 + 1] = (int16_t)(r >> 8);
    }
    return active;
}
static PDSynth* syn; static SoundChannel* B;
static const float pans[6] = { -1.0f, -0.5f, 0.0f, 0.5f, 1.0f, 0.0f };
static const float vols[6] = { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.5f };
static int update(void* ud) {
    frames++;
    for (int k = 0; k < 6; k++)
        if (frames == 15 + 25 * k) { pd->sound->channel->setPan(B, pans[k]); pd->sound->channel->setVolume(B, vols[k]); pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 180 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 4)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* A = pd->sound->getDefaultChannel();
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(A, fx);
        B = pd->sound->channel->newChannel();
        pd->sound->addChannel(B);
        syn = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn, kWaveformSine);
        pd->sound->channel->removeSource(A, (SoundSource*)syn);
        pd->sound->channel->addSource(B, (SoundSource*)syn);
        SoundSource* out = pd->sound->channel->getOutputAsSource(B);
        if (out) pd->sound->channel->addSource(A, out);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
