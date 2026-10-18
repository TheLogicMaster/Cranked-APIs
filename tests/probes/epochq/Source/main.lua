-- Probe: epochFromTime and epochFromGMTTime with unusual dates, and timeFromEpoch edge cases
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function t(y, mo, d, h, mi, s, ms) return { year = y, month = mo, day = d, hour = h, minute = mi, second = s, millisecond = ms } end
local cases = {
  { "normal", t(2024, 5, 17, 13, 45, 30, 250) }, { "y2000", t(2000, 1, 1, 0, 0, 0, 0) }, { "y1999", t(1999, 12, 31, 23, 59, 59, 0) },
  { "y0", t(0, 0, 0, 0, 0, 0, 0) }, { "month0", t(2024, 0, 10, 0, 0, 0, 0) }, { "day0", t(2024, 3, 0, 0, 0, 0, 0) },
  { "month13", t(2024, 13, 1, 0, 0, 0, 0) }, { "y2100mar", t(2100, 3, 1, 0, 0, 0, 0) }, { "y2104mar", t(2104, 3, 1, 0, 0, 0, 0) },
  { "hour25", t(2024, 1, 1, 25, 0, 0, 0) }, { "min75", t(2024, 1, 1, 0, 75, 0, 0) }, { "sec99", t(2024, 1, 1, 0, 0, 99, 1500) },
  { "y2136", t(2136, 3, 1, 0, 0, 0, 0) }, { "y2200", t(2200, 1, 1, 0, 0, 0, 0) }, { "day40", t(2024, 2, 40, 0, 0, 0, 0) },
  { "y2001mar", t(2001, 3, 1, 0, 0, 0, 0) }, { "y2004mar", t(2004, 3, 1, 0, 0, 0, 0) }, { "y2005jan", t(2005, 1, 1, 0, 0, 0, 0) },
}
for _, c in ipairs(cases) do
  local ok1, a1, b1 = pcall(playdate.epochFromGMTTime, c[2])
  fh:write(c[1] .. " gmt " .. tostring(ok1) .. " " .. tostring(a1) .. " " .. tostring(b1) .. "\n")
end
for _, e in ipairs({ 0, 1, 86399, 86400, 4102444800 - 946684800, -1, -86401, 2147483647, 4294967295, 4294967296 }) do
  local ok, r = pcall(playdate.timeFromEpoch, e, 0)
  local g = ok and r and string.format("%d-%d-%d %d:%d:%d wd=%s ms=%s", r.year, r.month, r.day, r.hour, r.minute, r.second, tostring(r.weekday), tostring(r.millisecond)) or tostring(r)
  local ok2, r2 = pcall(playdate.GMTTimeFromEpoch, e, 0)
  local g2 = ok2 and r2 and string.format("%d-%d-%d %d:%d:%d wd=%s", r2.year, r2.month, r2.day, r2.hour, r2.minute, r2.second, tostring(r2.weekday)) or tostring(r2)
  fh:write("fromEpoch " .. e .. " gmt " .. g2 .. "\n")
end
local function show(r) if type(r) ~= "table" then return tostring(r) end return string.format("%d-%d-%d %d:%d:%d wd=%s ms=%s", r.year, r.month, r.day, r.hour, r.minute, r.second, tostring(r.weekday), tostring(r.millisecond)) end
local extra = {
  { "timeFromEpoch no ms", function() return playdate.timeFromEpoch(100) end },
  { "GMT no ms", function() return playdate.GMTTimeFromEpoch(100) end },
  { "GMT ms 1500", function() return playdate.GMTTimeFromEpoch(100, 1500) end },
  { "GMT ms -20", function() return playdate.GMTTimeFromEpoch(100, -20) end },
  { "GMT float", function() return playdate.GMTTimeFromEpoch(100.5, 0) end },
  { "local 1e6", function() return playdate.timeFromEpoch(1000000, 7) end },
  { "epochFromGMTTime nil", function() return playdate.epochFromGMTTime(nil) end },
  { "epochFromGMTTime str", function() return playdate.epochFromGMTTime("x") end },
  { "epochFromGMTTime floats", function() return playdate.epochFromGMTTime({ year = 2024.0, month = 2.5, day = "3", hour = 4 }) end },
  { "epochFromGMTTime big", function() return playdate.epochFromGMTTime({ year = 67536, month = 258, day = 1 }) end },
  { "epochFromTime empty", function() return playdate.epochFromTime({}) end },
  { "epochFromTime local", function() return playdate.epochFromTime({ year = 2010, month = 6, day = 15, hour = 12, millisecond = 77 }) end },
  { "epochFromTime numeric key", function() return playdate.epochFromTime({ 5, 6, year = 2010, month = 6, day = 15 }) end },
}
for _, c in ipairs(extra) do
  local r = table.pack(pcall(c[2]))
  local parts = {} for i = 2, r.n do parts[#parts + 1] = show(r[i]) end
  fh:write(c[1] .. " " .. tostring(r[1]) .. " " .. table.concat(parts, " ") .. "\n")
end
local now = playdate.getGMTTime() local lt = playdate.getTime()
fh:write("now fields " .. (now.year >= 2026 and "ok" or "bad") .. " " .. tostring(now.millisecond ~= nil) .. " " .. tostring(lt.weekday ~= nil) .. " " .. tostring(math.type(now.year)) .. "\n")
fh:close()
function playdate.update() end
