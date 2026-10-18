#!/usr/bin/env python3
"""Builds the probe suite: one bundle that runs many Lua probes in turn on a Playdate (see README.md).

Usage: build_suite.py --sdk <PlaydateSDK folder> --out <folder> [--probes name ...] [--all] [--list]

Each probe's Source/ is compiled with the SDK's pdc on its own, and its compiled files are copied into the suite
bundle under p/<name>/. The runner (runner/main.lua) is compiled as the suite's main program, and manifest.json lists
the probes in order with their frame limits. The suite is written to <out>/ProbeSuite.pdx, and a copy of the manifest
to <out>/manifest.json for compare.py.

Without --probes, the suite holds every Lua probe that has a text expected output and is not listed in
excluded.txt (probes that cannot run inside the suite, with the reason). Files a probe needs that the repository
does not include are taken from the SDK folder as assets.txt lists. --all ignores excluded.txt; --list prints
the selection and stops.
"""
import argparse, json, os, shutil, struct, subprocess, sys, tempfile, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
PROBES = os.path.normpath(os.path.join(HERE, '..', 'probes'))


def excluded():
    out = {}
    path = os.path.join(HERE, 'excluded.txt')
    for line in open(path, encoding='utf-8') if os.path.exists(path) else []:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        name, _, reason = line.partition(' ')
        out[name] = reason.strip()
    return out


def assets():
    """assets.txt: {probe: [(file under Source/, source)]}."""
    out = {}
    for line in open(os.path.join(HERE, 'assets.txt'), encoding='utf-8'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        name, dest, source = line.split(None, 2)
        out.setdefault(name, []).append((dest, source))
    return out


def write_png(path):
    """An 8x8 1-bit PNG with a checkerboard."""
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    rows = b''.join(b'\x00' + bytes([0xaa if y % 2 else 0x55]) for y in range(8))
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 8, 8, 1, 0, 0, 0, 0)) +
                chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


def probe_source(sdk, name, tmp, extra):
    """The folder to compile for a probe: its Source/, or a copy of it with the files from assets.txt added."""
    src = os.path.join(PROBES, name, 'Source')
    if not extra:
        return src
    copy = os.path.join(tmp, name + '-src')
    shutil.copytree(src, copy)
    for dest, source in extra:
        path = os.path.join(copy, dest)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if source == 'png':
            write_png(path)
        else:
            if not os.path.exists(os.path.join(sdk, source)):
                raise RuntimeError(f'missing {source} in the SDK folder')
            shutil.copy(os.path.join(sdk, source), path)
    return copy


def eligible():
    names = []
    for name in sorted(os.listdir(PROBES)):
        d = os.path.join(PROBES, name)
        if not os.path.isfile(os.path.join(d, 'Source', 'main.lua')):
            continue
        if os.path.isdir(os.path.join(d, 'src')):  # C or C + Lua probes need their own build
            continue
        exp = os.path.join(d, 'expected')
        if os.path.isdir(exp) and any(f.endswith(('.txt', '.json')) for f in os.listdir(exp)):
            names.append(name)
    return names


def readme_setting(name, key):
    """A probe's suite setting: <key>=<n> in its README (suite_frames, the frame limit; suite_idle, the frames
    without output that end it), else None."""
    readme = os.path.join(PROBES, name, 'README.md')
    if os.path.exists(readme):
        for line in open(readme, encoding='utf-8'):
            if key + '=' in line:
                return int(line.split(key + '=')[1].split()[0].strip('`.,;'))
    return None


def pdc(sdk, src, dst):
    env = dict(os.environ, PLAYDATE_SDK_PATH=sdk)
    r = subprocess.run([os.path.join(sdk, 'bin', 'pdc'), '-q', '-sdkpath', sdk, src, dst], env=env,
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or r.stdout.strip())


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--sdk', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--probes', nargs='*')
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--max-frames', type=int, default=900, help='default frame limit per probe (30 a second)')
    ap.add_argument('--idle-frames', type=int, default=150, help='frames without output that end a probe')
    a = ap.parse_args()

    skip = {} if a.all else excluded()
    names = a.probes if a.probes else [n for n in eligible() if n not in skip]
    if a.list:
        for n in names:
            print(n)
        print(f'{len(names)} probes; {len(skip)} excluded', file=sys.stderr)
        return

    os.makedirs(a.out, exist_ok=True)
    suite = os.path.join(a.out, 'ProbeSuite.pdx')
    if os.path.exists(suite):
        shutil.rmtree(suite)
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, 'runner')
        shutil.copytree(os.path.join(HERE, 'runner'), src)
        with open(os.path.join(src, 'pdxinfo'), 'w') as f:
            f.write('name=Probe suite\nauthor=Cranked APIs probes\nbundleID=org.crankedapis.suite\n'
                    'version=1.0\nbuildNumber=1\n')
        pdc(a.sdk, src, suite)
        manifest = {'maxFrames': a.max_frames, 'idleFrames': a.idle_frames, 'probes': []}
        failed = []
        extra = assets()
        for name in names:
            out = os.path.join(tmp, name + '.pdx')
            try:
                pdc(a.sdk, probe_source(a.sdk, name, tmp, extra.get(name)), out)
            except RuntimeError as e:
                failed.append((name, str(e)))
                continue
            dest = os.path.join(suite, 'p', name)
            shutil.copytree(out, dest)  # with its pdxinfo, which some probes list or read
            entry = {'name': name}
            for key, field in (('suite_frames', 'frames'), ('suite_idle', 'idle')):
                if readme_setting(name, key):
                    entry[field] = readme_setting(name, key)
            manifest['probes'].append(entry)
        with open(os.path.join(suite, 'manifest.json'), 'w') as f:
            json.dump(manifest, f, indent=1)
        shutil.copy(os.path.join(suite, 'manifest.json'), os.path.join(a.out, 'manifest.json'))
    print(f'{suite}: {len(manifest["probes"])} probes')
    for name, err in failed:
        print(f'not built: {name}: {err}', file=sys.stderr)


if __name__ == '__main__':
    main()
