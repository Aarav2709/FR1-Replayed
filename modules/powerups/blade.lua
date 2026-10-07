-- blade.

local physics = require("physics")

local blade = {}

local MAX_SPEED = 610
local LIFETIME = 6000
local OWNER_GRACE = 500
local SHAPE = { 7, 17, -7, 17, -17, 7, -17, -7, -7, -17, 7, -17, 17, -7, 17, 7 }

function blade.new(ownerId, owner, x, y, group, players)
  local object = display.newGroup()
  local removed = false
  local image, bloodyImage
  local ownerGrace = true

  local function endGrace()
    ownerGrace = false
  end

  local function spin()
    if object and not removed then
      local vx = object:getLinearVelocity()
      image:rotate(vx * 0.05 / FORCE_SCALE)
      bloodyImage:rotate(vx * 0.05 / FORCE_SCALE)
    end
  end

  local function update()
    if object and not removed then
      local vx, vy = object:getLinearVelocity()
      if vx < 0 and vx > -MAX_SPEED then
        vx = vx - 40
      elseif vx > 0 and vx < MAX_SPEED then
        vx = vx + 40
      end
      object:setLinearVelocity(vx, vy)
    end
  end

  local function removeObject()
    removed = true
    if object then
      Runtime:removeEventListener("enterFrame", spin)
      object:removeEventListener("collision", object)
      display.remove(object)
      object = nil
    end
  end

  local function changeImage()
    bloodyImage.alpha = 1
    image.alpha = 0
  end
  object.changeImage = changeImage

  local function onCollision(_, event)
    if event.phase == "began" then
      local other = event.other
      if other.id == ownerId and ownerGrace then
        return
      end
      if other.onCollisionPowerUp and other.onCollisionPowerUp(ownerId, 1) == 1 then
        changeImage()
      end
    end
  end

  image = display.newImageRect("images/game/powerup/blade/blade.png", 40, 40)
  bloodyImage = display.newImageRect("images/game/powerup/blade/blade_blood.png", 40, 40)
  bloodyImage.alpha = 0
  object:insert(image)
  object:insert(bloodyImage)
  physics.addBody(object,
    { density = 0.6, friction = 0.1, bounce = 0.5, shape = SHAPE, filter = powerUpFilter },
    { isSensor = true, radius = 18, filter = sensorFilter })
  object.collision = onCollision
  object:addEventListener("collision", object)
  object.isFixedRotation = true
  object.update = update
  object.removeObject = removeObject
  group:insert(object)
  Runtime:addEventListener("enterFrame", spin)

  players[ownerId].removeBladeAnimation()
  object:setLinearVelocity(MAX_SPEED, 5)
  object:applyForce(50 * FORCE_SCALE, 0, 0, -20)
  object:applyForce(-50 * FORCE_SCALE, 0, 0, 20)
  if owner then
    object.x = owner.x
    object.y = owner.y - 2
  else
    object.x = x
    object.y = y
  end

  timer.performWithDelay(OWNER_GRACE, endGrace, 1)
  timer.performWithDelay(LIFETIME, removeObject, 1)
  return object
end

return blade
