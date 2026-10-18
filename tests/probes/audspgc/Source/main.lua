-- Probe: when sample players the game keeps no reference to are collected. A player that plays is kept until it
-- finishes (with or without a finish callback), one that never played is collected at once, and players made and
-- dropped by the hundred (each loading its own copy of a one-second stereo sound) never run out of memory. The sound is
-- a .pda file of silence that the probe writes first: "Playdate AUD", the rate (44100) in the low 24 bits and the
-- format (3, 16-bit stereo) in the top byte, then the samples.
local out, frame = {}, 0
local function rec(...) out[#out + 1] = frame .. " " .. table.concat({...}, " ") end
local weak = setmetatable({}, { __mode = "v" })
local function state(name) return name .. "=" .. (weak[name] and ("alive playing=" .. tostring(weak[name]:isPlaying())) or "collected") end
local snd = playdate.sound
do
  local fh = playdate.file.open("tone.pda", playdate.file.kFileWrite)
  fh:write("Playdate AUD" .. string.char(0x44, 0xAC, 0x00, 3) .. string.rep("\0", 44100 * 4)); fh:close()
  local tone = snd.sample.new("tone")
  local a = snd.sampleplayer.new(tone); a:setFinishCallback(function() rec("finish callback a") end); a:play(1); weak.a = a
  local b = snd.sampleplayer.new(tone); b:play(1); weak.b = b
  local c = snd.sampleplayer.new(tone); weak.c = c
end
collectgarbage("collect")
rec(state("a"), state("b"), state("c"))
local made, fails = 0, 0
function playdate.update()
  frame = frame + 1
  collectgarbage("collect")
  if frame == 15 or frame == 45 then rec(state("a"), state("b"), state("c")) end
  if frame > 45 and frame <= 145 then
    for i = 1, 4 do
      local p = snd.sampleplayer.new("tone")
      if p then made = made + 1 else fails = fails + 1 end
    end
  end
  if frame == 150 then
    rec("made", made, "failed", fails)
    local fh = playdate.file.open("audspgc.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
  end
end
