-- Probe: coroutines started from a timer callback, drawing into an image and yielding (as a game's loader does)
import "CoreLibs/timer"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") out:flush() end
local steps = {
  { "plain yield", function() coroutine.yield() return "done" end },
  { "print", function() print("x") coroutine.yield() return "done" end },
  { "lockFocus", function() local im = gfx.image.new(8, 8) gfx.lockFocus(im) gfx.drawLine(1, 1, 5, 1) gfx.unlockFocus() coroutine.yield() gfx.lockFocus(im) gfx.unlockFocus() return "done" end },
  { "yield in lockFocus", function() local im = gfx.image.new(8, 8) gfx.lockFocus(im) coroutine.yield() gfx.unlockFocus() return "done" end },
  { "tonumber/sub", function() local s = "12W3B" local n = tonumber(string.sub(s, 1, 1)) coroutine.yield() return n end },
}
local k = 1
local function runNext()
  if k > #steps then out:close() return end
  local name, f = steps[k][1], steps[k][2]
  local wrapped = coroutine.wrap(f)
  local calls = 0
  playdate.timer.new(33, function(t)
    calls += 1
    local ok, r = pcall(wrapped)
    if not ok then w(name, "error", tostring(r)) t:remove() k += 1 runNext()
    elseif r ~= nil then w(name, "ok", r, calls) t:remove() k += 1 runNext() end
  end).repeats = true
end
runNext()
function playdate.update() playdate.timer.updateTimers() end
