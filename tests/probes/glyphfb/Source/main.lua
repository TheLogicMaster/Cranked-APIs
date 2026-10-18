-- Probe: drawing button glyphs (U+24B6, U+24B7) with the system font and with a font that lacks them
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function grid(name, f)
  local img = gfx.image.new(60, 24, gfx.kColorWhite)
  gfx.pushContext(img) local ok, w, h = pcall(f) gfx.popContext()
  fh:write(name .. " " .. tostring(ok) .. " " .. tostring(w) .. " " .. tostring(h) .. "\n")
  for y = 0, 23 do local r = {} for x = 0, 59 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end fh:write(table.concat(r) .. "\n") end
end
local custom = gfx.font.new("font-Bitmore-Medieval-Bold")
fh:write("custom " .. tostring(custom ~= nil) .. "\n")
for _, s in ipairs({"\u{24B6}", "\u{24B7}", "x\u{24B6}x", "\u{2190}", "\u{1F600}"}) do
  grid("sys " .. s, function() return gfx.drawText(s, 2, 2) end)
  grid("custom " .. s, function() gfx.setFont(custom) local w, h = gfx.drawText(s, 2, 2) return w, h end)
  fh:write("widths " .. gfx.getSystemFont():getTextWidth(s) .. " " .. custom:getTextWidth(s) .. "\n")
  gfx.setFont(gfx.getSystemFont())
end
for _, s in ipairs({"x", "xx", "x\u{24B6}", "\u{24B6}x", "x\u{24B6}x", "\u{24B6}\u{24B6}", "x\u{24B6}\u{24B6}x", "xy\u{2190}z"}) do
  gfx.setFont(custom)
  local img = gfx.image.new(80, 24, gfx.kColorWhite)
  gfx.pushContext(img) local w, h = gfx.drawText(s, 0, 0) gfx.popContext()
  local cols = {}
  for x = 0, 79 do local any = false for y = 0, 23 do if img:sample(x, y) == gfx.kColorBlack then any = true end end cols[#cols + 1] = any and "#" or "." end
  local tw, th = gfx.getTextSize(s)
  fh:write(string.format("m %s draw=%s,%s size=%s,%s fw=%d cols=%s\n", s, w, h, tw, th, custom:getTextWidth(s), table.concat(cols)))
  gfx.setFont(gfx.getSystemFont())
end
for _, s in ipairs({"x\u{24B6}x", "\u{24B6}"}) do
  local img = gfx.image.new(80, 24, gfx.kColorWhite)
  gfx.pushContext(img) local w, h = custom:drawText(s, 0, 0) gfx.popContext()
  local cols = {}
  for x = 0, 79 do local any = false for y = 0, 23 do if img:sample(x, y) == gfx.kColorBlack then any = true end end cols[#cols + 1] = any and "#" or "." end
  fh:write(string.format("fd %s draw=%s,%s cols=%s\n", s, tostring(w), tostring(h), table.concat(cols)))
  local fam = gfx.font.newFamily({[gfx.font.kVariantNormal] = "font-Bitmore-Medieval-Bold"})
  gfx.setFontFamily(fam) gfx.setFont(custom)
  img = gfx.image.new(80, 24, gfx.kColorWhite)
  gfx.pushContext(img) w, h = gfx.drawText("*" .. s .. "*", 0, 0) gfx.popContext()
  cols = {}
  for x = 0, 79 do local any = false for y = 0, 23 do if img:sample(x, y) == gfx.kColorBlack then any = true end end cols[#cols + 1] = any and "#" or "." end
  fh:write(string.format("bold %s draw=%s,%s cols=%s\n", s, tostring(w), tostring(h), table.concat(cols)))
  gfx.setFont(gfx.getSystemFont())
end
fh:write("heights " .. custom:getHeight() .. " " .. gfx.getSystemFont():getHeight() .. " tracking " .. custom:getTracking() .. "\n")
fh:close()
function playdate.update() end
