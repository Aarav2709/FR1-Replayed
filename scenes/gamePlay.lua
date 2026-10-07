-- the race. local simulation, bots or lan players.

local storyboard = require("modules.storyboard")
local physics = require("physics")
local map = require("modules.map")
local powerUps = require("modules.powerUps")
local player = require("modules.player")
local tutorialModule = require("modules.tutorialModule")
local lan = require("modules.lan")

local scene = storyboard.newScene()

local skyGroup, cloudGroup, mountainGroup, nearGroup, gameGroup, foregroundGroup
local selfArrow, ninjaArrow, homeButton, positionText, jumpHint, powerUpHint
local jumpArea, jumpButton, powerUpArea, powerUpButton
local countdownImage
local placeNames
local quitAlert
local cleanUp

local PLAYER_SCREEN_X, PLAYER_SCREEN_Y = 150, 204
local PROGRESS_BAR_WIDTH = 340
local PROGRESS_BAR_LEFT = (display.contentWidth - PROGRESS_BAR_WIDTH) * 0.5
local FINISH_TIMEOUT = 30000
local KILLING_POWER_UPS = { [1] = "blade", [2] = "trap", [3] = "lightning", [9] = "ninja" }

function scene:createScene()
  local view = self.view
  local screenRight = display.screenOriginX + display.actualContentWidth
  local font = storyboard.gameDataTable.font

  storyboard.gameDataTable.gameStats = nil
  skyGroup = display.newGroup()
  view:insert(skyGroup)
  cloudGroup = display.newGroup()
  view:insert(cloudGroup)
  mountainGroup = display.newGroup()
  view:insert(mountainGroup)
  nearGroup = display.newGroup()
  view:insert(nearGroup)
  gameGroup = display.newGroup()
  view:insert(gameGroup)
  foregroundGroup = display.newGroup()
  view:insert(foregroundGroup)

  selfArrow = display.newImageRect("images/game/selfArrow.png", 15, 15)
  selfArrow.x, selfArrow.y = 150, 160
  view:insert(selfArrow)
  ninjaArrow = display.newImageRect("images/game/powerup/ninja/arrow.png", 15, 15)
  ninjaArrow.x, ninjaArrow.y = 150, 160
  ninjaArrow.alpha = 0
  view:insert(ninjaArrow)

  homeButton = display.newImageRect("images/gui/button/smallHome.png", 35, 35)
  homeButton.x = display.screenOriginX + homeButton.width * 0.5 + 8
  homeButton.y = homeButton.height * 0.5 + 8
  view:insert(homeButton)

  positionText = display.newText("22", 0, 0, font, 40 * 2)
  positionText:setFillColor(1, 1, 1, 1)
  positionText.xScale, positionText.yScale = 0.5, 0.5
  positionText.x, positionText.y = display.contentWidth * 0.5, 20
  view:insert(positionText)

  local tutorial = storyboard.config.tutorial
  jumpArea = display.newImageRect("images/transparent.png", 150, 150)
  jumpArea.x = screenRight - jumpArea.width * 0.5
  jumpArea.y = display.contentHeight - jumpArea.height * 0.5
  view:insert(jumpArea)
  if tutorial then
    jumpArea.alpha = 0
  end
  jumpButton = display.newImageRect("images/gui/button/btnJump.png", 64, 64)
  jumpButton.x = screenRight - jumpButton.width * 0.5
  jumpButton.y = display.contentHeight - jumpButton.height * 0.5
  view:insert(jumpButton)
  if tutorial then
    jumpButton.alpha = 0
  end
  powerUpArea = display.newImageRect("images/transparent.png", 150, 150)
  powerUpArea.x = display.screenOriginX + powerUpArea.width * 0.5
  powerUpArea.y = display.contentHeight - powerUpArea.height * 0.5
  view:insert(powerUpArea)
  powerUpButton = display.newImageRect("images/gui/button/btnPowerUp.png", 64, 64)
  powerUpButton.x = display.screenOriginX + powerUpButton.width * 0.5
  powerUpButton.y = display.contentHeight - powerUpButton.height * 0.5
  view:insert(powerUpButton)
  if tutorial then
    powerUpButton.alpha = 0
  end
  if isPC then
    local function newHint(text, button)
      local hint = display.newText(text, 0, 0, font, 28)
      hint:setFillColor(1, 1, 1)
      hint.xScale, hint.yScale = 0.5, 0.5
      hint.x, hint.y = button.x, button.y - 40
      view:insert(hint)
      return hint
    end
    jumpHint = newHint("SPACE", jumpButton)
    powerUpHint = newHint("X", powerUpButton)
    if tutorial then
      jumpHint.alpha, powerUpHint.alpha = 0, 0
    end
  end

  placeNames = {
    storyboard.localized.get("1st"),
    storyboard.localized.get("2nd"),
    storyboard.localized.get("3rd"),
    storyboard.localized.get("4th"),
  }
  audio.reserveChannels(21)
