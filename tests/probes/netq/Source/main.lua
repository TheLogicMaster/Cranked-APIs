-- Probe: network, server time, launcher and other system functions, without network permission
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") out:flush() end
local function try(name, f) local r = table.pack(pcall(f)) w(name, table.unpack(r, 1, r.n)) end
local net = playdate.network
w("argv", #playdate.argv, playdate.argv[1], playdate.argv[2])
do
    local c1, c2 = playdate.sound.channel.new(), playdate.sound.channel.new()
    local src = c1:getOutputAsSource()
    w("chsrc", type(src), src and src.__name, src == c1:getOutputAsSource(), c2:addSource(src), c2:addSource(src))
end
w("consts", net.kStatusNotConnected, net.kStatusConnected, net.kStatusNotAvailable)
try("getStatus", function() return net.getStatus() end)
try("http.new", function() return net.http.new("example.com") end)
try("http.new port", function() return net.http.new("example.com", 80, false, "reason") end)
try("https.new", function() return net.https and net.https.new("example.com") end)
try("tcp.new", function() return net.tcp.new("example.com", 80) end)
try("setEnabled", function() return net.setEnabled(false, function(e) w("setEnabled cb", e) end) end)
try("getServerTime", function() return playdate.getServerTime(function(t, e) w("serverTime cb", t, e) end) end)
local syn = playdate.sound.synth.new()
local ins = playdate.sound.instrument.new(syn)
try("instrument:stop type", function() return type(ins.stop) end)
try("micinput.requestAccess", function() return playdate.sound.micinput.requestAccess and type(playdate.sound.micinput.requestAccess) end)
try("signalvalue", function() return playdate.sound.signalvalue and type(playdate.sound.signalvalue.getValue) end)
local lfo = playdate.sound.lfo.new(playdate.sound.kLFOSine)
try("lfo:getValue", function() return lfo:getValue() end)
try("ch:getOutputAsSource", function() local c = playdate.sound.channel.new() return type(c.getOutputAsSource) end)
try("channelsource", function() return playdate.sound.channelsource and type(playdate.sound.channelsource.new) end)
try("sendMirrorData", function() return type(playdate.sendMirrorData) end)
try("exitToLauncher type", function() return type(playdate.exitToLauncher) end)
local frames = 0
function playdate.update()
    frames += 1
    if frames == 60 then w("frame60") end
end
