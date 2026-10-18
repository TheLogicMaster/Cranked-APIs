-- Probe: widths of strings ending in an empty glyph (the italic system font's U+FFFD), via getTextWidth
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local R = "\u{FFFD}"
local f = gfx.getFont(gfx.font.kVariantItalic)
local cases = {R, "a" .. R, "aa" .. R, "b" .. R, "l" .. R, "i" .. R, "W" .. R, "." .. R, "j" .. R, " " .. R, "  " .. R,
  R .. " " .. R, R .. R .. R, "a" .. R .. R, R .. "a" .. R, "l", "W", "a", ".", "l.", "ll", "Wa", "aW", "la", "al", "a" .. R .. "a"}
local line = {}
for _, t in ipairs(cases) do line[#line + 1] = "[" .. t:gsub(R, "R") .. "]=" .. f:getTextWidth(t) end
fh:write(table.concat(line, " ") .. "\n")
fh:close()
function playdate.update() end
