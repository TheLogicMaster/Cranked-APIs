// Capture the mixed audio of the main channel through a custom effect.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 4)
static int16_t capL[MAXF], capR[MAXF];
static int captured = 0, frames = 0, written = 0, calls = 0, nonzero = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    calls++;
    for (int i = 0; i < n && captured < MAXF; i++, captured++) {
        int32_t l = (bufactive && left) ? left[i] : 0, r = (bufactive && right) ? right[i] : l;
        capL[captured] = (int16_t)(l >> 8); capR[captured] = (int16_t)(r >> 8);   // samples are 8.24 fixed point
        if (l || r) nonzero++;
    }
    return bufactive;
}
static PDSynth* sq; static SamplePlayer* sp;
static int update(void* ud) {
    frames++;
    if (frames == 10 && sp) pd->sound->sampleplayer->play(sp, 1, 1.0f);
    if (frames == 40) pd->sound->synth->playNote(sq, 440.0f, 0.5f, 0.3f, 0);
    if (frames == 80 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int i = 0; i < captured; i++) { pd->file->write(f, &capL[i], 2); pd->file->write(f, &capR[i], 2); }
        pd->file->close(f);
        SDFile* g = pd->file->open("capture.txt", kFileWrite);
        char* s; pd->system->formatString(&s, "frames=%d calls=%d nonzero=%d sample=%d\n", captured, calls, nonzero, sp != NULL);
        pd->file->write(g, s, (unsigned)__builtin_strlen(s)); pd->file->close(g);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        sq = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(sq, kWaveformSquare);
        AudioSample* smp = pd->sound->sample->load("assets/beep");
        sp = smp ? pd->sound->sampleplayer->newPlayer() : NULL;
        if (sp) pd->sound->sampleplayer->setSample(sp, smp);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
