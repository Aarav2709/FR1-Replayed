-- utils/physics.lua
-- Physics Utilities

local M = {}

-- Setup world physics
function M.setupWorld()
    local physics = require("physics")
    physics.start()
    physics.setGravity(0, 9.8)
    physics.setDrawMode("normal") -- Change to "debug" for testing
end

-- Create ground/platform
function M.createGround(x, y, width, height)
    local ground = display.newRect(x, y, width, height)
    ground:setFillColor(0.5, 0.3, 0.1)
    physics.addBody(ground, "static")
    ground.objType = "ground"
    return ground
end

-- Create moving platform
function M.createMovingPlatform(x, y, width, height, moveDistance, moveTime)
    local platform = display.newRect(x, y, width, height)
    platform:setFillColor(0.6, 0.4, 0.2)
    physics.addBody(platform, "kinematic")
    platform.objType = "platform"
    
    -- Animate movement
    local function movePlatform()
        transition.to(platform, {
            time = moveTime,
            x = x + moveDistance,
            onComplete = function()
                transition.to(platform, {
                    time = moveTime,
                    x = x,
                    onComplete = movePlatform
                })
            end
        })
    end
    movePlatform()
    
    return platform
end

-- Create obstacle
function M.createObstacle(x, y, width, height, obstacleType)
    local obstacle = display.newRect(x, y, width, height)
    
    if obstacleType == "spikes" then
        obstacle:setFillColor(0.8, 0.2, 0.2) -- Red spikes
    elseif obstacleType == "saw" then
        obstacle:setFillColor(0.7, 0.7, 0.7) -- Gray saw
        -- Add rotation animation
        transition.to(obstacle, {
            time = 1000,
            rotation = 360,
            iterations = -1
        })
    else
        obstacle:setFillColor(0.4, 0.4, 0.4) -- Default gray
    end
    
    physics.addBody(obstacle, "static")
    obstacle.objType = "obstacle"
    obstacle.obstacleType = obstacleType
    
    return obstacle
end

-- Create checkpoint
function M.createCheckpoint(x, y)
    local checkpoint = display.newRect(x, y, 20, 100)
    checkpoint:setFillColor(0, 1, 0, 0.5) -- Semi-transparent green
    physics.addBody(checkpoint, "static")
    checkpoint.isSensor = true
    checkpoint.objType = "checkpoint"
    return checkpoint
end

-- Create finish line
function M.createFinishLine(x, y)
    local finishLine = display.newRect(x, y, 30, 200)
    finishLine:setFillColor(1, 1, 0, 0.7) -- Yellow finish line
    physics.addBody(finishLine, "static")
    finishLine.isSensor = true
    finishLine.objType = "finish"
    return finishLine
end

-- Collision filtering
function M.setupCollisionFilters()
    -- Define collision filters for different object types
    M.FILTER_PLAYER = { categoryBits = 1, maskBits = 65535 }
    M.FILTER_GROUND = { categoryBits = 2, maskBits = 65535 }
    M.FILTER_POWERUP = { categoryBits = 4, maskBits = 1 }
    M.FILTER_OBSTACLE = { categoryBits = 8, maskBits = 1 }
end

return M
