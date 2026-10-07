-- map loading.

local mapElementsController = require("modules.mapElementsController")
local mapBackgrounds = require("modules.mapBackgrounds")
local maps = require("data.maps")

local map = {}

local CELL_WIDTH = 80
local CELL_HEIGHT = 50
local EMPTY = 1

local goalX
local mapId
local columns, rows
local elements = {}
local foregroundElements = {}

local function createElements(grid)
  elements = {}
  foregroundElements = {}
  for row = 1, #grid do
    for col = 1, #grid[1] do
      local cell = grid[row][col]
      local x, y = CELL_WIDTH * col, CELL_HEIGHT * row
      if cell ~= EMPTY then
        if type(cell) == "number" then
          elements[#elements + 1] = mapElementsController.createMapElement(x, y, cell, mapId)
        else
          for layer = 1, #cell do
            local elementIndex = cell[layer]
            if elementIndex ~= EMPTY then
              local element = mapElementsController.createMapElement(x, y, elementIndex, mapId)
              if layer == 3 then
                foregroundElements[#foregroundElements + 1] = element
              else
                elements[#elements + 1] = element
              end
            end
          end
        end
      end
    end
  end
end

function map.getLength()
  return CELL_WIDTH * columns
end

function map.isInGoal(x)
  return x > goalX
end

function map.init(id, gameGroup, foregroundGroup, nearGroup, mountainGroup, cloudGroup, skyGroup)
  local grid = maps[id]
  mapId = id
  columns = #grid[1]
  rows = #grid
  createElements(grid)
  mapBackgrounds.setVariables(id, CELL_WIDTH, CELL_HEIGHT, columns, rows)
  mapBackgrounds.generateBackgrounds(gameGroup, nearGroup, mountainGroup, cloudGroup, skyGroup)
  goalX = mapBackgrounds.getGoalX()
  for i = 1, #elements do
    gameGroup:insert(elements[i])
  end
  for i = 1, #foregroundElements do
    foregroundGroup:insert(foregroundElements[i])
  end
  return mapBackgrounds.getStartYPos()
end

function map.setMapName(group, playerX)
  mapBackgrounds.insertMapName(group, playerX)
end

function map.clean()
  for i = 1, #elements do
    if elements[i] then
      display.remove(elements[i])
      elements[i] = nil
    end
  end
end

return map
