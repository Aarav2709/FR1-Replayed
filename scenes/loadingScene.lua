-- loads sounds and the player data.

local storyboard = require("modules.storyboard")
local sprite = require("modules.sprite")
local spriteSheets = require("modules.spriteSheets")

local scene = storyboard.newScene()

local STEP_TIME = 240

function scene:createScene()
  local group = self.view
  local font = storyboard.gameDataTable.font

  local background = display.newImageRect("images/gui/background/startScreen.png", 480, 320)
  background.x = display.contentWidth * 0.5
  background.y = display.contentHeight * 0.5
  group:insert(background)

  local frame = display.newRect(0, 0, 200, 20)
  frame.strokeWidth = 1
  frame:setStrokeColor(1, 1, 1)
  frame:setFillColor(1, 1, 1, 0)
  frame.x = display.contentWidth * 0.5
  frame.y = display.contentHeight * 0.5
  group:insert(frame)

  local credit = display.newText("Welcome back to FR1!", 0, 0, font, 44)
  credit:setFillColor(1, 1, 1, 1)
  credit.xScale, credit.yScale = 0.5, 0.5
  credit.x = display.contentWidth * 0.5
  credit.y = display.contentHeight * 0.8
  group:insert(credit)
end

local function newSheet(imagePath, sheetName)
  return sprite.newSpriteSheetFromData(imagePath, spriteSheets.get(sheetName))
end

function scene:enterScene()
  local group = self.view
  local animations = storyboard.gameDataTable.animations

  local bar = display.newRect(0, 0, 0, 20)
  bar:setFillColor(1, 1, 1, 1)
  bar.anchorX = 0
  bar.anchorY = 0.5
  bar.x = display.contentWidth * 0.5 - 100
  bar.y = display.contentHeight * 0.5
  group:insert(bar)

  local function advance()
    transition.to(bar, { time = 200, width = bar.width + 40, x = bar.x })
  end

  local function openMainMenu()
    storyboard.loadScene("scenes.playMenu")
    storyboard.gotoScene("scenes.mainMenu")
  end

  local function loadSounds()
    local sounds = storyboard.gameDataTable.sounds
    local names = {
      "pickup", "jump", "blade_activate", "blade_hit", "trap_activate", "trap_hit",
      "lightning_activate", "lightning_hit", "speed_activate", "invul_activate", "armor_activate",
      "countdown", "start", "blood", "magnet_activate", "bounce_activate", "bounce_hit", "message_received",
    }
    for _, name in ipairs(names) do
      sounds[name] = audio.loadSound("sound/sfx_" .. name .. ".wav")
    end
    sounds.challangeCompleted = audio.loadSound("sound/sfx_coins.wav")
    advance()
    timer.performWithDelay(STEP_TIME, openMainMenu, 1)
  end

  local function loadTrapArmorMagnet()
    local bounceTrapSet = sprite.newSpriteSet(newSheet("images/game/powerup/bounceTrap/sprite.png", "bounceTrapSprite"), 1, 12)
    sprite.add(bounceTrapSet, "play", 1, 5, 70, 1)
    sprite.add(bounceTrapSet, "reset", 5, 8, 800, 1)
    animations.bounceTrapSet = bounceTrapSet

    local armorSet = sprite.newSpriteSet(newSheet("images/game/powerup/armor/sprite.png", "armorSprite"), 1, 12)
    sprite.add(armorSet, "normal", 1, 12, 300, 0)
    animations.armorSpriteSet = armorSet

    local magnetHitSet = sprite.newSpriteSet(newSheet("images/game/powerup/magnet/hitSprite.png", "magnetHitSprite"), 1, 4)
    sprite.add(magnetHitSet, "normal", 1, 4, 400, 1)
    animations.magnetEffect = magnetHitSet
    advance()
    timer.performWithDelay(STEP_TIME, loadSounds, 1)
  end

  local function loadShieldTrap()
    local shieldSet = sprite.newSpriteSet(newSheet("images/game/powerup/shield/sprite.png", "shieldSprite"), 1, 28)
    sprite.add(shieldSet, "shieldStart", 1, 12, 300, 1)
    sprite.add(shieldSet, "shieldActive", 13, 4, 300, 18)
    sprite.add(shieldSet, "shieldEnd", 17, 12, 300, 1)
    animations.shieldSpriteSet = shieldSet

    local trapSet = sprite.newSpriteSet(newSheet("images/game/powerup/trap/sprite.png", "trapSprite"), 1, 10)
    sprite.add(trapSet, "open", 4, 7, 1000, 1)
    sprite.add(trapSet, "close", 1, 4, 70, 1)
    animations.trapSet = trapSet
    advance()
    timer.performWithDelay(STEP_TIME, loadTrapArmorMagnet, 1)
  end

  local function loadMagnetLightning()
    storyboard.loadScene("scenes.mainMenu")
    local magnetUseSet = sprite.newSpriteSet(newSheet("images/game/powerup/magnet/useSprite.png", "magnetUseSprite"), 1, 6)
    sprite.add(magnetUseSet, "normal", 1, 6, 300, 1)
    animations.magnetUse = magnetUseSet

    local boltSet = sprite.newSpriteSet(
      newSheet("images/game/powerup/lightning/lightningBoltSprite.png", "lightningBoltSprite"), 1, 2)
    sprite.add(boltSet, "normal", 1, 2, 400, 2)
    animations.lightningBoltSet = boltSet
    advance()
    timer.performWithDelay(STEP_TIME, loadShieldTrap, 1)
  end

  advance()
  timer.performWithDelay(STEP_TIME, loadMagnetLightning, 1)
end

function scene:exitScene() end

function scene:destroyScene() end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
