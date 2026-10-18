-- Probe: what lies outside an image for blurredImage
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dumpImage(name, r)
  local w, h = r:getSize()
  fh:write(name .. " size " .. w .. " " .. h .. "\n")
  for y = 0, h - 1 do local row = {} for x = 0, w - 1 do local c = r:sample(x, y) row[#row+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(row) .. "\n") end
end
local a = gfx.image.new(16, 12, gfx.kColorBlack) gfx.pushContext(a) gfx.setColor(gfx.kColorWhite) gfx.fillRect(0, 0, 16, 12) gfx.popContext()
local b = gfx.image.new(16, 12, gfx.kColorWhite)
local c = gfx.image.new(16, 12, gfx.kColorBlack)
local d = gfx.image.new(21, 12, gfx.kColorWhite)
local e = gfx.image.new(21, 12) gfx.pushContext(e) gfx.setColor(gfx.kColorWhite) gfx.fillRect(0, 0, 21, 12) gfx.popContext()
for _, im in ipairs({{"newBlackFilledWhite", a}, {"newWhite", b}, {"newBlack", c}, {"new21White", d}, {"new21ClearFilledWhite", e}, {"w21", gfx.image.new("w21")}, {"w32", gfx.image.new("w32")}, {"b21", gfx.image.new("b21")}}) do
  dumpImage(im[1] .. " r1", im[2]:blurredImage(1, 1, gfx.image.kDitherTypeNone, false))
  dumpImage(im[1] .. " r2pad", im[2]:blurredImage(2, 1, gfx.image.kDitherTypeNone, true))
end
fh:close()
function playdate.update() end
