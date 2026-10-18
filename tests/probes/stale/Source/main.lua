-- Probe: does text drawn straight to the frame survive sprite.update once the game stops drawing it?
-- Variants run one after another; each draws text for 5 frames, stops, and samples the text area 5 frames later.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local variants = {
  "none", "offset00_in_sprite", "offset00_before", "offset11_before", "drawoffset00", "no_sprites",
  "offset_once", "bgcolor_black", "no_update", "late_start", "bg_callback",
}
local out = {}
local v, f, spr = 1, 0, nil
local function setup(name)
  gfx.sprite.removeAll()
  playdate.display.setOffset(0, 0); gfx.setBackgroundColor(gfx.kColorWhite)
  gfx.clear(gfx.kColorWhite)
  if name ~= "no_sprites" then
    spr = gfx.sprite.new(); spr:setSize(10, 10); spr:moveTo(20, 20)
    function spr:update() if name == "offset00_in_sprite" then playdate.display.setOffset(0, 0) end end
    spr:add()
  end
  if name == "bg_callback" then gfx.sprite.setBackgroundDrawingCallback(function() end) end
  if name == "bgcolor_black" then gfx.setBackgroundColor(gfx.kColorBlack) end
end
local function count()
  local img = gfx.getDisplayImage(); local n = 0
  for y = 115, 140 do for x = 150, 250 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end
  return n
end
setup(variants[1])
function playdate.update()
  local name = variants[v]
  if name == "offset00_before" then playdate.display.setOffset(0, 0) end
  if name == "offset11_before" then playdate.display.setOffset(1, 1) end
  if name == "drawoffset00" then gfx.setDrawOffset(0, 0) end
  if name == "offset_once" and f == 5 then playdate.display.setOffset(0, 0) end
  if name ~= "no_update" then gfx.sprite.update() end
  local s0 = (name == "late_start") and 3 or 0
  if f >= s0 and f < 5 then gfx.drawTextAligned("Press A to Start", 200, 120, kTextAlignment.center) end
  if f == 4 then out[#out + 1] = name .. "\tdrawn=" .. count() end
  if f == 10 then
    out[#out] = out[#out] .. "\tafter=" .. count()
    v = v + 1; f = -1
    if v > #variants then
      local fh = playdate.file.open("stale.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
      if playdate.simulator then playdate.simulator.exit() end; playdate.stop(); return
    end
    setup(variants[v])
  end
  f = f + 1
end
