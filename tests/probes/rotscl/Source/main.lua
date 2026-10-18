-- Probe: drawRotated with angle 0 and a scale, and nearby cases
local gfx = playdate.graphics
local out = {}
local function p(...) local t = {} for i = 1, select('#', ...) do t[#t+1] = tostring((select(i, ...))) end out[#out+1] = table.concat(t, " ") end
local src = gfx.image.new("figure")
local small = gfx.image.new(9, 7, gfx.kColorClear)
gfx.pushContext(small) for y = 0, 6 do for x = 0, 8 do if (x * 3 + y * 5) % 4 < 2 then gfx.setColor(gfx.kColorBlack) else gfx.setColor(gfx.kColorWhite) end gfx.drawPixel(x, y) end end gfx.popContext()
local function hash(img)
  local rows = {}
  for y = 0, 239 do local h = 0 for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then h = (h * 31 + x + 1) % 1000003 end end rows[#rows+1] = h end
  return rows
end
local function test(name, f)
  local img = gfx.image.new(400, 240, gfx.kColorWhite)
  gfx.pushContext(img) local ok, e = pcall(f) gfx.popContext()
  local rows = hash(img)
  local all = 0 for _, h in ipairs(rows) do all = (all * 17 + h) % 1000003 end
  p(name, ok, e, all)
  out[#out+1] = "  " .. table.concat(rows, ",")
end
for _, im in ipairs({{"t", src}, {"s", small}}) do
  local n, i = im[1], im[2]
  for _, sc in ipairs({0.75, 0.5, 1, 1.5, 2, 0.33, 0.9}) do
    test(n .. " rot0 " .. sc, function() i:drawRotated(150, 115, 0, sc) end)
    test(n .. " rot0 xy " .. sc, function() i:drawRotated(150, 115, 0, sc, sc * 0.8) end)
    test(n .. " rot360 " .. sc, function() i:drawRotated(150, 115, 360, sc) end)
    test(n .. " rot90 " .. sc, function() i:drawRotated(150, 115, 90, sc) end)
    test(n .. " rot180 " .. sc, function() i:drawRotated(150, 115, 180, sc) end)
    test(n .. " rot0.1 " .. sc, function() i:drawRotated(150, 115, 0.1, sc) end)
    test(n .. " rotimg " .. sc, function() i:rotatedImage(0, sc):draw(10, 10) end)
    test(n .. " scaled " .. sc, function() i:drawScaled(10, 10, sc) end)
  end
end
local f = playdate.file.open("out.txt", playdate.file.kFileWrite) f:write(table.concat(out, "\n") .. "\n") f:close()
function playdate.update() end
