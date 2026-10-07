-- first launch. pick a username.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local loadingAnimation = require("modules.loadingAnimation")

local scene = storyboard.newScene()

local TOP = 60
local MAX_USERNAME = 15

local usernameField
local playButton, suggestionButton
local background
local errorText, suggestionLabel, suggestionText
local loader
local busy = false
local busyTimer
local onFrame, onKey, onResponse

local function startTutorial()
  storyboard.config.tutorial = true
  storyboard.gotoScene("scenes.loadingScene")
  storyboard.purgeScene("scenes.registerScene")
end

function scene:createScene()
  local group = self.view
  local font = storyboard.gameDataTable.font
  local fontSize = storyboard.localized.getFontSize()
  local WHITE = { 1, 1, 1, 1 }
  busy = false

  loader = loadingAnimation.newLoadingAnimation()
  loader.displayGroup.x = display.contentWidth * 0.85
  loader.displayGroup.y = display.contentHeight * 0.2

  local function onRegister()
    if busy then
      return
    end
    native.setKeyboardFocus(nil)
    loader.startLoader()
    local name = usernameField.text and string.gsub(usernameField.text, "%s", "") or ""
    errorText.text = ""
    if string.len(name) < 1 then
      onResponse({ m = "a", e = storyboard.localized.get("EnterUsername") })
      return
    elseif string.len(name) < 3 then
      onResponse({ m = "a", e = storyboard.localized.get("UsernameTooShort") })
      return
    elseif string.gsub(name, "[^%a%d]", "") ~= name then
      onResponse({ m = "a", e = storyboard.localized.get("ValidCharacterMessage") })
      return
    end
    busy = true
    if busyTimer then
      timer.cancel(busyTimer)
    end
    busyTimer = timer.performWithDelay(5000, function() busy = false end, 1)
    storyboard.comm.createUser(name)
  end

  background = display.newImageRect("images/gui/background/login.png", 480, 320)
  function background.tap()
    native.setKeyboardFocus(nil)
  end
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  group:insert(background)

  local title = display.newText(storyboard.localized.get("Register"), 0, 0, font, fontSize * 3)
  title:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  title.xScale, title.yScale = 0.5, 0.5
  title.x = display.contentWidth * 0.5
  title.y = TOP
  group:insert(title)

  local label = display.newText(storyboard.localized.get("Username"), 0, 0, font, fontSize * 2)
  label:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  label.xScale, label.yScale = 0.5, 0.5
  label.anchorX, label.anchorY = 1, 0.5
  label.x = display.contentWidth * 0.28
  label.y = TOP + 40
  group:insert(label)

  usernameField = native.newTextField(display.contentWidth * 0.29, TOP + 40, 200, isAndroid and 40 or 30)
  usernameField.anchorX, usernameField.anchorY = 0, 0.5
  usernameField.x = display.contentWidth * 0.29
  usernameField.y = TOP + 40
  group:insert(usernameField)

  suggestionLabel = display.newText("Suggestion", 0, 0, font, fontSize * 2)
  suggestionLabel:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  suggestionLabel.xScale, suggestionLabel.yScale = 0.5, 0.5
  suggestionLabel.anchorX, suggestionLabel.anchorY = 1, 0.5
  suggestionLabel.x = display.contentWidth * 0.28
  suggestionLabel.y = TOP + 100
  suggestionLabel.isVisible = false
  group:insert(suggestionLabel)

  errorText = display.newText("", 0, 0, font, fontSize * 2)
  errorText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  errorText.xScale, errorText.yScale = 0.5, 0.5
  errorText.x = display.contentWidth * 0.5
  errorText.y = TOP + 65
  group:insert(errorText)

  function scene.showSuggestion(name)
    if name and name ~= usernameField.text then
      if suggestionText then
        display.remove(suggestionText)
      end
      suggestionLabel.isVisible = true
      suggestionButton.isVisible = true
      suggestionText = display.newText(name, 0, 0, font, fontSize * 2)
      suggestionText:setFillColor(0, 0, 0)
      suggestionText.xScale, suggestionText.yScale = 0.5, 0.5
      suggestionText.x = display.contentWidth * 0.5
      suggestionText.y = TOP + 100
      group:insert(suggestionText)
    end
  end

  playButton = gui.newButton({
    image = "images/gui/button/play.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = onRegister, x = display.contentWidth - 50, y = storyboard.gameDataTable.backButton[4], displayGroup = group,
  })
  suggestionButton = gui.newButton({
    image = "images/gui/button/blankLong.png", width = 200, height = 40,
    onRelease = function()
      usernameField.text = suggestionText.text
      errorText.text = ""
      suggestionLabel.isVisible = false
      suggestionButton.isVisible = false
      suggestionText.isVisible = false
    end,
    x = display.contentWidth * 0.5, y = TOP + 100, displayGroup = group,
  })
  suggestionButton.isVisible = false
  group:insert(loader.displayGroup)
end

local function onUserInput(event)
  if string.len(usernameField.text) > MAX_USERNAME then
    usernameField.text = usernameField.text:sub(1, MAX_USERNAME)
  end
  if event.phase == "submitted" then
    native.setKeyboardFocus(nil)
  end
end

function scene:enterScene()
  local keyReleased, backPressed = false, false
  storyboard.playerInfo = nil
  storyboard.database.resetWithoutReceipts()
  storyboard.database.setAvatarData({ 1, 1, 1, 1 })

  function onFrame()
    if backPressed then
      backPressed = false
      keyReleased = false
      local previous = storyboard.getPrevious()
      if previous then
        native.setKeyboardFocus(nil)
        storyboard.gotoScene(previous)
        storyboard.purgeScene("scenes.registerScene")
      end
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
    if storyboard.getCurrentSceneName() == "scenes.registerScene" then
      background:addEventListener("tap", background)
      suggestionButton.addListener()
      playButton.addListener()
      usernameField:addEventListener("userInput", onUserInput)
      keyReleased = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)

  function onResponse(packet)
    if busyTimer then
      timer.cancel(busyTimer)
      busyTimer = nil
    end
    loader.stopLoader()
    if packet == nil then
      errorText.text = storyboard.localized.get("ErrorServerBusy")
    else
      if packet.e then
        if packet.e == "This username is already taken." then
          scene.showSuggestion(packet.s)
        end
        errorText.text = storyboard.localized.get(packet.e)
      end
      if packet.a == 1 then
        errorText.text = storyboard.localized.get("StartToBegin")
        startTutorial()
      end
    end
    busy = false
  end
  storyboard.comm.setCallback(onResponse)
end

function scene:exitScene()
  if loader then
    loader.stopLoader()
  end
  if busyTimer then
    timer.cancel(busyTimer)
    busyTimer = nil
  end
  storyboard.comm.setCallback(function() end)
  background:removeEventListener("tap", background)
  suggestionButton.removeListener()
  playButton.removeListener()
  usernameField:removeEventListener("userInput", onUserInput)
  usernameField.isVisible = false
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  background, usernameField = nil, nil
  playButton, suggestionButton = nil, nil
  suggestionText = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
