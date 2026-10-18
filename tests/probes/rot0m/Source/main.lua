local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
for _, n in ipairs({"u1", "u2"}) do
  local i = gfx.image.new(n)
  fh:write(n .. " loaded hasMask " .. tostring(i:hasMask()) .. " maskImage " .. tostring(i:getMaskImage() ~= nil) .. "\n")
  for _, a in ipairs({0, 90, 180, 0.005}) do
    for _, sc in ipairs({1, 1.5, 0.75}) do
      local r = i:rotatedImage(a, sc)
      local w, h = r:getSize()
      local m = r:getMaskImage()
      local last = {}
      for y = 0, h - 1 do last[#last+1] = (r:sample(w - 1, y) == gfx.kColorBlack and "#") or (r:sample(w - 1, y) == gfx.kColorWhite and ".") or " " end
      fh:write(n .. " " .. a .. " " .. sc .. " size " .. w .. " " .. h .. " mask " .. tostring(m ~= nil) .. " lastcol " .. table.concat(last) .. "\n")
    end
  end
end
fh:close()
function playdate.update() end
