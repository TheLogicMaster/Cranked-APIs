-- Probe: the height of wrapped text drawn with a font family whose lines use fonts of different heights (a variant
-- missing from the family, a styled run, a character the font lacks). For each case: the returned size, and the
-- rows of the image that have black pixels, as runs "first-last".
import "CoreLibs/graphics"
local gfx = playdate.graphics
local light = gfx.font.new("Nontendo-Light"); local bold = gfx.font.new("Nontendo-Bold")
local out = {}
local img = gfx.image.new(120, 160)
local function rows()
  local runs, start = {}, nil
  for y = 0, 159 do
    local any = false
    for x = 0, 119 do if img:sample(x, y) == gfx.kColorBlack then any = true break end end
    if any and not start then start = y end
    if not any and start then runs[#runs + 1] = start .. "-" .. (y - 1); start = nil end
  end
  if start then runs[#runs + 1] = start .. "-159" end
  return table.concat(runs, " ")
end
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setFont(gfx.getSystemFont())
  local w, h = fn(); gfx.popContext()
  out[#out + 1] = name .. " " .. tostring(w) .. "," .. tostring(h) .. " rows " .. rows()
end
local famN = { [gfx.font.kVariantNormal] = light }
local famNB = { [gfx.font.kVariantNormal] = light, [gfx.font.kVariantBold] = bold }
out[#out + 1] = "heights system " .. gfx.getSystemFont():getHeight() .. " bold " .. gfx.getSystemFont("bold"):getHeight() .. " light " .. light:getHeight() .. " nbold " .. bold:getHeight()
local texts = { "Ab *Cd* 12 long text wraps", "aaaa bbbb *cccc* dddd eeee", "*aaaa* bbbb cccc dddd", "aaaa bbbb cccc *dddd*", "aa \u{24B6} bb cc dd ee ff gg" }
for i, t in ipairs(texts) do
  case("famN" .. i, function() return gfx.drawText(t, 1, 1, 60, 150, famN) end)
  case("famNB" .. i, function() return gfx.drawText(t, 1, 1, 60, 150, famNB) end)
  case("sys" .. i, function() return gfx.drawText(t, 1, 1, 60, 150) end)
  case("light" .. i, function() gfx.setFont(light) return gfx.drawText(t, 1, 1, 60, 150) end)
  case("rect_light" .. i, function() return gfx.drawTextInRect(t, 1, 1, 60, 150, nil, nil, nil, light) end)
end
-- lines given by newlines, so the lines are known: which font sets each line's height, and the returned height
for _, t in ipairs({ "aa", "*aa*", "bb", "dd", "*aa*\nbb\ncc", "aa\n*bb*\ncc", "aa\nbb\n*cc*", "aa *bb*\ncc", "aa\nbb *cc*",
    "aa\n\ncc", "*aa*\n\ncc", "aa\n*\n*cc", "aa\n", "*aa*\n", "aa*\n*bb\ncc", "aa*\n", "aa*\nbb*\ncc", "aa\n*bb\n*cc",
    "*aa\n*\ncc", "aa\n*\n" }) do
  local name = t:gsub("\n", "/")
  case("nl_famN " .. name, function() return gfx.drawText(t, 1, 1, famN) end)
  case("nl_famN_box " .. name, function() return gfx.drawText(t, 1, 1, 100, 150, famN) end)
end
-- wrapped lines whose glyphs come from different fonts (60 wide)
for _, t in ipairs({ "aaaa bbbb *cc*", "aaaa bbbb *cc* dd", "aaaa bbbb\n*cc*", "aaaa bbbb *cc*\ndd", "aaaa bbbb *cc* dddd eeee",
    "aaaa *bbbbbbbbbb*", "aaaa bbbb *c*c", "aaaa bbbb c*c*" }) do
  case("wrap_famN " .. t:gsub("\n", "/"), function() return gfx.drawText(t, 1, 1, 60, 150, famN) end)
end
case("famN_short_box", function() return gfx.drawText(texts[1], 1, 1, 60, 24, famN) end)
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
function playdate.update() end
