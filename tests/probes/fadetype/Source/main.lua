-- Probe: drawFaded and fadedImage with dither types outside 0 to 10
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(10, 6, gfx.kColorBlack)
local function sig(t) local n, s = 0, 0 local W, H = t:getSize() for y = 0, H - 1 do for x = 0, W - 1 do if t:sample(x, y) == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 end end end return n .. ":" .. s end
for _, ty in ipairs({ 0, 7, 10, 11, 12, 15, 16, 99, 255, 256, 263, -1, -249 }) do
  for _, a in ipairs({ 0.3, 0.5, 0.9 }) do
    local parts = {}
    for _, x in ipairs({ 0, 2, 5 }) do
      local t = gfx.image.new(30, 20, gfx.kColorWhite) gfx.pushContext(t) local ok = pcall(img.drawFaded, img, x, 3, a, ty) gfx.popContext()
      parts[#parts + 1] = ok and sig(t) or "err"
    end
    local ok, f = pcall(img.fadedImage, img, a, ty)
    local fs = "err"
    if ok and f then local t = gfx.image.new(30, 20, gfx.kColorWhite) gfx.pushContext(t) f:draw(0, 0) gfx.popContext() fs = sig(t) end
    fh:write(string.format("t=%d a=%s draw=%s faded=%s\n", ty, tostring(a), table.concat(parts, " "), fs))
  end
end
fh:close()
function playdate.update() end
