-- Probe: a sprite made without an image that sets its image in its own update.
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/timer"
local gfx = playdate.graphics
gfx.setBackgroundColor(gfx.kColorBlack); gfx.clear(gfx.kColorBlack)
local tbl = gfx.imagetable.new("images/arrow")
local variants = {}
local function make(name, x, opts)
  local s = gfx.sprite.new()
  if opts.z then s:setZIndex(opts.z) end
  if opts.ignore then s:setIgnoresDrawOffset(true) end
  local loop = opts.loop and gfx.animation.loop.new(200, tbl, true)
  s.update = function() s:setImage(loop and loop:image() or tbl:getImage(1)) end
  if not opts.late then s:add(); s:moveTo(x, 100) end
  variants[#variants + 1] = { name = name, s = s, x = x, opts = opts }
end
make("plain", 30, {})
make("z200", 80, { z = 200 })
make("ignoreOffset", 130, { ignore = true })
make("loop", 180, { loop = true })
make("late_add", 230, { late = true })
make("all", 280, { z = 200, ignore = true, loop = true, late = true })
local f = 0
function playdate.update()
  f = f + 1
  if f == 5 then for _, v in ipairs(variants) do if v.opts.late then v.s:add(); v.s:moveTo(v.x, 100) end end end
  if f > 5 then for _, v in ipairs(variants) do if v.opts.late then v.s:moveTo(v.x, 100) end end end
  gfx.sprite.update()
  playdate.timer.updateTimers()
  if f == 20 then
    local d = gfx.getDisplayImage(); local out = {}
    for _, v in ipairs(variants) do
      local n = 0
      for y = 80, 120 do for x = v.x - 20, v.x + 20 do if d:sample(x, y) == gfx.kColorWhite then n = n + 1 end end end
      out[#out + 1] = v.name .. "\twhite=" .. n
    end
    local fh = playdate.file.open("arrow.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
    if playdate.simulator then playdate.simulator.exit() end; playdate.stop()
  end
end
