Coin = Class{}

local MOVE_UP = -40

function Coin:init(map)
  self.width = 16
  self.height = 16

  self.tiles = {}
  self.map = map
  self.player = Player(map, x, y, coinUp)

  self.x = 0
  self.y = 0
  self.initSelfY = 0
  self.disappear = false

  -- set the path to the needed spritesheet and create needed quads
  self.texture = love.graphics.newImage('graphics/starCoin.png')
  self.frames = generateQuads(self.texture, 16, 16)

  -- set initial velocity
  self.dy = 0

  -- set initial state
  self.state = 'disappear'

  -- define animations and frames for coin
  self.animations = {
    ['spin'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[2], self.frames[3], self.frames[4], self.frames[5], self.frames[6], self.frames[7], self.frames[8], self.frames[9], self.frames[10], self.frames[10], self.frames[11]
      },
      interval = .01
    },
    ['disappear'] = Animation {
      texture = self.texture,
      frames = {
        self.frames[1]
      },
      interval = 1
    },
  }

  -- set initial animation
  self.animation = self.animations['disappear']

  -- define the different coin states
  self.behaviors = {
    ['spin'] = function(dt)
      self.dy = self.dy + MOVE_UP
      self.animation = self.animations['spin']
      if self.y <= self.initSelfY - (self.height * 4) then
        self.dy = 0
        self.dx = 0
        self.disappear = true
      end
    end,
    ['disappear'] = function(dt)
      self.dy = 0
      self.animation = self.animations['disappear']
      self.disappear = false
      self.x = self.player.x
      self.y = self.player.y
      self.initSelfY = self.y
    end
  }
end

function Coin:update(dt)
  self.player:update(dt)
  self.animation:update(dt)
  self.behaviors[self.state](dt)
  self.y = self.y + self.dy * dt
end

function Coin:render()

    -- decrease the scale of the coin
    local CoinScale = .75

    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2), 0, CoinScale, CoinScale, self.width / 2, self.height / 2)
end

-- function to reset coin after each use.  Allows the reuse of the coin.
function Coin:reset()
  self.x = 0
  self.y = 0
  self.dy = 0
  self.disappear = false
end
