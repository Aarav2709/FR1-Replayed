-- weekly and all time rankings.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local createSprite = require("modules.createSprite")
local tableView = require("modules.tableView")
local loadingAnimation = require("modules.loadingAnimation")

local scene = storyboard.newScene()

local WEEKLY, TOP = 1, 3
local RIGHT_SHIFT = display.contentWidth - 480

local homeButton
local weeklyTab, topTab
local loader
local timeLeftText
local ownEntries = {}
local tabListenersAdded = false
local setOwnEntry, showOwnStats, showList, showMessage, showPrizes
local cleanUp, onFrame, onKey

function scene:createScene()
  local view = self.view
  local prizeGroup = display.newGroup()
  local font = storyboard.gameDataTable.font
  local fontSize = storyboard.localized.getFontSize()
  local WHITE = { 1, 1, 1, 1 }
  local BLACK = { 0, 0, 0, 1 }
  local SELECTED = { 0.4392156862745098, 0.25098039215686274, 0.18823529411764706, 1 }
  local LIST_COLOR = { 0.9529411764705882, 0.8980392156862745, 0.803921568627451 }
  local STAR_LIMITS = { 1, 10, 50 }
  local AVATAR_X, AVATAR_Y = 100, 178
  local STATS_X = 115
  local buttonSound = storyboard.gameDataTable.sounds.buttonSound
  local body, hat, boots
  local statTexts = {}
  local messageText
  local lists = { {}, {}, {} }
  local ownEntry = {}
  local list
  local rowNumber = 0
  local currentTab = WEEKLY
  local currentItem, shownItem = 1, 1
  local itemTimer
  local listsShown = 0
  ownEntries = {}
  tabListenersAdded = false

  local function playButtonSound()
    if storyboard.database.getSound() == 1 then
      audio.play(buttonSound)
    end
  end

  local function clearStats()
    for key, text in pairs(statTexts) do
      text.text = ""
      statTexts[key] = nil
    end
  end

  local function onHome()
    storyboard.gotoScene("scenes.mainMenu")
    storyboard.purgeScene("scenes.ranking")
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

  local function spawnItemParticle()
    local particle = createSprite.changeSpriteItem(currentItem, view, 1)
    if particle then
      particle:setFrame(math.random(5))
      particle.x = AVATAR_X
      particle.y = AVATAR_Y + math.random(-20, 20)
      transition.to(particle, { time = 200, x = AVATAR_X - 54 })
      transition.to(particle, {
        time = 500, delay = 200, x = AVATAR_X - 110, alpha = 0,
        onComplete = function() display.remove(particle) end,
      })
      bringAvatarToFront()
    end
  end

  local function updateItemTrail()
    if shownItem ~= currentItem then
      shownItem = currentItem
      if itemTimer then
        timer.cancel(itemTimer)
      end
      if currentItem > 1 then
        itemTimer = timer.performWithDelay(200, spawnItemParticle, 0)
      end
    end
  end

  local function setPart(part, index)
    if part == 1 then
      if body then
        display.remove(body)
      end
      body = createSprite.changeSpriteAvatar(index, view, 1)
      body.x, body.y = AVATAR_X, AVATAR_Y
      body.xScale, body.yScale = 0.5, 0.5
      body.timeScale = 0.4
      body:play()
    elseif part == 2 then
      if hat then
        display.remove(hat)
      end
      hat = createSprite.changeSpriteHat(index, view, 1)
      hat.x, hat.y = AVATAR_X, AVATAR_Y - 12
      hat.xScale, hat.yScale = 0.5, 0.5
      hat.timeScale = 0.4
      body:prepare("normal")
      body:play()
      hat:prepare("normal")
      hat:play()
    elseif part == 3 then
      currentItem = index
      updateItemTrail()
    elseif part == 4 then
      if boots then
        display.remove(boots)
      end
      boots = createSprite.changeSpriteBoots(index, view, 1)
      boots.x, boots.y = AVATAR_X, AVATAR_Y
      boots.xScale, boots.yScale = 0.5, 0.5
      boots.timeScale = 0.4
      boots:play()
    end
  end

  local function showAvatar(avatar)
    for part = 1, 4 do
      setPart(part, avatar[part])
    end
  end

  local function addStat(key, text, x, y, size)
    local label = display.newText(text, 0, 0, font, size or fontSize * 2)
    label:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    label.xScale, label.yScale = 0.5, 0.5
    label.anchorX, label.anchorY = 0, 1
    label.x, label.y = x, y
    view:insert(label)
    statTexts[key] = label
    return label
  end

  local function showStats(name, rating, wins, games, kills, deaths, suicides)
    clearStats()
    if string.len(name) > 15 then
      name = name:sub(1, 15) .. ".."
    end
    local title = display.newText(name, 0, 0, font, fontSize * 2.7)
    title:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
    title.xScale, title.yScale = 0.5, 0.5
    title.x, title.y = STATS_X, 25
    view:insert(title)
    statTexts.name = title
    addStat("games", storyboard.localized.get("Games") .. games, 10, 70)
    if games == 0 then
      games = 1
    end
    local winRate = wins / games * 100 .. ""
    local dot = string.find(winRate, "%.")
    if dot ~= nil then
      winRate = winRate:sub(0, dot + 2)
    end
    addStat("wins", storyboard.localized.get("Wins") .. winRate .. "%", 10, 90)
    local killsText = addStat("kills", storyboard.localized.get("Kills") .. kills, STATS_X, 70)
    local deathsText = addStat("deaths", storyboard.localized.get("Deaths") .. deaths, STATS_X, 90)
    local suicidesText = addStat("suicides", storyboard.localized.get("Suicides") .. suicides, STATS_X, 110)
    if storyboard.localized.language == "ja" then
      suicidesText.y = 90
      deathsText.x = 10
      deathsText.y = 110
      killsText.y = 70
    end
  end

  function showMessage(text)
    if messageText then
      messageText.text = ""
      messageText = nil
    end
    if text ~= "" then
      messageText = display.newText(text, 0, 0, 230 / display.contentScaleX, 100, font, fontSize * 2)
      messageText:setFillColor(WHITE[1], WHITE[2], WHITE[3], WHITE[4])
      messageText.xScale, messageText.yScale = 0.5, 0.5
      messageText.anchorX, messageText.anchorY = 0, 1
      messageText.x = 15
      messageText.y = display.contentHeight * 0.5
      view:insert(messageText)
    end
  end

  local function setListData(tab, entries)
    lists[tab] = entries
  end
  scene.setListData = setListData

  function setOwnEntry(entry)
    ownEntry = entry
  end

  function showOwnStats()
    showAvatar(ownEntry.a)
    showStats(ownEntry.u, ownEntry.r, ownEntry.s[1], ownEntry.s[2], ownEntry.s[3], ownEntry.s[4], ownEntry.s[5])
  end

  local function showEntry(entry)
    if entry then
      showAvatar(entry.a)
      showStats(entry.u, entry.r, entry.s[1], entry.s[2], entry.s[3], entry.s[4], entry.s[5])
    end
  end

  local selectedRow
  local function onRowTap(event)
    if selectedRow then
      selectedRow.removePressEffect()
    end
    event.target.t.setPressEffect()
    showEntry(lists[currentTab][event.target.id])
    showMessage("")
    selectedRow = event.target.t
  end

  local function removeList()
    selectedRow = nil
    if list then
      list:cleanUp()
      list = nil
    end
    rowNumber = 0
  end

  local function buildList()
    removeList()
    list = tableView.newList({
      data = lists[currentTab], default = "images/gui/tableView/cell.png", onRelease = onRowTap,
      top = 50, bottom = 0, width = 250, height = 40,
      callback = function(entry)
        local row = display.newGroup()
        local name, rating, prefix
        if storyboard.gameDataTable.tryIt == 0 then
          if rowNumber == 0 then
            local highlight = display.newImageRect("images/gui/tableView/cell2.png", 250, 40)
            highlight.anchorX, highlight.anchorY = 0, 0
            highlight.x, highlight.y = 0, 5
            row:insert(highlight)
            name, rating, prefix = ownEntry.u, ownEntry.r, ""
          else
            name, rating, prefix = entry.u, entry.r, rowNumber .. ". "
          end
        else
          name, rating, prefix = entry.u, entry.r, rowNumber + 1 .. ". "
        end
        if string.len(name) > 15 then
          name = name:sub(1, 15) .. ".."
        end
        local nameText = display.newText(prefix .. name, 0, 0, font, fontSize * 2)
        nameText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
        nameText.xScale, nameText.yScale = 0.5, 0.5
        nameText.anchorX, nameText.anchorY = 0, 1
        nameText.x, nameText.y = 10, 36
        row:insert(nameText)
        local ratingText = display.newText(rating, 0, 0, font, fontSize * 2)
        ratingText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
        ratingText.xScale, ratingText.yScale = 0.5, 0.5
        ratingText.anchorX, ratingText.anchorY = 1, 1
        ratingText.x, ratingText.y = 240, 36
        row:insert(ratingText)
        if currentTab == WEEKLY then
          if rowNumber > 0 then
            ratingText.x = 220
          end
          local stars = 0
          if rowNumber <= STAR_LIMITS[1] and rowNumber > 0 then
            stars = 3
          elseif rowNumber > STAR_LIMITS[1] and rowNumber <= STAR_LIMITS[2] then
            stars = 2
          elseif rowNumber > STAR_LIMITS[2] and rowNumber <= STAR_LIMITS[3] then
            stars = 1
          end
          if stars > 0 then
            local star = display.newImageRect("images/gui/ranking/star" .. stars .. ".png", 25, 10)
            star.x, star.y = 236, 24
            row:insert(star)
          end
        end
        function row.setPressEffect()
          nameText:setFillColor(SELECTED[1], SELECTED[2], SELECTED[3], SELECTED[4])
          ratingText:setFillColor(SELECTED[1], SELECTED[2], SELECTED[3], SELECTED[4])
        end
        function row.removePressEffect()
          nameText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
          ratingText:setFillColor(BLACK[1], BLACK[2], BLACK[3], BLACK[4])
        end
        rowNumber = rowNumber + 1
        return row
      end,
    })
    list.x = 230 + RIGHT_SHIFT
    view:insert(list)
    view:insert(scene.listFrame)
    view:insert(topTab)
    view:insert(weeklyTab)
    if timeLeftText then
      view:insert(timeLeftText)
    end
  end

  function showList(tab)
    if storyboard.gameDataTable.tryIt == 0 then
      if tab == WEEKLY then
        if listsShown == 1 then
          table.insert(lists[WEEKLY], 1, ownEntry)
          buildList()
        end
      elseif tab == TOP then
        table.insert(lists[tab], 1, ownEntry)
        buildList()
      end
      listsShown = listsShown + 1
    else
      buildList()
    end
  end

  function cleanUp()
    currentItem = 0
    if itemTimer then
      timer.cancel(itemTimer)
    end
    createSprite.cleanSuperfluousSprites()
    if list then
      list:cleanUp()
      list = nil
    end
  end

  local background = display.newImageRect("images/gui/background/background_ranking.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)
  local listBackground = display.newRect(0, 0, 250, 320)
  listBackground:setFillColor(LIST_COLOR[1], LIST_COLOR[2], LIST_COLOR[3])
  listBackground.x, listBackground.y = 355 + RIGHT_SHIFT, 160
  view:insert(listBackground)
  scene.listFrame = display.newImageRect("images/gui/ranking/listBackground.png", 250, 320)
  scene.listFrame.anchorX, scene.listFrame.anchorY = 1, 0.5
  scene.listFrame.x = display.contentWidth
  scene.listFrame.y = display.contentHeight * 0.5
  view:insert(scene.listFrame)

  local function selectTab(tab)
    weeklyTab.alpha = tab == WEEKLY and 1 or 0.01
    topTab.alpha = tab == TOP and 1 or 0.01
    prizeGroup.isVisible = tab == WEEKLY
  end

  local function openTab(tab, request)
    playButtonSound()
    selectTab(tab)
    if #lists[tab] == 0 then
      request()
    else
      ownEntry = ownEntries[tab]
    end
    currentTab = tab
    if ownEntry.u then
      buildList()
      showOwnStats()
    end
  end

  weeklyTab = display.newImageRect("images/gui/ranking/marker.png", 72, 43)
  function weeklyTab.tap()
    openTab(WEEKLY, storyboard.comm.getWeeklyList)
  end
  weeklyTab.anchorX, weeklyTab.anchorY = 1, 0
  weeklyTab.x, weeklyTab.y = 306 + RIGHT_SHIFT, 6
  view:insert(weeklyTab)
  topTab = display.newImageRect("images/gui/ranking/marker.png", 72, 43)
  function topTab.tap()
    openTab(TOP, storyboard.comm.getTopList)
  end
  topTab.anchorX, topTab.anchorY = 1, 0
  topTab.x, topTab.y = 391 + RIGHT_SHIFT, 6
  view:insert(topTab)
  selectTab(WEEKLY)

  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = onHome,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })

  local starsInfo = display.newImageRect("images/gui/ranking/starsInfo.png", 55, 45)
  starsInfo.anchorX, starsInfo.anchorY = 0, 0
  starsInfo.x, starsInfo.y = 0, 14
  prizeGroup:insert(starsInfo)
  local quickPlayOnly = display.newText("(Only Quick Play)", 0, 0, font, fontSize * 1.2)
  quickPlayOnly:setFillColor(0.9372549019607843, 0.8980392156862745, 0.788235294117647, 1)
  quickPlayOnly.xScale, quickPlayOnly.yScale = 0.5, 0.5
  quickPlayOnly.anchorX, quickPlayOnly.anchorY = 0, 0
  quickPlayOnly.x, quickPlayOnly.y = 15, 60
  prizeGroup:insert(quickPlayOnly)

  function showPrizes(packet)
    for place = 1, 3 do
      local prize = packet.a[place]
      if prize.t then
        local icon, label = nil, ""
        if tonumber(prize.t) == 1 then
          icon, label = "diamondDoe", "1 x"
        elseif tonumber(prize.t) == 2 then
          icon, label = "coin", prize.v
        end
        local text = display.newText(label, 0, 0, font, fontSize * 1.5)
        text:setFillColor(1, 1, 1, 1)
        text.xScale, text.yScale = 0.5, 0.5
        text.anchorX, text.anchorY = 0, 0
        text.x = 65
        text.y = -4 + 16 * place
        prizeGroup:insert(text)
        if icon then
          local image = display.newImageRect("images/gui/ranking/" .. icon .. ".png", 10, 10)
          image.anchorX, image.anchorY = 0, 0
          image.x = text.x + text.width / 2 + 2
          image.y = text.y + 4
          prizeGroup:insert(image)
        end
      end
    end
    local minutes = math.abs(tonumber(packet.t))
    timeLeftText = display.newText(math.floor(minutes / 24 / 60) .. "d " .. math.floor(minutes / 60 % 24) .. "h "
      .. math.floor(minutes % 60) .. "m", 0, 0, font, fontSize * 1.2)
    timeLeftText:setFillColor(0.23529411764705882, 0.1607843137254902, 0.12549019607843137, 1)
    timeLeftText.xScale, timeLeftText.yScale = 0.5, 0.5
    timeLeftText.anchorX, timeLeftText.anchorY = 0, 0
    timeLeftText.x, timeLeftText.y = 250 + RIGHT_SHIFT, 31
    view:insert(timeLeftText)
  end

  view:insert(prizeGroup)
  prizeGroup.x, prizeGroup.y = 100, 245
  loader = loadingAnimation.newLoadingAnimation()
  view:insert(loader.displayGroup)
  loader.displayGroup.x = display.contentWidth * 0.75
  loader.displayGroup.y = display.contentHeight * 0.5
