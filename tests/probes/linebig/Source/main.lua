-- Lines starting above the clip top with extreme coordinates
local gfx = playdate.graphics
math.randomseed(12345)
local function rnd(n) return math.random(0, n - 1) end
local big = { -2147483648, -2147483647, -1073741824, -100000, -1000, -1, 0, 1, 240, 399, 1000, 100000, 1073741824, 2147483646, 2147483647 }
local function pick()
  if rnd(3) == 0 then return big[rnd(#big) + 1] end
  return rnd(1200) - 400
end
local out = {}
for i = 1, 400 do
  gfx.clear(gfx.kColorWhite)
  if i % 3 == 0 then gfx.setClipRect(rnd(200), rnd(120), rnd(300), rnd(200)) else gfx.clearClipRect() end
  if i % 5 == 0 then gfx.setDrawOffset(rnd(100) - 50, rnd(100) - 50) else gfx.setDrawOffset(0, 0) end
  local x1, y1, x2, y2 = pick(), pick(), pick(), pick()
  gfx.setColor(gfx.kColorBlack)
  gfx.drawLine(x1, y1, x2, y2)
  local img = gfx.getWorkingImage()
  local sum = 0
  for y = 0, 239, 1 do
    for x = 0, 399, 7 do
      if img:sample(x, y) == gfx.kColorBlack then sum = (sum * 31 + x * 977 + y) % 1000000007 end
    end
  end
  out[#out + 1] = string.format("%d %d %d %d %d %d", i, x1, y1, x2, y2, sum)
end
gfx.clearClipRect(); gfx.setDrawOffset(0, 0)
print(table.concat(out, "\n"))
print("linebig done")
function playdate.update() end
