-- scenes/menu.lua
-- Main Menu Scene

local composer = require("composer")
local widget = require("widget")

local scene = composer.newScene()

-- Scene variables
local background
local titleText
local playButton
local settingsButton
local exitButton

-- Scene creation
function scene:create(event)
    local sceneGroup = self.view
    
    -- Background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.2, 0.4, 0.8) -- Blue background
    
    -- Title
    titleText = display.newText(sceneGroup, "Fun Run 1: Replayed", display.contentCenterX, 150, native.systemFontBold, 48)
    titleText:setFillColor(1, 1, 1)
    
    -- Play Button
    playButton = widget.newButton({
        label = "PLAY",
        fontSize = 24,
        width = 200,
        height = 60,
        onRelease = function()
            composer.gotoScene("scenes.gameSetup", "slideLeft", 300)
        end
    })
    playButton.x = display.contentCenterX
    playButton.y = display.contentCenterY - 50
    sceneGroup:insert(playButton)
    
    -- Settings Button
    settingsButton = widget.newButton({
        label = "SETTINGS",
        fontSize = 24,
        width = 200,
        height = 60,
        onRelease = function()
            composer.gotoScene("scenes.settings", "slideLeft", 300)
        end
    })
    settingsButton.x = display.contentCenterX
    settingsButton.y = display.contentCenterY + 30
    sceneGroup:insert(settingsButton)
    
    -- Exit Button
    exitButton = widget.newButton({
        label = "EXIT",
        fontSize = 24,
        width = 200,
        height = 60,
        onRelease = function()
            native.requestExit()
        end
    })
    exitButton.x = display.contentCenterX
    exitButton.y = display.contentCenterY + 110
    sceneGroup:insert(exitButton)
end

-- Scene show
function scene:show(event)
    local phase = event.phase
    if phase == "will" then
        -- Code here runs when the scene is about to come on screen
    elseif phase == "did" then
        -- Code here runs when the scene is entirely on screen
    end
end

-- Scene hide
function scene:hide(event)
    local phase = event.phase
    if phase == "will" then
        -- Code here runs when the scene is about to go off screen
    elseif phase == "did" then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

-- Scene destroy
function scene:destroy(event)
    -- Code here runs prior to the removal of scene's view
end

-- Scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
