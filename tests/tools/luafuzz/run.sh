#!/bin/bash
# Run the Lua fuzzer until it finishes. Each crash or hang is recorded in findings.txt with the call
# that caused it, and that function is skipped on the next run. Usage: run.sh <runner binary> [seconds per run]
# FUZZ_CALLS (calls per function, default 12) and FUZZ_SEED (default 1234) vary the run.
D=$(cd "$(dirname "$0")" && pwd); BIN=${1:?usage: run.sh <emulator runner binary> [seconds per run]}; SECS=${2:-300}
: ${PLAYDATE_SDK_PATH:?set PLAYDATE_SDK_PATH}
$PLAYDATE_SDK_PATH/bin/pdc $D/Source $D/luafuzz.pdx > /dev/null || exit 1
mkdir -p $D/run && cd $D/run && rm -rf appData && mkdir -p appData/org.crankedapis.luafuzz
echo "${FUZZ_CALLS:-12} ${FUZZ_SEED:-1234}" > appData/org.crankedapis.luafuzz/config.txt
: > $D/findings.txt
for i in $(seq 1 60); do
  timeout $((SECS + 30)) $BIN $D/luafuzz.pdx $SECS > run.log 2>&1; rc=$?
  grep -h "runtime error\|ERROR: AddressSanitizer\|SUMMARY: AddressSanitizer" run.log | sed "s/^/SANITIZER /" >> $D/findings.txt # under the ASan/UBSan build
  A=appData/org.crankedapis.luafuzz
  if grep -q "^done" $A/fuzz.txt 2>/dev/null; then grep "^done\|^SLOW" $A/fuzz.txt >> $D/findings.txt; echo "finished after $i runs" >> $D/findings.txt; break; fi
  last=$(tail -1 $A/progress.txt); name=${last%% #*}
  kind=$([ $rc -eq 124 ] && echo "HANG" || echo "CRASH rc=$rc")
  echo "$kind $last | $(grep -m1 -E 'ERROR|runtime error|SEGV|exception' run.log | cut -c1-200)" >> $D/findings.txt
  grep "^SLOW" $A/fuzz.txt >> $D/findings.txt
  [ -z "$name" ] && break
  echo "$name" >> $A/skip.txt
done
