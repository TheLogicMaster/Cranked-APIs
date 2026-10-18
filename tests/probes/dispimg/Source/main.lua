-- Probe: which frame getDisplayImage returns during update, with and without sprites, before and after drawing.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local frame, out = 0, {}
local function bar(img) -- which of 8 slots in row 0 are black
  local s = {}
  for i = 0, 7 do s[#s + 1] = img:sample(i * 10 + 2, 2) == gfx.kColorBlack and "1" or "0" end
  return table.concat(s)
end
local spr
function playdate.update()
  frame = frame + 1
  local before = bar(gfx.getDisplayImage())
  if frame <= 4 then
    gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect((frame % 8) * 10, 0, 10, 10)
  elseif frame <= 8 then
    if not spr then
      gfx.clear(gfx.kColorWhite)
      local im = gfx.image.new(10, 10, gfx.kColorBlack); spr = gfx.sprite.new(im); spr:setCenter(0, 0); spr:add()
      gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) gfx.setColor(gfx.kColorWhite); gfx.fillRect(x, y, w, h) end)
    end
    spr:moveTo((frame % 8) * 10, 0); gfx.sprite.update()
  end
  local after = bar(gfx.getDisplayImage())
  local work = bar(gfx.getWorkingImage())
  out[#out + 1] = string.format("f%d|before=%s after=%s working=%s", frame, before, after, work)
  if frame == 10 then
    local fh = playdate.file.open("dispimg.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
