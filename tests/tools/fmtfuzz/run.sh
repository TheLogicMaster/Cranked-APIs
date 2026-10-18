#!/bin/bash
# Differential printf fuzzing. For each seed: random cases (gen.py), the probe built for the device,
# the host reference (snprintf), and the probe run on each runner given; prints the differing lines.
# Each seed regenerates probe/cases.h (and rebuilds the probe and ref in probe/).
# Usage: run.sh <count per seed> <seed...>   (RUNNERS, required: space-separated runner commands, "+" for spaces
# inside one)
cd "$(dirname "$0")/probe" || exit 1
N=$1; shift
RUNNERS=${RUNNERS:?set RUNNERS to the emulator runner command(s), space-separated}
: ${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}
W=$(mktemp -d)
for seed in "$@"; do
  python3 ../gen.py $seed $N > cases.h
  make device > make.log 2>&1 || { echo "seed $seed: build failed"; continue; }
  gcc -w -o ref ref.c && ./ref > ref.txt
  P=$PWD/fmtfuzz.pdx
  for r in $RUNNERS; do
    rm -rf $W/appData
    # stdout and stderr apart: interleaved in one pipe, a line could be split by the runner's last message
    (cd $W && RUNNER_VIRTUAL_CLOCK=1 timeout 300 ${r//+/ } $P 1 > so.txt 2> se.txt; grep -E "^fmt[ql]" so.txt; grep exception se.txt) > $W/out.txt
    d=$(diff $W/out.txt ref.txt | grep -c '^[<>]')
    echo "seed $seed $(basename ${r##*+}): $d differing lines"
    [ $d -gt 0 ] && diff $W/out.txt ref.txt | head -6
  done
done
