-- Probe: Lua file player behavior (play defaults, loop ranges and callbacks, stop, pause, offsets, buffer size)
local snd = playdate.sound
local frame = 0
local log = {}
local function L(...) local t = {} for i, v in ipairs({...}) do t[i] = tostring(v) end log[#log + 1] = table.concat(t, " ") end
local function off(p) return string.format("%.4f", p:getOffset()) end
local bad, err = snd.fileplayer.new("assets/nope")
L("new missing", type(bad), type(err))
local a = snd.fileplayer.new("assets/m44")
local b = snd.fileplayer.new("assets/m44")
local c = snd.fileplayer.new("assets/m22", 0.1)
local d = snd.fileplayer.new()
L("new empty", type(d), d and d:getLength())
local loopsA, loopsB = 0, 0
L("a fresh", off(a), a:isPlaying(), a:getLength())
a:setLoopRange(0.5, 1.0, function(p, arg) loopsA = loopsA + 1 end)
L("a loop range set", off(a))
b:setLoopRange(0, 0.5)
b:setLoopCallback(function(p, arg) loopsB = loopsB + 1; if loopsB == 1 then L("b loop arg", arg) end end, "argB")
c:setFinishCallback(function(p, arg) L("c finished frame", frame, "arg", arg) end, "argC")
function playdate.update()
    frame = frame + 1
    if frame == 5 then a:play(); b:play(); c:play(1) end
    if frame == 10 then
        local ok, e = pcall(function() return a:setBufferSize(0.5) end)
        L("setBufferSize playing", ok, e)
        L("setBufferSize stopped", d:setBufferSize(0.5))
    end
    if frame == 50 then a:pause(); L("a paused", off(a), a:isPlaying()) end
    if frame == 60 then L("a still paused", off(a)); a:play() end
    if frame == 65 then L("a resumed", off(a), a:isPlaying()) end
    if frame == 80 then c:stop(); L("c stopped", off(c), c:isPlaying()) end
    if frame == 85 then c:play(); L("c replay", off(c)) end
    if frame % 10 == 0 then L("f" .. frame, off(a), off(b), off(c), a:isPlaying(), b:isPlaying(), c:isPlaying(), loopsA, loopsB) end
    if frame == 200 then
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
