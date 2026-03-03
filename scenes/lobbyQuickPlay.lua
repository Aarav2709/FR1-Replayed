---------------------------------------------------------------------------------
-- lobbyQuickPlay.lua — Quick play matchmaking lobby
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local startButton
local enterFrameListener
local keyListener
local background
local playerSlots = {}
local countdownText
local countdownTimer
local searchingText
local loadingAnimation
local serverCallback
local mapImage
local isSearching = false

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = 18
    local fontSizeLarge = fontSize * 2.5
    local textColor = {1, 1, 1, 1}
    local darkColor = {0.145, 0.082, 0.063, 1}

    isSearching = false

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/quickPlay.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("QuickPlay") or "Quick Play",
        x = display.contentCenterX,
        y = display.contentHeight * 0.08,
        font = font,
        fontSize = fontSizeLarge,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    titleText.xScale = 0.5
    titleText.yScale = 0.5
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Searching text
    ---------------------------------------------------------------------------
    searchingText = display.newText({
        text = storyboard.localized.get("SearchingForPlayers") or "Searching for players...",
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = font,
        fontSize = fontSize,
    })
    searchingText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(searchingText)

    ---------------------------------------------------------------------------
    -- Player slots (up to 4)
    ---------------------------------------------------------------------------
    local playerNames = storyboard.gameDataTable.playerListNames or {}
    for i = 1, 4 do
        local slotY = display.contentHeight * (0.25 + (i - 1) * 0.12)
        local slotBg = display.newRect(display.contentCenterX, slotY, 200, 30)
        slotBg:setFillColor(0, 0, 0, 0.3)
        slotBg:setStrokeColor(1, 1, 1, 0.5)
        slotBg.strokeWidth = 1
        view:insert(slotBg)

        local nameText = display.newText({
            text = (playerNames[i] and playerNames[i].username) or "",
            x = display.contentCenterX,
            y = slotY,
            font = font,
            fontSize = fontSize,
        })
        nameText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
        view:insert(nameText)
        playerSlots[i] = {bg = slotBg, text = nameText}
    end

    ---------------------------------------------------------------------------
    -- Countdown text
    ---------------------------------------------------------------------------
    countdownText = display.newText({
        text = "",
        x = display.contentCenterX,
        y = display.contentHeight * 0.78,
        font = font,
        fontSize = fontSizeLarge,
    })
    countdownText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    countdownText.xScale = 0.5
    countdownText.yScale = 0.5
    view:insert(countdownText)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        if countdownTimer then timer.cancel(countdownTimer); countdownTimer = nil end
        storyboard.gotoScene("scenes.playMenu")
        storyboard.purgeScene("scenes.lobbyQuickPlay")
        return true
    end

    homeButton = gui.newButton({
        image = "images/gui/button/smallHome.png",
        width = 35, height = 35,
        x = 26, y = 26,
        onRelease = onHomeTap,
        displayGroup = view,
    })

    ---------------------------------------------------------------------------
    -- Key listener (Android back)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            onHomeTap(event)
            return true
        end
    end
    Runtime:addEventListener("key", keyListener)

    ---------------------------------------------------------------------------
    -- Server callback (matchmaking updates)
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if response and response.type == "matchFound" then
            if countdownTimer then timer.cancel(countdownTimer); countdownTimer = nil end
            storyboard.gotoScene("scenes.gamePlay")
            storyboard.purgeScene("scenes.lobbyQuickPlay")
        end
    end

    storyboard.comm.setCallback(serverCallback)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
    isSearching = true
    -- Begin matchmaking request
    storyboard.comm.send("quickPlay", {
        username = storyboard.playerInfo.username,
        avatar = storyboard.database.getAvatarData(),
    })
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
    isSearching = false
    if countdownTimer then timer.cancel(countdownTimer); countdownTimer = nil end
    storyboard.comm.setCallback(function(response) end)
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    homeButton = nil
    startButton = nil
    searchingText = nil
    countdownText = nil
    loadingAnimation = nil
    playerSlots = {}
    serverCallback = nil
    mapImage = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
