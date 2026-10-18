#!/bin/bash
# Run a pdx in the Simulator with SDL's disk audio driver, dismiss the start-up dialogs and raise the volume slider
# (synthetic X input through ../crankacc/xinput.py), and keep the final output mix.
# Usage: simout.sh <pdx> <out.raw> [seconds]. Needs PLAYDATE_SDK_PATH, Xvfb, and the Simulator window at its default
# place on a 1280x800 screen (the click coordinates assume that layout).
SDK=${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}; P=$(realpath "$1"); OUT=$2; secs=${3:-8}
HERE=$(cd "$(dirname "$0")" && pwd); TMP=$(mktemp -d)
export DISPLAY=${DISPLAY:-:97}; pgrep -f "Xvfb $DISPLAY" > /dev/null || { Xvfb $DISPLAY -screen 0 1280x800x24 > /dev/null 2>&1 & sleep 1; }
(cd $SDK && SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=$TMP/simdisk.raw timeout $((secs + 20)) ./bin/PlaydateSimulator "$P" > $TMP/sim_out.log 2>&1 &)
sleep 4
python3 "$HERE/../crankacc/xinput.py" click:639,448 sleep:0.8 click:692,469 sleep:0.5 drag:853,267,853,185 > /dev/null
sleep $secs
pgrep -x PlaydateSimulat | xargs -r kill -9
cp $TMP/simdisk.raw "$OUT"
