-- Probe: the width gfx.drawText returns against getTextSize, for single characters and short strings,
-- in the system font (three styles) and a Bitmore font
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local custom = gfx.font.new("font-Bitmore-Medieval-Bold")
local strs = {}
for c = 33, 126 do strs[#strs + 1] = string.char(c) end
for _, s in ipairs({"ab", "a.", "f", "ff", "j", "r.", "T.", "y,", "\u{FFFD}", "a\u{FFFD}", "1 ", "W"}) do strs[#strs + 1] = s end
for _, setup in ipairs({"sys", "bold", "italic", "custom"}) do
  local line = {}
  for _, s in ipairs(strs) do
    local img = gfx.image.new(60, 30)
    gfx.pushContext(img)
    if setup == "custom" then gfx.setFont(custom) end
    local t = s
    if setup == "bold" then t = "*" .. s .. "*" elseif setup == "italic" then t = "_" .. s .. "_" end
    if s == "*" or s == "_" then t = s .. s end
    local w, h = gfx.drawText(t, 0, 0)
    local tw, th = gfx.getTextSize(t)
    gfx.popContext()
    if w ~= tw then line[#line + 1] = s .. "=" .. w .. "/" .. tw end
  end
  fh:write(setup .. ": " .. table.concat(line, " ") .. "\n")
end
fh:close()
function playdate.update() end
