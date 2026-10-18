-- Probe: font:getGlyph with multibyte characters, missing characters, numbers and odd arguments
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local f = gfx.getSystemFont()
local fi = gfx.getFont(gfx.font.kVariantItalic)
local function desc(img)
  if img == nil then return "nil" end
  local w, h = img:getSize()
  local ink = 0
  for y = 0, h - 1 do for x = 0, w - 1 do if img:sample(x, y) == gfx.kColorBlack then ink = ink + 1 end end end
  return w .. "x" .. h .. ":" .. ink
end
local args = {"a", "ab", "\u{E9}", "\u{FFFD}", "\u{2603}", "", 65, 0xE9, 0xFFFD, 0x2603, 0, -1, 65.7, "65", 0x10041, 300}
local line, linei = {}, {}
for i, a in ipairs(args) do
  local lf = playdate.file.open("log.txt", playdate.file.kFileAppend) lf:write(i .. "\n") lf:close()
  local ok, r = pcall(f.getGlyph, f, a)
  line[#line + 1] = i .. "=" .. (ok and desc(r) or ("err:" .. tostring(r)))
  ok, r = pcall(fi.getGlyph, fi, a)
  linei[#linei + 1] = i .. "=" .. (ok and desc(r) or ("err:" .. tostring(r)))
end
fh:write("sys " .. table.concat(line, " ") .. "\n")
fh:write("ita " .. table.concat(linei, " ") .. "\n")
local ok, r = pcall(f.getGlyph, f)
fh:write("none " .. (ok and desc(r) or ("err:" .. tostring(r))) .. "\n")
fh:close()
function playdate.update() end
