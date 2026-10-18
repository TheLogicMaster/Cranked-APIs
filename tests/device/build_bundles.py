#!/usr/bin/env python3
"""Builds the probes that cannot run inside the probe suite as bundles of their own, for a Playdate (see README.md).

Usage: build_bundles.py --sdk <PlaydateSDK folder> --out <folder> [--probes name ...] [--list] [--no-c]

By default these are the C probes (a src/ folder and a Makefile, built with `make device`, which needs the ARM
toolchain the SDK's C documentation describes) and the Lua probes listed in excluded.txt. Each bundle gets the
bundle ID org.crankedapis.b.<name>, so that every probe has a data folder of its own on the device:
Data/org.crankedapis.b.<name>/. The files assets.txt lists are added as for the suite. The bundles are written to
<out>/<name>.pdx, and <out>/bundles.txt lists them.

The repository's probe folders are not changed: each probe is copied to a temporary folder and built there.
"""
import argparse, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_suite  # noqa: E402  (assets, excluded, write_png)

PROBES = build_suite.PROBES


def c_probes():
    return [n for n in sorted(os.listdir(PROBES))
            if os.path.isdir(os.path.join(PROBES, n, 'src')) and os.path.isfile(os.path.join(PROBES, n, 'Makefile'))]


def set_bundle_id(source, name):
    path = os.path.join(source, 'pdxinfo')
    lines = open(path, encoding='utf-8').read().splitlines() if os.path.exists(path) else []
    lines = [l for l in lines if not re.match(r'\s*(bundleID|name)\s*=', l)]
    lines += [f'name=Probe {name}', f'bundleID=org.crankedapis.b.{name}']
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')


def add_assets(sdk, source, extra):
    for dest, src in extra or []:
        path = os.path.join(source, dest)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if src == 'png':
            build_suite.write_png(path)
        else:
            if not os.path.exists(os.path.join(sdk, src)):
                raise RuntimeError(f'missing {src} in the SDK folder')
            shutil.copy(os.path.join(sdk, src), path)


def build(sdk, name, out, tmp, extra):
    copy = os.path.join(tmp, name)
    shutil.copytree(os.path.join(PROBES, name), copy, ignore=shutil.ignore_patterns('expected', 'build', '*.pdx'))
    source = os.path.join(copy, 'Source')
    set_bundle_id(source, name)
    add_assets(sdk, source, extra)
    product = os.path.join(out, name + '.pdx')
    if os.path.exists(product):
        shutil.rmtree(product)
    env = dict(os.environ, PLAYDATE_SDK_PATH=sdk)
    if os.path.isdir(os.path.join(copy, 'src')):
        cmd = ['make', '-C', copy, 'device', f'PRODUCT={product}']
    else:
        cmd = [os.path.join(sdk, 'bin', 'pdc'), '-q', '-sdkpath', sdk, source, product]
    r = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError((r.stderr.strip() or r.stdout.strip()).splitlines()[-1])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--sdk', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--probes', nargs='*')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--no-c', action='store_true', help='leave out the C probes')
    a = ap.parse_args()

    names = a.probes or ([] if a.no_c else c_probes()) + sorted(build_suite.excluded())
    if a.list:
        for n in names:
            print(n)
        print(f'{len(names)} probes', file=sys.stderr)
        return
    os.makedirs(a.out, exist_ok=True)
    a.out = os.path.abspath(a.out)
    extra = build_suite.assets()
    built, failed = [], []
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            try:
                build(a.sdk, name, a.out, tmp, extra.get(name))
                built.append(name)
            except (RuntimeError, OSError) as e:
                failed.append((name, str(e)))
    with open(os.path.join(a.out, 'bundles.txt'), 'w') as f:
        for n in built:
            f.write(f'{n} org.crankedapis.b.{n}\n')
    print(f'{a.out}: {len(built)} bundles')
    for name, err in failed:
        print(f'not built: {name}: {err}', file=sys.stderr)


if __name__ == '__main__':
    main()
