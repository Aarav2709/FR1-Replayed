---------------------------------------------------------------------------------
-- facebookScene.lua — Facebook connection scene (stub)
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local keyListener
local background
local messageText

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
        text = "Facebook",
        x = display.contentCenterX,
        y = display.contentHeight * 0.2,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Unavailable message
    ---------------------------------------------------------------------------
    messageText = display.newText({
        text = storyboard.localized.get("FacebookUnavailable") or "Facebook login is currently unavailable.",
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = font,
        fontSize = fontSize,
        width = display.contentWidth * 0.7,
        align = "center",
    })
    messageText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(messageText)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        storyboard.gotoScene("scenes.loginScene")
        storyboard.purgeScene("scenes.facebookScene")
        return true
    end

    backButton = gui.newButton({
        image = "images/gui/button/smallHome.png",
        width = 35, height = 35,
        x = 26, y = 26,
        onRelease = onBackTap,
    })
    view:insert(backButton.displayGroup or backButton)

    ---------------------------------------------------------------------------
    -- Key listener (Android back)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            onBackTap(event)
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
    backButton = nil
    messageText = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
