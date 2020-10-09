Map = Class{}

-- Setting names for each quad
TILE_BRICK = 1
TILE_EMPTY = 4

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

BUSH_LEFT = 2
BUSH_RIGHT = 3

MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

FLAG_POLE_TOP = 8
FLAG_POLE_MIDDLE = 12
FLAG_POLE_BASE = 16

FLAG_ONE = 13
FLAG_TWO = 14
FLAG_THREE = 15

local SCROLL_SPEED = 62




function Map:init()
  -- Setting gravity
  self.gravity = 40

  -- Setting the spritesheet file path
  self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')

  -- Defining the size of each quadrant or tile
  self.tilewidth = 16
  self.tileheight = 16

  -- Defining size of map based off of tile numbers not pixel
  self.mapWidth = 100
  self.mapHeight = 28

  -- Creating a tile table
  self.tiles = {}

  -- Creating different font sizes for information display
  smallFont = love.graphics.newFont('fonts/font.ttf', 8)
  welcomeFont = love.graphics.newFont('fonts/font.ttf', 28)
  scoreFont = love.graphics.newFont('fonts/font.ttf', 12)

  -- Setting each Class and needed parameters to a variable
  self.coin = Coin(self, state, x, y, dy, MOVE_UP)
  self.player = Player(self, fell, coinUp)
  self.flag = Flag(self, state, grounded)
  self.baddy = Baddy(self, x, y, direction)

  -- Setting baddy render trigger
  self.renderBaddy = false

  -- Creating the camera
  self.camX = 0
  self.camY = -3

  -- Setting the initial values of game data
  self.initScore = readScore()
  self.initLevel = readLevel()
  self.initHighscore = readHighscore()

  -- Converting the string created by reading the data text
  -- to a int
  self.score = tonumber(self.initScore)
  self.level = tonumber(self.initLevel)
  self.highscore = tonumber(self.initHighscore)

  -- Checking for any previous data, if none
  -- is found then set the data to inital values of 0
  if self.highscore == nil then
    self.highscore = 0
    self:saveScore()
  end

  if self.score == nil and self.level == nil then
    self.score = 0
    self.level = 0
    self:writeData()
  elseif self.score == nil then
    self.score = 0
    self:writeData()
  elseif self.level == nil then
    self.level = 0
    self:writeData()
  end

  -- Create the Quadrants needed for using a spritesheet
  self.tileSprites = generateQuads(self.spritesheet, self.tilewidth, self.tileheight)

  -- Create the audio and assign source path
  -- original song credits (not 8bit version)
      -- Songwriters: David Draiman / Dan Donegan / Steve Kmak / Mike Wengren
      -- Performed by Distrubed
  self.music = love.audio.newSource('sounds/disturbed.wav',  'static')

  -- Converting the size of map from tiles to pixels
  self.mapWidthPixels = self.mapWidth * self.tilewidth
  self.mapHeightPixels = self.mapHeight * self.tileheight

  -- Increment levels
  self.level = self.level + 1

  -- Check to see if this is first start or a restart and
  --set the game state accordingly
  if self.level == 1 then
    self.gameState = 'startGame'
  else
    self.gameState = 'play'
  end

  -- first, fill map with empty tiles
  for y = 1, self.mapHeight do
      for x = 1, self.mapWidth do
          -- support for multiple sheets per tile; storing tiles as tables
          self:setTile(x, y, TILE_EMPTY)
      end
  end

  -- begin generating the terrain using vertical scan lines
  -- make sure there is a tile brick at vertical scan line 10
  for y = (self.mapHeight / 2), self.mapHeight do
    self:setTile(10, y, TILE_BRICK)
  end

  -- increment scan line
  self.nextX = 1

  -- Loop through the map and create it using tiles
  while self.nextX < self.mapWidth and self.nextX <= self.mapWidth - 20 do

    self:makeClouds()

    -- 5% chance to generate a mushroom
    if math.random(20) == 1 and self.nextX ~= 10 then
      self:createMushrooms()

    -- 10% chance to generate bush, being sure to generate away from edge
    elseif math.random(10) == 1 and self.nextX < self.mapWidth - 3 then
      self:createBush()

    -- 5% chance to not generate anything, creating a gap
    elseif math.random(20) ~= 1 and self.nextX ~= 10 and self.level < 5 then
      self:createAnything()

    -- 10% chance to not generate anything, creating more gaps after level 5
    elseif math.random(10) ~=1 and self.next ~= 10 and self.level >= 5 then
      self:createAnything()

    -- 33% chance to generate small pyramid
    elseif math.random(1,3) == 2 and self.nextX > 10 then
      self:smallPyramid()

    -- increment X so we skip two scanlines, creating a 2-tile gap
    else
      if self.nextX ~= 10 then
        self.nextX = self.nextX + 2
      end
    end
  end

  -- create the big pyramid at the end of each level
  self:bigPyramid()

  -- create the background music
  self.music:setLooping(true)
  self.music:setVolume(0.45)


