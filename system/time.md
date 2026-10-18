# Time, dates, and the frame rate

This file covers the clocks a game can read and the date functions: `getCurrentTimeMilliseconds`, the elapsed-time
timer, `getSecondsSinceEpoch`, `getTime` and `getGMTTime`, the epoch conversions in Lua and C, the time zone,
`playdate.wait` and C `delay`, the refresh rate and frame pacing, and `getFPS` and `drawFPS`. The sound clock is in
[../audio/effects.md](../audio/effects.md#the-audio-clock); `getServerTime` is with the network functions in [menu.md](menu.md).
Behaviour is given for the device (3.1.2, by analysis) and the Simulator (SDK 3.1.1); where only one was measured, it
says which.

## The game clock: `getCurrentTimeMilliseconds`

- Lua `playdate.getCurrentTimeMilliseconds()` returns an integer; C `system->getCurrentTimeMilliseconds()` an
  `unsigned int`.
- It counts **all** time while the game runs, between frames as well as inside `update()`: the Simulator read 963 ms
  at frame 30 of a 30 fps game. It also advances within a frame, so a C `delay(20)` or a Lua `wait(30)` is visible in
  it.
- CoreLibs timers, frame timers and animators depend on it. With a correct clock, a 500 ms timer fires at frame 17
  (532 ms) at 30 fps, and a 10-frame frame timer at frame 11. A common mistake is to add up only the time spent inside
  `update()`, which makes every timer run many times too slowly.

How the clock behaves while the device's system menu is open is not known; check on hardware.

## Elapsed time

`playdate.resetElapsedTime()` and `playdate.getElapsedTime()` (C `resetElapsedTime`, `getElapsedTime`): the value is
a float in seconds, and right after a reset it is at least 0 and below 1. (PlayGB busy-waits on `getElapsedTime`, so it
must advance while the game is running code.)

## `getSecondsSinceEpoch`

Returns two integers: the seconds since **2000-01-01 00:00 UTC** (the Playdate epoch, not the Unix epoch) and the
milliseconds within the current second (0 to 999), in Lua and C (`getSecondsSinceEpoch(&ms)`). (`tests/probes/timeq`)

## `getTime` and `getGMTTime`

Return the current local or UTC time as a table with `year`, `month`, `day`, `weekday`, `hour`, `minute`, `second`
and `millisecond`.

- `weekday` runs from 1 (Monday) to 7 (Sunday).
- `millisecond` is within the current second, not since midnight.

C `getTimezoneOffset()` returns the offset in seconds (within a day either way). `shouldDisplay24HourTime()` is false
in the Simulator (a boolean in Lua, 0 in C).

## Epoch conversions

These convert between seconds since 2000-01-01 and date tables:

- date to epoch: Lua `playdate.epochFromTime(t)` (local) and `epochFromGMTTime(t)` (UTC), C
  `convertDateTimeToEpoch`;
- epoch to date: Lua `timeFromEpoch(seconds, ms)` (local) and `GMTTimeFromEpoch(seconds, ms)` (UTC), C
  `convertEpochToDateTime`.

The rules below are those of the device (3.1.2, by analysis), and the Simulator gives the same results on every measured
case (`tests/probes/epochq`, edge cases of both directions).

### Date to epoch

    days = (year - 2000) * 365 + 1 + floor((year - 2001) / 4)     -- 0 for the year 2000
         + days before the month (counting February 29 in a leap year)
         + day - 1
    seconds = days * 86400 + hour * 3600 + minute * 60 + second    -- in 32-bit arithmetic

- **Leap years:** every fourth year (`year % 4 == 0`), with no century rule, so 2100 is a leap year.
- **Years before 2000** give 0.
- **Months:** a month outside 2 to 12 adds no days before it, so month 0 and month 13 both count as January.
- **No normalizing:** hours, minutes and seconds are added as given, so hour 25 lands on the next day.
- **Wrapping:** the result wraps at 32 bits, so a date in 2100 gives a negative number in Lua.
- **Lua table fields** are read as integers: 0 when missing or not an integer, and a numeric string such as `"3"`
  reads as 3. The year is stored in 16 bits and the other fields in 8 bits, so out-of-range values are cut to those
  sizes.
- **Lua results:** two values, the epoch and the table's milliseconds, unchanged (0 for a date before 2000).
  `epochFromGMTTime({ year = 2000, month = 1, day = 1, hour = 0, minute = 0, second = 0 })` is `0, 0`, and
  `epochFromTime({ year = 2024, month = 3, day = 4, hour = 5, minute = 6, second = 7, millisecond = 8 })` is
  762843967 when the time zone is UTC.
- **Lua errors:** a value that is not a table raises `"Time table required."`. A table with a number key raises
  `"invalid key to 'next'"`.

### Epoch to date

- **Truncating division:** days and the time of day use truncating division, and the fields are 8-bit unsigned,
  so -1 is 2000-1-1 0:0:255 and -86401 is 1999-1-0.
- **The year** is `days / 365.25 + 2000`, computed in single precision; the month and day follow from the rest.
- **The weekday** is 1 (Monday) to 7 (Sunday). Epoch 0 (Saturday 2000-01-01) has weekday 6; 2001-01-01 01:01:01
  (epoch 86400 * 366 + 3661) has weekday 1; `GMTTimeFromEpoch(86400 * 365, 0)` is Sunday 2000-12-31, weekday 7.
- **Lua arguments:** both are required integers. A missing one is `"bad argument #2 ... number expected"`, and a float
  without an integer value (100.5) is an argument error too.
- **Milliseconds** are a 16-bit field, so -20 reads back as 65516.
- **Local time** adds the time zone offset, unless that would make the time negative.

### Large integers

Playdate Lua numbers are 32-bit integers and single-precision floats (see [../lua/runtime.md](../lua/runtime.md)).
Integer arguments must reach native functions exactly: `timeFromEpoch(762843967, 0)` is 05:06:07. A common mistake is
to read every argument as a float, which rounds integers above 2^24 and gives 05:06:08 here. The same applies to
seeds, sizes and IDs.

## `playdate.wait` and `delay`

- `playdate.wait(ms)` inside `playdate.update()` blocks: when it returns, the clock has advanced by about that much.
  *Inside Playdate* says it suspends the update callbacks instead.
- Called outside `playdate.update()`, it raises `"playdate.wait() can only be called from playdate.update()"`.
- C `system->delay(ms)` blocks, and `getCurrentTimeMilliseconds` shows the time passing.
- An emulator should bound a single wait, so a huge argument cannot stop it for good.

## Refresh rate and frame pacing

- `playdate.display.getRefreshRate()` returns a float (30.0 by default); C `display->getRefreshRate()` likewise.
- `setRefreshRate` limits the rate to 50: 60 and 1e9 read back as 50. A negative rate sets the default, 30. Zero (as
  fast as possible), fractions and NaN are kept. Treat NaN like 0 when pacing. (`tests/probes/rrq`)
- **Pacing:** a game at rate r gets an update every 1 / r seconds. Frames start on a fixed schedule; the schedule
  restarts after a frame that ran a whole period late. A common mistake is to wait a full truncated period (33 ms at
  30 fps) after each frame has started, which runs games a few percent slow (about 29.4 fps at 30).

## `getFPS` and `drawFPS`

- **The rate,** on the device (3.1.2, by analysis): 1,000 divided by the mean of the last 30 frame durations, in whole
  milliseconds, rounded, and at most 99. Lua `playdate.getFPS()` returns an integer; C `display->getFPS()` a float.
- **`drawFPS(x, y)`,** on the device (3.1.2, by analysis): fills a white 15 by 12 box at (x, y) in screen coordinates,
  then draws the rate as two digits in black at (x + 1, y + 1), in a small built-in digit font (6 by 10 cells, 7-pixel
  advance), with a space in place of the tens digit below 10. It does not use the current font.
  In the Simulator (SDK 3.1.1) the glyphs and the box are the same (measured pixel for pixel), but the digits are
  spaced by width: a blank tens digit advances 4 pixels and a 1 advances 5, so single-digit rates draw their digit at
  x + 5 and 10 to 19 draw the ones digit at x + 6 (from 20 up the layout matches). The Simulator also clips the box
  to the clip rect and the screen clip rect, which the analysis of the device does not show. Check on hardware.

Because the rate depends on the host's speed, screens that show the counter (playmon, 1_bit_fantasy) cannot be
compared pixel for pixel; test harnesses replace `drawFPS` with a no-op and fix `getFPS` at 30.

## Repeatable runs

For tests, an emulator can run on a virtual clock that moves only when the test advances it; if the frame schedule,
the game clock, `getElapsedTime`, `getSecondsSinceEpoch`, `getTime`, button times and the fps samples all read it,
two runs of a game give the same frames. Lua's string hash seed comes from the time at start-up, on the device (3.1.2,
by analysis) too, and `math.random`'s initial state differs from run to run in the Simulator, so a repeatable run also
fixes those.
