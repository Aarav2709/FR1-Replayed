-- loadingScene.lua — Loading screen / asset preloader scene
-- Reconstructed from decompiled loadingScene.lu.lua
-- Loads sounds, sprite sheets, and networking modules with a progress bar

local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()
local sprite = require("modules.sprite")

local localization = storyboard.localized
local database = storyboard.database

-- Scene-level references
local background
local progressBarOutline
local progressBarFill
local loadingText
local progressWidth = 0

--------------------------------------------------------------------------------
-- createScene
--------------------------------------------------------------------------------

function scene:createScene(event)
    local group = self.view

    -- Background (480x320)
    background = display.newImageRect("images/gui/background/startScreen.png", 480, 320)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    group:insert(background)

    -- "A Dirtybit Game" text
    loadingText = display.newText(
        localization.get("DirtybitGame"),
        display.contentCenterX,
        display.contentHeight * 0.7,
        storyboard.gameDataTable and storyboard.gameDataTable.font or native.systemFont,
        44
    )
    loadingText:scale(0.5, 0.5)
    loadingText:setFillColor(1, 1, 1)
    group:insert(loadingText)

    -- Progress bar outline (white border, 200x20)
    progressBarOutline = display.newRect(display.contentCenterX, display.contentCenterY, 200, 20)
    progressBarOutline:setFillColor(0, 0, 0, 0)
    progressBarOutline:setStrokeColor(1, 1, 1)
    progressBarOutline.strokeWidth = 2
    group:insert(progressBarOutline)

    -- Progress bar fill (starts at width 0)
    progressBarFill = display.newRect(
        progressBarOutline.x - 100,
        progressBarOutline.y,
        0,
        16
    )
    progressBarFill.anchorX = 0
    progressBarFill:setFillColor(1, 1, 1)
    group:insert(progressBarFill)
end

--------------------------------------------------------------------------------
-- Progress bar advancement
--------------------------------------------------------------------------------

local function advanceProgressBar(callback)
    progressWidth = progressWidth + 40
    transition.to(progressBarFill, {
        width = progressWidth,
        time = 200,
        onComplete = callback,
    })
end

--------------------------------------------------------------------------------
-- enterScene — Staged asset loading
--------------------------------------------------------------------------------

