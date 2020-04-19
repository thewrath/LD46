module = "background"

local background = {}

background.velocity = vec2(0)
background.pos = vec2(0)
background.size = vec2(84, 68)

background.image = [[
  pppppppppp
  cccccccccc
  cccccccccc
  cccccccccc
  cccccccccc
  cccccccccc
  cccccccccc
  cccccccccc
  rrrrrrrrrr
  rrrrrrrrrr
]]

-- Init function, add stuff to amulet scene
function background:init(win)
end

-- update function, call every frame
function background:update(win, scene) 
    
end

local constructor = {}
constructor.object = background

function constructor:new()
  return self.object
end

return constructor