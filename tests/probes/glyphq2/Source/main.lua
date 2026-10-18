-- Probe: drawText's returned size and pixels with missing and skipped code points
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local cases = { "A\u{FE0F}B", "A\u{200D}B", "A\u{4E00}B", "A\u{1F600}B", "A\u{2B05}\u{FE0F}B", "A\u{E9}B", "A\u{FFFD}B", "A\u{7F}B", "\u{4E00}", "x\u{4E00}", "\u{4E00}\n\u{4E00}", "ab\ncd", "A\u{0301}", "gy\u{4E00}" }
for i, s in ipairs(cases) do
  local img = gfx.image.new(120, 50, gfx.kColorWhite)
  gfx.pushContext(img) local w, h = gfx.drawText(s, 2, 2) gfx.popContext()
  local n, hs = 0, 0
  for y = 0, 49 do for x = 0, 119 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1 hs = (hs * 31 + x * 3 + y) % 1000003 end end end
  local tw, th = gfx.getTextSize(s)
  fh:write(i .. " w=" .. tostring(w) .. " h=" .. tostring(h) .. " tw=" .. tw .. " th=" .. th .. " px=" .. n .. " hash=" .. hs .. "\n")
end
fh:close()
function playdate.update() end
