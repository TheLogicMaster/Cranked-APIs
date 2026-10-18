-- Probe: listFiles order in the data folder for files made at run time, and after deleting and re-adding
local names = { "zeta.txt", "Alpha.txt", "mid.dat", "beta.txt", "_under.txt", "10.txt", "9.txt", "a.txt", "B.txt" }
for _, n in ipairs(names) do local f = playdate.file.open(n, playdate.file.kFileWrite) f:write(n) f:close() end
playdate.file.mkdir("dirB") playdate.file.mkdir("adir")
local function list(p) local l = playdate.file.listFiles(p) return l and table.concat(l, ",") or "nil" end
local out = { "root " .. list("") }
playdate.file.delete("mid.dat")
local f = playdate.file.open("mid.dat", playdate.file.kFileWrite) f:write("x") f:close()
out[#out + 1] = "readd " .. list("")
local f2 = playdate.file.open("dirB/x.txt", playdate.file.kFileWrite) f2:write("x") f2:close()
local f3 = playdate.file.open("dirB/A.txt", playdate.file.kFileWrite) f3:write("x") f3:close()
out[#out + 1] = "dirB " .. list("dirB")
out[#out + 1] = "dirB/ " .. list("dirB/")
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite) fh:write(table.concat(out, "\n") .. "\n") fh:close()
function playdate.update() end
