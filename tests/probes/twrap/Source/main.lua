-- Probe: drawText with a width and height: default wrap mode, explicit modes, alignment, and the returned size.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(120, 64)
local function dump(name, w, h)
  local t = {}
  for y = 0, 63 do for x = 0, 119 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. tostring(w) .. "," .. tostring(h) .. "|" .. table.concat(t)
end
local function case(name, fn) img:clear(gfx.kColorWhite); gfx.pushContext(img); local w, h = fn(); gfx.popContext(); dump(name, w, h) end
local s = "Ab Cd 12 long text wraps here"
case("wh_default", function() return gfx.drawText(s, 1, 1, 60, 40) end)
case("wh_small", function() return gfx.drawText(s, 1, 1, 60, 10) end)
case("wh_clip", function() return gfx.drawText(s, 1, 1, 60, 40, nil, 0, gfx.kWrapClip) end)
case("wh_char", function() return gfx.drawText(s, 1, 1, 60, 40, nil, 0, gfx.kWrapCharacter) end)
case("wh_word", function() return gfx.drawText(s, 1, 1, 60, 40, nil, 0, gfx.kWrapWord) end)
case("wh_center", function() return gfx.drawText(s, 1, 1, 60, 40, nil, 0, nil, gfx.kAlignCenter) end)
case("wh_center_w", function() return gfx.drawText(s, 1, 1, 60, 40, nil, nil, gfx.kWrapWord, gfx.kAlignCenter) end)
case("wh_ktext_right", function() return gfx.drawText(s, 1, 1, 60, 60, nil, 0, gfx.kWrapWord, kTextAlignment.right) end)
case("wh_char_right", function() return gfx.drawText(s, 1, 1, 60, 60, nil, nil, gfx.kWrapCharacter, gfx.kAlignRight) end)
case("rect_center", function() return gfx.drawText(s, playdate.geometry.rect.new(1, 1, 60, 40), nil, nil, nil, gfx.kAlignCenter) end)
case("wh_right", function() return gfx.drawText(s, 1, 1, 60, 60, nil, 0, gfx.kWrapWord, gfx.kAlignRight) end)
case("wh_lead", function() return gfx.drawText(s, 1, 1, 60, 60, nil, 4) end)
case("seq_align_only", function() return gfx.drawText(s, 1, 1, 60, 40, nil, gfx.kAlignCenter) end)
case("seq_swapped", function() return gfx.drawText(s, 1, 1, 60, 40, nil, gfx.kWrapCharacter, 3, gfx.kAlignRight) end)
case("seq_nofam", function() return gfx.drawText(s, 1, 1, 60, 40, gfx.kAlignRight) end)
case("seq_two_leads", function() return gfx.drawText(s, 1, 1, 60, 60, nil, 5, 1) end)
case("seq_noboxalign", function() return gfx.drawText("Hi", 1, 1, nil, gfx.kAlignRight) end)
case("rect_default", function() return gfx.drawText(s, playdate.geometry.rect.new(1, 1, 60, 40)) end)
case("short", function() return gfx.drawText("Hi", 1, 1, 60, 40) end)
case("nl", function() return gfx.drawText("Hi\nthere you", 1, 1, 60, 40) end)
out[#out + 1] = "consts|" .. tostring(gfx.kAlignLeft) .. "," .. tostring(gfx.kAlignCenter) .. "," .. tostring(gfx.kAlignRight) .. "," .. tostring(gfx.kWrapClip) .. "," .. tostring(gfx.kWrapCharacter) .. "," .. tostring(gfx.kWrapWord) .. "|"
local fh = playdate.file.open("twrap.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
