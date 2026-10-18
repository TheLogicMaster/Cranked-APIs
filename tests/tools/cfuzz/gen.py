# Generates src/main.c, a C API fuzzer, from the SDK headers.
import re, sys, os
SDK = os.path.join(os.environ['PLAYDATE_SDK_PATH'], 'C_API')  # run from this folder
text = ''
for f in ['pd_api.h'] + ['pd_api/' + x for x in sorted(os.listdir(SDK + '/pd_api'))]:
    text += open(os.path.join(SDK, f)).read() + '\n'
text = re.sub(r'//[^\n]*', '', text); text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
structs = {}
for m in re.finditer(r'struct\s+(\w+)\s*\{(.*?)\};', text, flags=re.S):
    structs[m.group(1)] = m.group(2)
OBJ = set('LCDBitmap LCDBitmapTable LCDFont LCDFontPage LCDFontGlyph LCDTileMap LCDVideoPlayer LCDStreamPlayer FilePlayer LCDSprite SDFile PDMenuItem SoundChannel SoundSource AudioSample SamplePlayer PDSynth PDSynthLFO PDSynthEnvelope PDSynthSignal PDSynthSignalValue ControlSignal SequenceTrack SoundSequence PDSynthInstrument SoundEffect TwoPoleFilter OnePoleFilter BitCrusher RingModulator DelayLine DelayLineTap Overdrive'.split())
SKIP = re.compile(r'^(system\.(realloc|error|setUpdateCallback|vaFormatString|parseString|restartGame|delay|setSerialMessageCallback|setButtonCallback|setLanguage|getServerTime)|file\.(unlink|rename|mkdir|close)|lua\..*|json\..*|network\..*|scoreboards\..*|graphics\.video\..*|graphics\.videostream\..*|sound\.effect\.newEffect|sound\.signal\.newSignal|sound\.source\.setFinishCallback|.*\.free\w*|.*\.release\w*|sprite\.freeSprite|sound\.removeSource|system\.removeAllMenuItems|system\.removeMenuItem|graphics\.popContext|graphics\.pushContext|graphics\.setFont|sound\.setMicCallback|sound\.getHeadphoneState|sound\.synth\.setGenerator.*|sprite\.setUpdateFunction|sprite\.setDrawFunction|sprite\.setCollisionResponseFunction|system\.setMenuItemUserdata|system\.add\w*MenuItem)$')
funcs = []
def walk(sname, path):
    body = structs.get(sname)
    if body is None: return
    for line in body.split(';'):
        line = ' '.join(line.split())
        if not line: continue
        m = re.match(r'(?:const )?struct (\w+)\s*\*\s*(\w+)$', line)
        if m: walk(m.group(1), path + [m.group(2)]); continue
        m = re.match(r'(.+?)\(\s*\*\s*(\w+)\s*\)\s*\((.*)\)$', line)
        if m: funcs.append((path + [m.group(2)], m.group(1).strip(), m.group(3).strip()))
walk('PlaydateAPI', [])
def params(p):
    if p in ('', 'void'): return []
    out, depth, cur = [], 0, ''
    for ch in p:
        if ch == '(' : depth += 1
        if ch == ')' : depth -= 1
        if ch == ',' and depth == 0: out.append(cur.strip()); cur = ''
        else: cur += ch
    out.append(cur.strip()); return out
def ptype(decl):
    if decl == '...': return '...'
    if '(*' in decl.replace(' ', ''): # an inline function pointer: drop the parameter name
        return re.sub(r'\(\s*\*\s*\w*\s*\)', '(*)', decl, count=1)
    m = re.match(r'(.*?)(\w+)\s*\[\s*\d*\s*\]$', decl)
    if m: return m.group(1).strip() + '*' # an array parameter is a pointer
    m = re.match(r'(.*?)(\w+)$', decl)
    t = (m.group(1) if m and m.group(1).strip() else decl).strip()
    return t
def expr(t):
    base = t.replace('const ', '').replace(' ', '')
    if base == '...': return None
    if '(*)' in base: return f'(({t}) pickFn())'
    if re.search(r'Callback|Function|Func$|Func\b|Proc|Handler', base):
        return f'(({t}{"" if base.endswith("*") else "*"}) pickFn())'
    if base.endswith('**'): return f'(({t}) pickBuf())'
    if base.endswith('*'):
        n = base[:-1]
        if n in OBJ: return f'(({t}) pickObj(T_{n}))'
        if n == 'char': return f'(({t}) pickStr())'
        if n in ('PDRect', 'LCDRect', 'CollisionPoint', 'CollisionVector'): return f'(({t}) pickBuf())'
        return f'(({t}) pickBuf())'
    if base == 'LCDColor': return 'pickColor()'
    if base == 'PDRect': return 'pickPDRect()'
    if base == 'LCDRect': return 'pickLCDRect()'
    if base in ('float', 'MIDINote', 'double'): return f'(({t}) pickFloat())'
    return f'(({t}) pickInt())'
objret = {}
lines = []
n = 0
for path, ret, ps in funcs:
    name = '.'.join(path)
    if SKIP.match(name): continue
    pl = [ptype(x) for x in params(ps)]
    args = [expr(t) for t in pl if t != '...']
    if any(a is None for a in args): continue
    call = 'pd->' + '->'.join(path) + '(' + ', '.join(args) + ')'
    rb = ret.replace('const ', '').replace(' ', '')
    if rb.endswith('*') and rb[:-1] in OBJ: body = f'{{ {ret} r = {call}; keepObj(T_{rb[:-1]}, (void *) r); }}'
    elif rb == 'void': body = f'{{ {call}; }}'
    else: body = f'{{ (void) {call}; }}'
    lines.append(f'static void f{n}(void) {body}')
    lines.append(f'static const char *fname{n} = "{name}";')
    n += 1
enum = 'enum { ' + ', '.join('T_' + o for o in sorted(OBJ)) + ', T_COUNT };'
tmpl = open('main_template.c').read()
tmpl = tmpl.replace('/*ENUM*/', enum).replace('/*FUNCS*/', '\n'.join(lines))
tmpl = tmpl.replace('/*TABLE*/', ',\n'.join(f'    {{ f{i}, &fname{i} }}' for i in range(n)))
tmpl = tmpl.replace('/*COUNT*/', str(n))
open('src/main.c', 'w').write(tmpl)
print(n, 'functions')
