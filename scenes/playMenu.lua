-- practice, quick play and lan.

local storyboard = require("modules.storyboard")
local gui = require("modules.gui")

local scene = storyboard.newScene()

local practiceButton, quickPlayButton, lanButton, homeButton
local onFrame, onKey

function scene:createScene()
  local group = self.view

  local background = display.newImageRect("images/gui/background/background_playMenu.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  group:insert(background)

  practiceButton = gui.newButton({
    image = "images/gui/button/singlePlayer.png",
    text = { string = storyboard.localized.get("Practice"), size = 20, languageSizes = { fr = 18, es = 16 }, y = 30 },
    width = 100, height = 100,
    onRelease = function()
      local names = storyboard.gameDataTable.playerListNames
      names[1] = { username = storyboard.playerInfo.username, avatar = storyboard.database.getAvatarData() }
      names[2] = { username = "BearBot", avatar = { 2, 1, 1, 1 } }
      names[3] = { username = "PandaBot", avatar = { 3, 4, 3, 2 } }
      names[4] = { username = "TurtleBot", avatar = { 4, 2, 4, 3 } }
      storyboard.gameType = 1
      storyboard.gotoScene("scenes.lobbySingleplayer")
      storyboard.purgeScene("scenes.playMenu")
      return true
    end,
    x = display.contentWidth * 0.17, y = display.contentHeight * 0.4,
    displayGroup = group,
  })

  quickPlayButton = gui.newButton({
    image = "images/gui/button/quickPlay.png",
    text = {
      string = storyboard.localized.get("QuickPlay"), size = 30,
      languageSizes = { fr = 28, es = 26, ja = 18, ko = 25, de = 24 }, y = 40,
    },
    width = 150, height = 150,
    onRelease = function()
      storyboard.tcpSocial.setReceiveInterval(100)
      storyboard.gameType = 2
      storyboard.gotoScene("scenes.lobbyQuickPlay")
      storyboard.purgeScene("scenes.playMenu")
      return true
    end,
    x = display.contentWidth * 0.5, y = display.contentHeight * 0.4,
    displayGroup = group,
  })

  lanButton = gui.newButton({
    image = "images/gui/button/host.png",
    text = { string = "LAN", size = 20, y = 30 },
    width = 100, height = 100,
    onRelease = function()
      storyboard.gotoScene("scenes.lan")
      storyboard.purgeScene("scenes.playMenu")
    end,
    x = display.contentWidth * 0.83, y = display.contentHeight * 0.4,
    displayGroup = group,
  })

  homeButton = gui.newButton({
    image = "images/gui/button/home.png",
    width = storyboard.gameDataTable.backButton[1], height = storyboard.gameDataTable.backButton[2],
    onRelease = function()
      storyboard.gotoScene("scenes.mainMenu")
    end,
    x = storyboard.gameDataTable.backButton[3], y = storyboard.gameDataTable.backButton[4],
    displayGroup = group,
  })

  storyboard.tcpSocial.setReceiveInterval(nil)
end

function scene:enterScene()
  local keyReleased, backPressed = false, false
  storyboard.gameDataTable.playerListNames = {}
  math.randomseed(os.time() + system.getTimer())

  function onFrame()
    if backPressed then
      backPressed = false
      keyReleased = false
      storyboard.gotoScene("scenes.mainMenu")
    end
  end

  function onKey(event)
    if event.phase == "up" and event.keyName == "back" then
      if keyReleased then
        backPressed = true
      end
      return true
    end
    return false
  end

  timer.performWithDelay(200, function()
    if practiceButton and storyboard.getCurrentSceneName() == "scenes.playMenu" then
      practiceButton.addListener()
      quickPlayButton.addListener()
      lanButton.addListener()
      homeButton.addListener()
      keyReleased = true
    end
  end, 1)
  Runtime:addEventListener("key", onKey)
  Runtime:addEventListener("enterFrame", onFrame)
  storyboard.tcpClient.stopTCPClient()
end

function scene:exitScene()
  practiceButton.removeListener()
  quickPlayButton.removeListener()
  lanButton.removeListener()
  homeButton.removeListener()
  Runtime:removeEventListener("key", onKey)
  Runtime:removeEventListener("enterFrame", onFrame)
end

function scene:destroyScene()
  practiceButton, quickPlayButton, lanButton, homeButton = nil, nil, nil, nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
