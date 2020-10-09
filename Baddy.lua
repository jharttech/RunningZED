Baddy = Class{}

local MOVE_SPEED = 50

function Baddy:init(map)
  self.width = 24
  self.height = 20

  self.map = map
  self.player = Player(map, x, y, width, height)

  -- set initial value of game over trigger
  self.endGame = false

  -- set random number for baddy's x value
  self.randomSpot = math.random(15,79)

  self.y = map.tileheight * ((map.mapHeight / 2) - 1) - self.height

  -- make sure the random x is not inside of a brick or on top of a gap
  while not self.map:tileAt(self.randomSpot, self.y).id ~= TILE_BRICK and not self.map:tileAt(self.randomSpot, self.y + 1).id == TILE_BRICK do

    -- while the random x is in a tile or on top of a gap grab a new random x
    self.randomSpot = math.random(15,79)
  end

  -- set the random x once an empty location is found
  self.x = self.map.tilewidth * self.randomSpot

  -- randomly decide which way the baddy will initially face
  self.whichWay = math.random(1,2)
  if self.whichWay == 1 then
    self.direction = 'right'
  elseif self.whichWay == 2 then
    self.direction = 'left'
  end

  -- set initial velocity
  self.dx = 0

  -- set path to needed spritesheet and create needed quads
  self.texture = love.graphics.newImage('graphics/baddy/blueBaddy.png')
  self.frames = generateQuads(self.texture, 24, 20)

  -- set initial state
  self.state = 'walking'

  -- define needed animations for baddy
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
        self.frames[4], self.frames[5], self.frames[6], self.frames[7], self.frames[8], self.frames[9], self.frames[10], self.frames[11], self.frames[12]
      },
      interval = .15
    },
  }

  -- set initial animation
  self.animation = self.animations['walking']

  -- set inital state
  self.behaviors = {
    ['idle'] = function(dt)
      self.dx = 0
    end,
    ['walking'] = function(dt)
      if self.direction == 'right' then
        self.dx = MOVE_SPEED
      elseif self.direction == 'left' then
        self.dx = -MOVE_SPEED
      end
    end
  }
end

function Baddy:update(dt)
  self.behaviors[self.state](dt)
  self.animation:update(dt)
  self.x = self.x + self.dx * dt
  self.player:update(dt)
  self:checkLeftCollision()
  self:checkRightCollision()
  self:turnAround()
  self:playerCollisionLeft()
  self:playerCollisionRight()
end

function Baddy:checkLeftCollision()
  if self.dx < 0 and self.direction == 'left' then
    if self.map:collides(self.map:tileAt(self.x -1, self.y)) or self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
      self.dx = 0
      self.direction = 'right'
      self.state = 'walking'
    end
  end
end

function Baddy:checkRightCollision()
  if self.dx > 0 and self.direction == 'right' then
    if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
      self.dx = 0
      self.direction = 'left'
      self.state = 'walking'
    end
  end
end

-- function to handle the baddy walking on map and turning around at
-- gaps, bricks, or mushrooms
function Baddy:turnAround()
  if self.y < 0 and self.direction == 'left' then
    self.direction = 'right'
  end
  if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and self.direction == 'left' then
    self.direction = 'right'
  elseif not self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height)) and self.direction == 'right' then
    self.direction = 'left'
  end
end

-- check for collision with player
function Baddy:playerCollisionLeft()
  if self.x + 3 <= self.player.x + (self.player.width / 2) and self.x + 3 >= self.player.x and self.y <= self.player.y
   then
    self.dx = 0
    self.endGame = true
  end
end

-- check for collision with player
function Baddy:playerCollisionRight()
  if self.x + self.width - 6 >= self.player.x and self.x + self.width <= self.player.x + self.player.width - 6 and self.y <= self.player.y then
    self.dx = 0
    self.endGame = true
  end
end

function Baddy:render()
  local baddyScaleX

  if self.direction == 'right' then
    baddyScaleX = 1
  elseif self.direction == 'left' then
    baddyScaleX = -1
  end

  love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2), 0, baddyScaleX, 1, self.width / 2, self.height / 2)
end
