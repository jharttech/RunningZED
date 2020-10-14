Player = Class{}

local MOVE_SPEED = 120
local JUMP_VELOCITY = 550
local GRAVITY = 40
local DROP = 60

function Player:init(map)
  self.width = 16
  self.height = 20

  self.map = map

  -- set initial location of player
  self.x = map.tilewidth * 10
  self.y = map.tileheight * ((map.mapHeight / 2) - 1) - self.height

  -- set initial velocity
  self.dx = 0
  self.dy = 0

  -- set coin tigger to false
  self.coinUp = false

  -- set the path to the needed spritesheet for the player and
  -- create the needed quads
  self.texture = love.graphics.newImage('graphics/blue_alien.png')
  self.frames = generateQuads(self.texture, 16, 20)

  -- set initial state, and needed triggers
  self.state = 'idle'
  self.direction = 'right'
  self.falling = false
  self.flagGrabbed = false
  self.fell = false
  self.jumpBlockCheck = false

  -- set a table of needed sounds
  self.sounds = {
    ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
    ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
    ['coin'] = love.audio.newSource('sounds/coin.wav', 'static')
  }

  -- define player animaions and frames needed
  self.animations = {
    ['idle'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[1]
      },
      interval = 1
    },
    ['walking'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[9], self.frames[10], self.frames[11]
      },
      interval = 0.15
    },
    ['jumping'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[3]
      },
      interval = 1
    },
  }

  -- define initial animation
  self.animation = self.animations['idle']

  -- make state machine
  self.behaviors = {
    ['idle'] = function(dt)
      --self.dy = 0
      if love.keyboard.wasPressed('space') then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animation = self.animations['jumping']
        self.sounds['jump']:play()
      elseif love.keyboard.isDown('left') and self.x > 0 then
        --self.dx = -MOVE_SPEED
        self.state = 'walking'
        --self.animation = self.animations['walking']
        --self.direction = 'left'
      elseif love.keyboard.isDown('right') then
        --self.dx = MOVE_SPEED
        self.state = 'walking'
        --self.animation = self.animations['walking']
        --self.direction = 'right'
      else
        --self.animation = self.animations['idle']
        self.dx = 0
      end
    end,
    ['walking'] = function(dt)
      if love.keyboard.wasPressed('space') then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animation = self.animations['jumping']
        self.sounds['jump']:play()
      elseif love.keyboard.isDown('left') and self.flagGrabbed == false and self.x > 0 then
        if love.keyboard.wasPressed('space') then
          self.dy = -JUMP_VELOCITY
          self.state = 'jumping'
          self.animation = self.animations['jumping']
          self.sounds['jump']:play()
        end
        self.dx = -MOVE_SPEED
        self.animation = self.animations['walking']
        self.direction = 'left'
        self:checkLeftCollision()
      elseif love.keyboard.isDown('right') then
        if love.keyboard.wasPressed('space') then
          self.dy = -JUMP_VELOCITY
          self.state = 'jumping'
          self.animation = self.animations['jumping']
          self.sounds['jump']:play()
        end
        self.dx = MOVE_SPEED
        self.animation = self.animations['walking']
        self.direction = 'right'
        self:checkRightCollision()
        self:grabFlag()
      else
        self.state = 'idle'
        self.animation = self.animations['idle']
      end

      if not self.map:collides(self.map:tileAt(self.x, self.y + self.height - 1)) and not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
        self.state = 'jumping'
        self.animation = self.animations['jumping']
      end
    end,
    ['jumping'] = function(dt)
      if love.keyboard.isDown('left') and self.flagGrabbed == false and self.x > 0 then
        self.direction = 'left'
        self.dx = -MOVE_SPEED -20
        self:checkLeftCollision()
      elseif love.keyboard.isDown('right') then
        self.direction = 'right'
        self.dx = MOVE_SPEED + 20
        self:checkRightCollision()
        self:grabFlag()
      elseif self.y > (map.tileheight * (map.mapHeight / 2) + 3) then
          self.fell = true
          self.map:checkHighscore()
          return
      else
        self.dx = 0
      end

      self.dy = self.dy + self.map.gravity
    end,
    ['poledance'] = function(dt)
      self.flagGrabbed = true
      self.dx = 0
      self.x = (self.map.mapWidth * self.map.tilewidth) - (self.map.tilewidth * 6.5)
      self.dy = DROP
    end
  }
end

function Player:update(dt)
  self.behaviors[self.state](dt)
  self.animation:update(dt)
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt

  -- check to see if player is jumping and if so if player is jumping into
  -- a jump block
  if self.dy < 0 then
    if (self.map:tileAt(self.x, self.y).id == JUMP_BLOCK or self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK) or (self.map:tileAt(self.x, self.y).id == JUMP_BLOCK_HIT or self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK_HIT) then
      self.jumpBlockCheck = true
      self.dy = 0

      -- if player jumped into jump block then play sound, increase score
      -- write the score data and change block to a jump block hit
      if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
        self.sounds['coin']:play()
        self.map.score = self.map.score + 1
        self.map:writeData()
        self.map:setTile(math.floor(self.x / self.map.tilewidth) + 1, math.floor(self.y / self.map.tileheight) + 1, JUMP_BLOCK_HIT)
        self.coinUp = true

      -- if player jumped into jump block then play sound, increase score
      -- write the score data and change block to a jump block hit
      elseif self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
        self.sounds['coin']:play()
        self.map.score = self.map.score + 1
        self.map:writeData()
        self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tilewidth) + 1, math.floor(self.y / self.map.tileheight) + 1, JUMP_BLOCK_HIT)
        self.coinUp = true
      else
        self.sounds['hit']:play()
      end
    end

  -- if player is on the way down then check to see if player lands
  -- on brick and set triggers and animation
  elseif self.dy > 0 then
    if self.map:collides(self.map:tileAt(self.x, self.y + self.height - 1)) or self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height - 1)) then
      self.dy = 0
      self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileheight - self.height
      self.jumpBlockCheck = false
      self.touchGround = true
      self.state = 'idle'
      self.animation = self.animations['idle']
    end
  end
end

function Player:checkLeftCollision()
  if self.dx < 0 and self.jumpBlockCheck == false then
    if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
      self.dx = 0
      self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tilewidth
    end
  end
end

function Player:checkRightCollision()
  if self.dx > 0 and self.jumpBlockCheck == false then
    if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
      self.dx = 0
      self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tilewidth - self.width
    end
  end
end

function Player:grabFlag()
    if self.x >= (self.map.mapWidth * self.map.tilewidth) - (self.map.tilewidth * 6.5) then
      self.map:writeData()
      self.state = 'poledance'
  end
end

function Player:render()
  local scaleX

  if self.direction == 'right' then
    scaleX = 1
  else
    scaleX = -1
  end

  love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2), 0, scaleX, 1, self.width / 2, self.height / 2)
end
