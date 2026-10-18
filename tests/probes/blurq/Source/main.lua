-- Probe: blurredImage and drawBlurred with masks
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dumpImage(name, r)
  local w, h = r:getSize()
  fh:write(name .. " size " .. w .. " " .. h .. " mask " .. tostring(r:hasMask()) .. "\n")
  for y = 0, h - 1 do local row = {} for x = 0, w - 1 do local c = r:sample(x, y) row[#row+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end fh:write(table.concat(row) .. "\n") end
end
-- hand-made: half transparent, half black/white
local hm = gfx.image.new(16, 12, gfx.kColorClear)
gfx.pushContext(hm) gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 8, 12) gfx.setColor(gfx.kColorWhite) gfx.fillRect(8, 0, 4, 12) gfx.popContext()
local hw = gfx.image.new(16, 12, gfx.kColorWhite)
gfx.pushContext(hw) gfx.setColor(gfx.kColorBlack) gfx.fillRect(4, 3, 6, 5) gfx.popContext()
local imgs = {{"u1", gfx.image.new("u1")}, {"u2", gfx.image.new("u2")}, {"c1", gfx.image.new("c1")}, {"hm", hm}, {"hw", hw}}
for _, im in ipairs(imgs) do
  for _, cfg in ipairs({{1, 1, gfx.image.kDitherTypeNone, false}, {2, 2, gfx.image.kDitherTypeBayer4x4, false}, {2, 2, gfx.image.kDitherTypeBayer4x4, true}, {1, 1, gfx.image.kDitherTypeBayer8x8, true}}) do
    dumpImage(im[1] .. " blurred " .. table.concat({cfg[1], cfg[2], cfg[3], tostring(cfg[4])}, ","), im[2]:blurredImage(cfg[1], cfg[2], cfg[3], cfg[4]))
  end
  local img = gfx.image.new(40, 34, gfx.kColorClear)
  gfx.pushContext(img) im[2]:drawBlurred(5, 6, 2, 2, gfx.image.kDitherTypeBayer4x4) gfx.popContext()
  dumpImage(im[1] .. " drawBlurred", img)
end
fh:close()
function playdate.update() end
