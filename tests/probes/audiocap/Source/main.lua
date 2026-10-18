local snd = playdate.sound
local frame = 0
local beep = snd.sampleplayer.new("assets/beep")
local sq = snd.synth.new(snd.kWaveSquare)
local sine = snd.synth.new(snd.kWaveSine)
function playdate.update()
    frame = frame + 1
    if frame == 10 then beep:play() end                     -- about 0.33 s in
    if frame == 40 then sq:playNote(440, 0.5, 0.3) end      -- about 1.33 s
    if frame == 70 then sine:playNote(220, 0.5, 0.3) end    -- about 2.33 s
    if frame == 110 then
        if playdate.simulator then playdate.simulator.exit() end
        playdate.stop()
    end
end
