-- Probe: a black screen, Inverted draw mode, a bordered bitmap font with tracking -1 and 0, then the pixels
-- as text
local gfx = playdate.graphics
local font = gfx.font.new("font/namco-1x")
local frame = 0
function playdate.update()
  frame += 1
  if frame ~= 3 then return end
  gfx.clear(gfx.kColorBlack)
  gfx.setImageDrawMode(gfx.kDrawModeInverted)
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRect(playdate.geometry.rect.new(170, 90, 60, 60))
  gfx.setFont(font)
  gfx.setFontTracking(-1)
  gfx.drawText("count: 20", 4, 2)
  gfx.setFontTracking(0)
  gfx.drawText("count: 20", 4, 22)
  gfx.setImageDrawMode(gfx.kDrawModeCopy)
  local img = gfx.getWorkingImage()
  local out = playdate.file.open("txt.txt", playdate.file.kFileWrite)
  for y = 0, 40 do
    local row = {}
    for x = 0, 79 do row[#row + 1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end
    out:write(table.concat(row) .. "\n")
  end
  out:close()
end
