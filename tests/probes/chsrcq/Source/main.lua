-- Probe: playdate.sound.channelsource.new and remove, signalvalue, and the source base methods
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") out:flush() end
local function try(name, f) local r = table.pack(pcall(f)) local t = {} for i = 1, r.n do local v = r[i] t[#t+1] = type(v) == "userdata" and ("ud:" .. tostring(v.__name)) or tostring(v) end w(name, table.concat(t, " ")) end
local snd = playdate.sound
local c1, c2 = snd.channel.new(), snd.channel.new()
try("new()", function() return snd.channelsource.new() end)
try("new(c1)", function() return snd.channelsource.new(c1) end)
try("new(c1,c2)", function() return snd.channelsource.new(c1, c2) end)
local src = c1:getOutputAsSource()
try("src methods", function() local m = {} for _, k in ipairs({ "setVolume", "getVolume", "remove", "isPlaying", "play", "stop" }) do m[#m+1] = k .. "=" .. type(src[k]) end return table.concat(m, ",") end)
try("src:getVolume", function() return src:getVolume() end)
try("src:setVolume(0.5)", function() src:setVolume(0.5) return src:getVolume() end)
try("c2:addSource", function() return c2:addSource(src) end)
try("src:remove()", function() return src:remove() end)
try("c2:addSource again", function() return c2:addSource(src) end)
try("signalvalue", function() local m = {} for k, v in pairs(snd.signalvalue) do m[#m+1] = k end table.sort(m) return table.concat(m, ",") end)
local lfo = snd.lfo.new(snd.kLFOSine)
try("signalvalue.getValue(lfo)", function() return snd.signalvalue.getValue(lfo) end)
try("lfo signalvalue mt", function() return getmetatable(lfo).__index == snd.lfo, rawget(snd.lfo, "getValue") ~= nil end)
try("signal", function() local m = {} for k, v in pairs(snd.signal) do m[#m+1] = k end table.sort(m) return table.concat(m, ",") end)
function playdate.update() end
