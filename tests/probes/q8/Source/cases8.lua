-- Native API probe for differential testing (Simulator vs an emulator under test).
local gfx = playdate.graphics
local geom = playdate.geometry
local cases8 = {}
local function c(name, f) cases8[#cases8 + 1] = { name, f } end

local function num(x)
    if math.type(x) == "integer" then return tostring(x) .. "i" end
    local s = string.format("%.3f", x)
    if s == "-0.000" then s = "0.000" end
    return s .. "f"
end
local function v(x)
    local t = type(x)
    if t == "number" then return num(x) end
    if t == "string" then return string.format("%q", x) end
    if t == "nil" or t == "boolean" then return tostring(x) end
    if t == "table" and getmetatable(x) == nil then
        local keys = {}
        for k in pairs(x) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. v(x[k]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    local mt = getmetatable(x)
    if mt == geom.rect then return "R(" .. num(x.x) .. "," .. num(x.y) .. "," .. num(x.width) .. "," .. num(x.height) .. ")" end
    if mt == geom.point then return "P(" .. num(x.x) .. "," .. num(x.y) .. ")" end
    if mt == gfx.image then local w, h = x:getSize(); return "IMG(" .. w .. "x" .. h .. ")" end
    return "<" .. t .. ">"
end
local function all(...)
    local p = table.pack(...)
    local out = {}
    for i = 1, p.n do out[#out + 1] = v(p[i]) end
    return table.concat(out, " | ")
end

-- Image serialization: one hex string per row, 1 = white, 0 = black, "x" = transparent
local function dump(img)
    local w, h = img:getSize()
    local rows = {}
    for y = 0, h - 1 do
        local bits = {}
        for x = 0, w - 1 do
            local s = img:sample(x, y)
            bits[#bits + 1] = (s == gfx.kColorWhite) and "1" or ((s == gfx.kColorBlack) and "0" or "x")
        end
        rows[#rows + 1] = table.concat(bits)
    end
    return "PIX:" .. w .. "x" .. h .. ":" .. table.concat(rows, "/")
end
local function draw(w, h, f)
    local img = gfx.image.new(w, h, gfx.kColorWhite)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorBlack)
    f(img)
    gfx.popContext()
    return dump(img)
end
local function D(name, w, h, f) c(name, function() return draw(w, h, f) end) end


local function srcimg()
    local img = gfx.image.new(8, 6, gfx.kColorClear)
    gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 6); gfx.setColor(gfx.kColorWhite); gfx.fillRect(4, 0, 2, 6); gfx.popContext()
    return img
end
local function arrow()
    local i = gfx.image.new(12, 6, gfx.kColorClear)
    gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 2, 8, 2); gfx.fillTriangle(8, 0, 11, 3, 8, 5); gfx.popContext()
    return i
end
local CK = { 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }
local ST = { 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0 }

-- Patterns and dither
D("Q pattern with draw offset 1,0", 16, 8, function() gfx.setPattern(ST); gfx.setDrawOffset(1, 0); gfx.fillRect(0, 0, 15, 8) end)
D("Q pattern with draw offset 0,1", 16, 8, function() gfx.setPattern({ 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0 }); gfx.setDrawOffset(0, 1); gfx.fillRect(0, 0, 16, 7) end)
D("Q pattern origin in rect at 3,0", 16, 8, function() gfx.setPattern(ST); gfx.fillRect(3, 0, 10, 8) end)
D("Q pattern image phase", 16, 8, function() local p = gfx.image.new(8, 8, gfx.kColorWhite); gfx.pushContext(p); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 8); gfx.popContext(); gfx.setPattern(p, 2, 0); gfx.fillRect(0, 0, 16, 8) end)
D("Q dither 0.5 diagonal origin", 16, 16, function() gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2); gfx.fillRect(1, 1, 14, 14) end)
D("Q dither alpha 0 and 1", 16, 8, function() gfx.setDitherPattern(0.0, gfx.image.kDitherTypeBayer4x4); gfx.fillRect(0, 0, 8, 8); gfx.setDitherPattern(1.0, gfx.image.kDitherTypeBayer4x4); gfx.fillRect(8, 0, 8, 8) end)

