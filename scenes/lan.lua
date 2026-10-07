-- lan menu. host a game or join one on the network.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")
local lan = require("modules.lan")

local scene = storyboard.newScene()

local homeButton, hostButton, joinButton
local gameButtons = {}
local ipField, statusText, searchingText
local refreshTimer
local onFrame, onKey

local function clearGames()
  for _, button in ipairs(gameButtons) do
    button.removeListener()
    display.remove(button.text)
    display.remove(button)
  end
  gameButtons = {}
end

function scene:createScene()
  local view = self.view
  local font = storyboard.gameDataTable.font
  local width = display.contentWidth
  local leftX, rightX = width * 0.27, width * 0.73

  local background = display.newImageRect("images/gui/background/login.png", 480, 320)
  background.x = width * 0.5
  background.y = display.contentHeight * 0.5
  view:insert(background)

  local function addText(text, size, x, y, boxWidth)
    local label = display.newText({
      text = text, x = x, y = y, width = boxWidth, font = font, fontSize = size * 2, align = "center",
    })
    label:setFillColor(1, 1, 1)
    label.xScale, label.yScale = 0.5, 0.5
    view:insert(label)
    return label
  end

  local function addPanel(x)
    local panel = display.newImageRect("images/gui/background/settingsWall1.png", 230, 190)
    panel.x, panel.y = x, 155
    view:insert(panel)
  end

  addText("LAN", 26, width * 0.5, 30)
  addPanel(leftX)
  addPanel(rightX)

  addText("Host a game", 18, leftX, 82)
  addText("Other players on your network will see your game and can join it.", 12, leftX, 118, 380)
  local address = lan.getLocalIP()
  if address then
    addText("Your address " .. address, 12, leftX, 228)
  end

  addText("Join a game", 18, rightX, 82)
  searchingText = addText("Searching the network", 12, rightX, 125)
  statusText = addText("", 13, width * 0.5, 298)

  local function enterLobby(gameType)
    storyboard.gameType = gameType
    storyboard.gotoScene("scenes.lanLobby")
    storyboard.purgeScene("scenes.lan")
  end

  local function join(ip, port)
    local ok = lan.join(ip, port, storyboard.playerInfo.username, storyboard.database.getAvatarData())
    if ok then
      enterLobby(4)
    else
      statusText.text = "Could not connect"
    end
  end
  scene.join = join

  hostButton = gui.newButton({
    image = "images/gui/button/blank.png",
    text = { string = "Host", size = 22 },
    width = 100, height = 50, x = leftX, y = 172, displayGroup = view,
    onRelease = function()
      local ok = lan.host(storyboard.playerInfo.username, storyboard.database.getAvatarData())
      if ok then
        enterLobby(3)
      else
        statusText.text = "Could not host a game"
      end
    end,
  })
  joinButton = gui.newButton({
    image = "images/gui/button/blank.png",
    text = { string = "Join", size = 16 },
    width = 64, height = 34, x = rightX + 78, y = 226, displayGroup = view,
    onRelease = function()
      local ip = string.gsub(ipField and ipField.text or "", "%s", "")
      if ip == "" then
        statusText.text = "Enter the host address"
      else
        join(ip)
      end
    end,
  })
  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lan")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = view,
  })
  if not lan.isAvailable() then
    statusText.text = "LAN is not available on this device"
  end
end

function scene:enterScene()
  local view = self.view
  local backKeyEnabled, backPressed = false, false
  local lastList = nil
  local rightX = display.contentWidth * 0.73

  ipField = native.newTextField(rightX - 38, 226, 118, 28)
  ipField.placeholder = "192.168.0.10"

  local function refreshGames()
    local list = lan.getFound()
    local key = ""
    for _, game in ipairs(list) do
      key = key .. game.ip .. game.port .. game.name .. game.players .. ";"
    end
    if key == lastList then
      return
    end
    lastList = key
    clearGames()
    searchingText.isVisible = #list == 0
    for i = 1, math.min(#list, 3) do
      local game = list[i]
      local button = gui.newButton({
        image = "images/gui/button/blank.png",
        text = { string = game.name .. "  " .. game.players .. "/4", size = 15 },
        width = 190, height = 30, x = rightX, y = 98 + i * 32, displayGroup = view,
        onRelease = function() scene.join(game.ip, game.port) end,
      })
      button.addListener()
      gameButtons[#gameButtons + 1] = button
    end
  end

  lan.startScan()
  refreshTimer = timer.performWithDelay(500, refreshGames, 0)

  function onFrame()
    if backPressed then
      backPressed = false
      backKeyEnabled = false
      storyboard.gotoScene("scenes.mainMenu")
      storyboard.purgeScene("scenes.lan")
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
    if storyboard.getCurrentSceneName() == "scenes.lan" then
      hostButton.addListener()
      joinButton.addListener()
      homeButton.addListener()
      backKeyEnabled = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
end

function scene:exitScene()
  if refreshTimer then
    timer.cancel(refreshTimer)
    refreshTimer = nil
  end
  lan.stopScan()
  clearGames()
  display.remove(ipField)
  ipField = nil
  hostButton.removeListener()
  joinButton.removeListener()
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  homeButton, hostButton, joinButton = nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
