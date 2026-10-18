-- Multi-frame probe: scripted scenes inside playdate.update, capturing the last completed frame.
local gfx = playdate.graphics
local W, H = 128, 96 -- captured region, top-left of the screen

local function dumpDisplay()
    local img = gfx.getDisplayImage()
    local rows = {}
    for y = 0, H - 1 do
        local b = {}
        for x = 0, W - 1 do
            local s = img:sample(x, y)
            b[#b + 1] = s == gfx.kColorWhite and "1" or (s == gfx.kColorBlack and "0" or "x")
        end
        rows[#rows + 1] = table.concat(b)
    end
    return "PIX:" .. W .. "x" .. H .. ":" .. table.concat(rows, "/")
end
local function block(w, h, color) return gfx.image.new(w, h, color) end
local function checker(w, h)
    local i = gfx.image.new(w, h, gfx.kColorWhite)
    gfx.pushContext(i); gfx.setColor(gfx.kColorBlack)
    for y = 0, h - 1 do for x = 0, w - 1 do if (x + y) % 2 == 0 then gfx.drawPixel(x, y) end end end
    gfx.popContext(); return i
end
local function arrow()
    local i = gfx.image.new(12, 6, gfx.kColorClear)
    gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 2, 8, 2); gfx.fillTriangle(8, 0, 11, 3, 8, 5); gfx.popContext()
    return i
end
local function spr(img, x, y, z)
    local s = gfx.sprite.new(img); s:setCenter(0, 0); s:moveTo(x, y); if z then s:setZIndex(z) end; s:add(); return s
end

-- Each scene: setup(), optional step(frame), frames to run before capture.
local scenes = {}
local function scene(name, frames, setup, step) scenes[#scenes + 1] = { name = name, frames = frames, setup = setup, step = step } end

scene("background white default", 3, function() end, function() gfx.sprite.update() end)
scene("background color black", 3, function() gfx.setBackgroundColor(gfx.kColorBlack) end, function() gfx.sprite.update() end)
scene("z order", 3, function() spr(block(30, 30, gfx.kColorBlack), 10, 10, 2); spr(checker(30, 30), 25, 25, 1) end, function() gfx.sprite.update() end)
scene("z order reversed", 3, function() spr(block(30, 30, gfx.kColorBlack), 10, 10, 1); spr(checker(30, 30), 25, 25, 2) end, function() gfx.sprite.update() end)
scene("invisible sprite", 3, function() local s = spr(block(30, 30, gfx.kColorBlack), 10, 10); s:setVisible(false) end, function() gfx.sprite.update() end)
scene("transparent image over sprite", 3, function() spr(block(40, 20, gfx.kColorBlack), 10, 10, 1); spr(arrow(), 20, 15, 2) end, function() gfx.sprite.update() end)
scene("moving sprite no trails", 4, function() movingSprite = spr(block(10, 10, gfx.kColorBlack), 0, 20) end, function(f) movingSprite:moveBy(15, 0); gfx.sprite.update() end)
scene("sprite removed leaves background", 4, function() removedSprite = spr(block(20, 20, gfx.kColorBlack), 20, 20) end, function(f) if f == 2 then removedSprite:remove() end; gfx.sprite.update() end)
scene("background drawing callback", 3, function()
    gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 64, 48) end)
    spr(block(10, 10, gfx.kColorWhite), 30, 30)
end, function() gfx.sprite.update() end)
scene("sprite scale 2", 3, function() local s = spr(arrow(), 10, 10); s:setScale(2) end, function() gfx.sprite.update() end)
scene("sprite rotation 90", 3, function() local s = gfx.sprite.new(arrow()); s:moveTo(40, 40); s:setRotation(90); s:add() end, function() gfx.sprite.update() end)
scene("sprite flip x", 3, function() local s = spr(arrow(), 10, 10); s:setImageFlip(gfx.kImageFlippedX) end, function() gfx.sprite.update() end)
scene("sprite draw mode XOR", 3, function() spr(block(40, 40, gfx.kColorBlack), 0, 0, 1); local s = spr(checker(20, 20), 10, 10, 2); s:setImageDrawMode(gfx.kDrawModeXOR) end, function() gfx.sprite.update() end)
scene("sprite draw mode fill white", 3, function() spr(block(40, 40, gfx.kColorBlack), 0, 0, 1); local s = spr(arrow(), 10, 10, 2); s:setImageDrawMode(gfx.kDrawModeFillWhite) end, function() gfx.sprite.update() end)
scene("sprite with draw offset", 3, function() gfx.setDrawOffset(20, 10); spr(block(10, 10, gfx.kColorBlack), 0, 0) end, function() gfx.sprite.update() end)
scene("sprite ignores draw offset", 3, function() gfx.setDrawOffset(20, 10); local s = spr(block(10, 10, gfx.kColorBlack), 0, 0); s:setIgnoresDrawOffset(true) end, function() gfx.sprite.update() end)
scene("sprite clip rect", 3, function() local s = spr(block(40, 40, gfx.kColorBlack), 0, 0); s:setClipRect(10, 10, 15, 15) end, function() gfx.sprite.update() end)
scene("sprite custom draw", 3, function()
    local s = gfx.sprite.new(); s:setSize(30, 20); s:setCenter(0, 0); s:moveTo(10, 10)
    function s:draw(x, y, w, h) gfx.setColor(gfx.kColorBlack); gfx.drawRect(0, 0, self.width, self.height); gfx.fillRect(5, 5, 5, 5) end
    s:add()
end, function() gfx.sprite.update() end)
scene("sprite update method moves", 4, function()
    local s = spr(block(8, 8, gfx.kColorBlack), 0, 50)
    function s:update() self:moveBy(10, 0) end
end, function() gfx.sprite.update() end)
scene("sprite stencil pattern", 3, function() local s = spr(block(32, 32, gfx.kColorBlack), 0, 0); s:setStencilPattern({ 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }) end, function() gfx.sprite.update() end)
scene("sprite tilemap", 3, function()
    local it = gfx.imagetable.new(2); it:setImage(1, block(8, 8, gfx.kColorWhite)); it:setImage(2, block(8, 8, gfx.kColorBlack))
    local tm = gfx.tilemap.new(); tm:setImageTable(it); tm:setTiles({ 1, 2, 1, 2, 2, 1, 2, 1 }, 4)
    local s = gfx.sprite.new(); s:setTilemap(tm); s:setCenter(0, 0); s:moveTo(8, 8); s:add()
end, function() gfx.sprite.update() end)
scene("direct drawing persists without sprites", 3, function() end, function(f) if f == 1 then gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(10, 10, 20, 20) end end)
scene("clear each frame", 3, function() end, function(f) gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(10 * f, 10, 10, 10) end)
scene("text on screen", 3, function() end, function() gfx.clear(gfx.kColorWhite); gfx.drawText("Frame test", 4, 4) end)
scene("drawFPS overlay", 3, function() end, function() gfx.clear(gfx.kColorWhite); playdate.drawFPS(0, 0) end)
scene("display inverted capture", 3, function() playdate.display.setInverted(true) end, function() gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 20, 20) end)

