-- Probe: nested *bold* and _italic_ markup, with and without an italic font in the family
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local cases = { "_*Goal*_", "*_Goal_*", "_Goal_", "*Goal*", "_*Go*al_", "*_Go_al*", "_*Goal_*", "*a_b*c_", "__ab__", "**ab**", "*_ab*_", "x*y", "_x" }
local function run(label)
  for _, s in ipairs(cases) do
    local img = gfx.image.new(160, 30, gfx.kColorWhite)
    gfx.pushContext(img) local w = gfx.drawText(s, 2, 2) gfx.popContext()
    local n, hs = 0, 0
    for y = 0, 29 do for x = 0, 159 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 hs = (hs * 31 + x * 3 + y) % 1000003 end end end
    fh:write(label .. " " .. s .. " w=" .. tostring(w) .. " px=" .. n .. " h=" .. hs .. "\n")
  end
end
run("system")
local normal = gfx.getSystemFont(gfx.font.kVariantNormal)
local bold = gfx.getSystemFont(gfx.font.kVariantBold)
local italic = gfx.getSystemFont(gfx.font.kVariantItalic)
gfx.setFontFamily({ [gfx.font.kVariantNormal] = normal, [gfx.font.kVariantBold] = bold })
run("noitalic")
gfx.setFontFamily({ [gfx.font.kVariantNormal] = normal, [gfx.font.kVariantItalic] = italic })
run("nobold")
fh:close()
function playdate.update() end
