-- Probe: mirrored scales of images whose stored data is trimmed
local gfx = playdate.graphics
local out = {}
local function dump(name, f)
  local img = gfx.image.new(120, 90, gfx.kColorClear)
  gfx.pushContext(img) local ok, e = pcall(f) gfx.popContext()
  out[#out+1] = name .. " " .. tostring(ok) .. " " .. tostring(e)
  for y = 0, 89 do local r = {} for x = 0, 119 do local c = img:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end out[#out+1] = table.concat(r) end
end
for _, n in ipairs({"c1", "c2", "c3"}) do
  local i = gfx.image.new(n)
  for _, sc in ipairs({0.75, 0.5, 1, 1.5, 2.5, 0.33}) do
    dump(n .. " nn " .. sc, function() i:drawScaled(5, 6, -sc, -sc) end)
    dump(n .. " np " .. sc, function() i:drawScaled(5, 6, -sc, sc) end)
    dump(n .. " pn " .. sc, function() i:drawScaled(5, 6, sc, -sc) end)
    dump(n .. " r180 " .. sc, function() i:drawRotated(50, 40, 180, sc) end)
  end
end
local f = playdate.file.open("out.txt", playdate.file.kFileWrite) f:write(table.concat(out, "\n") .. "\n") f:close()
function playdate.update() end
