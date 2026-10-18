-- Probe: swapped metatables on native objects - leaks, and another type's __gc on an object
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local mode = playdate.file.exists("mode2") and 2 or 1
local frame = 0
function playdate.update()
  frame = frame + 1
  if frame <= 30 then
    for i = 1, 200 do
      local img = gfx.image.new(64, 64)
      if mode == 1 then setmetatable(img, {}) -- loses the image's __gc
      else setmetatable(img, getmetatable(playdate.sound.synth.new())) end -- a synth's __gc on an image
    end
    collectgarbage("collect")
  end
  if frame == 31 then
    fh:write("mode " .. mode .. " lua KB " .. math.floor(collectgarbage("count")) .. "\n")
    fh:close()
  end
end
