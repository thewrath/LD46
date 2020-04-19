math.randomseed(os.time())

am.ascii_color_map = {
    W = vec4(1, 1, 1, 1),          -- full white
    w = vec4(0.75, 0.75, 0.75, 1), -- silver
    K = vec4(0, 0, 0, 1),          -- full black
    k = vec4(0.5, 0.5, 0.5, 1),    -- dark grey
    R = vec4(1, 0, 0, 1),          -- full red
    r = vec4(0.5, 0, 0, 1),        -- half red (maroon)
    Y = vec4(1, 1, 0, 1),          -- full yellow
    y = vec4(0.5, 0.5, 0, 1),      -- half yellow (olive)
    G = vec4(0, 1, 0, 1),          -- full green
    g = vec4(0, 0.5, 0, 1),        -- half green
    C = vec4(0, 1, 1, 1),          -- full cyan
    c = vec4(0, 0.5, 0.5, 1),      -- half cyan (teal)
    p = vec4(0.09, 0.4, 0.4, 1),      -- half cyan (teal)
    B = vec4(0, 0, 1, 1),          -- full blue
    b = vec4(0, 0, 0.5, 1),        -- half blue (navy)
    M = vec4(1, 0, 1, 1),          -- full magenta
    m = vec4(0.5, 0, 0.5, 1),      -- half magenta
    O = vec4(1, 0.5, 0, 1),        -- full orange
    o = vec4(0.5, 0.25, 0, 1),     -- half orange (brown)
}

local Background = require("background")
local Player = require("waiter")
local Plate = require("plate")

local win = am.window{
    title = "Leaning plates",
    width = 840,
    height = 680,
    clear_color = vec4(0, 0.5, 0.5, 1)
}

-- Object that doesn't need to be reset between screen
win.background = Background:new()
win.background:init(win)
win.text_color = vec4(1, 1, 1, 1)
-- Object that need to be reset between screen 
function win:reset()
  self.plates = {}
  self.score = 0
  self.game_over = false
  self.max_plates = 10
  self.plate_velocity = vec2(0, -300)
  
  self.player = Player:new()
  self.player:init(self)
  
  if am.load_state("stat") ~= nil and am.load_state("stat").best_score ~= nil then
    win.best_score = am.load_state("stat").best_score
  else
    win.best_score = 0
  end
end

