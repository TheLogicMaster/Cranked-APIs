-- Probe: a channel's dry and wet level signals, unused and used as modulators, with a steady square wave
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local ch = snd.channel.new()
local syn = snd.synth.new(snd.kWaveSquare)
syn:setVolume(0.5)
ch:addSource(syn)
local od = snd.overdrive.new() od:setGain(3) od:setMix(1)
ch:addEffect(od)
local dry, wet = ch:getDryLevelSignal(), ch:getWetLevelSignal()
local ch2 = snd.channel.new()
local syn2 = snd.synth.new(snd.kWaveSine)
ch2:addSource(syn2)
syn:playNote(220)
syn2:playNote(330)
local frame = 0
local function f(v) return string.format("%.4f", v) end
function playdate.update()
  frame = frame + 1
  if frame == 10 then syn2:setAmplitudeMod(dry) end
  if frame == 20 then syn2:setFrequencyMod(wet) end
  if frame == 30 then syn:setVolume(0.25) end
  if frame == 40 then syn:noteOff() end
  if frame % 2 == 0 and frame <= 56 then
    fh:write("frame " .. frame .. " dry " .. f(dry:getValue()) .. " wet " .. f(wet:getValue()) .. "\n") fh:flush()
  end
  if frame == 57 then fh:close() end
end
