-- map scenery.

local storyboard = require("modules.storyboard")
local mapInfo = require("modules.mapInfo")

local mapBackgrounds = {}

local BG = "images/map/background/"

local function layer(image, width, height, positions)
  return { image = BG .. image, width = width, height = height, positions = positions }
end

local FOREST_DEFAULT = { { 0, 8 }, { 980, 7 }, { 1960, 6 }, { 2940, 6 }, { 3920, 7 }, { 4900, 8 } }
local ROW9 = { { 0, 9 }, { 980, 9 }, { 1960, 9 }, { 2940, 8 }, { 3920, 9 }, { 4900, 9 } }
local ROW9B = { { 0, 9 }, { 980, 8 }, { 1960, 9 }, { 2940, 9 }, { 3920, 9 }, { 4900, 9 } }
local SHORE5 = { { -45, 8, 10 }, { 935, 8, 10 }, { 1915, 8, 10 }, { 2895, 8, 10 }, { 3875, 8, 10 } }

local function forest(positions) return { layer("forest/bkg_mountains.png", 1050, 375, positions) } end
local function beach(positions) return { layer("beach/bkg_mountains.png", 1050, 375, positions) } end
local function fall(positions) return { layer("fall/bkg_mountains.png", 1050, 375, positions) } end
local function snow(positions) return { layer("snow/bkg_mountains.png", 1050, 375, positions) } end

local function candy(list)
  local layers = {}
  for i, m in ipairs(list) do
    layers[i] = layer("candy/" .. m[1] .. ".png", m[4], m[5], { { m[2], m[3] } })
  end
  return layers
end

local BACKGROUNDS = {
  [1] = { mountains = forest(FOREST_DEFAULT), startY = 357, sky = "forest/bkg_sundown.png" },
  [2] = { mountains = forest(ROW9), startY = 507, sky = "forest/bkg_sunup.png" },
  [3] = { mountains = forest(FOREST_DEFAULT), startY = 507, sky = "forest/bkg_day.png" },
  [4] = { mountains = forest({ { -490, 9 }, { 1080, 5 }, { 2940, 5 }, { 3920, 6 }, { 4900, 7 } }),
          startY = 257, sky = "forest/bkg_day.png" },
  [5] = { mountains = forest(FOREST_DEFAULT), startY = 257, sky = "forest/bkg_sundown.png" },
  [6] = { mountains = forest(ROW9B), startY = 257, sky = "forest/bkg_sunup.png" },
  [7] = {
    mountains = candy({
      { "bakgrunn2", -150, 19, 818, 320 }, { "bakgrunn2", 400, 17, 818, 320 },
      { "bakgrunn1", 1200, 18, 818, 320 }, { "bakgrunn1", 1700, 15.5, 818, 320 },
      { "bakgrunn2", 2060, 16, 818, 320 }, { "bakgrunn1", 3500, 15.5, 818, 320 },
      { "bakgrunn2", 4000, 17, 818, 320 }, { "bakgrunn1", 4800, 17, 818, 320 },
    }),
    clouds = { 2, 25, 0.1 }, startY = 357, sky = "forest/bkg_day.png",
  },
  [8] = {
    mountains = candy({
      { "bakgrunn1", -100, 9, 1090, 426 }, { "bakgrunn2", 980, 9, 1050, 375 },
      { "bakgrunn1", 1960, 8, 1050, 375 }, { "bakgrunn2", 2940, 9, 1050, 375 },
    }),
    clouds = { 2, 15, 0.1 }, startY = 357, sky = "forest/bkg_sundown.png",
  },
  [9] = {
    mountains = candy({
      { "bakgrunn1", 90, 9, 1090, 426 }, { "bakgrunn2", 980, 8, 1050, 375 },
      { "bakgrunn1", 1960, 9, 1050, 375 }, { "bakgrunn2", 2940, 8, 1050, 375 },
      { "bakgrunn1", 3920, 8, 1050, 375 }, { "bakgrunn2", 4900, 9, 1050, 375 },
    }),
    clouds = { 2, 15, 0.1 }, startY = 507, sky = "forest/bkg_day.png",
  },
  [10] = {
    mountains = candy({ { "bakgrunn1", 290, 7, 1050, 375 }, { "bakgrunn2", 980, 8, 1050, 375 } }),
    clouds = { 2, 15, 0.1 }, startY = 807, sky = "forest/bkg_sunup.png",
  },
  [11] = {
    mountains = candy({
      { "bakgrunn1", -100, 16, 1090, 426 }, { "bakgrunn2", 980, 16, 1050, 375 },
      { "bakgrunn1", 1960, 15, 1050, 375 }, { "bakgrunn2", 2940, 16, 1050, 375 },
    }),
    clouds = { 2, 15, 0.1 }, startY = 357, sky = "forest/bkg_sundown.png",
  },
  [12] = {
    mountains = candy({
      { "bakgrunn1", -100, 22, 1090, 426 }, { "bakgrunn2", 980, 22, 1050, 375 },
      { "bakgrunn1", 1960, 21, 1050, 375 }, { "bakgrunn2", 2940, 22, 1050, 375 },
    }),
    clouds = { 2, 15, 0.1 }, startY = 357, sky = "forest/bkg_sundown.png",
  },
  [13] = { mountains = forest(ROW9B), startY = 507, sky = "forest/bkg_sunup.png" },
  [14] = { mountains = forest(ROW9B), startY = 357, sky = "forest/bkg_sunup.png" },
  [15] = { mountains = forest(ROW9B), startY = 507, sky = "forest/bkg_sunup.png" },
  [16] = { mountains = forest({ { 0, 7 }, { 980, 7 }, { 1960, 7 }, { 2940, 7 }, { 3920, 7 }, { 4900, 7 } }),
           startY = 657, sky = "forest/bkg_day.png" },
  [17] = { mountains = forest(FOREST_DEFAULT), startY = 357, sky = "forest/bkg_day.png" },
  [18] = { mountains = forest(FOREST_DEFAULT), startY = 357, sky = "forest/bkg_day.png" },
  [19] = { mountains = forest(FOREST_DEFAULT), startY = 407, sky = "forest/bkg_day.png" },
  [20] = { mountains = beach({ { -400, 8 }, { 600, 8 }, { 1600, 8 }, { 2600, 8 } }),
           clouds = { 1, 15, 0.05 }, startY = 407, sky = "beach/bkg_sundown.png" },
  [21] = { mountains = beach({ { -45, 15, 10 }, { 935, 15, 10 }, { 1915, 15, 10 }, { 2895, 15, 10 } }),
           startY = 957, sky = "beach/bkg_day.png" },
  [22] = { mountains = beach({ { -300, 8, 10 }, { 700, 8, 10 }, { 1700, 8, 10 }, { 2700, 8, 10 },
                               { 3700, 8, 10 }, { 4700, 8, 10 }, { 5700, 8, 10 } }),
           startY = 457, sky = "beach/bkg_sundown.png" },
  [23] = { mountains = beach({ { -45, 8, 10 }, { 935, 8, 10 }, { 1915, 8, 10 }, { 2895, 8, 10 } }),
           startY = 357, sky = "beach/bkg_sunup.png" },
  [24] = { mountains = beach({ { -45, 13, 10 }, { 935, 13, 10 }, { 1915, 13, 10 }, { 2895, 13, 10 }, { 3875, 13, 10 } }),
           startY = 157, sky = "beach/bkg_sunup.png" },
  [25] = { mountains = beach(SHORE5), startY = 357, sky = "beach/bkg_day.png" },
  [26] = { mountains = fall(SHORE5), startY = 357, sky = "fall/bkg_sunup.png" },
  [27] = { mountains = fall(SHORE5), startY = 357, sky = "fall/bkg_day.png" },
  [28] = { mountains = fall(SHORE5), startY = 357, sky = "fall/bkg_day.png" },
  [29] = { mountains = fall(SHORE5), startY = 357, sky = "fall/bkg_sunup.png" },
  [30] = { mountains = fall(ROW9), startY = 507, sky = "fall/bkg_sunup.png" },
  [31] = { mountains = fall(ROW9), startY = 457, sky = "beach/bkg_sundown.png" },
  [32] = { mountains = snow(ROW9), startY = 357, sky = "snow/bkg_sundown.png" },
  [33] = { mountains = snow(ROW9), startY = 507, sky = "snow/bkg_sunup.png" },
  [34] = { mountains = snow(ROW9), startY = 507, sky = "snow/bkg_day.png" },
  [35] = { mountains = snow(ROW9), startY = 507, sky = "forest/bkg_sunup.png" },
  [36] = { mountains = snow(ROW9), startY = 357, sky = "forest/bkg_day.png" },
  [37] = { mountains = snow(ROW9B), startY = 257, sky = "snow/bkg_sunup.png" },
  [38] = { mountains = forest(ROW9B), startY = 257, sky = "forest/bkg_sunup.png" },
}

