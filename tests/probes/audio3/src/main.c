// Capture playback of 8-bit and IMA ADPCM samples (mono and stereo), left and right separately.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 5)
static int16_t cap[MAXF * 2]; // interleaved left, right
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) {
        int32_t l = (active && left) ? left[i] : 0, r = (active && right) ? right[i] : l;
        cap[captured * 2] = (int16_t)(l >> 8); cap[captured * 2 + 1] = (int16_t)(r >> 8);
    }
    return active;
}
static SamplePlayer* players[3];
static int update(void* ud) {
    frames++;
    if (frames == 15 && players[0]) pd->sound->sampleplayer->play(players[0], 1, 1.0f);
    if (frames == 45 && players[1]) pd->sound->sampleplayer->play(players[1], 1, 1.0f);
    if (frames == 75 && players[2]) pd->sound->sampleplayer->play(players[2], 1, 1.0f);
    if (frames == 120 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, (unsigned)(captured * 4)); // one call: writing per sample is very slow under emulation
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        const char* names[3] = { "assets/pcm8", "assets/adpcm_mono", "assets/adpcm_stereo" };
        for (int i = 0; i < 3; i++) {
            AudioSample* s = pd->sound->sample->load(names[i]);
            players[i] = s ? pd->sound->sampleplayer->newPlayer() : NULL;
            if (players[i]) pd->sound->sampleplayer->setSample(players[i], s);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
