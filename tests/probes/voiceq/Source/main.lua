-- Probe: when instrument:addVoice refuses a synth
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function try(name, inst, s) local ok, e = pcall(inst.addVoice, inst, s) fh:write(name .. " " .. tostring(ok) .. " " .. tostring(e):gsub("^.-:%d+: ", "") .. "\n") end
local s1 = snd.synth.new(snd.kWaveSine) try("fresh", snd.instrument.new(), s1)
try("same synth, second instrument", snd.instrument.new(), s1)
local i3 = snd.instrument.new() local s3 = snd.synth.new() try("first", i3, s3) try("same instrument again", i3, s3)
local s2 = snd.synth.new() s2:playNote(440, 0.1, 0.05) try("after playNote", snd.instrument.new(), s2)
local s4 = snd.synth.new() local ch = snd.channel.new() ch:addSource(s4) try("in a channel", snd.instrument.new(), s4)
local s5 = snd.synth.new() local ch2 = snd.channel.new() ch2:addSource(s5) ch2:removeSource(s5) try("removed from channel", snd.instrument.new(), s5)
local s6 = snd.synth.new() s6:setVolume(0.5) try("after setVolume", snd.instrument.new(), s6)
local s7 = snd.synth.new() local c7 = s7:copy() try("copy", snd.instrument.new(), c7)
local s8 = snd.synth.new() s8:playNote(440) s8:noteOff() try("after playNote + noteOff", snd.instrument.new(), s8)
local i9 = snd.instrument.new() local s9 = snd.synth.new() i9:addVoice(s9) local ok, e = pcall(snd.channel.new().addSource, snd.channel.new(), s9) fh:write("channel add of a voice " .. tostring(ok) .. " " .. tostring(e) .. "\n")
fh:close()
function playdate.update() end