local DEFAULT_CLOUDS = { 1, 15, 0.1 }
local CLOUD_IMAGES = { BG .. "forest/cloud", BG .. "candy/cloud" }

local mapId
local cellWidth, cellHeight, columns, rows
local goalX
local startY = 250
local lastCloudX = 0

local function addImage(path, x, y, width, height, group)
  local image = display.newImageRect(path, width, height)
  image.anchorX = 0
  image.anchorY = 1
  image.x = x
  image.y = y
  group:insert(image)
  return image
end

local function addCloud(cloudType, rowsFromBottom, group)
  local y = (rows - rowsFromBottom) * cellHeight + math.random(-80, 80)
  local x = lastCloudX + 20 + math.random(0, cellWidth * 2)
  lastCloudX = x
  addImage(CLOUD_IMAGES[cloudType] .. math.random(6) .. ".png", x, y, 200, 100, group)
end

function mapBackgrounds.setVariables(id, cellW, cellH, cols, rowCount)
  mapId = id
  cellWidth, cellHeight = cellW, cellH
  columns, rows = cols, rowCount
end

function mapBackgrounds.generateBackgrounds(gameGroup, nearGroup, mountainGroup, cloudGroup, skyGroup)
  lastCloudX = 0
  local config = BACKGROUNDS[mapId]
  if not config then
    return
  end
  for _, mountains in ipairs(config.mountains) do
    for _, pos in ipairs(mountains.positions) do
      local y = (rows - pos[2]) * cellHeight + (pos[3] or 0)
      addImage(mountains.image, pos[1], y, mountains.width, mountains.height, mountainGroup)
    end
  end
  local clouds = config.clouds or DEFAULT_CLOUDS
  for _ = 1, columns * clouds[3] do
    addCloud(clouds[1], clouds[2], cloudGroup)
  end
  goalX = cellWidth * (columns - 14) + 35
  startY = config.startY
  addImage(BG .. config.sky, display.screenOriginX, 360, math.max(480, display.actualContentWidth), 360, skyGroup)
end

function mapBackgrounds.insertMapName(group, playerX)
  local text = display.newText(mapInfo.getMapName(mapId), 0, 0, storyboard.gameDataTable.font, 80)
  text:setFillColor(1, 1, 1)
  text.xScale = 0.5
  text.yScale = 0.5
  text.x = playerX + 90
  text.y = startY + 75
  group:insert(text)
end

function mapBackgrounds.getGoalX()
  return goalX
end

function mapBackgrounds.getStartYPos()
  return startY
end

return mapBackgrounds
