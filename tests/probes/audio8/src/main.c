// Block sizes, an unadded delay tap, and noise register continuity.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 6)
static int16_t cap[MAXF];
static int blockSizes[64]; static int nBlocks = 0;
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int active) {
    if (nBlocks < 64) blockSizes[nBlocks++] = n;
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (int16_t)(((active && left) ? left[i] : 0) >> 8);
    return active;
}
static SamplePlayer* sp; static PDSynth* n1; static PDSynth* n2; static SoundChannel* ch; static SoundEffect* fx; static DelayLine* dl;
static int update(void* ud) {
    frames++;
    if (frames == 15) { pd->sound->channel->removeEffect(ch, fx); pd->sound->channel->addEffect(ch, (SoundEffect*)dl); pd->sound->channel->addEffect(ch, fx);
                        pd->sound->sampleplayer->play(sp, 1, 1.0f); }  // tap made but never added to a channel
    if (frames == 40) { pd->sound->channel->removeEffect(ch, (SoundEffect*)dl); pd->sound->synth->playNote(n1, 440.0f, 0.5f, 0.2f, 0); }
    if (frames == 60) pd->sound->synth->playNote(n1, 440.0f, 0.5f, 0.2f, 0);
    if (frames == 80) pd->sound->synth->playNote(n2, 440.0f, 0.5f, 0.2f, 0);
    if (frames == 110 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, (unsigned)(captured * 2)); pd->file->close(f);
        SDFile* g = pd->file->open("blocks.txt", kFileWrite);
        for (int i = 0; i < nBlocks; i++) { char* s; int len = pd->system->formatString(&s, "%d ", blockSizes[i]); pd->file->write(g, s, (unsigned)len); }
        pd->file->close(g);
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
        dl = pd->sound->effect->delayline->newDelayLine(4410, 0); pd->sound->effect->setMix((SoundEffect*)dl, 0.0f);
        pd->sound->effect->delayline->addTap(dl, 1000);
        n1 = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(n1, kWaveformNoise);
        n2 = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(n2, kWaveformNoise);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
