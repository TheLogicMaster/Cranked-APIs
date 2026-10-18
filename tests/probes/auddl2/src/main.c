// Delay line taps with delay modulators. A sine synth note (1.5 s) into a delay line of 8000 frames
// at mix 0 with a tap at 2000 frames; one channel and capture each: 0 square LFO (rate 2, depth 0.01 s),
// 1 sine LFO (rate 1, depth 0.005 s), 2 control signal (0, then 0.01 s at step 8, 0.02 s at step 16),
// 3 triangle LFO (rate 4, depth 0.002 s), 4 no modulator, the tap's delay set to 3000 after 150 blocks (from the
// capture effect, so at the same block in both)
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 5
#define PER (44100 * 4)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static DelayLineTap* tap4;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    if (k == 4 && captured[k] == 256 * 150) pd->sound->effect->delayline->setTapDelay(tap4, 3000);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5 + 30 * 4 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
        pd->file->close(f);
    }
    return 1;
}
static PDSynthLFO* lfo(LFOType t, float rate, float depth) {
    PDSynthLFO* l = pd->sound->lfo->newLFO(t);
    pd->sound->lfo->setRate(l, rate); pd->sound->lfo->setDepth(l, depth); pd->sound->lfo->setCenter(l, 0);
    return l;
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
            DelayLine* d = pd->sound->effect->delayline->newDelayLine(8000, 0);
            pd->sound->effect->setMix((SoundEffect*)d, 0.0f);
            DelayLineTap* tap = pd->sound->effect->delayline->addTap(d, 2000);
            PDSynthSignalValue* m = NULL;
            if (k == 4) tap4 = tap;
            else if (k == 0) m = (PDSynthSignalValue*)lfo(kLFOTypeSquare, 2, 0.01f);
            else if (k == 1) m = (PDSynthSignalValue*)lfo(kLFOTypeSine, 1, 0.005f);
            else if (k == 3) m = (PDSynthSignalValue*)lfo(kLFOTypeTriangle, 4, 0.002f);
            else {
                ControlSignal* c = pd->sound->controlsignal->newSignal();
                pd->sound->controlsignal->addEvent(c, 0, 0.0f, 0);
                pd->sound->controlsignal->addEvent(c, 8, 0.01f, 0);
                pd->sound->controlsignal->addEvent(c, 16, 0.02f, 0);
                m = (PDSynthSignalValue*)c;
            }
            if (m) pd->sound->effect->delayline->setTapDelayModulator(tap, m);
            pd->sound->channel->addSource(ch, (SoundSource*)tap);
            pd->sound->channel->addEffect(ch, (SoundEffect*)d);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
            pd->sound->synth->playNote(syn[k], 330.0f, 0.8f, 1.5f, 0); // at once: the LFOs run from the start
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
