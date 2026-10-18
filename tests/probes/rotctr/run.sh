#!/bin/bash
# Run the probe in an emulator and compare its pixels with the Simulator's (expected/expected.raw: all 7 frames; the
# 1e30 case is blank and must finish quickly). Usage: run.sh <rotctr.pdx> <runner binary>
# (the runner interface is described in tests/README.md)
D=$(cd "$(dirname "$0")" && pwd); PDX=$(realpath "$1"); BIN=${2:?usage: run.sh <rotctr.pdx> <runner binary>}; W=$(mktemp -d)
cd $W && timeout 300 $BIN $PDX 3 > run.log 2>&1
cmp -s appData/org.crankedapis.rotctr/out.raw $D/expected/expected.raw && grep -q done appData/org.crankedapis.rotctr/out.txt && echo "rotctr: pass" || echo "rotctr: FAIL"
