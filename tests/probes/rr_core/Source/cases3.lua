-- Native API probe for differential testing (Simulator vs an emulator under test).
local gfx = playdate.graphics
local geom = playdate.geometry
local cases3 = {}
local function c(name, f) cases3[#cases3 + 1] = { name, f } end

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

-- constants
c("color constants", function() return all(gfx.kColorBlack, gfx.kColorWhite, gfx.kColorClear, gfx.kColorXOR) end)
c("draw mode constants", function() return all(gfx.kDrawModeCopy, gfx.kDrawModeWhiteTransparent, gfx.kDrawModeBlackTransparent, gfx.kDrawModeFillWhite, gfx.kDrawModeFillBlack, gfx.kDrawModeXOR, gfx.kDrawModeNXOR, gfx.kDrawModeInverted) end)
c("display size", function() return all(playdate.display.getWidth(), playdate.display.getHeight(), playdate.display.getRefreshRate()) end)

-- primitives
D("pixel", 8, 8, function() gfx.drawPixel(3, 4) end)
D("line h", 16, 8, function() gfx.drawLine(1, 3, 14, 3) end)
D("line v", 8, 16, function() gfx.drawLine(3, 1, 3, 14) end)
D("line diag", 16, 16, function() gfx.drawLine(1, 1, 14, 9) end)
D("line steep", 16, 16, function() gfx.drawLine(2, 1, 6, 14) end)
D("line width 3 h", 16, 12, function() gfx.setLineWidth(3); gfx.drawLine(2, 5, 13, 5) end)
D("line width 4 diag", 20, 20, function() gfx.setLineWidth(4); gfx.drawLine(3, 3, 16, 12) end)
D("line cap round", 20, 12, function() gfx.setLineWidth(5); gfx.setLineCapStyle(gfx.kLineCapStyleRound); gfx.drawLine(4, 5, 15, 5) end)
D("line cap square", 20, 12, function() gfx.setLineWidth(5); gfx.setLineCapStyle(gfx.kLineCapStyleSquare); gfx.drawLine(4, 5, 15, 5) end)
D("drawRect", 16, 12, function() gfx.drawRect(2, 2, 10, 7) end)
D("drawRect width 2", 16, 12, function() gfx.setLineWidth(2); gfx.drawRect(2, 2, 10, 7) end)
D("drawRect stroke inside", 16, 12, function() gfx.setLineWidth(3); gfx.setStrokeLocation(gfx.kStrokeInside); gfx.drawRect(2, 2, 10, 7) end)
D("drawRect stroke outside", 20, 16, function() gfx.setLineWidth(3); gfx.setStrokeLocation(gfx.kStrokeOutside); gfx.drawRect(5, 5, 10, 6) end)
D("fillRect", 16, 12, function() gfx.fillRect(3, 2, 9, 6) end)
D("fillRect negative size", 16, 12, function() gfx.fillRect(12, 9, -8, -5) end)
D("drawRoundRect", 24, 16, function() gfx.drawRoundRect(2, 2, 19, 11, 4) end)
D("drawRoundRect width 3", 24, 16, function() gfx.setLineWidth(3); gfx.drawRoundRect(2, 2, 19, 11, 4) end)
D("fillRoundRect", 24, 16, function() gfx.fillRoundRect(2, 2, 19, 11, 4) end)
D("drawCircleAtPoint", 24, 24, function() gfx.drawCircleAtPoint(11, 11, 8) end)
D("fillCircleAtPoint", 24, 24, function() gfx.fillCircleAtPoint(11, 11, 8) end)
D("drawCircleInRect", 24, 24, function() gfx.drawCircleInRect(2, 2, 18, 18) end)
D("drawEllipseInRect", 32, 20, function() gfx.drawEllipseInRect(2, 2, 27, 15) end)
D("fillEllipseInRect", 32, 20, function() gfx.fillEllipseInRect(2, 2, 27, 15) end)
D("ellipse angles", 32, 32, function() gfx.drawEllipseInRect(2, 2, 27, 27, 30, 200) end)
D("fill ellipse angles", 32, 32, function() gfx.fillEllipseInRect(2, 2, 27, 27, 30, 200) end)
D("ellipse angles wrap", 32, 32, function() gfx.drawEllipseInRect(2, 2, 27, 27, 300, 60) end)
D("drawArc", 32, 32, function() gfx.drawArc(15, 15, 12, 0, 90) end)
D("drawArc object", 32, 32, function() gfx.drawArc(geom.arc.new(15, 15, 12, 45, 270)) end)
D("drawArc negative", 32, 32, function() gfx.drawArc(15, 15, 12, -90, 90) end)
D("drawTriangle", 24, 24, function() gfx.drawTriangle(2, 20, 12, 2, 21, 18) end)
D("fillTriangle", 24, 24, function() gfx.fillTriangle(2, 20, 12, 2, 21, 18) end)
D("drawPolygon", 24, 24, function() gfx.drawPolygon(geom.polygon.new(2, 2, 20, 4, 14, 20, 4, 16, 2, 2)) end)
D("fillPolygon", 24, 24, function() gfx.fillPolygon(geom.polygon.new(2, 2, 20, 4, 14, 20, 4, 16, 2, 2)) end)
D("fillPolygon star even-odd", 32, 32, function() gfx.setPolygonFillRule(gfx.kPolygonFillEvenOdd); gfx.fillPolygon(geom.polygon.new(16, 1, 25, 30, 1, 11, 31, 11, 7, 30, 16, 1)) end)
D("fillPolygon star non-zero", 32, 32, function() gfx.setPolygonFillRule(gfx.kPolygonFillNonZero); gfx.fillPolygon(geom.polygon.new(16, 1, 25, 30, 1, 11, 31, 11, 7, 30, 16, 1)) end)

-- state: patterns, dither, offsets, clipping
D("pattern checker", 16, 16, function() gfx.setPattern({ 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 }); gfx.fillRect(0, 0, 16, 16) end)
D("pattern stripes", 16, 16, function() gfx.setPattern({ 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0 }); gfx.fillRect(1, 1, 14, 14) end)
D("dither bayer 0.5", 16, 16, function() gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4); gfx.fillRect(0, 0, 16, 16) end)
D("dither bayer 0.25", 16, 16, function() gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer8x8); gfx.fillRect(0, 0, 16, 16) end)
D("dither diagonal", 16, 16, function() gfx.setDitherPattern(0.5, gfx.image.kDitherTypeDiagonalLine); gfx.fillRect(0, 0, 16, 16) end)
D("draw offset", 16, 16, function() gfx.setDrawOffset(3, 2); gfx.fillRect(0, 0, 4, 4) end)
D("clip rect", 16, 16, function() gfx.setClipRect(4, 4, 6, 6); gfx.fillRect(0, 0, 16, 16) end)
D("clip rect with offset", 16, 16, function() gfx.setDrawOffset(2, 2); gfx.setClipRect(4, 4, 6, 6); gfx.fillRect(0, 0, 16, 16) end)
D("screen clip rect", 16, 16, function() gfx.setDrawOffset(2, 2); gfx.setScreenClipRect(4, 4, 6, 6); gfx.fillRect(0, 0, 16, 16) end)
D("color white on black", 8, 8, function() gfx.clear(gfx.kColorBlack); gfx.setColor(gfx.kColorWhite); gfx.fillRect(2, 2, 4, 4) end)
D("color XOR", 8, 8, function() gfx.fillRect(0, 0, 4, 8); gfx.setColor(gfx.kColorXOR); gfx.fillRect(2, 2, 4, 4) end)
D("color clear", 8, 8, function() gfx.fillRect(0, 0, 8, 8); gfx.setColor(gfx.kColorClear); gfx.fillRect(2, 2, 4, 4) end)

