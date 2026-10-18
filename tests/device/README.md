# Probe suite for a Playdate

The probes in `../probes/` each build into a bundle of their own. Running 250 of them on a Playdate one at a time
means 250 installs, launches and copies, so this folder packs the Lua probes into one bundle, ProbeSuite.pdx, that
runs them in turn and leaves every probe's output in its data folder. `compare.py` then compares that folder with the
probes' expected output (recorded in the SDK 3.1.1 Simulator), or with another run of the suite.

| File | What it is |
| --- | --- |
| `build_suite.py` | builds ProbeSuite.pdx and manifest.json |
| `runner/main.lua` | the suite's main program, which runs the probes |
| `compare.py` | compares a run's data folder with `expected/`, or with another run |
| `build_bundles.py` | builds the probes the suite cannot hold (C probes, excluded Lua probes) as bundles of their own |
| `excluded.txt` | probes that cannot run inside the suite, with the reason |
| `variable.txt` | probes whose output depends on time or speed; compare.py reports them as `varies` |
| `assets.txt` | files some probes need that are not in the repository, taken from the SDK folder at build time |

## Building

```
python3 build_suite.py --sdk <PlaydateSDK folder> --out <folder>
```

writes `<folder>/ProbeSuite.pdx` and `<folder>/manifest.json`. The SDK folder supplies `pdc` and the fonts and video
listed in `assets.txt`. `--probes a b c` builds a suite of just those probes, `--list` prints the selection without
building, `--all` ignores `excluded.txt`. `--max-frames` (default 900, 30 seconds) and `--idle-frames` (default 150)
set how long a probe may run; a probe's README can give its own values as `suite_frames=<n>` and
`suite_idle=<n>`.

Included are the Lua probes (a `Source/main.lua` and no `src/`) with a text expected output. C probes need a build
each and are not part of the suite.

## How a probe runs

The runner runs each probe's compiled main.pdz with `playdate.file.run`, in an environment table of its own and in
a coroutine of its own, with CoreLibs already imported. Relative paths the probe gives to file, datastore, image,
font, sound and JSON functions are redirected to `p/<name>/`, so its assets come from `p/<name>/` in the bundle and
its outputs go to `p/<name>/` in the suite's data folder. `print` writes `p/<name>/console.txt`.

A probe ends when it calls `playdate.simulator.exit()` or `playdate.stop()`, when its update raises an error
(written to `p/<name>/error.txt`), after 150 frames (5 seconds) without output once it has written something, or at
its frame limit. The runner then puts back the fields of the playdate tables, resets graphics, display, sprites,
timers, menu items and input handlers, and runs one sprite update of its own, so that the next probe's first sprite
update redraws only what that probe changed.

What differs from running a probe on its own:

- The main chunk runs inside the suite's update, so it cannot yield, and code that checks whether it runs in an
  update sees that it does. CoreLibs is imported before the probe's own imports. Probes that test these are in
  excluded.txt.
- An error raised by a function the runner wraps has the probe's calling line in front, as usual, except when the
  probe calls it as a tail call (`return f(...)`), which has no line to report.
- Files the probe writes are under `p/<name>/`; a probe that lists the data folder sees only its own.

Some probes end by raising an error on purpose or by running past the end of their cases (`geoflt` calls a method
that does not exist, `sprrotq` indexes its removed sprite); their error.txt is part of the result, the same in the
Simulator.

`suite.txt` in the data folder has a line when a probe starts and one when it ends, with how it ended and how many
frames it ran. A run that is interrupted (the battery runs out, the device is reset, a probe crashes the system)
continues where it stopped on the next launch: the probe that was running is run again, and if the run stops in it
a second time it is skipped and logged as `crashed`. Hold B while launching to start again from the first probe.

## Running on a Playdate

1. Build the suite as above.
2. Install `ProbeSuite.pdx`: put the device in data disk mode (`pdutil <serial port> datadisk`, with pdutil from
   the SDK's bin folder, or Settings > System > Reboot to Data Disk), copy the bundle into `Games/` on the disk it
   mounts, and eject it. The Simulator's Device menu (Upload Game to Device) and sideloading from play.date work too.
3. Launch "Probe suite" from the launcher, or `pdutil <serial port> run /Games/ProbeSuite.pdx`. The runner turns off
   auto-lock while it runs. The screen shows the current probe as `index/count name`; the whole suite takes about 20
   minutes, and "Probe suite done" means every probe has run.
4. Back in data disk mode, copy `Data/org.crankedapis.suite/` from the disk.
5. Compare: `python3 compare.py <copied folder>`.

The data folder of a run in the Simulator is `Disk/Data/org.crankedapis.suite/` in the SDK folder. To check that the
runner itself does not change what the probes see, run the suite there and compare with `expected/`; a probe that
matches when run on its own but not in the suite points at the runner, not at the device.

## Probes outside the suite

```
python3 build_bundles.py --sdk <PlaydateSDK folder> --out <folder>
```

builds the C probes (with `make device`, which needs the ARM toolchain from the SDK's C documentation) and the Lua
probes in excluded.txt, each as `<folder>/<name>.pdx` with the bundle ID `org.crankedapis.b.<name>`, so each has a
data folder of its own. Copy them to `Games/` in data disk mode and run each one (from the launcher, or
`pdutil <serial port> run /Games/<name>.pdx`) until it has written its output (its source shows when it is done:
most write their file at once, audio probes after a few seconds of playing). Then copy the device's whole `Data/` folder and
compare with `python3 compare.py --bundles <copied Data folder>`.

Several C probes print their results to the console instead of a file (their expected file is `sim_log.txt`). On a
device that output goes to the serial console; save it as `console.txt` in the probe's data folder before comparing.

## Comparing

```
python3 compare.py <data folder> [--diff] [--json report.json] [--probes name ...]
python3 compare.py <device data folder> --against <Simulator data folder>
```

Each probe's outputs are paired with its `expected/` files by name; when names differ (the expected file is
`sim.txt` and the probe wrote `out.txt`), a single expected file pairs with the single output file, or else with
console.txt. Host addresses (`0x...`) are replaced on both sides, and `<word>` placeholders in an expected line match
any text. A probe's result is `same`, `differs` (with the number of differing lines; `--diff` prints the first),
`missing` or `not run`, followed by how it ended and the first line of its error.txt.

Probes whose output depends on time or on the host (`timeq`, `numtype`, `perfq`, and those noted in their README)
differ between any two runs; a device run is better compared with `--against` a Simulator run of the same suite for
those, and with `expected/` for the rest.
