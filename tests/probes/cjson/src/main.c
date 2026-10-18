// Probe: the C API JSON decoder (callback sequence, paths, values, errors, skipping, returnString)
#include "pd_api.h"
#include <string.h>
static PlaydateAPI* pd;
static char out[200000]; static int outLen = 0;
static void put(const char* s) { int n = (int)strlen(s); if (outLen + n < (int)sizeof(out)) { memcpy(out + outLen, s, n); outLen += n; } }
static void putf(const char* fmt, ...) { char* s; va_list ap; va_start(ap, fmt); pd->system->vaFormatString(&s, fmt, ap); va_end(ap); put(s); pd->system->realloc(s, 0); }
static void val(json_value v) {
    switch (v.type) {
        case kJSONNull: put("null"); break; case kJSONTrue: put("true"); break; case kJSONFalse: put("false"); break;
        case kJSONInteger: putf("i%d", v.data.intval); break;
        case kJSONFloat: { union { float f; uint32_t u; } c; c.f = v.data.floatval; putf("f%08x", c.u); break; }
        case kJSONString: { put("s\""); for (const unsigned char* p = (const unsigned char*)v.data.stringval; *p; p++) { if (*p < 32 || *p > 126 || *p == '"') putf("\\x%02x", *p); else { char b[2] = { (char)*p, 0 }; put(b); } } put("\""); break; }
        case kJSONArray: case kJSONTable: putf("%s(%d)", v.type == kJSONArray ? "A" : "T", (int)(intptr_t)v.data.tableval); break;
        default: putf("?%d", v.type);
    }
}
static int mode = 0, listCount = 0;
static void cbError(json_decoder* d, const char* e, int line) { putf(" ERR[%s@%d path=%s]", e, line, d->path ? d->path : "NULL"); }
static void cbWill(json_decoder* d, const char* name, json_value_type t) {
    putf(" will(%s,%d,p=%s)", name, t, d->path ? d->path : "NULL");
    if (mode == 2 && strcmp(name, "raw") == 0) d->returnString = 1;
}
static int cbShouldKey(json_decoder* d, const char* key) { putf(" sk(%s,p=%s)", key, d->path ? d->path : "NULL"); return mode == 1 ? strcmp(key, "skip") != 0 : 1; }
static void cbDidKey(json_decoder* d, const char* key, json_value v) { putf(" dk(%s,p=%s)=", key, d->path ? d->path : "NULL"); val(v); }
static int cbShouldIdx(json_decoder* d, int pos) { putf(" si(%d,p=%s)", pos, d->path ? d->path : "NULL"); return mode == 1 ? pos != 2 : 1; }
static void cbDidIdx(json_decoder* d, int pos, json_value v) { putf(" di(%d,p=%s)=", pos, d->path ? d->path : "NULL"); val(v); }
static void* cbDidList(json_decoder* d, const char* name, json_value_type t) { putf(" did(%s,%d)", name, t); return (void*)(intptr_t)(++listCount); }
static const char* inputs[] = {
    "[1,2,3]", "{\"a\":1,\"b\":[true,false,null],\"c\":{\"d\":\"e\"}}", "[]", "{}", "12", "12 ", "\"s\" ", "[1.5,0.1,-0.0,1e3,1E-2,2.5e+3]",
    "[01,-,9999999999,21e8,3e9,1e]", "[\"\\u0041\\u00e9\\u20ac\\ud83d\\ude00\"]", "[\"\\q\"]", "[\"abc", "[1,]", "{\"a\":1,}", "{\"a\" 1}", "{a:1}",
    "[True]", "[1] 2", "", "  ", "{\"a\":1", "[[1,[2]],[3],[4,[5,[6]]]]", "[0,1,2,3,4,5,6,7,8,9,10,11,12,[13]]", "{\"x\":{\"y\":{\"z\":[1,{\"w\":2}]}}}",
    "{\"skip\":{\"a\":[1,2]},\"keep\":[1,2,3,4]}", "{\"raw\":{\"a\":[1, \"]\" ,2]},\"after\":1}", "{\"raw\":[ 1, [2], '[' ]}", "[\n1,\n2,\nx]", "{\"\":[1]}", "{\"\":{\"x\":1}}",
    "[\"a\\nb\\t\\\\\\/\\\"\"]", "{\"a\":1,\"a\":2}", "[1 2]", "[-1.5e2, 123456.789, 0.123456789123]",
};
static int update(void* ud) { return 0; }
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg) {
    if (event == kEventInit) {
        pd = playdate;
        for (int m = 0; m < 3; m++) {
            for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); i++) {
                mode = m; listCount = 0;
                json_decoder d = { cbError, cbWill, cbShouldKey, cbDidKey, cbShouldIdx, cbDidIdx, cbDidList, NULL, 0, NULL };
                json_value v = { 0 };
                putf("m%d:%u\t", m, i);
                int r = pd->json->decodeString(&d, inputs[i], &v);
                putf(" => %d ", r); if (r) val(v); put("\n");
            }
        }
        // no callbacks at all
        for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); i++) {
            json_decoder d = { cbError, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL };
            json_value v = { 0 };
            putf("bare:%u\t", i); int r = pd->json->decodeString(&d, inputs[i], &v); putf(" => %d ", r); if (r) val(v); put("\n");
        }
        SDFile* f = pd->file->open("out.txt", kFileWrite);
        pd->file->write(f, out, outLen); pd->file->close(f);
        pd->system->setUpdateCallback(update, NULL);
    }
    return 0;
}