local results = {}
local s, f = 1, 0
local counters = { updates = 0, start = nil }
function playdate.update()
    counters.updates = counters.updates + 1
    counters.start = counters.start or playdate.getCurrentTimeMilliseconds()
    local sc = scenes[s]
    if not sc then
        local elapsed = playdate.getCurrentTimeMilliseconds() - counters.start
        results[#results + 1] = "frame pacing\t" .. tostring(counters.updates > 0) .. " | " .. tostring(elapsed > 0)
        local file = playdate.file.open("out7.txt", playdate.file.kFileWrite)
        file:write(table.concat(results, "\n") .. "\n"); file:close()
        if playdate.simulator then playdate.simulator.exit() end
        playdate.stop()
        return
    end
    if f == 0 then
        gfx.sprite.removeAll(); gfx.setBackgroundColor(gfx.kColorWhite); gfx.setDrawOffset(0, 0); gfx.clear(gfx.kColorWhite)
        playdate.display.setInverted(false); pcall(gfx.sprite.setBackgroundDrawingCallback, nil)
        local ok, err = pcall(sc.setup)
        if not ok then results[#results + 1] = sc.name .. "\tERR " .. tostring(err); s, f = s + 1, 0; return end
    end
    if f < sc.frames then
        f = f + 1
        local ok, err = pcall(sc.step or function() end, f)
        if not ok then results[#results + 1] = sc.name .. "\tERR " .. tostring(err); s, f = s + 1, 0 end
        return
    end
    -- capture at the start of the frame after the scene's last frame: getDisplayImage shows the completed frame
    results[#results + 1] = sc.name .. "\t" .. dumpDisplay()
    s, f = s + 1, 0
end
