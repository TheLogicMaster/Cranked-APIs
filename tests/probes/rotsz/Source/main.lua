-- Probe: rotatedImage sizes over a grid of angles and scales, two source sizes
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
for _, sz in ipairs({ {37, 29}, {20, 10}, {16, 16} }) do
  local src = gfx.image.new(sz[1], sz[2], gfx.kColorBlack)
  for _, a in ipairs({ 0, 10, 30, 45, 60, 90, 135, 200, 270, 333 }) do
    for _, s in ipairs({ 0.5, 0.75, 1, 1.3, 2, 0.33 }) do
      local im = src:rotatedImage(a, s) local w, h = im:getSize()
      out:write(string.format("%dx%d %d %.2f\t%dx%d\n", sz[1], sz[2], a, s, w, h))
    end
  end
end
out:close()
function playdate.update() end
