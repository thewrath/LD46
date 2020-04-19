module = "plate"

local utils = require("utils")

local plate = {}

plate.pos = vec2(0)
plate.velocity = vec2(0, -300)
plate.angle = 0
-- check if plate already compute in the score
plate.consume = false

plate.image = "plate-1.png"

-- Init function, add stuff to amulet scene
function plate:init(win, velocity)
  -- if the plate is near the washbasin is velocity is increase
  plate.velocity = velocity
  plate.angle = math.random(-15, 15)
  plate.image = "plate-"..math.random(1, 4)..".png"
end

-- update function, call every frame
function plate:update(win, scene, id, player, plates) 
  local in_collision = false
  -- plate is in player hand 
  if player.plate_in_hands == id then
    self.pos = self.pos{x=player.pos.x}
    in_collision = true
  else
    -- compute collisions with player and the other plate
    -- if not the first plate 
    if id ~= 1 then
      if utils.rect_collision(self.pos.x, self.pos.y, 16*8, 16*4, plates[id-1].pos.x, plates[id-1].pos.y, 16*8, 16*4)  then
         self.pos = self.pos{x=plates[id-1].pos.x, y=plates[id-1].pos.y+16*2}
         plates[id-1].angle = plates[id-1].angle + self.angle
         if not self.consume then
          if #plates >= win.max_plates - win.max_plates/4 then
            win:increase_score(30 , self.pos, am.ascii_color_map.Y, 67456000)  
          else
            win:increase_score(10, self.pos, vec4(1, 1, 1, 1), 64451400)  
          end
          self.consume = true
        end
         in_collision = true
      end
    end
    
    -- if collide payer
    if utils.rect_collision(self.pos.x, self.pos.y, 16*8, 16*8, player.pos.x, player.pos.y, 16*8, 16*8) then
      -- if it's first plate clip it to player hand 
      if player.plate_in_hands == nil then
        player.plate_in_hands = id
        -- fix plate.y at good position
        self.pos = self.pos{y=player.pos.y+16*4}
        if not self.consume then
          win:increase_score(10, self.pos, vec4(1, 1, 1, 1), 64451400)
          self.consume = true
        end
        in_collision = true
      end
    end
  end
  
  if not in_collision then
    self.pos = self.pos + self.velocity * am.delta_time
    self.pos = math.clamp(self.pos, vec2(-win.width/2,-win.height/2), vec2(win.width,win.height))
  end
  
  -- if plate on the ground
  if self.pos.y < player.pos.y then
    win.game_over = true
  end
  -- update position
  scene("platet"..id).position2d = self.pos
  
  -- set angle to be the same as the player one
  if self.consume then
    scene("platewaiterr"..id).angle = math.rad(player.angle)
  end
  
end

local constructor = {}
constructor.object = plate

function constructor:new()
  return table.shallow_copy(self.object)
end

function constructor:new(x,y)
  local p = table.shallow_copy(self.object)
  p.pos = plate.pos{x=x, y=y}
  return p
end

return constructor