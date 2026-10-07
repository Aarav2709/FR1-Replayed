-- entry point.

display.setStatusBar(display.HiddenStatusBar)
system.setIdleTimer(false)

isAndroid = system.getInfo("platformName") == "Android"
isSimulator = system.getInfo("environment") == "simulator"

FORCE_SCALE = display.fps / 30

local cancelTimer = timer.cancel
function timer.cancel(handle)
  if handle then
    return cancelTimer(handle)
  end
end

isPC = system.getInfo("platform") == "win32" or system.getInfo("platform") == "macos"

Runtime:addEventListener("key", function(event)
  if event.keyName == "escape" then
    Runtime:dispatchEvent({ name = "key", phase = event.phase, keyName = "back" })
    return true
  end
end)

localPlayerCollisionFilter = { categoryBits = 1, maskBits = 10 }
remotePlayerCollisionFilter = { categoryBits = 16, maskBits = 2 }
obstacleFilter = { categoryBits = 2, maskBits = 21 }
powerUpFilter = { categoryBits = 4, maskBits = 2 }
sensorFilter = { categoryBits = 8, maskBits = 1 }

local fontName = "Brady Bunch Remastered"
if isAndroid or system.getInfo("platformName") == "Win" then
  fontName = "BradyBunchRemastered"
end

if audio.supportsSessionProperty == true then
  audio.setSessionProperty(audio.MixMode, audio.AmbientMixMode)
end

require("modules.adaptiveUI")
local storyboard = require("modules.storyboard")
require("modules.configuration")
local database = require("modules.database")
require("modules.textHelper")
storyboard.database = database
storyboard.gamesPlayed = 0

local function disposeGameSounds()
  if storyboard.gameDataTable and storyboard.gameDataTable.sounds then
    for _, sound in pairs(storyboard.gameDataTable.sounds) do
      audio.dispose(sound)
    end
  end
end

local function onUnhandledError(event)
  return true
end

local function onSystemEvent(event)
  if event.type == "applicationExit" then
    if storyboard.comm then
      storyboard.comm.stopTCPSocial()
    end
    if storyboard.tcpClient then
      storyboard.tcpClient.stopTCPClient()
    end
    disposeGameSounds()
  end
end

Runtime:addEventListener("system", onSystemEvent)
if not isSimulator then
  Runtime:addEventListener("unhandledError", onUnhandledError)
end

local function initializeGame()
  database.setupTables()
  storyboard.totalGamesPlayed = database.getNumberOfGamesPlayed()

  storyboard.localized = require("modules.localization")
  storyboard.localized.updateLanguage()

  storyboard.gameDataTable = {
    version = storyboard.config.version,
    serverVersion = storyboard.config.serverVersion,
    playerListNames = {},
    sounds = { buttonSound = audio.loadSound("sound/sfx_button_press.wav") },
    animations = { avatar = {}, boots = {}, item = {}, hat = {} },
    messageOfTheDay = "",
    font = fontName,
    backButton = { 80, 50, 50, 290 },
    tryIt = 0,
  }

  storyboard.errorTable = { showServerError = true }
  storyboard.suspendAlert = false
  storyboard.wifiOn = true
  storyboard.showingDailyChallange = false
  storyboard.gameType = 0

  storyboard.httpClient = require("modules.httpClient")
  storyboard.tcpClient = require("modules.tcpClient")
  storyboard.tcpSocial = require("modules.tcpSocial")
  storyboard.comm = require("modules.communicationModule")
  storyboard.lan = require("modules.lan")

  if database.getPlayerInformation() then
    storyboard.gotoScene("scenes.loadingScene")
  else
    storyboard.gotoScene("scenes.registerScene")
  end
end

initializeGame()
