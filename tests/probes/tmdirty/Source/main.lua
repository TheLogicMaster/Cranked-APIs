-- Probe: does setTileAtPosition on a sprite's tilemap redraw the sprite without markDirty?
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out, frame = {}, 0
local it = gfx.imagetable.new(2)
local a = gfx.image.new(8, 8, gfx.kColorWhite); local b = gfx.image.new(8, 8, gfx.kColorBlack)
it:setImage(1, a); it:setImage(2, b)
local tm = gfx.tilemap.new(); tm:setImageTable(it); tm:setSize(4, 1)
for i = 1, 4 do tm:setTileAtPosition(i, 1, 1) end
local s = gfx.sprite.new(); s:setTilemap(tm); s:setCenter(0, 0); s:moveTo(0, 0); s:add()
function playdate.update()
  frame = frame + 1
  if frame >= 2 and frame <= 5 then tm:setTileAtPosition(frame - 1, 1, 2) end
  if frame == 6 then tm:setTiles({1, 1, 1, 1}, 4) end
  gfx.sprite.update()
  local d = gfx.getWorkingImage(); local t = {}
  for i = 0, 3 do t[#t + 1] = d:sample(i * 8 + 3, 3) == gfx.kColorBlack and "1" or "0" end
  out[#out + 1] = frame .. "|" .. table.concat(t)
  if frame == 7 then
    local fh = playdate.file.open("tmdirty.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
