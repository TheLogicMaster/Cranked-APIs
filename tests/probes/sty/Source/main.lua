-- Probe: styled text glyph positions (first ink column of each glyph run)
local gfx = playdate.graphics
local cases = { "a*b*c", "a_b_c", "*b*", "_b_", "ab*cd*ef", "ab_cd_ef", "W*W*W", "W_W_W", "A*V*A", "T_o_T", "f_j_f", "*x*_y_z", "x _y_ z", "l*l*l" }
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
for _, s in ipairs(cases) do
    local img = gfx.image.new(200, 30, gfx.kColorWhite)
    gfx.pushContext(img); gfx.drawText(s, 2, 2); gfx.popContext()
    local cols = {}
    local inRun = false
    for x = 0, 199 do
        local ink = false
        for y = 0, 29 do if img:sample(x, y) == gfx.kColorBlack then ink = true; break end end
        if ink and not inRun then cols[#cols + 1] = x end
        inRun = ink
    end
    local w, h = gfx.getTextSize(s)
    f:write(s .. "\t" .. table.concat(cols, ",") .. "\tw=" .. w .. "\n")
end
f:close()
playdate.stop()
function playdate.update() end