-- images
local function src()
    local img = gfx.image.new(8, 6, gfx.kColorClear)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 6)
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(4, 0, 2, 6)
    gfx.popContext()
    return img
end
local modes = { "Copy", "WhiteTransparent", "BlackTransparent", "FillWhite", "FillBlack", "XOR", "NXOR", "Inverted" }
for _, m in ipairs(modes) do
    D("image draw mode " .. m, 12, 10, function()
        gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 5, 12, 5)
        gfx.setImageDrawMode(gfx["kDrawMode" .. m]); src():draw(2, 2)
    end)
end
D("image flip X", 12, 10, function() src():draw(2, 2, gfx.kImageFlippedX) end)
D("image flip Y", 12, 10, function() local i = gfx.image.new(4, 4, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 1); gfx.popContext(); i:draw(2, 2, gfx.kImageFlippedY) end)
D("image source rect", 12, 10, function() src():draw(2, 2, gfx.kImageUnflipped, geom.rect.new(2, 0, 4, 6)) end)
D("image drawCentered", 16, 12, function() src():drawCentered(8, 6) end)
D("image drawAnchored", 16, 12, function() src():drawAnchored(8, 6, 1, 1) end)
D("image drawScaled 2", 20, 16, function() src():drawScaled(1, 1, 2) end)
D("image drawScaled 2x1", 20, 16, function() src():drawScaled(1, 1, 2, 1) end)
D("image drawRotated 90", 20, 20, function() src():drawRotated(10, 10, 90) end)
D("image drawRotated 45", 24, 24, function() src():drawRotated(12, 12, 45) end)
D("image drawRotated scale", 24, 24, function() src():drawRotated(12, 12, 0, 2) end)
D("image drawTiled", 20, 14, function() src():drawTiled(1, 1, 18, 12) end)
D("image drawFaded", 16, 16, function() local i = gfx.image.new(16, 16, gfx.kColorBlack); i:drawFaded(0, 0, 0.5, gfx.image.kDitherTypeBayer4x4) end)
D("image drawBlurred", 24, 24, function() local i = gfx.image.new(24, 24, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(8, 8, 8, 8); gfx.popContext(); i:drawBlurred(0, 0, 2, 1, gfx.image.kDitherTypeBayer4x4) end)
D("image drawSampled", 32, 16, function() local i = gfx.image.new(8, 8, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 4, 4); gfx.fillRect(4, 4, 4, 4); gfx.popContext(); i:drawSampled(0, 0, 32, 16, 0.5, 0.5, 1, 0, 0, 1, 0, 0, 16, 32, true) end)
c("image size", function() return all(src():getSize()) end)
c("image sample out of range", function() return all(src():sample(100, 100)) end)
c("image new filled", function() return dump(gfx.image.new(3, 2, gfx.kColorBlack)) end)
c("image copy", function() return dump(src():copy()) end)
c("image invertedImage", function() return dump(src():invertedImage()) end)
c("image rotatedImage 90", function() return dump(src():rotatedImage(90)) end)
c("image scaledImage", function() return dump(src():scaledImage(2)) end)
c("image fadedImage", function() return dump(gfx.image.new(8, 8, gfx.kColorBlack):fadedImage(0.5, gfx.image.kDitherTypeBayer8x8)) end)
c("image clear", function() local i = src(); i:clear(gfx.kColorWhite); return dump(i) end)
c("image hasMask", function() return all(src():hasMask(), gfx.image.new(2, 2, gfx.kColorWhite):hasMask()) end)
c("image addMask", function() local i = gfx.image.new(4, 2, gfx.kColorBlack); i:addMask(false); return dump(i) end)
c("image addMask default", function() local i = gfx.image.new(4, 2, gfx.kColorBlack); i:addMask(); return dump(i) end)
c("image setInverted", function() local i = src(); i:setInverted(true); local o = gfx.image.new(8, 6, gfx.kColorWhite); gfx.pushContext(o); i:draw(0, 0); gfx.popContext(); return dump(o) end)
c("image vcrPauseFilter", function() return dump(src():vcrPauseFilterImage()) end)

-- text
D("drawText", 64, 20, function() gfx.drawText("Hi 12", 1, 1) end)
D("drawText bold", 64, 20, function() gfx.drawText("*Hi*", 1, 1) end)
D("drawText aligned center", 64, 20, function() gfx.drawTextAligned("Hi", 32, 1, kTextAlignment.center) end)
D("drawText aligned right", 64, 20, function() gfx.drawTextAligned("Hi", 63, 1, kTextAlignment.right) end)
D("drawTextInRect wrap", 48, 48, function() gfx.drawTextInRect("one two three four", 1, 1, 46, 46) end)
D("drawTextInRect center", 48, 48, function() gfx.drawTextInRect("one two three", 1, 1, 46, 46, nil, nil, kTextAlignment.center) end)
D("drawTextInRect truncate", 48, 24, function() gfx.drawTextInRect("one two three four five six", 1, 1, 46, 22, nil, "...") end)
c("getTextSize", function() return all(gfx.getTextSize("Hello world")) end)
c("getTextSize multiline", function() return all(gfx.getTextSize("Hello\nworld")) end)
c("getTextSize leading", function() return all(gfx.getTextSize("Hello\nworld", nil, 5)) end)
c("getTextSizeForMaxWidth", function() return all(gfx.getTextSizeForMaxWidth("one two three four", 40)) end)
c("font height and tracking", function() local f = gfx.getSystemFont(); return all(f:getHeight(), f:getTracking(), f:getLeading()) end)
c("font getTextWidth", function() return all(gfx.getSystemFont():getTextWidth("Hello world")) end)
c("imageWithText", function() local i = gfx.imageWithText("Hi there", 60, 30); return v(i) end)

-- sprites
c("sprite new and position", function() local s = gfx.sprite.new(); s:moveTo(10, 20); return all(s:getPosition()) .. " | " .. all(s.x, s.y) end)
c("sprite size and bounds", function() local s = gfx.sprite.new(); s:setSize(10, 6); s:moveTo(50, 40); return all(s:getSize()) .. " | " .. v(s:getBoundsRect()) end)
c("sprite center", function() local s = gfx.sprite.new(); s:setSize(10, 6); s:setCenter(0, 0); s:moveTo(50, 40); return v(s:getBoundsRect()) .. " | " .. all(s:getCenter()) end)
c("sprite setBounds", function() local s = gfx.sprite.new(); s:setBounds(5, 6, 7, 8); return v(s:getBoundsRect()) .. " | " .. all(s:getPosition()) end)
c("sprite image sets size", function() local s = gfx.sprite.new(src()); return all(s:getSize()) end)
c("sprite setImage scale", function() local s = gfx.sprite.new(); s:setImage(src(), gfx.kImageUnflipped, 2); return all(s:getSize()) .. " | " .. all(s:getScale()) end)
c("sprite setImage default scale", function() local s = gfx.sprite.new(); s:setImage(src()); return all(s:getScale()) end)
c("sprite setScale", function() local s = gfx.sprite.new(src()); s:setScale(2, 3); return all(s:getSize()) end)
c("sprite rotation", function() local s = gfx.sprite.new(src()); s:setRotation(90); return all(s:getRotation()) .. " | " .. all(s:getSize()) end)
c("sprite collideRect", function() local s = gfx.sprite.new(); s:setSize(10, 10); s:moveTo(20, 20); s:setCollideRect(1, 2, 3, 4); return v(s:getCollideRect()) .. " | " .. v(s:getCollideBounds()) end)
c("sprite zIndex", function() local s = gfx.sprite.new(); s:setZIndex(7); return all(s:getZIndex()) end)
c("sprite visible", function() local s = gfx.sprite.new(); s:setVisible(false); return all(s:isVisible()) end)
c("sprite tag", function() local s = gfx.sprite.new(); s:setTag(12); return all(s:getTag()) end)
c("sprite count add remove", function()
    gfx.sprite.removeAll()
    local a, b = gfx.sprite.new(), gfx.sprite.new()
    a:add(); b:add()
    local n1 = gfx.sprite.spriteCount()
    a:remove()
    local n2 = gfx.sprite.spriteCount()
    gfx.sprite.removeAll()
    return all(n1, n2, gfx.sprite.spriteCount())
end)
local function box(x, y, w, h)
    local s = gfx.sprite.new(); s:setSize(w, h); s:setCenter(0, 0); s:moveTo(x, y); s:setCollideRect(0, 0, w, h); s:add(); return s
end
local function colsummary(cols)
    local parts = {}
    for i, col in ipairs(cols) do
        parts[#parts + 1] = string.format("%s,%s,touch(%s,%s),move(%s,%s),n(%s,%s)", tostring(col.type), v(col.overlaps), v(col.touch.x), v(col.touch.y), v(col.move.x), v(col.move.y), v(col.normal.x), v(col.normal.y))
    end
    return table.concat(parts, ";")
end
c("moveWithCollisions slide", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); box(20, 0, 10, 10)
    local x, y, cols, n = a:moveWithCollisions(15, 3)
    local r = all(x, y, n) .. " | " .. colsummary(cols)
    gfx.sprite.removeAll(); return r
end)
c("moveWithCollisions overlap", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); box(20, 0, 10, 10)
    a.collisionResponse = gfx.sprite.kCollisionTypeOverlap
    local x, y, cols, n = a:moveWithCollisions(15, 3)
    local r = all(x, y, n) .. " | " .. colsummary(cols)
    gfx.sprite.removeAll(); return r
end)
c("moveWithCollisions freeze", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); box(20, 0, 10, 10)
    function a:collisionResponse() return gfx.sprite.kCollisionTypeFreeze end
    local x, y, cols, n = a:moveWithCollisions(15, 3)
    local r = all(x, y, n) .. " | " .. colsummary(cols)
    gfx.sprite.removeAll(); return r