end

-- functions to handle how each map object is created
function Map:makeClouds()

  -- 5% chance to generate a cloud
  -- make sure we're 2 tiles from edge at least
  if self.nextX < self.mapWidth - 2 then
    if math.random(20) == 1 then

      -- choose a random vertical spot above where blocks/pipes generate
      local cloudStart = math.random(self.mapHeight / 2 - 6)

      -- create clouds, putting each side needed together
      self:setTile(self.nextX, cloudStart, CLOUD_LEFT)
      self:setTile(self.nextX + 1, cloudStart, CLOUD_RIGHT)

    end
  end
end

function Map:createMushrooms()

  -- randomly decide tall big each mushroom will be in terms of tiles
  self.shroom = math.random(1, 3)

  -- draw the correct tiles and number of tiles based on the number create above
  if self.shroom == 1 or 2 then
    self:setTile(self.nextX, self.mapHeight / 2 - self.shroom, MUSHROOM_TOP)
  end
  if self.shroom == 2 or 3 then
    self:setTile(self.nextX, self.mapHeight / 2 - (self.shroom - 1), MUSHROOM_BOTTOM)
  end
  if self.shroom == 3 then
    self:setTile(self.nextX, self.mapHeight / 2 - (self.shroom - 2), MUSHROOM_BOTTOM)
  end

  -- creates column of tiles going to bottom of map
  for y = self.mapHeight / 2, self.mapHeight do
    self:setTile(self.nextX, y, TILE_BRICK)
  end

  -- next vertical scan line
  self.nextX = self.nextX + 1
end

function Map:createBush()
  local bushLevel = self.mapHeight / 2 - 1

  -- place bush component and then column of bricks
  self:setTile(self.nextX, bushLevel, BUSH_LEFT)
  for y = self.mapHeight / 2, self.mapHeight do
    self:setTile(self.nextX, y, TILE_BRICK)
  end
  self.nextX = self.nextX + 1

  self:setTile(self.nextX, bushLevel, BUSH_RIGHT)
  for y = self.mapHeight / 2, self.mapHeight do
    self:setTile(self.nextX, y, TILE_BRICK)
  end


  self.nextX = self.nextX + 1
end

function Map:createAnything()

  -- creates column of tiles going to bottom of map
  for y = self.mapHeight / 2, self.mapHeight do
    self:setTile(self.nextX, y, TILE_BRICK)
  end

  -- 10% chance to create a block for Mario to hit
  if math.random(10) == 1 then
    self:setTile(self.nextX, self.mapHeight / 2 - math.random(3, 6), JUMP_BLOCK)
  end

  -- next vertical scan line
  self.nextX = self.nextX + 1
end

function Map:smallPyramid()

  -- randomly decide if small pyramid will face left or right
  if math.random(1,2) == 1 then
    local step = 1

    -- if small pyramid faces left
    while step <= 3 do
      for y = self.mapHeight / 2 - step, self.mapHeight do
        self:setTile(self.nextX, y, TILE_BRICK)
      end
      step = step + 1
      self.nextX = self.nextX + 1
    end
  else
    local step = 3

    -- if small pyramid faces right
    while step >= 1 do
      for y = self.mapHeight / 2 - step, self.mapHeight do
        self:setTile(self.nextX, y, TILE_BRICK)
      end
      step = step - 1
      self.nextX = self.nextX + 1
    end
  end

  -- add the needed bottom blocks under pyramid
  for y = self.mapHeight / 2, self.mapHeight do
      self:setTile(self.nextX, y, TILE_BRICK)
  end
  self.nextX = self.nextX + 1
