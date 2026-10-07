-- results after a quick play or lan race.

local storyboard = require("modules.storyboard")
local adaptiveUI = require("modules.adaptiveUI")
local gui = require("modules.gui")
local mapInfo = require("modules.mapInfo")
local createSprite = require("modules.createSprite")
local loadingAnimation = require("modules.loadingAnimation")

local scene = storyboard.newScene()

local PODIUM = { { 119, 115 }, { 46, 145 }, { 191, 158 }, { 278, 198 } }
local ANIMATION_TAG = "postlobbyAnimationTransitions"
local TEXT_ANIMATION_TAG = "postlobbyTextAnimationTransitions"

local exitButton, playButton, marketButton, freeCoinsButton
local touchBlocker, marketArrow, offerShine, coinShine
local loader
local coinsText
local offerShown = false
local cleanUp, onCoinsClaimed, onFrame, onKey

local function contains(value, list)
  if value == nil or list == nil then
    return false
  end
  for i = 1, #list do
    if value == list[i] then
      return true
    end
  end
  return false
end

local function formatTime(value)
  value = "" .. value
  local dot = string.find(value, "%.")
  if dot then
    if dot + 2 < string.len(value) then
      value = value:sub(1, dot + 2)
    elseif dot + 1 == string.len(value) then
      value = value .. "0"
    elseif dot == string.len(value) then
      value = value .. "00"
    end
  else
    value = value .. ".00"
  end
  return value
end

local function shouldOfferFreeCoins()
  local games = storyboard.totalGamesPlayed
  return (games == 3 or games == 4) and not storyboard.database.hasClaimedEarnCoins(1, 1)
