-- Probe: lines with ends off the target or outside the clip rect (pixel lists)
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local W, H = 64, 48
local seed = 99
local function rnd(n) seed = (seed * 16807) % 2147483647 return math.floor(seed % n) end
local function run(name, x1, y1, x2, y2, clip)
  local img = gfx.image.new(W, H, gfx.kColorWhite)
  gfx.pushContext(img)
  if clip then gfx.setClipRect(clip[1], clip[2], clip[3], clip[4]) end
  gfx.drawLine(x1, y1, x2, y2)
  gfx.popContext()
  local p = {}
  for y = 0, H - 1 do for x = 0, W - 1 do if img:sample(x, y) == gfx.kColorBlack then p[#p+1] = x .. ":" .. y end end end
  fh:write(name .. " " .. table.concat({x1, y1, x2, y2}, ",") .. (clip and (" clip " .. table.concat(clip, ",")) or "") .. " | " .. table.concat(p, " ") .. "\n")
end
run("X1", -20, 5, 172, -20)
run("X2", -20, 5, 60, -20)
run("X3", -5, 5, 60, -20)
run("X4", 0, 5, 172, -20)
run("X5", 10, 5, 172, -20)
run("X6", -20, 5, 172, -2)
for i = 1, 300 do
  local x1, y1, x2, y2 = rnd(400) - 170, rnd(300) - 126, rnd(400) - 170, rnd(300) - 126
  run("L" .. i, x1, y1, x2, y2)
end
for i = 1, 400 do
  local x1, y1 = rnd(100) - 18, rnd(80) - 16
  local x2 = rnd(2) == 0 and (W + 3 + rnd(150)) or (-3 - rnd(150))
  local y2 = rnd(2) == 0 and (H + 3 + rnd(100)) or (-3 - rnd(100))
  if rnd(2) == 0 then x1, y1, x2, y2 = x2, y2, x1, y1 end
  run("K" .. i, x1, y1, x2, y2)
end
for i = 1, 150 do
  local x1, y1, x2, y2 = rnd(120) - 28, rnd(100) - 26, rnd(120) - 28, rnd(100) - 26
  run("C" .. i, x1, y1, x2, y2, { 10, 8, 40, 30 })
end
fh:close()
function playdate.update() end
