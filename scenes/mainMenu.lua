-- main menu.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local createSprite = require("modules.createSprite")
local pcMode = require("modules.pcMode")
local serverData = require("modules.offline.serverData")

local scene = storyboard.newScene()

local buttons = {}
local marketBadge, marketCount
local tutorialCover, tutorialText
local pcMenu, pcAvatarGroup, pcCoinText
local WHITE = { 1, 1, 1, 1 }

function scene:createScene()
  local group = self.view
  local font = storyboard.gameDataTable.font

  if not storyboard.playerInfo then
    storyboard.playerInfo = storyboard.database.getPlayerInformation()
  end

  local function startTutorial()
    storyboard.gameDataTable.playerListNames[1] = {
      username = storyboard.playerInfo.username,
      avatar = storyboard.database.getAvatarData(),
    }
    storyboard.gameType = 1
    storyboard.gameDataTable.mapSelected = 38
    storyboard.gotoScene("scenes.gamePlay")
  end

  local function onPlay()
    if storyboard.config.tutorial then
      tutorialCover.alpha = 1
      tutorialText.alpha = 1
      group:insert(tutorialCover)
      group:insert(tutorialText)
      timer.performWithDelay(100, startTutorial, 1)
    else
      storyboard.gotoScene("scenes.playMenu")
    end
    return true
  end

  local function onSettings()
    storyboard.gotoScene("scenes.settings")
    return true
  end

  local function onRanking()
    storyboard.gotoScene("scenes.ranking")
  end

  local function onLan()
    storyboard.gotoScene("scenes.lan")
  end

  local function onMarket()
    storyboard.gotoScene("scenes.marketplace")
    storyboard.database.resetMarketNotification()
  end

  local function onChallenges()
    storyboard.gotoScene("scenes.earnCoins")
  end

  local function onSocialMessage(packet)

    return packet.m == "l"
  end
  scene.onSocialMessage = onSocialMessage

  storyboard.playerInfo = storyboard.database.getPlayerInformation()
  storyboard.comm.startSocialTCP(onSocialMessage)

  local background = display.newImageRect("images/gui/background/background_mainMenu.png", 480, 320)
  background.anchorY = 0
  background.x = display.contentWidth * 0.5
  background.y = 0
  group:insert(background)

  local H = display.contentHeight
  local playY = math.min(H * 0.575 * background.yScale, H - 75)
  buttons.play = gui.newButton({ image = "images/gui/button/play.png", width = 120, height = 60, onRelease = onPlay,
    x = display.contentWidth * 0.5, y = playY, displayGroup = group })
  buttons.settings = gui.newButton({ image = "images/gui/button/settings.png", width = 50, height = 50,
    onRelease = onSettings, x = 30, y = H - 30, displayGroup = group })
  buttons.ranking = gui.newButton({ image = "images/gui/button/ranking.png", width = 50, height = 50,
    onRelease = onRanking, x = 85, y = H - 30, displayGroup = group })
  buttons.lan = gui.newButton({ image = "images/gui/button/blank.png", width = 60, height = 50,
    text = { string = "LAN", size = 22 }, onRelease = onLan, x = 145, y = H - 30, displayGroup = group })
  buttons.market = gui.newButton({ image = "images/gui/button/market.png", width = 80, height = 50,
    onRelease = onMarket, x = display.contentWidth - 50, y = H - 30, displayGroup = group })
  buttons.challenges = gui.newButton({ image = "images/gui/button/earnCoins.png", width = 50, height = 50,
    onRelease = onChallenges, x = display.contentWidth - 120, y = H - 30, displayGroup = group })

  createSprite.updateAvatar(storyboard.database.getAvatarData())

  if pcMode.isPC then
    local PLANK_W, PLANK_H, PLANK_GAP, LABEL_SIZE = 190, 27, 4, 17
    local W = display.contentWidth
    for _, button in pairs(buttons) do
      button.showButton(false)
    end
    background.isVisible = false
    local blurred = display.newImageRect("images/gui/background/background_playMenu.png", 480, 320)
    blurred.x, blurred.y = W * 0.5, H * 0.5
    blurred.fill.effect = "filter.blurGaussian"
    blurred.fill.effect.horizontal.blurSize = 12
    blurred.fill.effect.horizontal.sigma = 6
    blurred.fill.effect.vertical.blurSize = 12
    blurred.fill.effect.vertical.sigma = 6
    group:insert(2, blurred)

    pcMenu = display.newGroup()
    group:insert(pcMenu)
    local items = {
      { "Play", onPlay },
      { "Shop", onMarket },
      { "Leagues", onRanking },
      { "LAN", onLan },
      { "Challenges", onChallenges },
      { "Settings", onSettings },
      { "Quit", function() native.requestExit() end },
    }
    local columnX = W - PLANK_W * 0.5 - 24
    local listH = #items * PLANK_H + (#items - 1) * PLANK_GAP
    local logo = display.newImageRect(pcMenu, "images/gui/menu_logo.png", 302, 77.5)
    local logoRoom = H - (listH + 10 + 10 + 20) - 16
    local logoScale = math.max(0.2, math.min((PLANK_W - 10) / 302, logoRoom / 77.5))
    logo.xScale, logo.yScale = logoScale, logoScale
    local logoH = 77.5 * logoScale
    local columnTop = (H - (logoH + 10 + listH + 10 + 20)) * 0.5
    logo.x, logo.y = columnX, columnTop + logoH * 0.5
    local firstY = columnTop + logoH + 10 + PLANK_H * 0.5

    for i, item in ipairs(items) do
      local plank = display.newGroup()
      pcMenu:insert(plank)
      display.newImageRect(plank, "images/gui/button/plank.png", PLANK_W, PLANK_H)
      local label = display.newText(plank, item[1], 0, 1, font, LABEL_SIZE)
      label:setFillColor(1, 1, 1)
      plank.restX, plank.restRotation = columnX, (i % 2 == 0) and 1.5 or -1.5
      plank.x, plank.y, plank.rotation = plank.restX, firstY + (i - 1) * (PLANK_H + PLANK_GAP), plank.restRotation
      function plank.tap()
        if storyboard.getCurrentSceneName() ~= "scenes.mainMenu" then
          return true
        end
        if storyboard.database.getSound() == 1 then
          audio.play(storyboard.gameDataTable.sounds.buttonSound)
        end
        item[2]()
        return true
      end
      plank:addEventListener("tap", plank)
      function plank.navCustomFocus(isFocused)
        transition.cancel(plank)
        transition.to(plank, {
          time = 140, rotation = isFocused and 4 or plank.restRotation, x = plank.restX - (isFocused and 14 or 0),
          xScale = isFocused and 1.06 or 1, yScale = isFocused and 1.06 or 1, transition = easing.outQuad,
        })
        if isFocused then
          label:setFillColor(0.9, 0.58, 0)
        else
          label:setFillColor(1, 1, 1)
        end
      end
    end

    local coinsY = firstY + listH - PLANK_H * 0.5 + 10 + 10
    local coinIcon = display.newImageRect(pcMenu, "images/gui/extra/coin.png", 16, 16)
    pcCoinText = display.newText(pcMenu, "", 0, coinsY, font, 16)
    pcCoinText:setFillColor(1, 1, 1)
    function pcCoinText.refresh()
      local entry = serverData.current()
      pcCoinText.text = tostring(entry and entry.profile and entry.profile.coins or 0)
      local lineW = 16 + 6 + pcCoinText.width
      coinIcon.x, coinIcon.y = columnX - lineW * 0.5 + 8, coinsY
      pcCoinText.x = coinIcon.x + 14 + pcCoinText.width * 0.5
    end

    pcAvatarGroup = display.newGroup()
    group:insert(pcAvatarGroup)
    pcAvatarGroup.x = (columnX - PLANK_W * 0.5) * 0.45
    pcAvatarGroup.y = H * 0.6
  end

  tutorialCover = display.newImageRect("images/gui/background/login.png", 480, 320)
  tutorialCover.x = display.contentWidth * 0.5
  tutorialCover.y = display.contentHeight * 0.5
  tutorialCover.alpha = 0
  group:insert(tutorialCover)
  tutorialText = display.newText(storyboard.localized.get("LoadingGame"), 0, 0, font, 54)
  tutorialText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  tutorialText.xScale, tutorialText.yScale = 0.5, 0.5
  tutorialText.x = display.contentWidth * 0.5
  tutorialText.y = display.contentHeight * 0.5
  tutorialText.alpha = 0
  group:insert(tutorialText)
