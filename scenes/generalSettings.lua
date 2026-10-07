-- sound, notifications and language overlay.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local scene = storyboard.newScene()

local panel, closeButton, notificationOffButton
local removeListeners, onFrame, onKey

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local soundOn, soundOff, notificationOn, languageButton
  local SOUND_X, NOTIFICATION_X, LANGUAGE_X = -85, 0, 85
  panel = display.newGroup()

  local dim = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  dim:setFillColor(0, 0, 0, 0.5882352941176471)
  dim.x = display.contentWidth * 0.5
  dim.y = display.contentHeight * 0.5
  view:insert(dim)
  local wall = display.newImageRect("images/gui/background/settingsWall2.png", 282, 103)
  panel:insert(wall)
  panel:insert(display.newText(storyboard.localized.get("GeneralSettings"), 0, -35, font, 22))

  local function toggleSound()
    if storyboard.database.getSound() == 1 then
      storyboard.database.setSound(0)
      soundOff.alpha = 1
      soundOn.alpha = 0
    else
      storyboard.database.setSound(1)
      soundOn.alpha = 1
      soundOff.alpha = 0
    end
  end

  local function toggleNotifications()
    if storyboard.database.getNotification() == 1 then
      storyboard.database.setNotification(0)
      notificationOffButton.alpha = 1
      notificationOn.alpha = 0
    else
      storyboard.database.setNotification(1)
      notificationOn.alpha = 1
      notificationOffButton.alpha = 0
    end
  end

  local function newToggle(image, x, width, height, onRelease)
    return gui.newButton({
      image = image, width = width or 50, height = height or 50, onRelease = onRelease, x = x, y = 5,
      displayGroup = panel,
    })
  end
  soundOn = newToggle("images/gui/button/mute.png", SOUND_X, nil, nil, toggleSound)
  soundOff = newToggle("images/gui/button/unmute.png", SOUND_X, nil, nil, toggleSound)
  notificationOn = newToggle("images/gui/button/notification.png", NOTIFICATION_X,
    storyboard.gameDataTable.backButton[1], storyboard.gameDataTable.backButton[2], toggleNotifications)
  notificationOffButton = newToggle("images/gui/button/notificationOff.png", NOTIFICATION_X,
    storyboard.gameDataTable.backButton[1], storyboard.gameDataTable.backButton[2], toggleNotifications)

  languageButton = gui.newButton({
    image = "images/gui/button/blank.png",
    text = {
      string = storyboard.localized.get("Phone"), string2 = storyboard.localized.get("Language"), size = 16,
      languageSizes = { fr = 20, es = 19, ja = 17, ko = 18 },
    },
    width = 75, height = 50, x = LANGUAGE_X, y = 5, displayGroup = panel,
    onRelease = function()
      if storyboard.database.usingPhoneLanguage() then
        storyboard.database.usePhoneLanguage(false)
        languageButton.getText().text = storyboard.localized.get("English")
      else
        storyboard.database.usePhoneLanguage(true)
        languageButton.getText().text = storyboard.localized.get("Phone")
        languageButton.getText().text2.text = storyboard.localized.get("Language")
      end
    end,
  })

  if storyboard.database.getSound() == 1 then
    soundOff.alpha = 0
  else
    soundOn.alpha = 0
  end
  if storyboard.database.usingPhoneLanguage() then
    languageButton.getText().text = storyboard.localized.get("Phone")
    languageButton.getText().text2.text = storyboard.localized.get("Language")
  else
    languageButton.getText().text = storyboard.localized.get("English")
  end
  if storyboard.localized.language ~= "en" then
    notificationOffButton.alpha = 0
    notificationOn.alpha = 0
  elseif storyboard.database.getNotification() == 1 then
    notificationOffButton.alpha = 0
  else
    notificationOn.alpha = 0
  end

  local buttons = { soundOff, notificationOn, notificationOffButton, soundOn, languageButton }
  function panel.addButtonListeners()
    for _, button in ipairs(buttons) do
      button.addListener()
    end
  end
  function panel.removeButtonListeners()
    for _, button in ipairs(buttons) do
      button.removeListener()
    end
  end

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
    panel.removeButtonListeners()
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
    if notificationOffButton then
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
  closeButton, panel, notificationOffButton = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
