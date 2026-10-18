-- Lua drawLine with an explicit width argument, drawLine(lineSegment, width), and lines entering the clip rect from
-- above whose x range misses the clip: row dumps of the drawn pixels.
local gfx = playdate.graphics
local out = {}
local function dump(tag)
  local img = gfx.getWorkingImage()
  local px = {}
  for y = 0, 239 do
    for x = 0, 399 do
      if img:sample(x, y) == gfx.kColorBlack then px[#px + 1] = x .. "," .. y end
    end
  end
  out[#out + 1] = tag .. ": " .. #px .. " " .. table.concat(px, " ", 1, math.min(#px, 60))
end
local function case(tag, f)
  gfx.clear(gfx.kColorWhite); gfx.clearClipRect(); gfx.setDrawOffset(0, 0)
  gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(3); gfx.setLineCapStyle(gfx.kLineCapStyleButt)
  local ok, err = pcall(f)
  if not ok then out[#out + 1] = tag .. ": error " .. tostring(err) else dump(tag) end
end
case("ctx3", function() gfx.drawLine(10, 10, 30, 14) end)
case("w0", function() gfx.drawLine(10, 10, 30, 14, 0) end)
case("w1", function() gfx.drawLine(10, 10, 30, 14, 1) end)
case("w5", function() gfx.drawLine(10, 10, 30, 14, 5) end)
case("w2.6", function() gfx.drawLine(10, 10, 30, 14, 2.6) end)
case("wneg", function() gfx.drawLine(10, 10, 30, 14, -2) end)
case("wnil", function() gfx.drawLine(10, 10, 30, 14, nil) end)
case("seg", function() gfx.drawLine(playdate.geometry.lineSegment.new(10, 10, 30, 14)) end)
case("seg0", function() gfx.drawLine(playdate.geometry.lineSegment.new(10, 10, 30, 14), 0) end)
case("seg5", function() gfx.drawLine(playdate.geometry.lineSegment.new(10, 10, 30, 14), 5) end)
-- 1-pixel lines entering the clip from above, x range inside / outside the clip
local function clipcase(tag, x1, y1, x2, y2)
  case(tag, function() gfx.setLineWidth(1); gfx.setClipRect(20, 20, 40, 40); gfx.drawLine(x1, y1, x2, y2) end)
end
clipcase("in", 25, 0, 30, 20)
clipcase("in2", 25, -50, 45, 20)
clipcase("leftout", 0, -50, 10, 20)
clipcase("rightout", 70, -50, 80, 20)
clipcase("leftout2", -100, -1, -10, 20)
clipcase("edge", 5, -30, 19, 20)
clipcase("edge2", 5, -30, 20, 20)
playdate.datastore.write({}, "x") -- create the data folder
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
f:write(table.concat(out, "\n") .. "\n"); f:close()
function playdate.update() end
