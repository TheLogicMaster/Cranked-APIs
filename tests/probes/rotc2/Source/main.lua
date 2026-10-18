-- Probe (the Simulator as reference): which drawing method reproduces a rotated sprite's pixels?
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(6, 14, gfx.kColorWhite)
gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillRect(1, 0, 4, 14); gfx.fillRect(0, 10, 6, 4); gfx.popContext()
local angles = { 30, 45, -20, 60, 10, 75, 135, 200, -100, 17, 33.3, 290 }
local centers = { { 0.5, 0.5 }, { 0.5, 1 }, { 0.2, 0.7 } }
local cases = {}
local i = 0
for _, c in ipairs(centers) do for _, a in ipairs(angles) do
  i = i + 1
  local x, y = 20 + ((i - 1) % 9) * 44 + 0.3 * (i % 3), 24 + ((i - 1) // 9) * 50 + 0.4 * (i % 2)
  local s = gfx.sprite.new(img); s:setCenter(c[1], c[2]); s:moveTo(x, y); s:setRotation(a); s:add()
  cases[#cases + 1] = { s = s, a = a, c = c, x = x, y = y }
end end
local function grab(d, x0, y0) local t = {}; for yy = 0, 29 do for xx = 0, 29 do t[#t + 1] = d:sample(x0 + xx, y0 + yy) == gfx.kColorBlack and 1 or 0 end end; return t end
local function render(fn) gfx.clear(gfx.kColorWhite); fn(); return gfx.getWorkingImage() end
local f, out = 0, {}
function playdate.update()
  f = f + 1; gfx.sprite.update()
  if f == 3 then
    local d = gfx.getDisplayImage():copy()
    gfx.sprite.removeAll()
    for k, c in ipairs(cases) do
      local bx, by = c.s:getBounds()
      local x0, y0 = math.floor(bx) - 8, math.floor(by) - 8
      local ref = grab(d, x0, y0)
      local r = img:rotatedImage(c.a)
      local cand = {
        floor = function() r:draw(math.floor(bx), math.floor(by)) end,
        round = function() r:draw(math.floor(bx + 0.5), math.floor(by + 0.5)) end,
        ceil = function() r:draw(math.ceil(bx), math.ceil(by)) end,
        drawRotated_mid = function() img:drawRotated(bx + c.s.width / 2, by + c.s.height / 2, c.a) end,
        transform_mid = function() local t = playdate.geometry.affineTransform.new(); t:rotate(c.a); img:drawWithTransform(t, bx + c.s.width / 2, by + c.s.height / 2) end,
      }
      local line = {}
      for _, name in ipairs({ "floor", "round", "ceil", "drawRotated_mid", "transform_mid" }) do
        local w = render(cand[name]); local t = grab(w, x0, y0); local n = 0
        for q = 1, #t do if t[q] ~= ref[q] then n = n + 1 end end
        line[#line + 1] = name .. "=" .. n
      end
      out[#out + 1] = string.format("a=%g c=%g,%g b=%.3f,%.3f\t%s", c.a, c.c[1], c.c[2], bx, by, table.concat(line, " "))
    end
    local fh = playdate.file.open("rotc2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
