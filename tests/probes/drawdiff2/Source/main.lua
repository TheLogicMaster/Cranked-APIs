-- Probe: differential drawing. Random drawing calls from a fixed generator; after each call the target's
-- hash is written, so the first call whose result differs between environments can be found.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local geom = playdate.geometry
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seed = 12345
local function rnd(n) seed = (seed * 16807) % 2147483647 return math.floor(seed % n) end
local function rf(a, b) return a + rnd(10000) / 10000 * (b - a) end
local imgs = { gfx.image.new("u1"), gfx.image.new("u2"), gfx.image.new("c1"), gfx.image.new("c3") }
local small = gfx.image.new(13, 9, gfx.kColorClear)
gfx.pushContext(small) gfx.setColor(gfx.kColorBlack) gfx.fillCircleAtPoint(6, 4, 4) gfx.setColor(gfx.kColorWhite) gfx.drawLine(0, 0, 12, 8) gfx.popContext()
imgs[#imgs + 1] = small
local W, H = 160, 120
local target = gfx.image.new(W, H, gfx.kColorWhite)
local function hash()
  local h = 0
  for y = 0, H - 1 do for x = 0, W - 1 do local c = target:sample(x, y) local v = c == gfx.kColorBlack and 1 or (c == gfx.kColorWhite and 2 or 3) h = (h * 31 + v * (x + 1) + y) % 1000000007 end end
  return h
end
local colors = { gfx.kColorBlack, gfx.kColorWhite, gfx.kColorXOR, gfx.kColorClear }
local modes = { gfx.kDrawModeCopy, gfx.kDrawModeInverted, gfx.kDrawModeXOR, gfx.kDrawModeNXOR, gfx.kDrawModeWhiteTransparent, gfx.kDrawModeBlackTransparent, gfx.kDrawModeFillWhite, gfx.kDrawModeFillBlack }
local flips = { gfx.kImageUnflipped, gfx.kImageFlippedX, gfx.kImageFlippedY, gfx.kImageFlippedXY }
local dithers = { gfx.image.kDitherTypeNone, gfx.image.kDitherTypeBayer2x2, gfx.image.kDitherTypeBayer4x4, gfx.image.kDitherTypeBayer8x8, gfx.image.kDitherTypeDiagonalLine, gfx.image.kDitherTypeScreen }
local function pt() return rnd(W + 40) - 20, rnd(H + 40) - 20 end
local ops = {
  function() local x1, y1 = pt() local x2, y2 = pt() gfx.drawLine(x1, y1, x2, y2) return "line " .. x1 .. "," .. y1 .. "," .. x2 .. "," .. y2 end,
  function() local x, y = pt() local w, h = rnd(60) - 5, rnd(50) - 5 gfx.fillRect(x, y, w, h) return "fillRect " .. x .. "," .. y .. "," .. w .. "," .. h end,
  function() local x, y = pt() local w, h = rnd(60), rnd(50) gfx.drawRect(x, y, w, h) return "drawRect " .. x .. "," .. y .. "," .. w .. "," .. h end,
  function() local x, y = pt() local r = rnd(30) gfx.fillCircleAtPoint(x, y, r) return "fillCircle " .. x .. "," .. y .. "," .. r end,
  function() local x, y = pt() local r = rnd(30) gfx.drawCircleAtPoint(x, y, r) return "drawCircle " .. x .. "," .. y .. "," .. r end,
  function() local x, y = pt() local w, h = rnd(60), rnd(50) local r = rnd(12) gfx.fillRoundRect(x, y, w, h, r) return "fillRoundRect " .. x .. "," .. y .. "," .. w .. "," .. h .. "," .. r end,
  function() local x, y = pt() local w, h = rnd(60), rnd(50) local r = rnd(12) gfx.drawRoundRect(x, y, w, h, r) return "drawRoundRect " .. x .. "," .. y .. "," .. w .. "," .. h .. "," .. r end,
  function() local x, y = pt() local w, h = rnd(60) + 1, rnd(50) + 1 local a1, a2 = rnd(360), rnd(360) gfx.fillEllipseInRect(x, y, w, h, a1, a2) return "fillEllipse " .. x .. "," .. y .. "," .. w .. "," .. h .. "," .. a1 .. "," .. a2 end,
  function() local x, y = pt() local w, h = rnd(60) + 1, rnd(50) + 1 local a1, a2 = rnd(360), rnd(360) gfx.drawEllipseInRect(x, y, w, h, a1, a2) return "drawEllipse " .. x .. "," .. y .. "," .. w .. "," .. h .. "," .. a1 .. "," .. a2 end,
  function() local x, y = pt() local r = rnd(30) + 1 local a1, a2 = rnd(360), rnd(360) gfx.drawArc(x, y, r, a1, a2) return "drawArc " .. x .. "," .. y .. "," .. r .. "," .. a1 .. "," .. a2 end,
  function() local x1, y1 = pt() local x2, y2 = pt() local x3, y3 = pt() gfx.fillTriangle(x1, y1, x2, y2, x3, y3) return "fillTriangle " .. table.concat({x1, y1, x2, y2, x3, y3}, ",") end,
  function() local x1, y1 = pt() local x2, y2 = pt() local x3, y3 = pt() gfx.drawTriangle(x1, y1, x2, y2, x3, y3) return "drawTriangle " .. table.concat({x1, y1, x2, y2, x3, y3}, ",") end,
  function() local n = rnd(4) + 3 local p = {} for i = 1, n do local x, y = pt() p[#p + 1] = x p[#p + 1] = y end gfx.fillPolygon(table.unpack(p)) return "fillPolygon " .. table.concat(p, ",") end,
  function() local n = rnd(4) + 3 local p = {} for i = 1, n do local x, y = pt() p[#p + 1] = x p[#p + 1] = y end local poly = geom.polygon.new(table.unpack(p)) poly:close() gfx.drawPolygon(poly) return "drawPolygon " .. table.concat(p, ",") end,
  function() local c = colors[rnd(#colors) + 1] gfx.setColor(c) return "setColor " .. c end,
  function() local p = {} for i = 1, 8 do p[i] = rnd(256) end gfx.setPattern(p) return "setPattern " .. table.concat(p, ",") end,
  function() local a = rnd(100) / 100 local d = dithers[rnd(#dithers) + 1] gfx.setDitherPattern(a, d) return "setDither " .. a .. "," .. d end,
  function() local w = rnd(6) gfx.setLineWidth(w) return "lineWidth " .. w end,
  function() local s = rnd(3) gfx.setStrokeLocation(s) return "stroke " .. s end,
  function() local m = modes[rnd(#modes) + 1] gfx.setImageDrawMode(m) return "drawMode " .. m end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local f = flips[rnd(4) + 1] imgs[i]:draw(x, y, f) return "draw " .. i .. "," .. x .. "," .. y .. "," .. f end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local s = rf(0.2, 3) local s2 = rnd(2) == 0 and s or rf(0.2, 3) imgs[i]:drawScaled(x, y, s, s2) return "drawScaled " .. i .. "," .. x .. "," .. y .. "," .. s .. "," .. s2 end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local a = rnd(8) * 45 + (rnd(3) == 0 and rf(0, 40) or 0) local s = rnd(2) == 0 and 1 or rf(0.3, 2.5) imgs[i]:drawRotated(x, y, a, s) return "drawRotated " .. i .. "," .. x .. "," .. y .. "," .. a .. "," .. s end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local a = rf(0, 1) local d = dithers[rnd(#dithers) + 1] imgs[i]:drawFaded(x, y, a, d) return "drawFaded " .. i .. "," .. x .. "," .. y .. "," .. a .. "," .. d end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local w, h = rnd(80), rnd(60) imgs[i]:drawTiled(x, y, w, h, flips[rnd(4) + 1]) return "drawTiled " .. i .. "," .. x .. "," .. y .. "," .. w .. "," .. h end,
  function() local x, y = pt() local w, h = rnd(100), rnd(80) gfx.setClipRect(x, y, w, h) return "clip " .. x .. "," .. y .. "," .. w .. "," .. h end,
  function() gfx.clearClipRect() return "clearClip" end,
  function() local x, y = rnd(30) - 15, rnd(30) - 15 gfx.setDrawOffset(x, y) return "offset " .. x .. "," .. y end,
  function() local x, y = pt() local s = ({ "Hello", "*Bold* text", "_It_", "Wrap me in a box please", "12345" })[rnd(5) + 1] gfx.drawText(s, x, y) return "drawText " .. s .. "," .. x .. "," .. y end,
  function() local x, y = pt() local w, h = rnd(80) + 5, rnd(40) + 5 local s = "The quick brown fox jumps over the lazy dog" gfx.drawTextInRect(s, x, y, w, h, nil, "...", rnd(3)) return "textInRect " .. x .. "," .. y .. "," .. w .. "," .. h end,
  function() local x, y = pt() gfx.drawPixel(x, y) return "pixel " .. x .. "," .. y end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() imgs[i]:drawCentered(x, y) return "drawCentered " .. i .. "," .. x .. "," .. y end,
  function() local i = rnd(#imgs) + 1 local x, y = pt() local sx, sy, sw, sh = rnd(10), rnd(8), rnd(15) + 1, rnd(12) + 1 imgs[i]:draw(x, y, flips[rnd(4) + 1], sx, sy, sw, sh) return "drawSource " .. i .. "," .. x .. "," .. y .. "," .. sx .. "," .. sy .. "," .. sw .. "," .. sh end,
}
local seeds = {} for s = 9, 48 do seeds[#seeds + 1] = s end
for _, sd in ipairs(seeds) do
  seed = sd * 7919
  gfx.pushContext(target)
  gfx.clear(gfx.kColorWhite)
  gfx.setDrawOffset(0, 0) gfx.clearClipRect() gfx.setColor(gfx.kColorBlack) gfx.setLineWidth(1) gfx.setImageDrawMode(gfx.kDrawModeCopy) gfx.setStrokeLocation(gfx.kStrokeCentered)
  for i = 1, 150 do
    local op = ops[rnd(#ops) + 1]
    local ok, desc = pcall(op)
    local ox, oy = gfx.getDrawOffset()
    local st = "mode=" .. tostring(gfx.getImageDrawMode()) .. " off=" .. ox .. "," .. oy .. " clip=" .. table.concat({gfx.getClipRect()}, ",") .. " lw=" .. gfx.getLineWidth()
    gfx.popContext()
    fh:write(sd .. " " .. i .. " " .. tostring(ok) .. " " .. tostring(desc) .. " " .. hash() .. " " .. st .. "\n")
    gfx.pushContext(target)
  end
  gfx.popContext()
end
fh:close()
function playdate.update() end
