-- Probe: fillRoundRect / drawRoundRect with radius 0 and 1 across widths and heights (corner cutting).
local gfx = playdate.graphics
local out = {}
local function case(name, fn)
  local d = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(d); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 23 do for x = 0, 23 do t[#t + 1] = d:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
for _, r in ipairs({0, 1}) do
  for w = 1, 12 do for _, h in ipairs({2, 3, 4, 5, 6, 10}) do
    case(string.format("fill %d %d %d", w, h, r), function() gfx.fillRoundRect(2, 2, w, h, r) end)
    case(string.format("draw %d %d %d", w, h, r), function() gfx.drawRoundRect(2, 2, w, h, r) end)
  end end
end
local fh = playdate.file.open("rrsmall.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
