-- Probe: does playdate.display.setInverted change getDisplayImage / getWorkingImage contents?
local gfx = playdate.graphics
local out, frame = {}, 0
local function px(img) return (img:sample(0, 0) == gfx.kColorBlack and "B" or "W") .. (img:sample(10, 10) == gfx.kColorBlack and "B" or "W") end
function playdate.update()
  frame = frame + 1
  gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 5, 5)
  if frame >= 3 and frame <= 5 then playdate.display.setInverted(true) end
  if frame == 6 then playdate.display.setInverted(true); playdate.display.setInverted(true) end
  if frame == 7 then playdate.display.setInverted(false) end
  out[#out + 1] = string.format("%d inv=%s display=%s working=%s", frame, tostring(playdate.display.getInverted and playdate.display.getInverted()), px(gfx.getDisplayImage()), px(gfx.getWorkingImage()))
  if frame == 10 then
    local fh = playdate.file.open("dispinv.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
    playdate.stop()
  end
end