end)
c("moveWithCollisions bounce", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); box(20, 0, 10, 10)
    function a:collisionResponse() return gfx.sprite.kCollisionTypeBounce end
    local x, y, cols, n = a:moveWithCollisions(15, 3)
    local r = all(x, y, n) .. " | " .. colsummary(cols)
    gfx.sprite.removeAll(); return r
end)
c("checkCollisions", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); box(20, 0, 10, 10)
    local x, y, cols, n = a:checkCollisions(15, 0)
    local r = all(x, y, n) .. " | pos " .. all(a:getPosition())
    gfx.sprite.removeAll(); return r
end)
c("collision groups mask", function()
    gfx.sprite.removeAll()
    local a = box(0, 0, 10, 10); local b = box(20, 0, 10, 10)
    a:setGroups({ 1 }); a:setCollidesWithGroups({ 2 }); b:setGroups({ 3 })
    local x, y, cols, n = a:moveWithCollisions(15, 0)
    local r = all(x, y, n)
    gfx.sprite.removeAll(); return r
end)
c("querySpritesAtPoint", function() gfx.sprite.removeAll(); box(0, 0, 10, 10); box(5, 5, 10, 10); local r = #gfx.sprite.querySpritesAtPoint(7, 7) .. "," .. #gfx.sprite.querySpritesAtPoint(1, 1) .. "," .. #gfx.sprite.querySpritesAtPoint(10, 10); gfx.sprite.removeAll(); return r end)
c("querySpritesInRect", function() gfx.sprite.removeAll(); box(0, 0, 10, 10); box(30, 30, 10, 10); local r = #gfx.sprite.querySpritesInRect(5, 5, 10, 10) .. "," .. #gfx.sprite.querySpritesInRect(0, 0, 50, 50) .. "," .. #gfx.sprite.querySpritesInRect(10, 0, 5, 5); gfx.sprite.removeAll(); return r end)
c("querySpritesAlongLine", function() gfx.sprite.removeAll(); box(10, 0, 10, 10); box(30, 0, 10, 10); local r = #gfx.sprite.querySpritesAlongLine(0, 5, 50, 5) .. "," .. #gfx.sprite.querySpritesAlongLine(0, 50, 50, 50); gfx.sprite.removeAll(); return r end)
c("overlappingSprites", function() gfx.sprite.removeAll(); local a = box(0, 0, 10, 10); box(5, 5, 10, 10); box(10, 0, 5, 5); local r = #a:overlappingSprites() .. "," .. #gfx.sprite.allOverlappingSprites(); gfx.sprite.removeAll(); return r end)
c("sprite draw order", function()
    gfx.sprite.removeAll()
    local i1 = gfx.image.new(8, 8, gfx.kColorBlack)
    local i2 = gfx.image.new(8, 8, gfx.kColorWhite)
    local a = gfx.sprite.new(i1); a:setCenter(0, 0); a:moveTo(0, 0); a:setZIndex(2); a:add()
    local b = gfx.sprite.new(i2); b:setCenter(0, 0); b:moveTo(4, 4); b:setZIndex(1); b:add()
    gfx.sprite.update()
    local d = gfx.getWorkingImage()
    local out = gfx.image.new(16, 16)
    gfx.pushContext(out); d:draw(0, 0); gfx.popContext()
    gfx.sprite.removeAll()
    return dump(out)
end)

-- files, json, datastore
c("file write read", function()
    local f = playdate.file.open("t1.txt", playdate.file.kFileWrite); f:write("abc\ndef"); f:close()
    f = playdate.file.open("t1.txt"); local data, n = f:read(100); f:close()
    return all(data, n)
end)
c("file readline LF CR CRLF empty", function()
    local f = playdate.file.open("t2.txt", playdate.file.kFileWrite); f:write("a\nb\rc\r\nd\n\ne"); f:close()
    f = playdate.file.open("t2.txt"); local lines = {}
    for i = 1, 8 do lines[#lines + 1] = v(f:readline()) end
    f:close(); return table.concat(lines, ",")
end)
c("file seek tell", function()
    local f = playdate.file.open("t1.txt"); f:seek(2); local t1 = f:tell(); local d = f:read(2); local t2 = f:tell()
    f:seek(-1, playdate.file.kSeekFromEnd); local t3 = f:tell(); f:close()
    return all(t1, d, t2, t3)
end)
c("file append", function()
    local f = playdate.file.open("t3.txt", playdate.file.kFileWrite); f:write("x"); f:close()
    f = playdate.file.open("t3.txt", playdate.file.kFileAppend); f:write("y"); f:close()
    f = playdate.file.open("t3.txt"); local d = f:read(10); f:close(); return all(d)
end)
c("file write returns", function() local f = playdate.file.open("t4.txt", playdate.file.kFileWrite); local r = table.pack(f:write("hello")); f:close(); return all(table.unpack(r, 1, r.n)) end)
c("file open missing", function() return all(playdate.file.open("nope/missing.txt")) end)
c("file exists isdir getSize getType", function() return all(playdate.file.exists("t1.txt"), playdate.file.isdir("t1.txt"), playdate.file.getSize("t1.txt"), playdate.file.getType("t1.txt"), playdate.file.exists("zzz")) end)
c("file mkdir listFiles", function()
    playdate.file.mkdir("d1"); playdate.file.mkdir("d1/sub")
    local f = playdate.file.open("d1/a.txt", playdate.file.kFileWrite); f:write("1"); f:close()
    local l = playdate.file.listFiles("d1"); table.sort(l); return all(table.unpack(l))
end)
c("file rename delete", function()
    local f = playdate.file.open("r1.txt", playdate.file.kFileWrite); f:write("1"); f:close()
    local a = playdate.file.rename("r1.txt", "r2.txt")
    local b = playdate.file.exists("r1.txt"); local cc = playdate.file.exists("r2.txt")
    local d = playdate.file.delete("r2.txt"); return all(a, b, cc, d, playdate.file.exists("r2.txt"))
end)
c("file delete nonempty dir", function() return all(playdate.file.delete("d1"), playdate.file.exists("d1"), playdate.file.delete("d1", true), playdate.file.exists("d1")) end)
c("file modtime fields", function() local m = playdate.file.modtime("t1.txt"); local keys = {}; for k in pairs(m) do keys[#keys + 1] = k end; table.sort(keys); return table.concat(keys, ",") end)
c("json encode", function() return json.encode({ a = 1, b = { 1, 2, 3 }, c = "x", d = true }) end)
c("json encode array", function() return json.encode({ 1, 2.5, "a", false }) end)
c("json encode empty table", function() return json.encode({}) end)
c("json encodePretty", function() return json.encodePretty({ a = 1, b = { 2 } }) end)
c("json decode", function() return v(json.decode('{"a":1,"b":[1,2,{"c":null}],"d":1.5,"e":"s","f":false}')) end)
c("json decode integer vs float", function() local t = json.decode('{"i":3,"f":3.0}'); return all(t.i, t.f) end)
c("json decode invalid", function() return all(json.decode("{bad")) end)
c("json null", function() return all(tostring(json.null), json.encode({ a = json.null })) end)
c("datastore write read", function() playdate.datastore.write({ x = 1, y = { 2, 3 } }, "ds1"); return v(playdate.datastore.read("ds1")) end)
c("datastore default name", function() playdate.datastore.write({ z = 5 }); return v(playdate.datastore.read()) end)
c("datastore delete", function() playdate.datastore.write({ q = 1 }, "ds2"); local d = playdate.datastore.delete("ds2"); return all(d, playdate.datastore.read("ds2")) end)

-- time and system
c("getTime keys", function() local t = playdate.getTime(); local keys = {}; for k in pairs(t) do keys[#keys + 1] = k end; table.sort(keys); return table.concat(keys, ",") end)
c("epoch round trip", function() local e = playdate.epochFromTime({ year = 2024, month = 3, day = 4, hour = 5, minute = 6, second = 7, millisecond = 8 }); local t = playdate.timeFromEpoch(e, 0); return all(e) .. " | " .. v(t) end)
c("epochFromGMTTime", function() return all(playdate.epochFromGMTTime({ year = 2000, month = 1, day = 1, hour = 0, minute = 0, second = 0 })) end)
c("GMTTimeFromEpoch", function() return v(playdate.GMTTimeFromEpoch(86400 * 365, 0)) end)
c("getSecondsSinceEpoch types", function() local s, ms = playdate.getSecondsSinceEpoch(); return math.type(s) .. "," .. math.type(ms) end)
c("crank defaults", function() return all(playdate.getCrankPosition(), playdate.isCrankDocked(), playdate.getCrankChange()) end)
c("getCrankTicks", function() return all(playdate.getCrankTicks(6)) end)
c("buttons idle", function() return all(playdate.getButtonState()) end)
c("button constants", function() return all(playdate.kButtonLeft, playdate.kButtonRight, playdate.kButtonUp, playdate.kButtonDown, playdate.kButtonB, playdate.kButtonA) end)
c("menu items", function()
    local m = playdate.getSystemMenu()
    local a = m:addMenuItem("A", function() end)
    local b = m:addCheckmarkMenuItem("B", true, function() end)
    local o = m:addOptionsMenuItem("C", { "x", "y" }, "y", function() end)
    local n = #m:getMenuItems()
    local r = all(n, a:getTitle(), b:getValue(), o:getValue())
    m:removeAllMenuItems(); return r .. " | after " .. #m:getMenuItems()
end)
c("display scale invert offset", function()
    local d = playdate.display
    d.setScale(2); local s = d.getScale(); local w = d.getWidth(); d.setScale(1)
    d.setInverted(true); local inv = d.getInverted(); d.setInverted(false)
    d.setOffset(3, 4); local ox, oy = d.getOffset(); d.setOffset(0, 0)
    return all(s, w, inv, ox, oy)
end)
c("refresh rate", function() playdate.display.setRefreshRate(20); local r = playdate.display.getRefreshRate(); playdate.display.setRefreshRate(30); return all(r) end)

-- sound object state (no audio output involved)
c("synth volume", function() local s = playdate.sound.synth.new(playdate.sound.kWaveSquare); s:setVolume(0.25); return all(s:getVolume()) end)
c("synth playing", function() local s = playdate.sound.synth.new(); return all(s:isPlaying()) end)
c("channel volume", function() local ch = playdate.sound.channel.new(); ch:setVolume(0.5); local r = all(ch:getVolume()); ch:remove(); return r end)
c("sample new size", function() local s = playdate.sound.sample.new(1, playdate.sound.kFormat16bitMono); return all(s:getLength()) end)
c("sampleplayer from sample", function() local s = playdate.sound.sample.new(0.5, playdate.sound.kFormat16bitMono); local p = playdate.sound.sampleplayer.new(s); return all(p:getLength(), p:isPlaying()) end)
c("sampleplayer rate", function() local p = playdate.sound.sampleplayer.new(playdate.sound.sample.new(0.5, playdate.sound.kFormat16bitMono)); p:setRate(2); return all(p:getRate()) end)
c("sampleplayer volume", function() local p = playdate.sound.sampleplayer.new(playdate.sound.sample.new(0.5, playdate.sound.kFormat16bitMono)); p:setVolume(0.3, 0.6); return all(p:getVolume()) end)
c("fileplayer rate", function() local p = playdate.sound.fileplayer.new(); p:setRate(1.5); return all(p:getRate()) end)
c("lfo and envelope", function() local l = playdate.sound.lfo.new(playdate.sound.kLFOSine); l:setRate(2); local e = playdate.sound.envelope.new(0.1, 0.2, 0.5, 0.3); return all(l:getValue(), e:getValue()) end)
c("sequence new", function() local s = playdate.sound.sequence.new(); return all(s:getTrackCount(), s:getLength(), s.getTempo and s:getTempo() or "noTempo") end)
c("track notes", function() local t = playdate.sound.track.new(); t:addNote(1, 60, 4); t:addNote(5, 62, 2); return all(#t:getNotes(), t:getLength()) end)
c("getCurrentTime type", function() return math.type(playdate.sound.getCurrentTime()) end)
c("headphone state", function() return all(playdate.sound.getHeadphoneState()) end)

function runCases3(write, skip)
    skip = skip or {}
    for _, case in ipairs(cases3) do
      if not skip[case[1]] then
        gfx.setLineWidth(1); gfx.setLineCapStyle(gfx.kLineCapStyleButt); gfx.setStrokeLocation(gfx.kStrokeCentered)
        gfx.setDrawOffset(0, 0); gfx.clearClipRect(); gfx.setImageDrawMode(gfx.kDrawModeCopy); gfx.setColor(gfx.kColorBlack)
        local ok, r = pcall(case[2])
        local out = ok and tostring(r) or ("ERR " .. tostring(r))
        out = out:gsub("\n", "\\n"):gsub("\t", "\\t")
        write(case[1] .. "\t" .. out)
      end
    end
end
