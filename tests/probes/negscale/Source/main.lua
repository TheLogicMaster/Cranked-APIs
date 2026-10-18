-- Probe: scaledImage and drawScaled with negative scales (size and pixels).
local gfx = playdate.graphics
local out = {}
local src = gfx.image.new(5, 3, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack); gfx.drawPixel(0, 0); gfx.drawPixel(1, 0); gfx.drawPixel(4, 2); gfx.drawPixel(2, 1); gfx.popContext()
local function bits(img)
  local w, h = img:getSize(); local t = {}
  for y = 0, h - 1 do for x = 0, w - 1 do local s = img:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or "c") end; t[#t + 1] = "/" end
  return w .. "x" .. h .. ":" .. table.concat(t)
end
for _, sc in ipairs({ {-1, nil}, {-2, nil}, {-1.5, nil}, {2, -1}, {-1, 2}, {-0.5, nil} }) do
  local ok, r = pcall(function() return sc[2] and src:scaledImage(sc[1], sc[2]) or src:scaledImage(sc[1]) end)
  out[#out + 1] = "scaled " .. sc[1] .. "," .. tostring(sc[2]) .. "|" .. (ok and bits(r) or ("ERR " .. tostring(r)))
  local dst = gfx.image.new(24, 12, gfx.kColorWhite)
  gfx.pushContext(dst); local ok2, e = pcall(function() if sc[2] then src:drawScaled(12, 6, sc[1], sc[2]) else src:drawScaled(12, 6, sc[1]) end end); gfx.popContext()
  out[#out + 1] = "draw " .. sc[1] .. "," .. tostring(sc[2]) .. "|" .. (ok2 and bits(dst) or ("ERR " .. tostring(e)))
end
local fh = playdate.file.open("negscale.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
