-- market.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local accessories = require("modules.accessories")
local createSprite = require("modules.createSprite")
local tableViewHorizontal = require("modules.tableViewHorizontal")
local loadingAnimation = require("modules.loadingAnimation")

local scene = storyboard.newScene()

local AVATARS, HATS, ITEMS, BOOTS = 1, 2, 3, 4
local GOLD_FOX_ID, DIAMOND_DOE_ID = 199, 198

local homeButton, getMoreButton, buyButton
local categoryTabs = {}
local packButtons = {}
local loader
local avatar
local savedAvatar
local onFrame, onKey, addListeners, cleanUp

local function isNewItem(itemId)
  for _, id in ipairs(storyboard.config.newItems.items) do
    if itemId == id then
      return true
    end
  end
  return false
end

function scene:createScene()
  local extra = display.contentWidth - 480
  local view = display.newGroup()
  self.view:insert(view)
  view.x = extra
  local font = storyboard.gameDataTable.font
  local FONT_SIZE = 22
  local WHITE = { 1, 1, 1, 1 }
  local buttonSound = storyboard.gameDataTable.sounds.buttonSound
  local leftBar = display.newGroup()
  local packGroup = display.newGroup()
  local body, boots, hat
  local nameText, coinsText, statusText, packText
  local category = AVATARS
  local selected = 1
  local owned = {}
  local coins = 0
  local currentList
  local carousel
  local ownsGoldFox, ownsDiamondDoe = false, false
  local itemTrail, shownTrail, trailTimer = 1, 1, nil
  local panelState = 1

  avatar = storyboard.database.getAvatarData()
  savedAvatar = {}
  for i = 1, #avatar do
    savedAvatar[i] = avatar[i]
  end
  selected = avatar[AVATARS]

  local function playButtonSound()
    if storyboard.database.getSound() == 1 then
      audio.play(buttonSound)
    end
  end

  local function owns(itemId)
    for _, id in ipairs(owned[category]) do
      if id == itemId then
        return true
      end
    end
    return false
  end

  local function selectList(newCategory)
    if newCategory == AVATARS then
      currentList = accessories.getAvatarList()
    elseif newCategory == HATS then
      currentList = accessories.getHatList(avatar[AVATARS])
    elseif newCategory == ITEMS then
      currentList = accessories.getItemList(avatar[AVATARS])
    elseif newCategory == BOOTS then
      currentList = accessories.getBootsList(avatar[AVATARS])
    end
  end

  local function bringAvatarToFront()
    if body then
      view:insert(body)
    end
    if hat then
      view:insert(hat)
    end
    if boots then
      view:insert(boots)
    end
  end

  local function spawnTrailParticle()
    local particle = createSprite.changeSpriteItem(itemTrail, view, 0)
    particle:setFrame(math.random(5))
    particle.x = 290
    particle.y = 120 + math.random(-20, 20)
    particle.xScale, particle.yScale = 0.98, 0.98
    transition.to(particle, { time = 200, x = 236 })
    transition.to(particle, {
      time = 500, delay = 200, x = 180, alpha = 0, onComplete = function() display.remove(particle) end,
    })
    bringAvatarToFront()
  end

  local function updateTrail()
    if shownTrail ~= itemTrail then
      shownTrail = itemTrail
      if trailTimer then
        timer.cancel(trailTimer)
      end
      if itemTrail > 1 then
        trailTimer = timer.performWithDelay(200, spawnTrailParticle, 0)
      end
    end
  end

  local function showPart(part, index)
    if part == AVATARS then
      if body then
        display.remove(body)
      end
      body = createSprite.changeSpriteAvatar(index, view, 0)
      body.x, body.y = 290, 120
      body.xScale, body.yScale = 0.5, 0.5
      body.timeScale = 0.4
      body:play()
    elseif part == HATS then
      if hat then
        display.remove(hat)
      end
      hat = createSprite.changeSpriteHat(index, view, 0)
      hat.x, hat.y = 290, 108
      hat.xScale, hat.yScale = 0.5, 0.5
      hat.timeScale = 0.4
      body:prepare("normal")
      body:play()
      hat:prepare("normal")
      hat:play()
    elseif part == ITEMS then
      itemTrail = index
      updateTrail()
    elseif part == BOOTS then
      if boots then
        display.remove(boots)
      end
      boots = createSprite.changeSpriteBoots(index, view, 0)
      boots.x, boots.y = 290, 120
      boots.xScale, boots.yScale = 0.5, 0.5
      boots.timeScale = 0.4
      boots:play()
    end
    bringAvatarToFront()
  end

  local function showItem(part, index)
    selectList(part)
    if nameText then
      nameText.text = " "
      nameText = nil
    end
    nameText = display.newText(currentList[index][1], 0, 0, font, FONT_SIZE * 2)
    nameText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    nameText.xScale, nameText.yScale = 0.5, 0.5
    nameText.x, nameText.y = 290, 280
    view:insert(nameText)
    showPart(part, index)
    if part ~= BOOTS then
      showPart(BOOTS, avatar[BOOTS])
    end
    if part ~= HATS then
      showPart(HATS, avatar[HATS])
    end
  end

  local function showCoins()
    if coinsText then
      coinsText.text = ""
      coinsText = nil
    end
    coinsText = display.newText(coins, 0, 0, font, FONT_SIZE * 2)
    coinsText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    coinsText.xScale, coinsText.yScale = 0.5, 0.5
    coinsText.anchorX, coinsText.anchorY = 0, 0.5
    coinsText.x, coinsText.y = 140 - extra, 45
    view:insert(coinsText)
  end

  local function selectTab(tab)
    for i = 1, 4 do
      categoryTabs[i].alpha = i == tab and 1 or 0.05
    end
  end

  local function showAvatar()
    showItem(AVATARS, avatar[AVATARS])
    showPart(HATS, avatar[HATS])
    showPart(ITEMS, avatar[ITEMS])
    showPart(BOOTS, avatar[BOOTS])
  end

  local function setOwned(isOwned)
    if storyboard.getCurrentSceneName() == "scenes.marketplace" then
      if isOwned then
        buyButton.text:setFillColor(0.788235294117647, 0.7058823529411765, 0.5490196078431373)
      else
        buyButton.text:setFillColor(0.1411764705882353, 0.0784313725490196, 0.06274509803921569)
      end
      buyButton.isVisible = not isOwned
    end
  end

  local function onPanelMoved()
    if panelState == 3 then
      panelState = 2
    elseif panelState == 4 then
      panelState = 1
    end
  end

  local function toggleCoinPacks()
    if panelState == 2 then
      panelState = 4
      transition.to(view, { time = 200, y = 0, onComplete = onPanelMoved })
    elseif panelState == 1 then
      panelState = 3
      packText.text = storyboard.localized.get("SelectNumberOfCoins")
      transition.to(view, { time = 200, y = 90, onComplete = onPanelMoved })
    end
  end

  local function onHome()
    local previous = storyboard.getPrevious()
    if previous == "scenes.postLobby" then
      previous = "scenes.mainMenu"
    end
    storyboard.gotoScene(previous)
    storyboard.purgeScene("scenes.marketplace")
  end

  local buildCarousel

  local function openCategory(tab)
    if panelState == 2 then
      toggleCoinPacks()
    end
    if category ~= tab then
      setOwned(true)
      selectTab(tab)
      playButtonSound()
      showPart(category, avatar[category])
      category = tab
      selected = avatar[tab]
      showItem(category, avatar[tab])
      buildCarousel()
    end
  end

  local function onBuy()
    local itemId = accessories.getItemId(category, selected)
    if coins < accessories.getItem(itemId).price then
      toggleCoinPacks()
      packText.text = storyboard.localized.get("NotEnoughCoins")
    else
      storyboard.comm.setCallback(scene.onPacket)
      storyboard.comm.buyItem(itemId)
    end
  end

  local function onScrollEnd(index)
    selected = index
    showItem(category, selected)
    local isOwned = owns(accessories.getItemId(category, selected))
    setOwned(isOwned)
    if isOwned then
      avatar[category] = selected
    else
      avatar[category] = savedAvatar[category]
    end
  end

  function buildCarousel()
    if carousel then
      carousel:cleanUp()
      carousel = nil
    end
    local entries = {}
    for i = 1, #currentList do
      local entry = currentList[i]
      local imageName
      if entry[2] > 199 and i == 1 then
        imageName = "transparent"
      else
        imageName = entry[4]
      end
      local image = "images/gui/market/accessories/" .. imageName .. ".png"
      if imageName == "goldfox" then
        if ownsGoldFox then
          local n = #entries + 1
          entries[n] = { image = image, price = entry[3], bought = owns(entry[2]), index = i, tableIndex = n }
        end
      elseif imageName == "diamondDoe" then
        if ownsDiamondDoe then
          local n = #entries + 1
          entries[n] = { image = image, price = entry[3], bought = owns(entry[2]), index = i, tableIndex = n }
        end
      else
        entries[i] = {
          image = image, price = entry[3], bought = owns(entry[2]), newItem = isNewItem(entry[2]),
          index = i, tableIndex = i,
        }
      end
    end
    carousel = tableViewHorizontal.newList({
      data = entries, onRelease = function() end, onScrollEnd = onScrollEnd,
      left = 250, right = 0, width = 80, height = 80,
      callback = function(entry)
        local label = display.newGroup()
        local price = " "
        if not entry.bought then
          price = entry.price
          local priceBackground = display.newImageRect("images/gui/market/priceBackground.png", 53, 13)
          priceBackground.x, priceBackground.y = 40, 82
          label:insert(priceBackground)
        end
        local priceText = display.newText(price, 0, 0, font, 30)
        priceText:setFillColor(0.3607843137254902, 0.21568627450980393, 0.06274509803921569)
        priceText.xScale, priceText.yScale = 0.5, 0.5
        priceText.x, priceText.y = 35, 81
        label:insert(priceText)
        return label
      end,
    })
    carousel.anchorX, carousel.anchorY = 0, 1
    carousel.anchorChildren = true
    carousel.x, carousel.y = 145, 264
    view:insert(carousel)
    carousel:startAt(selected)
    view:insert(leftBar)
    view:insert(packGroup)
  end

  function scene.onPacket(packet)
    if storyboard.getCurrentSceneName() ~= "scenes.marketplace" then
      return
    end
    if packet.m == "n" then
      if packet.p then
        owned = storyboard.database.getItems()
        for _, id in ipairs(owned[AVATARS]) do
          if id == GOLD_FOX_ID then
            ownsGoldFox = true
          elseif id == DIAMOND_DOE_ID then
            ownsDiamondDoe = true
          end
        end
        coins = storyboard.database.getMoney()
        setOwned(true)
        setOwned(owns(accessories.getItemId(category, selected)))
        buildCarousel()
        showAvatar()
        showCoins()
        statusText.isVisible = false
        addListeners()
      end
    elseif packet.m == "o" then
      if packet.a == 1 then
        coins = storyboard.database.getMoney()
        showCoins()
        owned = storyboard.database.getItems()
        avatar[category] = accessories.getItem(packet.itemId).item
        setOwned(owns(accessories.getItemId(category, selected)))
        buildCarousel()
        statusText.text = ""
      elseif packet.a == 2 then
        statusText.isVisible = true
        statusText.text = storyboard.localized.get("CantAffordItem")
      elseif packet.a == 3 then
        statusText.isVisible = true
        statusText.text = storyboard.localized.get("AlreadyOwnItem")
      elseif packet.a == 4 then
        statusText.isVisible = true
        statusText.text = storyboard.localized.get("ErrorCantBuyItem")
      end
    elseif packet.m == "A" then
      coins = storyboard.database.getMoney()
      showCoins()
    end
  end

  function cleanUp()
    itemTrail = 0
    if trailTimer then
      timer.cancel(trailTimer)
    end
    if carousel then
      carousel:cleanUp()
      carousel = nil
    end
  end

  local background = display.newImageRect("images/gui/background/marketPlace.png", 380, 410)
  background.anchorX, background.anchorY = 1, 0
  background.x = 480
  background.y = -90
  view:insert(background)
  if extra > 0 then
    local sheet = graphics.newImageSheet("images/gui/background/marketPlace.png", {
      frames = { { x = 4, y = 0, width = 235, height = 250 }, { x = 140, y = 250, width = 10, height = 570 } },
      sheetContentWidth = 760, sheetContentHeight = 820,
    })
    local lower = display.newImageRect(view, sheet, 2, extra + 75, 285)
    lower.anchorX, lower.anchorY = 1, 0
    lower.x, lower.y = 175, 35
    local right = 102
    while right > 100 - extra do
      local awning = display.newImageRect(view, sheet, 1, 117.5, 125)
      awning.anchorX, awning.anchorY = 1, 0
      awning.x, awning.y = right, -90
      right = right - 117.5
    end
  end
  local leftBarBackground = display.newImageRect("images/gui/background/marketLeftBar.png", 100, 410)
  leftBarBackground.anchorX, leftBarBackground.anchorY = 0, 0
  leftBarBackground.x, leftBarBackground.y = 0, -90
  leftBar.x = -extra
  leftBar:insert(leftBarBackground)
  statusText = display.newText(storyboard.localized.get("Loading"), 0, 0, font, 40)
  statusText:setFillColor(1, 1, 1)
  statusText.xScale, statusText.yScale = 0.5, 0.5
  statusText.x = display.contentWidth * 0.5 - extra
  statusText.y = display.contentHeight * 0.95
  view:insert(statusText)

  packText = display.newText(storyboard.localized.get("SelectNumberOfCoins"), 0, 0, font, 15)
  packText.x = display.contentWidth * 0.5
  packText.y = 4
  packText:setFillColor(0, 0, 0)
  packGroup:insert(packText)
  loader = loadingAnimation.newLoadingAnimation()
  packGroup:insert(loader.displayGroup)
  loader.displayGroup.x = display.contentWidth * 0.5
  loader.displayGroup.y = 35
  local PACK_IMAGES = { 200, 500, 2000, 5000 }

  local function onPurchased(result)
    if packText then
      if result.message then
        packText.text = result.message
        if result.value and result.value > -1 then
          coins = result.value
          showCoins()
        end
      end
    end
  end

  local function buyPack(pack)
    packText.text = storyboard.localized.get("Purchasing")
    timer.performWithDelay(600, function()
      if storyboard.getCurrentSceneName() == "scenes.marketplace" then
        storyboard.comm.addMoney(pack, onPurchased)
      end
    end, 1)
  end

  local function showPacks()
    local priceTexts = {}
    for pack = 1, 4 do
      packButtons[pack] = gui.newButton({
        image = "images/transparent.png", over = "images/gui/market/buyOver" .. PACK_IMAGES[pack] .. ".png",
        onRelease = function()
          buyPack(pack)
          return true
        end,
        width = 95, height = 40, x = 0, y = 0, displayGroup = packGroup,
      })
      local shift = pack > 1 and extra or 0
      packButtons[pack].setPosition(119.5 * pack - 60 + shift, 36)
      packButtons[pack].addListener()
      packGroup:insert(packButtons[pack])
      packButtons[pack].isVisible = false
      priceTexts[pack] = display.newText(storyboard.localized.get("Loading"), 0, 0, font, 18)
      priceTexts[pack]:setFillColor(0, 0, 0)
      priceTexts[pack].x = 120 * pack - 60 + shift
      priceTexts[pack].y = 68
      packGroup:insert(priceTexts[pack])
    end
    loader.stopLoader()
    if storyboard.config.freeCoinPacks then
      for pack = 1, 4 do
        packButtons[pack].isVisible = true
        priceTexts[pack].text = storyboard.localized.get("Free")
      end
    else
      for pack = 1, 4 do
        priceTexts[pack].isVisible = false
      end
      packText.text = storyboard.localized.get("InAppNotSupported")
    end
  end
  timer.performWithDelay(100, function()
    if storyboard.getCurrentSceneName() == "scenes.marketplace" then
      showPacks()
    end
  end, 1)
  view:insert(packGroup)
  packGroup.x = -extra
  packGroup.y = -80

  local coinIcon = display.newImageRect("images/gui/extra/coin.png", 15, 15)
  coinIcon.anchorX, coinIcon.anchorY = 0, 0.5
  coinIcon.x, coinIcon.y = 120 - extra, 45
  view:insert(coinIcon)

  local TAB_IMAGES = {
    "images/gui/market/categorySelected.png", "images/gui/market/categorySelected.png",
    "images/gui/market/categorySelected_.png", "images/gui/market/categorySelected_.png",
  }
  local TAB_WIDTHS = { 87, 87, 86, 86 }
  local TAB_Y = { 36, 90, 144, 199 }
  for tab = 1, 4 do
    local marker = display.newImageRect(TAB_IMAGES[tab], TAB_WIDTHS[tab], 50)
    marker.anchorX, marker.anchorY = 0, 0
    marker.tap = function() openCategory(tab) end
    marker.x, marker.y = 5, TAB_Y[tab]
    marker.alpha = 0.001
    leftBar:insert(marker)
    categoryTabs[tab] = marker
  end
  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = onHome,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = leftBar,
  })
  getMoreButton = gui.newButton({
    image = "images/transparent.png", over = "images/gui/button/inAppOver.png",
    text = {
      string = storyboard.localized.get("GetMore"), size = 20, languageSizes = { fr = 14, es = 16, ja = 10, de = 16 },
      x = -15, color = { 0.3176470588235294, 0.15294117647058825, 0 },
    },
    width = 121, height = 45, onRelease = toggleCoinPacks, x = 413.5, y = 56.5, displayGroup = view,
  })
  buyButton = gui.newButton({
    image = "images/gui/button/buy.png",
    text = {
      string = storyboard.localized.get("Buy"), size = 35, languageSizes = { fr = 23, es = 22, ja = 25, de = 25 },
      color = { 0.39215686274509803, 0.39215686274509803, 0.39215686274509803 },
    },
    width = 79, height = 50, onRelease = onBuy, x = 430, y = 290, displayGroup = view,
  })
  view:insert(leftBar)

  selectTab(AVATARS)
  selectList(AVATARS)
  setOwned(true)
  storyboard.comm.setCallback(scene.onPacket)
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false
  storyboard.tcpSocial.setReceiveInterval(50)
  storyboard.comm.getMyItems()

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      local previous = storyboard.getPrevious()
      if previous == "scenes.postLobby" then
        previous = "scenes.mainMenu"
      end
      storyboard.gotoScene(previous)
      storyboard.purgeScene("scenes.marketplace")
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

  function addListeners()
    if storyboard.getCurrentSceneName() == "scenes.marketplace" then
      buyButton.addListener()
      getMoreButton.addListener()
      for tab = 1, 4 do
        categoryTabs[tab]:addEventListener("tap", categoryTabs[tab])
      end
    end
  end

  timer.performWithDelay(200, function()
    if storyboard.getCurrentSceneName() == "scenes.marketplace" then
      homeButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  local changed = false
  for i = 1, #savedAvatar do
    if savedAvatar[i] ~= avatar[i] then
      changed = true
    end
  end
  if changed then
    storyboard.comm.setAvatarData(avatar)
  end
  createSprite.updateAvatar(avatar)
  storyboard.tcpSocial.setReceiveInterval(nil)
  if loader then
    loader.stopLoader()
  end
  for _, button in pairs(packButtons) do
    button.removeListener()
  end
  cleanUp()
  buyButton.removeListener()
  getMoreButton.removeListener()
  for tab = 1, 4 do
    categoryTabs[tab]:removeEventListener("tap", categoryTabs[tab])
  end
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
  storyboard.comm.setCallback(function() end)
end

function scene:destroyScene()
  homeButton, getMoreButton, buyButton = nil, nil, nil
  categoryTabs, packButtons = {}, {}
  loader, avatar, savedAvatar = nil, nil, nil
  addListeners, cleanUp, scene.onPacket = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
