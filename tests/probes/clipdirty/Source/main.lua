-- Probe: which image changes redraw a sprite showing that image, with no markDirty:
-- A: pushContext + fillRect; B: image:clear only (alternating colors); C: pushContext/popContext with no drawing,
-- after the image was changed by clear in the previous frame... D: drawing into a copy (control).
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out, frame = {}, 0
local function mk(x) local im = gfx.image.new(20, 10, gfx.kColorWhite); local s = gfx.sprite.new(im); s:setCenter(0, 0); s:moveTo(x, 10); s:add(); return im end
local A, B, C, D = mk(10), mk(60), mk(110), mk(160)
local Dcopy = D:copy()
function playdate.update()
  frame = frame + 1
  gfx.pushContext(A); gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(frame % 20, 0, 1, 10); gfx.popContext()
  B:clear(frame % 2 == 0 and gfx.kColorBlack or gfx.kColorWhite)
  if frame % 2 == 0 then C:clear(gfx.kColorBlack) else gfx.pushContext(C); gfx.popContext() end
  gfx.pushContext(Dcopy); gfx.clear(gfx.kColorBlack); gfx.popContext()
  gfx.sprite.update()
  local d = gfx.getWorkingImage()
  local function col(x0) for x = 0, 19 do if d:sample(x0 + x, 15) == gfx.kColorBlack then return x end end return -1 end
  out[#out + 1] = string.format("%d A=%d B=%d C=%d D=%d", frame, col(10), col(60), col(110), col(160))
  if frame == 8 then
    local fh = playdate.file.open("clipdirty.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
