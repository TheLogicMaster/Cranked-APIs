-- Probe: nineSlice drawing at many sizes, imageWithText, and drawTextInRect truncation and alignment
import "CoreLibs/graphics"
import "CoreLibs/nineslice"
local gfx = playdate.graphics
playdate.file.delete("out.txt")
local fh = { write = function(_, t) local f = playdate.file.open("out.txt", playdate.file.kFileAppend) f:write(t) f:close() end, close = function() end }
local function sig(img) local w, h = img:getSize() local s, n = 0, 0 for y = 0, h - 1 do for x = 0, w - 1 do local c = img:sample(x, y) if c == gfx.kColorBlack then s = (s * 31 + x * 7 + y * 13) % 1000003 n = n + 1 elseif c == gfx.kColorClear then s = (s * 17 + x + y * 3) % 1000003 end end end return w .. "x" .. h .. ":" .. n .. ":" .. s end
local ns = gfx.nineSlice.new("ns", 4, 3, 4, 3)
fh:write("ns size " .. table.concat({ ns:getSize() }, ",") .. " min " .. table.concat({ ns:getMinSize() }, ",") .. "\n")
for _, sz in ipairs({ { 12, 9 }, { 20, 15 }, { 7, 5 }, { 3, 2 }, { 40, 9 }, { 12, 30 }, { 33, 17 }, { 0, 0 }, { 1, 1 } }) do
  local img = gfx.image.new(50, 40, gfx.kColorWhite)
  fh:write("trying " .. sz[1] .. "x" .. sz[2] .. "\n") gfx.pushContext(img) local okd, ed = pcall(ns.drawInRect, ns, 3, 2, sz[1], sz[2]) gfx.popContext() if not okd then fh:write("ERR " .. tostring(ed) .. "\n") end
  fh:write("ns " .. sz[1] .. "x" .. sz[2] .. " " .. sig(img) .. "\n")
end
local img = gfx.image.new(50, 40, gfx.kColorWhite)
gfx.pushContext(img) gfx.setDrawOffset(5, 3) ns:drawInRect(geo and 0 or 0, 0, 20, 15) gfx.setDrawOffset(0, 0) gfx.popContext()
fh:write("ns offset " .. sig(img) .. "\n")
for _, t in ipairs({ { "hello world", 40 }, { "hello world", 200 }, { "a\nbb\nccc", 100 }, { "*bold* _it_", 100 }, { "", 50 } }) do
  local ok0, im, trunc = pcall(gfx.imageWithText, t[1], t[2], 60) if not ok0 then im = nil trunc = "ERR " .. tostring(im) end
  fh:write("iwt [" .. t[1]:gsub("\n", "/") .. "] " .. t[2] .. " " .. (im and sig(im) or "nil") .. " " .. tostring(trunc) .. "\n")
  for _, al in ipairs({ kTextAlignment.left, kTextAlignment.center, kTextAlignment.right }) do
    local ok1, im2, tr2 = pcall(gfx.imageWithText, t[1], t[2], 30, nil, nil, nil, al) if not ok1 then tr2 = "ERR " .. tostring(im2) im2 = nil end
    fh:write("  al" .. al .. " " .. (im2 and sig(im2) or "nil") .. " " .. tostring(tr2) .. "\n")
  end
end
for _, c in ipairs({ { "the quick brown fox jumps", 60, 40 }, { "the quick brown fox jumps", 60, 20 }, { "supercalifragilistic", 40, 40 }, { "a b c d e f g h", 30, 30 } }) do
  for _, al in ipairs({ kTextAlignment.left, kTextAlignment.center, kTextAlignment.right }) do
    for _, tz in ipairs({ "", "..." }) do
      local im3 = gfx.image.new(80, 60, gfx.kColorWhite)
      gfx.pushContext(im3)
      local w, h, tr = gfx.drawTextInRect(c[1], 5, 5, c[2], c[3], nil, tz, al)
      gfx.popContext()
      fh:write("dtir [" .. c[1] .. "] " .. c[2] .. "x" .. c[3] .. " al" .. al .. " tz'" .. tz .. "' -> " .. tostring(w) .. "," .. tostring(h) .. "," .. tostring(tr) .. " " .. sig(im3) .. "\n")
    end
  end
end
fh:close()
function playdate.update() end
