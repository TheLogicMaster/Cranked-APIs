-- Probe: file player seeks while playing and while stopped, and offsets right after
local snd = playdate.sound
local frame = 0
local log = {}
local function L(...) local t = {} for i, v in ipairs({...}) do t[i] = tostring(v) end log[#log + 1] = table.concat(t, " ") end
local function off(p) return string.format("%.4f", p:getOffset()) end
local a = snd.fileplayer.new("assets/m44")
local b = snd.fileplayer.new("assets/m44", 1.0)
local c = snd.fileplayer.new("assets/m44")
function playdate.update()
    frame = frame + 1
    if frame == 5 then a:play(); b:play(); c:setOffset(2.0); L("c set stopped", off(c)); c:play(); L("c played", off(c)) end
    if frame == 20 then a:setOffset(2.0); b:setOffset(2.0); L("seek playing", off(a), off(b)) end
    if frame >= 20 and frame <= 40 then L("f" .. frame, off(a), off(b), off(c)) end
    if frame == 60 then
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
