-- Probe: the display image and clearing at display scale 2
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local frame = 0
function playdate.update()
  frame += 1
  if frame <= 2 then gfx.clear(gfx.kColorBlack) end
  if frame == 3 then playdate.display.setScale(2) end
  if frame == 4 then gfx.clear(gfx.kColorBlack) gfx.setColor(gfx.kColorWhite) gfx.fillRect(0, 0, 10, 10) gfx.fillRect(195, 115, 10, 10) end
  if frame == 6 then
    local img = gfx.getDisplayImage()
    local w, h = img:getSize()
    local t = {}
    for _, p in ipairs({ {5, 5}, {100, 60}, {196, 116}, {199, 119}, {200, 120}, {202, 117}, {197, 122}, {300, 200}, {399, 239}, {300, 100}, {300, 130}, {399, 0}, {100, 200}, {210, 5} }) do
      t[#t + 1] = p[1] .. "," .. p[2] .. "=" .. tostring(img:sample(p[1], p[2]))
    end
    out:write("display image\t" .. w .. "x" .. h .. " " .. table.concat(t, " ") .. "\n")
    local wi = gfx.getWorkingImage() local ww, wh = wi:getSize()
    out:write("working image\t" .. ww .. "x" .. wh .. "\n")
    out:write("display size\t" .. playdate.display.getWidth() .. "x" .. playdate.display.getHeight() .. " scale " .. playdate.display.getScale() .. "\n")
    out:close()
  end
end
