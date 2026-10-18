-- Probe: fileplayer and sample results without a file, and sample defaults
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function show(name, ...) local r = table.pack(...) local s = {} for i = 1, r.n do s[#s + 1] = tostring(r[i]) end fh:write(name .. " n=" .. r.n .. " " .. table.concat(s, " | ") .. "\n") end
local fp = snd.fileplayer.new()
show("getLength", fp:getLength())
show("getOffset", fp:getOffset())
show("load missing", fp:load("nope"))
show("load missing again", fp:load("nope"))
show("getLength after", fp:getLength())
show("play", fp:play())
show("isPlaying", fp:isPlaying())
show("load while playing", fp:load("nope"))
fp:stop()
show("load after stop", fp:load("nope"))
local fp2 = snd.fileplayer.new(1)
show("play fresh", fp2:play())
show("load fresh playing", fp2:load("nope"))
for _, sec in ipairs({ 0.1, 1 }) do
  local s = snd.sample.new(sec)
  show("sample " .. sec, s:getFormat(), s:getLength(), s:getSampleRate())
  show("sub", s:getSubsample(0, 10))
  show("sub2", s:getSubsample(10, 100))
end
for f = 0, 3 do local s = snd.sample.new(0.1, f) show("sample fmt " .. f, s:getFormat(), s:getLength()) show("sub fmt " .. f, s:getSubsample(0, 10)) end
fh:close()
function playdate.update() end
