// Sample player rate modulators other than LFOs. One channel and capture each:
// 0 control signal (1, ramp to 1.3, 0.8), 1 envelope never triggered, value offset 0.8 (a constant 0.8),
// 2 control signal with scale 0.5 and offset 0.6 (0 to 2 play at once), 3 square LFO (center 1, depth 0.2, rate 3)
// played at frame 5 (its LFO is stepped from the start: compare by absolute time)
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 4
#define PER (44100 * 4)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static SamplePlayer* sp[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) pd->sound->sampleplayer->play(sp[3], 1, 1.0f); // the LFO has run since the start
    if (frames == 5 + 30 * 4 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
        pd->file->close(f);
    }
    return 1;
}
static ControlSignal* ramp(void) {
    ControlSignal* c = pd->sound->controlsignal->newSignal();
    pd->sound->controlsignal->addEvent(c, 0, 1.0f, 0);
    pd->sound->controlsignal->addEvent(c, 4, 1.0f, 1);
    pd->sound->controlsignal->addEvent(c, 12, 1.3f, 0);
    pd->sound->controlsignal->addEvent(c, 20, 0.8f, 0);
    return c;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        AudioSample* s = pd->sound->sample->load("assets/m44");
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            sp[k] = pd->sound->sampleplayer->newPlayer();
            pd->sound->sampleplayer->setSample(sp[k], s);
            PDSynthSignalValue* m = NULL;
            if (k == 0) m = (PDSynthSignalValue*)ramp();
            if (k == 1) {
                PDSynthEnvelope* e = pd->sound->envelope->newEnvelope(0.1f, 0.1f, 0.5f, 0.1f);
                pd->sound->signal->setValueOffset((PDSynthSignal*)e, 0.8f);
                m = (PDSynthSignalValue*)e;
            }
            if (k == 2) {
                ControlSignal* c = ramp();
                pd->sound->signal->setValueScale((PDSynthSignal*)c, 0.5f);
                pd->sound->signal->setValueOffset((PDSynthSignal*)c, 0.6f);
                m = (PDSynthSignalValue*)c;
            }
            if (k == 3) {
                PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSquare);
                pd->sound->lfo->setRate(l, 3.0f); pd->sound->lfo->setDepth(l, 0.2f); pd->sound->lfo->setCenter(l, 1.0f);
                m = (PDSynthSignalValue*)l;
            }
            pd->sound->sampleplayer->setRateModulator(sp[k], m);
            pd->sound->channel->addSource(ch, (SoundSource*)sp[k]);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
            if (k < 3) pd->sound->sampleplayer->play(sp[k], 1, 1.0f);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
