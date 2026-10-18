-- Probe: integer or float, for the numbers that argument-free getters return
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function t(v) if type(v) == "number" then return math.type(v) .. ":" .. tostring(v) end return type(v) end
local function run(name, fn, ...)
  local r = table.pack(pcall(fn, ...))
  local s = {}
  if not r[1] then s[1] = "err" else for i = 2, r.n do
    local v = r[i]
    if type(v) == "table" then local ks = {} for k, x in pairs(v) do if type(x) == "number" then ks[#ks + 1] = k .. "=" .. t(x) end end table.sort(ks) s[#s + 1] = "{" .. table.concat(ks, ",") .. "}"
    elseif type(v) == "userdata" and v.unpack then s[#s + 1] = "<" .. table.concat((function() local o = {} for _, x in ipairs({v:unpack()}) do o[#o + 1] = t(x) end return o end)(), ",") .. ">"
    else s[#s + 1] = t(v) end end end
  fh:write(name .. " " .. table.concat(s, " ") .. "\n")
end
local d = playdate.display
run("display.getSize", d.getSize) run("display.getWidth", d.getWidth) run("display.getHeight", d.getHeight)
run("display.getRect", d.getRect) run("display.getScale", d.getScale) run("display.getRefreshRate", d.getRefreshRate)
run("display.getOffset", d.getOffset) run("display.getMosaic", d.getMosaic)
run("gfx.getDrawOffset", gfx.getDrawOffset) run("gfx.getClipRect", gfx.getClipRect) run("gfx.getScreenClipRect", gfx.getScreenClipRect)
run("gfx.getLineWidth", gfx.getLineWidth) run("gfx.getColor", gfx.getColor) run("gfx.getBackgroundColor", gfx.getBackgroundColor)
run("gfx.getImageDrawMode", gfx.getImageDrawMode) run("gfx.getFontTracking", gfx.getFontTracking) run("gfx.getTextSize", gfx.getTextSize, "Hi")
run("gfx.getStrokeLocation", gfx.getStrokeLocation)
local img = gfx.image.new(10, 7)
run("image:getSize", img.getSize, img) run("displayImage:getSize", gfx.getDisplayImage().getSize, gfx.getDisplayImage())
local f = gfx.getSystemFont()
run("font:getHeight", f.getHeight, f) run("font:getTracking", f.getTracking, f) run("font:getLeading", f.getLeading, f) run("font:getTextWidth", f.getTextWidth, f, "Hi")
local s = gfx.sprite.new(img) s:moveTo(10, 20) s:add()
run("sprite:getPosition", s.getPosition, s) run("sprite:getSize", s.getSize, s) run("sprite:getBounds", s.getBounds, s)
run("sprite:getCenter", s.getCenter, s) run("sprite:getZIndex", s.getZIndex, s) run("sprite:getRotation", s.getRotation, s)
run("sprite:getScale", s.getScale, s) run("sprite:getCollideRect", s.getCollideRect, s) run("sprite:getTag", s.getTag, s)
run("sprite:getImageFlip", s.getImageFlip, s) run("sprite:getCenterPoint", s.getCenterPoint, s) run("sprite:getBoundsRect", s.getBoundsRect, s)
run("sprite.spriteCount", gfx.sprite.spriteCount)
run("pd.getCrankPosition", playdate.getCrankPosition) run("pd.getCrankChange", playdate.getCrankChange)
run("pd.getButtonState", playdate.getButtonState) run("pd.getFlipped", playdate.getFlipped)
run("pd.getBatteryPercentage", playdate.getBatteryPercentage) run("pd.getBatteryVoltage", playdate.getBatteryVoltage)
run("pd.getSecondsSinceEpoch", playdate.getSecondsSinceEpoch) run("pd.getTime", playdate.getTime) run("pd.getGMTTime", playdate.getGMTTime)
run("pd.getPowerStatus", playdate.getPowerStatus) run("pd.getSystemLanguage", playdate.getSystemLanguage)
run("pd.getServerTime", function() return 0 end)
run("pd.readAccelerometer", playdate.readAccelerometer) run("pd.getStats", playdate.getStats)
run("pd.getSystemMenu", function() return 0 end)
run("sound.getCurrentTime", playdate.sound.getCurrentTime) run("sound.getHeadphoneState", playdate.sound.getHeadphoneState)
run("sound.playingSources", function() return #playdate.sound.playingSources() end)
run("file.getSize", playdate.file.getSize, "main.pdz") run("file.modtime", playdate.file.modtime, "main.pdz")
run("metadata", function() return playdate.metadata end)
run("pd.getReduceFlashing", playdate.getReduceFlashing)
run("geometry.point", function() return playdate.geometry.point.new(1, 2) end)
run("geometry.rect", function() return playdate.geometry.rect.new(1, 2, 3, 4) end)
run("tilemap", function() local tm = gfx.tilemap.new() tm:setImageTable(gfx.imagetable.new(1)) tm:setSize(3, 2) return tm:getSize() end)
run("imagetable", function() local it = gfx.imagetable.new(4) return #it, it:getLength() end)
fh:close()
function playdate.update() end
