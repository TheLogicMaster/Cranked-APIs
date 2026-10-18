-- Probe: drawText in each image draw mode, with a bordered bitmap font (namco-1x, from the SDK's Particles
-- example) and the system font, over a background half black and half white. Writes the pixels as text.
local gfx = playdate.graphics
local fonts = { gfx.font.new("font/namco-1x"), gfx.getSystemFont() }
local frame = 0
function playdate.update()
  frame += 1
  if frame ~= 3 then return end
  gfx.clear(gfx.kColorWhite)
  local out = playdate.file.open("txtmode.txt", playdate.file.kFileWrite)
  for fi, font in ipairs(fonts) do
    for mode = 0, 7 do
      local y = (fi - 1) * 120 + mode * 14
      gfx.setImageDrawMode(gfx.kDrawModeCopy)
      gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, y, 200, 14)
      gfx.setFont(font)
      gfx.setImageDrawMode(mode)
      gfx.drawText("Ab1", 2, y + 1)
      gfx.drawText("Ab1", 202, y + 1)
    end
  end
  gfx.setImageDrawMode(gfx.kDrawModeCopy)
  local img = gfx.getWorkingImage()
  for y = 0, 239 do
    local row = {}
    for x = 0, 79 do
      local sx = x < 40 and x or x + 160 -- 0..39 over black, 200..239 over white
      row[#row + 1] = img:sample(sx, y) == gfx.kColorBlack and "#" or "."
    end
    out:write(table.concat(row) .. "\n")
  end
  out:close()
end
