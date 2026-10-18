local gfx = playdate.graphics
local small = gfx.image.new(16, 16, gfx.kColorBlack)
function playdate.update()
  for i = 1, 20000 do small:draw(i % 380, i % 220) end
  for i = 1, 500 do gfx.drawText("Hello world", 10, 10) end
end
