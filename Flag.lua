Flag = Class{}

local MOVE_DOWN = 60

function Flag:init(map)
  self.width = 16
  self.height = 16

  self.map = map
  self.player = Player(map, x, dx, flagGrabbed)

  -- set exact location of the flag since it should not align
  -- with tiles to look right
  self.x = (self.map.mapWidth * self.width) - (self.width * 6.5)
  self.y = self.height * 2.5
  self.flagInit = self.height * 2.5

  -- set flags y velocity
  self.dy = 0

  -- set the path to the spritesheet and generate the quads needed
  self.texture = love.graphics.newImage('graphics/spritesheet.png')
  self.frames = generateQuads(self.texture, 16, 16)

  -- set inital flag state to idle
  self.state = 'idleFlag'

  -- boolean check to see if flag is up or down
  self.grounded = false


  -- define animations and needed tiles for animations
  self.animations = {
    ['wavingFlag'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[13], self.frames[14]
      },
      interval = .15
    },
    ['idleFlag'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[15]
      },
      interval = 1
    },
  }

  -- set initial animation
  self.animation = self.animations['idleFlag']

  -- define the different flag behaviors
  self.behaviors = {
    ['idleFlag'] = function(dt)
      if self.player.x >= (self.map.mapWidth * self.width) - (self.width * 15) then
        self.x = (self.map.mapWidth * self.width) - (self.width * 5.5)
        self.state = 'wavingFlag'
        self.animation = self.animations['wavingFlag']
      elseif self.player.x < (self.map.mapWidth * self.width) - (self.width * 19) and self.player.dx < 0 then
        self.x = (self.map.mapWidth * self.width) - (self.width * 6.5)
        self.state = 'idleFlag'
        self.animation = self.animations['idleFlag']
      end
    end,
    ['wavingFlag'] = function(dt)
      if self.player.x < (self.map.mapWidth * self.width) - (self.width * 19) then
        self.x = (self.map.mapWidth * self.width) - (self.width * 6.5)
        self.state = 'idleFlag'
        self.animation = self.animations['idleFlag']
      elseif self.player.x > (self.map.mapWidth * self.width) - (self.width * 15) and self.player.dx > 0 then
        self.x = (self.map.mapWidth * self.width) - (self.width * 5.5)
        self.state = 'wavingFlag'
        self.animation = self.animations['wavingFlag']
      end
    end,
    ['flagDown'] = function(dt)
      if self.y + self.height <= (self.player.y + self.player.height) then
        self.dy = MOVE_DOWN
      else
        self.dy = 0
        self.grounded = true
      end
    end
  }
end

function Flag:update(dt)
  self.y = self.y + self.dy * dt
  self.animation:update(dt)
  self.behaviors[self.state](dt)
  self.player:update(dt)

  -- check to see if player has grabbed the flag pole,
  -- if so then set flag state so the flag drops
  if self.player.flagGrabbed == true then
    self.state = 'flagDown'
  end
end


function Flag:render()

  -- set initial direction of the flag based around the x axis
  local FlagScaleX = -1

  -- change the flag direction based off of the flags state
  if self.state == 'idle' then
    FlagScaleX = -1
  elseif self.state == 'wavingFlag' or self.state == 'flagDown' then
    FlagScaleX = 1
  end

  -- draw the flag
  love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2), 0, FlagScaleX, 1, self.width / 2, self.height / 2)
end
