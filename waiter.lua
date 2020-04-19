module = "waiter"

local utils = require("utils")

local waiter = {}

waiter.velocity = vec2(0)
waiter.pos = vec2(0, 0)
waiter.max_velocity = vec2(400)
waiter.min_velocity = vec2(-400)
waiter.speed = 40
waiter.min_speed = 20
waiter.max_speed = 45
waiter.plate_in_hands = nil
waiter.has_fall_down = false
waiter.angle = 0
waiter.in_difficulty = false

waiter.image = "waiter.png"

-- Init function, add stuff to amulet scene
function waiter:init(win)
  self.pos = self.pos{y=-win.height/2+16*10}
end

-- update function, call every frame
function waiter:update(win, scene)
  
  self.angle = 0
  if not self.has_fall_down then
    self:drop_plat(win)
    if win:key_down"a" or win:key_down"left" then
      self.velocity = self.velocity{x=self.velocity.x - self.speed}
      self.angle = self.angle -3
    elseif win:key_down"d" or win:key_down"right" then
      self.velocity = self.velocity{x=self.velocity.x + self.speed}
      self.angle = self.angle + 3
    end
    self.velocity = math.clamp(self.velocity, self.min_velocity, self.max_velocity)
    
    self.pos = self.pos + self.velocity * am.delta_time
    self.pos = math.clamp(self.pos, vec2(-win.width/2,-win.height/2), vec2(win.width/2,win.height/2))
  else
    win.game_over = true
  end
  scene"waitert".position2d = self.pos
  scene"waiterr".angle = math.rad(self.angle)
end

function waiter:drop_plat(win)
  -- check if the waiter is near the washbasin
  if utils.rect_collision(self.pos.x, self.pos.y, 16*8, 16*8, -350, -win.height/2+16*10-25, 16*8, 16*8) then
    win.scene"washbasintouhcv".color = win.scene"washbasintouhcv".color{w=1}
    
    if win:key_down"space" then
      win:remove_top_plate()
    end
    
  end
end

function waiter:decrease_speed()
  self.speed = self.speed - 5
  self.speed = math.clamp(self.speed, self.min_speed, self.max_speed)
end

function waiter:fall_down(scene)
  self.pos = self.pos{y=self.pos.y - 16*2}
  scene:action(am.series{am.delay(0), function() self.has_fall_down = true end})
end

local constructor = {}
constructor.object = waiter

function constructor:new()
  return table.shallow_copy(self.object)
end

return constructor