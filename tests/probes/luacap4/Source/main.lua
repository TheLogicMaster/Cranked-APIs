-- Probe: Lua LFO API (arpeggio, delay, retrigger, random seed), notes on the audio clock
local snd = playdate.sound
local frame = 0
local function synth(w) local s = snd.synth.new(w or snd.kWaveSine); return s end
local a = synth(); local la = snd.lfo.new(snd.kLFOSquare); la:setArpeggio(0, 3, 7, 12, 15); la:setRate(4); a:setFrequencyMod(la)
local b = synth(); local lb = snd.lfo.new(snd.kLFOTriangle); lb:setRate(3); lb:setDepth(0.5); lb:setDelay(0.1, 0.2); b:setFrequencyMod(lb)
local c = synth(); local lc = snd.lfo.new(snd.kLFOSampleAndHold); lc:setRate(8); lc:setDepth(0.3); lc:setRandomSeed(1234); c:setFrequencyMod(lc)
local d = synth(); local ld = snd.lfo.new(snd.kLFOSine); ld:setRate(2.5); ld:setDepth(0.4); ld:setRetrigger(true); ld:setStartPhase(0.5); d:setFrequencyMod(ld)
function playdate.update()
    frame = frame + 1
    if frame == 5 then
        local t = snd.getCurrentTime() + 0.1
        a:playNote(440, 0.5, 1.0, t)
        b:playNote(440, 0.5, 0.6, t + 1.1); b:playNote(440, 0.5, 0.6, t + 1.8)
        c:playNote(440, 0.5, 0.6, t + 2.5)
        d:playNote(440, 0.5, 0.3, t + 3.2); d:playNote(440, 0.5, 0.3, t + 3.6)
    end
    if frame == 5 + 30 * 5 then
        captureSave("capture.raw")
        if playdate.simulator then playdate.simulator.exit() end
    end
end