-- Contexts
c("Q pushContext inherits line width", function() gfx.setLineWidth(5); local img = gfx.image.new(4, 4); gfx.pushContext(img); local w = gfx.getLineWidth(); gfx.popContext(); gfx.setLineWidth(1); return all(w) end)
c("Q pushContext inherits draw offset", function() gfx.setDrawOffset(3, 4); local img = gfx.image.new(4, 4); gfx.pushContext(img); local r = all(gfx.getDrawOffset()); gfx.popContext(); gfx.setDrawOffset(0, 0); return r end)
c("Q pushContext inherits color", function() gfx.setColor(gfx.kColorWhite); local img = gfx.image.new(4, 4); gfx.pushContext(img); local r = all(gfx.getColor()); gfx.popContext(); gfx.setColor(gfx.kColorBlack); return r end)
c("Q pushContext inherits clip rect", function() gfx.setClipRect(1, 1, 5, 5); local img = gfx.image.new(4, 4); gfx.pushContext(img); local r = all(gfx.getClipRect()); gfx.popContext(); gfx.clearClipRect(); return r end)
c("Q pushContext inherits font tracking", function() gfx.setFontTracking(3); local img = gfx.image.new(4, 4); gfx.pushContext(img); local r = all(gfx.getFontTracking()); gfx.popContext(); gfx.setFontTracking(0); return r end)
c("Q pushContext inherits image draw mode", function() gfx.setImageDrawMode(gfx.kDrawModeXOR); local img = gfx.image.new(4, 4); gfx.pushContext(img); local r = all(gfx.getImageDrawMode()); gfx.popContext(); gfx.setImageDrawMode(gfx.kDrawModeCopy); return r end)
c("Q state changes inside context do not leak", function() local img = gfx.image.new(4, 4); gfx.pushContext(img); gfx.setLineWidth(7); gfx.setDrawOffset(2, 2); gfx.popContext(); local r = all(gfx.getLineWidth(), gfx.getDrawOffset()); gfx.setLineWidth(1); gfx.setDrawOffset(0, 0); return r end)
c("Q pushContext with no image keeps target", function() local img = gfx.image.new(4, 4, gfx.kColorWhite); gfx.pushContext(img); gfx.pushContext(); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 2, 2); gfx.popContext(); gfx.popContext(); return dump(img) end)
c("Q lockFocus then pushContext", function() local a = gfx.image.new(4, 4, gfx.kColorWhite); local b = gfx.image.new(4, 4, gfx.kColorWhite); gfx.lockFocus(a); gfx.pushContext(b); gfx.fillRect(0, 0, 4, 4); gfx.popContext(); gfx.fillRect(0, 0, 1, 1); gfx.unlockFocus(); return dump(a) .. " " .. dump(b) end)

-- Text
c("Q kerning AV", function() local f = gfx.getSystemFont(); return all(f:getTextWidth("AV"), f:getTextWidth("A") + f:getTextWidth("V"), f:getTextWidth("VA"), f:getTextWidth("To"), f:getTextWidth("T") + f:getTextWidth("o")) end)
c("Q text widths per glyph", function() local f = gfx.getSystemFont(); return all(f:getTextWidth("a"), f:getTextWidth("aa"), f:getTextWidth(" "), f:getTextWidth("H"), f:getTextWidth("Hello"), f:getTextWidth("Hello world")) end)
c("Q font tracking adds to context tracking", function() local f = gfx.getSystemFont(); local w0 = f:getTextWidth("abc"); f:setTracking(2); local w1 = f:getTextWidth("abc"); gfx.setFontTracking(3); local w2 = gfx.getTextSize("abc"); f:setTracking(0); local w3 = gfx.getTextSize("abc"); gfx.setFontTracking(0); return all(w0, w1, w2, w3) end)
c("Q getTextSize equals font width", function() return all(gfx.getTextSize("Hello world"), gfx.getSystemFont():getTextWidth("Hello world"), gfx.getSystemFont():getHeight()) end)
D("Q drawTextInRect clips partial line", 48, 20, function() gfx.drawTextInRect("one two three four", 1, 1, 46, 18) end)
c("Q drawTextInRect return values", function() local img = gfx.image.new(48, 48); gfx.pushContext(img); local r = all(gfx.drawTextInRect("one two three four", 1, 1, 46, 46)); gfx.popContext(); return r end)
c("Q drawText return values", function() local img = gfx.image.new(64, 20); gfx.pushContext(img); local r = all(gfx.drawText("Hi there", 1, 1)); gfx.popContext(); return r end)
D("Q drawText no wrap past image", 30, 20, function() gfx.drawText("Hello world wide", 1, 1) end)
D("Q drawText newline", 48, 40, function() gfx.drawText("ab\ncd", 1, 1) end)
D("Q drawText leading", 48, 48, function() gfx.drawText("ab\ncd", 1, 1, nil, 6) end)

