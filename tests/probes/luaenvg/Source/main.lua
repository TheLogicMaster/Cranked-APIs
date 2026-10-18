-- Probe: Lua envelope:setGlobal and synth:setEnvelopeCurvature
-- (a global envelope used as a synth's modulator corrupts the Simulator's heap)
local snd = playdate.sound
local frame = 0
local log = {}
-- curvature on the synth's own envelope (note at 0.1 s, audio time)
local a = snd.synth.new(snd.kWaveSine); a:setADSR(0.3, 0.3, 0.3, 0.3); a:setEnvelopeCurvature(0.8)
a:playNote(330, 0.8, 0.8, 0.1)
-- a global envelope runs on its own; another, unused, does not
local eg = snd.envelope.new(1.5, 0.5, 0.5, 0.5); eg:setGlobal(true); eg:trigger(1)
local en = snd.envelope.new(1.5, 0.5, 0.5, 0.5); en:trigger(1)
function playdate.update()
    frame = frame + 1
    if frame % 15 == 0 and frame <= 120 then log[#log + 1] = string.format("f%d global %.2f other %.2f", frame, eg:getValue(), en:getValue()) end
    if frame == 130 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); for _, l in ipairs(log) do f:write(l .. "\n") end; f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
