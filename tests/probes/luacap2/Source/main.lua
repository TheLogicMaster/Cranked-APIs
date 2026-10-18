local snd = playdate.sound
local log = {}
local function note(s) log[#log + 1] = s .. " at capture frame " .. captureFrames() end
local frame = 0
local synth = snd.synth.new(snd.kWaveSine)
synth:setADSR(0.05, 0.1, 0.5, 0.2)
local sp = snd.sampleplayer.new("assets/beep")
sp:setVolume(0.5)
sp:setFinishCallback(function() note("sampleplayer finished") end)
local s2 = snd.synth.new(snd.kWaveSine)
s2:setFinishCallback(function() note("synth finished") end)
local dl = snd.delayline.new(0.05)
if dl then dl:setFeedback(0.5) end
local bc = snd.bitcrusher.new()
bc:setAmount(0.5)
local fp = snd.fileplayer.new("assets/beep")
if fp then fp:setVolume(0.5) end
function playdate.update()
    frame = frame + 1
    if frame == 15 then note("synth ADSR start"); synth:playNote(440, 0.5, 0.3) end
    if frame == 45 then note("sampleplayer start"); sp:play() end
    if frame == 75 then note("synth with callback start"); s2:playNote(440, 0.5, 0.2) end
    if frame == 100 and dl then note("delay start"); snd.addEffect(dl); sp:setVolume(1); sp:play() end
    if frame == 135 then if dl then snd.removeEffect(dl) end; snd.addEffect(bc); note("bitcrusher start"); s2:playNote(440, 0.5, 0.3) end
    if frame == 160 then snd.removeEffect(bc); note("fileplayer start"); if fp then fp:play() end end
    if frame == 200 then
        captureSave("capture.raw")
        local f = playdate.file.open("log.txt", playdate.file.kFileWrite); f:write(table.concat(log, "\n") .. "\n"); f:close()
        if playdate.simulator then playdate.simulator.exit() end
    end
end
