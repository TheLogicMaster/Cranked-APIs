-- Probe: setFontFamily given a font instead of a table, and getFont variants
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") end
local big = gfx.font.new("/System/Fonts/Asheville-Sans-24-Light")
local sys = gfx.getSystemFont()
local function size(label) local wd, ht = gfx.getTextSize("Score:0") w(label, wd, ht, gfx.getFont() == sys, gfx.getFont() == big, gfx.getFont(gfx.font.kVariantBold) == sys, gfx.getFont(gfx.font.kVariantBold) == big) end
size("start")
w("big ok", big ~= nil, big and big:getHeight())
local ok, err = pcall(gfx.setFontFamily, big)
w("setFontFamily(font)", ok, err)
size("after family(font)")
pcall(gfx.setFontFamily, { [gfx.font.kVariantNormal] = big })
size("after family{normal=big}")
gfx.setFont(sys)
pcall(gfx.setFontFamily, gfx.getFont(gfx.font.kVariantBold))
size("after family(getFont(bold))")
local ok2, err2 = pcall(gfx.setFontFamily, nil)
w("setFontFamily(nil)", ok2, err2)
local ok3, err3 = pcall(gfx.setFontFamily, {})
w("setFontFamily({})", ok3, err3)
size("after empty table")
out:close()
function playdate.update() end
