-- Probe: file player volume fades (Lua setVolume with fade time and callback)
local snd = playdate.sound
local frame = 0
local log = {}
local function L(x) log[#log + 1] = x end
local a = snd.fileplayer.new("assets/tone")
local b = snd.fileplayer.new("assets/tone")
local c = snd.fileplayer.new("assets/tone")
function playdate.update()
    frame = frame + 1
    if frame == 5 then a:play(0); a:setVolume(0.8) end
    if frame == 15 then a:setVolume(0, 0, 1.0, function(p, arg) L("fade a done frame " .. frame .. " arg " .. tostring(arg)) end, "xa") end
    if frame == 70 then a:stop(); b:play(0); b:setVolume(0.1, 0.1) end
    if frame == 75 then b:setVolume(1, 0.5, 0.5, function(p, arg) L("fade b done frame " .. frame) end) end
    if frame == 110 then b:stop(); c:play(0); c:setVolume(0.6) end
    if frame == 115 then c:setVolume(0, 0, 2.0, function() L("fade c done (should not happen)") end) end
    if frame == 125 then c:setVolume(0.3) end
    if frame >= 5 and frame <= 135 and frame % 5 == 0 then
        local p = frame < 70 and a or frame < 110 and b or c
        local l, r = p:getVolume()
        L(string.format("f%d vol %.4f %.4f", frame, l, r))
    end
    if frame == 150 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
