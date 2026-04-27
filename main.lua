-- main.lua — Fun Run 1 Rebuilt Entry Point
-- Reconstructed from decompiled main.lu.lua
display.setStatusBar(display.HiddenStatusBar)
system.setIdleTimer(false)

-- Platform detection
isAndroid = ("Android" == system.getInfo("platformName"))
isSimulator = ("simulator" == system.getInfo("environment"))

localPlayerCollisionFilter  = { categoryBits = 1,  maskBits = 10 }
remotePlayerCollisionFilter = { categoryBits = 16, maskBits = 2  }
obstacleFilter              = { categoryBits = 2,  maskBits = 21 }
powerUpFilter               = { categoryBits = 4,  maskBits = 2  }
sensorFilter                = { categoryBits = 8,  maskBits = 1  }

local fontName = "Brady Bunch Remastered"
if isAndroid or isSimulator then
    fontName = "BradyBunchRemastered"
end


if audio.supportsSessionProperty == true then
    audio.setSessionProperty(audio.MixMode, audio.AmbientMixMode)
end


local storyboard = require("modules.storyboard")
require("modules.configuration")
local database = require("modules.database")

storyboard.database = database
storyboard.gamesPlayed = 0


local function disposeGameSounds()
    if storyboard.gameDataTable and storyboard.gameDataTable.sounds then
        for i = 1, #storyboard.gameDataTable.sounds do
            audio.dispose(storyboard.gameDataTable.sounds[i])
        end
    end
end

local function stopAllConnections()
    if storyboard and storyboard.comm then
        if storyboard.playerInfo then
            if storyboard.tcpSocial then
                storyboard.comm.stopTCPSocial()
            end
            if storyboard.tcpClient then
                storyboard.tcpClient.stopTCPClient()
            end
        end
    end
end

local function stopSocialOnly()
    if storyboard and storyboard.comm then
        if storyboard.playerInfo then
            if storyboard.tcpSocial then
                storyboard.comm.stopTCPSocial()
            end
        end
    end
end

local function onSuspendAlert(event)
    if event.action == "clicked" then
        local current = storyboard.getCurrentSceneName()
        local previous = storyboard.getPrevious()
        storyboard.gotoScene("scenes.playMenu")

        if current == "scenes.chatScene" then
            storyboard.purgeScene(current)
            storyboard.purgeScene(previous)
        else
            storyboard.purgeScene(current)
        end
        storyboard.suspendAlert = false
    end
end

local function showSuspendedAlert()
    if not storyboard.suspendAlert then
        storyboard.suspendAlert = true
        native.showAlert(
            storyboard.localized.get("Disconnected"),
            storyboard.localized.get("YouSuspended"),
            { storyboard.localized.get("Ok") },
            onSuspendAlert
        )
    end
end

local function onUnhandledError(event)
    print(event)
    local rand = math.random(1, 10)
    if rand > 3 then
        print("suppress error")
        return true
    end
    print("show error")
end

local function onSystemEvent(event)
    if event.type == "applicationStart" then
        if storyboard.notification then
            storyboard.notification.clearLocalPushNotificationQueue()
        end
    elseif event.type == "applicationExit" then
        stopAllConnections()
        disposeGameSounds()
        if isAndroid then
            Runtime:removeEventListener("unhandledError", onUnhandledError)
        end
        Runtime:removeEventListener("system", onSystemEvent)
    elseif event.type == "applicationSuspend" then
        local currentScene = storyboard.getCurrentSceneName()

        if currentScene == "scenes.earnCoins" then
            print("keep connection open")
        elseif currentScene == "scenes.postLobby" then
            print("keep connection open")
        elseif storyboard.rewardedVideoType == 2 then
            print("keep connection open")
        elseif currentScene ~= "scenes.gamePlay" then
            stopAllConnections()
        else
            stopSocialOnly()
        end

        -- Schedule return notifications
        if storyboard.notification then
            storyboard.notification.queue3DayNotification()
            storyboard.notification.queue7DayNotification()
            storyboard.notification.queue30DayNotification()
        end
    elseif event.type == "applicationResume" then
        if storyboard.comm and storyboard.tcpSocial then
            local currentScene = storyboard.getCurrentSceneName()

            if currentScene ~= "scenes.earnCoins" and
               currentScene ~= "scenes.postLobby" and
               storyboard.rewardedVideoType ~= 2 then
                storyboard.comm.startSocialTCP(function() end)
            else
                if not storyboard.tcpSocial.isConnected() then
                    storyboard.comm.startSocialTCP(function() end)
                end
            end

            -- Handle Facebook callback
            if currentScene == "scenes.facebookScene" then
                if storyboard.facebookCallback then
                    storyboard.facebookCallback()
                end
            elseif currentScene == "scenes.lobbyQuickPlay" or
                   currentScene == "scenes.lobbyCustomPlay" or
                   currentScene == "scenes.customplay" or
                   currentScene == "scenes.chatScene" then
                showSuspendedAlert()
            end
        end

        -- Clear notifications on resume
        if storyboard.notification then
            storyboard.notification.clearLocalPushNotificationQueue()
        end
    end