function win:generate_plate()
  if self.player.has_fall_down then return end
  local plate = Plate:new(math.random(-self.width/2+16*8, self.width/2-16*8), self.height/2+150)
  plate:init(self, self.plate_velocity)
  table.insert(self.plates, plate)
  self.scene"plates":append(
    am.group{
      am.translate(self.plates[#self.plates].pos):tag("platet"..#self.plates)
      ^am.rotate(0):tag("platewaiterr"..#self.plates)
      ^am.rotate(math.rad(self.plates[#self.plates].angle)):tag("plater"..#self.plates)
      ^am.scale(8)
      ^am.sprite(self.plates[#self.plates].image)}:tag("plate"..#self.plates)
    )
  -- move indicator
  self.scene"indicators".color = vec4(1,1,1,1)
  self.scene"indicatort".position2d = self.scene"indicatort".position2d{x=plate.pos.x}
end

function win:increase_score(value, position, color, sound)
  -- play catch sound
  self.scene:action(am.play(am.sfxr_synth(sound)))
  -- update score
  self.score = win.score + value
  self.scene"score".text = self.score
  self.scene"scoreprintert".position2d = position + vec2(25, 25)
  self.scene"scoreprinterv".color = color
  self.scene"scoreprinterv".text = "+"..value
  -- check if difficulty need to be update
  self:update_difficulty()
end

function win:decrease_score(value)
  -- update score
  self.score = win.score - value
  self.scene"score".text = self.score
  self.scene"scoreprintert".position2d = self.player.pos + vec2(25, 25) 
  self.scene"scoreprinterv".color = vec4(0.8,0,0,1)
  self.scene"scoreprinterv".text = "-"..value
  -- check if difficulty need to be update
  -- self:update_difficulty()
end

function win:update_difficulty()
  self.plate_velocity = self.plate_velocity{y=self.plate_velocity.y  - 20}
  self.plate_velocity = math.clamp(self.plate_velocity, vec2(0, -550), vec2(0, 0)) 
  -- self.player:decrease_speed() 
  
  -- if plates length > 100 player start to fall down
  if #self.plates > self.max_plates then
    self.player:fall_down(self.scene)
  elseif #self.plates > self.max_plates - 2 then
    self.player.in_difficulty = true
  end
end

function win:remove_top_plate()
  local plate_removed = false
  self.player.plate_in_hands = nil 
  for i=#self.plates, 1, -1 do
    if self.plates[i].consume == true then
      -- remove from amulet nodes graphe
      self.scene("plates"):remove("plate"..#self.plates)
      table.remove(self.plates, i)
      plate_removed = true
    end
  end
  
  if plate_removed then
    -- play washbasin sound 
    self.scene:action(am.play(am.sfxr_synth(92362602)))
    -- remove score here
    -- self:decrease_score(30)
    self.player.in_difficulty = false
    self.scene"washbasinbublest".position2d = vec2(-350, -self.height/2+16*10-40)
    self.scene:action("washanimation", am.series{am.delay(2), function() 
      self.scene"washbasinbublest".position2d = vec2(-self.width*4, -self.height*4) self.scene:cancel("washanimation")
    end})
  end
end

function win:update_clock()
  local time = os.date("*t")
  local sec = time.sec
  local min = time.min
  local hour = time.hour
  
  self.scene"clockhourr".angle = (hour*(math.pi/6) + (math.pi/360)*min + (math.pi/21600)*sec)
  self.scene"clockminuter".angle = ((math.pi/30)*min + (math.pi/1800)*sec)
  self.scene"clockseconder".angle = -(sec * math.pi/30)
end

function win:over_game()
  self.scene = self:game_over_scene()
  self.scene:action(am.play(am.sfxr_synth(94878709)))
end

function win:start_game()
  self:reset()
  self.scene = self:game_scene()
end

function win:help_game()
  self.scene = self:help_scene()
end

function win:menu_scene()
    -- be sure best_score is defined
    if self.best_score == nil then
      self.best_score = 0
    end
    local line1 = am.text("Leaning", self.text_color)
    local line2 = am.text("plates", self.text_color)
    local line3 = am.text("Keeps all the dishes alive ", self.text_color)
    local line4 = am.text("Press enter to start", self.text_color)
    local line5 = am.text("Press h for help", self.text_color)
    local line6 = am.text("by Thomas Le Goff", am.ascii_color_map.p)
    
    local title = am.group{
        am.translate(0, 150) ^ am.scale(4) ^ line1,
        am.translate(0, 80) ^ am.scale(4) ^ line2,
        am.translate(0, -20) ^ am.scale(3) ^ line3,
        am.translate(0, -130) ^ am.scale(2) ^ line4,
        am.translate(0, -180) ^ am.scale(2) ^ line5,
        am.translate(0, -240) ^ am.scale(2) ^ line6,
    }
    return am.group{
      am.translate(self.background.pos)
            ^ am.scale(self.background.size)
            ^ am.sprite(self.background.image),
      am.translate(-250, -self.height/2+16*10)
            ^ am.rotate(0)
            ^ am.scale(8)
            ^ am.sprite("waiter-welcome.png"),
      am.translate(0, -self.height/2+16*10-55)
            ^ am.line(vec2(-self.width, 0), vec2(self.width, 0), 65, vec4(0.43, 0, 0, 1)),
      am.translate(-350, -self.height/2+16*10-25)
            ^ am.scale(8)
            ^ am.sprite("washbasin.png"),
      am.translate(-200, 100)
            ^ am.scale(8)
            ^ am.sprite("picture.png"),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*3, am.ascii_color_map.r),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*2.5, vec4(0.8,0.8,0.8,1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(180)):tag"clockhourr"
            ^ am.line(vec2(0, 0), vec2(16*1.5, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(90)):tag"clockminuter"
            ^ am.line(vec2(0, 0), vec2(16*2, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(0)):tag"clockseconder"
            ^ am.line(vec2(0, 0), vec2(16*2.4, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 6, am.ascii_color_map.k),
            
      title,
    }:action(function()
      self:update_clock()
        if win:key_pressed"enter" then
            self:start_game()
        elseif win:key_pressed"h" then
            self:help_game()
        end
    end)
end

function win:help_scene()
    -- be sure best_score is defined
    if self.best_score == nil then
      self.best_score = 0
    end
    local line1 = am.text("1 Prevent the plates from breaking", self.text_color)
    local line2 = am.text("2 Put them in the dishwasher, you'll be well ", self.text_color)
    local line2b = am.text("rewarded if you economize water !", self.text_color)
    local line3 = am.text("3 Be careful you can't carry more than 10 plates...", self.text_color)
    local line4 = am.text("Press enter to start", self.text_color)
    local title = am.group{
        am.translate(0, 150) ^ am.scale(1.6) ^ line1,
        am.translate(0, 110) ^ am.scale(1.6) ^ line2,
        am.translate(0, 80) ^ am.scale(1.6) ^ line2b,
        am.translate(0, 40) ^ am.scale(1.6) ^ line3,
        am.translate(0, -130) ^ am.scale(2) ^ line4
    }
    return am.group{
      am.translate(self.background.pos)
            ^ am.scale(self.background.size)
            ^ am.sprite(self.background.image),
      am.translate(0, -self.height/2+16*10-55)
            ^ am.line(vec2(-self.width, 0), vec2(self.width, 0), 65, vec4(0.43, 0, 0, 1)),
      am.translate(-350, -self.height/2+16*10-25)
            ^ am.scale(8)
            ^ am.sprite("washbasin.png"),
      title,
    }:action(function()
        if win:key_pressed"enter" then
            self:start_game()
        end
    end)
end

function win:game_over_scene()
    -- be sure best_score is defined
    if self.best_score == nil then
      self.best_score = 0
    end
    local line1 = am.text("Game", self.text_color)
    local line2 = am.text("Over", self.text_color)
    local line3 = am.text("Best score: "..self.best_score, self.text_color)
    local line4 = am.text("Your score: "..self.score, self.text_color)
    local line5 = am.text("Press enter to restart", self.text_color)
    local line6 = am.text("Press h for help", self.text_color)
    
    
    local title = am.group{
        am.translate(0, 150) ^ am.scale(5) ^ line1,
        am.translate(0, 80) ^ am.scale(5) ^ line2,
        am.translate(0, 10) ^ am.scale(3) ^ line3,
        am.translate(0, -60) ^ am.scale(3) ^ line4,
        am.translate(0, -130) ^ am.scale(2) ^ line5,
        am.translate(0, -180) ^ am.scale(2) ^ line6
    }
    return am.group{
      am.translate(self.background.pos)
            ^ am.scale(self.background.size)
            ^ am.sprite(self.background.image),
      am.translate(0, -self.height/2+16*10-55)
            ^ am.line(vec2(-self.width, 0), vec2(self.width, 0), 65, vec4(0.43, 0, 0, 1)),
      am.translate(-350, -self.height/2+16*10-25)
            ^ am.scale(8)
            ^ am.sprite("washbasin.png"),
      am.translate(-200, 100)
            ^ am.scale(8)
            ^ am.sprite("picture.png"),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*3, am.ascii_color_map.r),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*2.5, vec4(0.8,0.8,0.8,1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(180)):tag"clockhourr"
            ^ am.line(vec2(0, 0), vec2(16*1.5, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(90)):tag"clockminuter"
            ^ am.line(vec2(0, 0), vec2(16*2, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.rotate(math.rad(0)):tag"clockseconder"
            ^ am.line(vec2(0, 0), vec2(16*2.4, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
      am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 6, am.ascii_color_map.k),
      title,
    }:action(function()
        self:update_clock()
        if win:key_pressed"enter" then
            self:start_game()
        elseif win:key_pressed"h" then
            self:help_game()
        end
    end)
end

function win:game_scene()
  -- be sure best_score is defined
  if self.best_score == nil then
    self.best_score = 0
  end
  return am.group{
        am.translate(self.background.pos)
            ^ am.scale(self.background.size)
            ^ am.sprite(self.background.image),
        am.translate(-200, 100)
            ^ am.scale(8)
            ^ am.sprite("picture.png"),
        am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*3, am.ascii_color_map.r),
        am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 16*2.5, vec4(0.8,0.8,0.8,1)),
        am.translate(200, 100)
            ^ am.rotate(math.rad(180)):tag"clockhourr"
            ^ am.line(vec2(0, 0), vec2(16*1.5, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
        am.translate(200, 100)
            ^ am.rotate(math.rad(90)):tag"clockminuter"
            ^ am.line(vec2(0, 0), vec2(16*2, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
        am.translate(200, 100)
            ^ am.rotate(math.rad(0)):tag"clockseconder"
            ^ am.line(vec2(0, 0), vec2(16*2.4, 0), 5, vec4(0.3, 0.3, 0.3, 1)),
        am.translate(200, 100)
            ^ am.circle(vec2(0, 0), 6, am.ascii_color_map.k),
        am.translate(self.player.pos):tag"waitert"
            ^ am.rotate(0):tag"waiterr"
            ^ am.scale(8)
            ^ am.sprite(self.player.image):tag"waiteri",
        am.translate(-self.width/2-16*4, self.height/2 - 25):tag"indicatort"
            ^ am.scale(4)
            ^ am.sprite("indicator.png"):tag"indicators",
        am.group():tag"plates",
        am.translate(0, self.height/2-50)
          ^ am.scale(3)
          ^ am.text(self.score):tag"score",
        am.translate(0, -self.height/2+16*10-55)
            ^ am.line(vec2(-self.width, 0), vec2(self.width, 0), 65, vec4(0.43, 0, 0, 1)),
        am.translate(-350, -self.height/2+16*10-25)
            ^ am.scale(8)
            ^ am.sprite("washbasin.png"),
        am.translate(-350, -self.height/2+16*10-75)
            ^ am.scale(1)
            ^ am.text("Press space"):tag"washbasintouhcv",
        am.translate(0, 0):tag"scoreprintert"
            ^ am.scale(2)
            ^ am.text("+10", vec4(1, 1, 1, 0)):tag"scoreprinterv",
        
        am.translate(-self.width*4, -self.height*4):tag"washbasinbublest"
            ^ am.particles2d{
                source_pos = vec2(0),
                source_pos_var = vec2(40, 0),
                max_particles = 50,
                emission_rate = 30,
                start_particles = 0,
                life = 0.2,
                life_var = 0.1,
                angle = math.rad(90),
                angle_var = math.rad(180),
                speed = 0.02,
                start_color = vec4(0.38, 0.6, 1, 1),
                start_color_var = vec4(0.1, 0.05, 0.0, 0.1),
                end_color = vec4(0.38, 0.6, 1, 1),
                end_color_var = vec4(0.1),
                start_size = 10,
                start_size_var = 5,
                end_size = 2,
                end_size_var = 2,
                gravity = vec2(0, 0),
            }
    }
    :action(am.tween(win.scene"particles2d", 1, {gravity = vec2(0, 0)}))
    :action(am.series({
          am.delay(1.5), 
          am.loop(function() 
              return am.series{am.delay(3), self:generate_plate()}
          end)
    }))
    :action(function(scene)
        self:update_clock()
        if not self.game_over then
          self.scene"washbasintouhcv".color = self.scene"washbasintouhcv".color{w=0}
          self.player:update(win, scene)
          for i=1, #self.plates do self.plates[i]:update(self, scene, i, self.player, self.plates) end
          self.scene"scoreprintert".position2d = self.scene"scoreprintert".position2d + vec2(0, 25) * am.delta_time 
          self.scene"scoreprinterv".color = self.scene"scoreprinterv".color - vec4(0,0,0,0.015)
          self.scene"indicators".color = self.scene"indicators".color - vec4(0,0,0,0.015)
        else
          -- play game over screen here
          if self.best_score == nil or self.score > self.best_score then
            am.save_state("stat", {best_score=self.score})
            self.best_score = score
          end
          self:over_game()
        end
    end):action(function()
        if self:key_pressed"escape" then
            self:close()
        end
    end)
end

win.scene = win:menu_scene()