end

function scene:enterScene()
  local view = self.view
  local killFeed = display.newGroup()
  local font = storyboard.gameDataTable.font
  local WHITE = { 1, 1, 1, 1 }

  local raceStarted = false
  local waitingForGoal = true
  local ended = false
  local backKeyEnabled = false
  local backPressed = false
  local countdownValue = 3
  local raceStartTime = 0
  local position = 0
  local heads = {}
  local players = {}
  local killFeedEntries = {}
  local me
  local raceTimer, countdownTimer, inputTimer, finishTimeout, stateTimer, goTimeout
  local powerUpIcon
  local hasPowerUpIcon = false
  local lanMode = (storyboard.gameType == 3 or storyboard.gameType == 4) and lan.isActive()

  local username = lanMode and lan.getName() or storyboard.playerInfo.username
  local resultReported = false
  local raceStats = { kills = 0, deaths = 0, suicides = 0, pickups = 0, killsBy = {} }
  local onPowerUpTouch, onMessage, countdownTick, startCountdown, setUpLan

  system.activate("multitouch")

  local function playSound(name, channel)
    if storyboard.database.getSound() == 1 then
      if channel then
        audio.play(storyboard.gameDataTable.sounds[name], { channel = channel })
      else
        audio.play(storyboard.gameDataTable.sounds[name])
      end
    end
  end

  local function volumeForDistance(myX, otherX)
    local distance = math.abs(myX - otherX)
    if distance < display.contentWidth then
      return 0.9
    elseif distance < display.contentWidth * 2 then
      return 0.7
    elseif distance < display.contentWidth * 4 then
      return 0.4
    end
    return 0
  end

  local function createPlayers(startY)
    local names = storyboard.gameDataTable.playerListNames
    for i = 1, #names do
      if names[i].username ~= "" then
        local isLocal = names[i].username == username

        local startPowerUp = math.random(1, 10)
        if startPowerUp == 2 then
          startPowerUp = 1
        elseif startPowerUp == 8 then
          startPowerUp = 6
        end
        players[i] = player.new(i, names[i].username, names[i].avatar, startPowerUp, isLocal, players, startY,
          lanMode and not isLocal)
        players[i].addPlaySoundFunction(playSound)
        gameGroup:insert(players[i].getBodyPartsGroup())
        gameGroup:insert(players[i])
        gameGroup:insert(players[i].getGhostGroup())
        view:insert(players[i].getScreenGroup())
      end
    end
  end

  local function newPowerUpIcon(powerUpId, size)
    local images = {
      [0] = "images/transparent.png",
      [1] = "images/game/powerup/blade/icon.png",
      [2] = "images/game/powerup/trap/icon.png",
      [3] = "images/game/powerup/lightning/icon.png",
      [4] = "images/game/powerup/speed/icon.png",
      [5] = "images/game/powerup/shield/icon.png",
      [6] = "images/game/powerup/armor/icon.png",
      [7] = "images/game/powerup/magnet/icon.png",
      [8] = "images/game/powerup/bounceTrap/icon.png",
      [9] = "images/game/powerup/ninja/icon.png",
      [10] = "images/game/powerup/jump/icon.png",
      [99] = "images/game/powerup/mapIcon.png",
    }
    if images[powerUpId] then
      return display.newImageRect(images[powerUpId], size, size)
    end
  end

  local function removePowerUpIcon()
    if powerUpIcon then
      display.remove(powerUpIcon)
      powerUpIcon = nil
      hasPowerUpIcon = false
    end
  end

  local function showPowerUpIcon(powerUpId)
    if powerUpIcon then
      display.remove(powerUpIcon)
      powerUpIcon = nil
    end
    if powerUpId > 50 then
      powerUpId = powerUpId - 50
    end
    powerUpIcon = newPowerUpIcon(powerUpId, 60)
    powerUpIcon.x = display.screenOriginX + 28
    powerUpIcon.y = display.contentHeight - 30
    view:insert(powerUpIcon)
    hasPowerUpIcon = true
  end

  local function onPowerUpPickedUp(powerUpId)
    raceStats.pickups = raceStats.pickups + 1
    showPowerUpIcon(powerUpId)
  end

  local function updateNinjaArrow()
    ninjaArrow.alpha = me.ninjaMark and 1 or 0
  end

  local function updateHead(i)
    heads[i].x = players[i].x / (map.getLength() - 10) * PROGRESS_BAR_WIDTH + PROGRESS_BAR_LEFT
  end

  local function showPosition(place)
    if place ~= positionText.text then
      positionText.text = placeNames[place]
    end
  end

  local function removeUnlessEnded(object)
    if object and not ended then
      display.remove(object)
    end
  end

  local function addKillFeedEntry(killerId, powerUpId, victimId)
    if not players or ended then
      return
    end
    local killerName = players[killerId].getUsername()
    local victimName = players[victimId].getUsername()
    local LIFETIME = 6000
    if powerUpId == 7 or powerUpId == 99 then
      victimName = ""
    end
    local rowY = -(#killFeedEntries / 3 + 1) * display.contentHeight * 0.05

    local victimText = display.newText(victimName, 0, 0, font, 28 * 1.5)
    victimText.anchorX, victimText.anchorY = 1, 0
    victimText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    victimText.xScale, victimText.yScale = 0.5, 0.5
    victimText.x = display.screenOriginX + display.actualContentWidth - 4
    victimText.y = rowY
    timer.performWithDelay(LIFETIME, function() return removeUnlessEnded(victimText) end, 1)

    local icon = newPowerUpIcon(powerUpId, 26)
    icon.anchorX, icon.anchorY = 1, 0
    icon.x = victimText.x - victimText.width * 0.5
    icon.y = 2 + rowY
    timer.performWithDelay(LIFETIME, function() return removeUnlessEnded(icon) end, 1)

    local killerText = display.newText(killerName, 0, 0, font, 28 * 1.5)
    killerText.anchorX, killerText.anchorY = 1, 0
    killerText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    killerText.xScale, killerText.yScale = 0.5, 0.5
    killerText.x = icon.x - icon.width
    killerText.y = rowY
    timer.performWithDelay(LIFETIME, function() return removeUnlessEnded(killerText) end, 1)

    for _ = 1, 3 do
      killFeedEntries[#killFeedEntries + 1] = 1
    end
    killFeed:insert(victimText)
    killFeed:insert(icon)
    killFeed:insert(killerText)
    view:insert(killFeed)
  end

  local function recordKill(killerId, powerUpId, victimId)
    local kind = KILLING_POWER_UPS[powerUpId]
    if not kind or not me then
      return
    end
    if killerId == me.id and victimId == me.id then
      raceStats.suicides = raceStats.suicides + 1
    elseif killerId == me.id then
      raceStats.kills = raceStats.kills + 1
      raceStats.killsBy[kind] = (raceStats.killsBy[kind] or 0) + 1
    end
    if victimId == me.id then
      raceStats.deaths = raceStats.deaths + 1
    end
  end

  local function killMessage(killerId, powerUpId, victimId)
    recordKill(killerId, powerUpId, victimId)
    killFeed.y = killFeed.y + display.contentHeight * 0.05
    timer.performWithDelay(200, function() return addKillFeedEntry(killerId, powerUpId, victimId) end, 1)
  end

  local function isNearPlayer(i)
    local other = players[i]
    if other and me and other.x and me.x then
      return other.x >= me.x - 400 and other.x <= me.x + 580
    end
    return false
  end

  local function updateCamera()
    if ended or not me or not me.x or not gameGroup then
      return
    end
    if storyboard.config.tutorial then
      tutorialModule.update(me)
      if me.x > 4300 then
        selfArrow.alpha = 0
        return
      end
    end
    gameGroup.x = -me.x + PLAYER_SCREEN_X
    gameGroup.y = -me.y + PLAYER_SCREEN_Y
    foregroundGroup.x = -me.x + PLAYER_SCREEN_X
    foregroundGroup.y = -me.y + PLAYER_SCREEN_Y
    nearGroup.x = -me.x * 0.8
    nearGroup.y = -me.y * 0.8
    mountainGroup.x = -me.x * 0.2
    mountainGroup.y = -me.y * 0.2
    cloudGroup.x = -me.x * 0.05
    cloudGroup.y = -me.y * 0.05
    if raceStarted then
      for i = 1, #players do
        if isNearPlayer(i) then
          players[i].interpolation()
          players[i].calculateRotation()
        else
          players[i].forcePlayer()
        end
      end
    end
  end

  local function gotoResults()
    if not ended then
      storyboard.gotoScene("scenes.postLobby")
      storyboard.purgeScene("scenes.gamePlay")
    end
  end

  local allFinished = false
  local function updateRanking(finishedId)
    if ended or allFinished then
      return
    end
    local finished, myPlace = 0, 1
    local ranking = {}
    for i = 1, #players do
      local goalTime = players[i].getPlayerGoalTime()
      if goalTime == -2 then
        goalTime = 9999999999
      end
      ranking[i] = { username = players[i].getUsername(), goalTime = goalTime, index = i }
      if goalTime > 0 then
        finished = finished + 1
        if goalTime < me.getPlayerGoalTime() then
          myPlace = myPlace + 1
        end
      end
    end
    storyboard.gameDataTable.quickPlayerRankingTable = ranking
    if finishedId == me.id then
      showPosition(myPlace)
    end
    if finished == #players then
      allFinished = true
      if finishTimeout then
        timer.cancel(finishTimeout)
        finishTimeout = nil
      end

      if storyboard.gameType == 2 and not resultReported then
        resultReported = true
        local sorted = {}
        for i, entry in ipairs(ranking) do
          sorted[i] = entry
        end
        table.sort(sorted, function(a, b) return a.goalTime < b.goalTime end)
        local racers = {}
        for place, entry in ipairs(sorted) do
          local racer = { name = entry.username, place = place, isPlayer = entry.index == me.id }
          for _, lobbyRacer in ipairs(storyboard.tcpClient.getRacers()) do
            if lobbyRacer.name == entry.username then
              racer.botId = lobbyRacer.botId
            end
          end
          racers[place] = racer
          if racer.isPlayer then
            raceStats.position = place
          end
        end
        raceStats.racers = racers
        raceStats.mapId = storyboard.gameDataTable.mapSelected
        raceStats.gameType = storyboard.gameType
        storyboard.gameDataTable.gameStats = storyboard.tcpClient.reportRaceResult(raceStats)
      end
      timer.performWithDelay(2000, gotoResults, 1)
    end
  end

  local function finishStragglers()
    finishTimeout = nil
    if ended or allFinished then
      return
    end
    local now = system.getTimer() - raceStartTime
    for i = 1, #players do
      if players[i].getPlayerGoalTime() < 0 then
        local remaining = math.max(0, map.getLength() - players[i].x)
        players[i].setPlayerGoalTime(now + remaining / 300 * 1000)
        players[i].stopPlayer()
      end
    end
    updateRanking(me.id)
  end

  local function onPlayerFinished()
    me.setCurrentGameTime(system.getTimer() - raceStartTime)
    powerUpArea:removeEventListener("touch", powerUpArea)
    jumpArea:removeEventListener("touch", jumpArea)
    me.setPlayerGoalTime(me.getCurrentGameTime())
    killMessage(me.id, 99, me.id)
    if lanMode then
      lan.sendRace({ m = "j", i = me.id, s = { x = me.x, s = me.getCurrentGameTime() } })
    end
    updateRanking(me.id)
    if not allFinished then
      finishTimeout = timer.performWithDelay(FINISH_TIMEOUT, finishStragglers, 1)
    end
  end

  local function raceTick()
    if not raceStarted or ended then
      return
    end
    position = 1
    for i = 1, #players do
      local racer = players[i]
      if map.isInGoal(racer.x) then
        racer.stopPlayer()
        if waitingForGoal and map.isInGoal(me.x) then
          waitingForGoal = false
          onPlayerFinished()
        end
      else
        racer.accelerate()
      end
      if racer.x > me.x then
        position = position + 1
      end
      updateHead(i)
    end
    updateNinjaArrow()
    if not map.isInGoal(me.x) then
      showPosition(position)
      me.setPlayerPosition(position, #players)
    end
  end

  local function stopGame()
    if ended then
      return
    end
    ended = true
    physics.pause()
    for i = 1, #players do
      players[i].pauseSprite()
    end
    if me.getPlayerGoalTime() < 0 then
      powerUpArea:removeEventListener("touch", powerUpArea)
      jumpArea:removeEventListener("touch", jumpArea)
    end
  end

  local function showCountdown(value)
    if countdownImage then
      display.remove(countdownImage)
      countdownImage = nil
    end
    if value == "GO!" or value == storyboard.localized.get("Go") then
      countdownImage = display.newImageRect("images/game/countdownGo.png", 129, 70)
    else
      countdownImage = display.newImageRect("images/game/countdown" .. tostring(value):sub(1, 1) .. ".png", 129, 70)
    end
    if countdownImage then
      countdownImage.x = display.contentWidth * 0.5
      countdownImage.y = display.contentHeight * 0.3
      view:insert(countdownImage)
      transition.to(countdownImage, { time = 400, alpha = 1 })
      transition.to(countdownImage, { time = 400, delay = 500, alpha = 0 })
    end
  end

  local function leaveGame()
    if lanMode then
      lan.leave()
    end
    if storyboard.config.tutorial then
      storyboard.gotoScene("scenes.playMenu")
    else
      storyboard.gotoScene("scenes.mainMenu")
    end
    storyboard.purgeScene("scenes.gamePlay")
  end

  local function reportQuit()
    if storyboard.gameType == 2 and not resultReported and me and me.getPlayerGoalTime() < 0 then
      resultReported = true
      local racers = {}
      for _, lobbyRacer in ipairs(storyboard.tcpClient.getRacers()) do
        racers[#racers + 1] = { name = lobbyRacer.name, botId = lobbyRacer.botId, place = 1, isPlayer = lobbyRacer.isPlayer }
      end
      raceStats.position = #players
      for _, racer in ipairs(racers) do
        if racer.isPlayer then
          racer.place = #players
        end
      end
      raceStats.racers = racers
      raceStats.quit = true
      storyboard.tcpClient.reportRaceResult(raceStats)
    end
  end

  local function onQuitAlert(event)
    if event.action == "clicked" then
      quitAlert = nil
      local yes = isAndroid and 1 or 2
      if event.index == yes and not ended then
        reportQuit()
        stopGame()
        timer.performWithDelay(200, leaveGame, 1)
      end
    end
  end

  local function askQuit()
    local message = storyboard.localized.get("QuitGame")
    if storyboard.gameType == 2 and me.getPlayerGoalTime() <= 0 then
      message = storyboard.localized.get("QuitGameWithWarning")
    end
    local yes, no = storyboard.localized.get("Yes"), storyboard.localized.get("No")
    if isAndroid then
      quitAlert = native.showAlert(storyboard.localized.get("Quit"), message, { yes, no }, onQuitAlert)
    else
      quitAlert = native.showAlert(storyboard.localized.get("Quit"), message, { no, yes }, onQuitAlert)
    end
  end

  function onMessage(message)
    if ended or not message or not message.m then
      return
    end
    local racer = players[message.i]
    if not racer then
      return
    end
    racer.connected = true
    if message.s and message.s.x then
      racer.setSoundVolume(volumeForDistance(me.x, message.s.x))
    end
    if message.m == "h" then
      if racer.canOtherPlayerUsePU() then
        powerUps.usePowerUp(message.p.t, message.i, username, nil, message.p.x, message.p.y, gameGroup, view, players)
        if message.p.t <= 50 then
          racer.usedPowerUp()
        end
      end
    elseif message.m == "j" then
      if racer.getPlayerGoalTime() > 0 then
        return
      end
      racer.setPlayerGoalTime(message.s.s)
      killMessage(message.i, 99, message.i)
      updateRanking(message.i)
    end
  end

  function countdownTick(event)
    if ended then
      return
    end
    showCountdown(countdownValue)
    if countdownValue == storyboard.localized.get("Go") then
      raceStarted = true
      raceStartTime = system.getTimer()
      for i = 1, #players do
        players[i].setBotModuleFunction(onMessage, raceStartTime)
      end
      playSound("start")
      timer.cancel(event.source)
    else
      playSound("countdown")
      countdownValue = countdownValue - 1
      if countdownValue == 0 then
        countdownValue = storyboard.localized.get("Go")
      end
    end
  end

  local function onJumpTouch(_, event)
    if event.phase == "began" and raceStarted then
      local tutorialAllows = false
      if storyboard.config.tutorial then
        tutorialAllows = tutorialModule.jumpButtonClicked()
      end
      if me.canJump() or tutorialAllows then
        me.jump()
        playSound("jump")
        me.onGround = false
      end
      return true
    end
  end

  local function useSecondPowerUp(powerUpId)
    powerUps.usePowerUp(powerUpId, me.id, username, me, 0, 0, gameGroup, view, players)
    if lanMode then
      lan.sendRace({ m = "h", i = me.id, p = { t = powerUpId, x = me.x, y = me.y }, s = { x = me.x } })
    end
  end

  function onPowerUpTouch(_, event)
    if event.phase == "began" and raceStarted then
      local tutorialAllows = false
      if storyboard.config.tutorial then
        tutorialAllows = tutorialModule.puButtonClicked()
      end
      local powerUp = me.getPowerUp()
      local canUse = powerUp > 0 and hasPowerUpIcon
      if canUse or tutorialAllows then
        me.usedPowerUp()
        powerUps.usePowerUp(powerUp, me.id, username, me, 0, 0, gameGroup, view, players)
        if lanMode then
          lan.sendRace({ m = "h", i = me.id, p = { t = powerUp, x = me.x, y = me.y }, s = { x = me.x } })
        end
        if powerUp > 50 then
          timer.performWithDelay(200, function() return useSecondPowerUp(powerUp - 50) end, 1)
        end
        removePowerUpIcon()
      end
      return true
    end
  end

  local function onHomeTouch(_, event)
    if event.phase == "began" then
      askQuit()
    end
  end

  local function cancelTimers()
    for _, handle in pairs({ raceTimer = raceTimer, inputTimer = inputTimer, countdownTimer = countdownTimer,
      finishTimeout = finishTimeout, stateTimer = stateTimer, goTimeout = goTimeout }) do
      timer.cancel(handle)
    end
    raceTimer, inputTimer, countdownTimer, finishTimeout, stateTimer, goTimeout = nil, nil, nil, nil, nil, nil
  end

  local function onFrame()
    if backPressed then
      backPressed = false
      askQuit()
    end
  end

  local function onKey(event)
    if event.phase == "down" and ended == false and raceStarted then
      if event.keyName == "space" then
        onJumpTouch(nil, { phase = "began" })
        return true
      elseif event.keyName == "x" then
        onPowerUpTouch(nil, { phase = "began" })
        return true
      end
    end
    if event.phase == "up" and event.keyName == "back" then
      if backKeyEnabled then
        backPressed = true
      end
      return true
    end
    return false
  end

  local function enableInput()
    if storyboard.getCurrentSceneName() == "scenes.gamePlay" then
      jumpArea.touch = onJumpTouch
      powerUpArea.touch = onPowerUpTouch
      homeButton.touch = onHomeTouch
      powerUpArea:addEventListener("touch", powerUpArea)
      jumpArea:addEventListener("touch", jumpArea)
      homeButton:addEventListener("touch", homeButton)
      backKeyEnabled = true
    end
  end

  local function bringControlsToFront()
    view:insert(homeButton)
    view:insert(positionText)
    view:insert(killFeed)
    view:insert(jumpArea)
    view:insert(jumpButton)
    view:insert(powerUpButton)
    if jumpHint then
      view:insert(jumpHint)
      view:insert(powerUpHint)
    end
    if powerUpIcon then
      view:insert(powerUpIcon)
    end
  end

  function cleanUp()
    ended = true
    cancelTimers()
    if lanMode then
      lan.setHandler(nil)
    end
    Runtime:removeEventListener("enterFrame", updateCamera)
    Runtime:removeEventListener("key", onKey)
    Runtime:removeEventListener("enterFrame", onFrame)
    system.deactivate("multitouch")
    if quitAlert then
      native.cancelAlert(quitAlert)
      quitAlert = nil
    end
    powerUps.clean()
    for i = 1, #players do
      if players[i] then
        players[i].clean()
        players[i] = nil
      end
    end
    players = nil
    map.clean()
    countdownImage = nil
    physics.stop()
    tutorialModule.clean()
    storyboard.config.tutorial = false
  end

  local function onLanRace(msg)
    local racer = players[msg.i]
    if not racer or msg.i == me.id then
      return
    end
    if msg.m == "s" then
      if raceStarted then
        racer.setRemoteState(msg.x, msg.y, msg.vx, msg.vy)
      end
    else
      onMessage(msg)
    end
  end

  local function disconnectRacer(racer, index)
    if racer and racer ~= me and racer.getPlayerGoalTime() < 0 then
      racer.setDisconnected()
      racer.setPlayerGoalTime(-2)
      if not ended then
        updateRanking(index)
      end
    end
  end

  local function onLanEvent(event)
    if ended then
      return
    end
    if event.type == "go" then
      startCountdown()
    elseif event.type == "race" then
      onLanRace(event.msg)
    elseif event.type == "gone" then
      for i = 1, #players do
        if players[i].getUsername() == event.name then
          disconnectRacer(players[i], i)
        end
      end
    elseif event.type == "closed" then
      for i = 1, #players do
        disconnectRacer(players[i], i)
      end
    end
  end

  local function sendLanState()
    if raceStarted and not ended and me and me.x then
      local vx, vy = me:getLinearVelocity()
      lan.sendRace({ m = "s", i = me.id, x = me.x, y = me.y, vx = vx, vy = vy })
    end
  end

  function setUpLan()
    lan.setHandler(onLanEvent)
    stateTimer = timer.performWithDelay(50, sendLanState, 0)
    lan.sendReady()

    goTimeout = timer.performWithDelay(20000, startCountdown, 1)
  end

  physics.setVelocityIterations(2)
  physics.setPositionIterations(4)
  physics.start()
  physics.setGravity(0, 20)
  storyboard.powerUpPositions = {}
  local startY = map.init(storyboard.gameDataTable.mapSelected, gameGroup, foregroundGroup, nearGroup, mountainGroup,
    cloudGroup, skyGroup)
  createPlayers(startY)
  for i = 1, #players do
    if players[i].getUsername() == username then
      me = players[i]
      position = #players - i + 1
      me.setUpdatePowerUpImageFunction(onPowerUpPickedUp)
      me.mobileUser = true
      updateCamera()
    end
    players[i].connected = false
    players[i].setKillMessageFunction(killMessage)
  end
  map.setMapName(gameGroup, me.x)
  powerUps.init()
  powerUps.addPlaySoundFunction(playSound)
  showPowerUpIcon(me.getPowerUp())

  for i = 1, #players do
    heads[i] = players[i].getPlayerHead()
    heads[i].x = players[i].x / (map.getLength() - 10) * PROGRESS_BAR_WIDTH + PROGRESS_BAR_LEFT
    heads[i].y = display.contentHeight + 2
    view:insert(heads[i])
    if storyboard.config.tutorial then
      heads[i].alpha = 0
    end
  end
  view:insert(heads[me.id])
  showPosition(position)

  raceTimer = timer.performWithDelay(100, raceTick, 0)
  function startCountdown()
    if not countdownTimer and not ended then
      countdownTimer = timer.performWithDelay(1000, countdownTick, 7)
    end
  end
  if lanMode then
    setUpLan()
  else
    startCountdown()
  end
  if storyboard.config.tutorial then
    tutorialModule.init(view, physics)
    tutorialModule.setFunctions(function()
      jumpArea.alpha = 1
      jumpButton.alpha = 1
      if jumpHint then
        jumpHint.alpha = 1
      end
    end, function()
      powerUpButton.alpha = 1
      if powerUpHint then
        powerUpHint.alpha = 1
      end
    end)
  end
  bringControlsToFront()
  Runtime:addEventListener("enterFrame", updateCamera)
  inputTimer = timer.performWithDelay(500, enableInput, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  if homeButton then
    homeButton:removeEventListener("touch", homeButton)
  end
  if cleanUp then
    cleanUp()
    cleanUp = nil
  end
end

function scene:destroyScene()
  quitAlert = nil
  placeNames = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
