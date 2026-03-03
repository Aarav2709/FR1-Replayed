---------------------------------------------------------------------------------
-- playMenu.lua — Play mode selection (Practice, QuickPlay, Friends)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local practiceButton
local quickPlayButton
local friendsButton
local homeButton
local enterFrameListener
local keyListener
local alertRef
local tipText

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local backgroundImage

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
    -- Show error alerts
    ---------------------------------------------------------------------------
    local function showError(code)
        if alertRef then
            native.cancelAlert(alertRef)
            alertRef = nil
        end
        if code == 1 then
            alertRef = native.showAlert("Trail",
                "You must create a user to play online.",
                {"Cancel", "Register"}, alertHandler)
        elseif code == 2 then
            alertRef = native.showAlert("Trail",
                "You must create a user to play online with friends.",
                {"Cancel", "Register"}, alertHandler)
        elseif code == 3 then
            alertRef = native.showAlert(
                storyboard.localized.get("ServerMessage"),
                storyboard.errorTable.quickplay,
                {storyboard.localized.get("Ok")})
        elseif code == 4 then
            alertRef = native.showAlert(
                storyboard.localized.get("ServerMessage"),
                storyboard.errorTable.friends,
                {storyboard.localized.get("Ok")})
        end
    end

    ---------------------------------------------------------------------------
    -- Practice mode: single-player with bots
    ---------------------------------------------------------------------------
    local function onPracticeTap(event)
        storyboard.gameDataTable.playerListNames = {}
        storyboard.gameDataTable.playerListNames[1] = {
            username = storyboard.playerInfo.username,
            avatar = storyboard.database.getAvatarData()
        }
        storyboard.gameDataTable.playerListNames[2] = {
            username = "BearBot",
            avatar = {2, 1, 1, 1}
        }
        storyboard.gameDataTable.playerListNames[3] = {
            username = "PandaBot",
            avatar = {3, 4, 3, 2}
        }
        storyboard.gameDataTable.playerListNames[4] = {
            username = "TurtleBot",
            avatar = {4, 2, 4, 3}
        }
        storyboard.gameType = 1
        storyboard.gotoScene("scenes.lobbySingleplayer")
        storyboard.purgeScene("scenes.playMenu")
        return true
    end

    ---------------------------------------------------------------------------
    -- Quick Play: online matchmaking
    ---------------------------------------------------------------------------
    local function onQuickPlayTap(event)
        native.showAlert("Offline Mode", "Offline mode unavailable", {"Ok"})
    end

    ---------------------------------------------------------------------------
    -- Friends: play with friends
    ---------------------------------------------------------------------------
    local function onFriendsTap(event)
        native.showAlert("Offline Mode", "Offline mode unavailable", {"Ok"})
    end

    ---------------------------------------------------------------------------
    -- Home: back to main menu
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.mainMenu")
    end

    ---------------------------------------------------------------------------
    -- UI: Background
    ---------------------------------------------------------------------------
    backgroundImage = display.newImageRect("images/gui/background/background_playMenu.png", 480, 320)
    backgroundImage.x = display.contentWidth * 0.5
    backgroundImage.y = display.contentHeight * 0.5
    view:insert(backgroundImage)

    ---------------------------------------------------------------------------
    -- UI: Buttons
    ---------------------------------------------------------------------------
    practiceButton = gui.newButton({
        image = "images/gui/button/singlePlayer.png",
        text = {
            string = storyboard.localized.get("Practice"),
            size = 20,
            languageSizes = {fr = 18, es = 16},
            y = 30
        },
        width = 100,
        height = 100,
        onRelease = onPracticeTap,
        x = display.contentWidth * 0.17,
        y = display.contentHeight * 0.4,
        displayGroup = view
    })

    quickPlayButton = gui.newButton({
        image = "images/gui/button/quickPlay.png",
        text = {
            string = storyboard.localized.get("QuickPlay"),
            size = 30,
            languageSizes = {fr = 28, es = 26, ja = 18, ko = 25, de = 24},
            y = 40
        },
        width = 150,
        height = 150,
        onRelease = onQuickPlayTap,
        x = display.contentWidth * 0.5,
        y = display.contentHeight * 0.4,
        displayGroup = view
    })

    friendsButton = gui.newButton({
        image = "images/gui/button/host.png",
        text = {
            string = storyboard.localized.get("Friends"),
            size = 20,
            languageSizes = {fr = 18, es = 16},
            y = 30
        },
        width = 100,
        height = 100,
        onRelease = onFriendsTap,
        x = display.contentWidth * 0.83,
        y = display.contentHeight * 0.4,
        displayGroup = view
    })

    homeButton = gui.newButton({
        image = "images/gui/button/home.png",
        width = storyboard.gameDataTable.backButton[1],
        height = storyboard.gameDataTable.backButton[2],
        onRelease = onHomeTap,
        x = storyboard.gameDataTable.backButton[3],
        y = storyboard.gameDataTable.backButton[4],
        displayGroup = view
    })

    -- Reset TCP receive interval
    storyboard.tcpSocial.setReceiveInterval(nil)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    local canGoBack = false
    local backPressed = false
    local view = self.view
    local font = storyboard.gameDataTable.font
    local fontSize = 18
    local textColor = {1, 1, 1, 1}

    -- Initialize player list
    storyboard.gameDataTable.playerListNames = {}

    ---------------------------------------------------------------------------
    -- Tips of the Day (TD1 - TD36)
    ---------------------------------------------------------------------------
    local tipNames = {
        "TD1",  "TD2",  "TD3",  "TD4",  "TD5",  "TD6",
        "TD7",  "TD8",  "TD9",  "TD10", "TD11", "TD12",
        "TD13", "TD14", "TD15", "TD16", "TD17", "TD18",
        "TD19", "TD20", "TD21", "TD22", "TD23", "TD24",
        "TD25", "TD26", "TD27", "TD28", "TD29", "TD30",
        "TD31", "TD32", "TD33", "TD34", "TD35", "TD36"
    }

    math.randomseed(os.time() + system.getTimer())
    local randomTip = tipNames[math.random(1, #tipNames)]
    local tipString = storyboard.localized.get(randomTip)

    -- Override with message of the day if available
    if type(storyboard.gameDataTable.messageOfTheDay) == "string" then
        if string.len(storyboard.gameDataTable.messageOfTheDay) > 1 then
            tipString = storyboard.gameDataTable.messageOfTheDay
        end
    end

    tipText = display.newText(tipString, 0, 0, 750, 110, font, fontSize * 1.9)
    tipText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    tipText.xScale = 0.5
    tipText.yScale = 0.5
    tipText.anchorX = 0
    tipText.anchorY = 0.5
    tipText.x = display.contentWidth * 0.2
    tipText.y = display.contentHeight * 0.9
    view:insert(tipText)

    ---------------------------------------------------------------------------
    -- Enable back navigation
    ---------------------------------------------------------------------------
    local function enableBack()
        canGoBack = true
    end

    enterFrameListener = function(event)
        if backPressed == true then
            backPressed = false
            canGoBack = false
            storyboard.gotoScene("scenes.mainMenu")
        end
    end

    keyListener = function(event)
        if event.phase == "up" and event.keyName == "back" then
            if canGoBack then
                backPressed = true
            end
            return true
        end
        return false
    end

    -- Add button listeners
    local function addListeners()
        if not practiceButton then return end
        if storyboard.getCurrentSceneName() == "scenes.playMenu" then
            practiceButton.addListener()
            quickPlayButton.addListener()
            friendsButton.addListener()
            homeButton.addListener()
            enableBack()
        end
    end

    timer.performWithDelay(200, addListeners, 1)
    Runtime:addEventListener("key", keyListener)
    Runtime:addEventListener("enterFrame", enterFrameListener)

    -- Stop TCP client
    storyboard.tcpClient.stopTCPClient()

    ---------------------------------------------------------------------------
    -- Simulator bot auto-play (debug)
    ---------------------------------------------------------------------------
    timer.performWithDelay(5000, function()
        if isSimulator then
            if storyboard.gameDataTable.bot then
                storyboard.gameType = 2
                storyboard.gotoScene("scenes.lobbyQuickPlay")
                storyboard.purgeScene("scenes.playMenu")
            end
        end
    end, 1)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    practiceButton.removeListener()
    quickPlayButton.removeListener()
    friendsButton.removeListener()
    homeButton.removeListener()

    if tipText then
        tipText.text = ""
        tipText = nil
    end

    if alertRef then
        native.cancelAlert(alertRef)
        alertRef = nil
    end

    Runtime:removeEventListener("key", keyListener)
    Runtime:removeEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    practiceButton = nil
    quickPlayButton = nil
    friendsButton = nil
    homeButton = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
