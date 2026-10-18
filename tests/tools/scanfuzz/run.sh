#!/bin/bash
# Differential scanf fuzzing of parseString (see gen.py). Usage: run.sh <count> <seed...>
# RUNNERS (required): space-separated runner commands ("+" for spaces inside one)
# Each seed regenerates probe/cases.inc (and rebuilds the probe and ref in probe/).
cd "$(dirname "$0")/probe" || exit 1
N=$1; shift
RUNNERS=${RUNNERS:?set RUNNERS to the emulator runner command(s), space-separated}
: ${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}
W=$(mktemp -d)
for seed in "$@"; do
  python3 ../gen.py $seed $N > cases.inc
  make device > make.log 2>&1 || { echo "seed $seed: build failed"; tail -5 make.log; continue; }
  gcc -w -o ref ref.c && ./ref > ref.txt
  P=$PWD/scanfuzz.pdx
  for r in $RUNNERS; do
    rm -rf $W/appData
    (cd $W && RUNNER_VIRTUAL_CLOCK=1 timeout 300 ${r//+/ } $P 1 > so.txt 2> se.txt; grep -E "^scan" so.txt; grep exception se.txt) > $W/out.txt
    d=$(diff $W/out.txt ref.txt | grep -c '^[<>]')
    echo "seed $seed $(basename ${r##*+}): $d differing lines"
    [ $d -gt 0 ] && diff $W/out.txt ref.txt | head -8
  done
done
