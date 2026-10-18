#!/bin/bash
# Run the C API fuzzer until it finishes. Each crash, hang or emulator error is recorded in findings.txt
# with the call that caused it, and that function is skipped on the next run. Usage: run.sh <runner> [seconds per run]
# FUZZ_CALLS sets the calls per function (default 12).
D=$(cd "$(dirname "$0")" && pwd); BIN=${1:?usage: run.sh <emulator runner binary> [seconds per run]}; SECS=${2:-60}   # build cfuzz.pdx first: make device
mkdir -p $D/run && cd $D/run && rm -rf appData && mkdir -p appData/org.crankedapis.cfuzz
A=appData/org.crankedapis.cfuzz; echo "${FUZZ_CALLS:-12}" > $A/config.txt
: > $D/findings.txt
for i in $(seq 1 120); do
  timeout $((SECS + 30)) $BIN $D/cfuzz.pdx $SECS > run.log 2>&1; rc=$?
  grep -h "runtime error\|ERROR: AddressSanitizer\|SUMMARY: AddressSanitizer" run.log | sed "s/^/SANITIZER /" >> $D/findings.txt # under the ASan/UBSan build
  if grep -q "^done" $A/result.txt 2>/dev/null; then cat $A/result.txt >> $D/findings.txt; echo "finished after $i runs" >> $D/findings.txt; break; fi
  last=$(tail -1 $A/progress.txt); name=${last%% #*}
  kind=$([ $rc -eq 124 ] && echo "HANG" || echo "STOP rc=$rc")
  echo "$kind $last | $(grep -m1 -iE 'error|exception|SEGV|runtime error' run.log | cut -c1-220)" >> $D/findings.txt
  [ -z "$name" ] && break
  echo "$name" >> $A/skip.txt
done
