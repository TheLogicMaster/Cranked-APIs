// MP3 file players (decoders differ, so samples differ slightly).
// One channel and capture each: 0 128 kb/s mono, 1 VBR stereo, 2 64 kb/s 22.05 kHz with an ID3v2 tag, played twice.
// Logs getLength, and getOffset and isPlaying every 10 frames.
#include <string.h>
#include "pd_api.h"
static PlaydateAPI* pd;
#define N 3
#define PER (44100 * 8)
static int32_t cap[N][PER];
static int captured[N], frames = 0, written = 0;
static SDFile* logFile;
static int captureProc(SoundEffect* e, int32_t* left, int32_t* right, int n, int bufactive) {
    int k = (int)(intptr_t)pd->sound->effect->getUserdata(e);
    for (int i = 0; i < n && captured[k] < PER; i++, captured[k]++) cap[k][captured[k]] = (bufactive && left) ? left[i] : 0;
    return bufactive;
}
static FilePlayer* fp[N];
static void logLine(const char* fmt, double a, double b) {
    char* line; pd->system->formatString(&line, fmt, a, b);
    pd->file->write(logFile, line, (unsigned)strlen(line)); pd->system->realloc(line, 0);
}
static int update(void* ud) {
    frames++;
    if (frames % 10 == 0 && frames <= 240) {
        logLine("f%.0f", frames, 0);
        for (int k = 0; k < N; k++) logLine(" %.4f/%.0f", pd->sound->fileplayer->getOffset(fp[k]), pd->sound->fileplayer->isPlaying(fp[k]));
        logLine("\n", 0, 0);
    }
    if (frames == 5 + 30 * 8 && !written) {
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
        static const char* files[N] = {"assets/cbr", "assets/vbr.mp3", "assets/tag"};
        for (int k = 0; k < N; k++) {
            SoundChannel* ch = pd->sound->channel->newChannel();
            pd->sound->addChannel(ch);
            fp[k] = pd->sound->fileplayer->newPlayer();
            int ok = pd->sound->fileplayer->loadIntoPlayer(fp[k], files[k]);
            logLine("load %.0f length %.4f\n", ok, pd->sound->fileplayer->getLength(fp[k]));
            pd->sound->channel->addSource(ch, (SoundSource*)fp[k]);
            SoundEffect* c = pd->sound->effect->newEffect(captureProc, (void*)(intptr_t)k);
            pd->sound->channel->addEffect(ch, c);
            pd->sound->fileplayer->play(fp[k], k == 2 ? 2 : 1);
        }
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
