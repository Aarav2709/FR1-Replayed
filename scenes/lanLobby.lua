-- lan lobby. players, map choice and start.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local mapInfo = require("modules.mapInfo")
local createSprite = require("modules.createSprite")
local lan = require("modules.lan")

local scene = storyboard.newScene()

local SLOTS = { { 0.45, 0.27, 0.45 }, { 0.77, 0.27, 0.45 }, { 0.45, 0.72, 0.9 }, { 0.77, 0.72, 0.9 } }

local homeButton, startButton, prevButton, nextButton
local slotGroups, noUserImages, nameTexts, avatars = {}, {}, {}, {}
local mapImage, mapText, infoText
local mapIds = {}
local shownMap = -1
local started = false
local alert
local onFrame, onKey

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local isHost = lan.getRole() == "host"
  started = false
  avatars = { {}, {}, {}, {} }
  slotGroups, noUserImages, nameTexts = {}, {}, {}
  shownMap, mapImage = -1, nil

  mapIds = {}
  for _, name in ipairs(mapInfo.getAllMapImageNames(storyboard.gameDataTable.serverVersion)) do
    mapIds[#mapIds + 1] = mapInfo.getMapId(name)
  end

  local background = display.newImageRect("images/gui/background/login.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)
  local lobbyBackground = display.newImageRect("images/gui/background/lobbyCustomPlay.png", 480, 320)
  lobbyBackground.x = display.contentWidth * 0.5
  lobbyBackground.y = display.contentHeight * 0.5
  view:insert(lobbyBackground)

  for i = 1, 4 do
    slotGroups[i] = display.newGroup()
    view:insert(slotGroups[i])
    noUserImages[i] = display.newImageRect("images/gui/lobby/noUser.png", 100, 100)
    slotGroups[i]:insert(noUserImages[i])
    nameTexts[i] = display.newText("", 0, 0, font, storyboard.localized.getFontSize() * 2.5)
    nameTexts[i]:setFillColor(1, 1, 1)
    nameTexts[i].xScale, nameTexts[i].yScale = 0.5, 0.5
    nameTexts[i].anchorX, nameTexts[i].anchorY = 0.5, 0
    nameTexts[i].x = display.contentWidth * SLOTS[i][1]
    nameTexts[i].y = display.contentHeight * SLOTS[i][3]
    view:insert(nameTexts[i])
    slotGroups[i].x = display.contentWidth * SLOTS[i][1]
    slotGroups[i].y = display.contentHeight * SLOTS[i][2]
  end

  mapText = display.newText("", 0, 0, font, 28)
  mapText:setFillColor(1, 1, 1)
  mapText.xScale, mapText.yScale = 0.5, 0.5
  mapText.x, mapText.y = 50, display.contentHeight * 0.5 + 62
  view:insert(mapText)

  local info = isHost and ("Your address " .. (lan.getLocalIP() or "unknown")) or "Waiting for the host"
  infoText = display.newText(info, 0, 0, font, 28)
  infoText:setFillColor(1, 1, 1)
  infoText.xScale, infoText.yScale = 0.5, 0.5
  infoText.x, infoText.y = display.contentWidth * 0.5, 12
  view:insert(infoText)

  local function stepMap(step)
    local current = 1
    for i, id in ipairs(mapIds) do
      if id == lan.getMap() then
        current = i
      end
    end
    current = (current - 1 + step) % #mapIds + 1
    lan.setMap(mapIds[current])
  end

  if isHost then
    prevButton = gui.newButton({
      image = "images/gui/button/left.png", width = 24, height = 24, x = 18, y = display.contentHeight * 0.5,
      onRelease = function() stepMap(-1) end, displayGroup = view,
    })
    nextButton = gui.newButton({
      image = "images/gui/button/right.png", width = 24, height = 24, x = 82, y = display.contentHeight * 0.5,
      onRelease = function() stepMap(1) end, displayGroup = view,
    })
    startButton = gui.newButton({
      image = "images/gui/button/blank.png",
      text = { string = storyboard.localized.get("Start"), size = 25 },
      width = 80, height = 50, x = display.contentWidth - 50, y = display.contentHeight - 30, displayGroup = view,
      onRelease = function() lan.start() end,
    })
    startButton.showButton(false)
  end
  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      lan.leave()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lanLobby")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })
end

function scene:enterScene()
  local view = self.view
  local backKeyEnabled, backPressed = false, false
  local isHost = lan.getRole() == "host"

  local function removeAvatar(slot)
    for _, part in pairs(avatars[slot]) do
      display.remove(part)
    end
    avatars[slot] = {}
  end

  local function showAvatar(slot, avatar)
    removeAvatar(slot)
    noUserImages[slot].alpha = 0
    local parts = avatars[slot]
    parts.spriteBody = createSprite.changeSpriteAvatar(avatar[1], slotGroups[slot], slot)
    parts.spriteHat = createSprite.changeSpriteHat(avatar[2], slotGroups[slot], slot)
    parts.spriteBoots = createSprite.changeSpriteBoots(avatar[4], slotGroups[slot], slot)
    parts.spriteBoots:setFrame(4)
    for _, part in pairs(parts) do
      part.xScale, part.yScale = 0.5, 0.5
    end
    parts.spriteHat.y = -12
  end

  local function showMap(id)
    if id == shownMap then
      return
    end
    shownMap = id
    if mapImage then
      display.remove(mapImage)
      mapImage = nil
    end
    mapImage = display.newImageRect("images/map/" .. mapInfo.getMapIcon(id) .. ".png", 80, 104)
    mapImage.x, mapImage.y = 50, display.contentHeight * 0.5
    view:insert(mapImage)
    mapText.text = mapInfo.getMapName(id)
  end

  local function leave(sceneName)
    storyboard.gotoScene(sceneName)
    storyboard.purgeScene("scenes.lanLobby")
  end

  local closedMessages = {
    full = "The game is full",
    started = "The race already started",
    hostLeft = "The host left",
    lost = "Connection lost",
    timeout = "The host did not answer",
  }

  local function onEvent(event)
    if started then
      return
    end
    if event.type == "lobby" then
      local count = #event.players
      for slot = 1, 4 do
        local player = event.players[slot]
        if player then
          if nameTexts[slot].text ~= player.n then
            nameTexts[slot].text = player.n
            showAvatar(slot, player.a)
          end
        else
          nameTexts[slot].text = ""
          removeAvatar(slot)
          noUserImages[slot].alpha = 1
        end
      end
      showMap(event.map)
      if isHost then
        startButton.showButton(count > 1)
      end
    elseif event.type == "start" then
      started = true
      local names = {}
      for i, player in ipairs(event.players) do
        names[i] = { username = player.n, avatar = player.a }
      end
      storyboard.gameDataTable.playerListNames = names
      storyboard.gameDataTable.mapSelected = event.map
      leave("scenes.gamePlay")
    elseif event.type == "closed" then
      started = true
      alert = native.showAlert("LAN", closedMessages[event.reason] or "Disconnected",
        { storyboard.localized.get("Ok") }, function() leave("scenes.lan") end)
    end
  end

  lan.setHandler(onEvent)
  lan.requestLobby()

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      lan.leave()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lanLobby")
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
    if storyboard.getCurrentSceneName() == "scenes.lanLobby" then
      homeButton.addListener()
      if isHost then
        startButton.addListener()
        prevButton.addListener()
        nextButton.addListener()
      end
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  lan.setHandler(nil)
  if alert then
    native.cancelAlert(alert)
    alert = nil
  end
  if not started then
    createSprite.cleanSuperfluousSprites()
  end
  homeButton.removeListener()
  if startButton then
    startButton.removeListener()
    prevButton.removeListener()
    nextButton.removeListener()
  end
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  avatars = { {}, {}, {}, {} }
  homeButton, startButton, prevButton, nextButton = nil, nil, nil, nil
  mapImage = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
