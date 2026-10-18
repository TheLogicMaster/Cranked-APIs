local scene = { name = "retro" }
function scene:draw() return "drew " .. self.name end
function scene:setup() self.ready = true end
scene:setup()
return scene
