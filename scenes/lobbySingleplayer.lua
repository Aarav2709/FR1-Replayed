-- practice lobby.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local mapInfo = require("modules.mapInfo")

local scene = storyboard.newScene()

local mapButtons, arrowButtons
local homeButton
local wallLoader
local onFrame, onKey

local MAPS_PER_WALL = 6
local WALL_COUNT = 6
local SLIDE_TIME = 500
local SEPARATOR_WIDTH = 50
local SLOTS = { { 0.2, 0.2 }, { 0.5, 0.2 }, { 0.8, 0.2 }, { 0.2, 0.56 }, { 0.5, 0.56 }, { 0.8, 0.56 } }

local function wallOffset(wall)
  return -display.contentWidth * wall - SEPARATOR_WIDTH * wall
end

function scene:createScene()
  mapButtons, arrowButtons = {}, {}
  local group = self.view
  local walls = display.newGroup()
  local font = storyboard.gameDataTable.font
  local starting = false
  local nextWallX = 0
  local maps = mapInfo.getAllMapImageNamesForPracticeMode()
  local loadingText

  local function startGame()
    if not starting then
      starting = true
      storyboard.gotoScene("scenes.gamePlay")
      storyboard.purgeScene("scenes.lobbySingleplayer")
    end
  end

  local function selectMap(mapId)
    loadingText.alpha = 1
    storyboard.gameDataTable.mapSelected = mapId
    timer.performWithDelay(100, startGame, 1)
  end

  local function addArrow(direction, wall, wallGroup)
    local image, x = "images/gui/button/nextSceneLeft.png", 15
    if direction == 1 then
      image, x = "images/gui/button/nextSceneRight.png", display.contentWidth - 15
    end
    local target = wall + direction - 1
    arrowButtons[#arrowButtons + 1] = gui.newButton({
      image = image, width = 25, height = 40,
      onRelease = function()
        storyboard.gameDataTable.selectedPracticeWall = target
        transition.to(walls, { time = SLIDE_TIME, x = wallOffset(target) })
      end,
      x = x, y = 123, displayGroup = wallGroup,
    })
  end

  local selectedWall = storyboard.gameDataTable.selectedPracticeWall
  if selectedWall and type(selectedWall) == "number" then
    walls.x = wallOffset(selectedWall)
  else
    walls.x = 0
  end

  local wallsBuilt = 0
  local function buildNextWall()
    wallsBuilt = wallsBuilt + 1
    local wall = wallsBuilt
    if wall > WALL_COUNT then
      return
    end
    local wallGroup = display.newGroup()
    local backgroundIndex = wall == 2 and 1 or wall
    local background = display.newImageRect("images/gui/background/practiceWall" .. backgroundIndex .. ".png", 480, 320)
    background.anchorX, background.anchorY = 0, 0
    background.xScale, background.yScale = display.contentWidth / 480, 1
    wallGroup:insert(background)

    for slot = 1, MAPS_PER_WALL do
      local icon = maps[(wall - 1) * MAPS_PER_WALL + slot]
      local position = SLOTS[(slot - 1) % MAPS_PER_WALL + 1]
      local image = "images/map/" .. icon .. ".png"
      local onRelease = function()
        selectMap(mapInfo.getMapId(icon))
      end
      if mapInfo.isMapCommingSoon(storyboard.gameDataTable.serverVersion, icon) then
        image = "images/map/ComingSoon.png"
        onRelease = function() end
      end
      mapButtons[#mapButtons + 1] = gui.newButton({
        image = image, width = 80, height = 104, onRelease = onRelease,
        x = display.contentWidth * position[1], y = display.contentHeight * position[2],
        displayGroup = wallGroup,
      })
    end

    if wall == 1 then
      addArrow(1, wall, wallGroup)
    elseif wall == WALL_COUNT then
      addArrow(-1, wall, wallGroup)
    else
      addArrow(-1, wall, wallGroup)
      addArrow(1, wall, wallGroup)
    end

    wallGroup.x = nextWallX
    walls:insert(wallGroup)
    if wall ~= WALL_COUNT then
      local separator = display.newImageRect("images/gui/background/wallSeparator" .. wall .. ".png", SEPARATOR_WIDTH, 320)
      separator.anchorX, separator.anchorY = 0, 0
      separator.x = wallGroup.x + wallGroup.width
      walls:insert(separator)
      nextWallX = separator.x + separator.width
    end

    if wall == WALL_COUNT and storyboard.getCurrentSceneName() == "scenes.lobbySingleplayer" then
      for _, button in ipairs(mapButtons) do
        button.addListener()
      end
      for _, button in ipairs(arrowButtons) do
        button.addListener()
      end
    end
  end

  local buildNow = 1
  if selectedWall and type(selectedWall) == "number" then
    buildNow = selectedWall + 1
  end
  for _ = 1, buildNow do
    buildNextWall()
  end
  if WALL_COUNT - buildNow > 0 then
    wallLoader = timer.performWithDelay(50, buildNextWall, WALL_COUNT - buildNow)
  end
  group:insert(walls)

  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lobbySingleplayer")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = group,
  })

  loadingText = display.newText(storyboard.localized.get("LoadingGame"), 0, 0, font, 18 * 2.5)
  loadingText:setFillColor(1, 1, 1, 1)
  loadingText.xScale, loadingText.yScale = 0.5, 0.5
  loadingText.x = display.contentWidth * 0.5
  loadingText.y = display.contentHeight * 0.9
  loadingText.alpha = 0
  group:insert(loadingText)
end

function scene:enterScene()
  local keyReleased, backPressed = false, false

  function onFrame()
    if backPressed then
      backPressed = false
      keyReleased = false
      storyboard.gotoScene("scenes.playMenu")
      storyboard.purgeScene("scenes.lobbySingleplayer")
    end
  end

  function onKey(event)
    if event.phase == "up" and event.keyName == "back" then
      if keyReleased then
        backPressed = true
      end
      return true
    end
    return false
  end

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.lobbySingleplayer" then
      for _, button in ipairs(mapButtons) do
        button.addListener()
      end
      for _, button in ipairs(arrowButtons) do
        button.addListener()
      end
      homeButton.addListener()
      keyReleased = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  if wallLoader then
    timer.cancel(wallLoader)
    wallLoader = nil
  end
  for _, button in ipairs(mapButtons) do
    button.removeListener()
  end
  for _, button in ipairs(arrowButtons) do
    button.removeListener()
  end
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  onFrame, onKey = nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
