-- Probe: when does sprite.update redraw direct draws? Varies sprites present, background color, and history.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local function region(x0, y0, x1, y1) -- returns "black/total"
  local img = gfx.getDisplayImage(); local n, t = 0, 0
  for y = y0, y1 do for x = x0, x1 do t = t + 1; if img:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end
  return n .. "/" .. t
end
-- each variant: setup(), then per-frame step(f) for 6 frames; sample at the start of frame 7
local function addSprite() local s = gfx.sprite.new(); s:setSize(4, 4); s:moveTo(390, 230); s:add(); return s end
local function white() gfx.setColor(gfx.kColorWhite); gfx.fillRect(10, 10, 30, 30); gfx.setColor(gfx.kColorBlack) end
local BG = function() gfx.setBackgroundColor(gfx.kColorBlack) end
local CL = function() gfx.clear(gfx.kColorWhite) end
local U = function(f) gfx.sprite.update() end
local variants = {
  { "1 before any sprite: bg,rect | upd", function() BG(); white() end, U },
  { "2 before: clear,bg | upd", function() CL(); BG() end, U },
  { "3 sprite.new only (not added)", function() local s = gfx.sprite.new(); s:setSize(4, 4); s:moveTo(390, 230) end, U },
  { "4 after new only: bg,rect | upd", function() BG(); white() end, U },
  { "5 sprite added then removed same frame", function() local s = addSprite(); s:remove() end, U },
  { "6 after add+remove: bg,rect | upd", function() BG(); white() end, U },
  { "7 sprite added and updated", function() addSprite() end, U },
  { "8 after: bg,rect | upd", function() BG(); white() end, U },
  { "9 after: clear,bg | upd", function() CL(); BG() end, U },
}
local out, v, f = {}, 1, 0
function playdate.update()
  local c = variants[v]
  if not c then
    local fh = playdate.file.open("s4.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop(); return
  end
  if f == 0 then
    gfx.sprite.removeAll(); gfx.setBackgroundColor(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.clear(gfx.kColorWhite)
    gfx.sprite.update() -- settle the reset
    c[2]()
  elseif f <= 6 then c[3](f)
  else
    out[#out + 1] = c[1] .. "\trect=" .. region(10, 10, 39, 39) .. "\tfar=" .. region(200, 100, 209, 109)
    v = v + 1; f = -1
  end
  f = f + 1
end
