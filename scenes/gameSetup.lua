-- scenes/gameSetup.lua
-- Game Setup/Lobby Scene

local composer = require("composer")
local widget = require("widget")

local scene = composer.newScene()

-- Scene variables
local background
local titleText
local characterSelection
local trackSelection
local startButton
local backButton

-- Scene creation
function scene:create(event)
    local sceneGroup = self.view
    
    -- Background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.1, 0.3, 0.6)
    
    -- Title
    titleText = display.newText(sceneGroup, "Setup Game", display.contentCenterX, 100, native.systemFontBold, 36)
    titleText:setFillColor(1, 1, 1)
    
    -- Character selection placeholder
    local charText = display.newText(sceneGroup, "Character: Fox", display.contentCenterX - 200, 200, native.systemFont, 20)
    charText:setFillColor(1, 1, 1)
    
    -- Track selection placeholder
    local trackText = display.newText(sceneGroup, "Track: Forest", display.contentCenterX + 200, 200, native.systemFont, 20)
    trackText:setFillColor(1, 1, 1)
    
    -- Start Button
    startButton = widget.newButton({
        label = "START RACE",
        fontSize = 24,
        width = 200,
        height = 60,
        onRelease = function()
            composer.gotoScene("scenes.game", "slideLeft", 300)
        end
    })
    startButton.x = display.contentCenterX
    startButton.y = display.contentCenterY + 100
    sceneGroup:insert(startButton)
    
    -- Back Button
    backButton = widget.newButton({
        label = "BACK",
        fontSize = 20,
        width = 100,
        height = 40,
        onRelease = function()
            composer.gotoScene("scenes.menu", "slideRight", 300)
        end
    })
    backButton.x = 80
    backButton.y = 50
    sceneGroup:insert(backButton)
end

-- Scene show/hide/destroy functions (similar to menu.lua)
function scene:show(event) end
function scene:hide(event) end
function scene:destroy(event) end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
