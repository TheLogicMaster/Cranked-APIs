local snd = playdate.sound
local log = {}
local seq = snd.sequence.new("song.mid")
local inst = snd.instrument.new()
inst:addVoice(snd.synth.new(snd.kWaveSine))
inst:addVoice(snd.synth.new(snd.kWaveSine))
seq:getTrackAtIndex(1):setInstrument(inst)   -- no channel added, as many games do
local frame = 0
function playdate.update()
    frame = frame + 1
    if frame == 15 then
        log[#log + 1] = "play at capture frame " .. captureFrames()
        seq:play(function() log[#log + 1] = "finished at capture frame " .. captureFrames() .. ", isPlaying " .. tostring(seq:isPlaying()) end)
    end
    if frame == 150 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
