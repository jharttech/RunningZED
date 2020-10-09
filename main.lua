WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

Class = require 'class'
push = require 'push'

require 'utility'
require 'Player'
require 'Flag'
require 'Map'
require 'Animation'
require 'Coin'
require 'Baddy'



function love.load()

  math.randomseed(os.time())

  map = Map()


  love.graphics.setDefaultFilter('nearest', 'nearest') --keep pixels, does not smooth pixels causing blur

  love.window.setTitle('Running ZED')

  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = true,
    vsync = true
  })

  love.keyboard.keysPressed = {}
  map:init()
end

-- create a was pressed function because lua does not have a native one
function love.keyboard.wasPressed(key)
  return love.keyboard.keysPressed[key]
end

-- ability to resize screen
function love.resize(w, h)
  push:resize(w, h)
end

function love.update(dt)
  map:update(dt)

  love.keyboard.keysPressed = {}
  if map.gameState == 'restart' then
    map:init()
  end

end

-- write data and exit game if escape key is pressed
function love.keypressed(key)
  if key == 'escape' then
    map.score = 0
    map.level = 0
    map:writeData()
    love.event.quit()
  end

  love.keyboard.keysPressed[key] = true
end

function love.draw()
  push:apply('start')

  love.graphics.clear(108/255, 140/255, 255/255, 255/255)
  --love.graphics.print("Hello, world") -- sanity check


  love.graphics.translate(math.floor(-map.camX + 0.5), math.floor( -map.camY + 0.5))

  map:render()
  push:apply('end')
end
