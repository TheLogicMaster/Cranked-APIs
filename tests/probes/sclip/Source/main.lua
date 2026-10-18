-- Probe: sprite clip rects away from the origin, with centers, offsets, and ratios.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local img = gfx.image.new(20, 20, gfx.kColorBlack)
local cases = {}
local function case(name, x, y, setup) cases[#cases + 1] = { name = name, x = x, y = y, setup = setup } end
case("center00_clip_full", 40, 40, function(s) s:setCenter(0, 0); s:setClipRect(s.x, s.y, 20, 20) end)
case("center00_clip_half", 100, 40, function(s) s:setCenter(0, 0); s:setClipRect(s.x, s.y, 20, 10) end)
case("center_default_clip_at_pos", 160, 40, function(s) s:setClipRect(s.x, s.y, 20, 20) end)
case("clip_local_coords", 220, 40, function(s) s:setCenter(0, 0); s:setClipRect(0, 0, 20, 20) end)
case("clip_then_move", 280, 40, function(s) s:setCenter(0, 0); s:setClipRect(280, 40, 20, 20); s:moveTo(290, 50) end)
case("clip_fraction", 340, 40, function(s) s:setCenter(0, 0); s:setClipRect(s.x, s.y, 20, 7.5) end)
case("fields", 40, 120, function(s) s:setCenter(0, 0); s:setClipRect(s.x, s.y, s.width, s.height * 0.5) end)
case("drawoffset", 100, 120, function(s) s:setCenter(0, 0); s:setClipRect(s.x, s.y, 20, 20) end)
local sprites = {}
for _, c in ipairs(cases) do local s = gfx.sprite.new(img); s:moveTo(c.x, c.y); c.setup(s); s:add(); sprites[#sprites + 1] = s end
local f = 0
function playdate.update()
  f = f + 1
  gfx.sprite.update()
  if f == 3 then
    local d = gfx.getDisplayImage(); local out = {}
    for _, c in ipairs(cases) do
      local n, minx, miny, maxx, maxy = 0, 999, 999, -1, -1
      for y = c.y - 25, c.y + 35 do for x = c.x - 25, c.x + 35 do
        if d:sample(x, y) == gfx.kColorBlack then n = n + 1; minx = math.min(minx, x); maxx = math.max(maxx, x); miny = math.min(miny, y); maxy = math.max(maxy, y) end
      end end
      out[#out + 1] = c.name .. "\tblack=" .. n .. (n > 0 and string.format(" box=%d,%d-%d,%d", minx, miny, maxx, maxy) or "")
    end
    out[#out + 1] = "width field=" .. tostring(sprites[7].width) .. " height field=" .. tostring(sprites[7].height)
    local fh = playdate.file.open("sclip.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
