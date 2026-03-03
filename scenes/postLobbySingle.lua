---------------------------------------------------------------------------------
-- postLobbySingle.lua — Post-game results (singleplayer / practice)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local playAgainButton
local enterFrameListener
local keyListener
local background
local playerResultSlots = {}
local resultTitleText
local xpGainedText
local coinsGainedText

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
    local gameStats = storyboard.gameDataTable.gameStats or {}

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/postLobby.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Result title
    ---------------------------------------------------------------------------
    local resultStr = "Results"
    if gameStats.position then
        if gameStats.position == 1 then
            resultStr = storyboard.localized.get("YouWin") or "You Win!"
        else
            resultStr = (storyboard.localized.get("Position") or "Position") .. ": " .. tostring(gameStats.position)
        end
    end
    resultTitleText = display.newText({
        text = resultStr,
        x = display.contentCenterX,
        y = display.contentHeight * 0.1,
        font = font,
        fontSize = fontSizeLarge,
    })
    resultTitleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    resultTitleText.xScale = 0.5
    resultTitleText.yScale = 0.5
    view:insert(resultTitleText)

    ---------------------------------------------------------------------------
    -- Player result slots
    ---------------------------------------------------------------------------
    local playerNames = storyboard.gameDataTable.playerListNames or {}
    for i = 1, 4 do
        local slotY = display.contentHeight * (0.22 + (i - 1) * 0.12)
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
        playerResultSlots[i] = {bg = slotBg, text = nameText}
    end

    ---------------------------------------------------------------------------
    -- XP / Coins gained
    ---------------------------------------------------------------------------
    local xp = gameStats.xpGained or 0
    local coins = gameStats.coinsGained or 0

    xpGainedText = display.newText({
        text = "XP: +" .. tostring(xp),
        x = display.contentCenterX - 50,
        y = display.contentHeight * 0.72,
        font = font,
        fontSize = fontSize,
    })
    xpGainedText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(xpGainedText)

    coinsGainedText = display.newText({
        text = "Coins: +" .. tostring(coins),
        x = display.contentCenterX + 50,
        y = display.contentHeight * 0.72,
        font = font,
        fontSize = fontSize,
    })
    coinsGainedText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(coinsGainedText)

    ---------------------------------------------------------------------------
    -- Play Again button
    ---------------------------------------------------------------------------
    local function onPlayAgainTap(event)
        storyboard.gotoScene("scenes.lobbySingleplayer")
        storyboard.purgeScene("scenes.postLobbySingle")
        return true
    end

    playAgainButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("PlayAgain") or "Play Again",
        width = 120, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.85,
        onRelease = onPlayAgainTap,
    })
    view:insert(playAgainButton.displayGroup or playAgainButton)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.postLobbySingle")
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
    playAgainButton = nil
    resultTitleText = nil
    xpGainedText = nil
    coinsGainedText = nil
    playerResultSlots = {}
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
