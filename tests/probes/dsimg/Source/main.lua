-- Probe: where datastore.writeImage puts images, and what readImage reads back.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local function r(...) if select("#", ...) == 0 then return "(no value)" end return tostring((...)) end
local img = gfx.image.new(10, 6, gfx.kColorWhite)
gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 5, 6); gfx.popContext()
local function dump(i) if not i then return "nil" end local w, h = i:getSize(); local r = {}
  for y = 0, h - 1 do local t = {}; for x = 0, w - 1 do local s = i:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "0" or (s == gfx.kColorWhite and "1" or "x") end; r[#r + 1] = table.concat(t) end
  return w .. "x" .. h .. ":" .. table.concat(r, "/") end
out[#out + 1] = "write pic\t" .. r(playdate.datastore.writeImage(img, "pic"))
out[#out + 1] = "write sub/pic2\t" .. r(playdate.datastore.writeImage(img, "sub/pic2"))
out[#out + 1] = "write pic3.pdi\t" .. r(playdate.datastore.writeImage(img, "pic3.pdi"))
out[#out + 1] = "write g.gif\t" .. r(playdate.datastore.writeImage(img, "g.gif"))
local function walk(dir, acc) for _, f in ipairs(playdate.file.listFiles(dir) or {}) do
  if f:sub(-1) == "/" then walk(dir .. f, acc) else acc[#acc + 1] = dir .. f .. "(" .. tostring(playdate.file.getSize(dir .. f)) .. ")" end end end
local files = {}; walk("", files); table.sort(files)
out[#out + 1] = "files\t" .. table.concat(files, " ")
out[#out + 1] = "read pic\t" .. dump(playdate.datastore.readImage("pic"))
out[#out + 1] = "read sub/pic2\t" .. dump(playdate.datastore.readImage("sub/pic2"))
out[#out + 1] = "read pic3.pdi\t" .. dump(playdate.datastore.readImage("pic3.pdi"))
out[#out + 1] = "read pic3\t" .. dump(playdate.datastore.readImage("pic3"))
out[#out + 1] = "read images/pic\t" .. dump(playdate.datastore.readImage("images/pic"))
out[#out + 1] = "read missing\t" .. dump(playdate.datastore.readImage("missing"))
local fh = playdate.file.open("ds.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
