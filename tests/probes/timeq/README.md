# timeq

The wall-clock time functions: getSecondsSinceEpoch, getTime, getGMTTime, timeFromEpoch, GMTTimeFromEpoch, epochFromTime, epochFromGMTTime and getTimeZoneOffset, plus conversions of fixed times.

Language: Lua. Build: `pdc Source timeq.pdx`.

Notes:

- The current-time lines (secs, getTime, getGMTTime, timeFromEpoch, GMTTimeFromEpoch, epochFromTime, epochFromGMTTime) are the time of the run, so expected/sim.txt shows them as placeholders such as `<year>` and `<n>`; only their form is compared. The g0, e2024 and t2024 lines are fixed times and are compared exactly; t0 (`timeFromEpoch(0, 0)`, in local time) matches only with the time zone set to UTC, and `offset` is nil because the Lua API has no `playdate.getTimeZoneOffset`.
