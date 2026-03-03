---------------------------------------------------------------------------------
-- earnCoins.lua — Earn coins / rewards screen
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

local rewardedVideoModule = require("modules.rewardedVideoModule")

-- Module-level variables
local homeButton
local keyListener
local background
local watchAdButton
local coinBalanceText
local enterFrameListener

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
        text = storyboard.localized.get("EarnCoins") or "Earn Coins",
        x = display.contentCenterX,
        y = display.contentHeight * 0.1,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Coin balance
    ---------------------------------------------------------------------------
    local coins = 0
    if storyboard.playerInfo then
        coins = storyboard.playerInfo.coins or 0
    end
    coinBalanceText = display.newText({
        text = (storyboard.localized.get("YourCoins") or "Your Coins") .. ": " .. tostring(coins),
        x = display.contentCenterX,
        y = display.contentHeight * 0.22,
        font = font,
        fontSize = fontSize,
    })
    coinBalanceText:setFillColor(1, 0.84, 0)
    view:insert(coinBalanceText)

    ---------------------------------------------------------------------------
    -- Watch ad for coins
    ---------------------------------------------------------------------------
    local function onWatchAdTap(event)
        rewardedVideoModule.showRewardedVideo(function(rewarded)
            if rewarded then
                -- TODO: Award coins via server
                native.showAlert("Fun Run",
                    storyboard.localized.get("CoinsEarned") or "You earned coins!",
                    {storyboard.localized.get("Ok") or "OK"})
            end
        end)
        return true
    end

    watchAdButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("WatchVideo") or "Watch Video",
        width = 150, height = 45,
        x = display.contentCenterX,
        y = display.contentCenterY,
        onRelease = onWatchAdTap,
    })
    view:insert(watchAdButton.displayGroup or watchAdButton)

    ---------------------------------------------------------------------------
    -- Info text
    ---------------------------------------------------------------------------
    local infoText = display.newText({
        text = storyboard.localized.get("WatchVideoInfo") or "Watch a short video to earn free coins!",
        x = display.contentCenterX,
        y = display.contentHeight * 0.65,
        font = font,
        fontSize = fontSize * 0.85,
        width = display.contentWidth * 0.7,
        align = "center",
    })
    infoText:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(infoText)

    ---------------------------------------------------------------------------
    -- Home button
    ---------------------------------------------------------------------------
    local function onHomeTap(event)
        storyboard.gotoScene("scenes.mainMenu")
        storyboard.purgeScene("scenes.earnCoins")
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
    -- Refresh coin balance
    if storyboard.playerInfo and coinBalanceText then
        local coins = storyboard.playerInfo.coins or 0
        coinBalanceText.text = (storyboard.localized.get("YourCoins") or "Your Coins") .. ": " .. tostring(coins)
    end
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
    watchAdButton = nil
    coinBalanceText = nil
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
