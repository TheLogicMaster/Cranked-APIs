-- Probe (differential): one random display configuration per run (scale, offset, flips, inversion,
-- background color) over random screen content; the runner's dump of the displayed frame is compared between builds.
-- The configuration comes from a counter kept in the datastore, so successive runs cover different cases.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local state = playdate.datastore.read("n") or { n = 0 }
state.n = state.n + 1
playdate.datastore.write(state, "n")
math.randomseed(state.n * 7919)
local R = math.random
local scales = { 1, 2, 4, 8 }
playdate.display.setScale(scales[R(4)])
playdate.display.setOffset(R(-60, 60), R(-40, 40))
playdate.display.setFlipped(R(2) == 1, R(2) == 1)
playdate.display.setInverted(R(2) == 1)
gfx.setBackgroundColor(R(2) == 1 and gfx.kColorWhite or gfx.kColorBlack)
function playdate.update()
  gfx.clear()
  for _ = 1, 40 do
    gfx.setColor(R(2) == 1 and gfx.kColorWhite or gfx.kColorBlack)
    gfx.fillRect(R(-20, 400), R(-20, 240), R(1, 120), R(1, 80))
  end
  gfx.setColor(gfx.kColorBlack); gfx.drawLine(0, 0, 399, 239); gfx.drawText("Probe " .. state.n, R(0, 300), R(0, 200))
end
