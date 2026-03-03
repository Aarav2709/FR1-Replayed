---------------------------------------------------------------------------------
-- lobbyCustomPlay.lua — Custom play lobby (friends / invite)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local startButton
local inviteButton
local enterFrameListener
local keyListener
local background
local playerSlots = {}
local countdownText
local countdownTimer
local loadingAnimation
local serverCallback
local mapImage
local isHost = false

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

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/lobbyCustomPlay.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("CustomPlay") or "Custom Play",
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
    -- Player slots (up to 4)
    ---------------------------------------------------------------------------
    local playerNames = storyboard.gameDataTable.playerListNames or {}
    for i = 1, 4 do
        local slotY = display.contentHeight * (0.25 + (i - 1) * 0.12)
        local slotBg = display.newRoundedRect(display.contentCenterX, slotY, 200, 30, 4)
        slotBg:setFillColor(0, 0, 0, 0.35)
        slotBg:setStrokeColor(1, 1, 1, 0.4)
        slotBg.strokeWidth = 1
        slotBg.x = display.contentCenterX
        slotBg.y = slotY
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
    -- Start button (host only)
    ---------------------------------------------------------------------------
    local function onStartTap(event)
        storyboard.comm.send("startCustomGame", {})
        return true
    end

    startButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Start") or "Start",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.88,
        onRelease = onStartTap,
    })
    view:insert(startButton.displayGroup or startButton)

    ---------------------------------------------------------------------------
    -- Invite button
    ---------------------------------------------------------------------------
    local function onInviteTap(event)
        storyboard.gotoScene("scenes.friends")
        return true
    end

    inviteButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Invite") or "Invite",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.70,
        onRelease = onInviteTap,
    })
    view:insert(inviteButton.displayGroup or inviteButton)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        if countdownTimer then timer.cancel(countdownTimer); countdownTimer = nil end
        storyboard.comm.send("leaveCustomGame", {})
        storyboard.gotoScene("scenes.playMenu")
        storyboard.purgeScene("scenes.lobbyCustomPlay")
        return true
    end

    homeButton = gui.newButton({
        image = "images/gui/button/smallHome.png",
        width = 35, height = 35,
        x = 26, y = 26,
        onRelease = onHomeTap,
    })
    view:insert(homeButton.displayGroup or homeButton)

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
    -- Server callback
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if response and response.type == "gameStart" then
            if countdownTimer then timer.cancel(countdownTimer); countdownTimer = nil end
            storyboard.gotoScene("scenes.gamePlay")
            storyboard.purgeScene("scenes.lobbyCustomPlay")
        end
    end

    storyboard.comm.setCallback(serverCallback)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
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
    inviteButton = nil
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