-- Ellipses and arcs
D("Q ellipse angles 0 to 360", 24, 24, function() gfx.drawEllipseInRect(2, 2, 19, 19, 0, 360) end)
D("Q ellipse angles 90 to 450", 24, 24, function() gfx.drawEllipseInRect(2, 2, 19, 19, 90, 450) end)
D("Q ellipse angles -90 to 90", 24, 24, function() gfx.drawEllipseInRect(2, 2, 19, 19, -90, 90) end)
D("Q ellipse angles 270 to 90", 24, 24, function() gfx.drawEllipseInRect(2, 2, 19, 19, 270, 90) end)
D("Q fill ellipse 0 to 90", 24, 24, function() gfx.fillEllipseInRect(2, 2, 19, 19, 0, 90) end)
D("Q fill ellipse 45 to 45", 24, 24, function() gfx.fillEllipseInRect(2, 2, 19, 19, 45, 45) end)
D("Q ellipse even size", 24, 24, function() gfx.drawEllipseInRect(2, 2, 20, 20) end)
D("Q ellipse width 2", 24, 24, function() gfx.setLineWidth(2); gfx.drawEllipseInRect(2, 2, 19, 19) end)
D("Q arc 0 to 90", 24, 24, function() gfx.drawArc(12, 12, 9, 0, 90) end)
D("Q arc 350 to 10", 24, 24, function() gfx.drawArc(12, 12, 9, 350, 10) end)

-- Lines and rects
D("Q rect width 3 centered", 20, 16, function() gfx.setLineWidth(3); gfx.drawRect(4, 4, 12, 8) end)
D("Q line width 2 horizontal", 16, 8, function() gfx.setLineWidth(2); gfx.drawLine(2, 3, 13, 3) end)
D("Q line width 2 vertical", 8, 16, function() gfx.setLineWidth(2); gfx.drawLine(3, 2, 3, 13) end)
D("Q line width 3 diagonal", 16, 16, function() gfx.setLineWidth(3); gfx.drawLine(2, 2, 13, 13) end)
D("Q line reversed endpoints", 16, 16, function() gfx.drawLine(14, 9, 1, 1) end)
D("Q round rect radius larger than size", 16, 12, function() gfx.drawRoundRect(2, 2, 12, 8, 10) end)

-- Rotation, scaling, sampling, blur, fade
c("Q drawRotated bounds 90", function() local o = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(o); arrow():drawRotated(12, 12, 90); gfx.popContext(); return dump(o) end)
c("Q drawRotated bounds 30", function() local o = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(o); arrow():drawRotated(12, 12, 30); gfx.popContext(); return dump(o) end)
c("Q rotatedImage 30 size", function() return all(arrow():rotatedImage(30):getSize()) end)
c("Q rotatedImage 90 pixels", function() return dump(arrow():rotatedImage(90)) end)
c("Q scaledImage 1.5 size", function() return all(arrow():scaledImage(1.5):getSize()) end)
D("Q drawScaled 0.5", 12, 8, function() arrow():drawScaled(0, 0, 0.5) end)
D("Q drawSampled identity", 16, 8, function() local i = srcimg(); i:drawSampled(0, 0, 16, 8, 0, 0, 1, 0, 0, 1, 0, 0, 16, 0, true) end)
D("Q drawSampled no tile", 16, 8, function() local i = srcimg(); i:drawSampled(0, 0, 16, 8, 0, 0, 1, 0, 0, 1, 0, 0, 16, 0, false) end)
D("Q drawSampled scale 2", 16, 8, function() local i = srcimg(); i:drawSampled(0, 0, 16, 8, 0, 0, 0.5, 0, 0, 0.5, 0, 0, 16, 0, true) end)
D("Q drawSampled center", 16, 8, function() local i = srcimg(); i:drawSampled(0, 0, 16, 8, 0.5, 0.5, 1, 0, 0, 1, 0, 0, 16, 0, true) end)
D("Q drawSampled translate", 16, 8, function() local i = srcimg(); i:drawSampled(0, 0, 16, 8, 0, 0, 1, 0, 0, 1, 0.25, 0, 16, 0, true) end)
D("Q drawSampled tilt", 32, 16, function() local i = srcimg(); i:drawSampled(0, 0, 32, 16, 0.5, 0.5, 1, 0, 0, 1, 0, 0, 16, 45, true) end)
c("Q blurredImage passes", function() local i = gfx.image.new(12, 12, gfx.kColorWhite); gfx.pushContext(i); gfx.fillRect(4, 4, 4, 4); gfx.popContext(); return dump(i:blurredImage(1, 1, gfx.image.kDitherTypeNone)) .. " " .. dump(i:blurredImage(1, 3, gfx.image.kDitherTypeNone)) end)
c("Q blurredImage padEdges", function() local i = gfx.image.new(12, 12, gfx.kColorBlack); return all(i:blurredImage(2, 1, gfx.image.kDitherTypeBayer4x4, false):getSize()) .. " " .. all(i:blurredImage(2, 1, gfx.image.kDitherTypeBayer4x4, true):getSize()) end)
c("Q fadedImage keeps mask", function() return dump(srcimg():fadedImage(0.5, gfx.image.kDitherTypeBayer4x4)) end)
c("Q invertedImage keeps mask", function() return dump(srcimg():invertedImage()) end)

