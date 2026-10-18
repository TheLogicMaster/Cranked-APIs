-- Probe: the rect passed to a Lua sprite draw callback, for fractional positions and partial redraws.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local log, frame = {}, 0
local function mk(name, w, h, x, y, cx, cy)
  local s = gfx.sprite.new(); s:setSize(w, h); if cx then s:setCenter(cx, cy) end; s:moveTo(x, y)
  function s:draw(a, b, c, d) log[#log + 1] = string.format("f%d %s\t%g,%g,%g,%g\tbounds=%s", frame, name, a, b, c, d, tostring(s:getBoundsRect())) end
  s:add(); return s
end
local odd = mk("odd_w57_at200", 57, 30, 200, 72)
local even = mk("even_w56_at200", 56, 30, 200, 140)
local frac = mk("frac_x100.3", 20, 20, 100.3, 200.7)
local corner = mk("center00_at10.5", 21, 11, 10.5, 10.5, 0, 0)
function playdate.update()
  frame = frame + 1
  if frame == 3 then gfx.sprite.addDirtyRect(190, 60, 30, 10); gfx.sprite.addDirtyRect(100, 140, 5, 5) end
  if frame == 4 then odd:markDirty() end
  if frame == 5 then gfx.sprite.addDirtyRect(171, 57, 4, 4) end
  gfx.sprite.update()
  if frame == 6 then
    local fh = playdate.file.open("args.txt", playdate.file.kFileWrite); fh:write(table.concat(log, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
