-- Probe: the dirty rect each kind of direct draw produces, read from the background callback's rect.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx = playdate.graphics
local rects, frame, out = {}, 0, {}
gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h) rects[#rects + 1] = string.format("%d %d %d %d", x, y, w, h) end)
local timg = gfx.image.new(20, 12, gfx.kColorClear); gfx.pushContext(timg); gfx.fillRect(5, 3, 6, 4); gfx.popContext()
local shapes = {
  { "line", function() gfx.drawLine(30, 40, 90, 60) end },
  { "line rev", function() gfx.drawLine(90, 60, 30, 40) end },
  { "line offscreen", function() gfx.drawLine(-20, -10, 50, 30) end },
  { "wide5 butt", function() gfx.setLineWidth(5); gfx.setLineCapStyle(gfx.kLineCapStyleButt); gfx.drawLine(30, 40, 90, 60) end },
  { "wide4 square", function() gfx.setLineWidth(4); gfx.setLineCapStyle(gfx.kLineCapStyleSquare); gfx.drawLine(30, 40, 90, 40) end },
  { "wide6 round", function() gfx.setLineWidth(6); gfx.setLineCapStyle(gfx.kLineCapStyleRound); gfx.drawLine(30, 40, 30, 90) end },
  { "fillRect", function() gfx.fillRect(10, 20, 30, 15) end },
  { "drawRect w3", function() gfx.setLineWidth(3); gfx.drawRect(10, 20, 30, 15) end },
  { "fillEllipse", function() gfx.fillEllipseInRect(10, 20, 31, 17) end },
  { "drawEllipse w4 centered", function() gfx.setLineWidth(4); gfx.drawEllipseInRect(10, 20, 31, 17) end },
  { "arc", function() gfx.drawArc(60, 60, 20, 0, 90) end },
  { "polygon", function() gfx.fillPolygon(10, 10, 60, 20, 40, 70, 5, 50) end },
  { "triangle", function() gfx.fillTriangle(10, 10, 60, 20, 40, 70) end },
  { "drawTriangle", function() gfx.drawTriangle(10, 10, 60, 20, 40, 70) end },
  { "fillRoundRect", function() gfx.fillRoundRect(10, 20, 40, 30, 6) end },
  { "drawRoundRect w3", function() gfx.setLineWidth(3); gfx.drawRoundRect(10, 20, 40, 30, 6) end },
  { "text", function() gfx.drawText("Hello", 20, 30) end },
  { "image transparent", function() timg:draw(30, 30) end },
  { "pixel", function() gfx.drawPixel(77, 33) end },
  { "offset line", function() gfx.setDrawOffset(15, 7); gfx.drawLine(30, 40, 90, 60) end },
  { "clipped fillRect", function() gfx.setClipRect(20, 25, 10, 10); gfx.fillRect(10, 20, 30, 15) end },
  { "drawRect w1", function() gfx.setLineWidth(1); gfx.drawRect(10, 20, 30, 15) end },
  { "drawRect w2", function() gfx.setLineWidth(2); gfx.drawRect(10, 20, 30, 15) end },
  { "drawRect w4", function() gfx.setLineWidth(4); gfx.drawRect(10, 20, 30, 15) end },
  { "drawRect w3 inside", function() gfx.setLineWidth(3); gfx.setStrokeLocation(gfx.kStrokeInside); gfx.drawRect(10, 20, 30, 15) end },
  { "drawRect w3 outside", function() gfx.setLineWidth(3); gfx.setStrokeLocation(gfx.kStrokeOutside); gfx.drawRect(10, 20, 30, 15) end },
  { "drawRoundRect w3 outside", function() gfx.setLineWidth(3); gfx.setStrokeLocation(gfx.kStrokeOutside); gfx.drawRoundRect(10, 20, 40, 30, 6) end },
  { "drawRoundRect w4 inside", function() gfx.setLineWidth(4); gfx.setStrokeLocation(gfx.kStrokeInside); gfx.drawRoundRect(10, 20, 40, 30, 6) end },
  { "fillEllipse even", function() gfx.fillEllipseInRect(10, 20, 30, 16) end },
  { "drawEllipse w1 even", function() gfx.setLineWidth(1); gfx.drawEllipseInRect(10, 20, 30, 16) end },
  { "drawEllipse thick fill path", function() gfx.setLineWidth(9); gfx.setStrokeLocation(gfx.kStrokeInside); gfx.drawEllipseInRect(10, 20, 30, 16) end },
  { "fillCircle", function() gfx.fillCircleAtPoint(50, 50, 10) end },
  { "wide2", function() gfx.setLineWidth(2); gfx.drawLine(30, 40, 70, 90) end },
  { "wide7 round diag", function() gfx.setLineWidth(7); gfx.setLineCapStyle(gfx.kLineCapStyleRound); gfx.drawLine(70, 40, 30, 90) end },
  { "xor line w1", function() gfx.setColor(gfx.kColorXOR); gfx.drawLine(30, 40, 90, 60) end },
  { "xor line w2", function() gfx.setColor(gfx.kColorXOR); gfx.setLineWidth(2); gfx.drawLine(30, 40, 90, 60) end },
  { "xor fillRect", function() gfx.setColor(gfx.kColorXOR); gfx.fillRect(10, 20, 30, 15) end },
  { "fractional xor line", function() gfx.setDrawOffset(0, -16); gfx.setColor(gfx.kColorXOR); gfx.setLineWidth(2); gfx.drawLine(224.0, 64.0, 222.4375, 71.16602) end },
  { "fractional line no xor", function() gfx.setDrawOffset(0, -16); gfx.setLineWidth(2); gfx.drawLine(224.0, 64.0, 222.4375, 71.16602) end },
  { "integer line no xor", function() gfx.setDrawOffset(0, -16); gfx.setLineWidth(2); gfx.drawLine(224, 64, 222, 71) end },
  { "polyline", function() gfx.drawPolygon(10, 10, 60, 20, 40, 70) end },
}
function playdate.update()
  frame = frame + 1
  gfx.sprite.update()
  if frame > 2 and frame % 2 == 1 and shapes[(frame - 3) // 2 + 1] then out[#out + 1] = shapes[(frame - 3) // 2 + 1][1] .. "|" .. table.concat(rects, ";") end
  rects = {}
  local i = frame // 2
  if frame % 2 == 0 and shapes[i] then
    gfx.pushContext(); shapes[i][2](); gfx.popContext()
  end
  if frame == 2 * #shapes + 3 then
    local fh = playdate.file.open("dirtyb.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end
  end
end