end

function Map:bigPyramid()
  local z = 1
  local a = 11
  local b = 10

  -- set the size of tiles needed to create ending scene and loop through
  -- them creating the big pyramid and flag pole
  while self.nextX > self.mapWidth - 20 and self.nextX < self.mapWidth do
    if self.nextX >= self.mapWidth - 20 and self.nextX < self.mapWidth - 9 then
      for y = (self.mapHeight / 2) - z, self.mapHeight do
        self:setTile(self.nextX, y, TILE_BRICK)
      end
    elseif self.nextX == self.mapWidth - 5 then
      for y = (self.mapHeight / 2) - a, (self.mapHeight / 2) - a do
        self:setTile(self.nextX, y, FLAG_POLE_TOP)
      end
      for y = (self.mapHeight / 2) - b, (self.mapHeight / 2) - 2 do
        self:setTile(self.nextX, y, FLAG_POLE_MIDDLE)
      end
      for y = (self.mapHeight / 2), self.mapHeight do
        self:setTile(self.nextX, y, TILE_BRICK)
      end
      y = (self.mapHeight / 2) - 1
      self:setTile(self.nextX, y, FLAG_POLE_BASE)
    else
       for y = self.mapHeight / 2, self.mapHeight do
        self:setTile(self.nextX, y, TILE_BRICK)
      end
    end
    self.nextX = self.nextX + 1
    z = z + 1
  end
end

-- functions to set and get information about tiles at requested location
function Map:setTile(x, y, id)
  self.tiles[(y - 1) * self.mapWidth + x] = id
end

function Map:getTile(x, y)
  return self.tiles[(y - 1) * self.mapWidth + x]
end

