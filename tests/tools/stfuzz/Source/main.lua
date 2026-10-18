-- Probe (differential): random image draws through random stencils; prints a hash of the target after each
-- case, so two builds can be compared (no Simulator reference). Covers tiled and untiled stencils of any size,
-- inverted and masked stencils, all draw modes, flips, draw offsets, clip rects, masked sources and targets.
import "CoreLibs/graphics"
local gfx = playdate.graphics
math.randomseed(12345)
local R = math.random
local function randImage(w, h, withMask)
  local img = gfx.image.new(w, h, withMask and gfx.kColorClear or (R(2) == 1 and gfx.kColorWhite or gfx.kColorBlack))
  gfx.pushContext(img)
  for _ = 1, R(1, 6) do
    local c = R(3); gfx.setColor(c == 1 and gfx.kColorWhite or (c == 2 and gfx.kColorBlack or gfx.kColorClear))
    gfx.fillRect(R(-4, w), R(-4, h), R(1, w + 4), R(1, h + 4))
  end
  gfx.popContext()
  return img
end
local modes = { gfx.kDrawModeCopy, gfx.kDrawModeWhiteTransparent, gfx.kDrawModeBlackTransparent, gfx.kDrawModeFillWhite,
  gfx.kDrawModeFillBlack, gfx.kDrawModeXOR, gfx.kDrawModeNXOR, gfx.kDrawModeInverted }
local flips = { gfx.kImageUnflipped, gfx.kImageFlippedX, gfx.kImageFlippedY, gfx.kImageFlippedXY }
local function hash(img)
  local h = 7
  local w, hh = img:getSize()
  for y = 0, hh - 1 do for x = 0, w - 1 do
    local s = img:sample(x, y); local v = s == gfx.kColorBlack and 1 or (s == gfx.kColorWhite and 2 or 3)
    h = (h * 31 + v) % 1000000007
  end end
  return tostring(math.tointeger(h) or h)
end
local out = {}
for case = 1, 3000 do
  local tw, th = R(1, 70), R(1, 30)
  local target = randImage(tw, th, R(4) == 1)
  local src = randImage(R(1, 50), R(1, 20), R(3) == 1)
  local st = randImage(R(32, 72), R(1, 20), R(3) == 1)
  if R(4) == 1 then st = st:invertedImage() end
  local tiled = R(2) == 1
  gfx.pushContext(target)
  if R(3) == 1 then gfx.setDrawOffset(R(-10, 10), R(-10, 10)) end
  if R(3) == 1 then gfx.setClipRect(R(-5, tw), R(-5, th), R(0, tw + 5), R(0, th + 5)) end
  gfx.setStencilImage(st, tiled)
  gfx.setImageDrawMode(modes[R(#modes)])
  src:draw(R(-20, tw + 5), R(-20, th + 5), flips[R(#flips)])
  gfx.clearStencil()
  gfx.popContext()
  out[#out + 1] = case .. " " .. hash(target)
end
local fh = playdate.file.open("stfuzz.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
function playdate.update() end
