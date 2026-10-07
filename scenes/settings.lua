-- settings and credits.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local scene = storyboard.newScene()

local homeButton
local settingsButtons
local onFrame, onKey

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local FONT_SIZE, LARGE_SIZE = 20, 22
  local WHITE = { 1, 1, 1, 1 }
  settingsButtons = require("modules.settingsModule").create()

  local background = display.newImageRect("images/gui/background/login.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)

  local function addCentered(text, size, y)
    local label = display.newText(text, 0, 0, font, size * 2)
    label:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    label.xScale, label.yScale = 0.5, 0.5
    label.x = display.contentWidth * 0.74
    label.y = y
    view:insert(label)
  end
  addCentered(storyboard.localized.get("Credits"), 21, 32)
  addCentered("Aarav Gupta", 18, 78)
  addCentered("aarav2709.github.io", 13, 108)

  local function addText(text, size, y)
    local label = display.newText(text, 0, 0, font, size)
    label:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    label.xScale, label.yScale = 0.5, 0.5
    label.x = display.contentWidth * 0.28
    label.y = y
    view:insert(label)
    return label
  end
  local usernameLabel = addText(storyboard.localized.get("Username"), FONT_SIZE * 2, 16)
  local username = addText(storyboard.playerInfo.username, LARGE_SIZE * 2.6, usernameLabel.y + 36)
  local gameName = addText("Fun Run 1: Replayed", FONT_SIZE * 2, username.y + 70)
  addText("v1.0.0", FONT_SIZE * 2, gameName.y + 30)

  local footer = display.newImageRect("images/gui/background/settings.png", 480, 120)
  footer.anchorX, footer.anchorY = 0.5, 1
  footer.x = display.contentWidth * 0.5
  footer.y = display.contentHeight
  view:insert(footer)

  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.settings")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })
  view:insert(settingsButtons)
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.settings")
    end
  end

  function onKey(event)
    if event.phase == "up" and event.keyName == "back" then
      if backKeyEnabled then
        backPressed = true
      end
      return true
    end
    return false
  end

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.settings" then
      settingsButtons.addButtonListeners()
      homeButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  settingsButtons.removeButtonListeners()
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  homeButton = nil
  settingsButtons.clean()
  settingsButtons = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
