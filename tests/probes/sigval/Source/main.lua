-- Probe: the class of a channel's level signals (playdate.sound.signalvalue) and what it can do
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function keys(t) local k = {} for n, v in pairs(t or {}) do k[#k + 1] = n .. ":" .. type(v) end table.sort(k) return table.concat(k, " ") end
local ch = snd.channel.new()
local s = ch:getDryLevelSignal()
local mt = getmetatable(s)
fh:write("name " .. tostring(mt and mt.__name) .. "\n")
fh:write("keys " .. keys(mt) .. "\n")
fh:write("index same " .. tostring(mt and mt.__index == mt) .. "\n")
for _, m in ipairs({ "getValue", "setOffset", "setScale" }) do
  local ok, r = pcall(function() return s[m](s, m == "getValue" and nil or 0.5) end)
  fh:write(m .. " " .. tostring(ok) .. " " .. tostring(r) .. "\n")
end
fh:write("wet same object " .. tostring(ch:getWetLevelSignal() == ch:getWetLevelSignal()) .. "\n")
local syn = snd.synth.new()
local ok, e = pcall(function() syn:setAmplitudeMod(s) end) fh:write("as modulator " .. tostring(ok) .. " " .. tostring(e) .. "\n")
local lfo = snd.lfo.new() fh:write("lfo name " .. tostring(getmetatable(lfo).__name) .. " keys " .. keys(getmetatable(lfo)) .. "\n")
fh:write("signal class " .. keys(snd.signal) .. "\n")
fh:write("signalvalue class " .. keys(snd.signalvalue) .. "\n")
fh:close()
function playdate.update() end
