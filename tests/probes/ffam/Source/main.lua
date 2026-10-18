-- Probe: the font family argument of drawText and drawTextInRect, with missing variants, styled text, and
-- the returned size.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local light = gfx.font.new("Nontendo-Light"); local bold = gfx.font.new("Nontendo-Bold")
local out = {}
local img = gfx.image.new(120, 24)
local function dump(name, w, h)
  local t = {}
  for y = 0, 23 do for x = 0, 119 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. tostring(w) .. "," .. tostring(h) .. "|" .. table.concat(t)
end
local function case(name, fn) img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setFont(gfx.getSystemFont()); local w, h = fn(); gfx.popContext(); dump(name, w, h) end
local famN = { [gfx.font.kVariantNormal] = light }
local famB = { [gfx.font.kVariantBold] = bold }
local famNB = { [gfx.font.kVariantNormal] = light, [gfx.font.kVariantBold] = bold }
case("none", function() return gfx.drawText("Ab *Cd* 12", 1, 1) end)
case("famN", function() return gfx.drawText("Ab *Cd* 12", 1, 1, famN) end)
case("famB", function() return gfx.drawText("Ab *Cd* 12", 1, 1, famB) end)
case("famNB", function() return gfx.drawText("Ab *Cd* 12", 1, 1, famNB) end)
case("newFamily", function() return gfx.drawText("Ab *Cd* 12", 1, 1, gfx.font.newFamily({ [gfx.font.kVariantNormal] = "Nontendo-Light" })) end)
case("wh_famN", function() return gfx.drawText("Ab *Cd* 12 long text wraps", 1, 1, 60, 24, famN) end)
case("rect_famN", function() return gfx.drawText("Ab *Cd* 12", playdate.geometry.rect.new(1, 1, 100, 20), famN) end)
case("empty_fam", function() return gfx.drawText("Ab *Cd* 12", 1, 1, {}) end)
case("setFontFamily", function() gfx.setFontFamily(famN); return gfx.drawText("Ab *Cd* 12", 1, 1) end)
case("fam_then_ctx", function() gfx.drawText("x", 1, 1, famN); return gfx.drawText("Ab *Cd* 12", 1, 1) end)
local fh = playdate.file.open("ffam.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