-- Tilemap source rect
D("Q tilemap draw sourceRect", 24, 16, function()
    local it = gfx.imagetable.new(2); it:setImage(1, gfx.image.new(8, 8, gfx.kColorWhite)); it:setImage(2, gfx.image.new(8, 8, gfx.kColorBlack))
    local tm = gfx.tilemap.new(); tm:setImageTable(it); tm:setTiles({ 1, 2, 1, 2, 1, 2 }, 3); tm:draw(0, 0, geom.rect.new(4, 0, 12, 12))
end)

-- Sprites
local function sp(img) local s = gfx.sprite.new(img); s:setCenter(0, 0); return s end
c("Q sprite setScale size and bounds", function() local s = sp(srcimg()); s:moveTo(10, 10); s:setScale(2, 3); return all(s:getSize()) .. " | " .. v(s:getBoundsRect()) .. " | " .. all(s:getScale()) end)
c("Q sprite setScale collide rect", function() local s = sp(srcimg()); s:setCollideRect(0, 0, 8, 6); s:setScale(2); return v(s:getCollideRect()) .. " | " .. v(s:getCollideBounds()) end)
c("Q sprite setRotation size", function() local s = gfx.sprite.new(arrow()); s:setRotation(90); return all(s:getSize()) .. " | " .. all(s:getRotation()) end)
c("Q sprite setRotation 45 size", function() local s = gfx.sprite.new(arrow()); s:setRotation(45); return all(s:getSize()) end)
c("Q sprite setImage replaces scale", function() local s = gfx.sprite.new(); s:setImage(srcimg(), gfx.kImageUnflipped, 2); s:setImage(srcimg()); return all(s:getSize()) .. " | " .. all(s:getScale()) end)
c("Q sprite copy fields", function()
    local s = sp(srcimg()); s:moveTo(5, 6); s:setZIndex(3); s:setTag(4); s:setCollideRect(1, 1, 2, 2); s:setVisible(false); s.custom = "x"
    local t = s:copy()
    return all(t:getPosition()) .. " | " .. all(t:getZIndex(), t:getTag(), t:isVisible(), t.custom, t:getImage() == s:getImage()) .. " | " .. v(t:getCollideRect())
end)
c("Q sprite copy not added", function() gfx.sprite.removeAll(); local s = sp(srcimg()); s:add(); local t = s:copy(); local r = all(gfx.sprite.spriteCount()); gfx.sprite.removeAll(); return r end)
c("Q sprite tilemap replaces image", function() local s = gfx.sprite.new(srcimg()); local it = gfx.imagetable.new(1); it:setImage(1, gfx.image.new(8, 8)); local tm = gfx.tilemap.new(); tm:setImageTable(it); tm:setTiles({ 1, 1 }, 2); s:setTilemap(tm); return all(s:getImage(), s:getSize()) end)
c("Q sprite collide rect flips with image", function()
    gfx.sprite.removeAll()
    local a = sp(gfx.image.new(10, 10)); a:moveTo(0, 0); a:setCollideRect(0, 0, 4, 10); a:setImageFlip(gfx.kImageFlippedX); a:add()
    local b = sp(gfx.image.new(2, 10)); b:moveTo(7, 0); b:setCollideRect(0, 0, 2, 10); b:add()
    local r = all(#a:overlappingSprites()) .. " | " .. v(a:getCollideBounds())
    gfx.sprite.removeAll(); return r
end)
c("Q sprite update order equal z", function()
    gfx.sprite.removeAll(); local order = {}
    for i = 1, 4 do local s = gfx.sprite.new(); s:setZIndex(0); function s:update() order[#order + 1] = i end; s:add() end
    gfx.sprite.update(); gfx.sprite.removeAll(); return table.concat(order, ",")
end)
c("Q sprite update order after z change", function()
    gfx.sprite.removeAll(); local order = {}; local list = {}
    for i = 1, 3 do local s = gfx.sprite.new(); s:setZIndex(i); function s:update() order[#order + 1] = i end; s:add(); list[i] = s end
    list[1]:setZIndex(5); gfx.sprite.update(); gfx.sprite.removeAll(); return table.concat(order, ",")
end)
c("Q sprite draw callback args full redraw", function()
    gfx.sprite.removeAll(); local got
    local s = gfx.sprite.new(); s:setSize(10, 8); s:setCenter(0, 0); s:moveTo(5, 6); function s:draw(x, y, w, h) got = all(x, y, w, h) end; s:add()
    gfx.sprite.redrawBackground(); gfx.sprite.update(); gfx.sprite.removeAll(); return got
end)
c("Q sprite draw callback args partial", function()
    gfx.sprite.removeAll(); local calls = {}
    local s = gfx.sprite.new(); s:setSize(40, 40); s:setCenter(0, 0); s:moveTo(0, 0); function s:draw(x, y, w, h) calls[#calls + 1] = all(x, y, w, h) end; s:add()
    gfx.sprite.update(); calls = {}; gfx.sprite.addDirtyRect(10, 10, 5, 5); gfx.sprite.update(); gfx.sprite.removeAll(); return table.concat(calls, " ; ")
end)
c("Q sprite draw not called when clean", function()
    gfx.sprite.removeAll(); local n = 0
    local s = gfx.sprite.new(); s:setSize(10, 10); function s:draw() n = n + 1 end; s:add()
    gfx.sprite.update(); local a = n; gfx.sprite.update(); local b = n; s:markDirty(); gfx.sprite.update(); local cc = n
    gfx.sprite.removeAll(); return all(a, b, cc)
end)
c("Q sprite draw offset passed to draw", function()
    gfx.sprite.removeAll(); local got
    local s = gfx.sprite.new(); s:setSize(10, 8); s:setCenter(0, 0); s:moveTo(5, 6); function s:draw(x, y, w, h) got = all(x, y, w, h) .. " offset " .. all(gfx.getDrawOffset()) end; s:add()
    gfx.sprite.update(); gfx.sprite.removeAll(); return got
end)
c("Q sprite opaque flag default", function() local s = gfx.sprite.new(gfx.image.new(4, 4, gfx.kColorBlack)); local t = gfx.sprite.new(srcimg()); return all(s:isOpaque(), t:isOpaque()) end)
c("Q sprite setSize on image sprite", function() local s = gfx.sprite.new(srcimg()); s:setSize(20, 20); return all(s:getSize()) end)
c("Q sprite moveTo rounds", function() local s = sp(srcimg()); s:moveTo(1.6, 2.4); return all(s:getPosition()) .. " | " .. v(s:getBoundsRect()) end)
c("Q sprite center default", function() local s = gfx.sprite.new(srcimg()); s:moveTo(10, 10); return all(s:getCenter()) .. " | " .. v(s:getBoundsRect()) end)

function runCases8(write, skip)
    skip = skip or {}
    for _, case in ipairs(cases8) do
        if not skip[case[1]] then
            gfx.setLineWidth(1); gfx.setLineCapStyle(gfx.kLineCapStyleButt); gfx.setStrokeLocation(gfx.kStrokeCentered)
            gfx.setDrawOffset(0, 0); gfx.clearClipRect(); gfx.setImageDrawMode(gfx.kDrawModeCopy); gfx.setColor(gfx.kColorBlack)
            local ok, r = pcall(case[2])
            local out = ok and tostring(r) or ("ERR " .. tostring(r))
            write(case[1] .. "\t" .. out:gsub("\n", "\\n"):gsub("\t", "\\t"))
        end
    end
end
