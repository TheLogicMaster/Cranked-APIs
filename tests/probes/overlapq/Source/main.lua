-- Probe: allOverlappingSprites and overlappingSprites, before and after a sprite update
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function mk(name, x, y, w, h) local s = gfx.sprite.new() s.name = name s:setSize(w, h) s:setCenter(0, 0) s:moveTo(x, y) s:setCollideRect(0, 0, w, h) s:add() return s end
local a = mk("a", 50, 0, 10, 100)
local b = mk("b", 0, 60, 200, 10)
local c = mk("c", 55, 5, 10, 10)
local d = mk("d", 150, 55, 10, 10)
local e = mk("e", 52, 58, 3, 3)
local function report(label)
  local all = gfx.sprite.allOverlappingSprites()
  local parts = {}
  for _, pair in ipairs(all) do if type(pair) == "table" and pair[1] then parts[#parts + 1] = tostring(pair[1].name) .. "+" .. tostring(pair[2] and pair[2].name) else parts[#parts + 1] = tostring(pair.name or pair) end end
  local oa = {} for _, s in ipairs(a:overlappingSprites()) do oa[#oa + 1] = s.name end table.sort(oa)
  fh:write(label .. " all=" .. #all .. " [" .. table.concat(parts, " ") .. "] a overlaps [" .. table.concat(oa, ",") .. "]\n")
end
report("before update")
local frame = 0
function playdate.update()
  frame = frame + 1
  gfx.sprite.update()
  if frame <= 2 then report("after update " .. frame) end
  if frame == 3 then fh:close() end
end
