-- Coverage probe for functions not reached by cases1-3.
local gfx = playdate.graphics
local geom = playdate.geometry
local snd = playdate.sound
local pf = playdate.pathfinder
local cases4 = {}
local function c(name, f) cases4[#cases4 + 1] = { name, f } end

local function num(x)
    if math.type(x) == "integer" then return tostring(x) .. "i" end
    local s = string.format("%.3f", x)
    if s == "-0.000" then s = "0.000" end
    return s .. "f"
end
local v
local function node(n) return "N(" .. tostring(n.id) .. "," .. num(n.x) .. "," .. num(n.y) .. ")" end
v = function(x)
    local t = type(x)
    if t == "number" then return num(x) end
    if t == "string" then return string.format("%q", x) end
    if t == "nil" or t == "boolean" then return tostring(x) end
    local mt = getmetatable(x)
    if mt == geom.rect then return "R(" .. num(x.x) .. "," .. num(x.y) .. "," .. num(x.width) .. "," .. num(x.height) .. ")" end
    if mt == geom.point then return "P(" .. num(x.x) .. "," .. num(x.y) .. ")" end
    if mt == gfx.image then local w, h = x:getSize(); return "IMG(" .. w .. "x" .. h .. ")" end
    if mt == pf.node then return node(x) end
    if t == "table" and mt == nil then
        local keys = {}
        for k in pairs(x) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. v(x[k]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "<" .. t .. ">"
end
local function all(...)
    local p = table.pack(...)
    local out = {}
    for i = 1, p.n do out[#out + 1] = v(p[i]) end
    return table.concat(out, " | ")
end
local function ok(...) return "ok " .. all(...) end
local function ids(list) local o = {}; for i, n in ipairs(list or {}) do o[i] = tostring(type(n) == "number" and n or n.id) end; return "[" .. table.concat(o, ",") .. "]" end
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
    gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); f(img); gfx.popContext()
    return dump(img)
end
local function D(name, w, h, f) c(name, function() return draw(w, h, f) end) end
local function table3()
    local it = gfx.imagetable.new(3)
    it:setImage(1, gfx.image.new(8, 8, gfx.kColorWhite))
    it:setImage(2, gfx.image.new(8, 8, gfx.kColorBlack))
    local ch = gfx.image.new(8, 8, gfx.kColorWhite)
    gfx.pushContext(ch); gfx.setColor(gfx.kColorBlack); for i = 0, 7 do gfx.drawPixel(i, i) end; gfx.popContext()
    it:setImage(3, ch)
    return it
end

-- graphics state getters and setters
c("graphics.getColor", function() gfx.setColor(gfx.kColorWhite); local r = gfx.getColor(); gfx.setColor(gfx.kColorBlack); return all(r) end)
c("graphics.setBackgroundColor/getBackgroundColor", function() gfx.setBackgroundColor(gfx.kColorBlack); local r = gfx.getBackgroundColor(); gfx.setBackgroundColor(gfx.kColorWhite); return all(r) end)
c("graphics.getLineWidth", function() gfx.setLineWidth(4); local r = gfx.getLineWidth(); gfx.setLineWidth(1); return all(r) end)
c("graphics.getStrokeLocation", function() gfx.setStrokeLocation(gfx.kStrokeInside); local r = gfx.getStrokeLocation(); gfx.setStrokeLocation(gfx.kStrokeCentered); return all(r) end)
c("graphics.getImageDrawMode", function() gfx.setImageDrawMode(gfx.kDrawModeXOR); local r = gfx.getImageDrawMode(); gfx.setImageDrawMode(gfx.kDrawModeCopy); return all(r) end)
c("graphics.getDrawOffset", function() gfx.setDrawOffset(5, -3); local r = all(gfx.getDrawOffset()); gfx.setDrawOffset(0, 0); return r end)
c("graphics.getClipRect", function() gfx.setClipRect(1, 2, 30, 40); local r = all(gfx.getClipRect()); gfx.clearClipRect(); return r end)
c("graphics.getClipRect cleared", function() gfx.clearClipRect(); return all(gfx.getClipRect()) end)
c("graphics.getScreenClipRect", function() gfx.setDrawOffset(3, 3); gfx.setScreenClipRect(1, 2, 30, 40); local r = all(gfx.getScreenClipRect()); gfx.clearClipRect(); gfx.setDrawOffset(0, 0); return r end)
c("graphics.getClipRect with offset", function() gfx.setDrawOffset(3, 3); gfx.setClipRect(1, 2, 30, 40); local r = all(gfx.getClipRect()); gfx.clearClipRect(); gfx.setDrawOffset(0, 0); return r end)
c("graphics.getFont/setFont", function() local f = gfx.getFont(); gfx.setFont(f); return all(gfx.getFont() == f, f:getHeight()) end)
c("graphics.getFont variants", function() return all(gfx.getFont(gfx.font.kVariantBold) ~= nil, gfx.getFont(gfx.font.kVariantItalic) ~= nil) end)
c("graphics.setFontTracking/getFontTracking", function() gfx.setFontTracking(3); local r = gfx.getFontTracking(); gfx.setFontTracking(0); return all(r) end)
D("graphics.setFontTracking draw", 64, 20, function() gfx.setFontTracking(4); gfx.drawText("ab", 1, 1); gfx.setFontTracking(0) end)
c("graphics.setFontFamily", function() local f = gfx.getSystemFont(); gfx.setFontFamily({ [gfx.font.kVariantNormal] = f, [gfx.font.kVariantBold] = f }); return "ok" end)
c("graphics.lockFocus/unlockFocus", function() local i = gfx.image.new(4, 4, gfx.kColorWhite); gfx.lockFocus(i); gfx.fillRect(0, 0, 2, 2); gfx.unlockFocus(); return dump(i) end)
c("graphics.getDisplayImage type", function() return v(gfx.getDisplayImage()) end)
c("graphics.getWorkingImage type", function() return v(gfx.getWorkingImage()) end)
c("graphics.imageSizeAtPath", function() return all(gfx.imageSizeAtPath("assets/img10x6")) end)
c("graphics.imageSizeAtPath missing", function() return all(gfx.imageSizeAtPath("assets/none")) end)
c("graphics.checkAlphaCollision overlap", function() local a = gfx.image.new(4, 4, gfx.kColorBlack); return all(gfx.checkAlphaCollision(a, 0, 0, gfx.kImageUnflipped, a, 2, 2, gfx.kImageUnflipped)) end)
c("graphics.checkAlphaCollision apart", function() local a = gfx.image.new(4, 4, gfx.kColorBlack); return all(gfx.checkAlphaCollision(a, 0, 0, gfx.kImageUnflipped, a, 10, 10, gfx.kImageUnflipped)) end)
c("graphics.checkAlphaCollision transparent", function() local a = gfx.image.new(4, 4, gfx.kColorClear); local b = gfx.image.new(4, 4, gfx.kColorBlack); return all(gfx.checkAlphaCollision(a, 0, 0, gfx.kImageUnflipped, b, 1, 1, gfx.kImageUnflipped)) end)
c("graphics.perlin", function() return all(gfx.perlin(0.5, 0.25, 0.75), gfx.perlin(1.3, 2.7, 0, 0, 2, 0.5), gfx.perlin(0, 0, 0)) end)
c("graphics.perlin repeat", function() return all(gfx.perlin(0.5, 0.5, 0, 4), gfx.perlin(4.5, 0.5, 0, 4)) end)
c("graphics.perlinArray", function() local a = gfx.perlinArray(4, 0.1, 0.2, 0.3); return all(#a, a[1], a[4]) end)
D("graphics.fillCircleInRect", 24, 24, function() gfx.fillCircleInRect(2, 2, 18, 18) end)
D("graphics.setStencilImage", 16, 16, function() local s = gfx.image.new(32, 16, gfx.kColorBlack); gfx.pushContext(s); gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 8, 16); gfx.popContext(); gfx.setStencilImage(s); gfx.fillRect(0, 0, 16, 16); gfx.clearStencil() end)
D("graphics.setStencilImage tile", 16, 16, function() local s = gfx.image.new(32, 4, gfx.kColorBlack); gfx.pushContext(s); gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 2, 2); gfx.popContext(); gfx.setStencilImage(s, true); gfx.fillRect(0, 0, 16, 16); gfx.clearStencilImage() end)
D("graphics.setStencilPattern", 16, 16, function() gfx.setStencilPattern({ 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00 }); gfx.fillRect(0, 0, 16, 16); gfx.clearStencil() end)
D("graphics.setStencilPattern level", 16, 16, function() gfx.setStencilPattern(0.5, gfx.image.kDitherTypeBayer4x4); gfx.fillRect(0, 0, 16, 16); gfx.clearStencil() end)
c("graphics.getLocalizedText missing key", function() return all(gfx.getLocalizedText("no_such_key")) end)
D("graphics.drawLocalizedText missing key", 64, 20, function() gfx.drawLocalizedText("no_such_key", 1, 1) end)

-- images: loading, masks, transforms, blending
c("image.new from path", function() return dump(gfx.image.new("assets/img10x6")) end)
c("image.new missing path", function() return all(gfx.image.new("assets/none")) end)
c("image:load", function() local i = gfx.image.new(2, 2); local r = i:load("assets/img10x6"); return all(r) .. " " .. dump(i) end)
D("image:drawIgnoringOffset", 16, 12, function() gfx.setDrawOffset(4, 4); gfx.image.new(4, 4, gfx.kColorBlack):drawIgnoringOffset(1, 1); gfx.setDrawOffset(0, 0) end)
D("image:drawWithTransform", 24, 24, function() local t = geom.affineTransform.new(); t:scale(2); t:translate(4, 4); gfx.image.new(4, 3, gfx.kColorBlack):drawWithTransform(t, 2, 2) end)
c("image:transformedImage", function() local t = geom.affineTransform.new(); t:rotate(90); return dump(gfx.image.new("assets/img10x6"):transformedImage(t)) end)
c("image:blurredImage", function() local i = gfx.image.new(12, 12, gfx.kColorWhite); gfx.pushContext(i); gfx.setColor(gfx.kColorBlack); gfx.fillRect(4, 4, 4, 4); gfx.popContext(); return dump(i:blurredImage(1, 1, gfx.image.kDitherTypeBayer4x4)) end)
c("image:blendWithImage", function() local a = gfx.image.new(8, 8, gfx.kColorBlack); local b = gfx.image.new(8, 8, gfx.kColorWhite); return dump(a:blendWithImage(b, 0.5, gfx.image.kDitherTypeBayer4x4)) end)
c("image:setMaskImage/getMaskImage", function() local i = gfx.image.new(4, 2, gfx.kColorBlack); local m = gfx.image.new(4, 2, gfx.kColorBlack); gfx.pushContext(m); gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 2, 2); gfx.popContext(); i:setMaskImage(m); return dump(i) .. " mask " .. dump(i:getMaskImage()) end)
c("image:getMaskImage none", function() return all(gfx.image.new(4, 2, gfx.kColorBlack):getMaskImage()) end)
c("image:removeMask", function() local i = gfx.image.new(4, 2, gfx.kColorClear); i:removeMask(); return dump(i) .. " " .. tostring(i:hasMask()) end)
c("image:clearMask default", function() local i = gfx.image.new(4, 2, gfx.kColorClear); i:clearMask(); return dump(i) end)
c("image:clearMask boolean argument", function() local i = gfx.image.new(4, 2, gfx.kColorClear); i:clearMask(true); return dump(i) end)
c("image:clearMask number 0", function() local i = gfx.image.new(4, 2, gfx.kColorBlack); i:addMask(); i:clearMask(0); return dump(i) end)

-- image tables and tilemaps
c("imagetable.new count", function() local it = gfx.imagetable.new(3); return all(it:getLength(), #it) end)
c("imagetable.new from path", function() local it = gfx.imagetable.new("assets/tiles"); return all(it:getLength(), it:getSize()) end)
c("imagetable:getImage", function() local it = gfx.imagetable.new("assets/tiles"); return dump(it:getImage(2)) .. " " .. dump(it:getImage(3)) end)
c("imagetable:getImage out of range", function() local it = gfx.imagetable.new("assets/tiles"); return all(it:getImage(0), it:getImage(4)) end)
c("imagetable:getImage xy", function() local it = gfx.imagetable.new("assets/tiles"); return dump(it:getImage(3, 1)) end)
c("imagetable index operator", function() local it = gfx.imagetable.new("assets/tiles"); return dump(it[2]) end)
c("imagetable:load", function() local it = gfx.imagetable.new(1); local r = it:load("assets/tiles"); return all(r, it:getLength()) end)
D("imagetable:drawImage", 24, 10, function() gfx.imagetable.new("assets/tiles"):drawImage(2, 1, 1) end)
c("tilemap setTiles/getTiles", function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); local d, w = tm:getTiles(); return all(w, table.concat(d, ","), tm:getSize()) end)
c("tilemap get/setTileAtPosition", function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); tm:setTileAtPosition(1, 2, 3); return all(tm:getTileAtPosition(1, 1), tm:getTileAtPosition(3, 1), tm:getTileAtPosition(1, 2), tm:getTileAtPosition(9, 9)) end)
c("tilemap getPixelSize/getTileSize", function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); return all(tm:getPixelSize()) .. " | " .. all(tm:getTileSize()) end)
c("tilemap:getCollisionRects", function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 2, 2, 1, 0, 2, 1 }, 3); local r = tm:getCollisionRects({ 1 }); local o = {}; for i, x in ipairs(r) do o[i] = v(x) end; return #r .. " " .. table.concat(o, ";") end)
D("tilemap:draw", 24, 16, function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); tm:draw(0, 0) end)
D("tilemap:draw sourceRect", 24, 16, function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); tm:draw(0, 0, geom.rect.new(8, 0, 16, 16)) end)
D("tilemap:drawIgnoringOffset", 24, 16, function() gfx.setDrawOffset(5, 5); local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0, 2, 1 }, 3); tm:drawIgnoringOffset(0, 0); gfx.setDrawOffset(0, 0) end)
D("nineSlice:drawInRect", 24, 16, function() local ns = gfx.nineSlice.new("assets/frame", 3, 3, 3, 3); ns:drawInRect(1, 1, 22, 14) end)
c("nineSlice:getSize", function() local ns = gfx.nineSlice.new("assets/frame", 3, 3, 3, 3); return all(ns:getSize()) end)

