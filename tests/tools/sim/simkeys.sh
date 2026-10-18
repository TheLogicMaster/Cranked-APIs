#!/bin/bash
# Run a pdx in the Simulator under Xvfb and replay an actions file through xdotool (one command per line:
# "sleep <s>", "key <keysym>" (press and release), "down <keysym>", "up <keysym>", "wheel <4|5>" (crank by the
# mouse wheel)). The game's data folder is cleared first. The Simulator's output goes to sim_input.log and a
# screenshot to sim_screen.png, both in the current folder.
# Usage: simkeys.sh <pdx> <bundleid> <actions-file> <seconds>   (needs PLAYDATE_SDK_PATH, Xvfb, xdotool,
# matchbox-window-manager, xwd and ImageMagick)
SDK=${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}
PDX=$(realpath "$1")
BID=${2:?usage: simkeys.sh <pdx> <bundleID> <actions> <seconds>}
LOG=$PWD/sim_input.log
export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 > /dev/null 2>&1 &
XPID=$!
sleep 1; matchbox-window-manager -use_titlebar no > /dev/null 2>&1 &
WMPID=$!
sleep 1
rm -rf "$SDK/Disk/Data/$BID"
(cd "$SDK" && ./bin/PlaydateSimulator "$PDX" > "$LOG" 2>&1) &
SPID=$!
sleep 5
WIN=$(xdotool search --onlyvisible --class "PlaydateSimulator" 2>/dev/null | head -1)
[ -z "$WIN" ] && WIN=$(xdotool search --onlyvisible --name "Playdate" 2>/dev/null | head -1)
echo "window: $WIN $(xdotool getwindowname $WIN 2>/dev/null)"
xdotool windowfocus --sync $WIN 2>/dev/null; xdotool mousemove --window $WIN 200 300 click 1; sleep 0.5
while read -r cmd arg; do
  case "$cmd" in
    sleep) sleep "$arg" ;;
    down) xdotool keydown "$arg" ;;
    up) xdotool keyup "$arg" ;;
    key) xdotool keydown "$arg"; sleep 0.3; xdotool keyup "$arg" ;;
    wheel) xdotool mousemove --window $WIN 200 200 click "$arg" ;;
  esac
done < "$3"
sleep "$4"
xwd -root -silent | convert xwd:- sim_screen.png 2>/dev/null
kill $SPID 2>/dev/null; sleep 1; kill -9 $SPID 2>/dev/null; pkill -x PlaydateSimulat 2>/dev/null; kill $WMPID $XPID 2>/dev/null
