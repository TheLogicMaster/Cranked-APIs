-- Probe: tilemap tiles that were never set, out-of-range positions, and getTiles
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(label, tm)
  local w, h = tm:getSize()
  local rows = {}
  for y = 0, h + 1 do local r = {} for x = 0, w + 1 do r[#r + 1] = tostring(tm:getTileAtPosition(x, y)) end rows[#rows + 1] = table.concat(r, ",") end
  local t, tw = tm:getTiles()
  local all = {} for i = 1, #t do all[#all + 1] = tostring(t[i]) end
  fh:write(label .. " size=" .. w .. "x" .. h .. " | " .. table.concat(rows, " / ") .. " | tiles(" .. tostring(tw) .. ")=" .. table.concat(all, ",") .. "\n")
end
local it = gfx.imagetable.new(4) for i = 1, 4 do it:setImage(i, gfx.image.new(8, 8, gfx.kColorBlack)) end
local tm = gfx.tilemap.new()
dump("new", tm)
tm:setImageTable(it)
tm:setSize(5, 3)
dump("setSize", tm)
tm:setTileAtPosition(2, 2, 3)
dump("set 2,2", tm)
tm:setTileAtPosition(0, 1, 2) dump("set 0,1", tm)
tm:setTileAtPosition(6, 1, 2) dump("set 6,1", tm)
tm:setTileAtPosition(1, 0, 4) dump("set 1,0", tm)
tm:setTileAtPosition(1, 4, 4) dump("set 1,4", tm)
tm:setTileAtPosition(3, 3, 0) dump("set 3,3=0", tm)
tm:setTileAtPosition(4, 3, 9) dump("set 4,3=9", tm)
tm:setTileAtPosition(5, 3, -1) dump("set 5,3=-1", tm)
local tm2 = gfx.tilemap.new() tm2:setImageTable(it) tm2:setTiles({ 1, 0, 2, 0, 3, 4 }, 3) dump("setTiles", tm2)
tm2:setSize(4, 3) dump("resize", tm2)
local tm3 = gfx.tilemap.new() tm3:setSize(2, 2) dump("noimagetable", tm3)
fh:close()
function playdate.update() end
