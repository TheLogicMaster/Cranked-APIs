#!/bin/bash
# Run the probe in the Simulator (SDL disk audio driver, under xvfb-run) and copy its capture file.
# Usage: simrun.sh <pdx> <out.raw>  (needs PLAYDATE_SDK_PATH; SIMSECS sets the run time, default 25)
P=$(realpath "$1"); SDK=${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}; TMP=$(mktemp -d); rm -rf "$SDK/Disk/Data/org.crankedapis.audsw"
(cd $SDK && SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=$TMP/simdisk.raw timeout ${SIMSECS:-25} xvfb-run -a ./bin/PlaydateSimulator "$P" > $TMP/simrun.log 2>&1)
cp $SDK/Disk/Data/org.crankedapis.audsw/capture.raw "$2"; rm -rf "$TMP"
