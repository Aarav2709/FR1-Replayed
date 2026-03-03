---------------------------------------------------------------------------------
-- ranking.lua — Leaderboard / ranking screen
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local homeButton
local keyListener
local background
local rankingList
local playerRankText
local enterFrameListener
local serverCallback
local loadingAnimation

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
    local view = self.view
    local gui = require("modules.gui")
    local font = storyboard.gameDataTable.font
    local fontSize = storyboard.localized.getFontSize()
    local textColor = {1, 1, 1, 1}

    ---------------------------------------------------------------------------
    -- Background
    ---------------------------------------------------------------------------
    background = display.newImageRect("images/gui/background/login.png",
        display.contentWidth, display.contentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    view:insert(background)

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("Ranking") or "Ranking",
        x = display.contentCenterX,
        y = display.contentHeight * 0.06,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Player rank display
    ---------------------------------------------------------------------------
    playerRankText = display.newText({
        text = "",
        x = display.contentCenterX,
        y = display.contentHeight * 0.14,
        font = font,
        fontSize = fontSize,
    })
    playerRankText:setFillColor(1, 0.84, 0)
    view:insert(playerRankText)

    ---------------------------------------------------------------------------
    -- Leaderboard area placeholder
    ---------------------------------------------------------------------------
    local listBg = display.newRect(display.contentCenterX, display.contentCenterY + 20,
        display.contentWidth * 0.9, display.contentHeight * 0.6)
    listBg:setFillColor(0, 0, 0, 0.2)
    view:insert(listBg)

    local loadingText = display.newText({
        text = storyboard.localized.get("Loading") or "Loading...",
        x = display.contentCenterX,
        y = display.contentCenterY + 20,
        font = font,
        fontSize = fontSize,
    })
    loadingText:setFillColor(textColor[1], textColor[2], textColor[3], 0.6)
    view:insert(loadingText)

    -- TODO: Populate scrollable ranking list from server data

    ---------------------------------------------------------------------------
    -- Server callback
    ---------------------------------------------------------------------------
    serverCallback = function(response)
        if response and response.rankings then
            loadingText.isVisible = false
            -- TODO: Create ranking rows
            if response.playerRank then
                playerRankText.text = (storyboard.localized.get("YourRank") or "Your Rank") ..
                    ": #" .. tostring(response.playerRank)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.ranking")
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
    -- Request ranking from server
    storyboard.comm.send("getRanking", {
        username = storyboard.playerInfo.username,
    }, serverCallback)
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
    playerRankText = nil
    rankingList = nil
    loadingAnimation = nil
    serverCallback = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
