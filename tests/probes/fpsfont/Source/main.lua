-- Probe: which system font draws the FPS digits ("30" at 1,1, black on white)
local gfx = playdate.graphics
local fonts = { "Asheville-Sans-14-Bold", "Asheville-Sans-14-Light", "Roobert-10-Bold", "Roobert-11-Bold", "Roobert-11-Medium", "Roobert-24-Medium", "Asheville-Sans-24-Light", "Roobert-20-Medium" }
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
for _, name in ipairs(fonts) do
    local font = gfx.font.new("/System/Fonts/" .. name)
    local img = gfx.image.new(18, 14, gfx.kColorWhite)
    gfx.pushContext(img); if font then gfx.setFont(font) end; gfx.drawText("30", 1, 1); gfx.popContext()
    local rows = {}
    for y = 0, 13 do local r = {} for x = 0, 17 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "#" or "." end rows[#rows + 1] = table.concat(r) end
    f:write(name .. "\t" .. tostring(font ~= nil) .. "\t" .. table.concat(rows, "/") .. "\n")
end
f:close()
playdate.stop()
function playdate.update() end