-- fonts
c("font:setTracking/getTracking", function() local f = gfx.getSystemFont(); f:setTracking(2); local r = f:getTracking(); f:setTracking(0); return all(r) end)
c("font:setLeading/getLeading", function() local f = gfx.getSystemFont(); f:setLeading(3); local r = f:getLeading(); f:setLeading(0); return all(r) end)
c("font:getGlyph", function() return v(gfx.getSystemFont():getGlyph("A")) end)
c("font.newFamily", function() local fam = gfx.font.newFamily({ [gfx.font.kVariantNormal] = "/System/Fonts/Asheville-Sans-14-Light" }); return type(fam) end)

-- sprites
local function spr(w, h) local s = gfx.sprite.new(); s:setSize(w, h); return s end
c("sprite:getImage", function() local i = gfx.image.new(3, 2); local s = gfx.sprite.new(i); return all(s:getImage() == i) end)
c("sprite:moveBy", function() local s = gfx.sprite.new(); s:moveTo(1, 2); s:moveBy(3, 4); return all(s:getPosition()) end)
c("sprite:getCenterPoint", function() local s = spr(10, 10); s:setCenter(0.25, 0.75); return v(s:getCenterPoint()) end)
c("sprite:setUpdatesEnabled", function() local s = gfx.sprite.new(); s:setUpdatesEnabled(false); return all(s:updatesEnabled()) end)
c("sprite:setImageFlip/getImageFlip", function() local s = gfx.sprite.new(gfx.image.new(2, 2)); s:setImageFlip(gfx.kImageFlippedX); return all(s:getImageFlip()) end)
c("sprite:setIgnoresDrawOffset", function() local s = gfx.sprite.new(); s:setIgnoresDrawOffset(true); return "ok" end)
c("sprite:setOpaque/isOpaque", function() local s = gfx.sprite.new(); local a = s:isOpaque(); s:setOpaque(true); return all(a, s:isOpaque()) end)
c("sprite:setCollisionsEnabled", function() local s = gfx.sprite.new(); local a = s:collisionsEnabled(); s:setCollisionsEnabled(false); return all(a, s:collisionsEnabled()) end)
c("sprite group masks", function() local s = gfx.sprite.new(); s:setGroupMask(0x5); s:setCollidesWithGroupsMask(0x3); local r = all(s:getGroupMask(), s:getCollidesWithGroupsMask()); s:resetGroupMask(); s:resetCollidesWithGroupsMask(); return r .. " | " .. all(s:getGroupMask(), s:getCollidesWithGroupsMask()) end)
c("sprite setGroups mask value", function() local s = gfx.sprite.new(); s:setGroups({ 1, 3 }); s:setCollidesWithGroups({ 2 }); return all(s:getGroupMask(), s:getCollidesWithGroupsMask()) end)
c("sprite:clearCollideRect", function() local s = spr(10, 10); s:setCollideRect(0, 0, 10, 10); s:clearCollideRect(); return v(s:getCollideRect()) end)
c("sprite:setAlwaysRedraw/getAlwaysRedraw", function() local a = gfx.sprite.getAlwaysRedraw(); gfx.sprite.setAlwaysRedraw(true); local b = gfx.sprite.getAlwaysRedraw(); gfx.sprite.setAlwaysRedraw(false); return all(a, b) end)
c("sprite addSprite/removeSprite/getAllSprites", function() gfx.sprite.removeAll(); local s = gfx.sprite.new(); gfx.sprite.addSprite(s); local n = #gfx.sprite.getAllSprites(); gfx.sprite.removeSprite(s); return all(n, #gfx.sprite.getAllSprites()) end)
c("sprite.removeSprites", function() gfx.sprite.removeAll(); local a, b = gfx.sprite.new(), gfx.sprite.new(); a:add(); b:add(); gfx.sprite.removeSprites({ a, b }); return all(gfx.sprite.spriteCount()) end)
c("sprite:markDirty/addDirtyRect", function() local s = gfx.sprite.new(); s:markDirty(); gfx.sprite.addDirtyRect(0, 0, 10, 10); return "ok" end)
c("sprite clip rects in range", function() gfx.sprite.setClipRectsInRange(0, 0, 10, 10, 1, 5); gfx.sprite.clearClipRectsInRange(1, 5); return "ok" end)
c("sprite:setStencilPattern/clearStencil", function() local s = gfx.sprite.new(); s:setStencilPattern({ 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0 }); s:clearStencil(); return "ok" end)
c("sprite:setStencilImage", function() local s = gfx.sprite.new(); s:setStencilImage(gfx.image.new(8, 8, gfx.kColorWhite)); s:clearStencil(); return "ok" end)
c("sprite:setTilemap", function() local tm = gfx.tilemap.new(); tm:setImageTable(table3()); tm:setTiles({ 1, 2, 3, 0 }, 2); local s = gfx.sprite.new(); s:setTilemap(tm); return all(s:getSize()) end)
c("sprite:alphaCollision", function() gfx.sprite.removeAll(); local a = gfx.sprite.new(gfx.image.new(4, 4, gfx.kColorBlack)); a:moveTo(0, 0); local b = gfx.sprite.new(gfx.image.new(4, 4, gfx.kColorBlack)); b:moveTo(2, 2); local r = all(a:alphaCollision(b)); b:moveTo(20, 20); return r .. " | " .. all(a:alphaCollision(b)) end)
c("sprite.querySpriteInfoAlongLine", function()
    gfx.sprite.removeAll()
    local s = spr(10, 10); s:setCenter(0, 0); s:moveTo(10, 0); s:setCollideRect(0, 0, 10, 10); s:add()
    local info = gfx.sprite.querySpriteInfoAlongLine(0, 5, 50, 5)
    local r = #info
    if info[1] then r = r .. " " .. all(info[1].ti1, info[1].ti2) .. " " .. v(info[1].entryPoint) .. " " .. v(info[1].exitPoint) end
    gfx.sprite.removeAll(); return r
end)
c("sprite update callback order", function()
    gfx.sprite.removeAll()
    local order = {}
    for i, z in ipairs({ 3, 1, 2 }) do local s = gfx.sprite.new(); s:setZIndex(z); function s:update() order[#order + 1] = z end; s:add() end
    gfx.sprite.update(); gfx.sprite.removeAll()
    return table.concat(order, ",")
end)
c("sprite update disabled", function()
    gfx.sprite.removeAll()
    local n = 0
    local s = gfx.sprite.new(); function s:update() n = n + 1 end; s:setUpdatesEnabled(false); s:add()
    gfx.sprite.update(); gfx.sprite.removeAll(); return all(n)
end)
c("sprite draw callback", function()
    gfx.sprite.removeAll()
    local got
    local s = spr(10, 8); s:setCenter(0, 0); s:moveTo(5, 6)
    function s:draw(x, y, w, h) got = all(x, y, w, h) end
    s:add(); gfx.sprite.update(); gfx.sprite.removeAll(); return got
end)

-- pathfinding
local function grid() return pf.graph.new2DGrid(3, 3, false) end
c("graph.new2DGrid nodes", function() local g = grid(); local n = g:allNodes(); return all(#n) .. " " .. v(g:nodeWithXY(2, 2)) end)
c("graph.new2DGrid connections", function() local g = grid(); return ids(g:nodeWithXY(2, 2):connectedNodes()) .. " " .. ids(g:nodeWithXY(1, 1):connectedNodes()) end)
c("graph.new2DGrid diagonals", function() local g = pf.graph.new2DGrid(3, 3, true); return ids(g:nodeWithXY(1, 1):connectedNodes()) end)
c("graph.new2DGrid included", function() local g = pf.graph.new2DGrid(3, 2, false, { 1, 1, 1, 0, 1, 1 }); return all(#g:allNodes()) .. " " .. tostring(g:nodeWithXY(1, 2)) end)
c("graph:findPath grid", function() local g = grid(); local p = g:findPath(g:nodeWithXY(1, 1), g:nodeWithXY(3, 3)); return ids(p) end)
c("graph:findPathWithIDs", function() local g = grid(); return ids(g:findPathWithIDs(1, 9)) end)
c("graph:findPath unreachable", function() local g = pf.graph.new(); local a = g:addNewNode(1, 0, 0); local b = g:addNewNode(2, 5, 5); return all(g:findPath(a, b)) end)
c("graph:findPath adjacent goal", function() local g = grid(); return ids(g:findPathWithIDs(1, 9, nil, true)) end)
c("graph:findPath heuristic", function() local g = grid(); local calls = 0; local p = g:findPath(g:nodeWithXY(1, 1), g:nodeWithXY(3, 1), function(a, b) calls = calls + 1; return math.abs(a.x - b.x) + math.abs(a.y - b.y) end); return ids(p) .. " " .. tostring(calls > 0) end)
c("graph.new with coordinates", function() local g = pf.graph.new(3, { { 0, 0 }, { 10, 0 }, { 10, 10 } }); return v(g:nodeWithID(2)) .. " " .. all(#g:allNodes()) end)
c("graph:addNewNode connections", function() local g = pf.graph.new(); local a = g:addNewNode(1, 0, 0); local b = g:addNewNode(2, 1, 0, { a }, { 5 }, true); return ids(a:connectedNodes()) .. " " .. ids(b:connectedNodes()) end)
c("graph:addNewNodes", function() local g = pf.graph.new(); local n = g:addNewNodes(3); return all(#n, #g:allNodes()) .. " " .. v(n[1]) end)
c("graph:addNode/addNodes", function() local g = pf.graph.new(); local a = g:addNewNode(5, 1, 1); local b = g:addNewNode(6, 2, 2); g:removeNode(a); g:removeNode(b); g:addNode(a); local n1 = #g:allNodes(); g:removeNode(a); g:addNodes({ a, b }); return all(n1, #g:allNodes()) end)
c("graph:removeNode variants", function() local g = grid(); g:removeNode(g:nodeWithID(5)); g:removeNodeWithXY(1, 1); g:removeNodeWithID(9); return all(#g:allNodes()) .. " " .. ids(g:nodeWithXY(2, 1):connectedNodes()) end)
c("graph:nodeWithID missing", function() local g = grid(); return all(g:nodeWithID(99), g:nodeWithXY(9, 9)) end)
c("graph:addConnections", function() local g = pf.graph.new(); g:addNewNodes(3); g:addConnections({ [1] = { 2, 1, 3, 1 }, [2] = { 3, 1 } }); return ids(g:nodeWithID(1):connectedNodes()) .. " " .. ids(g:nodeWithID(3):connectedNodes()) end)
c("graph:addConnectionToNodeWithID", function() local g = pf.graph.new(); g:addNewNodes(2); g:addConnectionToNodeWithID(1, 2, 3, true); return ids(g:nodeWithID(2):connectedNodes()) end)
c("graph:removeAllConnections", function() local g = grid(); g:removeAllConnections(); return ids(g:nodeWithID(5):connectedNodes()) end)
c("graph:removeAllConnectionsFromNodeWithID", function() local g = grid(); g:removeAllConnectionsFromNodeWithID(5, true); return ids(g:nodeWithID(5):connectedNodes()) .. " " .. ids(g:nodeWithID(2):connectedNodes()) end)
c("graph:setXYForNodeWithID", function() local g = grid(); g:setXYForNodeWithID(1, 7, 8); return v(g:nodeWithID(1)) end)
c("node:addConnection", function() local g = pf.graph.new(); local a, b = g:addNewNode(1, 0, 0), g:addNewNode(2, 1, 1); a:addConnection(b, 2, false); return ids(a:connectedNodes()) .. " " .. ids(b:connectedNodes()) end)
c("node:addConnections", function() local g = pf.graph.new(); local a, b, d = g:addNewNode(1, 0, 0), g:addNewNode(2, 1, 1), g:addNewNode(3, 2, 2); a:addConnections({ b, d }, { 1, 1 }, true); return ids(a:connectedNodes()) .. " " .. ids(d:connectedNodes()) end)
c("node:addConnectionToNodeWithXY", function() local g = grid(); local a = g:nodeWithXY(1, 1); a:addConnectionToNodeWithXY(3, 3, 1, false); return ids(a:connectedNodes()) end)
c("node:removeConnection", function() local g = grid(); local a = g:nodeWithXY(1, 1); a:removeConnection(g:nodeWithXY(2, 1), true); return ids(a:connectedNodes()) .. " " .. ids(g:nodeWithXY(2, 1):connectedNodes()) end)
c("node:removeAllConnections", function() local g = grid(); local a = g:nodeWithXY(2, 2); a:removeAllConnections(true); return ids(a:connectedNodes()) .. " " .. ids(g:nodeWithXY(2, 1):connectedNodes()) end)
c("node:setXY", function() local g = grid(); local a = g:nodeWithID(1); a:setXY(4, 5); return v(a) end)

-- system
c("apiVersion", function() return all(playdate.apiVersion()) end)
c("getSystemLanguage", function() return all(playdate.getSystemLanguage(), playdate.graphics.font.kLanguageEnglish) end)
c("getReduceFlashing/getFlipped/shouldDisplay24HourTime", function() return all(playdate.getReduceFlashing(), playdate.getFlipped(), playdate.shouldDisplay24HourTime()) end)
c("readAccelerometer stopped", function() playdate.stopAccelerometer(); return all(playdate.readAccelerometer()) end)
c("readAccelerometer started", function() playdate.startAccelerometer(); local r = table.pack(playdate.readAccelerometer()); playdate.stopAccelerometer(); return all(r.n, math.type(r[1])) end)
c("button queries idle", function() return all(playdate.buttonIsPressed(playdate.kButtonA), playdate.buttonJustPressed(playdate.kButtonA), playdate.buttonJustReleased("a")) end)
c("buttonIsPressed string", function() return all(playdate.buttonIsPressed("up")) end)
c("setButtonQueueSize", function() playdate.setButtonQueueSize(8); return "ok" end)
c("setCrankSoundsDisabled/setAutoLockDisabled", function() playdate.setCrankSoundsDisabled(true); playdate.setAutoLockDisabled(true); playdate.setCrankSoundsDisabled(false); playdate.setAutoLockDisabled(false); return "ok" end)
c("getCurrentTimeMilliseconds type", function() return math.type(playdate.getCurrentTimeMilliseconds()) end)
c("resetElapsedTime/getElapsedTime", function() playdate.resetElapsedTime(); local t = playdate.getElapsedTime(); return math.type(t) .. " " .. tostring(t >= 0 and t < 1) end)
c("getGMTTime keys", function() local t = playdate.getGMTTime(); local k = {}; for key in pairs(t) do k[#k + 1] = key end; table.sort(k); return table.concat(k, ",") end)
c("getFPS type", function() return math.type(playdate.getFPS()) end)
c("getStats type", function() return type(playdate.getStats()) end)
c("setStatsInterval", function() playdate.setStatsInterval(0); return "ok" end)
c("getPowerStatus keys", function() local p = playdate.getPowerStatus(); local k = {}; for key, val in pairs(p) do k[#k + 1] = key .. ":" .. type(val) end; table.sort(k); return table.concat(k, ",") end)
c("getBatteryPercentage/Voltage types", function() return all(math.type(playdate.getBatteryPercentage()), math.type(playdate.getBatteryVoltage())) end)
c("drawFPS", function() playdate.drawFPS(0, 0); return "ok" end)
c("setMenuImage", function() playdate.setMenuImage(gfx.image.new(400, 240, gfx.kColorWhite), 0); playdate.setMenuImage(nil); return "ok" end)
c("console and gc controls", function() playdate.clearConsole(); playdate.setDebugDrawColor(1, 0, 0, 0.5); playdate.setCollectsGarbage(true); playdate.setMinimumGCTime(2); playdate.setGCScaling(0.4, 0.7); playdate.setNewlinePrinted(true); return "ok" end)
c("display getRect", function() return v(playdate.display.getRect()) end)
c("display mosaic", function() playdate.display.setMosaic(2, 3); local r = all(playdate.display.getMosaic()); playdate.display.setMosaic(0, 0); return r end)
c("display flipped", function() playdate.display.setFlipped(true, false); playdate.display.setFlipped(false, false); return "ok" end)
c("display flush", function() playdate.display.flush(); return "ok" end)
c("display loadImage", function() playdate.display.loadImage("assets/full"); return "ok" end)
c("menu item setTitle/setValue/setCallback", function()
    local m = playdate.getSystemMenu()
    local a = m:addMenuItem("A", function() end)
    a:setTitle("B"); a:setValue(7); a:setCallback(function() end)
    local r = all(a:getTitle(), a:getValue())
    m:removeMenuItem(a)
    return r .. " | " .. #m:getMenuItems()
end)
c("menu checkmark toggle value", function() local m = playdate.getSystemMenu(); local a = m:addCheckmarkMenuItem("C", false, function() end); a:setValue(true); local r = all(a:getValue()); m:removeAllMenuItems(); return r end)
c("menu options setValue", function() local m = playdate.getSystemMenu(); local a = m:addOptionsMenuItem("O", { "x", "y", "z" }, "x", function() end); a:setValue("z"); local r = all(a:getValue()); m:removeAllMenuItems(); return r end)
c("menu fourth item", function() local m = playdate.getSystemMenu(); m:addMenuItem("1", function() end); m:addMenuItem("2", function() end); m:addMenuItem("3", function() end); local r = table.pack(m:addMenuItem("4", function() end)); m:removeAllMenuItems(); return all(r.n, r[1] == nil, type(r[2])) end)

-- files and JSON files
c("file:flush", function() local f = playdate.file.open("fl.txt", playdate.file.kFileWrite); f:write("x"); local r = all(f:flush()); f:close(); return r end)
c("file.load and run", function()
    local fn = playdate.file.load("modx")
    return all(type(fn), fn and fn() or nil, playdate.file.run("modx"))
end)
c("json encodeToFile/decodeFile", function() json.encodeToFile("j.json", false, { a = 1, b = { 2, 3 } }); return v(json.decodeFile("j.json")) end)
c("json encodeToFile pretty", function() json.encodeToFile("j2.json", true, { a = 1 }); local f = playdate.file.open("j2.json"); local d = f:read(100); f:close(); return all(d) end)
c("json decodeFile missing", function() return all(json.decodeFile("missing.json")) end)
c("datastore writeImage/readImage", function() playdate.datastore.writeImage(gfx.image.new("assets/img10x6"), "pic"); return dump(playdate.datastore.readImage("pic")) end)

-- sound: global and sources
c("sound.getSampleRate", function() return all(snd.getSampleRate()) end)
c("sound.playingSources", function() return all(#snd.playingSources()) end)
c("sound global effects", function() local e = snd.bitcrusher.new(); snd.addEffect(e); snd.removeEffect(e); return "ok" end)
c("sound.setOutputsActive", function() snd.setOutputsActive(true, true); return "ok" end)
c("sound.resetTime", function() snd.resetTime(); return all(snd.getCurrentTime() < 1) end)
c("sample.new from path", function() local s = snd.sample.new("assets/beep"); return all(s ~= nil, s and s:getSampleRate(), s and s:getFormat(), s and s:getLength()) end)
c("sample:getSubsample", function() local s = snd.sample.new("assets/beep"); local sub = s:getSubsample(0, 1000); return all(sub:getLength()) end)
c("sample:load", function() local s = snd.sample.new(0.1, snd.kFormat16bitMono); local r = s:load("assets/beep"); return all(r, s:getLength()) end)
c("sample:decompress", function() local s = snd.sample.new("assets/beep"); return all(s:decompress()) end)
c("sample:play/playAt", function() local s = snd.sample.new("assets/beep"); return all(type(s:play()), type(s:playAt(0))) end)
c("sample:save", function() local s = snd.sample.new("assets/beep"); return all(s:save("saved.wav"), playdate.file.exists("saved.wav")) end)
c("sampleplayer play/stop", function() local p = snd.sampleplayer.new("assets/beep"); local r = all(p:play(1), p:isPlaying()); p:stop(); return r .. " | " .. all(p:isPlaying()) end)
c("sampleplayer playAt", function() local p = snd.sampleplayer.new("assets/beep"); return all(p:playAt(0)) end)
c("sampleplayer setSample/getSample", function() local s = snd.sample.new("assets/beep"); local p = snd.sampleplayer.new(snd.sample.new(0.1, snd.kFormat16bitMono)); p:setSample(s); return all(p:getSample() == s, p:getLength()) end)
c("sampleplayer setPlayRange/setPaused", function() local p = snd.sampleplayer.new("assets/beep"); p:setPlayRange(0, 100); p:play(); p:setPaused(true); local r = all(p:isPlaying()); p:stop(); return r end)
c("sampleplayer callbacks", function() local p = snd.sampleplayer.new("assets/beep"); p:setFinishCallback(function() end); p:setLoopCallback(function() end); p:setRateMod(snd.lfo.new()); return "ok" end)
c("fileplayer load/play", function() local p = snd.fileplayer.new(); local r = all(p:load("assets/beep")); local q = all(p:play(1), p:isPlaying()); p:stop(); return r .. " | " .. q .. " | " .. all(p:isPlaying()) end)
c("fileplayer from path length", function() local p = snd.fileplayer.new("assets/beep"); return all(p:getLength()) end)
c("fileplayer pause", function() local p = snd.fileplayer.new("assets/beep"); p:play(); p:pause(); local r = all(p:isPlaying()); p:stop(); return r end)
c("fileplayer misc", function() local p = snd.fileplayer.new("assets/beep"); p:setFinishCallback(function() end); p:setLoopRange(0, 0.1); p:setLoopCallback(function() end); p:setBufferSize(0.5); p:setStopOnUnderrun(false); p:setRateMod(snd.lfo.new()); return all(p:didUnderrun()) end)

-- synth, instrument, envelope, LFO, signals
c("synth playNote", function() local s = snd.synth.new(snd.kWaveSine); local r = all(s:playNote(440, 0.5, 0.1)); local p = all(s:isPlaying()); s:stop(); return r .. " | " .. p .. " | " .. all(s:isPlaying()) end)
c("synth playMIDINote/noteOff", function() local s = snd.synth.new(); local r = all(s:playMIDINote(60, 0.5)); s:noteOff(); return r end)
c("synth envelope setters", function() local s = snd.synth.new(); s:setADSR(0.1, 0.2, 0.5, 0.3); s:setAttack(0.1); s:setDecay(0.1); s:setSustain(0.5); s:setRelease(0.2); s:setEnvelopeCurvature(0.5); s:clearEnvelope(); return type(s:getEnvelope()) end)
c("synth misc setters", function() local s = snd.synth.new(); s:setWaveform(snd.kWaveSquare); s:setLegato(true); s:setFinishCallback(function() end); s:setAmplitudeMod(snd.lfo.new()); s:setFrequencyMod(snd.lfo.new()); s:setParameter(1, 0.5); s:setParameterMod(1, snd.lfo.new()); return "ok" end)
c("synth setWavetable", function() local s = snd.synth.new(); local r = all(s:setWavetable(snd.sample.new("assets/beep"), 128, 2, 2)); return r end)
c("instrument addVoice/playNote", function() local i = snd.instrument.new(); local r = all(i:addVoice(snd.synth.new())); local n = i:playNote(440, 0.5, 0.1); i:noteOff(440); i:allNotesOff(); return r .. " | " .. type(n) end)
c("instrument pitch and volume", function() local i = snd.instrument.new(); i:setPitchBend(0.5); i:setPitchBendRange(2); i:setTranspose(1); i:setVolume(0.4); return all(i:getVolume()) end)
c("instrument playMIDINote", function() local i = snd.instrument.new(snd.synth.new()); return type(i:playMIDINote(60)) end)
c("envelope setters and trigger", function() local e = snd.envelope.new(0.1, 0.1, 0.5, 0.1); e:setAttack(0); e:setDecay(0); e:setSustain(0.7); e:setRelease(0); e:setCurvature(0); e:setVelocitySensitivity(0); e:setRateScaling(0); e:setLegato(false); e:setRetrigger(false); e:setGlobal(false); e:trigger(1, 0.5); return "ok" end)
c("lfo setters", function() local l = snd.lfo.new(); l:setType(snd.kLFOSquare); l:setDepth(0.5); l:setPhase(0.25); l:setStartPhase(0); l:setGlobal(false); l:setRetrigger(false); l:setDelay(0, 0); l:setArpeggio(0, 4, 7); return "ok" end)
c("controlsignal events", function() local cs = snd.controlsignal.new(); cs:addEvent(0, 0.5); cs:addEvent(10, 1, true); local n = #cs.events; cs:clearEvents(); cs:setControllerType(7); return all(n, #cs.events, cs:getControllerType()) end)

-- channels, sequences, tracks, effects
c("channel effects and sources", function() local ch = snd.channel.new(); local e = snd.overdrive.new(); ch:addEffect(e); ch:removeEffect(e); local p = snd.sampleplayer.new("assets/beep"); local a = ch:addSource(p); local b = ch:removeSource(p); ch:remove(); return all(a, b) end)
c("channel pan and mods", function() local ch = snd.channel.new(); ch:setPan(-0.5); ch:setPanMod(snd.lfo.new()); ch:setVolumeMod(snd.lfo.new()); local r = all(type(ch:getDryLevelSignal()), type(ch:getWetLevelSignal())); ch:remove(); return r end)
c("sequence tempo and play", function() local s = snd.sequence.new(); s:setTempo(8); local t = s:getTempo(); s:setLoops(0, 4, 2); s:play(); local p = s:isPlaying(); s:stop(); return all(t, p, s:getCurrentStep()) end)
c("sequence tracks", function() local s = snd.sequence.new(); local t = snd.track.new(); local i = s:addTrack(t); s:setTrackAtIndex(2, snd.track.new()); return all(i, s:getTrackCount(), s:getTrackAtIndex(1) == t) end)
c("sequence goToStep/allNotesOff", function() local s = snd.sequence.new(); s:goToStep(5); s:allNotesOff(); return all(s:getCurrentStep()) end)
c("track setNotes/removeNote/clearNotes", function()
    local t = snd.track.new()
    t:setNotes({ { step = 1, note = 60, length = 2, velocity = 1 }, { step = 3, note = 62, length = 1, velocity = 0.5 } })
    local a = #t:getNotes(); t:removeNote(1, 60); local b = #t:getNotes(); t:clearNotes()
    return all(a, b, #t:getNotes())
end)
c("track instrument and polyphony", function() local t = snd.track.new(); local i = snd.instrument.new(); t:setInstrument(i); t:setMuted(false); return all(t:getInstrument() == i, t:getPolyphony(), t:getNotesActive()) end)
c("track control signals", function() local t = snd.track.new(); t:addControlSignal(snd.controlsignal.new()); return all(#t:getControlSignals()) end)
c("bitcrusher setters", function() local e = snd.bitcrusher.new(); e:setMix(0.5); e:setMixMod(snd.lfo.new()); e:setAmount(0.5); e:setAmountMod(snd.lfo.new()); e:setUndersampling(0.5); e:setUndersamplingMod(snd.lfo.new()); return "ok" end)
c("overdrive setters", function() local e = snd.overdrive.new(); e:setMix(0.5); e:setMixMod(snd.lfo.new()); e:setGain(2); e:setLimit(0.8); e:setLimitMod(snd.lfo.new()); e:setOffsetMod(snd.lfo.new()); return "ok" end)
c("ringmod setters", function() local e = snd.ringmod.new(); e:setMix(0.5); e:setMixMod(snd.lfo.new()); e:setFrequency(200); e:setFrequencyMod(snd.lfo.new()); return "ok" end)
c("onepolefilter setters", function() local e = snd.onepolefilter.new(); e:setMix(0.5); e:setMixMod(snd.lfo.new()); e:setParameter(0.3); e:setParameterMod(snd.lfo.new()); return "ok" end)
c("twopolefilter setters", function() local e = snd.twopolefilter.new(snd.kFilterLowPass); e:setMix(0.5); e:setMixMod(snd.lfo.new()); e:setFrequency(1000); e:setFrequencyMod(snd.lfo.new()); e:setResonance(0.5); e:setResonanceMod(snd.lfo.new()); e:setGain(1); e:setType(snd.kFilterHighPass); return "ok" end)
c("delayline taps", function() local d = snd.delayline.new(1); d:setMix(0.5); d:setMixMod(snd.lfo.new()); d:setFeedback(0.3); local tap = d:addTap(0.2); tap:setDelay(0.1); tap:setDelayMod(snd.lfo.new()); tap:setFlipChannels(true); return type(tap) end)
c("micinput level", function() return all(math.type(snd.micinput.getLevel()), snd.micinput.getSource()) end)
c("micinput listening", function() snd.micinput.startListening(); snd.micinput.stopListening(); return "ok" end)

function caseNames4() local n = {}; for i, c in ipairs(cases4) do n[i] = c[1] end; return n end
function runCases4(write, skip)
    skip = skip or {}
    for _, case in ipairs(cases4) do
      if not skip[case[1]] then
        gfx.setLineWidth(1); gfx.setDrawOffset(0, 0); gfx.clearClipRect(); gfx.setImageDrawMode(gfx.kDrawModeCopy); gfx.setColor(gfx.kColorBlack)
        local okk, r = pcall(case[2])
        local out = okk and tostring(r) or ("ERR " .. tostring(r))
        out = out:gsub("\n", "\\n"):gsub("\t", "\\t")
        write(case[1] .. "\t" .. out)
      end
    end
end
