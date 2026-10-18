-- Probe: frame timers (deterministic): values, callbacks, repeats, reverses, delays, pause and removal
import "CoreLibs/frameTimer"
import "CoreLibs/easing"
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
local function log(s) fh:write(frame .. " " .. s .. "\n") end
local ft = playdate.frameTimer
local a = ft.new(5, 0, 10) a.updateCallback = function(t) log(string.format("a upd frame=%s value=%.3f", t.frame, t.value)) end a.timerEndedCallback = function(t) log("a ended") end
local b = ft.new(4, 0, 100, playdate.easingFunctions.inOutQuad) b.repeats = true b.reverses = true b.updateCallback = function(t) log(string.format("b frame=%s value=%.3f", t.frame, t.value)) end
local c = ft.new(3) c.delay = 2 c.updateCallback = function(t) log("c upd " .. t.frame) end c.timerEndedCallback = function(t) log("c ended") end
local d = ft.performAfterDelay(3, function(x) log("d fired " .. tostring(x)) end, "arg")
local e = ft.new(6) e.updateCallback = function(t) if t.frame == 2 then t:pause() log("e paused") end end
local g = ft.new(2) g.timerEndedCallback = function(t) log("g ended, removing a") a:remove() end
local h = ft.new(3) h.discardOnCompletion = false h.timerEndedCallback = function(t) log("h ended, frame=" .. t.frame) if frame < 8 then t:reset() t:start() log("h restarted") end end
function playdate.update()
  frame = frame + 1
  if frame == 6 then e:start() log("e started") end
  ft.updateTimers()
  log("timers=" .. #ft.allTimers())
  if frame == 14 then fh:close() end
end
