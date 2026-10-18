-- Probe: how many values, and of which types, common API calls return (setters included)
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animator"
local gfx = playdate.graphics
local geo = playdate.geometry
local snd = playdate.sound
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function desc(v)
  local t = type(v)
  if t == "number" then return math.type(v) == "integer" and "i" or "f" end
  if t == "userdata" or t == "table" then local mt = getmetatable(v) return (mt and mt.__name) or t end
  return t
end
local function run(name, fn, ...)
  local r = table.pack(pcall(fn, ...))
  if not r[1] then fh:write(name .. " ERR " .. tostring(r[2]):gsub("^.-:%d+: ", "") .. "\n") return end
  local s = {}
  for i = 2, r.n do s[#s + 1] = desc(r[i]) end
  fh:write(name .. " " .. (r.n - 1) .. " " .. table.concat(s, ",") .. "\n")
end
local img = gfx.image.new(16, 8, gfx.kColorWhite)
local it = gfx.imagetable.new(3)
local font = gfx.getSystemFont()
local spr = gfx.sprite.new(img)
local tm = gfx.tilemap.new()
local pt, rc, ln, vec = geo.point.new(1, 2), geo.rect.new(0, 0, 4, 4), geo.lineSegment.new(0, 0, 4, 4), geo.vector2D.new(1, 0)
local poly = geo.polygon.new(0, 0, 4, 0, 4, 4)
local tf = geo.affineTransform.new()
local calls = {
  { "gfx.setColor", gfx.setColor, gfx.kColorBlack }, { "gfx.getColor", gfx.getColor }, { "gfx.setLineWidth", gfx.setLineWidth, 2 },
  { "gfx.drawLine", gfx.drawLine, 0, 0, 5, 5 }, { "gfx.drawRect", gfx.drawRect, 0, 0, 5, 5 }, { "gfx.fillRect", gfx.fillRect, 0, 0, 5, 5 },
  { "gfx.drawCircleAtPoint", gfx.drawCircleAtPoint, 5, 5, 3 }, { "gfx.drawText", gfx.drawText, "a", 0, 0 },
  { "gfx.drawTextAligned", gfx.drawTextAligned, "a", 0, 0, kTextAlignment.left }, { "gfx.drawTextInRect", gfx.drawTextInRect, "a b", 0, 0, 50, 30 },
  { "gfx.getTextSizeForMaxWidth", gfx.getTextSizeForMaxWidth, "a b c", 10 }, { "gfx.imageWithText", gfx.imageWithText, "ab", 50, 30 },
  { "gfx.setDrawOffset", gfx.setDrawOffset, 0, 0 }, { "gfx.getDrawOffset", gfx.getDrawOffset }, { "gfx.setClipRect", gfx.setClipRect, 0, 0, 400, 240 },
  { "gfx.clearClipRect", gfx.clearClipRect }, { "gfx.pushContext", gfx.pushContext }, { "gfx.popContext", gfx.popContext },
  { "gfx.getWorkingImage", gfx.getWorkingImage }, { "gfx.getDisplayImage", gfx.getDisplayImage }, { "gfx.checkAlphaCollision", gfx.checkAlphaCollision, img, 0, 0, 0, img, 0, 0, 0 },
  { "gfx.getFont", gfx.getFont }, { "gfx.setFont", gfx.setFont, font }, { "gfx.getFontTracking", gfx.getFontTracking },
  { "gfx.getBackgroundColor", gfx.getBackgroundColor }, { "gfx.getImageDrawMode", gfx.getImageDrawMode }, { "gfx.setPattern", gfx.setPattern, { 1, 2, 3, 4, 5, 6, 7, 8 } },
  { "gfx.setDitherPattern", gfx.setDitherPattern, 0.5 }, { "gfx.setColor2", gfx.setColor, gfx.kColorBlack },
  { "img:getSize", img.getSize, img }, { "img:copy", img.copy, img }, { "img:sample", img.sample, img, 1, 1 }, { "img:draw", img.draw, img, 0, 0 },
  { "img:drawScaled", img.drawScaled, img, 0, 0, 2 }, { "img:scaledImage", img.scaledImage, img, 2 }, { "img:rotatedImage", img.rotatedImage, img, 30 },
  { "img:blurredImage", img.blurredImage, img, 1, 1, gfx.image.kDitherTypeNone }, { "img:fadedImage", img.fadedImage, img, 0.5, gfx.image.kDitherTypeBayer8x8 },
  { "img:invertedImage", img.invertedImage, img }, { "img:hasMask", img.hasMask, img }, { "img:getMaskImage", img.getMaskImage, img },
  { "img:clear", img.clear, img, gfx.kColorWhite }, { "img:transformedImage", img.transformedImage, img, tf }, { "img:vcrPauseFilterImage", img.vcrPauseFilterImage, img },
  { "img:drawCentered", img.drawCentered, img, 10, 10 }, { "img:drawTiled", img.drawTiled, img, 0, 0, 30, 30 }, { "img:drawIgnoringOffset", img.drawIgnoringOffset, img, 0, 0 },
  { "img:addMask", img.addMask, img }, { "img:removeMask", img.removeMask, img }, { "img:setInverted", img.setInverted, img, false }, { "img:load", img.load, img, "nothing" },
  { "it:getLength", it.getLength, it }, { "it:getSize", it.getSize, it }, { "it:getImage", it.getImage, it, 1 }, { "it:setImage", it.setImage, it, 1, img },
  { "font:getHeight", font.getHeight, font }, { "font:getTextWidth", font.getTextWidth, font, "ab" }, { "font:drawText", font.drawText, font, "ab", 0, 0 },
  { "font:drawTextAligned", font.drawTextAligned, font, "ab", 0, 0, kTextAlignment.left }, { "font:getGlyph", font.getGlyph, font, "a" },
  { "spr:moveTo", spr.moveTo, spr, 1, 1 }, { "spr:moveBy", spr.moveBy, spr, 1, 1 }, { "spr:getPosition", spr.getPosition, spr }, { "spr:add", spr.add, spr },
  { "spr:remove", spr.remove, spr }, { "spr:setImage", spr.setImage, spr, img }, { "spr:getImage", spr.getImage, spr }, { "spr:setSize", spr.setSize, spr, 4, 4 },
  { "spr:getBounds", spr.getBounds, spr }, { "spr:getBoundsRect", spr.getBoundsRect, spr }, { "spr:setCollideRect", spr.setCollideRect, spr, 0, 0, 4, 4 },
  { "spr:getCollideRect", spr.getCollideRect, spr }, { "spr:getCollideBounds", spr.getCollideBounds, spr }, { "spr:moveWithCollisions", spr.moveWithCollisions, spr, 5, 5 },
  { "spr:checkCollisions", spr.checkCollisions, spr, 5, 5 }, { "spr:overlappingSprites", spr.overlappingSprites, spr }, { "spr:alphaCollision", spr.alphaCollision, spr, spr },
  { "spr:setTag", spr.setTag, spr, 3 }, { "spr:getTag", spr.getTag, spr }, { "spr:isVisible", spr.isVisible, spr }, { "spr:setVisible", spr.setVisible, spr, true },
  { "spr:setZIndex", spr.setZIndex, spr, 3 }, { "spr:copy", spr.copy, spr }, { "spr:getRotation", spr.getRotation, spr }, { "spr:setRotation", spr.setRotation, spr, 10 },
  { "spr:getScale", spr.getScale, spr }, { "spr:getCenter", spr.getCenter, spr }, { "spr:getCenterPoint", spr.getCenterPoint, spr }, { "spr:getImageFlip", spr.getImageFlip, spr },
  { "spr:setAnimator", spr.setAnimator, spr, gfx.animator.new(100, 0, 10) }, { "spr:getGroupMask", spr.getGroupMask, spr }, { "spr:getCollidesWithGroupsMask", spr.getCollidesWithGroupsMask, spr },
  { "spr:collisionsEnabled", spr.collisionsEnabled, spr }, { "spr:getStencil", spr.getStencil, spr }, { "spr:getsUpdatesEnabled", spr.updatesEnabled, spr },
  { "sprite.getAllSprites", gfx.sprite.getAllSprites }, { "sprite.spriteCount", gfx.sprite.spriteCount }, { "sprite.querySpritesAtPoint", gfx.sprite.querySpritesAtPoint, 1, 1 },
  { "sprite.querySpritesInRect", gfx.sprite.querySpritesInRect, 0, 0, 10, 10 }, { "sprite.querySpritesAlongLine", gfx.sprite.querySpritesAlongLine, 0, 0, 10, 10 },
  { "sprite.querySpriteInfoAlongLine", gfx.sprite.querySpriteInfoAlongLine, 0, 0, 10, 10 }, { "sprite.allOverlappingSprites", gfx.sprite.allOverlappingSprites },
  { "sprite.addEmptyCollisionSprite", gfx.sprite.addEmptyCollisionSprite, 0, 0, 3, 3 }, { "sprite.spriteWithText", gfx.sprite.spriteWithText, "ab", 50, 30 },
  { "tm:getSize", tm.getSize, tm }, { "tm:getPixelSize", tm.getPixelSize, tm }, { "tm:getTileSize", tm.getTileSize, tm }, { "tm:getTiles", tm.getTiles, tm },
  { "tm:getTileAtPosition", tm.getTileAtPosition, tm, 1, 1 }, { "tm:getCollisionRects", tm.getCollisionRects, tm, {} },
  { "pt:unpack", pt.unpack, pt }, { "pt:offsetBy", pt.offsetBy, pt, 1, 1 }, { "pt:distanceToPoint", pt.distanceToPoint, pt, geo.point.new(4, 6) }, { "pt:copy", pt.copy, pt },
  { "rc:unpack", rc.unpack, rc }, { "rc:intersection", rc.intersection, rc, geo.rect.new(1, 1, 4, 4) }, { "rc:intersects", rc.intersects, rc, geo.rect.new(1, 1, 4, 4) },
  { "rc:containsPoint", rc.containsPoint, rc, 1, 1 }, { "rc:centerPoint", rc.centerPoint, rc }, { "rc:isEmpty", rc.isEmpty, rc }, { "rc:toPolygon", rc.toPolygon, rc },
  { "rc:insetBy", rc.insetBy, rc, 1, 1 }, { "rc:offset", rc.offset, rc, 1, 1 }, { "rc:union", rc.union, rc, geo.rect.new(5, 5, 1, 1) }, { "rc:flipRelativeToRect", rc.flipRelativeToRect, rc, geo.rect.new(0, 0, 10, 10), gfx.kImageFlippedX },
  { "ln:unpack", ln.unpack, ln }, { "ln:length", ln.length, ln }, { "ln:midPoint", ln.midPoint, ln }, { "ln:intersectsLineSegment", ln.intersectsLineSegment, ln, geo.lineSegment.new(0, 4, 4, 0) },
  { "ln:intersectsRect", ln.intersectsRect, ln, rc }, { "ln:closestPointOnLineToPoint", ln.closestPointOnLineToPoint, ln, pt }, { "ln:pointOnLine", ln.pointOnLine, ln, 1 },
  { "ln:segmentVector", ln.segmentVector, ln }, { "ln:intersectsPolygon", ln.intersectsPolygon, ln, poly },
  { "vec:unpack", vec.unpack, vec }, { "vec:magnitude", vec.magnitude, vec }, { "vec:normalized", vec.normalized, vec }, { "vec:dotProduct", vec.dotProduct, vec, vec },
  { "vec:angleBetween", vec.angleBetween, vec, geo.vector2D.new(0, 1) }, { "vec:leftNormal", vec.leftNormal, vec },
  { "poly:count", poly.count, poly }, { "poly:getBounds", poly.getBounds, poly }, { "poly:getBoundsRect", poly.getBoundsRect, poly }, { "poly:containsPoint", poly.containsPoint, poly, 1, 1 },
  { "poly:isClosed", poly.isClosed, poly }, { "poly:length", poly.length, poly }, { "poly:getPointAt", poly.getPointAt, poly, 1 }, { "poly:pointOnPolygon", poly.pointOnPolygon, poly, 2 },
  { "poly:intersects", poly.intersects, poly, poly }, { "tf:transformXY", tf.transformXY, tf, 1, 2 }, { "tf:unpack", tf.unpack, tf }, { "tf:copy", tf.copy, tf },
  { "geo.squaredDistanceToPoint", geo.squaredDistanceToPoint, 0, 0, 3, 4 }, { "geo.distanceToPoint", geo.distanceToPoint, 0, 0, 3, 4 },
  { "pd.getCurrentTimeMilliseconds", playdate.getCurrentTimeMilliseconds }, { "pd.getElapsedTime", playdate.getElapsedTime }, { "pd.resetElapsedTime", playdate.resetElapsedTime },
  { "pd.getCrankPosition", playdate.getCrankPosition }, { "pd.getCrankChange", playdate.getCrankChange }, { "pd.getCrankTicks", playdate.getCrankTicks, 6 },
  { "pd.isCrankDocked", playdate.isCrankDocked }, { "pd.buttonIsPressed", playdate.buttonIsPressed, playdate.kButtonA }, { "pd.getButtonState", playdate.getButtonState },
  { "pd.startAccelerometer", playdate.startAccelerometer }, { "pd.readAccelerometer", playdate.readAccelerometer }, { "pd.accelerometerIsRunning", playdate.accelerometerIsRunning },
  { "pd.getSystemMenu", playdate.getSystemMenu }, { "pd.setMenuImage", playdate.setMenuImage, nil }, { "pd.getFPS", playdate.getFPS }, { "pd.setAutoLockDisabled", playdate.setAutoLockDisabled, false },
  { "pd.wait", playdate.wait, 1 }, { "pd.getSecondsSinceEpoch", playdate.getSecondsSinceEpoch }, { "pd.epochFromTime", playdate.epochFromTime, playdate.getTime() },
  { "pd.timeFromEpoch", playdate.timeFromEpoch, 1000, 0 }, { "pd.epochFromGMTTime", playdate.epochFromGMTTime, playdate.getGMTTime() }, { "pd.GMTTimeFromEpoch", playdate.GMTTimeFromEpoch, 1000, 0 },
  { "pd.getFlipped", playdate.getFlipped }, { "pd.getReduceFlashing", playdate.getReduceFlashing }, { "pd.getSystemLanguage", playdate.getSystemLanguage },
  { "pd.getBatteryPercentage", playdate.getBatteryPercentage }, { "pd.getBatteryVoltage", playdate.getBatteryVoltage }, { "pd.apiVersion", playdate.apiVersion },
  { "pd.getUptimeMilliseconds", playdate.getUptime or function() return nil end },
  { "datastore.write", playdate.datastore.write, { a = 1 } }, { "datastore.read", playdate.datastore.read }, { "datastore.delete", playdate.datastore.delete },
  { "datastore.writeImage", playdate.datastore.writeImage, img, "i.pdi" }, { "datastore.readImage", playdate.datastore.readImage, "i.pdi" },
  { "file.exists", playdate.file.exists, "main.pdz" }, { "file.isdir", playdate.file.isdir, "." }, { "file.listFiles", playdate.file.listFiles, "." }, { "file.getSize", playdate.file.getSize, "main.pdz" },
  { "file.getType", playdate.file.getType, "main.pdz" }, { "file.mkdir", playdate.file.mkdir, "dd" }, { "file.delete", playdate.file.delete, "dd" }, { "file.rename", playdate.file.rename, "nope", "nope2" },
  { "file.open missing", playdate.file.open, "nope.txt" }, { "file.run missing", playdate.file.run, "nope" }, { "file.load missing", playdate.file.load, "nope" },
  { "json.encode", json.encode, { 1, 2 } }, { "json.decode", json.decode, "[1,2]" }, { "json.decode bad", json.decode, "[1," },
  { "snd.getCurrentTime", snd.getCurrentTime }, { "snd.getSampleRate", snd.getSampleRate }, { "snd.playingSources", snd.playingSources }, { "snd.getHeadphoneState", snd.getHeadphoneState },
  { "snd.setOutputsActive", snd.setOutputsActive, true, true }, { "snd.sample.new", snd.sample.new, 100 }, { "snd.sampleplayer.new missing", snd.sampleplayer.new, "nope" },
  { "snd.fileplayer.new", snd.fileplayer.new }, { "snd.synth.new", snd.synth.new, snd.kWaveSine }, { "snd.getSystemVolume", playdate.getSystemVolume or function() end },
  { "timer.new", playdate.timer.new, 100, function() end }, { "timer.allTimers", playdate.timer.allTimers }, { "frameTimer.new", (playdate.frameTimer and playdate.frameTimer.new) or function() end, 5 },
  { "animator.new", gfx.animator.new, 100, 0, 10 }, { "string.format %d float", string.format, "%d", 3.0 }, { "math.floor type", math.floor, 2.5 }, { "tostring int float", tostring, 2.0 },
  { "pd.getStats", playdate.getStats }, { "pd.setStatsInterval", playdate.setStatsInterval, 0 }, { "pd.getPowerStatus", playdate.getPowerStatus },
}
for _, c in ipairs(calls) do run(c[1], table.unpack(c, 2)) end
fh:close()
function playdate.update() end
