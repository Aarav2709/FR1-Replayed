-- map elements.

local physics = require("physics")
local storyboard = require("modules.storyboard")
local mapInfo = require("modules.mapInfo")
local elementNames = require("data.mapElementNames")
local shapeData = require("data.mapPhysics")

local mapElementsController = {}

local fixtures = {}
for name, list in pairs(shapeData) do
  local withFilter = {}
  for i, fixture in ipairs(list) do
    local f = {}
    for k, v in pairs(fixture) do
      f[k] = v
    end
    f.filter = obstacleFilter
    withFilter[i] = f
  end
  fixtures[name] = withFilter
end

local VARIANTS = {
  ["1Av"] = 4, ["1Bv"] = 4, ["R1Av"] = 4, ["R1Bv"] = 4,
  ["0Av"] = 4, ["R0Av"] = 4, ["0Cv"] = 4, ["R0Cv"] = 4,
  ["0Bv"] = 6, ["R0Bv"] = 6,
  ["0Dv"] = 3, ["R0Dv"] = 3, ["0Ev"] = 3, ["R0Ev"] = 3,
  ["0Fv"] = 2, ["R0Fv"] = 2,
  stottev = 4,
}

local TREES = { tre1 = true, tre2 = true, tre3 = true, tre4 = true }
local BOUNCE = { gele1 = true, gele2 = true, gele3 = true, Jump1 = true }
local BOOST = { is1 = true, is2 = true, is3 = true }
local SLIDE = {
  ["Slide1-1"] = true, ["Slide1-2"] = true, ["Slide1-3"] = true, ["Slide1-4"] = true,
  ["RSlide1-1"] = true, ["RSlide1-2"] = true, ["RSlide1-3"] = true, ["RSlide1-4"] = true,
}
local SLOW = { slow1 = true, slow2 = true, slow3 = true }

local CRATE_SHAPE = { 13, -13, 13, 13, -13, 13, -13, -13 }

local function createPowerUpCrate(x, y)
  local crate = display.newImageRect("images/map/element/forest/crate.png", 80, 50)
  crate.x, crate.y = x, y
  local positions = storyboard.powerUpPositions
  positions[#positions + 1] = { x, y, 0, 0, 0, 0 }
  physics.addBody(crate, { shape = CRATE_SHAPE, isSensor = true, filter = obstacleFilter })
  crate.bodyType = "static"
  crate.powerUp = true
  return crate
end

function mapElementsController.createMapElement(x, y, elementIndex, mapId)
  local name = elementNames[elementIndex]
  if name == "powerUp" then
    return createPowerUpCrate(x, y)
  end
  if VARIANTS[name] then
    name = name .. math.random(VARIANTS[name])
  end

  local folder = "images/map/element/" .. mapInfo.getMapElementTheme(mapId) .. "/"
  local element
  if TREES[name] then
    element = display.newImageRect(folder .. name .. ".png", 160, 100)
    element.anchorX = 0
    element.anchorY = 0
  elseif name:sub(1, 1) == "R" then
    element = display.newImageRect(folder .. name:sub(2) .. ".png", 80, 50)
    element.xScale = -1
  else
    element = display.newImageRect(folder .. name .. ".png", 80, 50)
  end
  if element == nil then
    element = display.newImageRect(folder .. "1Av1.png", 80, 50)
  end

  if BOUNCE[name] then
    element.bounce = true
  end
  if BOOST[name] then
    element.boost = true
  end
  if SLIDE[name] then
    element.boost2 = true
  end
  if SLOW[name] then
    element.slow = true
  end

  element.x, element.y = x, y
  physics.addBody(element, unpack(fixtures[name]))
  element.bodyType = "static"
  element.mapElement = true
  return element
end

return mapElementsController
