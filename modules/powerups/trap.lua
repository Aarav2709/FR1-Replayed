-- trap.

local physics = require("physics")
local sprite = require("modules.sprite")
local storyboard = require("modules.storyboard")

local trap = {}

local LIFETIME = 30000
local OWNER_GRACE = 500
local BODY_SHAPE = { 20, 0, 20, 18, -20, 18, -20, 0 }
local SENSOR_SHAPE = { 26, 0, 26, 18, 15, 18, 15, 0 }

function trap.new(ownerId, owner, x, y, group, players)
  local object
  local closed = false
  local armed = true
  local ownerGrace = true

  local function endGrace()
    ownerGrace = false
  end

  local function close()
    object:prepare("close")
    object:play()
    closed = true
  end

  local function open()
    object:prepare("open")
    object:play()
    closed = false
  end

  local function onSprite(event)
    if event.phase == "ended" and closed then
      open()
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

  local function rearm()
    armed = true
  end

  local function hit(racer)
    armed = false
    racer.onCollisionPowerUp(ownerId, 2)
    timer.performWithDelay(1000, rearm, 1)
  end

  local function onCollision(_, event)
    if event.phase ~= "began" then
      return
    end
    local other = event.other
    local snap = true
    if other.id == ownerId and ownerGrace then
      snap = false
    elseif other.mobileUser and armed then
      hit(other)
    elseif armed and other.onCollisionPowerUp then
      hit(other)
    end
    if other.player and snap then
      close()
    end
  end

  players[ownerId].removeTrapAnimation()
  object = sprite.newSprite(storyboard.gameDataTable.animations.trapSet)
  physics.addBody(object,
    { density = 0.6, friction = 1, bounce = 0.3, shape = BODY_SHAPE, filter = powerUpFilter },
    { isSensor = true, shape = SENSOR_SHAPE, filter = obstacleFilter })
  object.xScale, object.yScale = 0.5, 0.5
  object.update = function() end
  object.removeObject = removeObject
  object.collision = onCollision
  object:addEventListener("collision", object)
  object:addEventListener("sprite", onSprite)
  if owner then
    object.x, object.y = owner.x, owner.y
  else
    object.x, object.y = x, y
  end
  group:insert(object)

  timer.performWithDelay(OWNER_GRACE, endGrace, 1)
  timer.performWithDelay(LIFETIME, removeObject, 1)
  return object
end

return trap