end

Runtime:addEventListener("system", onSystemEvent)

if isAndroid then
    Runtime:addEventListener("unhandledError", onUnhandledError)
end

local function initializeGame()
    -- Setup database
    database.setupTables()

    -- Set offline mode starting coins (10 million)
    database.setMoney(10000000)

    -- Load total games played
    storyboard.totalGamesPlayed = database.getNumberOfGamesPlayed()

    -- Load localization
    local localization = require("modules.localization")
    storyboard.localized = localization
    localization.updateLanguage()

    -- Load push notification module
    require("modules.pushNotification")

    -- Initialize game data table
    storyboard.gameDataTable = {}
    storyboard.gameDataTable.version = storyboard.config.version
    storyboard.gameDataTable.serverVersion = storyboard.config.serverVersion
    storyboard.gameDataTable.playerListNames = {}

    -- Sounds table (will be populated in loadingScene)
    storyboard.gameDataTable.sounds = {}
    storyboard.gameDataTable.sounds.buttonSound = audio.loadSound("sound/sfx_button_press.wav")

    -- Animation tables
    storyboard.gameDataTable.animations = {}
    storyboard.gameDataTable.animations.avatar = {}
    storyboard.gameDataTable.animations.boots = {}
    storyboard.gameDataTable.animations.item = {}
    storyboard.gameDataTable.animations.hat = {}

    -- Other game data
    storyboard.gameDataTable.messageOfTheDay = ""
    storyboard.gameDataTable.font = fontName
    storyboard.gameDataTable.backButton = { 80, 50, 50, 290 }
    storyboard.gameDataTable.tryIt = 0

    -- Ads table
    storyboard.adsTable = {}
    storyboard.adsTable.use = false
    storyboard.adsTable.active = false
    storyboard.adsTable.time = 0
    storyboard.adsTable.showTime = 4000
    storyboard.adsTable.refreshRate = 72000
    storyboard.adsTable.videoSeen = 0
    storyboard.adsTable.rewardedVideoTypeCounters = {}
    storyboard.adsTable.videoLimit = 0

    -- Error handling table
    storyboard.errorTable = {}
    storyboard.errorTable.showServerError = true

    -- State
    storyboard.suspendAlert = false
    storyboard.wifiOn = true
    storyboard.facebookCallback = function() end
    storyboard.videoViewedTime = 0
    storyboard.showingDailyChallange = false
    storyboard.onlineFriends = {}
    storyboard.gameType = 0
    storyboard.gameInvites = {}

    -- Map names
    storyboard.mapIconNames = {
        "SunsetValley", "GreenHills", "CliffClimber", "CloudRoad",
        "BrokenBridge", "MountainView", "SugarSlope", "JellyCave",
        "CandyShop", "ChocolateTops", "FrostingFields", "LollipopRoad",
        "Bridgetown", "ForestJump", "HighPeak", "TwigPeaks",
        "JumpingBluffs", "HiddenCaves", "BridgePass",
    }
    storyboard.mapIconNamesGame = {
        "Sunset Valley", "Green Hills", "Cliff Climber", "Cloud Road",
        "Broken Bridge", "Mountain View", "Sugar Slope", "Jelly Cave",
        "Candy Shop", "Chocolate Tops", "Frosting Fields", "Lollipop Road",
        "Bridgetown", "Forest Jump", "High Peak", "Twig peaks",
        "Jumping bluffs", "Hidden caves", "Bridge Pass",
    }

    -- Load networking modules (stubs in offline mode)
    storyboard.httpClient = require("modules.httpClient")
    storyboard.tcpClient = require("modules.tcpClient")
    storyboard.tcpSocial = require("modules.tcpSocial")
    storyboard.comm = require("modules.communicationModule")
    storyboard.facebook = require("modules.lib_facebook")
    storyboard.facebook.FB_App_ID = storyboard.config.facebook

    -- Push notification module reference
    storyboard.notification = require("modules.pushNotification")

    -- Route to first scene — bypass login (servers offline), ensure a default player exists
    local playerInfo = database.getPlayerInformation()
    if not playerInfo then
        database.setPlayerInformation("Player", 1, "offline")
    end
    storyboard.gotoScene("scenes.loadingScene")

    -- Load analytics (no-op stub)
    storyboard.analytics = require("modules.analytics")

    return true
end

initializeGame()
