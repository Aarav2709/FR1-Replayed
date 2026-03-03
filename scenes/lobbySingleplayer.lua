---------------------------------------------------------------------------------
-- lobbySingleplayer.lua — Singleplayer lobby (map select + bot preview)
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
local mapImage
local mapSelectLeft
local mapSelectRight
local currentMap

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

    currentMap = storyboard.gameDataTable.mapSelected or 1

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
        text = storyboard.localized.get("Practice") or "Practice",
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
    -- Player slots (up to 4 — player + bots)
    ---------------------------------------------------------------------------
    local playerNames = storyboard.gameDataTable.playerListNames or {}
    for i = 1, 4 do
        local slotY = display.contentHeight * (0.25 + (i - 1) * 0.12)
        local slotBg = display.newRoundedRect(display.contentCenterX, slotY, 200, 30, 4)
        slotBg:setFillColor(0, 0, 0, 0.35)
        slotBg:setStrokeColor(1, 1, 1, 0.4)
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
    -- Map label
    ---------------------------------------------------------------------------
    local mapLabel = display.newText({
        text = "Map: " .. tostring(currentMap),
        x = display.contentCenterX,
        y = display.contentHeight * 0.78,
        font = font,
        fontSize = fontSize,
    })
    mapLabel:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(mapLabel)

    ---------------------------------------------------------------------------
    -- Start button
    ---------------------------------------------------------------------------
    local function onStartTap(event)
        storyboard.gameDataTable.mapSelected = currentMap
        storyboard.gotoScene("scenes.gamePlay")
        storyboard.purgeScene("scenes.lobbySingleplayer")
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
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.playMenu")
        storyboard.purgeScene("scenes.lobbySingleplayer")
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
    Runtime:removeEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
    background = nil
    homeButton = nil
    startButton = nil
    mapImage = nil
    mapSelectLeft = nil
    mapSelectRight = nil
    playerSlots = {}
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