end

function scene:enterScene()
  local backKeyEnabled, backPressed = false, false
  storyboard.tcpSocial.setReceiveInterval(50)
  storyboard.comm.setCallback(function(packet)
    if packet.e then
      native.showAlert(storyboard.localized.get("Error"), storyboard.localized.get("CouldNotGetTop50"),
        { storyboard.localized.get("Ok") })
    elseif packet.m == "u" then
      loader.stopLoader()
      scene.setListData(1, packet.l)
      if packet.a and packet.t then
        showPrizes(packet)
      end
      if packet.s then
        ownEntries[1] = packet.s
        setOwnEntry(packet.s)
        showList(1)
        topTab:addEventListener("tap", topTab)
        tabListenersAdded = true
      else
        showMessage(storyboard.localized.get("You have to login to see your own stats"))
      end
      showOwnStats()
      showList(1)
    elseif packet.m == "i" then
      if packet.s then
        ownEntries[2] = packet.s
        setOwnEntry(packet.s)
        showOwnStats()
      end
      scene.setListData(2, packet.l)
      showList(2)
    elseif packet.m == "h" then
      if packet.s then
        ownEntries[3] = packet.s
        setOwnEntry(packet.s)
        showOwnStats()
      end
      scene.setListData(3, packet.l)
      showList(3)
    end
  end)
  storyboard.comm.getWeeklyList()
  loader.startLoader()

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.ranking")
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
    if storyboard.getCurrentSceneName() == "scenes.ranking" then
      homeButton.addListener()
      weeklyTab:addEventListener("tap", weeklyTab)
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  if loader then
    loader.stopLoader()
  end
  storyboard.tcpSocial.setReceiveInterval(nil)
  storyboard.comm.setCallback(function() end)
  cleanUp()
  homeButton.removeListener()
  if tabListenersAdded then
    topTab:removeEventListener("tap", topTab)
  end
  weeklyTab:removeEventListener("tap", weeklyTab)
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  homeButton = nil
  weeklyTab, topTab = nil, nil
  loader, timeLeftText = nil, nil
  ownEntries = {}
  setOwnEntry, showOwnStats, showList, showMessage, showPrizes, cleanUp = nil, nil, nil, nil, nil, nil
  scene.setListData, scene.listFrame = nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
