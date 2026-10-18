// Sample-based synths (setSample): pitch, sustain loops, release, the 2756 Hz cap, formats, volume.
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 12)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int16_t m16[6615], s16[2 * 8820]; static int8_t m8[3300];
static uint32_t lcg = 12345; static int rnd(void) { lcg = lcg * 1103515245u + 12345u; return (int)(lcg >> 16) & 0x7fff; }
#define N 9
static PDSynth* syn[N];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        static const float freq[N] = { 440, 261.6256f, 2000, 3500, 330, 523.25f, 440, 600, 261.6256f };
        static const float vel[N] = { 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 1.0f, 0.5f, 1.0f };
        static const float len[N] = { 2.0f, 0.6f, 0.4f, 0.4f, 0.5f, 0.5f, 0.4f, 0.7f, 0.3f };
        for (int i = 0; i < N; i++) pd->sound->synth->playNote(syn[i], freq[i], vel[i], len[i], t + i * 44100);
    }
    if (frames == 5 + 30 * 11 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        pd->file->write(f, cap, captured * 4); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        SoundEffect* fx = pd->sound->effect->newEffect(captureProc, NULL);
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), fx);
        for (int i = 0; i < 6615; i++) m16[i] = (int16_t)((i * 37 % 200 - 100) * 120 + rnd() % 2000 - 1000);
        for (int i = 0; i < 8820; i++) { s16[2 * i] = (int16_t)((i * 53 % 300 - 150) * 90); s16[2 * i + 1] = (int16_t)(rnd() % 16000 - 8000); }
        for (int i = 0; i < 3300; i++) m8[i] = (int8_t)(i * 11 % 120 - 60 + rnd() % 20 - 10);
        AudioSample* a = pd->sound->sample->newSampleFromData((uint8_t*)m16, kSound16bitMono, 22050, sizeof m16, 0);
        AudioSample* b = pd->sound->sample->newSampleFromData((uint8_t*)s16, kSound16bitStereo, 44100, sizeof s16, 0);
        AudioSample* c = pd->sound->sample->newSampleFromData((uint8_t*)m8, kSound8bitMono, 11025, sizeof m8, 0);
        for (int i = 0; i < N; i++) { syn[i] = pd->sound->synth->newSynth(); pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]); }
        pd->sound->synth->setSample(syn[0], a, 0, 0);          // no loop: plays to the end
        pd->sound->synth->setSample(syn[1], a, 1000, 5000);    // sustain loop, middle C
        pd->sound->synth->setSample(syn[2], a, 1000, 5000);    // 2000 Hz
        pd->sound->synth->setSample(syn[3], a, 1000, 5000);    // 3500 Hz (capped at 2756)
        pd->sound->synth->setSample(syn[4], b, 2000, 0);       // stereo, loop from 2000 to the end
        pd->sound->synth->setSample(syn[5], c, 500, 2500);     // 8-bit
        pd->sound->synth->setSample(syn[6], a, 1000, 5000);    // velocity 1: unity volume path
        pd->sound->synth->setSample(syn[7], a, 1000, 5000);    // envelope ramps
        pd->sound->synth->setAttackTime(syn[7], 0.05f); pd->sound->synth->setDecayTime(syn[7], 0.1f); pd->sound->synth->setSustainLevel(syn[7], 0.6f); pd->sound->synth->setReleaseTime(syn[7], 0.15f);
        pd->sound->synth->setSample(syn[8], a, 0, 9999);        // end beyond the sample, unity
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
