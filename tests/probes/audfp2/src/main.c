// File players, part 2. One channel and capture each, plus a log of getOffset:
// 0 square LFO rate modulator (center 1, depth 0.2, rate 3), 1 control signal rate modulator (1, ramp to 1.3, 0.8),
// 2 volume 0 for the first second, then 1, 3 loop range 0.5 to 1.0 s, 3 plays, rate 0.9, 4 22.05k with a 0.1 s buffer,
// 5 stopped at frame 20 and played again at frame 30; stopped at 60, offset 1.0 s, played at 70
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 6
#define PER (44100 * 4)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0, loops = 0, finished = 0;
static SDFile* logFile;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static FilePlayer* fp[N];
static void loopCb(SoundSource* s, void* ud) { loops++; }
static void finishCb(SoundSource* s, void* ud) { finished++; }
static void logLine(const char* fmt, float a, float b) {
    char* line; pd->system->formatString(&line, fmt, (double)a, (double)b);
    pd->file->write(logFile, line, (unsigned)strlen(line)); pd->system->realloc(line, 0);
}
static int update(void* ud) {
    frames++;
    if (frames == 5) for (int k = 0; k < N; k++) pd->sound->fileplayer->play(fp[k], k == 3 ? 3 : 1);
    if (frames == 35) pd->sound->fileplayer->setVolume(fp[2], 1, 1);
    if (frames == 20) pd->sound->fileplayer->stop(fp[5]);
    if (frames == 30) pd->sound->fileplayer->play(fp[5], 1);
    if (frames == 60) pd->sound->fileplayer->stop(fp[5]);
    if (frames == 65) pd->sound->fileplayer->setOffset(fp[5], 1.0f);
    if (frames == 70) pd->sound->fileplayer->play(fp[5], 1);
    if (frames % 5 == 0 && frames <= 120) {
        logLine("f%.0f", (float)frames, 0);
        for (int k = 2; k < N; k++) logLine(" %.6f/%.0f", pd->sound->fileplayer->getOffset(fp[k]), (float)pd->sound->fileplayer->isPlaying(fp[k]));
        logLine(" loops %.0f finished %.0f\n", (float)loops, (float)finished);
    }
    if (frames == 5 + 30 * 4 && !written) {
        written = 1;
        pd->file->close(logFile);
        SDFile* f = pd->file->open("capture.raw", kFileWrite);
        for (int k = 0; k < N; k++) pd->file->write(f, cap[k], (unsigned)PER * 4);
        pd->file->close(f);
    }
    return 1;
}
int eventHandler(PlaydateAPI* p, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = p;
        logFile = pd->file->open("log.txt", kFileWrite);
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            fp[k] = pd->sound->fileplayer->newPlayer();
            pd->sound->fileplayer->loadIntoPlayer(fp[k], k == 4 ? "assets/m22" : "assets/m44");
            if (k == 0) {
                PDSynthLFO* l = pd->sound->lfo->newLFO(kLFOTypeSquare);
                pd->sound->lfo->setRate(l, 3.0f); pd->sound->lfo->setDepth(l, 0.2f); pd->sound->lfo->setCenter(l, 1.0f);
                pd->sound->fileplayer->setRateModulator(fp[k], (PDSynthSignalValue*)l);
            }
            if (k == 1) {
                ControlSignal* c = pd->sound->controlsignal->newSignal();
                pd->sound->controlsignal->addEvent(c, 0, 1.0f, 0);
                pd->sound->controlsignal->addEvent(c, 4, 1.0f, 1);
                pd->sound->controlsignal->addEvent(c, 12, 1.3f, 0);
                pd->sound->controlsignal->addEvent(c, 20, 0.8f, 0);
                pd->sound->fileplayer->setRateModulator(fp[k], (PDSynthSignalValue*)c);
            }
            if (k == 2) pd->sound->fileplayer->setVolume(fp[k], 0, 0);
            if (k == 3) {
                pd->sound->fileplayer->setRate(fp[k], 0.9f);
                pd->sound->fileplayer->setLoopRange(fp[k], 0.5f, 1.0f);
                pd->sound->fileplayer->setLoopCallback(fp[k], loopCb, NULL);
                pd->sound->fileplayer->setFinishCallback(fp[k], finishCb, NULL);
            }
            if (k == 4) pd->sound->fileplayer->setBufferLength(fp[k], 0.1f);
            pd->sound->channel->addSource(ch, (SoundSource*)fp[k]);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