function scene:enterScene(event)
    local group = self.view
    local delay = 240

    -- Initialize game data table if needed
    if not storyboard.gameDataTable then
        storyboard.gameDataTable = {}
    end

    if not storyboard.gameDataTable.sounds then
        storyboard.gameDataTable.sounds = {}
    end

    if not storyboard.gameDataTable.sprites then
        storyboard.gameDataTable.sprites = {}
    end

    ---------------------------------------------------------------------------
    -- Stage 1: Load sound effects
    ---------------------------------------------------------------------------
    timer.performWithDelay(delay, function()
        local sounds = storyboard.gameDataTable.sounds

        sounds.pickupSound           = audio.loadSound("sound/sfx_pickup.wav")
        sounds.jumpSound             = audio.loadSound("sound/sfx_jump.wav")
        sounds.bladeActivateSound    = audio.loadSound("sound/sfx_blade_activate.wav")
        sounds.bladeHitSound         = audio.loadSound("sound/sfx_blade_hit.wav")
        sounds.trapActivateSound     = audio.loadSound("sound/sfx_trap_activate.wav")
        sounds.trapHitSound          = audio.loadSound("sound/sfx_trap_hit.wav")
        sounds.lightningActivateSound = audio.loadSound("sound/sfx_lightning_activate.wav")
        sounds.lightningHitSound     = audio.loadSound("sound/sfx_lightning_hit.wav")
        sounds.speedActivateSound    = audio.loadSound("sound/sfx_speed_activate.wav")
        sounds.invulActivateSound    = audio.loadSound("sound/sfx_invul_activate.wav")
        sounds.armorActivateSound    = audio.loadSound("sound/sfx_armor_activate.wav")
        sounds.countdownSound        = audio.loadSound("sound/sfx_countdown.wav")
        sounds.startSound            = audio.loadSound("sound/sfx_start.wav")
        sounds.bloodSound            = audio.loadSound("sound/sfx_blood.wav")
        sounds.magnetActivateSound   = audio.loadSound("sound/sfx_magnet_activate.wav")
        sounds.bounceActivateSound   = audio.loadSound("sound/sfx_bounce_activate.wav")
        sounds.bounceHitSound        = audio.loadSound("sound/sfx_bounce_hit.wav")
        sounds.messageReceivedSound  = audio.loadSound("sound/sfx_message_received.wav")
        sounds.challangeCompleted    = audio.loadSound("sound/sfx_coins.wav")
        sounds.buttonSound           = audio.loadSound("sound/sfx_pickup.wav")

        advanceProgressBar()
    end)
    delay = delay + 240

    ---------------------------------------------------------------------------
    -- Stage 2: Load sprite sheets — magnetUse + lightningBolt
    ---------------------------------------------------------------------------
    timer.performWithDelay(delay, function()
        local sprites = storyboard.gameDataTable.sprites

        -- Magnet use sprite (6 frames)
        local magnetUseSheet = sprite.newSpriteSheet("images/game/powerup/magnet/useSprite.png", 64, 64)
        local magnetUseSet = sprite.newSpriteSet(magnetUseSheet, 1, 6)
        sprites.magnetUseFactory = sprite.newSpriteMulti(magnetUseSet)

        -- Lightning bolt sprite (2 frames, looping)
        local lightningBoltSheet = sprite.newSpriteSheet("images/game/powerup/lightning/lightningBoltSprite.png", 64, 64)
        local lightningBoltSet = sprite.newSpriteSet(lightningBoltSheet, 1, 2)
        sprite.add(lightningBoltSet, "loop", 1, 2, 200, 0)
        sprites.lightningBoltFactory = sprite.newSpriteMulti(lightningBoltSet)

        advanceProgressBar()
    end)
    delay = delay + 240

    ---------------------------------------------------------------------------
    -- Stage 3: Load sprite sheets — shield + trap
    ---------------------------------------------------------------------------
    timer.performWithDelay(delay, function()
        local sprites = storyboard.gameDataTable.sprites

        -- Shield sprite (28 frames: start=1-12, active=13-16, end=17-28)
        local shieldSheet = sprite.newSpriteSheet("images/game/powerup/shield/sprite.png", 64, 64)
        local shieldSet = sprite.newSpriteSet(shieldSheet, 1, 28)
        sprite.add(shieldSet, "start", 1, 12, 800, 1)
        sprite.add(shieldSet, "active", 13, 4, 600, 0)
        sprite.add(shieldSet, "end", 17, 12, 800, 1)
        sprites.shieldFactory = sprite.newSpriteMulti(shieldSet)

        -- Trap sprite (8 frames: close=1-3, open=4-8)
        local trapSheet = sprite.newSpriteSheet("images/game/powerup/trap/sprite.png", 64, 64)
        local trapSet = sprite.newSpriteSet(trapSheet, 1, 8)
        sprite.add(trapSet, "open", 4, 5, 500, 1)
        sprite.add(trapSet, "close", 1, 3, 300, 1)
        sprites.trapFactory = sprite.newSpriteMulti(trapSet)

        advanceProgressBar()
    end)
    delay = delay + 240

    ---------------------------------------------------------------------------
    -- Stage 4: Load sprite sheets — bounceTrap + armor + magnetHit
    ---------------------------------------------------------------------------
    timer.performWithDelay(delay, function()
        local sprites = storyboard.gameDataTable.sprites

        -- Bounce trap sprite (12 frames: play=1-5, reset=5-12)
        local bounceTrapSheet = sprite.newSpriteSheet("images/game/powerup/bounceTrap/sprite.png", 64, 64)
        local bounceTrapSet = sprite.newSpriteSet(bounceTrapSheet, 1, 12)
        sprite.add(bounceTrapSet, "play", 1, 5, 300, 1)
        sprite.add(bounceTrapSet, "reset", 5, 8, 500, 1)
        sprites.bounceTrapFactory = sprite.newSpriteMulti(bounceTrapSet)

        -- Armor sprite (12 frames)
        local armorSheet = sprite.newSpriteSheet("images/game/powerup/armor/sprite.png", 64, 64)
        local armorSet = sprite.newSpriteSet(armorSheet, 1, 12)
        sprites.armorFactory = sprite.newSpriteMulti(armorSet)

        -- Magnet hit sprite (4 frames)
        local magnetHitSheet = sprite.newSpriteSheet("images/game/powerup/magnet/hitSprite.png", 64, 64)
        local magnetHitSet = sprite.newSpriteSet(magnetHitSheet, 1, 4)
        sprites.magnetHitFactory = sprite.newSpriteMulti(magnetHitSet)

        advanceProgressBar()
    end)
    delay = delay + 240

    ---------------------------------------------------------------------------
    -- Stage 5: Load networking modules + Facebook auto-login + scene transition
    ---------------------------------------------------------------------------
    timer.performWithDelay(delay, function()
        -- Load networking modules
        storyboard.httpClient = require("modules.httpClient")
        storyboard.tcpClient = require("modules.tcpClient")
        storyboard.tcpSocial = require("modules.tcpSocial")
        storyboard.communicationModule = require("modules.communicationModule")

        advanceProgressBar(function()
            -- Check for Facebook auto-login
            local facebookId = nil
            if database then
                facebookId = database.getFacebookId()
            end

            if facebookId and facebookId ~= "" then
                -- Auto-login with Facebook — go directly to play menu
                storyboard.loadScene("scenes.playMenu")
                storyboard.gotoScene("scenes.mainMenu", "slideLeft", 200)
            else
                -- No Facebook login — go to start screen
                storyboard.loadScene("scenes.playMenu")
                storyboard.gotoScene("scenes.mainMenu", "slideLeft", 200)
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- exitScene
--------------------------------------------------------------------------------

function scene:exitScene(event)
    -- Clean up timers if needed
end

--------------------------------------------------------------------------------
-- destroyScene
--------------------------------------------------------------------------------

function scene:destroyScene(event)
    background = nil
    progressBarOutline = nil
    progressBarFill = nil
    loadingText = nil
end

--------------------------------------------------------------------------------
-- Scene event listeners
--------------------------------------------------------------------------------

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
