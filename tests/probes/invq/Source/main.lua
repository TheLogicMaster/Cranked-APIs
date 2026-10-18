-- Probe: the inverted flag (setInverted) through copy, invertedImage, drawing, sampling and derived images
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function base()
  local im = gfx.image.new(8, 4, gfx.kColorBlack)
  gfx.pushContext(im) gfx.setColor(gfx.kColorWhite) gfx.fillRect(0, 0, 3, 4) gfx.popContext()
  return im
end
local function row(im)
  local t = {}
  for x = 0, im.width - 1 do local c = im:sample(x, 1) t[#t + 1] = c == gfx.kColorWhite and "w" or (c == gfx.kColorBlack and "b" or "c") end
  return table.concat(t)
end
local function drawn(im)
  local t = gfx.image.new(8, 4, gfx.kColorBlack)
  gfx.pushContext(t) im:draw(0, 0) gfx.popContext()
  return row(t)
end
local function report(name, im) fh:write(name .. " sample=" .. row(im) .. " drawn=" .. drawn(im) .. "\n") end
local a = base() report("plain", a)
a:setInverted(true) report("setInverted", a)
report("copy of inverted", a:copy())
report("invertedImage of inverted", a:invertedImage())
report("invertedImage of plain", base():invertedImage())
report("scaled of inverted", a:scaledImage(1))
report("rotated of inverted", a:rotatedImage(0))
report("blurred of inverted", a:blurredImage(0, 1, gfx.image.kDitherTypeNone))
report("faded of inverted", a:fadedImage(1, gfx.image.kDitherTypeNone))
report("blurred r1 of inverted", a:blurredImage(1, 1, gfx.image.kDitherTypeNone))
report("faded half of inverted", a:fadedImage(0.5, gfx.image.kDitherTypeBayer2x2))
report("scaled 2 of inverted", a:scaledImage(2))
report("rotated 90 of inverted", a:rotatedImage(90))
report("copy of copy", a:copy():copy())
report("inverted of copy", a:copy():invertedImage())
local sp = gfx.image.new(8, 4, gfx.kColorWhite) gfx.pushContext(sp) gfx.setImageDrawMode(gfx.kDrawModeWhiteTransparent) a:draw(0, 0) gfx.popContext() report("drawn white transparent", sp)
report("vcr of inverted", a:vcrPauseFilterImage())
local m = gfx.image.new(8, 4, gfx.kColorClear)
gfx.pushContext(m) a:draw(0, 0) gfx.popContext() report("drawn into clear", m)
a:setInverted(false) report("setInverted false", a)
fh:close()
function playdate.update() end
