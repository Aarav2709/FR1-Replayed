-- client side of the social protocol.

local storyboard = require("modules.storyboard")
local accessories = require("modules.accessories")
local createSprite = require("modules.createSprite")

local comm = {}

local BROWN = { 0.24313725490196078, 0.14901960784313725, 0.11764705882352941 }

local pendingAccount
local pendingPurchase

function comm.callback() end

local function toIndexes(itemIds)
  local indexes = {}
  for i = 1, #itemIds do
    indexes[i] = accessories.getItem(itemIds[i]).item
  end
  return indexes
end

local function showChallengeCompleted(packet)
  local group = display.newGroup()
  local removed = false
  storyboard.showingDailyChallange = true
  local background = display.newImageRect("images/gui/button/dropDownDC.png", 240, 40)
  background.anchorX, background.anchorY = 0.5, 1
  background.x, background.y = 0, 0
  group:insert(background)

  local content = display.newGroup()
  local coin = display.newImageRect("images/gui/extra/coin.png", 15, 15)
  coin.anchorX, coin.anchorY = 0, 0.5
  coin.x, coin.y = 0, 0
  content:insert(coin)
  local title = packet.h and storyboard.localized.get(packet.h) or ""
  local text = display.newText(packet.c .. " " .. title, 0, 0, storyboard.gameDataTable.font,
    storyboard.localized.getFontSize() * 2.5)
  text.anchorX, text.anchorY = 0, 0.5
  text:setFillColor(BROWN[1], BROWN[2], BROWN[3])
  text.xScale, text.yScale = 0.5, 0.5
  text.x, text.y = 20, 0
  content:insert(text)
  content.anchorX, content.anchorY = 0.5, 1
  content.anchorChildren = true
  content.x, content.y = 0, -4
  group:insert(content)

  local function remove(g)
    if not removed then
      removed = true
      display.remove(g)
      storyboard.showingDailyChallange = false
    end
  end

  group.x = display.contentWidth * 0.5
  group.y = background.height + 5
  group.alpha = 0
  if storyboard.database.getSound() == 1 then
    audio.play(storyboard.gameDataTable.sounds.challangeCompleted)
  end
  transition.to(group, { time = 100, alpha = 1 })
  transition.to(group, { time = 150, delay = 3000, alpha = 0, onComplete = remove })
end

local function logOut()
  if storyboard.playerInfo then
    comm.stopTCPSocial()
    storyboard.tcpClient.stopTCPClient()
  end
  local current = storyboard.getCurrentSceneName()
  if current ~= "scenes.mainMenu" then
    storyboard.purgeScene("scenes.mainMenu")
  end
  storyboard.gotoScene("scenes.registerScene")
  storyboard.purgeScene(current)
end

