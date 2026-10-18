-- Probe: what exists before the CoreLibs imports, whether a game's early overrides survive them, and the
-- geometry-object forms of the CoreLibs functions that test for userdata
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function out(...) local t = table.pack(...) local p = {} for i = 1, t.n do p[i] = tostring(t[i]) end fh:write(table.concat(p, " ") .. "\n") end
local gfx = playdate.graphics
out("before spritelib", type(spritelib), "nineSlice", type(gfx.nineSlice), "class", type(class), "animator", type(gfx.animator))
out("before setBackgroundDrawingCallback", type(gfx.sprite.setBackgroundDrawingCallback), "drawCircleInRect", type(gfx.drawCircleInRect), "Object", type(Object))
out("before drawTextInRect", type(gfx.drawTextInRect), "addEmptyCollisionSprite", type(gfx.sprite.addEmptyCollisionSprite), "timer", type(playdate.timer))
local early = function() return "early" end
gfx.drawCircleInRect = early
import "CoreLibs/graphics"
out("override survives graphics import", gfx.drawCircleInRect == early)
import "CoreLibs/sprites"
import "CoreLibs/nineslice"
import "CoreLibs/timer"
out("after spritelib", type(spritelib), "nineSlice", type(gfx.nineSlice), "class", type(class), "animator", type(gfx.animator))
local function sig(img) local n, s = 0, 0 for y = 0, 159 do for x = 0, 199 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 end end end return n .. ":" .. s end
local function case(name, f) local img = gfx.image.new(200, 160, gfx.kColorWhite) gfx.pushContext(img) local ok, e = pcall(f) gfx.popContext() out(name, ok, ok and "" or tostring(e), sig(img)) end
local R = playdate.geometry.rect.new(20, 30, 61, 41)
case("drawCircleInRect rect", function() gfx.drawCircleInRect(R) end)
case("fillCircleInRect rect", function() gfx.fillCircleInRect(R) end)
case("drawCircleAtPoint point", function() gfx.drawCircleAtPoint(playdate.geometry.point.new(70, 60), 25) end)
case("fillCircleAtPoint point", function() gfx.fillCircleAtPoint(playdate.geometry.point.new(70, 60), 25) end)
case("drawArc arc", function() gfx.drawArc(playdate.geometry.arc.new(100, 100, 40, 10, 200)) end)
case("drawArc ccw arc", function() gfx.drawArc(playdate.geometry.arc.new(100, 100, 40, 10, 200, false)) end)
case("drawTextInRect rect", function() gfx.drawTextInRect("Hello there, a wrapped line of text", R) end)
case("drawLocalizedTextInRect rect", function() gfx.drawLocalizedTextInRect("nokey", R) end)
case("addEmptyCollisionSprite rect", function() local s = gfx.sprite.addEmptyCollisionSprite(R) local x, y, w, h = s:getCollideBounds() out(" bounds", x, y, w, h, s.x, s.y) end)
local ns = gfx.nineSlice.new("u1", 5, 4, 8, 6)
case("nineSlice drawInRect rect", function() ns:drawInRect(R) end)
case("nineSlice drawInRect nums", function() ns:drawInRect(20, 30, 61, 41) end)
fh:close()
function playdate.update() end
