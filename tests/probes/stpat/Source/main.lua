-- Probe: gfx.setStencilPattern(level, ditherType) for every dither type and levels 0 to 1 by 0.01; the 8x8
-- stencil read back by filling through it
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local I = gfx.image
local types = { {"none", I.kDitherTypeNone}, {"diag", I.kDitherTypeDiagonalLine}, {"vert", I.kDitherTypeVerticalLine}, {"horiz", I.kDitherTypeHorizontalLine}, {"screen", I.kDitherTypeScreen}, {"b2", I.kDitherTypeBayer2x2}, {"b4", I.kDitherTypeBayer4x4}, {"b8", I.kDitherTypeBayer8x8}, {"fs", I.kDitherTypeFloydSteinberg}, {"burkes", I.kDitherTypeBurkes}, {"atkinson", I.kDitherTypeAtkinson}, {"nil", nil} }
for _, t in ipairs(types) do
  local prev = nil
  for i = 0, 100 do
    local lv = i / 100
    local img = gfx.image.new(8, 8, gfx.kColorWhite)
    gfx.pushContext(img)
    local ok, e = pcall(gfx.setStencilPattern, lv, t[2])
    gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 8, 8)
    gfx.popContext()
    local r = {}
    for y = 0, 7 do local row = 0 for x = 0, 7 do if img:sample(x, y) == gfx.kColorBlack then row = row | (1 << (7 - x)) end end r[#r + 1] = string.format("%02x", row) end
    local s = table.concat(r)
    if s ~= prev then fh:write(t[1] .. " " .. string.format("%.2f", lv) .. " " .. tostring(ok) .. " " .. s .. "\n") prev = s end
  end
end
for _, case in ipairs({"omit", "rows", "fs.3", "fs.9", "atk.5", "neg", "big", "str", "sprite"}) do
  local img = gfx.image.new(8, 8, gfx.kColorWhite)
  gfx.pushContext(img)
  local ok, e
  if case == "omit" then ok, e = pcall(gfx.setStencilPattern, 0.3)
  elseif case == "rows" then ok, e = pcall(gfx.setStencilPattern, 0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81)
  elseif case == "fs.3" then ok, e = pcall(gfx.setStencilPattern, 0.3, I.kDitherTypeFloydSteinberg)
  elseif case == "fs.9" then ok, e = pcall(gfx.setStencilPattern, 0.9, I.kDitherTypeFloydSteinberg)
  elseif case == "atk.5" then ok, e = pcall(gfx.setStencilPattern, 0.5, I.kDitherTypeAtkinson)
  elseif case == "neg" then ok, e = pcall(gfx.setStencilPattern, -0.5, I.kDitherTypeBayer4x4)
  elseif case == "big" then ok, e = pcall(gfx.setStencilPattern, 3, I.kDitherTypeBayer4x4)
  elseif case == "str" then ok, e = pcall(gfx.setStencilPattern, 0.5, "bayer4x4")
  end
  gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 8, 8)
  gfx.popContext()
  local r = {}
  for y = 0, 7 do local row = 0 for x = 0, 7 do if img:sample(x, y) == gfx.kColorBlack then row = row | (1 << (7 - x)) end end r[#r + 1] = string.format("%02x", row) end
  fh:write("case " .. case .. " " .. tostring(ok) .. " " .. tostring(e) .. " " .. table.concat(r) .. "\n")
end
fh:close()
function playdate.update() end
