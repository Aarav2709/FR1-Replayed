-- power up manager.

local blade = require("modules.powerups.blade")
local trap = require("modules.powerups.trap")
local bounceTrap = require("modules.powerups.bounceTrap")
local lightning = require("modules.powerups.lightning")
local magnet = require("modules.powerups.magnet")
local ninja = require("modules.powerups.ninja")
local jump = require("modules.powerups.jump")

local powerUps = {}

local active = {}
local updateTimer
local playSound

function powerUps.usePowerUp(powerUpId, userId, localUsername, user, x, y, gameGroup, sceneView, players)
  if not (players and gameGroup and sceneView and powerUpId) then
    return 1, 1
  end
  local slot = #active + 1
  local object
  if powerUpId == 1 then
    object = blade.new(userId, user, x, y, gameGroup, players)
    active[slot] = object
    players[userId].playSound("blade_activate")
  elseif powerUpId == 2 then
    object = trap.new(userId, user, x, y, gameGroup, players)
    active[slot] = object
    players[userId].playSound("trap_activate")
  elseif powerUpId == 3 then
    object = lightning.new(userId, localUsername, players)
    active[slot] = object
    playSound("lightning_activate")
  elseif powerUpId == 4 then
    players[userId].speedPowerUp()
    object = { x = 1, y = 1 }
    players[userId].playSound("speed_activate")
  elseif powerUpId == 5 then
    players[userId].shieldPowerUp()
    object = { x = 1, y = 1 }
    players[userId].playSound("invul_activate")
  elseif powerUpId == 6 then
    players[userId].armorPowerUp()
    object = { x = 1, y = 1 }
    players[userId].playSound("armor_activate")
  elseif powerUpId == 7 then
    object = magnet.new(userId, localUsername, players)
    players[userId].playSound("magnet_activate")
  elseif powerUpId == 8 then
    object = bounceTrap.new(userId, user, x, y, gameGroup, players)
    active[slot] = object
    players[userId].playSound("bounce_activate")
  elseif powerUpId == 9 then
    object = ninja.new(userId, localUsername, players)
    active[slot] = object
    players[userId].playSound("blade_activate")
  elseif powerUpId == 10 then
    object = jump.new(userId, players)
    active[slot] = object
    players[userId].playSound("bounce_activate")
  elseif powerUpId == 51 then
    players[userId].createBladeAnimation()
    object = { x = 1, y = 1 }
  elseif powerUpId == 52 then
    players[userId].createTrapAnimation()
    object = { x = 1, y = 1 }
  elseif powerUpId == 57 then
    players[userId].createMagnetAnimation()
    object = { x = 1, y = 1 }
  elseif powerUpId == 58 then
    players[userId].createBounceTrapAnimation()
    object = { x = 1, y = 1 }
  end
  if object == nil then
    return 1, 1
  end
  return object.x, object.y
end

function powerUps.getPowerUps()
  return active
end

local function updateAll()
  for i = 1, #active do
    local object = active[i]
    if object and object.update then
      object.update()
    end
  end
end

function powerUps.clean()
  if updateTimer then
    timer.cancel(updateTimer)
    updateTimer = nil
  end
  for i = 1, #active do
    local object = active[i]
    if object then
      if object.removeObject then
        object.removeObject()
      end
      active[i] = nil
    end
  end
end

function powerUps.init()
  active = {}
  updateTimer = timer.performWithDelay(100, updateAll, 0)
end

function powerUps.addPlaySoundFunction(fn)
  playSound = fn
end

return powerUps
