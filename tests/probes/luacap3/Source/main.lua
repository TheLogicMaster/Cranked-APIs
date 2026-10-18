local snd = playdate.sound
local log = {}
local function note(s) log[#log + 1] = s .. " at capture frame " .. captureFrames() end
local frame = 0
local inst = snd.instrument.new(snd.synth.new(snd.kWaveSine))   -- the synth shortcut
local inst2 = snd.instrument.new()
inst2:addVoice(snd.synth.new(snd.kWaveSine)); inst2:addVoice(snd.synth.new(snd.kWaveSine))
function playdate.update()
    frame = frame + 1
    if frame == 15 then note("instrument playNote 440 for 0.3"); inst:playNote(440, 0.5, 0.3) end
    if frame == 45 then note("instrument playMIDINote C5 held"); inst:playMIDINote("C5", 0.5) end
    if frame == 60 then note("instrument noteOff C5"); inst:noteOff("C5") end
    if frame == 80 then note("two-voice chord E4 G4 for 0.3"); inst2:playMIDINote(64, 0.5, 0.3); inst2:playMIDINote(67, 0.5, 0.3) end
    if frame == 81 then log[#log + 1] = "playingSources count " .. #snd.playingSources() end
    if frame == 120 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
