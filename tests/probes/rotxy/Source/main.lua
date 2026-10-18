-- Probe: full-frame dumps of a trimmed image drawn scaled with different x and y scales
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local out = setmetatable({}, {__newindex = function(t, k, v) fh:write(v .. "\n") end, __len = function() return 0 end})
local src = gfx.image.new("figure")
local function dump(name, f)
  local img = gfx.image.new(400, 240, gfx.kColorClear)
  gfx.pushContext(img) local ok, e = pcall(f) gfx.popContext()
  out[#out+1] = name .. " " .. tostring(ok) .. " " .. tostring(e)
  for y = 0, 239 do local r = {} for x = 0, 399 do local c = img:sample(x, y) r[#r+1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end out[#out+1] = table.concat(r) end
end
for _, pos in ipairs({{150, 115}, {150, 130}, {200, 120}, {150, 124}, {150, 123.5}}) do
  for _, a in ipairs({90, 270}) do
    dump("t rot " .. a .. " at " .. pos[1] .. " " .. pos[2], function() src:drawRotated(pos[1], pos[2], a) end)
  end
end
dump("t rotimg 90", function() src:rotatedImage(90):draw(10, -5) end)
fh:close()
function playdate.update() end
