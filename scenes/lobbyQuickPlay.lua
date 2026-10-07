-- quick play lobby with map voting.

local storyboard = require("modules.storyboard")
local adaptiveUI = require("modules.adaptiveUI")
local gui = require("modules.gui")
local createSprite = require("modules.createSprite")
local mapInfo = require("modules.mapInfo")

local scene = storyboard.newScene()

local SLOTS = { { 0.45, 0.28 }, { 0.77, 0.28 }, { 0.45, 0.75 }, { 0.77, 0.75 } }

local homeButton
local voteTitle, waitingText, searchingText
local voteCountTexts = {}
local nameTexts = {}
local noUserImages = {}
local slotGroups = {}
local quickPlayBackground
local gameStarting = false
local showLobby, onFrame, onKey, cleanUp

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local FONT_SIZE = 18
  local NAME_SIZE = FONT_SIZE * 2.5
  local WHITE = { 1, 1, 1, 1 }
  local BROWN = { 0.1450980392156863, 0.08235294117647059, 0.06274509803921569, 1 }
  local searching = true
  gameStarting = false

  local background = display.newImageRect("images/gui/background/login.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)
  quickPlayBackground = adaptiveUI.newSidebarBackground("images/gui/background/quickPlay.png")
  quickPlayBackground.alpha = 0
  view:insert(quickPlayBackground)

  voteTitle = display.newText(storyboard.localized.get("Vote"), 0, 0, font, 60)
  voteTitle:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  voteTitle.xScale, voteTitle.yScale = 0.5, 0.5
  voteTitle.alpha = 0
  voteTitle.x = 53
  voteTitle.y = display.contentHeight * 0.05
  view:insert(voteTitle)

  for i = 1, 4 do
    slotGroups[i] = display.newGroup()
    view:insert(slotGroups[i])
  end

  searchingText = display.newText(storyboard.localized.get("SearchingForGame"), 0, 0, font, NAME_SIZE * 1.2)
  searchingText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  searchingText.xScale, searchingText.yScale = 0.5, 0.5
  searchingText.x = display.contentWidth * 0.5
  searchingText.y = display.contentHeight * 0.5
  view:insert(searchingText)

  for i = 1, 4 do
    noUserImages[i] = display.newImageRect("images/gui/lobby/noUser.png", 100, 100)
    noUserImages[i].alpha = 0
    slotGroups[i]:insert(noUserImages[i])

    nameTexts[i] = display.newText(storyboard.localized.get("Searching"), 0, 0, font, NAME_SIZE)
    nameTexts[i]:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    nameTexts[i].xScale, nameTexts[i].yScale = 0.5, 0.5
    nameTexts[i].anchorX, nameTexts[i].anchorY = 0.5, 0
    nameTexts[i].x = display.contentWidth * SLOTS[i][1]
    nameTexts[i].y = display.contentHeight * (i <= 2 and 0.43 or 0.9)
    nameTexts[i].alpha = 0
    view:insert(nameTexts[i])

    slotGroups[i].x = display.contentWidth * SLOTS[i][1]
    slotGroups[i].y = display.contentHeight * SLOTS[i][2]
  end

  for i, y in ipairs({ 77, 190 }) do
    voteCountTexts[i] = display.newText("0", 0, 0, font, FONT_SIZE * 3)
    voteCountTexts[i]:setFillColor(BROWN[1], BROWN[2], BROWN[3], BROWN[4])
    voteCountTexts[i].xScale, voteCountTexts[i].yScale = 0.5, 0.5
    voteCountTexts[i].anchorX, voteCountTexts[i].anchorY = 0, 1
    voteCountTexts[i].x = 20
    voteCountTexts[i].y = y
    voteCountTexts[i].alpha = 0
    view:insert(voteCountTexts[i])
  end

  waitingText = display.newText(storyboard.localized.get("WaitingForPlayers"), 0, 0, font, FONT_SIZE * 3)
  waitingText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  waitingText.xScale, waitingText.yScale = 0.5, 0.5
  waitingText.x = display.contentWidth * 0.61
  waitingText.y = 14
  waitingText.alpha = 0
  view:insert(waitingText)

  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lobbyQuickPlay")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })
  homeButton.alpha = 0

  function showLobby()
    if searching then
      searching = false
      searchingText.alpha = 0
      quickPlayBackground.alpha = 1
      voteTitle.alpha = 1
      for i = 1, 4 do
        noUserImages[i].alpha = 1
        nameTexts[i].alpha = 1
      end
      voteCountTexts[1].alpha = 1
      voteCountTexts[2].alpha = 1
      waitingText.alpha = 1
      homeButton.alpha = 1
    end
  end
end

function scene:enterScene()
  local view = self.view
  local maps = { 0, 0 }
  local votes = { 0, 0, 0, 0 }
  local avatars = { {}, {}, {}, {} }
  local mapButtons = {}
  local mapButtonsShown = false
  local backKeyEnabled, backPressed = false, false
  local buttonSound = storyboard.gameDataTable.sounds.buttonSound

  local function removeAvatar(slot)
    for _, part in pairs(avatars[slot]) do
      display.remove(part)
    end
    avatars[slot] = {}
  end

  local function showAvatar(slot, avatar, present)
    removeAvatar(slot)
    if present then
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
    else
      noUserImages[slot].alpha = 1
    end
  end

  local function updateVoteCounts()
    local first, second = 0, 0
    for i = 1, #votes do
      if votes[i] == maps[1] then
        first = first + 1
      elseif votes[i] == maps[2] then
        second = second + 1
      end
    end
    voteCountTexts[1].text = first
    voteCountTexts[2].text = second
    view:insert(voteCountTexts[1])
    view:insert(voteCountTexts[2])
  end

  local function vote(choice)
    storyboard.tcpClient.sendPacketLobby({ m = "e", v = maps[choice] })
    if storyboard.database.getSound() == 1 then
      audio.play(buttonSound)
    end
  end

  local function showMapButtons()
    if mapButtonsShown then
      return
    end
    mapButtonsShown = true
    for i, y in ipairs({ 92, 205 }) do
      local button = display.newImageRect("images/map/" .. mapInfo.getMapIcon(maps[i]) .. ".png", 80, 104)
      button.tap = function() vote(i) end
      button.x, button.y = 50, y
      view:insert(button)
      button:addEventListener("tap", button)
      mapButtons[i] = button
    end
  end

  local function onLobbyPacket(packet)
    if packet.t then
      if packet.t == 99 then
        waitingText.text = storyboard.localized.get("WaitingForPlayers")
      else
        waitingText.text = storyboard.localized.get("GameStarting") .. packet.t
      end
    end
    if packet.mI then
      gameStarting = true
      if packet.mI == maps[1] then
        storyboard.gameDataTable.mapSelected = maps[1]
      else
        storyboard.gameDataTable.mapSelected = maps[2]
      end
      storyboard.gotoScene("scenes.gamePlay")
      storyboard.purgeScene("scenes.lobbyQuickPlay")
    elseif packet.players and not gameStarting then
      showLobby()
      local count = #packet.players
      maps = packet.maps
      storyboard.gameDataTable.playerListNames = {}
      showMapButtons()
      for slot = 1, 4 do
        local name, avatar, present = "searching", {}, false
        if slot <= count then
          name = packet.players[slot].n
          avatar = packet.players[slot].a
          storyboard.gameDataTable.playerListNames[slot] = { username = name, avatar = avatar }
          votes[slot] = packet.players[slot].v
          present = true
        else
          votes[slot] = 0
        end
        if nameTexts[slot].text ~= name then
          nameTexts[slot].text = name
          showAvatar(slot, avatar, present)
        end
      end
      updateVoteCounts()
    end
  end

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.playMenu")
      storyboard.purgeScene("scenes.lobbyQuickPlay")
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

  local connectInfo = {
    username = storyboard.playerInfo.username,
    playerId = storyboard.playerInfo.playerId,
    avatar = storyboard.database.getAvatarData(),
    version = storyboard.gameDataTable.version,
    requestType = "a",
  }
  storyboard.comm.setCallback(function(packet)
    if packet.m == "a" then
      if packet.a then
        storyboard.tcpClient.setGameServerAddress(packet.a)
        storyboard.tcpClient.startTCPClient(connectInfo, onLobbyPacket)
      end
      storyboard.tcpSocial.setReceiveInterval(nil)
    end
  end)
  storyboard.comm.getGameServerAddress()

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.lobbyQuickPlay" then
      homeButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)

  function cleanUp()
    for _, button in pairs(mapButtons) do
      button:removeEventListener("tap", button)
    end
    for slot = 1, 4 do
      removeAvatar(slot)
    end
  end
end

function scene:exitScene()
  if not gameStarting then
    storyboard.tcpClient.stopTCPClient()
  end
  cleanUp()
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
  storyboard.comm.setCallback(function() end)
  storyboard.tcpClient.changeReceiveInfo(function() end)
end

function scene:destroyScene()
  homeButton = nil
  voteTitle, waitingText, searchingText = nil, nil, nil
  voteCountTexts, nameTexts, noUserImages, slotGroups = {}, {}, {}, {}
  quickPlayBackground = nil
  showLobby, cleanUp = nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
