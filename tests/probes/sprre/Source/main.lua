-- Probe: sprite.update called again from inside the background drawing callback and a sprite's draw
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local bg, draws, nested, frame = 0, 0, 0, 0
local s = gfx.sprite.new()
s:setSize(20, 20); s:moveTo(100, 100); s:add()
function s:draw(x, y, w, h) draws += 1 gfx.fillRect(0, 0, 20, 20) if draws < 4 then nested += 1 gfx.sprite.update() end end
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) bg += 1 if bg < 5 then gfx.sprite.update() end end)
function playdate.update()
  frame += 1
  local ok, err = pcall(gfx.sprite.update)
  out:write(string.format("frame %d ok %s err %s bg %d draws %d nested %d\n", frame, tostring(ok), tostring(err), bg, draws, nested))
  if frame == 3 then s:moveTo(120, 100) end
  if frame == 5 then out:close() end
end
