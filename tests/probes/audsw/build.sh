#!/bin/bash
# Build the probe for one waveform. Usage: build.sh <SoundWaveform constant> <out.pdx>  (needs PLAYDATE_SDK_PATH)
cd "$(dirname "$0")" || exit 1
sed -i "s/^static SoundWaveform wave = .*/static SoundWaveform wave = $1;/" src/main.c
rm -rf build; make > build.log 2>&1 && rm -rf "$2" && mv audsw.pdx "$2"
