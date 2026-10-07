-- racer.

local physics = require("physics")
local sprite = require("modules.sprite")
local storyboard = require("modules.storyboard")
local accessories = require("modules.accessories")
local createSprite = require("modules.createSprite")
local botModule = require("modules.botModule")
local playerCorpses = require("modules.playerCorpses")
local spriteSheets = require("modules.spriteSheets")

local player = {}

local PU_NONE, PU_BLADE, PU_TRAP, PU_LIGHTNING, PU_SPEED = 0, 1, 2, 3, 4
local PU_SHIELD, PU_ARMOR, PU_MAGNET, PU_BOUNCE_TRAP, PU_NINJA, PU_JUMP = 5, 6, 7, 8, 9, 10

local HIT_KILLED, HIT_ARMOR, HIT_SHIELD, HIT_PUSHED = 1, 2, 3, 4

local SURFACE_NORMAL, SURFACE_BOOST, SURFACE_SLOW = 1, 3, 4

local HEAD_BAR_OFFSETS = {
  fox = { 2, -3 }, bear = { 7, -3 }, turtle = { 8, -3 }, skunk = { 6, -2 }, bunny = { 5, -3 },
  panda = { 5, 0 }, doe = { 2, -2 }, beaver = { 5, -4 }, parrot = { 2, 1 }, penguin = { 3, 0 },
  cat = { 1, 2 }, squirrel = { 4, 0 }, gecko = { 4, 0 }, polarbear = { 4, -1 }, cheeta = { 2, 2 },
  mouse = { 4, 0 }, panther = { 4, 1 }, tiger = { 2, -3 }, whiteTiger = { 2, -2 }, crocodile = { 5, -3 },
  camel = { 1, 0 }, unicorn = { 2, -3 }, hedgehog = { nil, 2 },
}

local LEGS_SHAPE = { 15, -9, 15, 7, -15, 7, -15, -9 }
local MIDDLE_SHAPE = { 12, 12, 9, 15, 4, 17, -4, 17, -9, 15, -12, 12, -15, 7, 15, 7 }
local HEAD_SHAPE = { -15, -9, -4, -18, 4, -18, 15, -9 }

local function round2(value)
  return math.floor(value * 100) * 0.01
end

