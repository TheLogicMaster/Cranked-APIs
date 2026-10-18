-- Probe: an unknown dither type in drawFaded at several x and y positions, and with a draw offset
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(10, 6, gfx.kColorBlack)
local function sig(t) local n, s = 0, 0 local W, H = t:getSize() for y = 0, H - 1 do for x = 0, W - 1 do if t:sample(x, y) == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 end end end return n .. ":" .. s end
for _, ty in ipairs({ 0, 12 }) do
  for _, a in ipairs({ 0.2, 0.6, 0.999 }) do
    local parts = {}
    for _, p in ipairs({ { 0, 0 }, { 0, 3 }, { 1, 3 }, { -1, 3 }, { -3, 3 }, { 3, 0 }, { 8, 3 }, { 0, -2 }, { 255, 3 }, { 256, 3 } }) do
      local t = gfx.image.new(300, 20, gfx.kColorWhite) gfx.pushContext(t) local ok = pcall(img.drawFaded, img, p[1], p[2], a, ty) gfx.popContext()
      parts[#parts + 1] = p[1] .. "," .. p[2] .. "=" .. (ok and sig(t) or "err")
    end
    fh:write(string.format("t=%d a=%s %s\n", ty, tostring(a), table.concat(parts, " ")))
  end
end
fh:close()
function playdate.update() end
