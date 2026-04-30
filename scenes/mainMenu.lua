---------------------------------------------------------------------------------
-- mainMenu.lua — Main hub scene (play, settings, social, market, etc.)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

local rewardedVideoModule = require("modules.rewardedVideoModule")
local videoModule = require("modules.videoModule")
local createSpriteModule = require("modules.createSprite")

-- Module-level variables
local playButton
local settingsButton
local rankingButton
local marketButton
local socialButton
local earnCoinsButton
local dinodashButton
local videoAdButton
local socialAlertImage
local socialAlertText
local alertRef
local delayTimer
local marketAlertImage
local marketAlertText
local socialConnected = false
local trackValue = 0
local showError
local videoHideTimer
local loadingText       -- tutorial overlay text
local loadingBackground -- tutorial overlay bg
local socialCallback
local updateMoneyFn
local showCoinDisplayFn
local checkVideoAvailableFn

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
  local view = self.view
  local gui = require("modules.gui")
  local backgroundImage
  local isConnected = false
  socialConnected = false
  local textColor = { 1, 1, 1, 1 }
  local font = storyboard.gameDataTable.font
  trackValue = 0

  -- Ensure player info is loaded
  if not storyboard.playerInfo then
    storyboard.playerInfo = storyboard.database.getPlayerInformation()
  end

  ---------------------------------------------------------------------------
  -- Tutorial: play on map 38 in single-player
  ---------------------------------------------------------------------------
  local function tutorialPlay()
    storyboard.gameDataTable.playerListNames = {}
    storyboard.gameDataTable.playerListNames[1] = {
      username = storyboard.playerInfo.username,
      avatar = storyboard.database.getAvatarData()
    }
    storyboard.gameType = 1
    storyboard.gameDataTable.mapSelected = 38
    storyboard.gotoScene("scenes.gamePlay")
  end

  ---------------------------------------------------------------------------
  -- Go to register (from guest alert)
  ---------------------------------------------------------------------------
  local function goToRegister()
    storyboard.gotoScene("scenes.registerScene")
    storyboard.purgeScene("scenes.mainMenu")
  end

  ---------------------------------------------------------------------------
  -- Alert handler for "must register" prompts
  ---------------------------------------------------------------------------
  local function alertHandler(event)
    if event.action == "clicked" then
      alertRef = nil
      if event.index == 1 then
        -- Cancel
      elseif event.index == 2 then
        timer.performWithDelay(200, goToRegister, 1)
      end
    end
  end

  ---------------------------------------------------------------------------
  -- Show error / info alerts
  ---------------------------------------------------------------------------
  showError = function(code)
    if alertRef then
      native.cancelAlert(alertRef)
      alertRef = nil
    end
    if code == 1 then
      alertRef = native.showAlert("Trail",
        "You must create a user to add friends.",
        { "Cancel", "Register" }, alertHandler)
    elseif code == 2 then
      alertRef = native.showAlert("Trail",
        "You must create a user to edit your avatar.",
        { "Cancel", "Register" }, alertHandler)
    elseif code == 3 then
      alertRef = native.showAlert(
        storyboard.localized.get("No connection"),
        storyboard.localized.get("Trying to reconnect"),
        { storyboard.localized.get("Ok") })
    elseif code == 4 then
      alertRef = native.showAlert("Trail",
        "You must create a user to view the highscore table.",
        { "Cancel", "Register" }, alertHandler)
    elseif code == 5 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.market, { "Ok" })
    elseif code == 6 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.ranking, { "Ok" })
    elseif code == 7 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.friends, { "Ok" })
    elseif code == 8 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.server, { "Ok" })
    elseif code == 9 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.earnCoins, { "Ok" })
    elseif code == 10 then
      alertRef = native.showAlert("Server message",
        storyboard.errorTable.dinodash, { "Ok" })
    elseif code == 11 then
      alertRef = native.showAlert("Server message",
        "Waiting for server... Try again.", { "Ok" })
    end
  end

  ---------------------------------------------------------------------------
  -- Button handlers
  ---------------------------------------------------------------------------
  local function onPlayTap(event)
    if storyboard.config.tutorial then
      if not storyboard.playerInfo then
        showError(11)
        return
      end
      -- Show loading overlay for tutorial
      if loadingBackground then
        view:insert(loadingBackground)
        loadingBackground.alpha = 1
      end
      if loadingText then
        view:insert(loadingText)
        loadingText.alpha = 1
      end
      timer.performWithDelay(100, tutorialPlay, 1)
    else
      storyboard.gotoScene("scenes.playMenu")
    end
    return true
  end

  local function onSettingsTap(event)
    storyboard.gotoScene("scenes.settings")
    return true
  end

  local function onRankingTap(event)
    native.showAlert("Offline Mode", "Offline mode unavailable", { "Ok" })
  end

  local function onFriendsTap(event)
    native.showAlert("Offline Mode", "Offline mode unavailable", { "Ok" })
  end

  local function onMarketTap(event)
    storyboard.gotoScene("scenes.marketplace")
  end

  local function onEarnCoinsTap(event)
    native.showAlert("Offline Mode", "Offline mode unavailable", { "Ok" })
  end

  local function onDinodashTap(event)
    native.showAlert("Offline Mode", "Offline mode unavailable", { "Ok" })
  end

  local function onVideoAdTap(event)
    native.showAlert("Offline Mode", "Offline mode unavailable", { "Ok" })
  end

  ---------------------------------------------------------------------------
  -- Social TCP callback
  ---------------------------------------------------------------------------
  socialCallback = function(data)
    if data.m == "l" then
      if data.a == 1 then
        isConnected = true
      end
      socialConnected = true
      return true
    end
    if socialConnected then
      return true
    else
      return false
    end
  end

  ---------------------------------------------------------------------------
  -- Start social TCP if registered user
  ---------------------------------------------------------------------------
  if storyboard.gameDataTable.tryIt == 0 then
    storyboard.playerInfo = storyboard.database.getPlayerInformation()
    storyboard.comm.startSocialTCP(socialCallback)
  end

  ---------------------------------------------------------------------------
  -- UI: Background
  ---------------------------------------------------------------------------
  backgroundImage = display.newImageRect("images/gui/background/background_mainMenu.png", 480, 320)
  backgroundImage.x = display.contentWidth * 0.5
  backgroundImage.y = display.contentHeight * 0.5
  view:insert(backgroundImage)

  ---------------------------------------------------------------------------
  -- UI: Buttons
  ---------------------------------------------------------------------------
  playButton = gui.newButton({
    image = "images/gui/button/play.png",
    width = 120,
    height = 60,
    onRelease = onPlayTap,
    x = display.contentWidth * 0.5,
    y = display.contentHeight * 0.575,
    displayGroup = view
  })

  settingsButton = gui.newButton({
    image = "images/gui/button/settings.png",
    width = 50,
    height = 50,
    onRelease = onSettingsTap,
    x = 30,
    y = display.contentHeight - 30,
    displayGroup = view
  })

  rankingButton = gui.newButton({
    image = "images/gui/button/ranking.png",
    width = 50,
    height = 50,
    onRelease = onRankingTap,
    x = 85,
    y = display.contentHeight - 30,
    displayGroup = view
  })

  socialButton = gui.newButton({
    image = "images/gui/button/social.png",
    width = 50,
    height = 50,
    onRelease = onFriendsTap,
    x = 140,
    y = display.contentHeight - 30,
    displayGroup = view
  })

  marketButton = gui.newButton({
    image = "images/gui/button/market.png",
    width = 80,
    height = 50,
    onRelease = onMarketTap,
    x = display.contentWidth - 50,
    y = display.contentHeight - 30,
    displayGroup = view
  })

  earnCoinsButton = gui.newButton({
    image = "images/gui/button/earnCoins.png",
    width = 50,
    height = 50,
    onRelease = onEarnCoinsTap,
    x = display.contentWidth - 120,
    y = display.contentHeight - 30,
    displayGroup = view
  })

  dinodashButton = gui.newButton({
    image = "images/gui/button/FRA.png",
    width = 80,
    height = 50,
    onRelease = onDinodashTap,
    x = display.contentWidth - 190,
    y = display.contentHeight - 30,
    displayGroup = view
  })
  dinodashButton.isVisible = false

  -- Video ad button with coin reward text
  local embossColor = {
    highlight = { r = 0, g = 0, b = 0 },
    shadow = { r = 0, g = 0, b = 0 }
  }
  videoAdButton = gui.newButton({
    image = "images/gui/button/videoAd.png",
    width = 75,
    height = 45,
    text = {
      string = "+" .. 250,
      x = 10,
      y = 10,
      size = 16,
      color = { 0.23529411764705882, 1, 0 },
      embossColor = embossColor
    },
    onRelease = onVideoAdTap,
    x = display.contentWidth - 42,
    y = 30,
    displayGroup = view
  })
  videoAdButton.showButton(false)

  ---------------------------------------------------------------------------
  -- Update avatar display
  ---------------------------------------------------------------------------
  -- Avatar preview will be rendered in enterScene to avoid duplicate creations

  ---------------------------------------------------------------------------
  -- Tutorial loading overlay (shown when config.tutorial is true)
  ---------------------------------------------------------------------------
  if storyboard.config.tutorial then
    loadingBackground = display.newImageRect("images/gui/background/login.png", 480, 320)
    loadingBackground.x = display.contentWidth * 0.5
    loadingBackground.y = display.contentHeight * 0.5
    view:insert(loadingBackground)
    loadingBackground.alpha = 0

    loadingText = display.newText(
      storyboard.localized.get("LoadingGame"),
      0, 0, font, 54
    )
    loadingText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    loadingText.xScale = 0.5
    loadingText.yScale = 0.5
    loadingText.x = display.contentWidth * 0.5
    loadingText.y = display.contentHeight * 0.5
    view:insert(loadingText)
    loadingText.alpha = 0
  end
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
  local view = self.view
  local font = storyboard.gameDataTable.font
  local fontSize = 22
  local textColor = { 1, 1, 1, 1 }
  local canGoBack = true
  local moneyText = nil
  local coinIcon = nil
  local videoShown = false

  createSpriteModule.renderAvatar(storyboard.database.getAvatarData(), {
    parent = view,
    x = 80,
    y = 170,
    scale = 0.9,
  })

  ---------------------------------------------------------------------------
  -- Update money display
  ---------------------------------------------------------------------------
  local function updateMoney()
    if storyboard.getCurrentSceneName() == "scenes.mainMenu" then
      local money = storyboard.database.getMoney()
      if money == nil then money = 100000 end
      if moneyText then
        moneyText:removeSelf()
        moneyText = nil
      end
      moneyText = display.newText(money, 0, 0, font, 39)
      moneyText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
      moneyText.xScale = 0.5
      moneyText.yScale = 0.5
      moneyText.anchorX = 0
      moneyText.anchorY = 0.5
      moneyText.x = 30
      moneyText.y = 25
      view:insert(moneyText)
    end
  end
  updateMoneyFn = updateMoney

  ---------------------------------------------------------------------------
  -- Coin icon
  ---------------------------------------------------------------------------
  coinIcon = display.newImageRect("images/gui/extra/coin.png", 16, 16)
  coinIcon.anchorX = 0
  coinIcon.anchorY = 0.5
  coinIcon.x = 10
  coinIcon.y = 25
  view:insert(coinIcon)
  if moneyText then
    view:insert(moneyText)
  end

  ---------------------------------------------------------------------------
  -- Show/hide coin display
  ---------------------------------------------------------------------------
  local function showCoinDisplay(visible)
    if moneyText then
      moneyText.isVisible = visible
    end
    coinIcon.isVisible = visible
  end
  showCoinDisplayFn = showCoinDisplay
  showCoinDisplay(false)

  ---------------------------------------------------------------------------
  -- Show dino dash button if enabled
  ---------------------------------------------------------------------------
  if storyboard.showDinoDash then
    dinodashButton.isVisible = true
    if storyboard.database.shouldShowFunRunPopup() then
      storyboard.database.haveShownFunRunPopup()
      storyboard.showOverlay("scenes.dinodash", { isModal = true })
    end
  end

  ---------------------------------------------------------------------------
  -- Check if rewarded video is available
  ---------------------------------------------------------------------------
  local function checkVideoAvailable()
    if videoModule.isVideoAvailable() then
      if rewardedVideoModule.shouldShowMainMenuRewardedVideo() then
        if not videoShown then
          videoShown = true
          videoAdButton.showButton(true)
        end
      end
    end
  end
  checkVideoAvailableFn = checkVideoAvailable
  checkVideoAvailable()
  Runtime:addEventListener("loadedVideoEvent", checkVideoAvailableFn)

  ---------------------------------------------------------------------------
  -- Add button listeners (delayed to avoid race conditions)
  ---------------------------------------------------------------------------
  local function addButtonListeners()
    if storyboard.getCurrentSceneName() == "scenes.mainMenu" then
      rankingButton.addListener()
      socialButton.addListener()
      playButton.addListener()
      settingsButton.addListener()
      earnCoinsButton.addListener()
      dinodashButton.addListener()
      videoAdButton.addListener()
    end
  end

  local function addMarketListener()
    if storyboard.getCurrentSceneName() == "scenes.mainMenu" then
      marketButton.addListener()
    end
  end

  ---------------------------------------------------------------------------
  -- Notification badge for social button
  ---------------------------------------------------------------------------
  local function updateNotificationBadge()
    local count = storyboard.comm.getNumberOfNotifications()
    if count > 0 then
      if count > 99 then count = 99 end
      if socialAlertImage then
        socialAlertImage:removeSelf()
        socialAlertImage = nil
      end
      socialAlertImage = display.newImageRect("images/gui/mainMenu/alert.png", 20, 20)
      socialAlertImage.x = socialButton.x + 23
      socialAlertImage.y = socialButton.y - 20
      view:insert(socialAlertImage)

      if socialAlertText then
        socialAlertText:removeSelf()
        socialAlertText = nil
      end
      socialAlertText = display.newText(count, 0, 0, font, fontSize * 1.8)
      socialAlertText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
      socialAlertText.xScale = 0.5
      socialAlertText.yScale = 0.5
      socialAlertText.x = socialAlertImage.x
      socialAlertText.y = socialAlertImage.y
      view:insert(socialAlertText)
    else
      if socialAlertImage then
        socialAlertImage:removeSelf(); socialAlertImage = nil
      end
      if socialAlertText then
        socialAlertText:removeSelf(); socialAlertText = nil
      end
    end
  end
  updateNotificationBadge()

  ---------------------------------------------------------------------------
  -- Notification badge for market button
  ---------------------------------------------------------------------------
  local function updateMarketBadge()
    local data = storyboard.database.getMarketNotification()
    local count = data.number
    if count > 0 then
      if count > 99 then data.number = 99 end
      if marketAlertImage then
        marketAlertImage:removeSelf(); marketAlertImage = nil
      end
      marketAlertImage = display.newImageRect("images/gui/mainMenu/alert.png", 20, 20)
      marketAlertImage.x = marketButton.x + 34
      marketAlertImage.y = marketButton.y - 20
      view:insert(marketAlertImage)

      if marketAlertText then
        marketAlertText:removeSelf(); marketAlertText = nil
      end
      marketAlertText = display.newText(data.number, 0, 0, font, fontSize * 1.8)
      marketAlertText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
      marketAlertText.xScale = 0.5
      marketAlertText.yScale = 0.5
      marketAlertText.x = marketAlertImage.x
      marketAlertText.y = marketAlertImage.y
      view:insert(marketAlertText)
    else
      if marketAlertImage then
        marketAlertImage:removeSelf(); marketAlertImage = nil
      end
      if marketAlertText then
        marketAlertText:removeSelf(); marketAlertText = nil
      end
    end
  end
  updateMarketBadge()

  ---------------------------------------------------------------------------
  -- Server / social callback for enter scene
  ---------------------------------------------------------------------------
  local function enterSceneCallback(response)
    -- Update social notification badge on any message
    if response.m then
      updateNotificationBadge()
    end
    -- Handle video reward response
    if response.m == "x" then
      updateMoney()
      videoHideTimer = timer.performWithDelay(1500, function()
        showCoinDisplay(false)
      end, 1)
    end
    -- Forward to social callback
    socialConnected = socialCallback(response)
  end

  timer.performWithDelay(200, addButtonListeners, 1)
  timer.performWithDelay(400, addMarketListener, 1)
  storyboard.comm.setCallback(enterSceneCallback)

  ---------------------------------------------------------------------------
  -- Connection check after delay
  ---------------------------------------------------------------------------
  local function checkConnection()
    if storyboard.gameDataTable.tryIt == 0 then
      if not alertRef then
        if not socialConnected then
          -- could attempt reconnection
        end
      end
    end
  end
  delayTimer = timer.performWithDelay(6000, checkConnection, 1)

  storyboard.tcpSocial.setReceiveInterval(nil)

  ---------------------------------------------------------------------------
  -- Simulator bot auto-play (debug)
  ---------------------------------------------------------------------------
  timer.performWithDelay(2000, function()
    if isSimulator then
      if storyboard.gameDataTable.bot then
        storyboard.gotoScene("scenes.playMenu")
      end
    end
  end, 1)

  ---------------------------------------------------------------------------
  -- Handle old version redirect
  ---------------------------------------------------------------------------
  if storyboard.oldVersion then
    storyboard.gotoUpdateScene = true
    storyboard.gotoScene("scenes.updateScene", "fade", 200)
  end

  storyboard.enterMainMenu = true

  -- Show server error if flagged
  if storyboard.errorTable.server then
    if storyboard.errorTable.showServerError then
      storyboard.errorTable.showServerError = false
      showError(8)
    end
  end

  -- Handle post-lobby redirect
  if storyboard.config.openPostLobby then
    storyboard.totalGamesPlayed = 3
    storyboard.database.setEarnCoins({})
    storyboard.gotoScene("scenes.postLobby")
  end
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
  playButton.removeListener()
  settingsButton.removeListener()
  rankingButton.removeListener()
  marketButton.removeListener()
  socialButton.removeListener()
  earnCoinsButton.removeListener()
  dinodashButton.removeListener()
  videoAdButton.removeListener()

  Runtime:removeEventListener("loadedVideoEvent", checkVideoAvailableFn)

  if socialAlertImage then
    socialAlertImage:removeSelf(); socialAlertImage = nil
  end
  if socialAlertText then
    socialAlertText:removeSelf(); socialAlertText = nil
  end
  if marketAlertImage then
    marketAlertImage:removeSelf(); marketAlertImage = nil
  end
  if marketAlertText then
    marketAlertText:removeSelf(); marketAlertText = nil
  end
  if alertRef then
    native.cancelAlert(alertRef); alertRef = nil
  end
  if delayTimer then
    timer.cancel(delayTimer); delayTimer = nil
  end
  if loadingText then
    loadingText:removeSelf(); loadingText = nil
  end
  if loadingBackground then
    loadingBackground:removeSelf(); loadingBackground = nil
  end
  if videoHideTimer then
    timer.cancel(videoHideTimer); videoHideTimer = nil
  end

  showCoinDisplayFn(false)
  storyboard.comm.setCallback(function(response) end)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
  socialCallback = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
