-- Probe: how many files can be open at once, the error for one more, and whether closing frees a slot
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local files = {}
local firstNil, err
for i = 1, 80 do
  local f, e = playdate.file.open("data/t.txt", playdate.file.kFileRead)
  if not f and not firstNil then firstNil, err = i, e end
  files[#files + 1] = f or false
end
fh:write("first nil at " .. tostring(firstNil) .. " err " .. tostring(err) .. "\n")
-- writes count too?
local w, we = playdate.file.open("w.txt", playdate.file.kFileWrite)
fh:write("write open while full " .. tostring(w ~= nil) .. " " .. tostring(we) .. "\n")
if files[1] then files[1]:close() end
local g, ge = playdate.file.open("data/t.txt", playdate.file.kFileRead)
fh:write("after one close " .. tostring(g ~= nil) .. " " .. tostring(ge) .. "\n")
for i = 2, #files do if files[i] then files[i]:close() end end
if g then g:close() end
files = {}
for i = 1, 70 do local f = playdate.file.open("data/t.txt") if not f then fh:write("default mode nil at " .. i .. "\n") break end files[#files + 1] = f end
for _, f in ipairs(files) do f:close() end
-- garbage collected files free their slots?
for i = 1, 70 do playdate.file.open("data/t.txt") end
collectgarbage("collect")
local h = playdate.file.open("data/t.txt")
fh:write("after gc " .. tostring(h ~= nil) .. "\n")
fh:close()
function playdate.update() end
