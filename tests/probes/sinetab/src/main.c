// (1) ring modulator on a constant 2^30 input at a phase step of 1 (every 16-bit phase),
// (2) sine LFO values by getValue at phases 0..65535 step 16 (rate 0), (3) sample-and-hold LFO values (seed).
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (65536 * 2 + 4096)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int setter(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n; i++) { left[i] = 1 << 30; if (right) right[i] = 1 << 30; }
    return 1;
}
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = left[i];
    return bufactive;
}
#define NL 64
static PDSynthLFO* lfo[NL];
static float lval[4096];
#define NSH 4
static PDSynthLFO* sh[NSH];
#define SHF 240
static float shval[NSH][SHF];
static PDSynth* syn;
static int update(void* ud) {
    int F = frames++;
    if (F >= 3 && F < 3 + 64 * 3) {
        int b = (F - 3) / 3, r = (F - 3) % 3;
        if (r == 0) for (int j = 0; j < NL; j++) pd->sound->lfo->setPhase(lfo[j], (float)((b * NL + j) * 16) / 65536.0f);
        if (r == 2) for (int j = 0; j < NL; j++) lval[b * NL + j] = pd->sound->lfo->getValue(lfo[j]);
    }
    if (F >= 1 && F < 1 + SHF) for (int k = 0; k < NSH; k++) shval[k][F - 1] = pd->sound->lfo->getValue(sh[k]);
    if (F == 260 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, captured * 4); pd->file->close(f);
        f = pd->file->open("lfo.bin", kFileWrite); pd->file->write(f, lval, sizeof lval); pd->file->close(f);
        f = pd->file->open("sh.bin", kFileWrite); pd->file->write(f, shval, sizeof shval); pd->file->close(f);
        f = pd->file->open("done.txt", kFileWrite); pd->file->write(f, "done\n", 5); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundChannel* ch = pd->sound->channel->newChannel();
        pd->sound->addChannel(ch);
        pd->sound->channel->addEffect(ch, pd->sound->effect->newEffect(setter, NULL));
        RingModulator* rm = pd->sound->effect->ringmodulator->newRingmod();
        pd->sound->effect->ringmodulator->setFrequency(rm, 0.67291259765625f); // 44100 / 65536: phase step 1
        pd->sound->channel->addEffect(ch, (SoundEffect*)rm);
        pd->sound->channel->addEffect(ch, pd->sound->effect->newEffect(captureProc, NULL));
        syn = pd->sound->synth->newSynth(); pd->sound->synth->setWaveform(syn, kWaveformSine);
        pd->sound->channel->addSource(ch, (SoundSource*)syn);
        pd->sound->synth->playNote(syn, 440.0f, 1.0f, 30.0f, 0);
        for (int j = 0; j < NL; j++) {
            lfo[j] = pd->sound->lfo->newLFO(kLFOTypeSine);
            pd->sound->lfo->setRate(lfo[j], 0.0f); pd->sound->lfo->setDepth(lfo[j], 1.0f); pd->sound->lfo->setCenter(lfo[j], 0.0f);
            pd->sound->lfo->setGlobal(lfo[j], 1);
        }
        static const float rates[NSH] = { 5.0f, 5.0f, 5.0f, 7.5f };
        for (int k = 0; k < NSH; k++) {
            sh[k] = pd->sound->lfo->newLFO(kLFOTypeSampleAndHold);
            pd->sound->lfo->setRate(sh[k], rates[k]); pd->sound->lfo->setDepth(sh[k], 1.0f); pd->sound->lfo->setCenter(sh[k], 0.0f);
            if (k == 1) pd->sound->lfo->setRandomSeed(sh[k], 0);
            if (k == 2) pd->sound->lfo->setRandomSeed(sh[k], 0x1234);
            pd->sound->lfo->setGlobal(sh[k], 1);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
