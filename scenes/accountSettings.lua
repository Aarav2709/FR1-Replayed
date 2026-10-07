-- change username overlay.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local population = require("modules.offline.population")
local serverData = require("modules.offline.serverData")

local scene = storyboard.newScene()

local MAX_USERNAME = 15
local panel, closeButton, saveButton
local removeListeners, onFrame, onKey

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local keyboardShown = false
  panel = display.newGroup()

  local dim = display.newRect(0, 0, display.actualContentWidth, display.actualContentHeight)
  dim:setFillColor(0, 0, 0, 0.5882352941176471)
  dim.x = display.contentWidth * 0.5
  dim.y = display.contentHeight * 0.5
  view:insert(dim)
  local wall = display.newImageRect("images/gui/background/settingsWall1.png", 310, 220)
  wall.y = -10

  local title = display.newText(storyboard.localized.get("ChangeUsername"), 0, -80, font, 22)
  local currentLabel = display.newText("", 0, -45, font, 14)
  local usernameField = native.newTextField(0, 1000, 180, 26)
  usernameField.y = -10
  usernameField.isVisible = false
  usernameField.hasPlaceholder = false
  local messageText = display.newText("", 0, 25, font, 14)
  panel:insert(wall)
  for _, object in ipairs({ title, currentLabel, usernameField, messageText }) do
    panel:insert(object)
  end

  local function showCurrentName()
    local info = storyboard.database.getPlayerInformation()
    currentLabel.text = storyboard.localized.get("Username") .. ": " .. (info and info.username or "")
  end

  local function moveForKeyboard(y)
    if not isAndroid then
      panel.y = y
    end
  end

  local function onUserInput(event)
    if event.phase == "began" then
      keyboardShown = true
      moveForKeyboard(display.contentHeight * 0.5 - 30)
    elseif event.phase == "ended" or event.phase == "submitted" then
      keyboardShown = false
      moveForKeyboard(display.contentHeight * 0.5)
      native.setKeyboardFocus(nil)
    elseif event.phase == "editing" then
      if string.len(usernameField.text) > MAX_USERNAME then
        usernameField.text = usernameField.text:sub(1, MAX_USERNAME)
      end
    end
  end

  local function save()
    native.setKeyboardFocus(nil)
    local name = string.gsub(usernameField.text or "", "%s", "")
    local info = storyboard.database.getPlayerInformation()
    local problem
    if string.len(name) < 1 then
      problem = storyboard.localized.get("EnterUsername")
    elseif string.len(name) < 3 then
      problem = storyboard.localized.get("UsernameTooShort")
    elseif string.gsub(name, "[^%a%d]", "") ~= name then
      problem = storyboard.localized.get("ValidCharacterMessage")
    elseif population.getByName(name) then
      problem = storyboard.localized.get("This username is already taken.")
    end
    if not problem and name ~= info.username then
      local refused = serverData.renameAccount(name)
      if refused then
        problem = storyboard.localized.get(refused)
      else
        storyboard.database.setPlayerInformation(name, info.playerId, info.token)
        storyboard.playerInfo = storyboard.database.getPlayerInformation()
      end
    end
    if problem then
      messageText:setFillColor(1, 0.45, 0.45)
      messageText.text = problem
    else
      messageText:setFillColor(0.6, 1, 0.6)
      messageText.text = storyboard.localized.get("UsernameChanged")
      usernameField.text = ""
      showCurrentName()
    end
  end

  saveButton = gui.newButton({
    image = "images/gui/button/blank.png",
    text = { string = storyboard.localized.get("Save"), size = 25 },
    width = 80, height = 50, onRelease = save, x = 0, y = 70, displayGroup = panel,
  })
  closeButton = gui.newButton({
    image = "images/gui/button/exit.png", width = 20, height = 19,
    onRelease = function() storyboard.hideOverlay() end,
    x = 135, y = -100, displayGroup = panel,
  })

  function panel.addButtonListeners()
    saveButton.addListener()
    usernameField:addEventListener("userInput", onUserInput)
  end
  function panel.removeButtonListeners()
    saveButton.removeListener()
    usernameField:removeEventListener("userInput", onUserInput)
  end

  local function onPanelTouch(event)
    if event.phase == "ended" then
      native.setKeyboardFocus(nil)
    end
    return true
  end
  local function onDimTouch(event)
    if event.phase == "ended" then
      if keyboardShown then
        native.setKeyboardFocus(nil)
      else
        storyboard.hideOverlay()
      end
    end
    return true
  end

  function removeListeners()
    native.setKeyboardFocus(nil)
    usernameField.isVisible = false
    panel.removeButtonListeners()
    dim:removeEventListener("touch", onDimTouch)
    wall:removeEventListener("touch", onPanelTouch)
  end

  dim:addEventListener("touch", onDimTouch)
  wall:addEventListener("touch", onPanelTouch)
  view:insert(panel)
  panel.x = display.contentWidth * 0.5
  panel.y = display.contentHeight * 0.5
  showCurrentName()
  usernameField.isVisible = true
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
    if saveButton then
      backKeyEnabled = true
      closeButton.addListener()
      panel.addButtonListeners()
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
  closeButton, panel, saveButton = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
