-- Timer probe: when CoreLibs timers and animators fire, by frame and by clock.
import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/animator"
import "CoreLibs/easing"
local gfx = playdate.graphics
local log = {}
local frame = 0
local t0 = playdate.getCurrentTimeMilliseconds()
local function ev(s) log[#log + 1] = string.format("%s\t%d\t%d", s, frame, playdate.getCurrentTimeMilliseconds() - t0) end
playdate.timer.performAfterDelay(500, function() ev("timer 500ms fired") end)
local rep = playdate.timer.keyRepeatTimerWithDelay(300, 100, function() end)
local count = 0
local periodic = playdate.timer.new(200, function() count = count + 1; ev("timer 200ms repeat " .. count) end)
periodic.repeats = true
playdate.frameTimer.performAfterDelay(10, function() ev("frameTimer 10 frames fired") end)
local anim = gfx.animator.new(1000, 0, 100, playdate.easingFunctions.linear)
local animChecks = { [250] = false, [500] = false, [750] = false }
local stopped = false
function playdate.update()
    frame = frame + 1
    playdate.timer.updateTimers()
    playdate.frameTimer.updateTimers()
    local elapsed = playdate.getCurrentTimeMilliseconds() - t0
    for t, done in pairs(animChecks) do
        if not done and elapsed >= t then animChecks[t] = true; log[#log + 1] = string.format("animator at %dms\t%.0f\t%s", t, anim:currentValue(), tostring(anim:ended())) end
    end
    if count >= 4 and not stopped then periodic:remove(); stopped = true; ev("periodic removed") end
    if elapsed > 1600 then
        log[#log + 1] = string.format("animator ended after 1600ms\t%s\t%.0f", tostring(anim:ended()), anim:currentValue())
        log[#log + 1] = string.format("frames per second\t%d", math.floor(frame * 1000 / elapsed + 0.5))
        local f = playdate.file.open("outt.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
        playdate.stop()
    end
end
