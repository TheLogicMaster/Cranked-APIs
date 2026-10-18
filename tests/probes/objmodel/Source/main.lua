import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"
local gfx, geom, snd = playdate.graphics, playdate.geometry, playdate.sound
local out = {}
local objects = {
    { "sprite", function() return gfx.sprite.new() end },
    { "image", function() return gfx.image.new(4, 4) end },
    { "imagetable", function() return gfx.imagetable.new(2) end },
    { "tilemap", function() return gfx.tilemap.new() end },
    { "font", function() return gfx.getSystemFont() end },
    { "rect", function() return geom.rect.new(1, 2, 3, 4) end },
    { "point", function() return geom.point.new(1, 2) end },
    { "vector2D", function() return geom.vector2D.new(1, 2) end },
    { "size", function() return geom.size.new(1, 2) end },
    { "lineSegment", function() return geom.lineSegment.new(0, 0, 1, 1) end },
    { "arc", function() return geom.arc.new(0, 0, 5, 0, 90) end },
    { "polygon", function() return geom.polygon.new(0, 0, 1, 0, 1, 1) end },
    { "affineTransform", function() return geom.affineTransform.new() end },
    { "synth", function() return snd.synth.new() end },
    { "sample", function() return snd.sample.new(0.1) end },
    { "sampleplayer", function() return snd.sampleplayer.new(snd.sample.new(0.1)) end },
    { "lfo", function() return snd.lfo.new() end },
    { "channel", function() return snd.channel.new() end },
    { "sequence", function() return snd.sequence.new() end },
    { "file", function() return playdate.file.open("x.txt", playdate.file.kFileWrite) end },
    { "graph", function() return playdate.pathfinder.graph.new() end },
    { "timer", function() return playdate.timer.new(1000) end },
}
for _, o in ipairs(objects) do
    local ok, v = pcall(o[2])
    if not ok then out[#out + 1] = o[1] .. "\tERR " .. tostring(v) else
        local t = type(v)
        local setok = pcall(function() v.customField = 42 end)
        local getv = setok and select(2, pcall(function() return v.customField end)) or nil
        local npairs = 0
        local pok = pcall(function() for _ in pairs(v) do npairs = npairs + 1 end end)
        local mt = getmetatable(v)
        local mtdesc = mt == nil and "nil" or (type(mt) == "table" and (rawget(mt, "__name") and tostring(rawget(mt, "__name")) or "table") or tostring(mt))
        local rawok = pcall(function() return rawget(v, "customField") end)
        out[#out + 1] = string.format("%s\ttype=%s custom=%s/%s pairs=%s(%d) mt=%s rawget=%s tostring=%s", o[1], t, tostring(setok), tostring(getv), tostring(pok), npairs, mtdesc, tostring(rawok), tostring(v):gsub("0x%x+", "ADDR"))
    end
end
local f = playdate.file.open("obj.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
