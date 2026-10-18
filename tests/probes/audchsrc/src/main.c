// A channel's output as a source (channel->getOutputAsSource). Five channels, added in order A..E,
// each with a capture effect: A a 440 Hz note at volume 0.3; B only A's output source; C a 660 Hz note, then E's
// output source; D E's output source, then an 880 Hz note; E a 330 Hz note, later than A's. The captures show where
// the copy is taken (before the channel volume), whether a later channel's copy is one block old, and whether the
// copy adds to or replaces what the channel's other sources mixed.
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 5
#define PER (44100 * 2)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static void note(SoundChannel* ch, float freq, float when) {
    PDSynth* s = pd->sound->synth->newSynth();
    pd->sound->synth->setWaveform(s, kWaveformSine);
    pd->sound->channel->addSource(ch, (SoundSource*)s);
    pd->sound->synth->playNote(s, freq, 0.5f, 0.3f, (uint32_t)(when * 44100));
}
static int update(void* ud) {
    if (++frames == 90 && !written) {
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
        SoundChannel* ch[N];
        for (int k = 0; k < N; k++) {
            ch[k] = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch[k]);
            pd->sound->channel->addEffect(ch[k], pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k));
        }
        note(ch[0], 440, 0.25f); pd->sound->channel->setVolume(ch[0], 0.3f);
        pd->sound->channel->addSource(ch[1], pd->sound->channel->getOutputAsSource(ch[0]));
        note(ch[2], 660, 0.6f);
        pd->sound->channel->addSource(ch[2], pd->sound->channel->getOutputAsSource(ch[4]));
        pd->sound->channel->addSource(ch[3], pd->sound->channel->getOutputAsSource(ch[4]));
        note(ch[3], 880, 0.6f);
        note(ch[4], 330, 0.75f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
