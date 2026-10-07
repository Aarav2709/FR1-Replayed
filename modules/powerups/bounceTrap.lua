-- bounce trap.

local physics = require("physics")
local sprite = require("modules.sprite")
local storyboard = require("modules.storyboard")

local bounceTrap = {}

local LIFETIME = 30000
local OWNER_GRACE = 500
local BODY_SHAPE = { 29.5, -5, 29.5, 19, 6.5, 19, 6.5, -5 }
local SENSOR_SHAPE = { 15.5, -5, 15.5, 19, 6.5, 19, 6.5, -5 }

function bounceTrap.new(ownerId, owner, x, y, group, players)
  local object
  local triggered = false
  local canHitPlayer = true
  local canHitOther = true
  local ownerGrace = true

  local function endGrace()
    ownerGrace = false
  end

  local function play()
    object:prepare("play")
    object:play()
    triggered = true
  end

  local function reset()
    object:prepare("reset")
    object:play()
    triggered = false
  end

  local function onSprite(event)
    if event.phase == "ended" and triggered then
      reset()
    end
  end

  local function removeObject()
    if object then
      object:removeEventListener("sprite", onSprite)
      object:removeEventListener("collision", object)
      display.remove(object)
      object = nil
    end
  end

  local function onCollision(_, event)
    if event.phase ~= "began" then
      return
    end
    local other = event.other
    local spring = true
    if other.id == ownerId and ownerGrace then
      spring = false
    elseif other.mobileUser then
      if canHitPlayer then
        canHitPlayer = false
        other.onCollisionPowerUp(ownerId, 8)
      end
    elseif other.onCollisionPowerUp and canHitOther then
      canHitOther = false
      other.onCollisionPowerUp(ownerId, 8)
    end
    if other.player and spring then
      play()
    end
  end

  players[ownerId].removeBounceTrapAnimation()
  object = sprite.newSprite(storyboard.gameDataTable.animations.bounceTrapSet)
  physics.addBody(object,
    { density = 0.6, friction = 1, bounce = 0.3, shape = BODY_SHAPE, filter = powerUpFilter },
    { isSensor = true, shape = SENSOR_SHAPE, filter = obstacleFilter })
  object.collision = onCollision
  object:addEventListener("collision", object)
  object.xScale, object.yScale = 0.5, 0.5
  object.update = function() end
  object.removeObject = removeObject
  object:addEventListener("sprite", onSprite)
  if owner then
    object.x, object.y = owner.x - 15, owner.y
  else
    object.x, object.y = x, y
  end
  group:insert(object)

  timer.performWithDelay(OWNER_GRACE, endGrace, 1)
  timer.performWithDelay(LIFETIME, removeObject, 1)
  return object
end

return bounceTrap