-- Update the map
function Map:update(dt)
  -- set the camera up to follow player
  if self.gameState == 'play' then
    self.camX = math.max(0,
    math.min(self.player.x - VIRTUAL_WIDTH / 2,
    math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

    -- update information about each object
    self.player:update(dt)
    self.flag:update(dt)
    self.coin:update(dt)
    self.baddy:update(dt)

  -- create game over data to set stage for next replay
  elseif self.gameState == 'gameOver' then
    self.score = 0
    self.level = 0
    self.music:stop()
    self:writeData()

  -- restart map for a new level, keeping all data from previous level intact
  elseif self.gameState == 'restartWithData' then
    self.music:stop()
    self:init()
  end

  -- check to see if player fell off map and end game if so
  if self.player.fell == true then
    self.gameState = 'gameOver'

  -- check to see if flag scene is over and go to next level scene if so
  elseif self.flag.state == 'flagDown' and self.flag.grounded == true then
    self.music:stop()
    self.gameState = 'nextLevel'
  end

  -- check if the coin needs to be hidden (could probably use a active/unactive
  -- type functiont to do this same function)
  if self.coin.disappear == true then
    self.coin.state = 'disappear'
    self.coin.animation = self.coin.animations['disappear']
    self.coin:reset()
    self.player.coinUp = false
  end

  -- check for button presses and proceed to the next scene accordingly
  if ((love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return')) and self.gameState == 'startGame') then
    self.gameState = 'play'
  elseif ((love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return')) and self.gameState == 'gameOver') then

    -- reset the end game trigger in baddy
    self.baddy.endGame = false
    self.gameState = 'restart'
  elseif ((love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return')) and self.gameState == 'nextLevel') then
    self:writeData()
    self.gameState = 'restartWithData'
  end

  -- if baddy end game trigger is tripped then end the game
  if self.baddy.endGame == true then
    self.gameState = 'gameOver'
  end

end

function Map:render()
  for y = 1, self.mapHeight do
    for x = 1, self.mapWidth do
      love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)],
        (x - 1) * self.tilewidth, (y - 1) * self.tileheight)
    end
  end

  -- only render the player and baddy if the game has started
  if self.gameState == 'play' then
    self.music:play()
    self.player:render()
    self.baddy:render()

  -- write the data of the finished level
  elseif self.gameState == 'restartWithData' then
    self:writeData()
    self:init()
  end

  -- render coin if player hits a jump block
  if self.player.coinUp == true then
    self.coin.state = 'spin'
    self.coin:render()
  end

  self.flag:render()
  self:display()
  --self:debug()
end

function Map:tileAt(x, y)
  return {
    x = math.floor(x / self.tilewidth) + 1,
    y = math.floor(y / self.tileheight) + 1,
    id = self:getTile(math.floor(x / self.tilewidth) + 1, math.floor(y / self.tileheight) + 1)
  }
end

-- create a table of collidables
function Map:collides(tile)
  local collidables = {
    TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT, MUSHROOM_TOP, MUSHROOM_BOTTOM,
  }

  -- loop through the collidables and return if there was a collision or not
  for _, v in ipairs(collidables) do
    if tile.id == v then
      return true
    end
  end
  return false
end

-- set the information on the screen depending on the game state
function Map:startScreen()
  love.graphics.setFont(welcomeFont)
  love.graphics.printf("Welcome to running ZED!", 0, VIRTUAL_HEIGHT / 2 - 40, VIRTUAL_WIDTH, 'center')
  love.graphics.setFont(scoreFont)
  love.graphics.printf("Press Enter to start game", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
end

function Map:gameInfo()
  love.graphics.setFont(scoreFont)
  love.graphics.printf("Score: " .. tostring(self.score), self.camX, 10, VIRTUAL_WIDTH, 'center')
  love.graphics.printf("High Score: " .. tostring(self.highscore), self.camX, 10, VIRTUAL_WIDTH, 'left')
  love.graphics.printf("Level: " .. tostring(self.level), self.camX, 10 , VIRTUAL_WIDTH, 'right')
end

function Map:dead()
  love.graphics.setFont(welcomeFont)
  love.graphics.printf("GAME OVER", self.camX, (VIRTUAL_HEIGHT / 2) - 40, VIRTUAL_WIDTH, 'center')
  love.graphics.setFont(scoreFont)
  love.graphics.printf("Press Enter to try again", self.camX, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
end

function Map:playNext()
  love.graphics.setFont(welcomeFont)
  love.graphics.printf("Level " .. tostring(self.level + 1), self.camX, VIRTUAL_HEIGHT / 2 - 40, VIRTUAL_WIDTH, 'center')
  love.graphics.setFont(scoreFont)
  love.graphics.printf("Press Enter to start game", self.camX, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
end

function Map:display()
  if self.gameState == 'startGame' then
    self:startScreen()
  elseif self.gameState == 'play' then
    self:gameInfo()
  elseif self.gameState == 'gameOver' then
    self:dead()
  elseif self.gameState == 'nextLevel' then
    self:playNext()
  end
end

-- showing desired debug info on screen
function Map:debug()
  love.graphics.setFont(scoreFont)
  love.graphics.printf("baddyX: " .. tostring(self.baddy.x), self.camX, 30, VIRTUAL_WIDTH, 'center')
  love.graphics.printf("baddyDirection : " .. tostring(self.baddy.direction), self.camX, 40, VIRTUAL_WIDTH, 'center')
  love.graphics.printf("playerX :" .. tostring(self.player.x), self.camX, 50, VIRTUAL_WIDTH, 'center')
end

-- write new highscore
function Map:checkHighscore()
  if self.score >= self.highscore then
    self.highscore = self.score
    self:saveScore()
    --self.test = self.test + 1
  end
end

-- write score and level data
function Map:writeData()

  -- if no score file then create one
  if not love.filesystem.getInfo('data/score', info) then
    local scoreFile = io.open("data/score", "w")
    scoreFile:write("0")
    scoreFile:close()
  end

  local scoreFile = io.open("data/score", "w")
  scoreFile:write(self.score)
  scoreFile:close()

  -- if no level file then create one
  if not love.filesystem.getInfo('data/level', info) then
    local levelFile = io.open("data/level", "w")
    levelFile:write("0")
    levelFile:close()
  end

  local levelFile = io.open("data/level", "w")
  levelFile:write(self.level)
  levelFile:close()
end

-- write highscore
function Map:saveScore()

  -- if no highscore file then create one
  if not love.filesystem.getInfo('data/highscore', info) then
    local highscoreFile = io.open("data/highscore", "w")
    highscoreFile:write("0")
    highscoreFile:close()
  end

  local highscoreFile = io.open("data/highscore", "w")
  highscoreFile:write(self.highscore)
  highscoreFile:close()
end