end

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local SMALL, MEDIUM, LARGE = 14, 16, 20
  local BLACK = { 0, 0, 0, 1 }
  local WHITE = { 1, 1, 1, 1 }
  local changeGroup = display.newGroup()
  local totalsGroup = display.newGroup()
  local podiumGroup = display.newGroup()
  local resultsGroup = display.newGroup()
  local avatarGroups = {}
  local racerNames = {}
  local coinChangeText, coinIcon, trophyIcon
  local ratingTimer, startRatingCount
  local coinDelayTimer, coinTimer

  loader = loadingAnimation.newLoadingAnimation()
  loader.displayGroup.x = 50
  loader.displayGroup.y = 30
  offerShown = false
  if storyboard.gameType ~= 1 then
    storyboard.gamesPlayed = storyboard.gamesPlayed + 1
    storyboard.totalGamesPlayed = storyboard.totalGamesPlayed + 1
    storyboard.database.incrementNumberOfGamesPlayed()
  end

  local function onExit()
    storyboard.lan.leave()
    storyboard.tcpClient.stopTCPClient()
    storyboard.gotoScene("scenes.mainMenu")
    storyboard.purgeScene("scenes.postLobby")
  end

  local function onMarket()
    storyboard.lan.leave()
    storyboard.tcpClient.stopTCPClient()
    storyboard.gotoScene("scenes.marketplace")
    storyboard.purgeScene("scenes.postLobby")
  end

  local function onPlayAgain()
    local nextScene = ({
      [1] = "scenes.lobbySingleplayer", [2] = "scenes.lobbyQuickPlay", [3] = "scenes.lanLobby", [4] = "scenes.lanLobby",
    })
      [storyboard.gameType]
    if nextScene then
      storyboard.gotoScene(nextScene)
      storyboard.purgeScene("scenes.postLobby")
    end
  end

  local function slideOut(object)
    if object then
      transition.cancel(object)
      transition.to(object, { time = 500, x = display.contentWidth + 60, transition = easing.inBack, tag = ANIMATION_TAG })
    end
    if offerShine then
      transition.to(offerShine, { time = 300, alpha = 0, transition = easing.linear, tag = ANIMATION_TAG })
    end
  end

  local function bounceArrow(distance)
    transition.to(marketArrow, {
      time = 1000, delta = true, y = distance, transition = easing.linear, tag = ANIMATION_TAG,
      onComplete = function() bounceArrow(-distance) end,
    })
  end

  local function onClaimFreeCoins()
    slideOut(freeCoinsButton)
    storyboard.comm.claimEarnCoins(1)
    freeCoinsButton.removeListener()
    if touchBlocker then
      touchBlocker.isVisible = false
      touchBlocker:removeEventListener("touch", touchBlocker)
      display.remove(touchBlocker)
      touchBlocker = nil
    end
    if marketArrow then
      marketArrow.isVisible = true
      marketArrow.x = marketButton.x
      marketArrow.y = marketButton.y - 40
      bounceArrow(25)
    end
  end

  local mapId = storyboard.gameDataTable.mapSelected
  local background = display.newImageRect("images/gui/background/" .. mapInfo.getPostLobbyImage(mapId) .. ".png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)
  view:insert(podiumGroup)
  local resultsPanel = display.newImageRect("images/gui/background/PostlobbyResults.png", 209.5, 131)
  resultsPanel.anchorX, resultsPanel.anchorY = 1, 0
  resultsPanel.x = display.contentWidth - 15
  resultsPanel.y = 10
  view:insert(resultsPanel)
  local coinsPanel = display.newImageRect("images/gui/background/PostlobbyCoinsRating.png", 221, 50)
  coinsPanel.anchorX, coinsPanel.anchorY = 0.5, 1
  coinsPanel.x = display.contentWidth * 0.5 - 45
  coinsPanel.y = display.contentHeight - 4
  coinsPanel.isVisible = storyboard.gameDataTable.gameStats ~= nil
  view:insert(coinsPanel)
  view:insert(loader.displayGroup)

  exitButton = gui.newButton({
    image = "images/gui/button/exit.png", width = 31, height = 29, onRelease = onExit, x = 20, y = 20,
    displayGroup = view,
  })
  playButton = gui.newButton({
    image = "images/gui/button/playPostlobby.png", width = 80, height = 50, onRelease = onPlayAgain,
    x = display.contentWidth - 48, y = display.contentHeight - 30, displayGroup = view,
  })
  marketButton = gui.newButton({
    image = "images/gui/button/marketPostlobby.png", width = 66.5, height = 50, onRelease = onMarket,
    x = display.contentWidth - 130, y = display.contentHeight - 30, displayGroup = view,
  })

  touchBlocker = display.newRect(0, 0, display.contentWidth, display.contentHeight)
  touchBlocker:setFillColor(0, 0, 0, 0.4)
  touchBlocker.anchorX, touchBlocker.anchorY = 0, 0
  touchBlocker.isVisible = false
  view:insert(touchBlocker)
  function touchBlocker.touch(_, event)
    if event.phase == "began" then
      return true
    end
  end

  marketArrow = display.newImageRect("images/game/arrow.png", 70, 105)
  marketArrow.anchorY = 1
  marketArrow.isVisible = false
  view:insert(marketArrow)
  offerShine = display.newImageRect("images/gui/extra/videoShine.png", 201, 198.5)
  offerShine.isVisible = false
  view:insert(offerShine)
  coinShine = display.newImageRect("images/gui/extra/videoShine.png", 201, 198.5)
  coinShine.isVisible = false
  view:insert(coinShine)

  freeCoinsButton = gui.newButton({
    image = "images/gui/button/firstOffer.png", width = 80, height = 50, onRelease = onClaimFreeCoins,
    x = display.contentWidth + 60, y = display.contentHeight - 110, displayGroup = view,
  })
  freeCoinsButton.isVisible = false
  local function spinShine()
    transition.to(offerShine, {
      time = 4500, rotation = 360, delta = true, transition = easing.linear, tag = ANIMATION_TAG, onComplete = spinShine,
    })
  end

  local function showShine(target)
    offerShine.isVisible = true
    offerShine.x, offerShine.y = target.x, target.y
    offerShine.xScale, offerShine.yScale = 0.01, 0.01
    transition.to(offerShine, { time = 1500, xScale = 1, yScale = 1, transition = easing.outBounce, tag = ANIMATION_TAG })
    spinShine()
  end

  local function showFreeCoinsOffer()
    touchBlocker.isVisible = true
    touchBlocker:toFront()
    offerShine:toFront()
    freeCoinsButton.isVisible = true
    freeCoinsButton:toFront()
    transition.to(freeCoinsButton, {
      time = 500, x = display.contentWidth - 88, transition = easing.outBounce, tag = ANIMATION_TAG,
      onComplete = function() showShine(freeCoinsButton) end,
    })
  end

  for place = 1, 4 do
    avatarGroups[place] = display.newGroup()
    podiumGroup:insert(avatarGroups[place])
  end

  local function showRacer(place, avatars, name, slot)
    local x, y = adaptiveUI.coverPoint(PODIUM[place][1], PODIUM[place][2])
    local scale = adaptiveUI.coverScale()
    local avatar = avatars[name]
    if avatar ~= nil then
      local parts = {
        spriteBody = createSprite.changeSpriteAvatar(avatar[1], avatarGroups[place], slot),
        spriteHat = createSprite.changeSpriteHat(avatar[2], avatarGroups[place], slot),
        spriteBoots = createSprite.changeSpriteBoots(avatar[4], avatarGroups[place], slot),
      }
      parts.spriteBoots:setFrame(4)
      for _, part in pairs(parts) do
        part.xScale, part.yScale = 0.5 * scale, 0.5 * scale
        part.x, part.y = x, y
      end
      parts.spriteHat.y = y - 12 * scale
    end
  end

  local function showStats(rating, ratingChange, coins, coinsWon, coinsLabel, countRating)
    if coinsWon then
      if coinChangeText and coinsLabel then
        coinChangeText.text = " + " .. coinsLabel
      else
        coinChangeText = display.newText(" + " .. coinsWon, 0, 0, font, LARGE)
        coinChangeText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
        coinChangeText.anchorX, coinChangeText.anchorY = 1, 0
        coinChangeText.x, coinChangeText.y = 90, 18
        changeGroup:insert(coinChangeText)
      end
      storyboard.database.setMoney(coins)
      local shown = coins - coinsWon
      if not coinIcon then
        coinIcon = display.newImageRect("images/gui/extra/postlobbyCoin.png", 26, 26.5)
        coinIcon.x, coinIcon.y = 10, 15
        totalsGroup:insert(coinIcon)
      end
      if not trophyIcon then
        trophyIcon = display.newImageRect("images/gui/extra/postlobbyTrophy.png", 25, 27)
        trophyIcon.x, trophyIcon.y = 123, 15
        totalsGroup:insert(trophyIcon)
      end
      if coinsText then
        coinsText.text = shown
      else
        coinsText = display.newText(shown, 0, 0, font, storyboard.fitTextFontSize(shown, LARGE - 5, LARGE + 2, 56))
        coinsText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
        coinsText.anchorX, coinsText.anchorY = 1, 0
        coinsText.x, coinsText.y = 90, 11
        totalsGroup:insert(coinsText)
      end

      local tickCount, sinceShine, ticks, step = 0, 0, coinsWon, 1
      if ticks > 50 then
        step = math.floor(coinsWon / 50)
        ticks = 50
      end
      local function finish()
        if coinsText then
          coinsText.text = coins
        end
        if startRatingCount and countRating then
          ratingTimer = timer.performWithDelay(500, startRatingCount, 1)
        end
      end
      local function coinTick()
        sinceShine = sinceShine + 1
        local shine = sinceShine >= ticks * 0.15
        if shine or tickCount == 0 then
          if shine then
            sinceShine = 0
          end
          coinShine.x, coinShine.y = coinIcon.x, coinIcon.y
          coinShine.xScale, coinShine.yScale = 0.35, 0.35
          coinShine.isVisible = true
          coinShine.alpha = 0.3
          coinShine.rotation = math.random(0, 360)
          totalsGroup:insert(coinShine)
          transition.cancel(coinShine)
          transition.to(coinShine, {
            time = 250, xScale = 0.2, yScale = 0.2, alpha = 0, rotation = coinShine.rotation + 15,
            transition = easing.linear, tag = TEXT_ANIMATION_TAG,
          })
          coinIcon:toFront()
          coinIcon:scale(0.8, 0.8)
          transition.cancel(coinIcon)
          transition.scaleTo(coinIcon, { time = 450, xScale = 1, yScale = 1, transition = easing.outElastic, tag = TEXT_ANIMATION_TAG })
        end
        shown = shown + step
        if coinsText then
          coinsText.text = shown
        end
        if tickCount + 1 == ticks then
          finish()
        else
          tickCount = tickCount + 1
        end
      end
      if ticks > 0 then
        coinDelayTimer = timer.performWithDelay(1000, function()
          coinTimer = timer.performWithDelay(1000 / ticks, coinTick, ticks)
        end, 1)
      else
        finish()
      end
    end

    if ratingChange then
      local label
      if ratingChange > -1 then
        label = "+ " .. ratingChange
      else
        label = "- " .. math.abs(ratingChange)
      end
      local size = LARGE
      local language = storyboard.localized.language
      if language == "ja" or language == "es" or language == "fr" then
        size = MEDIUM
      end
      local ratingChangeText = display.newText(label, 0, 0, font, size)
      ratingChangeText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
      ratingChangeText.anchorX, ratingChangeText.anchorY = 1, 0
      ratingChangeText.x, ratingChangeText.y = 203, 18
      changeGroup:insert(ratingChangeText)

      local shown = rating - ratingChange
      local ratingText = display.newText(shown, 0, 0, font, storyboard.fitTextFontSize(shown, size - 5, size + 2, 56))
      ratingText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
      ratingText.anchorX, ratingText.anchorY = 1, 0
      ratingText.x, ratingText.y = 203, 11
      totalsGroup:insert(ratingText)

      local ticks = math.abs(ratingChange)
      local step = ratingChange < 0 and -1 or 1
      if ticks > 50 then
        ticks = 50
        step = math.floor(ratingChange / 50)
      end
      local count, sinceShine = 0, 0
      local function ratingTick()
        sinceShine = sinceShine + 1
        local shine = sinceShine >= ticks * 0.15
        if shine or count == 0 then
          if shine then
            sinceShine = 0
          end
          if step > 0 then
            coinShine.x, coinShine.y = trophyIcon.x, trophyIcon.y
            coinShine.xScale, coinShine.yScale = 0.35, 0.35
            coinShine.isVisible = true
            coinShine.alpha = 0.3
            coinShine.rotation = math.random(0, 360)
            totalsGroup:insert(coinShine)
            transition.cancel(coinShine)
            transition.to(coinShine, {
              time = 250, xScale = 0.2, yScale = 0.2, alpha = 0, rotation = coinShine.rotation + 15,
              transition = easing.linear, tag = TEXT_ANIMATION_TAG,
            })
          end
          trophyIcon:toFront()
          trophyIcon:scale(0.8, 0.8)
          transition.cancel(trophyIcon)
          transition.scaleTo(trophyIcon, { time = 550, xScale = 1, yScale = 1, transition = easing.outElastic, tag = TEXT_ANIMATION_TAG })
        end
        shown = shown + step
        if ratingText then
          ratingText.text = shown
        end
        count = count + 1
      end
      function startRatingCount()
        if ticks > 0 then
          ratingTimer = timer.performWithDelay(1000 / ticks, ratingTick, ticks)
        end
      end
    end
  end

  local function showGameStats()
    local stats = storyboard.gameDataTable.gameStats
    if stats then
      showStats(stats.r, stats.dr, stats.c, stats.dc, nil, true)
    end
  end

  function onCoinsClaimed(amount)
    local stats = storyboard.gameDataTable.gameStats
    if stats then
      for _, handle in ipairs({ coinTimer, coinDelayTimer }) do
        timer.cancel(handle)
      end
      coinTimer, coinDelayTimer = nil, nil
      local money = storyboard.database.getMoney()
      if coinsText then
        coinsText.text = money
      end
      showStats(nil, nil, money, amount, amount, false)
      coinChangeText.text = " + " .. (stats.dc + amount)
    end
  end

  local function showResults(ranking)
    if ranking then
      if #ranking >= 5 then
        return
      end
      local avatars = {}
      for _, entry in ipairs(storyboard.gameDataTable.playerListNames) do
        avatars[entry.username] = entry.avatar
      end
      table.sort(ranking, function(a, b) return a.goalTime < b.goalTime end)
      showGameStats()
      local winnerTime = math.round(ranking[1].goalTime) / 1000

      local mapName = display.newText(mapInfo.getMapName(mapId), 0, 0, font, LARGE)
      mapName:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
      mapName.anchorX, mapName.anchorY = 0, 0
      mapName.x, mapName.y = 5, 2
      resultsGroup:insert(mapName)
      local line = display.newLine(5, 28, resultsPanel.width - 10, 28)
      line:setStrokeColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
      line.strokeWidth = 2
      resultsGroup:insert(line)

      for i = 1, #ranking - 1 do
        if ranking[i].goalTime >= ranking[i + 1].goalTime then
          ranking[i + 1].goalTime = ranking[i].goalTime + 0.01
        end
      end
      for place, entry in ipairs(ranking) do
        local name = entry.username
        local shortName = name
        if string.len(shortName) > 11 then
          shortName = shortName:sub(1, 11) .. ".."
        end
        local time = math.round(entry.goalTime) / 1000
        local timeLabel
        local timeSize, timeOffset = LARGE, 0
        if place == 1 then
          timeLabel = formatTime(time) .. " s"
        elseif time > 999999 then
          timeLabel = storyboard.localized.get("PlayerDisconnected")
          timeSize, timeOffset = SMALL, 5
        else
          timeLabel = " + " .. formatTime("" .. time - winnerTime) .. " s"
        end
        local nameText = display.newText(place .. ". " .. shortName, 0, 0, font, LARGE)
        nameText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
        nameText.anchorX, nameText.anchorY = 0, 0.5
        nameText.x = 8
        nameText.y = 8 + place * 23 + LARGE / 2
        nameText:scale(0, 1)
        resultsGroup:insert(nameText)
        transition.scaleTo(nameText, {
          delay = place * 300, time = 300, xScale = 1, yScale = 1, transition = easing.inCubic, tag = TEXT_ANIMATION_TAG,
        })
        local timeText = display.newText(timeLabel, 0, 0, font, timeSize)
        timeText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
        timeText.anchorX, timeText.anchorY = 1, 0
        timeText.x = resultsPanel.width - 10
        timeText.y = 3 + place * 23 + timeOffset
        timeText.alpha = 0
        resultsGroup:insert(timeText)
        racerNames[place] = name
        showRacer(place, avatars, name, entry.index)
        transition.to(timeText, { delay = place * 300, time = 400, alpha = 1, transition = easing.inCubic, tag = TEXT_ANIMATION_TAG })
      end
      resultsGroup.x = resultsPanel.x - resultsPanel.width
      resultsGroup.y = resultsPanel.y
      view:insert(resultsGroup)
    else
      local text = display.newText(storyboard.localized.get("ErrorNoPlayers"), 0, 0, font, MEDIUM)
      text:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
      text.x = display.contentWidth * 0.5
      text.y = display.contentHeight * 0.3
      view:insert(text)
    end
  end

  showResults(storyboard.gameDataTable.quickPlayerRankingTable)

  function cleanUp()
    transition.cancel(ANIMATION_TAG)
    transition.cancel(TEXT_ANIMATION_TAG)
    for _, handle in ipairs({ coinDelayTimer, coinTimer, ratingTimer }) do
      timer.cancel(handle)
    end
    createSprite.cleanSuperfluousSprites()
  end

  changeGroup.x, changeGroup.y = coinsPanel.x - 100, display.contentHeight - 72
  view:insert(changeGroup)
  totalsGroup.x, totalsGroup.y = coinsPanel.x - 100, display.contentHeight - 45
  view:insert(totalsGroup)

  if storyboard.gameDataTable.gameStats and shouldOfferFreeCoins() then
    showFreeCoinsOffer()
    exitButton.isVisible = false
    playButton.isVisible = false
    offerShown = true
  end
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false

  function onFrame()
    if offerShown then
      return
    end
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.lan.leave()
      storyboard.tcpClient.stopTCPClient()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.postLobby")
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

  storyboard.comm.setCallback(function(packet)
    if packet and packet.m == "A" and not packet.a then
      onCoinsClaimed(packet.d or 0)
    end
  end)

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.postLobby" then
      playButton.addListener()
      freeCoinsButton.addListener()
      exitButton.addListener()
      marketButton.addListener()
      backKeyEnabled = true
      if touchBlocker then
        touchBlocker:addEventListener("touch", touchBlocker)
      end
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)

end

function scene:exitScene()
  cleanUp()
  if loader then
    loader.stopLoader()
  end
  if storyboard.gameType == 2 then
    storyboard.tcpClient.stopTCPClient()
  end
  storyboard.comm.setCallback(function() end)
  playButton.removeListener()
  freeCoinsButton.removeListener()
  exitButton.removeListener()
  marketButton.removeListener()
  if touchBlocker then
    touchBlocker:removeEventListener("touch", touchBlocker)
  end
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  loader = nil
  exitButton, playButton, marketButton, freeCoinsButton = nil, nil, nil, nil
  touchBlocker, marketArrow, offerShine, coinShine = nil, nil, nil, nil
  coinsText = nil
  cleanUp, onCoinsClaimed = nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
