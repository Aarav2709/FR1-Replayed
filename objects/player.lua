-- objects/player.lua
-- Player Character Object

local M = {}

local physics = require("physics")
local config = require("config.gameConfig")

-- Player constructor
function M.new(params)
    params = params or {}
    
    local player = {}
    
    -- Visual representation
    player.sprite = display.newRect(params.x or 0, params.y or 0, 40, 40)
    player.sprite:setFillColor(params.color or {1, 0, 0})
    
    -- Physics
    physics.addBody(player.sprite, "dynamic", {
        friction = 0.3,
        bounce = 0.2,
        density = 1.0
    })
    player.sprite.isFixedRotation = true
    
    -- Properties
    player.id = params.id or 1
    player.name = params.name or "Player"
    player.character = params.character or "fox"
    player.speed = config.PLAYER_SPEED
    player.isGrounded = false
    player.powerUp = nil
    player.position = 0
    
    -- Movement
    function player:moveLeft()
        self.sprite:setLinearVelocity(-self.speed, 0)
    end
    
    function player:moveRight()
        self.sprite:setLinearVelocity(self.speed, 0)
    end
    
    function player:jump()
        if self.isGrounded then
            self.sprite:setLinearVelocity(0, config.JUMP_FORCE)
            self.isGrounded = false
        end
    end
    
    function player:stop()
        self.sprite:setLinearVelocity(0, 0)
    end
    
    -- Power-up usage
    function player:usePowerUp()
        if self.powerUp then
            -- Implement power-up effects
            self.powerUp = nil
        end
    end
    
    -- Collision detection
    function player:collision(event)
        if event.phase == "began" then
            if event.other.objType == "ground" then
                self.isGrounded = true
            elseif event.other.objType == "powerup" then
                self.powerUp = event.other.powerType
                event.other:removeSelf()
            end
        end
    end
    
    player.sprite.collision = function(event)
        player:collision(event)
    end
    player.sprite:addEventListener("collision")
    
    -- Cleanup
    function player:destroy()
        if self.sprite then
            self.sprite:removeSelf()
            self.sprite = nil
        end
    end
    
    return player
end

return M
