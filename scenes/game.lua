-- scenes/game.lua
-- Main Game Scene

local composer = require("composer")
local physics = require("physics")

local scene = composer.newScene()

-- Scene variables
local background
local camera
local players = {}
local powerUps = {}
local ui = {}

-- Scene creation
function scene:create(event)
    local sceneGroup = self.view
    
    -- Enable physics
    physics.start()
    physics.setGravity(0, 9.8)
    
    -- Background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth * 3, display.contentHeight)
    background:setFillColor(0.3, 0.7, 0.3) -- Green background
    
    -- Create player placeholder
    local player = display.newRect(sceneGroup, 100, display.contentCenterY, 40, 40)
    player:setFillColor(1, 0, 0) -- Red player
    physics.addBody(player, "dynamic", { friction = 0.3, bounce = 0.2 })
    players[1] = player
    
    -- Ground
    local ground = display.newRect(sceneGroup, display.contentCenterX, display.contentHeight - 50, display.contentWidth * 3, 100)
    ground:setFillColor(0.5, 0.3, 0.1) -- Brown ground
    physics.addBody(ground, "static")
    
    -- UI Elements
    local pauseButton = display.newText(sceneGroup, "PAUSE", display.contentWidth - 80, 50, native.systemFont, 20)
    pauseButton:setFillColor(1, 1, 1)
    ui.pauseButton = pauseButton
    
    local timer = display.newText(sceneGroup, "60", display.contentCenterX, 50, native.systemFontBold, 24)
    timer:setFillColor(1, 1, 1)
    ui.timer = timer
end

-- Game loop
local function gameLoop()
    -- Update game logic here
end

-- Touch controls
local function onTouch(event)
    if event.phase == "began" then
        -- Jump
        if players[1] then
            players[1]:setLinearVelocity(0, -400)
        end
    end
    return true
end

-- Scene show
function scene:show(event)
    local phase = event.phase
    if phase == "will" then
        Runtime:addEventListener("touch", onTouch)
    elseif phase == "did" then
        Runtime:addEventListener("enterFrame", gameLoop)
    end
end

-- Scene hide
function scene:hide(event)
    local phase = event.phase
    if phase == "will" then
        Runtime:removeEventListener("touch", onTouch)
        Runtime:removeEventListener("enterFrame", gameLoop)
    elseif phase == "did" then
        -- Clean up
    end
end

-- Scene destroy
function scene:destroy(event)
    physics.stop()
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
