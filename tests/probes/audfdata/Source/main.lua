-- Probe: where the sound loaders look. The bundle has both.wav (two seconds of silence, made for this probe); the probe
-- writes both.pda (one second) and only.pda (half a second) to its data folder, then loads them by name. Sounds are
-- read from the data folder first, and listFiles names a file that is in both places once.
local out = {}
local function rec(...) out[#out + 1] = table.concat({...}, " ") end
local function pda(name, seconds) -- "Playdate AUD", rate 44100 (low 24 bits) and format 2, 16-bit mono (top byte)
  local fh = playdate.file.open(name, playdate.file.kFileWrite)
  fh:write("Playdate AUD" .. string.char(0x44, 0xAC, 0x00, 2) .. string.rep("\0", math.floor(44100 * seconds) * 2)); fh:close()
end
pda("both.pda", 1); pda("only.pda", 0.5)
local function len(x) return x and string.format("%.2f", x:getLength()) or "nil" end
rec("sample both", len(playdate.sound.sample.new("both")))
rec("sample only", len(playdate.sound.sample.new("only")))
rec("sampleplayer only", len(playdate.sound.sampleplayer.new("only")))
rec("fileplayer only", len(playdate.sound.fileplayer.new("only")))
rec("listFiles", table.concat(playdate.file.listFiles("/"), ","))
local fh = playdate.file.open("audfdata.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
function playdate.update() if playdate.simulator then playdate.simulator.exit() end end
