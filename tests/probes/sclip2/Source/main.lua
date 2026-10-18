-- Probe: per-frame clip rect updates on a sprite, combined with visibility changes.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(20, 20, gfx.kColorBlack)
local cases = {}
local function case(name, x, perFrame, init) cases[#cases + 1] = { name = name, x = x, perFrame = perFrame, init = init } end
local Y = 60
case("grow_visible", 20, function(s, f) s:setClipRect(s.x, s.y, 20, f) end)
case("grow_then_setVisible", 60, function(s, f) s:setClipRect(s.x, s.y, 20, f); s:setVisible(true) end)
case("hidden_until_5", 100, function(s, f) s:setClipRect(s.x, s.y, 20, f); s:setVisible(f >= 5) end, function(s) s:setVisible(false) end)
case("const_clip_each_frame", 140, function(s, f) s:setClipRect(s.x, s.y, 20, 6) end)
case("clip_once", 180, function(s, f) if f == 1 then s:setClipRect(s.x, s.y, 20, 6) end end)
case("clip_frac_grow", 220, function(s, f) s:setClipRect(s.x, s.y, 20, f * 0.7) end)
case("start_invisible_clip_set", 260, function(s, f) if f == 1 then s:setClipRect(s.x, s.y, 20, 6) end; if f == 3 then s:setVisible(true) end end, function(s) s:setVisible(false) end)
case("zero_then_grow", 300, function(s, f) s:setClipRect(s.x, s.y, 20, f - 1) end)
case("clip_before_add", 340, function(s, f) end, function(s) s:setClipRect(s.x, s.y, 20, 6) end)
local list = {}
for _, c in ipairs(cases) do
  local s = gfx.sprite.new(img); s:moveTo(c.x, Y); s:setCenter(0, 0)
  if c.init then c.init(s) end
  s:add(); list[#list + 1] = s
end
local f, out = 0, {}
local function measure(tag)
  local d = gfx.getDisplayImage()
  for i, c in ipairs(cases) do
    local rows = 0
    for y = Y, Y + 19 do if d:sample(c.x + 10, y) == gfx.kColorBlack then rows = rows + 1 end end
    out[#out + 1] = tag .. "\t" .. c.name .. "\trows=" .. rows
  end
end
function playdate.update()
  f = f + 1
  for i, c in ipairs(cases) do c.perFrame(list[i], f) end
  gfx.sprite.update()
  if f == 3 or f == 8 then measure("f" .. f) end
  if f == 8 then
    local fh = playdate.file.open("sclip2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
