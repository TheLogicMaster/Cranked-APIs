#!/bin/bash
# Turn the Simulator's crank to set angles (through its crank field, with synthetic X input from xinput.py) and log
# getCrankChange's two values. Coordinates fit the Simulator window at its default place on a 1280x800 Xvfb screen.
# Usage: run.sh <crankacc.pdx> <out.txt>  (needs PLAYDATE_SDK_PATH)
SDK=${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}; D=$(cd "$(dirname "$0")" && pwd); PDX=$(realpath "$1"); OUT=$2
export DISPLAY=${DISPLAY:-:97}; pgrep -f "Xvfb $DISPLAY" > /dev/null || { Xvfb $DISPLAY -screen 0 1280x800x24 > /dev/null 2>&1 & sleep 1; }
rm -rf $SDK/Disk/Data/org.crankedapis.crankacc
(cd $SDK && timeout 90 ./bin/PlaydateSimulator "$PDX" > /dev/null 2>&1 &)
sleep 6
args="click:639,448 sleep:0.5 click:658,559 sleep:0.5" # dismiss the notice, undock the crank
for a in 5 25 70 115 160 210 300 330 355; do args="$args tripleclick:758,559 type:$a key:Return sleep:0.5"; done
python3 $D/xinput.py $args; sleep 2
cp $SDK/Disk/Data/org.crankedapis.crankacc/log.txt "$OUT"; cat "$OUT"
