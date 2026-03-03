---------------------------------------------------------------------------------
-- updateScene.lua — Update required scene
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local keyListener
local background
local updateButton

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
        text = storyboard.localized.get("UpdateRequired") or "Update Required",
        x = display.contentCenterX,
        y = display.contentHeight * 0.2,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- Message
    ---------------------------------------------------------------------------
    local messageText = display.newText({
        text = storyboard.localized.get("UpdateMessage") or
            "A new version of Fun Run is available.\nPlease update to continue playing.",
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = font,
        fontSize = fontSize,
        width = display.contentWidth * 0.75,
        align = "center",
    })
    messageText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(messageText)

    ---------------------------------------------------------------------------
    -- Update button (opens store link)
    ---------------------------------------------------------------------------
    local function onUpdateTap(event)
        local platform = system.getInfo("platform")
        if platform == "android" then
            system.openURL("market://details?id=com.dirtybit.funrun")
        else
            system.openURL("https://apps.apple.com/app/fun-run/id543164103")
        end
        return true
    end

    updateButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Update") or "Update",
        width = 150, height = 45,
        x = display.contentCenterX,
        y = display.contentHeight * 0.75,
        onRelease = onUpdateTap,
    })
    view:insert(updateButton.displayGroup or updateButton)

    ---------------------------------------------------------------------------
    -- Key listener (Android back — do nothing, force update)
    ---------------------------------------------------------------------------
    keyListener = function(event)
        if event.keyName == "back" and event.phase == "up" then
            return true -- consume back key
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
    updateButton = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