function player.new(id, username, avatarData, startPowerUp, isLocal, players, startY, remoteHuman)
  local body = display.newGroup()
  local ghost = display.newGroup()
  local avatarGroup = display.newGroup()
  local effectsGroup = display.newGroup()
  local screenGroup = display.newGroup()
  local headMarker = display.newGroup()
  local bot

  local icons = {
    bladeImage = display.newImageRect("images/game/powerup/blade/blade.png", 25, 25),
    trapImage = display.newImageRect("images/game/powerup/trap/icon.png", 25, 25),
    bounceTrapImage = display.newImageRect("images/game/powerup/bounceTrap/icon.png", 25, 25),
    ninjaPlayerImage = display.newImageRect("images/game/powerup/ninja/arrow.png", 15, 15),
    ninjaBarImage = display.newImageRect("images/game/powerup/ninja/arrow.png", 15, 15),
  }

  local speed = {
    defaultTopSpeed = 350,
    defaultAcceleration = 30,
    topSpeedX = 350,
    accelerateX = 25,
    tempSpeedX = 350,
  }
  speed.boostMaks = speed.topSpeedX * 1.5
  speed.boostMaksSlide = speed.topSpeedX * 2
  speed.slowMaks = speed.topSpeedX * 0.4

  local stats = {
    groundTime = 0,
    playerDeadtime = 3000,
    goalTime = -1,
    powerUpAtTimes = 0,
    lastJumpTime = 1000,
    currentGameTime = -1,
    currentUDID = -1,
  }

  local surface = SURFACE_NORMAL
  local ninjaTarget = id + 1
  if ninjaTarget > #players then
    ninjaTarget = 1
  end
  local VELOCITY_SAMPLES = 6
  local racePosition, activeRacers = -1, 1

  local impulseState = 0
  local lastPowerUpX = 0
  local lastPickupTime = 0
  local powerUp = startPowerUp
  if storyboard.config.tutorial then
    powerUp = PU_NONE
  end

  local state = {
    armorActive = false,
    shieldActive = false,
    spriteIsRunning = false,
    spriteIsInAir = false,
    playerDead = false,
    playerInvulnerable = false,
    speedActive = false,
    disconnected = false,
    startedClean = false,
    tutorialPause = false,
  }

  local corpse = playerCorpses.newCorpsParts(effectsGroup, body)
  local velocityHistory = {}
  local ninjaMarkTimer, ninjaTimer
  local hitListener
  local endProtections
  local powerUpImageListener
  local avatarIndex, isOldAvatar

  local CHANNELS_PER_PLAYER = 5
  local channels = {}
  for i = 1, CHANNELS_PER_PLAYER do
    channels[i] = (id - 1) * CHANNELS_PER_PLAYER + i
  end
  local nextChannel = 1
  local currentVolume = -1
  local soundPlayer
  local playSound
  local killMessage

  local sprites = {}
  local disconnectedIcon = display.newImageRect("images/game/avatar/disconnected.png", 18, 18)
  local headMarkerImage
  if isLocal then
    headMarkerImage = display.newImageRect("images/game/playerPlaceSelf.png", 28, 33)
  else
    headMarkerImage = display.newImageRect("images/game/playerPlaceOthers.png", 28, 33)
  end
  local HEAD_BAR_SCALE = 0.2
  local ghostMarker = display.newImageRect("images/game/playerPlaceSelf.png", 28, 33)
  ghostMarker.isVisible = false
  ghost:insert(ghostMarker)

  for i = 1, 4 do
    if avatarData[i] >= 100 then
      avatarData[i] = accessories.getTableIndex(avatarData[i])
    end
  end
  local avatars = accessories.getAvatarList()
  if avatarData[1] > #avatars then
    avatarData[1] = 1
  end
  if avatarData[2] > #accessories.getHatList(avatarData[1]) then
    avatarData[2] = 1
  end
  if avatarData[3] > #accessories.getItemList(avatarData[1]) then
    avatarData[3] = 1
  end
  if avatarData[4] > #accessories.getBootsList(avatarData[1]) then
    avatarData[4] = 1
  end
  avatarIndex = avatarData[1]
  isOldAvatar = accessories.isOldAvtar(avatarIndex)

  sprites.spriteBody = createSprite.changeSpriteAvatar(avatarData[1], nil, id)
  sprites.spriteHat = createSprite.changeSpriteHat(avatarData[2], nil, id)
  sprites.spriteHeadBar = createSprite.changeSpriteHat(avatarData[2], nil, id)
  sprites.spriteItem = createSprite.changeSpriteItem(avatarData[3], nil, id)
  sprites.spriteItemSet = createSprite.getSpriteItemSet(id)
  sprites.spriteBoots = createSprite.changeSpriteBoots(avatarData[4], nil, id)
  sprites.spriteHat.y = -6
  sprites.spriteHeadBar.xScale = HEAD_BAR_SCALE
  sprites.spriteHeadBar.yScale = HEAD_BAR_SCALE
  sprites.spriteBody.xScale, sprites.spriteBody.yScale = 0.24, 0.24
  sprites.spriteBoots.xScale, sprites.spriteBoots.yScale = 0.24, 0.24
  if sprites.spriteItem then
    sprites.spriteItem.xScale, sprites.spriteItem.yScale = 0.24, 0.24
    sprites.spriteItem.alpha = 0
  end
  sprites.spriteHat.xScale, sprites.spriteHat.yScale = 0.24, 0.24

  local function hideAvatar()
    avatarGroup.alpha = 0
  end

  local function endInvulnerability()
    avatarGroup.alpha = 1
    state.playerInvulnerable = false
  end

  local function startRespawnProtection()
    avatarGroup.alpha = 0.4
    timer.performWithDelay(stats.playerDeadtime - 1000, endInvulnerability, 1)
  end

  local effectSheetName = avatars[avatarData[1]][8]
  local effectSheet = sprite.newSpriteSheetFromData("images/game/avatar/" .. effectSheetName .. ".png",
    spriteSheets.get(effectSheetName))
  local headDeathSet = sprite.newSpriteSet(effectSheet, 1, 8)
  sprite.add(headDeathSet, "normal", 1, 7, 1000, 1)
  sprite.add(headDeathSet, "head", 8, 1, 1000, 1)
  local lightningDeathSet = sprite.newSpriteSet(effectSheet, 9, 4)
  sprite.add(lightningDeathSet, "normal", 1, 2, 300, 2)
  sprite.add(lightningDeathSet, "head", 3, 1, 1000, 1)
  local bladeDeathSet = sprite.newSpriteSet(effectSheet, 12, 7)
  sprite.add(bladeDeathSet, "normal", 1, 6, 600, 1)
  sprite.add(bladeDeathSet, "head", 7, 1, 1000, 1)
  local speedSet = sprite.newSpriteSet(effectSheet, 19, 5)
  sprite.add(speedSet, "normal", 1, 5, 500, 8)
  corpse.addSpriteSet(lightningDeathSet, headDeathSet, bladeDeathSet)

  local function removeParticle(particle)
    if particle and not state.startedClean then
      display.remove(particle)
    end
  end

  local function spawnItemParticle()
    if avatarData[3] > 1 and not state.playerDead then
      local particle = sprite.newSprite(sprites.spriteItemSet)
      particle:prepare("normal")
      particle:setFrame(math.random(5))
      particle.xScale, particle.yScale = 0.5, 0.5
      particle.x = body.x
      particle.y = body.y + math.random(-20, 20)
      effectsGroup:insert(particle)
      transition.to(particle, { time = 500, delay = 200, alpha = 0, onComplete = removeParticle })
    end
  end

  local function newEffectSprite(set, yOffset)
    local effect = sprite.newSprite(set)
    effect.xScale, effect.yScale = 0.6, 0.6
    effect.alpha = 0
    if not isOldAvatar then
      effect.y = yOffset
    end
    return effect
  end

  local function hideOnEnd(effect)
    return function(event)
      if event.phase == "ended" then
        effect.alpha = 0
      end
    end
  end

  local function playEffect(effect)
    return function()
      effect.alpha = 1
      effect:prepare("normal")
      effect.rotation = avatarGroup.rotation
      effect:play()
    end
  end

  local headDeath = newEffectSprite(headDeathSet, -6)
  local onHeadDeathSprite = hideOnEnd(headDeath)
  local playHeadDeath = playEffect(headDeath)

  local bladeDeath = newEffectSprite(bladeDeathSet, -6)
  local onBladeDeathSprite = hideOnEnd(bladeDeath)
  local playBladeDeath = playEffect(bladeDeath)

  local lightningDeath = newEffectSprite(lightningDeathSet, -6)
  local onLightningDeathSprite = hideOnEnd(lightningDeath)
  local playLightningDeath = playEffect(lightningDeath)

  local lightningBolt = sprite.newSprite(storyboard.gameDataTable.animations.lightningBoltSet)
  lightningBolt.xScale, lightningBolt.yScale = 0.5, 0.5
  lightningBolt.alpha = 0
  effectsGroup:insert(lightningBolt)

  local function showLightningBolt()
    lightningBolt.alpha = 1
    lightningBolt.x = body.x + 10
    lightningBolt.y = body.y - 110
    lightningBolt:prepare("normal")
    lightningBolt:play()
  end

  local onLightningBoltSprite = hideOnEnd(lightningBolt)

  local cloudTop, cloudBottom, lightningBackground
  if isLocal then
    local cloudWidth = math.max(530, display.contentWidth + 50)
    cloudBottom = display.newImageRect("images/game/powerup/lightning/cloudBottom.png", cloudWidth, 94)
    cloudBottom.anchorX, cloudBottom.anchorY = 1, 0
    cloudBottom.x, cloudBottom.y = display.contentWidth, 0
    cloudBottom.alpha = 0
    cloudTop = display.newImageRect("images/game/powerup/lightning/cloudTop.png", cloudWidth, 94)
    cloudTop.anchorX, cloudTop.anchorY = 0, 0
    cloudTop.x, cloudTop.y = 0, 0
    cloudTop.alpha = 0
    lightningBackground = display.newImageRect("images/game/powerup/lightning/lightningBackground.png",
      display.contentWidth, display.contentHeight)
    lightningBackground.x = display.contentWidth * 0.5
    lightningBackground.y = display.contentHeight * 0.5
    lightningBackground.alpha = 0
    screenGroup:insert(lightningBackground)
    screenGroup:insert(cloudBottom)
    screenGroup:insert(cloudTop)
  end

  local function resetClouds()
    cloudBottom.alpha = 0
    cloudTop.alpha = 0
    cloudBottom.x = display.contentWidth
    cloudTop.x = 0
  end

  local function showCloud()
    if isLocal then
      lightningBackground.alpha = 0.7
      transition.to(lightningBackground, { delay = 800, time = 1200, alpha = 0 })
      cloudBottom.alpha = 1
      cloudTop.alpha = 1
      transition.to(cloudBottom, { x = display.contentWidth + 50, time = 1500 })
      transition.to(cloudTop, { x = -50, time = 1500 })
      transition.to(cloudBottom, { delay = 1200, time = 500, alpha = 0 })
      transition.to(cloudTop, { delay = 1200, time = 500, alpha = 0 })
      timer.performWithDelay(2200, resetClouds, 1)
    end
  end

  local speedEffect = sprite.newSprite(speedSet)
  speedEffect.xScale, speedEffect.yScale = 0.6, 0.6
  speedEffect.alpha = 0
  speedEffect.x = -3
  if not isOldAvatar then
    speedEffect.y = -5
  end

  local function endSpeed()
    if speedEffect and not state.startedClean then
      speedEffect:pause()
      state.speedActive = false
      speedEffect.alpha = 0
      speed.topSpeedX = speed.defaultTopSpeed
      speed.tempSpeedX = speed.topSpeedX
      speed.accelerateX = speed.defaultAcceleration
    end
  end

  local function startSpeedEffect()
    speedEffect.alpha = 1
    speedEffect:prepare("normal")
    speedEffect:play()
  end

  local function onSpeedSprite(event)
    if event.phase == "ended" and state.speedActive and not state.playerDead then
      endSpeed(true)
    end
  end

  local armorEffect = sprite.newSprite(storyboard.gameDataTable.animations.armorSpriteSet)
  armorEffect.xScale, armorEffect.yScale = 0.6, 0.6
  armorEffect.alpha = 0

  local function endArmor()
    state.armorActive = false
    armorEffect.alpha = 0
    armorEffect:pause()
  end

  local function startArmorEffect()
    armorEffect.alpha = 1
    armorEffect:prepare("normal")
    armorEffect:play()
  end

  local function playJumpEffect()
    local cloud = display.newImageRect("images/game/powerup/jump/cloud.png", 45, 20)
    cloud.x = body.x
    cloud.y = body.y + 20
    effectsGroup:insert(cloud)
    transition.to(cloud, { time = 1000, alpha = 0 })
  end

  local magnetUse = sprite.newSprite(storyboard.gameDataTable.animations.magnetUse)
  magnetUse.xScale, magnetUse.yScale = 0.5, 0.5
  magnetUse.alpha = 0
  magnetUse.y = -45

  local function onMagnetUseSprite(event)
    if event.phase == "ended" then
      transition.to(magnetUse, { time = 200, alpha = 0 })
      magnetUse:pause()
    end
  end

  local function playMagnetUse()
    magnetUse.alpha = 1
    magnetUse:prepare("normal")
    magnetUse:play()
  end

  local magnetHit = sprite.newSprite(storyboard.gameDataTable.animations.magnetEffect)
  magnetHit.xScale, magnetHit.yScale = 0.24, 0.24
  magnetHit.alpha = 0

  local function onMagnetHitSprite(event)
    if event.phase == "ended" then
      magnetHit.alpha = 0
      magnetHit:pause()
    end
  end

  local function playMagnetHit()
    magnetHit.alpha = 1
    magnetHit:prepare("normal")
    magnetHit:play()
  end

  local shieldEffect = sprite.newSprite(storyboard.gameDataTable.animations.shieldSpriteSet)
  shieldEffect.xScale, shieldEffect.yScale = 0.6, 0.6
  shieldEffect.alpha = 0

  local function endShield()
    state.shieldActive = false
    shieldEffect.alpha = 0
    shieldEffect:pause()
  end

  local function onShieldSprite(event)
    if not event or event.phase ~= "ended" then
      return
    end
    if shieldEffect.animationType == 1 then
      shieldEffect:prepare("shieldActive")
      shieldEffect:play()
      shieldEffect.animationType = 2
    elseif shieldEffect.animationType == 2 then
      shieldEffect:prepare("shieldEnd")
      shieldEffect:play()
      shieldEffect.animationType = 3
    elseif shieldEffect.animationType == 3 then
      endShield()
    end
  end

  local function startShieldEffect()
    shieldEffect.animationType = 1
    shieldEffect.alpha = 1
    shieldEffect:prepare("shieldStart")
    shieldEffect:play()
  end

  local bloodBottomLeft, bloodTopLeft, bloodTopRight
  if isLocal then
    bloodBottomLeft = display.newImageRect("images/game/powerup/bloodScreenBL.png", 365, 88)
    bloodBottomLeft.anchorX, bloodBottomLeft.anchorY = 0, 1
    bloodBottomLeft.x, bloodBottomLeft.y = 0, display.contentHeight
    bloodBottomLeft.alpha = 0
    screenGroup:insert(bloodBottomLeft)
    bloodTopLeft = display.newImageRect("images/game/powerup/bloodScreenTL.png", 137, 116)
    bloodTopLeft.anchorX, bloodTopLeft.anchorY = 0, 0
    bloodTopLeft.x, bloodTopLeft.y = 0, 0
    bloodTopLeft.alpha = 0
    screenGroup:insert(bloodTopLeft)
    bloodTopRight = display.newImageRect("images/game/powerup/bloodScreenTR.png", 216, 140)
    bloodTopRight.anchorX, bloodTopRight.anchorY = 1, 0
    bloodTopRight.x, bloodTopRight.y = display.contentWidth, 0
    bloodTopRight.alpha = 0
    screenGroup:insert(bloodTopRight)
  end

  local function showNextBloodSplatter()
    if bloodBottomLeft.alpha == 0 then
      bloodBottomLeft.alpha = 1
    elseif bloodTopRight.alpha == 0 then
      bloodTopRight.alpha = 1
    elseif bloodTopLeft.alpha == 0 then
      bloodTopLeft.alpha = 1
    end
  end

  local function fadeBlood()
    transition.to(bloodBottomLeft, { time = 300, alpha = 0 })
    transition.to(bloodTopRight, { time = 300, alpha = 0 })
    transition.to(bloodTopLeft, { time = 300, alpha = 0 })
  end

  local function showBlood()
    if isLocal then
      showNextBloodSplatter()
      playSound("blood")
      timer.performWithDelay(125, showNextBloodSplatter, 1)
      timer.performWithDelay(250, showNextBloodSplatter, 1)
      timer.performWithDelay(375, showNextBloodSplatter, 1)
      timer.performWithDelay(800, fadeBlood, 1)
    end
  end

  local function setPlayerPosition(position, racers)
    racePosition = position
    activeRacers = racers
  end

  local function setUpdatePowerUpImageFunction(fn)
    powerUpImageListener = fn
  end

  local function removeNinjaMark()
    if not state.startedClean then
      icons.ninjaPlayerImage.alpha = 0
      icons.ninjaBarImage.alpha = 0
      body.ninjaMark = false
    end
  end

  local function addNinjaMark()
    if not state.startedClean then
      if not isLocal then
        icons.ninjaPlayerImage.alpha = 1
      end
      icons.ninjaBarImage.alpha = 1
      if ninjaMarkTimer then
        timer.cancel(ninjaMarkTimer)
        ninjaMarkTimer = nil
      end
      ninjaMarkTimer = timer.performWithDelay(500, removeNinjaMark, 1)
      body.ninjaMark = true
    end
  end

  local function canBeNinjaTarget(index)
    if index > #players then
      return false
    end
    return not players[index].isDisconnected()
  end

  local function cycleNinjaTarget()
    if powerUp == PU_NINJA and not state.startedClean and stats.goalTime < 1 then
      if ninjaTimer == nil then
        ninjaTarget = math.random(1, #players)
        if ninjaTarget == id then
          ninjaTarget = ninjaTarget + 1
        end
      end
      local attempts = 8
      while not canBeNinjaTarget(ninjaTarget) do
        ninjaTarget = ninjaTarget + 1
        if ninjaTarget > #players then
          ninjaTarget = 1
        end
        attempts = attempts - 1
        if attempts < 0 then
          break
        end
      end
      if attempts < 0 then
        ninjaTarget = id
      end
      players[ninjaTarget].addNinjaMark()
      ninjaTarget = ninjaTarget + 1
      ninjaTimer = timer.performWithDelay(501, cycleNinjaTarget, 1)
    else
      ninjaTimer = nil
    end
  end

  local function choosePowerUp()
    local roll = math.random(1, 100)
    lastPowerUpX = body.x
    if racePosition == activeRacers then
      if roll > 75 then powerUp = PU_LIGHTNING
      elseif roll > 45 then powerUp = PU_MAGNET
      elseif roll > 20 then powerUp = PU_SPEED
      elseif roll > 10 then powerUp = PU_NINJA
      elseif roll > 5 then powerUp = PU_JUMP
      else powerUp = PU_SHIELD end
    elseif racePosition == 1 then
      if roll > 82 then powerUp = PU_BLADE
      elseif roll > 64 then powerUp = PU_BOUNCE_TRAP
      elseif roll > 46 then powerUp = PU_TRAP
      elseif roll > 33 then powerUp = PU_NINJA
      elseif roll > 23 then powerUp = PU_JUMP
      elseif roll > 10 then powerUp = PU_SPEED
      else powerUp = PU_SHIELD end
    else
      if roll > 89 then powerUp = PU_BLADE
      elseif roll > 82 then powerUp = PU_JUMP
      elseif roll > 70 then powerUp = PU_NINJA
      elseif roll > 60 then powerUp = PU_MAGNET
      elseif roll > 50 then powerUp = PU_TRAP
      elseif roll > 40 then powerUp = PU_BOUNCE_TRAP
      elseif roll > 30 then powerUp = PU_LIGHTNING
      elseif roll > 20 then powerUp = PU_SPEED
      elseif roll > 10 then powerUp = PU_SHIELD
      else powerUp = PU_ARMOR end
    end
    if activeRacers == 1 then
      if roll > 87 then powerUp = PU_BLADE
      elseif roll > 75 then powerUp = PU_TRAP
      elseif roll > 62 then powerUp = PU_LIGHTNING
      elseif roll > 50 then powerUp = PU_SPEED
      elseif roll > 38 then powerUp = PU_SHIELD
      elseif roll > 25 then powerUp = PU_ARMOR
      elseif roll > 12 then powerUp = PU_MAGNET
      elseif roll > 5 then powerUp = PU_BOUNCE_TRAP
      else powerUp = PU_NINJA end
    end
    if storyboard.config.tutorial then
      powerUp = PU_SPEED
    end
    if isLocal then
      powerUpImageListener(powerUp)
      if powerUp == PU_NINJA then
        if ninjaTimer then
          timer.cancel(ninjaTimer)
          ninjaTimer = nil
        end
        cycleNinjaTarget()
      end
    end
  end

  local function getPowerUp()
    if powerUp == PU_BLADE then
      powerUp = 50 + PU_BLADE
    elseif powerUp == PU_TRAP then
      powerUp = 50 + PU_TRAP
    elseif powerUp == PU_MAGNET then
      powerUp = 50 + PU_MAGNET
    elseif powerUp == PU_BOUNCE_TRAP then
      powerUp = 50 + PU_BOUNCE_TRAP
    end
    if state.playerDead then
      return 0
    end
    return powerUp
  end

  local function isCrateAt(x, y, index)
    local crate = storyboard.powerUpPositions[index]
    return math.abs(tonumber(x) - tonumber(crate[1])) < 2 and math.abs(tonumber(y) - tonumber(crate[2])) < 2
  end

  local function setPowerUp(x, y, powerUpId)
    for i = 1, #storyboard.powerUpPositions do
      if isCrateAt(x, y, i) then
        local pickups = storyboard.powerUpPositions[i]
        if pickups[id + 2] < 2 then
          powerUp = PU_BLADE
          if powerUpId < 50 then
            pickups[id + 2] = pickups[id + 2] + 1
          end
        end
      end
    end
  end

  local function canOtherPlayerUsePU()
    return true
  end

  local function usedPowerUp()
    powerUp = PU_NONE
  end

  local function pauseSprite()
    if state.spriteIsRunning and not state.startedClean then
      state.spriteIsRunning = false
      sprites.spriteBody:pause()
      sprites.spriteBoots:pause()
      sprites.spriteHat:pause()
    end
  end

  local function tutorialPause(paused)
    if paused == true then
      state.tutorialPause = true
      pauseSprite()
    else
      state.tutorialPause = false
    end
  end

  local function showInAirFrame()
    if not state.spriteIsInAir and not state.startedClean then
      state.spriteIsInAir = true
      sprites.spriteBody:setFrame(4)
      sprites.spriteBoots:setFrame(4)
      sprites.spriteBody:pause()
      sprites.spriteBoots:pause()
      sprites.spriteHat:setFrame(4)
      sprites.spriteHat:pause()
    end
  end

  local function resumeRunAnimation()
    if stats.goalTime > 0 or state.tutorialPause then
      return
    end
    if state.spriteIsInAir and not state.startedClean then
      state.spriteIsInAir = false
      sprites.spriteBody:play()
      sprites.spriteBoots:play()
      sprites.spriteHat:play()
    end
  end

  local function checkStillInAir()
    if body and system.getTimer() > stats.groundTime + 300 then
      body.onGround = false
      showInAirFrame()
    end
  end

  local function updateRunAnimation(vx)
    if stats.goalTime > 0 or state.tutorialPause then
      return
    end
    if not state.spriteIsRunning and not state.startedClean then
      state.spriteIsRunning = true
      sprites.spriteBody:prepare("normal")
      sprites.spriteBody:play()
      sprites.spriteBoots:prepare("normal")
      sprites.spriteBoots:play()
      sprites.spriteHat:prepare("normal")
      sprites.spriteHat:play()
    end
    local timeScale = vx / speed.topSpeedX
    if timeScale < 0.05 then
      timeScale = 0.05
    end
    local bodyFrame = sprites.spriteBody.frame
    local bootsFrame = sprites.spriteBoots.frame
    local hatFrame = sprites.spriteHat.frame
    sprites.spriteBody.timeScale = timeScale
    sprites.spriteBoots.timeScale = timeScale
    sprites.spriteHat.timeScale = timeScale
    sprites.spriteBody:setFrame(bodyFrame)
    sprites.spriteBoots:setFrame(bootsFrame)
    sprites.spriteHat:setFrame(hatFrame)
  end

  local function restoreCrateBlend(crates)
    if crates then
      crates[1].blendMode = "normal"
    end
  end

  local function canPickUp()
    if lastPickupTime + 500 > system.getTimer() then
      return false
    end
    if body.x > lastPowerUpX + 100 then
      stats.powerUpAtTimes = 1
      return true
    end
    if stats.powerUpAtTimes < 2 then
      stats.powerUpAtTimes = stats.powerUpAtTimes + 1
      return true
    end
    return false
  end

  local function setVelocity(vx, vy)
    body:setLinearVelocity(vx, vy)
    ghost:setLinearVelocity(vx, vy)
  end

  local function applyForceBoth(fx, fy)
    fx, fy = fx * FORCE_SCALE, fy * FORCE_SCALE
    body:applyForce(fx, fy, body.x, body.y)
    ghost:applyForce(fx, fy, ghost.x, ghost.y)
  end

  local function onCollision(_, event)
    local other = event.other
    if event.phase == "began" then
      if other.mapElement then
        body.onGround = true
        resumeRunAnimation()
        stats.groundTime = system.getTimer()
        if other.bounce then
          impulseState = 1
          local vx, vy = body:getLinearVelocity()
          if math.abs(vy) > 100 then
            vx = vx * 0.7
          end
          local bounceVy = -math.abs(vy * 1.3)
          if bounceVy < -700 then
            bounceVy = -700
          end
          setVelocity(vx, bounceVy)
          surface = SURFACE_NORMAL
          impulseState = 2
        elseif other.boost then
          impulseState = 1
          local vx, vy = body:getLinearVelocity()
          if vx < speed.boostMaks then
            if vx < 0 then
              vx = vx * 0.7
            else
              vx = vx * 1.3
            end
            if vx > speed.boostMaks then
              vx = speed.boostMaks
            end
            setVelocity(vx, vy)
          end
          surface = SURFACE_BOOST
          impulseState = 2
        elseif other.boost2 then
          impulseState = 1
          local vx, vy = body:getLinearVelocity()
          if vx < speed.boostMaksSlide then
            if vx < 0 then
              vx = vx * 0.7
            else
              vx = vx * 1.5
            end
            if vx > speed.boostMaksSlide then
              vx = speed.boostMaksSlide
            end
            setVelocity(vx, vy)
          end
          surface = SURFACE_BOOST
          impulseState = 2
        elseif other.slow then
          impulseState = 1
          local vx, vy = body:getLinearVelocity()
          if vx > speed.slowMaks then
            vx = vx * 0.8
            if vx < speed.slowMaks then
              vx = speed.slowMaks
            end
            setVelocity(vx, vy)
          end
          surface = SURFACE_SLOW
          impulseState = 2
        else
          surface = SURFACE_NORMAL
        end
      elseif other.powerUp and powerUp == PU_NONE and canPickUp() then
        if isLocal then
          other.blendMode = "add"
          local crates = { other }
          timer.performWithDelay(200, function() return restoreCrateBlend(crates) end, 1)
          playSound("pickup")
          lastPickupTime = system.getTimer()
        end
        choosePowerUp()
        if stats.powerUpAtTimes == 2 and isLocal then
          other:setFillColor(0.5450980392156862, 0.5137254901960784, 0.47058823529411764, 1)
        end
      end
    elseif event.phase == "ended" and other.mapElement then
      timer.performWithDelay(300, checkStillInAir, 1)
    end
  end

  local particleCounter = 1
  local function calculateRotation()
    local vx, vy = body:getLinearVelocity()
    if vy < -400 then
      vy = vy / 2
    end
    if vx > 50 then
      if #velocityHistory > VELOCITY_SAMPLES then
        table.remove(velocityHistory)
        table.remove(velocityHistory)
      end
      table.insert(velocityHistory, 1, vx)
      table.insert(velocityHistory, 2, vy)
      local sumX, sumY = 0, 0
      for i = 1, #velocityHistory, 2 do
        sumX = sumX + velocityHistory[i]
        sumY = sumY + velocityHistory[i + 1]
      end
      local angle = math.deg(math.atan(sumY / VELOCITY_SAMPLES / (sumX / VELOCITY_SAMPLES)))
      if angle > 90 then
        angle = 89
      elseif angle < -90 then
        angle = -89
      end
      avatarGroup.rotation = angle
    end
    if particleCounter > 5 then
      particleCounter = 0
      spawnItemParticle()
    end
    particleCounter = particleCounter + 1
  end

  local lastAccelerateTime = 0
  local firstAccelerate = true

  local function accelerate()
    if state.startedClean or state.disconnected then
      return
    end
    if firstAccelerate then
      firstAccelerate = false
      lastAccelerateTime = system.getTimer()
      body.bodyType = "dynamic"
      if powerUp == PU_NINJA and isLocal then
        cycleNinjaTarget()
      end
    end
    local vx, vy = body:getLinearVelocity()
    if impulseState == 1 then
      lastAccelerateTime = system.getTimer()
    else
      impulseState = 0
      local startVx = vx
      local acceleration = speed.accelerateX
      local now = system.getTimer()
      local elapsed = (now - lastAccelerateTime) * 0.01
      lastAccelerateTime = now
      acceleration = acceleration * elapsed
      if vx < speed.topSpeedX * 0.2 then
        acceleration = acceleration * 4
      elseif vx < speed.topSpeedX * 0.5 then
        acceleration = acceleration * 2
      end
      if body.onGround then
        vx = vx + acceleration
      else
        vx = vx + acceleration * 0.4
      end
      if vx > speed.topSpeedX and vy <= 20 then
        if vx - speed.topSpeedX < acceleration * 1.5 then
          vx = speed.topSpeedX
        else
          vx = vx * 0.9
        end
      elseif vx > speed.topSpeedX * 1.5 and vy > 0 then
        if vx - speed.topSpeedX < acceleration * 1.5 then
          vx = speed.topSpeedX * 1.5
        else
          vx = vx * 0.9
        end
      end
      if state.playerDead then
        vx = 0
        setVelocity(vx, vy)
      elseif surface == SURFACE_NORMAL then
        setVelocity(vx, vy)
      elseif surface == SURFACE_BOOST and vx < speed.topSpeedX then
        setVelocity(vx, vy)
      elseif startVx < speed.topSpeedX * 0.4 then
        setVelocity(vx, vy)
      end
    end
    updateRunAnimation(vx)
  end

  local function canJump()
    return not state.playerDead and body.onGround == true
  end

  local function jump()
    stats.lastJumpTime = system.getTimer()
    impulseState = 1
    local vx = body:getLinearVelocity()
    if vx > speed.topSpeedX * 0.2 then
      if surface == SURFACE_SLOW then
        vx = vx * 0.8
      else
        vx = vx * 0.7
      end
    end
    setVelocity(vx, 0)
    applyForceBoth(0, -200)
    surface = SURFACE_NORMAL
    impulseState = 2
  end

  local function stopPlayer()
    if not state.startedClean then
      local vx, vy = body:getLinearVelocity()
      if body.onGround then
        if vx <= 0.1 then
          pauseSprite()
          setVelocity(0, vy)
        else
          vx = vx * 0.55
          updateRunAnimation(vx)
          setVelocity(vx, vy)
        end
      end
      if bot then
        bot.inGoal()
      end
    end
  end

  local function getPlayerGoalTime()
    return stats.goalTime
  end

  local function setPlayerGoalTime(time)
    stats.goalTime = time
  end

  local function getUsername()
    return username
  end

  local function getPlayerHead()
    return headMarker
  end

  local function getStatus(includeTime)
    local vx, vy = body:getLinearVelocity()
    local status = { x = round2(body.x), y = round2(body.y), vX = round2(vx), vY = round2(vy) }
    if includeTime then
      status.s = stats.currentGameTime
    end
    return status
  end

  local function getPlayerStatus()
    return getStatus(false)
  end

  local function getPlayerFinish()
    return getStatus(true)
  end

  local function getCurrentGameTime()
    return stats.currentGameTime
  end

  local function setCurrentGameTime(time)
    stats.currentGameTime = time
  end

  local function setPlayerHit(fn)
    hitListener = fn
  end

  local function getBodyPartsGroup()
    return effectsGroup
  end

  local function getScreenGroup()
    return screenGroup
  end

  local function getGhostGroup()
    return ghost
  end

  local function shieldPowerUp()
    endProtections()
    state.shieldActive = true
    startShieldEffect()
  end

  local function armorPowerUp()
    endProtections()
    state.armorActive = true
    startArmorEffect()
  end

  local function speedPowerUp()
    endProtections()
    state.speedActive = true
    speed.topSpeedX = speed.topSpeedX * 1.5
    speed.accelerateX = speed.accelerateX * 1.5
    applyForceBoth(300, 0)
    startSpeedEffect()
  end

  local function magnetPull(userId)
    if players[id].x < players[userId].x then
      applyForceBoth(100, 0)
      magnetHit.x = 40
      magnetHit.xScale = -math.abs(magnetHit.xScale)
    else
      setVelocity(0, 0)
      applyForceBoth(-400, 0)
      magnetHit.x = -40
      magnetHit.xScale = math.abs(magnetHit.xScale)
    end
    playMagnetHit()
  end

  local function bounceTrapLaunch()
    setVelocity(0, 0)
    applyForceBoth(-300, -150)
  end

  function endProtections()
    if state.shieldActive then
      endShield()
    end
    if state.armorActive then
      endArmor()
    end
    if state.speedActive then
      endSpeed(true)
    end
  end

  local function drawNinjaSlash()
    local MAX_WIDTH, TAIL, DURATION, LENGTH, HEIGHT = 8, 5, 150, 50, 10
    local points = {}
    for step = 1, LENGTH, 5 do
      table.insert(points, 1, { x = step - 25, y = step / LENGTH * HEIGHT })
      if #points > TAIL then
        table.remove(points)
      end
      for _, point in ipairs(points) do
        local line = display.newLine(point.x, point.y, step - 25, step / LENGTH * HEIGHT)
        body:insert(line)
        line.strokeWidth = MAX_WIDTH * (step / LENGTH)
        transition.to(line, {
          time = DURATION, alpha = 0, strokeWidth = 0, tag = "ninjaTrans",
          onComplete = function() display.remove(line) end,
        })
      end
    end
    while #points > 0 do
      table.remove(points)
    end
  end

  local function removeBladeAnimation()
    icons.bladeImage.alpha = 0
  end

  local function createBladeAnimation()
    icons.bladeImage.alpha = 1
    transition.to(icons.bladeImage, { time = 200, rotation = 355 })
  end

  local function removeTrapAnimation()
    icons.trapImage.alpha = 0
  end

  local function createTrapAnimation()
    icons.trapImage.alpha = 1
  end

  local function removeBounceTrapAnimation()
    icons.bounceTrapImage.alpha = 0
  end

  local function createBounceTrapAnimation()
    icons.bounceTrapImage.alpha = 1
  end

  local function createMagnetAnimation()
    playMagnetUse()
    killMessage(id, PU_MAGNET, id)
  end

  local function showAfterRespawn()
    if not state.playerDead and body then
      speed.topSpeedX = speed.tempSpeedX
      body.alpha = 1
    end
  end

  local function hideBody()
    if body then
      body.alpha = 0
    end
  end

  local function respawn()
    state.playerDead = false
    startRespawnProtection()
    showAfterRespawn()
    if state.speedActive then
      endSpeed(false)
    end
  end

  local function setKillMessageFunction(fn)
    killMessage = fn
  end

  local function leadCategory()
    local smallestLead = 5000
    for i = 1, #players do
      if i ~= id and smallestLead > body.x - players[i].x then
        smallestLead = body.x - players[i].x
      end
      if players[i].x + 2000 > body.x and i ~= id then
        return 0
      end
    end
    if smallestLead < 2500 then
      return 1
    end
    return 2
  end

  local function makeStatic()
    if body then
      body.bodyType = "static"
    end
  end

  local function stopMoving()
    if body then
      setVelocity(0, 0)
    end
  end

  local function setDisconnected()
    if body and not state.startedClean then
      pcall(stopMoving)
      state.disconnected = true
      state.playerInvulnerable = true
      body.alpha = 0.5
      disconnectedIcon.alpha = 1
      timer.performWithDelay(10, makeStatic, 1)
    end
  end

  local function isDisconnected()
    return state.disconnected
  end

  local function playHitAnimation(powerUpId, result, attackerId)
    if powerUpId == PU_BLADE then
      playSound("blade_hit")
    elseif powerUpId == PU_TRAP then
      playSound("trap_hit")
    elseif powerUpId == PU_LIGHTNING then
      showLightningBolt()
      playSound("lightning_hit")
    elseif powerUpId == PU_NINJA then
      playSound("trap_hit")
      drawNinjaSlash()
    end

    if result == HIT_KILLED then
      killMessage(attackerId, powerUpId, id)
      local respawnDelay = 1000
      if racePosition == 1 then
        local lead = leadCategory()
        if lead == 1 then
          respawnDelay = 1500
        elseif lead == 2 then
          respawnDelay = 2000
        end
      end
      state.playerDead = true
      state.playerInvulnerable = true
      hideAvatar()
      if bot then
        bot.botDied()
      end
      if powerUpId == PU_BLADE then
        playBladeDeath()
        showBlood()
        timer.performWithDelay(600, corpse.dropBrain, 1)
        timer.performWithDelay(1500, corpse.readyBrain, 1)
        timer.performWithDelay(respawnDelay, respawn, 1)
      elseif powerUpId == PU_TRAP or powerUpId == PU_NINJA then
        playHeadDeath()
        showBlood()
        timer.performWithDelay(10, corpse.dropHead, 1)
        timer.performWithDelay(1500, corpse.readyHead, 1)
        timer.performWithDelay(respawnDelay, respawn, 1)
      elseif powerUpId == PU_LIGHTNING then
        playLightningDeath()
        timer.performWithDelay(600, hideBody, 1)
        timer.performWithDelay(600, corpse.dropSkull, 1)
        timer.performWithDelay(1500, corpse.readySkull, 1)
        timer.performWithDelay(respawnDelay, respawn, 1)
      end
      if state.speedActive then
        speedEffect.alpha = 0
      end
      setVelocity(0, 0)
      if speed.topSpeedX > 0 then
        speed.tempSpeedX = speed.topSpeedX
        speed.topSpeedX = 0
      end
    elseif result == HIT_ARMOR then
      endArmor()
    elseif result == HIT_PUSHED then
      if powerUpId == PU_MAGNET then
        magnetPull(attackerId)
      elseif powerUpId == PU_BOUNCE_TRAP then
        playSound("bounce_hit")
        bounceTrapLaunch(attackerId)
        killMessage(attackerId, powerUpId, id)
      end
    end
  end

  local function onCollisionPowerUp(attackerId, powerUpId)
    if stats.goalTime == -1 and not state.playerInvulnerable then
      local result
      if state.shieldActive then
        result = HIT_SHIELD
      elseif state.armorActive then
        result = HIT_ARMOR
      elseif powerUpId == PU_MAGNET or powerUpId == PU_BOUNCE_TRAP then
        result = HIT_PUSHED
      else
        result = HIT_KILLED
      end
      playHitAnimation(powerUpId, result, attackerId)
      if hitListener then
        hitListener(getPlayerStatus(), { k = attackerId, p = powerUpId, h = result })
      end
      return result
    end
  end

  local function forcePlayer()
    if isLocal or state.startedClean then
      return
    end
    local vx, vy = ghost:getLinearVelocity()
    body:setLinearVelocity(vx, vy)
    body.x = ghost.x
    body.y = ghost.y
  end

  local function interpolation()
  end

  local function setRemoteState(x, y, vx, vy)
    if state.startedClean or state.disconnected or not body then
      return
    end
    local dx, dy = x - body.x, y - body.y
    if math.abs(dx) > 120 or math.abs(dy) > 120 then
      body.x, body.y = x, y
    else
      body.x, body.y = body.x + dx * 0.5, body.y + dy * 0.5
    end
    body:setLinearVelocity(vx, vy)
    ghost.x, ghost.y = body.x, body.y
    ghost:setLinearVelocity(vx, vy)
  end

  local function corrigateOtherPlayers(x, y, vx, vy, messageType, updateId)
    if state.startedClean then
      return
    end
    if updateId then
      if updateId > stats.currentUDID then
        stats.currentUDID = updateId
      else
        return
      end
    end
    ghost:setLinearVelocity(vx, vy)
    ghost.x = x
    ghost.y = y
    if messageType and messageType == "i" then
      forcePlayer()
    else
      body:setLinearVelocity(vx, vy)
    end
  end

  local function addPlaySoundFunction(fn)
    soundPlayer = fn
  end

  function playSound(soundName)
    soundPlayer(soundName, channels[nextChannel])
    nextChannel = nextChannel + 1
    if nextChannel > CHANNELS_PER_PLAYER then
      nextChannel = 1
    end
  end

  local function setSoundVolume(volume)
    if volume == currentVolume then
      return 1
    end
    currentVolume = volume
    for i = 1, CHANNELS_PER_PLAYER do
      audio.setVolume(volume, { channel = channels[i] })
    end
  end

  local function clean()
    state.startedClean = true
    corpse.startedCleanNow()
    body:removeEventListener("collision", body)
    shieldEffect:removeEventListener("sprite", onShieldSprite)
    lightningDeath:removeEventListener("sprite", onLightningDeathSprite)
    lightningBolt:removeEventListener("sprite", onLightningBoltSprite)
    bladeDeath:removeEventListener("sprite", onBladeDeathSprite)
    headDeath:removeEventListener("sprite", onHeadDeathSprite)
    speedEffect:removeEventListener("sprite", onSpeedSprite)
    magnetHit:removeEventListener("sprite", onMagnetHitSprite)
    magnetUse:removeEventListener("sprite", onMagnetUseSprite)
    transition.cancel("ninjaTrans")
    if bot then
      bot.cleanBot()
    end
    if effectSheet then
      effectSheet:dispose()
    end
    display.remove(ghost)
    ghost = nil
    display.remove(body)
    body = nil
  end

  if sprites.spriteItem then
    avatarGroup:insert(sprites.spriteItem)
  end
  avatarGroup:insert(speedEffect)
  avatarGroup:insert(sprites.spriteBody)
  avatarGroup:insert(sprites.spriteBoots)
  if sprites.spriteHat then
    avatarGroup:insert(sprites.spriteHat)
  end
  body:insert(avatarGroup)
  body:insert(icons.bladeImage)
  body:insert(icons.trapImage)
  body:insert(icons.bounceTrapImage)
  body:insert(icons.ninjaPlayerImage)
  body:insert(lightningDeath)
  body:insert(bladeDeath)
  body:insert(headDeath)
  body:insert(shieldEffect)
  body:insert(armorEffect)
  body:insert(magnetHit)
  body:insert(magnetUse)

  local headOffset = HEAD_BAR_OFFSETS[accessories.getAvatarName(avatarIndex)] or {}
  headMarker:insert(headMarkerImage)
  headMarker:insert(sprites.spriteHeadBar)
  headMarker:insert(icons.ninjaBarImage)
  headMarker.anchorChildren = true
  headMarker.anchorX = 0.5
  headMarker.anchorY = 1
  sprites.spriteHeadBar.y = headOffset[1] or 0
  sprites.spriteHeadBar.x = headOffset[2] or -3
  headMarker:insert(disconnectedIcon)
  disconnectedIcon.alpha = 0
  disconnectedIcon.y = 5
  disconnectedIcon.x = 1
  icons.ninjaBarImage.alpha = 0
  icons.ninjaBarImage.y = -20

  physics.addBody(body,
    { density = 1.27, friction = 0, shape = LEGS_SHAPE, bounce = 0.1, filter = remotePlayerCollisionFilter },
    { density = 0, friction = 0, shape = MIDDLE_SHAPE, bounce = 0.1, filter = localPlayerCollisionFilter },
    { density = 0, friction = 0, shape = HEAD_SHAPE, bounce = 0.1, filter = remotePlayerCollisionFilter })
  physics.addBody(ghost,
    { density = 1.27, friction = 0, shape = LEGS_SHAPE, bounce = 0.1, filter = remotePlayerCollisionFilter },
    { density = 0, friction = 0, shape = MIDDLE_SHAPE, bounce = 0.1, filter = remotePlayerCollisionFilter },
    { density = 0, friction = 0, shape = HEAD_SHAPE, bounce = 0.1, filter = remotePlayerCollisionFilter })
  timer.performWithDelay(10, makeStatic, 1)

  body.isSleepingAllowed = false
  body.x = 296 + id * 40
  body.y = startY
  body.id = id
  body.player = true
  body.onGround = true
  body.isFixedRotation = true
  body.mobileUser = false
  body.ninjaMark = false
  ghost.x = body.x
  ghost.y = body.y
  ghost.isFixedRotation = true
  ghost.isSleepingAllowed = false
  icons.bladeImage.alpha = 0
  icons.trapImage.alpha = 0
  icons.bounceTrapImage.alpha = 0
  icons.ninjaPlayerImage.alpha = 0
  icons.ninjaPlayerImage.y = -43
  magnetHit.alpha = 0

  local function attachBot()
    bot = botModule.new(body)
    local topSpeed = math.random(335, 345)
    speed.defaultTopSpeed = topSpeed
    speed.topSpeedX = topSpeed
    speed.tempSpeedX = topSpeed
  end

  if not isLocal and not remoteHuman then
    attachBot()
  end

  body.collision = onCollision
  body.onCollisionPowerUp = onCollisionPowerUp
  body.stopPlayer = stopPlayer
  body.accelerate = accelerate
  body.getPowerUp = getPowerUp
  body.usedPowerUp = usedPowerUp
  body.setPlayerPosition = setPlayerPosition
  body.getUsername = getUsername
  body.jump = jump
  body.canJump = canJump
  body.speedPowerUp = speedPowerUp
  body.shieldPowerUp = shieldPowerUp
  body.armorPowerUp = armorPowerUp
  body.calculateRotation = calculateRotation
  body.getPlayerGoalTime = getPlayerGoalTime
  body.setPlayerGoalTime = setPlayerGoalTime
  body.getCurrentGameTime = getCurrentGameTime
  body.setCurrentGameTime = setCurrentGameTime
  body.getPlayerHead = getPlayerHead
  body.setPlayerHit = setPlayerHit
  body.playHitAnimation = playHitAnimation
  body.getPlayerStatus = getPlayerStatus
  body.getPlayerFinish = getPlayerFinish
  body.getBodyPartsGroup = getBodyPartsGroup
  body.pauseSprite = pauseSprite
  body.createBladeAnimation = createBladeAnimation
  body.removeBladeAnimation = removeBladeAnimation
  body.createTrapAnimation = createTrapAnimation
  body.removeTrapAnimation = removeTrapAnimation
  body.createBounceTrapAnimation = createBounceTrapAnimation
  body.removeBounceTrapAnimation = removeBounceTrapAnimation
  body.createMagnetAnimation = createMagnetAnimation
  body.corrigateOtherPlayers = corrigateOtherPlayers
  body.setRemoteState = setRemoteState
  body.addPlaySoundFunction = addPlaySoundFunction
  body.playSound = playSound
  body.setSoundVolume = setSoundVolume
  body.setUpdatePowerUpImageFunction = setUpdatePowerUpImageFunction
  body.getScreenGroup = getScreenGroup
  body.showCloud = showCloud
  body.setKillMessageFunction = setKillMessageFunction
  body.clean = clean
  body.setDisconnected = setDisconnected
  body.isDisconnected = isDisconnected
  body.addNinjaMark = addNinjaMark
  body.playPowerUpJumpEffect = playJumpEffect
  body.interpolation = interpolation
  body.getGhostGroup = getGhostGroup
  body.forcePlayer = forcePlayer
  body.tutorialPause = tutorialPause
  body.setPowerUp = setPowerUp
  body.canOtherPlayerUsePU = canOtherPlayerUsePU

  function body.setBotModuleFunction(sendMessage, startTime, powerUpButtonHandler)
    if bot then
      bot.setGameFunction(sendMessage, startTime, powerUpButtonHandler)
    end
  end

  body:addEventListener("collision", body)
  shieldEffect:addEventListener("sprite", onShieldSprite)
  lightningDeath:addEventListener("sprite", onLightningDeathSprite)
  bladeDeath:addEventListener("sprite", onBladeDeathSprite)
  headDeath:addEventListener("sprite", onHeadDeathSprite)
  lightningBolt:addEventListener("sprite", onLightningBoltSprite)
  magnetHit:addEventListener("sprite", onMagnetHitSprite)
  speedEffect:addEventListener("sprite", onSpeedSprite)
  magnetUse:addEventListener("sprite", onMagnetUseSprite)
  corpse.readySkull()
  corpse.readyHead()
  corpse.readyBrain()
  return body
end

return player