end

local function newBadge(group, count, x, y)
  local font = storyboard.gameDataTable.font
  local badge = display.newImageRect("images/gui/mainMenu/alert.png", 20, 20)
  badge.x, badge.y = x, y
  group:insert(badge)
  local text = display.newText(count, 0, 0, font, 22 * 1.8)
  text:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
  text.xScale, text.yScale = 0.5, 0.5
  text.x, text.y = badge.x, badge.y
  group:insert(text)
  return badge, text
end

local function removeBadge(badge, text)
  if badge then
    display.remove(badge)
  end
  if text then
    display.remove(text)
  end
end

function scene:enterScene()
  local group = self.view

  local function updateMarketBadge()
    removeBadge(marketBadge, marketCount)
    marketBadge, marketCount = nil, nil
    local notification = storyboard.database.getMarketNotification()
    if notification.number > 0 then
      marketBadge, marketCount = newBadge(group, math.min(notification.number, 99),
        buttons.market.x + 34, buttons.market.y - 20)
    end
  end

  if pcMode.isPC then
    pcCoinText.refresh()
    for i = pcAvatarGroup.numChildren, 1, -1 do
      display.remove(pcAvatarGroup[i])
    end
    local avatar = storyboard.database.getAvatarData()
    local scale = 1.1
    local body = createSprite.changeSpriteAvatar(avatar[1], pcAvatarGroup, 0)
    local hat = createSprite.changeSpriteHat(avatar[2], pcAvatarGroup, 0)
    local boots = createSprite.changeSpriteBoots(avatar[4], pcAvatarGroup, 0)
    for _, part in ipairs({ body, hat, boots }) do
      part.xScale, part.yScale = scale, scale
      part.timeScale = 0.4
      part:play()
    end
    hat.y = -24 * scale
    hat:prepare("normal")
    hat:play()
  else
    updateMarketBadge()
  end

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.mainMenu" then
      for name, button in pairs(buttons) do
        if name ~= "market" then
          button.addListener()
        end
      end
    end
  end, 1)
  timer.performWithDelay(400, function()
    if storyboard.getCurrentSceneName() == "scenes.mainMenu" then
      buttons.market.addListener()
    end
  end, 1)

  storyboard.comm.setCallback(function(packet)
    scene.onSocialMessage(packet)
  end)
  storyboard.tcpSocial.setReceiveInterval(nil)

  storyboard.enterMainMenu = true
end

function scene:exitScene()
  for _, button in pairs(buttons) do
    button.removeListener()
  end
  if pcAvatarGroup then
    for i = pcAvatarGroup.numChildren, 1, -1 do
      display.remove(pcAvatarGroup[i])
    end
  end
  removeBadge(marketBadge, marketCount)
  marketBadge, marketCount = nil, nil
  tutorialCover.alpha = 0
  tutorialText.alpha = 0
  storyboard.comm.setCallback(function() end)
end

function scene:destroyScene()
  buttons = {}
  pcMenu, pcAvatarGroup, pcCoinText = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
