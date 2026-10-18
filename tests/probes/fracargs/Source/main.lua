-- Probe: how integer-taking calls treat fractional arguments (truncate, round, floor, or error).
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local out = {}
local function rec(name, fn)
  local ok, a, b, c, d = pcall(fn)
  out[#out + 1] = name .. "|" .. (ok and (tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d)) or ("ERR " .. tostring(a)))
end
local vals = {1.4, 1.5, 1.6, 2.5, -1.5}
for _, v in ipairs(vals) do
  rec("lineWidth " .. v, function() gfx.setLineWidth(v); return gfx.getLineWidth() end)
  rec("drawOffset " .. v, function() gfx.setDrawOffset(v, v + 1); local x, y = gfx.getDrawOffset(); gfx.setDrawOffset(0, 0); return x, y end)
  rec("sprite setSize " .. v, function() local s = gfx.sprite.new(); s:setSize(v + 10, v + 5); return s:getSize() end)
  rec("imagetable.new " .. v, function() local t = gfx.imagetable.new(v + 3); return t:getLength() end)
  rec("tilemap setSize " .. v, function() local t = gfx.tilemap.new(); t:setSize(v + 3, v + 2); return t:getSize() end)
  rec("sample " .. v, function() local i = gfx.image.new(4, 4, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.drawPixel(2, 2); gfx.popContext(); return i:sample(v + 1, v + 1), i:sample(2, v + 1) end)
  rec("drawPixel " .. v, function() local i = gfx.image.new(6, 6, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.drawPixel(v + 2, v + 2); gfx.popContext()
      local r = {}; for y = 0, 5 do for x = 0, 5 do if i:sample(x, y) == gfx.kColorBlack then r[#r + 1] = x .. "," .. y end end end; return table.concat(r, ";") end)
  rec("font tracking " .. v, function() local f = gfx.getSystemFont(); local old = f:getTracking(); f:setTracking(v); local t = f:getTracking(); f:setTracking(old); return t end)
  rec("image copy/size " .. v, function() local i = gfx.image.new(5, 5); local c = i:scaledImage(v); return c:getSize() end)
  rec("fillRect w " .. v, function() local i = gfx.image.new(8, 8, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(1, 1, v + 2, v + 2); gfx.popContext()
      local n = 0; for y = 0, 7 do for x = 0, 7 do if i:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end; return n end)
end
local fh = playdate.file.open("fracargs.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
