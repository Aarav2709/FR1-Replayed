-- help overlay.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local scene = storyboard.newScene()

local panel, closeButton, tutorialButton
local removeListeners, onFrame, onKey

function scene:createScene()
  local view = self.view
  panel = display.newGroup()

  local dim = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  dim:setFillColor(0, 0, 0, 0.5882352941176471)
  dim.x = display.contentWidth * 0.5
  dim.y = display.contentHeight * 0.5
  view:insert(dim)
  local wall = display.newImageRect("images/gui/background/settingsWall2.png", 282, 103)
  panel:insert(wall)

  tutorialButton = gui.newButton({
    image = "images/gui/button/blank.png",
    text = { string = storyboard.localized.get("Tutorial"), size = 16, languageSizes = { fr = 20, es = 19, ja = 17, ko = 18 } },
    width = 75, height = 50, x = 0, y = 0, displayGroup = panel,
    onRelease = function()
      storyboard.gotoScene("scenes.tutorial")
      storyboard.purgeScene("scenes.settings")
    end,
  })

  local function onPanelTouch()
    return true
  end
  local function onDimTouch(event)
    if event.phase == "ended" then
      storyboard.hideOverlay()
    end
    return true
  end

  closeButton = gui.newButton({
    image = "images/gui/button/exit.png", width = 20, height = 19,
    onRelease = function() storyboard.hideOverlay() end,
    x = 125, y = -35, displayGroup = panel,
  })

  function removeListeners()
    tutorialButton.removeListener()
    dim:removeEventListener("touch", onDimTouch)
    wall:removeEventListener("touch", onPanelTouch)
  end

  dim:addEventListener("touch", onDimTouch)
  wall:addEventListener("touch", onPanelTouch)
  view:insert(panel)
  panel.x = display.contentWidth * 0.5
  panel.y = display.contentHeight * 0.5
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.hideOverlay()
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
    if tutorialButton then
      backKeyEnabled = true
      closeButton.addListener()
      tutorialButton.addListener()
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  removeListeners()
  closeButton.removeListener()
  closeButton, panel, tutorialButton = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
