-- Input probe: logs input queries each frame and every input callback.
import "CoreLibs/crank"
local log = {}
local t0 = playdate.getCurrentTimeMilliseconds()
local frame = 0
local function ev(s) log[#log + 1] = string.format("%d\t%s", frame, s) end
function playdate.AButtonDown() ev("AButtonDown") end
function playdate.AButtonUp() ev("AButtonUp") end
function playdate.AButtonHeld() ev("AButtonHeld") end
function playdate.BButtonDown() ev("BButtonDown (global)") end
function playdate.crankUndocked() ev("crankUndocked") end
function playdate.crankDocked() ev("crankDocked") end
function playdate.cranked(change, accel) ev(string.format("cranked %.1f %s", change, tostring(accel ~= nil))) end
playdate.inputHandlers.push({ BButtonDown = function() ev("BButtonDown (handler)") end })
local last = ""
local crankSum = 0
local ticksTotal = 0
function playdate.update()
    frame = frame + 1
    local cur, pressed, released = playdate.getButtonState()
    local change = playdate.getCrankChange()
    crankSum = crankSum + change
    ticksTotal = ticksTotal + playdate.getCrankTicks(4)
    local state = string.format("isPressedA=%s justPressedA=%s justReleasedA=%s cur=%d pressed=%d released=%d docked=%s pos=%.1f",
        tostring(playdate.buttonIsPressed(playdate.kButtonA)), tostring(playdate.buttonJustPressed(playdate.kButtonA)), tostring(playdate.buttonJustReleased(playdate.kButtonA)),
        cur, pressed, released, tostring(playdate.isCrankDocked()), playdate.getCrankPosition())
    if state ~= last then ev(state); last = state end
    if frame == 30 then ev("clock at frame 30: " .. (playdate.getCurrentTimeMilliseconds() - t0)) end
    if frame >= 330 then
        ev(string.format("summary crankSum=%.1f ticks=%d frames=%d", crankSum, ticksTotal, frame))
        local f = playdate.file.open("outi.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        playdate.stop()
    end
end
