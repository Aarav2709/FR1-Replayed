-- main menu.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local createSprite = require("modules.createSprite")

local scene = storyboard.newScene()

local buttons = {}
local marketBadge, marketCount
local tutorialCover, tutorialText
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

  updateMarketBadge()

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
  removeBadge(marketBadge, marketCount)
  marketBadge, marketCount = nil, nil
  tutorialCover.alpha = 0
  tutorialText.alpha = 0
  storyboard.comm.setCallback(function() end)
end

function scene:destroyScene()
  buttons = {}
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
