map = Map

-- create function to slice sprite sheets into quads based on
-- given tile height and widths
function generateQuads(atlas, tilewidth, tileheight)
  local sheetWidth = atlas:getWidth() / tilewidth
  local sheetHeight = atlas:getHeight() / tileheight

  local sheetCounter = 1
  local quads = {}

  --NOTE: must do some fancy footwork due to lua starting index at 1 and pixels at 0
  for y = 0, sheetHeight - 1 do
    for x = 0, sheetWidth - 1 do
      quads[sheetCounter] = love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, tileheight, atlas:getDimensions())
      sheetCounter = sheetCounter + 1
    end
  end
  return quads
end

-- function to read score data
function readScore(score)
  if not love.filesystem.getInfo('data/score', info) then
    local scoreFile = io.open("data/score", "w")
    scoreFile:write("0")
    scoreFile:close()
  end

  local scoreFile = io.open("data/score", "r")
  score = scoreFile:read()
  scoreFile:close()

  return score
end

-- function to read level data
function readLevel(level)
  if not love.filesystem.getInfo('data/level', info) then
    local levelFile = io.open("data/level", "w")
    levelFile:write("0")
    levelFile:close()
  end

  local levelFile = io.open("data/level", "r")
  level = levelFile:read()
  levelFile:close()

  return level
end

-- function to read highscore data
function readHighscore(highscore)
  if not love.filesystem.getInfo('data/highscore', info) then
    local highscoreFile = io.open("data/highscore", "w")
    highscoreFile:write("0")
    highscoreFile:close()
  end

  local highscoreFile = io.open("data/highscore", "r")
  highscore = highscoreFile:read()
  highscoreFile:close()

  return highscore
end
