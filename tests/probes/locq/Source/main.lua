import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local function p(...) local t = {} for i = 1, select('#', ...) do t[#t+1] = tostring((select(i, ...))) end out[#out+1] = table.concat(t, " ") end
for _, k in ipairs({"alpha", "beta", "Zed", "gamma", "missing", "alph", "phaa"}) do
  p(k, gfx.getLocalizedText(k), gfx.getLocalizedText(k, gfx.font.kLanguageEnglish), gfx.getLocalizedText(k, gfx.font.kLanguageJapanese))
end
p("sys", playdate.getSystemLanguage())
p(pcall(gfx.getLocalizedText, nil))
p(pcall(gfx.getLocalizedText, "alpha", 7))
local function count(img)
  local n, h = 0, 0
  for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then n = n + 1; h = (h * 31 + x * 7 + y * 13) % 1000003 end end end
  return n .. "/" .. h
end
local function drawp(name, f, ...)
  local img = gfx.image.new(400, 240, gfx.kColorWhite)
  gfx.pushContext(img)
  local r = table.pack(pcall(f, ...))
  gfx.popContext()
  local t = {} for i = 1, r.n do t[#t+1] = tostring(r[i]) end
  p(name, r.n, table.concat(t, " "), count(img))
end
drawp("d1", gfx.drawLocalizedText, "beta", 10, 10)
drawp("d2", gfx.drawLocalizedText, "missing", 10, 30)
drawp("d3", gfx.drawLocalizedText, "alpha", 10, 50, 100, 40)
drawp("d4", gfx.drawLocalizedText, "alpha", 10, 50, gfx.font.kLanguageJapanese)
drawp("d5", gfx.drawLocalizedText, "gamma", 10, 50, nil, 5)
drawp("d6", gfx.drawLocalizedText, "alpha", 10, 50, "jp")
drawp("d7", gfx.drawLocalizedText, "alpha", playdate.geometry.rect.new(10, 50, 100, 40))
drawp("d8", gfx.drawLocalizedText, "alpha", 10.6, 50.4)
drawp("d9", gfx.drawLocalizedText, "multi", 10, 50)
drawp("d10", gfx.drawLocalizedText, "multi", 10, 50, nil, 5)
drawp("d11", gfx.drawLocalizedText, "multi", 10, 50, gfx.font.kLanguageEnglish, -3)
drawp("d12", gfx.drawLocalizedText, "alpha", 10, 50, 7)
drawp("d13", gfx.drawLocalizedText, "alpha", 10)
drawp("d14", gfx.drawLocalizedText, nil, 10, 50)
drawp("d15", gfx.drawLocalizedText, "beta", 10, 50, {})
p("g", gfx.getLocalizedText("multi"))
drawp("a1", gfx.drawLocalizedTextAligned, "alpha", 200, 70, kTextAlignment.center)
drawp("a2", gfx.drawLocalizedTextAligned, "missing", 200, 70, kTextAlignment.right)
drawp("a3", gfx.drawLocalizedTextAligned, "alpha", 200, 70, kTextAlignment.right, gfx.font.kLanguageJapanese)
drawp("r1", gfx.drawLocalizedTextInRect, "gamma", 10, 90, 100, 40)
drawp("r2", gfx.drawLocalizedTextInRect, "beta", playdate.geometry.rect.new(10, 90, 30, 60))
drawp("r3", gfx.drawLocalizedTextInRect, "missing", 10, 90, 100, 40, nil, "...", kTextAlignment.center)
drawp("r4", gfx.drawLocalizedTextInRect, "alpha", 10, 90, 100, 40, nil, nil, kTextAlignment.right, nil, gfx.font.kLanguageJapanese)
p(pcall(gfx.getLocalizedText, "alpha", gfx.font.kLanguageJapanese))
p(pcall(gfx.getLocalizedText, "alpha", "jp"))
p(pcall(gfx.getLocalizedText, "alpha", "en"))
p(pcall(gfx.getLocalizedText, "alpha", -1))
p(pcall(gfx.getLocalizedText, ""))
p(pcall(gfx.getLocalizedText, 5))
playdate.datastore.write({}, "x")
local f = playdate.file.open("out.txt", playdate.file.kFileWrite) f:write(table.concat(out, "\n") .. "\n") f:close()
function playdate.update() end