local function onSocialPacket(packet)
  local m = packet.m
  if m == "l" then
    if packet.a == 1 then
      if packet.t then
        storyboard.gameDataTable.messageOfTheDay = packet.t
      end
      if packet.b then
        storyboard.gameDataTable.serverVersion = packet.b
      end
      storyboard.database.setAvatarData(toIndexes(packet.d))
      if storyboard.getCurrentSceneName() ~= "scenes.marketplace" then
        createSprite.updateAvatar(storyboard.database.getAvatarData())
      end
      if packet.e then
        storyboard.database.setNumberOfGamesPlayed(packet.e)
      end
      if packet.i then
        storyboard.database.setMoney(packet.i)
      end
      comm.callback({ a = packet.a, m = "l" })
    elseif packet.a == 2 then
      comm.callback({ a = packet.a, m = "l" })
      native.showAlert(storyboard.localized.get("LoggingOut"), storyboard.localized.get("AccountDevice"),
        { storyboard.localized.get("Ok") }, logOut)
    elseif packet.a == 4 then
      if storyboard.gameDataTable.tryIt == 0 then
        native.showAlert(storyboard.localized.get("Error"),
          storyboard.localized.get("This user doesn't exist. Please contact us"),
          { storyboard.localized.get("Ok") }, logOut)
      end
    end

  elseif m == "a" then
    if packet.a then
      comm.callback({ a = packet.a, m = "a" })
    else
      comm.callback({ e = 0, m = "a" })
    end

  elseif m == "h" or m == "u" then
    if packet.l then
      packet.s.a = toIndexes(packet.s.a)
      for _, entry in ipairs(packet.l) do
        entry.a = toIndexes(entry.a)
      end
      comm.callback({ l = packet.l, s = packet.s, m = m, t = packet.t, a = packet.a })
    else
      comm.callback({ e = 0, m = m })
    end

  elseif m == "n" then
    if packet.p then
      table.insert(packet.p[1], 100)
      table.insert(packet.p[2], 200)
      table.insert(packet.p[3], 300)
      table.insert(packet.p[4], 400)
      storyboard.database.setItems(packet.p)
      storyboard.database.setMoney(packet.c)
      comm.callback({ p = packet.p, m = "n" })
    else
      comm.callback({ e = 0, m = "n" })
    end

  elseif m == "o" then
    if packet.a == 1 then
      local item = accessories.getItem(packet.i)
      storyboard.database.addItem(item.category, packet.i)
      storyboard.database.decreaseMoney(item.price)
      if packet.c then
        storyboard.database.setMoney(packet.c)
      end
      comm.callback({ m = "o", a = 1, price = item.price, category = item.category, itemId = packet.i })
    elseif packet.a then
      comm.callback(packet)
    end

  elseif m == "p" then
    if packet.a == 1 then
      storyboard.database.setAvatarData(toIndexes(packet.d))
    end

  elseif m == "y" then
    comm.callback(packet)

  elseif m == "r" then
    if packet.c then
      storyboard.database.setMoney(packet.c)
    end
    comm.callback(packet)

  elseif m == "s" then
    if storyboard.showingDailyChallange == false then
      showChallengeCompleted(packet)
    else
      timer.performWithDelay(4000, function() return onSocialPacket(packet) end, 1)
    end

  elseif m == "z" then
    if packet.a then
      storyboard.database.setEarnCoins(packet.a)
    end
    comm.callback(packet)

  elseif m == "A" then
    if not packet.a then
      storyboard.database.increaseMoney(packet.d or 0)
      storyboard.database.setEarnCoins(packet.c)
    elseif packet.a == 2 then
    end
    comm.callback(packet)

  elseif m == "coins" then
    if pendingPurchase then
      local callback = pendingPurchase
      pendingPurchase = nil
      if packet.a == 1 then
        storyboard.database.setMoney(packet.c)
        callback({ message = "+" .. packet.d, value = packet.c })
      else
        callback({ message = storyboard.localized.get("PurchaseFailed"), value = -1 })
      end
    end
  end
end

local function onAccountPacket(packet)
  if packet.a == 1 and pendingAccount then
    storyboard.database.setPlayerInformation(pendingAccount.username, packet.playerId, packet.token)
    storyboard.playerInfo = storyboard.database.getPlayerInformation()
  end
  comm.callback(packet)
  pendingAccount = nil
end

function comm.setCallback(fn)
  comm.callback = fn
end

function comm.createUser(username)
  pendingAccount = { username = username }
  storyboard.httpClient.initWithReceiveFunction(onAccountPacket)
  storyboard.httpClient.createUser(username)
end

function comm.startSocialTCP(callback)
  if storyboard.playerInfo then
    comm.callback = callback
    storyboard.tcpSocial.startTCP(onSocialPacket)
    return true
  end
  return false
end

function comm.stopTCPSocial()
  comm.callback = function() end
  storyboard.tcpSocial.closeTCP()
end

local function send(packet)
  storyboard.tcpSocial.sendPacket(packet)
end

function comm.getGameServerAddress() send({ m = "a" }) end
function comm.repportPlayer(username, reason) send({ m = "w", a = username, b = reason }) end
function comm.getRepports() send({ m = "y" }) end
function comm.getTopList() send({ m = "h" }) end
function comm.getWeeklyList() send({ m = "u" }) end
function comm.getDaliyChallanges() send({ m = "r" }) end
function comm.getMyItems() send({ m = "n" }) end
function comm.buyItem(itemId) send({ m = "o", i = itemId }) end
function comm.getEarnCoins() send({ m = "z" }) end
function comm.claimEarnCoins(offerId) send({ m = "A", b = offerId }) end

function comm.addMoney(pack, callback)
  pendingPurchase = callback
  send({ m = "coins", v = pack })
end

function comm.setAvatarData(avatar)
  send({
    m = "p",
    d = {
      accessories.getItemId(1, avatar[1]),
      accessories.getItemId(2, avatar[2]),
      accessories.getItemId(3, avatar[3]),
      accessories.getItemId(4, avatar[4]),
    },
  })
end

return comm
