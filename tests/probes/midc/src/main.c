// sample-based synth playback steps (how playback steps depend on the note frequency): a 44100 Hz sawtooth
// sample (60 ramps of 1000 frames) played at chosen frequencies, velocity 1, one synth per note, notes 1.5 s apart;
// the int32 output reveals the playback position
#include "pd_api.h"
static PlaydateAPI* pd;
#define MAXF (44100 * 36)
static int32_t cap[MAXF];
static int captured = 0, frames = 0, written = 0;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    for (int i = 0; i < n && captured < MAXF; i++, captured++) cap[captured] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static int16_t ramp[60000];
static const float freq[] = { 264.5378112792969f, 243.3757781982422f, 281.9992370605469f, 254.46978759765625f, 257.1205139160156f, 224.56504821777344f, 210.3372344970703f, 257.22430419921875f, 232.9603729248047f, 258.2423095703125f, 241.99049377441406f, 236.60914611816406f, 265.2962951660156f, 212.51690673828125f, 280.2307434082031f, 222.2855224609375f, 207.41099548339844f, 284.87750244140625f, 241.32379150390625f, 256.73724365234375f, 261.6256f, 440.0f };
#define N (int)(sizeof freq / sizeof freq[0])
static PDSynth* syn[64];
static int update(void* ud) {
    frames++;
    if (frames == 5) {
        uint32_t t = pd->sound->getCurrentTime() + 4410;
        for (int i = 0; i < N; i++) pd->sound->synth->playNote(syn[i], freq[i], 1.0f, 1.6f, t + i * 66150);
    }
    if (frames == 5 + 30 * 35 && !written) {
        written = 1;
        SDFile* f = pd->file->open("capture.raw", kFileWrite); pd->file->write(f, cap, captured * 4); pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        pd->sound->channel->addEffect(pd->sound->getDefaultChannel(), pd->sound->effect->newEffect(captureProc, NULL));
        for (int i = 0; i < 60000; i++) ramp[i] = (int16_t)((i % 1000) * 60 - 30000);
        AudioSample* a = pd->sound->sample->newSampleFromData((uint8_t*)ramp, kSound16bitMono, 44100, sizeof ramp, 0);
        for (int i = 0; i < N; i++) {
            syn[i] = pd->sound->synth->newSynth(); pd->sound->synth->setSample(syn[i], a, 0, 0);
            pd->sound->channel->addSource(pd->sound->getDefaultChannel(), (SoundSource*)syn[i]);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
