-- Probe: font:getGlyph with numbers - code point or the number's text?
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local f = gfx.getSystemFont()
local function sig(img) if not img then return "nil" end local w, h = img:getSize() local s = 0 for y = 0, h - 1 do for x = 0, w - 1 do if img:sample(x, y) == gfx.kColorBlack then s = s + x * 31 + y * 7 + 1 end end end return w .. "x" .. h .. ":" .. s end
for _, a in ipairs({ "A", "6", "9", "a", 65, 54, 0x2603, 97, 7, 66.5, "B" }) do
  local ok, img, adv = pcall(f.getGlyph, f, a)
  fh:write(tostring(a) .. " " .. (ok and (sig(img) .. " adv=" .. tostring(adv)) or ("err " .. tostring(img))) .. "\n")
end
fh:close()
function playdate.update() end
