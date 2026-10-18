// Measure source volumes and the default channel's volume and pan, capturing left and right.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 6)
static int16_t cap[MAXF * 2];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) {
        int32_t l = (active && left) ? left[i] : 0, r = (active && right) ? right[i] : l;
        cap[captured * 2] = (int16_t)(l >> 8); cap[captured * 2 + 1] = (int16_t)(r >> 8);
    }
    return active;
}
static SamplePlayer* sp; static PDSynth* syn; static SoundChannel* ch;
static int update(void* ud) {
    frames++;
    if (frames == 15) { pd->sound->sampleplayer->setVolume(sp, 0.5f, 0.25f); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 45) { pd->sound->synth->setVolume(syn, 1.0f, 0.0f); pd->sound->synth->playNote(syn, 440.0f, 0.5f, 0.4f, 0); }
    if (frames == 75) { pd->sound->sampleplayer->setVolume(sp, 1.0f, 1.0f); pd->sound->channel->setVolume(ch, 0.5f); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 105) { pd->sound->channel->setVolume(ch, 1.0f); pd->sound->channel->setPan(ch, -1.0f); pd->sound->sampleplayer->play(sp, 1, 1.0f); }
    if (frames == 150 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, (unsigned)(captured * 4)); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        ch = pd->sound->getDefaultChannel();
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(ch, fx);
        AudioSample* s = pd->sound->sample->load("assets/beep");
        sp = pd->sound->sampleplayer->newPlayer(); pd->sound->sampleplayer->setSample(sp, s);
        syn = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn, kWaveformSine);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
