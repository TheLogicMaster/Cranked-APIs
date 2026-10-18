-- Probe: single drawing calls from the drawdiff probe that differed between the Simulator and an emulator
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local imgs = { gfx.image.new("u1"), gfx.image.new("u2"), gfx.image.new("c1"), gfx.image.new("c3") }
local small = gfx.image.new(13, 9, gfx.kColorClear)
gfx.pushContext(small) gfx.setColor(gfx.kColorBlack) gfx.fillCircleAtPoint(6, 4, 4) gfx.setColor(gfx.kColorWhite) gfx.drawLine(0, 0, 12, 8) gfx.popContext()
imgs[#imgs + 1] = small
local W, H = 160, 120
local function dump(name, f)
  local img = gfx.image.new(W, H, gfx.kColorWhite)
  gfx.pushContext(img)
  if CLEARBG then gfx.setColor(gfx.kColorClear) gfx.fillRect(0, 0, W, H / 2) gfx.setPattern({0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55}) gfx.fillRect(W / 2, 0, W / 2, H) gfx.setColor(gfx.kColorBlack) end
  local ok, e = pcall(f) gfx.popContext()
  fh:write(name .. " " .. tostring(ok) .. " " .. tostring(e) .. "\n")
  for y = 0, H - 1 do local r = {} for x = 0, W - 1 do local c = img:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(r) .. "\n") end
end
dump("tiled1", function() imgs[2]:drawTiled(87, 65, 2, 9) end)
dump("tiled2", function() imgs[4]:drawTiled(-6, 5, 63, 29) end)
dump("tiled5", function() imgs[4]:drawTiled(90, 62, 78, 17) end)
dump("tiled7", function() imgs[1]:drawTiled(104, 96, 59, 24) end)
dump("tiled8", function() imgs[5]:drawTiled(2, 101, 14, 21) end)
dump("tiledflip", function() imgs[1]:drawTiled(4, 6, 59, 44, gfx.kImageFlippedX) end)
dump("tiledu1", function() imgs[1]:drawTiled(4, 6, 59, 44) end)
dump("tiledc1", function() imgs[3]:drawTiled(4, 6, 59, 44) end)
dump("faded3", function() imgs[3]:drawFaded(103, -7, 0.5962, gfx.image.kDitherTypeBayer4x4) end)
dump("faded3b", function() imgs[3]:drawFaded(10, 7, 0.5962, gfx.image.kDitherTypeBayer4x4) end)
dump("fadedu1", function() imgs[1]:drawFaded(10, 7, 0.5962, gfx.image.kDitherTypeBayer4x4) end)
dump("rot4", function() imgs[1]:drawRotated(96, 23, 190.416, 2.30728) end)
dump("rot4b", function() imgs[1]:drawRotated(60, 50, 190.416, 2.30728) end)
dump("rot4c", function() imgs[1]:drawRotated(60, 50, 190, 2) end)
for fi, f in ipairs({gfx.kImageUnflipped, gfx.kImageFlippedX, gfx.kImageFlippedY, gfx.kImageFlippedXY}) do
  for ii = 1, 5 do
    dump("T " .. ii .. " flip " .. fi, function() imgs[ii]:drawTiled(7, 5, 59, 44, f) end)
  end
end
dump("O tiled7", function() gfx.setDrawOffset(-15, 4) imgs[1]:drawTiled(104, 96, 59, 24) end)
dump("O tiled7b", function() gfx.setDrawOffset(-15, 4) imgs[1]:drawTiled(30, 20, 59, 44) end)
dump("O tiledflip", function() gfx.setDrawOffset(-7, -3) imgs[3]:drawTiled(30, 20, 59, 44, gfx.kImageFlippedXY) end)
dump("K rot4", function() gfx.setColor(gfx.kColorClear) imgs[1]:drawRotated(96, 23, 190.416, 2.30728) end)
dump("K rot4p", function() gfx.drawPolygon(104, 15, 65, -1, 32, 8) gfx.setColor(gfx.kColorClear) imgs[1]:drawRotated(96, 23, 190.416, 2.30728) end)
dump("S seq7", function()
  gfx.drawTextInRect("The quick brown fox jumps over the lazy dog", 28, 52, 12, 5, nil, "...", 0)
  imgs[2]:drawTiled(130, -18, 61, 22, gfx.kImageUnflipped)
  gfx.setDrawOffset(-15, 4)
  imgs[1]:drawTiled(104, 96, 59, 24, gfx.kImageUnflipped)
end)
dump("S two", function() imgs[2]:drawTiled(130, -18, 61, 22) imgs[1]:drawTiled(30, 20, 59, 44) end)
dump("S text", function() gfx.drawTextInRect("The quick brown fox jumps over the lazy dog", 28, 52, 12, 5, nil, "...", 0) imgs[1]:drawTiled(30, 20, 59, 44) end)
do
  local t = gfx.image.new(W, H, gfx.kColorWhite)
  gfx.pushContext(t) gfx.setDrawOffset(-15, 4) gfx.setClipRect(5, 5, 50, 50) gfx.setColor(gfx.kColorXOR) gfx.setLineWidth(3) gfx.popContext()
  gfx.pushContext(t)
  local ox, oy = gfx.getDrawOffset()
  fh:write("after repush offset " .. ox .. "," .. oy .. " clip " .. table.concat({gfx.getClipRect()}, ",") .. " lw " .. gfx.getLineWidth() .. "\n")
  imgs[1]:drawTiled(104, 96, 59, 24)
  gfx.fillRect(2, 2, 10, 10)
  gfx.popContext()
  fh:write("R repush true nil\n")
  for y = 0, H - 1 do local r = {} for x = 0, W - 1 do local c = t:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(r) .. "\n") end
end
CLEARBG = true
dump("C tiled1", function() imgs[2]:drawTiled(87, 65, 2, 9) end)
dump("C tiledu1", function() imgs[1]:drawTiled(4, 6, 59, 44) end)
dump("C tiledu2", function() imgs[2]:drawTiled(4, 6, 159, 104) end)
dump("C draw u1", function() imgs[1]:draw(4, 6) end)
dump("C draw u2", function() imgs[2]:draw(4, 6) end)
dump("C faded", function() imgs[3]:drawFaded(10, 7, 0.5962, gfx.image.kDitherTypeBayer4x4) end)
dump("C rot", function() imgs[1]:drawRotated(60, 50, 190.416, 2.30728) end)
dump("C rot2", function() imgs[2]:drawRotated(60, 50, 30) end)
dump("C scaled", function() imgs[2]:drawScaled(10, 50, 1.7) end)
dump("C fill", function() gfx.fillRect(10, 10, 100, 50) end)
dump("C line", function() gfx.drawLine(0, 0, 159, 119) end)
dump("C text", function() gfx.drawText("Hello there", 10, 20) end)
dump("C xor", function() gfx.setImageDrawMode(gfx.kDrawModeXOR) imgs[2]:draw(4, 6) gfx.setImageDrawMode(gfx.kDrawModeCopy) end)
dump("C fillwhite", function() gfx.setImageDrawMode(gfx.kDrawModeFillWhite) imgs[1]:draw(4, 6) gfx.setImageDrawMode(gfx.kDrawModeCopy) end)
fh:close()
function playdate.update() end
