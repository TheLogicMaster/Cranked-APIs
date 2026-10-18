// Delay lines (length 3000) after a short note: no feedback, feedback 0.5 and 0.9, mix 0.5, a stereo
// line, and a tap with the line's mix at 0. One channel and capture each.
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 6
#define MAXF (44100 * 9)
static int32_t cap[N][MAXF / N];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < MAXF / N; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) for (int k = 0; k < N; k++) pd->sound->synth->playNote(syn[k], 330.0f, 0.8f, 0.03f, 0);
    if (frames == 5 + 30 * 6 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)(MAXF / N) * 4);
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
            syn[k] = pd->sound->synth->newSynth();
            pd->sound->synth->setWaveform(syn[k], kWaveformSine);
            pd->sound->channel->addSource(ch, (SoundSource*)syn[k]);
            DelayLine* d = pd->sound->effect->delayline->newDelayLine(3000, k == 4);
            if (k == 1 || k == 4) pd->sound->effect->delayline->setFeedback(d, 0.5f);
            if (k == 2) pd->sound->effect->delayline->setFeedback(d, 0.9f);
            if (k == 3) { pd->sound->effect->delayline->setFeedback(d, 0.5f); pd->sound->effect->setMix((SoundEffect*)d, 0.5f); }
            if (k == 5) {
                pd->sound->effect->delayline->setFeedback(d, 0.6f); pd->sound->effect->setMix((SoundEffect*)d, 0.0f);
                DelayLineTap* tap = pd->sound->effect->delayline->addTap(d, 1000);
                pd->sound->channel->addSource(ch, (SoundSource*)tap);
            }
            pd->sound->channel->addEffect(ch, (SoundEffect*)d);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
