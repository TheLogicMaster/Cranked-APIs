-- Probe: drawFaded and fadedImage argument checks, and drawFaded's flip forms
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(10, 6, gfx.kColorBlack)
gfx.pushContext(img) gfx.setColor(gfx.kColorWhite) gfx.fillRect(0, 0, 3, 6) gfx.popContext()
local function sig(t) local n, s = 0, 0 local W, H = t:getSize() for y = 0, H - 1 do for x = 0, W - 1 do if t:sample(x, y) == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 end end end return n .. ":" .. s end
local function case(name, f) local t = gfx.image.new(30, 20, gfx.kColorWhite) gfx.pushContext(t) local ok, e = pcall(f) gfx.popContext() fh:write(name .. " " .. tostring(ok) .. " " .. (ok and "" or tostring(e)) .. " " .. sig(t) .. "\n") end
case("drawFaded no type", function() img:drawFaded(2, 3, 0.5) end)
case("drawFaded nil type", function() img:drawFaded(2, 3, 0.5, nil) end)
case("drawFaded string type", function() img:drawFaded(2, 3, 0.5, "x") end)
case("drawFaded float type", function() img:drawFaded(2, 3, 0.5, 5.5) end)
case("drawFaded no alpha", function() img:drawFaded(2, 3) end)
case("drawFaded flip int", function() img:drawFaded(2, 3, 0.5, 0, 1) end)
case("drawFaded flip str", function() img:drawFaded(2, 3, 0.5, 0, "flipX") end)
case("drawFaded flip nil", function() img:drawFaded(2, 3, 0.5, 0, nil) end)
case("drawFaded flip 3", function() img:drawFaded(2, 3, 0.5, 6, 3) end)
case("drawFaded alpha1 flip", function() img:drawFaded(2, 3, 1.0, 0, 1) end)
case("drawFaded big type", function() img:drawFaded(2, 3, 0.5, 99) end)
case("drawFaded x float", function() img:drawFaded(2.7, 3.2, 0.5, 0) end)
case("fadedImage no type", function() local f = img:fadedImage(0.5) gfx.image.draw(f, 0, 0) end)
case("fadedImage nil type", function() local f = img:fadedImage(0.5, nil) f:draw(0, 0) end)
case("fadedImage big type", function() local f = img:fadedImage(0.5, 99) f:draw(0, 0) end)
case("fadedImage no alpha", function() local f = img:fadedImage() f:draw(0, 0) end)
fh:close()
function playdate.update() end
