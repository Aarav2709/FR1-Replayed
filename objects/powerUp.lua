-- objects/powerUp.lua
-- Power-up Object

local M = {}

local physics = require("physics")

-- Power-up constructor
function M.new(params)
    params = params or {}
    
    local powerUp = {}
    
    -- Visual representation
    powerUp.sprite = display.newCircle(params.x or 0, params.y or 0, 15)
    powerUp.sprite:setFillColor(params.color or {1, 1, 0}) -- Yellow by default
    
    -- Physics
    physics.addBody(powerUp.sprite, "kinematic")
    powerUp.sprite.isSensor = true
    powerUp.sprite.objType = "powerup"
    
    -- Properties
    powerUp.type = params.type or "speed_boost"
    powerUp.duration = params.duration or 5 -- seconds
    powerUp.sprite.powerType = powerUp.type
    
    -- Animation
    local function animate()
        transition.to(powerUp.sprite, {
            time = 1000,
            rotation = 360,
            iterations = -1
        })
        transition.to(powerUp.sprite, {
            time = 2000,
            y = powerUp.sprite.y - 10,
            iterations = -1,
            transition = easing.inOutSine
        })
    end
    animate()
    
    -- Cleanup
    function powerUp:destroy()
        if self.sprite then
            transition.cancel(self.sprite)
            self.sprite:removeSelf()
            self.sprite = nil
        end
    end
    
    return powerUp
end

-- Power-up effects
function M.applyEffect(player, powerUpType)
    if powerUpType == "speed_boost" then
        player.speed = player.speed * 1.5
        timer.performWithDelay(5000, function()
            player.speed = player.speed / 1.5
        end)
    elseif powerUpType == "shield" then
        -- Implement shield effect
    elseif powerUpType == "lightning" then
        -- Implement lightning attack
    elseif powerUpType == "magnet" then
        -- Implement coin magnet
    elseif powerUpType == "bomb" then
        -- Implement bomb attack
    elseif powerUpType == "spring" then
        -- Implement super jump
        player:jump()
        player:jump() -- Double jump effect
    end
end

return M
