---------------------------------------------------------------------------------
-- helpSettings.lua — Help / about overlay
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()

-- Module-level variables
local backButton
local keyListener
local background
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
    -- Settings tab bar
    ---------------------------------------------------------------------------
    local settingsModule = require("modules.settingsModule")
    local settingsBar = settingsModule.create()
    if settingsBar and settingsBar.displayGroup then
        view:insert(settingsBar.displayGroup)
    end

    ---------------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------------
    local titleText = display.newText({
        text = storyboard.localized.get("Help") or "Help",
        x = display.contentCenterX,
        y = display.contentHeight * 0.12,
        font = font,
        fontSize = fontSize * 2,
    })
    titleText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(titleText)

    ---------------------------------------------------------------------------
    -- About / version info
    ---------------------------------------------------------------------------
    local versionText = display.newText({
        text = "Fun Run — Replayed",
        x = display.contentCenterX,
        y = display.contentHeight * 0.28,
        font = font,
        fontSize = fontSize,
    })
    versionText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(versionText)

    local versionNumber = display.newText({
        text = (storyboard.localized.get("Version") or "Version") .. ": " ..
               (storyboard.gameDataTable.version or "1.0"),
        x = display.contentCenterX,
        y = display.contentHeight * 0.34,
        font = font,
        fontSize = fontSize * 0.85,
    })
    versionNumber:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(versionNumber)

    ---------------------------------------------------------------------------
    -- Tutorial button
    ---------------------------------------------------------------------------
    local function onTutorialTap(event)
        storyboard.gotoScene("scenes.tutorial")
        return true
    end

    local tutorialButton = gui.newButton({
        image = "images/gui/button/blank.png",
        text = storyboard.localized.get("Tutorial") or "Tutorial",
        width = 150, height = 40,
        x = display.contentCenterX,
        y = display.contentHeight * 0.48,
        onRelease = onTutorialTap,
    })
    view:insert(tutorialButton.displayGroup or tutorialButton)

    ---------------------------------------------------------------------------
    -- Credits
    ---------------------------------------------------------------------------
    local creditsText = display.newText({
        text = storyboard.localized.get("Credits") or "Credits",
        x = display.contentCenterX,
        y = display.contentHeight * 0.62,
        font = font,
        fontSize = fontSize,
    })
    creditsText:setFillColor(textColor[1], textColor[2], textColor[3], textColor[4])
    view:insert(creditsText)

    local creditsBody = display.newText({
        text = "dirtybit",
        x = display.contentCenterX,
        y = display.contentHeight * 0.68,
        font = font,
        fontSize = fontSize * 0.85,
    })
    creditsBody:setFillColor(textColor[1], textColor[2], textColor[3], 0.7)
    view:insert(creditsBody)

    ---------------------------------------------------------------------------
    -- Back button
    ---------------------------------------------------------------------------
    local function onBackTap(event)
        storyboard.gotoScene("scenes.settings")
        storyboard.purgeScene("scenes.helpSettings")
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
    enterFrameListener = nil
    keyListener = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
