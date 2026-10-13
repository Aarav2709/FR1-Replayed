-- pc settings overlay. fullscreen, window size and race keys.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local pcSettings = require("modules.pcSettings")

local scene = storyboard.newScene()

local panel, closeButton
local rowButtons = {}
local removeListeners, onFrame, onKey
local ignoreBackUntil = 0

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  panel = display.newGroup()
  rowButtons = {}

  local dim = display.newRect(0, 0, display.actualContentWidth, display.actualContentHeight)
  dim:setFillColor(0, 0, 0, 0.5882352941176471)
  dim.x = display.contentWidth * 0.5
  dim.y = display.contentHeight * 0.5
  view:insert(dim)
  local wall = display.newImageRect("images/gui/background/settingsWall1.png", 310, 220)
  wall.y = -10
  panel:insert(wall)
  panel:insert(display.newText("PC", 0, -88, font, 22))

  local function fullscreenLabel()
    return "Fullscreen: " .. (pcSettings.isFullscreen() and "On" or "Off")
  end
  local function windowLabel()
    return "Window: " .. pcSettings.sizeLabel()
  end
  local function keyLabel(action)
    return (action == "jump" and "Jump: " or "Power up: ") .. pcSettings.keyLabel(action)
  end

  local function newRow(y, label, onRelease)
    local button = gui.newButton({
      image = "images/gui/button/blankLong.png", text = { string = label, size = 16 },
      width = 220, height = 34, x = 0, y = y, displayGroup = panel, onRelease = onRelease,
    })
    rowButtons[#rowButtons + 1] = button
    return button
  end

  local fullscreenButton, windowButton, jumpButton, powerButton
  fullscreenButton = newRow(-52, fullscreenLabel(), function()
    pcSettings.toggleFullscreen()
    timer.performWithDelay(100, function()
      if fullscreenButton and fullscreenButton.text then
        fullscreenButton.text.text = fullscreenLabel()
      end
    end, 1)
  end)
  windowButton = newRow(-12, windowLabel(), function()
    pcSettings.cycleSize()
    windowButton.text.text = windowLabel()
  end)

  local function captureKey(action, button)
    button.text.text = "Press a key"
    storyboard.capturingKey = function(keyName)
      if keyName == "escape" or keyName == "back" then
        ignoreBackUntil = system.getTimer() + 500
      end
      pcSettings.setKey(action, keyName)
      if button.text then
        button.text.text = keyLabel(action)
      end
    end
  end
  jumpButton = newRow(28, keyLabel("jump"), function() captureKey("jump", jumpButton) end)
  powerButton = newRow(68, keyLabel("power"), function() captureKey("power", powerButton) end)

  closeButton = gui.newButton({
    image = "images/gui/button/exit.png", width = 20, height = 19,
    onRelease = function() storyboard.hideOverlay() end,
    x = 135, y = -100, displayGroup = panel,
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

  function removeListeners()
    storyboard.capturingKey = nil
    for _, button in ipairs(rowButtons) do
      button.removeListener()
    end
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
      if backKeyEnabled and system.getTimer() > ignoreBackUntil and not storyboard.capturingKey then
        backPressed = true
      end
      return true
    end
    return false
  end

  timer.performWithDelay(200, function()
    if closeButton then
      backKeyEnabled = true
      closeButton.addListener()
      for _, button in ipairs(rowButtons) do
        button.addListener()
      end
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
  closeButton, panel = nil, nil
  rowButtons = {}
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
