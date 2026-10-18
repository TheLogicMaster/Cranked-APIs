-- Probe: drawFaded and fadedImage with kDitherTypeNone near alpha 0.5, and the other types at a few alphas
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new("u1")
local w, h = img:getSize()
fh:write("u1 " .. w .. "x" .. h .. " mask " .. tostring(img:hasMask()) .. "\n")
local function sig(t) local n, s = 0, 0 local W, H = t:getSize() for y = 0, H - 1 do for x = 0, W - 1 do local c = t:sample(x, y) if c == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 elseif c == gfx.kColorClear then s = (s * 13 + x + y * 5) % 1000003 end end end return n .. ":" .. s end
for _, a in ipairs({ 0.0, 0.25, 0.49, 0.4999, 0.5, 0.5006, 0.501, 0.51, 0.75, 0.999, 1.0 }) do
  for _, ty in ipairs({ gfx.image.kDitherTypeNone, gfx.image.kDitherTypeBayer2x2, gfx.image.kDitherTypeFloydSteinberg }) do
    local t = gfx.image.new(60, 40, gfx.kColorWhite)
    gfx.pushContext(t) img:drawFaded(3, 2, a, ty) gfx.popContext()
    local f = img:fadedImage(a, ty)
    fh:write(string.format("a=%s type=%d draw=%s faded=%s\n", tostring(a), ty, sig(t), f and sig(f) or "nil"))
  end
end
fh:close()
function playdate.update() end
