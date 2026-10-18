-- Probe: transformedImage sizes and pixels
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
for _, n in ipairs({"u1", "c1"}) do
  local i = gfx.image.new(n)
  for _, t in ipairs({{"s", 0.75}, {"s", 1.5}, {"s", 2.5}, {"s", 0.33}, {"r", 30}, {"r", 90}, {"sxy", 2, 0.5}, {"sk", 0.3, 0}, {"t", 3, 4}}) do
    local xf = playdate.geometry.affineTransform.new()
    if t[1] == "s" then xf:scale(t[2]) elseif t[1] == "r" then xf:rotate(t[2]) elseif t[1] == "sxy" then xf:scale(t[2], t[3]) elseif t[1] == "sk" then xf:skew(t[2], t[3]) else xf:translate(t[2], t[3]) end
    local r = i:transformedImage(xf)
    local w, h = r:getSize()
    fh:write(n .. " " .. table.concat(t, ",") .. " size " .. w .. " " .. h .. "\n")
    for y = 0, h - 1 do local row = {} for x = 0, w - 1 do local c = r:sample(x, y) row[#row+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(row) .. "\n") end
  end
end
fh:close()
function playdate.update() end
