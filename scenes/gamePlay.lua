---------------------------------------------------------------------------------
-- gamePlay.lua — Singleplayer practice race (playable)
-- Forest theme, procedurally generated flat course with obstacles
-- Physics-based player with jump controls + 3 AI bots
---------------------------------------------------------------------------------
local storyboard = require("modules.storyboard")
local scene = storyboard.newScene()
local physics = require("physics")
local rewardedVideoModule = require("modules.rewardedVideoModule")
local accessories = require("modules.accessories")

-- Constants
local CELL_W = 80
local CELL_H = 50
local GRAVITY = 20
local TOP_SPEED = 350
local ACCELERATION = 30
local JUMP_FORCE = -200
local PLAYER_DENSITY = 1.27
local PLAYER_FRICTION = 0
local PLAYER_BOUNCE = 0.1

-- Camera offset (player kept at ~1/3 from left, ~2/3 from top)
local CAM_OFFSET_X = 150
local CAM_OFFSET_Y = 204

-- Course parameters
local MAP_COLS = 120 -- 120 cells wide = 9600px
local MAP_ROWS = 7   -- 7 cells tall = 350px
local GROUND_ROW = 5 -- ground level row (0-indexed from top)
local MAP_LENGTH = MAP_COLS * CELL_W
local GOAL_X = MAP_LENGTH - CELL_W * 3

-- Module-level variables
local backgroundGroup, gameGroup, foregroundGroup, playerGroup, effectGroup, uiGroup
local skyImage, mountainImages, cloudImages
local groundTiles = {}
local player, playerBody, playerSprite
local bots = {}
local selfArrow, ninjaArrow, homeButton, timerText, statusText
local countdownTimer, gameTimer, enterFrameListener, keyListener
local isGameActive = false
local isGameRunning = false
local gameStartTime = 0
local jumpButton, powerupButton
local touchingJump = false
local playerFinished = false
local finishOrder = {}
local positionLabels = { "1st", "2nd", "3rd", "4th" }

-- Theme images
local THEME_DIR = "images/map/element/forest/"
local BG_DIR = "images/map/background/forest/"
local GROUND_TILES = { "1Av1.png", "1Av2.png", "1Av3.png", "1Av4.png" }

local avatarNames = {}
for _, item in ipairs(accessories.getAvatarList()) do
  avatarNames[item.id] = item.image
end

---------------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------------
local function getAvatarName(avatarId)
  return avatarNames[avatarId] or "fox"
end

local function createPlayerBody(name, startX, startY, group)
  local bodyPath = "images/game/avatar/" .. name .. "BodySprite.png"
  local sprite = display.newImageRect(bodyPath, 64, 64)
  if not sprite then
    local thumbPath = "images/gui/market/accessories/" .. name .. ".png"
    sprite = display.newImageRect(thumbPath, 64, 64)
    if not sprite then
      sprite = display.newRect(0, 0, 30, 30)
      sprite:setFillColor(1, 0.5, 0)
    end
  end
  sprite.xScale = 0.45
  sprite.yScale = 0.45

  -- Physics body: simplified box
  local bodyGroup = display.newGroup()
  bodyGroup:insert(sprite)
  bodyGroup.x = startX
  bodyGroup.y = startY
  group:insert(bodyGroup)

  physics.addBody(bodyGroup, "static", {
    density = PLAYER_DENSITY,
    friction = PLAYER_FRICTION,
    bounce = PLAYER_BOUNCE,
    box = { halfWidth = 12, halfHeight = 15 },
  })

  bodyGroup.isSleepingAllowed = false
  bodyGroup.isFixedRotation = true
  bodyGroup.onGround = false
  bodyGroup.topSpeedX = TOP_SPEED
  bodyGroup.accelerateX = ACCELERATION
  bodyGroup.sprite = sprite
  bodyGroup.username = ""
  bodyGroup.goalTime = -1
  bodyGroup.isBot = false
  bodyGroup.lastJumpTime = 0

  -- Ground detection collision
  bodyGroup.collision = function(self, event)
    if event.phase == "began" then
      if event.other and event.other.mapElement then
        self.onGround = true
        self.groundTime = system.getTimer()
      end
    elseif event.phase == "ended" then
      if event.other and event.other.mapElement then
        -- Check if still on something
        timer.performWithDelay(50, function()
          if self and self.removeSelf then
            local vx, vy = self:getLinearVelocity()
            if vy > 2 then
              self.onGround = false
            end
          end
        end)
      end
    end
  end
  bodyGroup:addEventListener("collision", bodyGroup)

  return bodyGroup
end

local function jumpPlayer(body)
  if not body or not body.removeSelf then return end
  if not body.getLinearVelocity then return end
  if not body.onGround then return end

  local now = system.getTimer()
  if now - (body.lastJumpTime or 0) < 200 then return end
  body.lastJumpTime = now

  local vx, vy = body:getLinearVelocity()
  body:setLinearVelocity(vx, 0)
  body:applyForce(0, JUMP_FORCE, body.x, body.y)
  body.onGround = false
end

local function acceleratePlayer(body, dt)
  if not body or not body.removeSelf then return end
  if not body.getLinearVelocity then return end
  if body.goalTime > 0 then return end   -- finished

  local vx, vy = body:getLinearVelocity()
  local acc = body.accelerateX or ACCELERATION

  -- Speed boost zones
  if not body.onGround then
    acc = acc * 0.4     -- less control in air
  end

  -- Below 20% speed: 4x boost
  if math.abs(vx) < body.topSpeedX * 0.2 then
    acc = acc * 4
  elseif math.abs(vx) < body.topSpeedX * 0.5 then
    acc = acc * 2
  end

  vx = vx + acc * (dt / 16.67)

  -- Cap speed
  if vx > body.topSpeedX then
    vx = vx - 5
  end

  body:setLinearVelocity(vx, vy)
end

---------------------------------------------------------------------------------
-- CREATE SCENE
---------------------------------------------------------------------------------
function scene:createScene(event)
  local view = self.view
  local font = storyboard.gameDataTable.font
  local fontSize = 40

  rewardedVideoModule.clearActiveVideoData()
  storyboard.gameDataTable.gameStats = nil

  -- Start physics early so addBody works in createScene
  physics.start()
  physics.pause()   -- pause until countdown finishes
  physics.setGravity(0, GRAVITY)

  ---------------------------------------------------------------------------
  -- Display groups (layered)
  ---------------------------------------------------------------------------
  backgroundGroup = display.newGroup()
  view:insert(backgroundGroup)

  gameGroup = display.newGroup()
  view:insert(gameGroup)

  foregroundGroup = display.newGroup()
  view:insert(foregroundGroup)

  playerGroup = display.newGroup()
  view:insert(playerGroup)

  effectGroup = display.newGroup()
  view:insert(effectGroup)

  uiGroup = display.newGroup()
  view:insert(uiGroup)

  ---------------------------------------------------------------------------
  -- Sky background (repeating)
  ---------------------------------------------------------------------------
  for i = 0, math.ceil(MAP_LENGTH / 480) + 1 do
    local sky = display.newImageRect(BG_DIR .. "bkg_sundown.png", 480, 360)
    sky.anchorX = 0
    sky.anchorY = 1
    sky.x = i * 480
    sky.y = GROUND_ROW * CELL_H + CELL_H + 60
    backgroundGroup:insert(sky)
  end

  ---------------------------------------------------------------------------
  -- Mountain parallax layer
  ---------------------------------------------------------------------------
  mountainImages = {}
  for i = 0, 5 do
    local mtn = display.newImageRect(BG_DIR .. "bkg_mountains.png", 1050, 375)
    mtn.anchorX = 0
    mtn.anchorY = 1
    mtn.x = i * 980
    mtn.y = GROUND_ROW * CELL_H + CELL_H + 30
    backgroundGroup:insert(mtn)
    mountainImages[#mountainImages + 1] = mtn
  end

  ---------------------------------------------------------------------------
  -- Clouds
  ---------------------------------------------------------------------------
  cloudImages = {}
  math.randomseed(os.time())
  for i = 1, 15 do
    local ci = math.random(1, 6)
    local cloud = display.newImageRect(BG_DIR .. "cloud" .. ci .. ".png", 200, 100)
    cloud.anchorX = 0
    cloud.x = math.random(0, MAP_LENGTH)
    cloud.y = math.random(20, GROUND_ROW * CELL_H - 80)
    cloud.alpha = 0.8
    backgroundGroup:insert(cloud)
    cloudImages[#cloudImages + 1] = cloud
  end

  ---------------------------------------------------------------------------
  -- Generate ground tiles (simple flat ground with some gaps/platforms)
  ---------------------------------------------------------------------------
  local groundY = GROUND_ROW * CELL_H

  -- Build a simple course pattern:
  -- Flat ground with occasional gaps and raised platforms
  local courseMap = {}
  for col = 1, MAP_COLS do
    courseMap[col] = true     -- ground by default
  end

  -- Create gaps (skip first 8 cols and last 8 cols for safety)
  local gapPositions = { 15, 16, 25, 26, 40, 41, 42, 55, 56, 70, 71, 85, 86, 87, 100, 101 }
  for _, g in ipairs(gapPositions) do
    if g <= MAP_COLS then courseMap[g] = false end
  end

  -- Place ground tiles
  for col = 1, MAP_COLS do
    if courseMap[col] then
      local tileIdx = ((col - 1) % #GROUND_TILES) + 1
      local tile = display.newImageRect(THEME_DIR .. GROUND_TILES[tileIdx], CELL_W, CELL_H)
      tile.anchorX = 0
      tile.anchorY = 0
      tile.x = col * CELL_W
      tile.y = groundY
      gameGroup:insert(tile)

      physics.addBody(tile, "static", {
        friction = 0.3,
        bounce = 0,
      })
      tile.mapElement = true
      groundTiles[#groundTiles + 1] = tile
    end
  end

  -- Add underground fill rows (below ground)
  for col = 1, MAP_COLS do
    if courseMap[col] then
      for row = 1, 3 do
        local tileIdx = ((col + row) % #GROUND_TILES) + 1
        local fill = display.newImageRect(THEME_DIR .. GROUND_TILES[tileIdx], CELL_W, CELL_H)
        fill.anchorX = 0
        fill.anchorY = 0
        fill.x = col * CELL_W
        fill.y = groundY + row * CELL_H
        gameGroup:insert(fill)
      end
    end
  end

  -- Raised platforms before gaps (give something to jump to)
  local platformPositions = {
    { 13, groundY - CELL_H }, { 14, groundY - CELL_H },
    { 23, groundY - CELL_H }, { 24, groundY - CELL_H },
    { 38, groundY - CELL_H }, { 39, groundY - CELL_H },
    { 43, groundY - CELL_H }, { 44, groundY - CELL_H },
    { 53, groundY - CELL_H }, { 54, groundY - CELL_H },
    { 68, groundY - CELL_H }, { 69, groundY - CELL_H },
    { 83, groundY - CELL_H }, { 84, groundY - CELL_H },
    { 88, groundY - CELL_H }, { 89, groundY - CELL_H },
    { 98,  groundY - CELL_H }, { 99, groundY - CELL_H },
    { 102, groundY - CELL_H }, { 103, groundY - CELL_H },
  }
  for _, pp in ipairs(platformPositions) do
    local col, py = pp[1], pp[2]
    if col <= MAP_COLS then
      local tileIdx = (col % #GROUND_TILES) + 1
      local plat = display.newImageRect(THEME_DIR .. GROUND_TILES[tileIdx], CELL_W, CELL_H)
      plat.anchorX = 0
      plat.anchorY = 0
      plat.x = col * CELL_W
      plat.y = py
      gameGroup:insert(plat)

      physics.addBody(plat, "static", { friction = 0.3, bounce = 0 })
      plat.mapElement = true
      groundTiles[#groundTiles + 1] = plat
    end
  end

  -- Add some decorative trees
  local treePositions = { 5, 18, 30, 48, 60, 75, 92, 108 }
  for _, col in ipairs(treePositions) do
    if courseMap[col] then
      local ti = math.random(1, 4)
      local tree = display.newImageRect(THEME_DIR .. "tre" .. ti .. ".png", 160, 100)
      if tree then
        tree.anchorX = 0.5
        tree.anchorY = 1
        tree.x = col * CELL_W + CELL_W * 0.5
        tree.y = groundY
        foregroundGroup:insert(tree)
      end
    end
  end

  ---------------------------------------------------------------------------
  -- Finish line (Goal)
  ---------------------------------------------------------------------------
  local goal = display.newImageRect(THEME_DIR .. "Goal.png", CELL_W, CELL_H * 3)
  if goal then
    goal.anchorX = 0.5
    goal.anchorY = 1
    goal.x = GOAL_X
    goal.y = groundY
    foregroundGroup:insert(goal)
  end

  ---------------------------------------------------------------------------
  -- Create player
  ---------------------------------------------------------------------------
  local avatarData = storyboard.database.getAvatarData() or { 100, 200, 300, 400 }
  local avatarName = getAvatarName(avatarData[1])
  local startX = 296
  local startY = groundY - 20

  player = createPlayerBody(avatarName, startX, startY, playerGroup)
  local playerInfo = storyboard.database.getPlayerInformation()
  player.username = (playerInfo and playerInfo.username) or "Player"
  player.isBot = false

  ---------------------------------------------------------------------------
  -- Create 3 AI bots
  ---------------------------------------------------------------------------
  local botNames = { "panda", "skunk", "bear" }
  local botUsernames = { "Bot 1", "Bot 2", "Bot 3" }
  for i = 1, 3 do
    local botX = 296 + i * 40
    local bot = createPlayerBody(botNames[i], botX, startY, playerGroup)
    bot.username = botUsernames[i]
    bot.isBot = true
    bot.topSpeedX = TOP_SPEED * (0.7 + math.random() * 0.4)     -- vary speed
    bot.accelerateX = ACCELERATION * (0.8 + math.random() * 0.5)
    bot.botJumpChance = 0.02 + math.random() * 0.03
    bot.botJumpAhead = math.random(2, 4) * CELL_W
    bots[i] = bot
  end

  ---------------------------------------------------------------------------
  -- Self-arrow (above player)
  ---------------------------------------------------------------------------
  selfArrow = display.newImageRect("images/game/selfArrow.png", 15, 15)
  selfArrow.x = startX
  selfArrow.y = startY - 25
  uiGroup:insert(selfArrow)

  ---------------------------------------------------------------------------
  -- Home button
  ---------------------------------------------------------------------------
  homeButton = display.newImageRect("images/gui/button/smallHome.png", 35, 35)
  homeButton.x = homeButton.width * 0.5 + 8
  homeButton.y = homeButton.height * 0.5 + 8
  uiGroup:insert(homeButton)

  ---------------------------------------------------------------------------
  -- Timer text
  ---------------------------------------------------------------------------
  timerText = display.newText("0.0", display.contentCenterX, 15, font, fontSize * 2)
  timerText:setFillColor(1, 1, 1)
  timerText.xScale = 0.5
  timerText.yScale = 0.5
  uiGroup:insert(timerText)

  ---------------------------------------------------------------------------
  -- Status text (countdown / finish position)
  ---------------------------------------------------------------------------
  statusText = display.newText("", 0, 0, font, fontSize * 2.5)
  statusText:setFillColor(1, 1, 1)
  statusText.xScale = 0.5
  statusText.yScale = 0.5
  statusText.x = display.contentWidth * 0.5
  statusText.y = display.contentHeight * 0.35
  uiGroup:insert(statusText)

  ---------------------------------------------------------------------------
  -- Jump button (right side of screen — transparent hit area)
  ---------------------------------------------------------------------------
  jumpButton = display.newRect(display.contentWidth - 75, display.contentHeight - 75, 150, 150)
  jumpButton:setFillColor(0, 0, 0, 0)
  uiGroup:insert(jumpButton)

  -- Jump button icon
  local jumpIcon = display.newImageRect("images/gui/button/btnJump.png", 50, 50)
  jumpIcon.x = display.contentWidth - 40
  jumpIcon.y = display.contentHeight - 40
  jumpIcon.alpha = 0.6
  uiGroup:insert(jumpIcon)

  jumpButton:addEventListener("touch", function(event)
    if event.phase == "began" then
      display.getCurrentStage():setFocus(event.target)
      touchingJump = true
      if isGameRunning and player then
        jumpPlayer(player)
      end
    elseif event.phase == "ended" or event.phase == "cancelled" then
      display.getCurrentStage():setFocus(nil)
      touchingJump = false
    end
    return true
  end)

  ---------------------------------------------------------------------------
  -- Home button handler
  ---------------------------------------------------------------------------
  local function onHomeTap(event)
    if isGameActive then
      native.showAlert("Fun Run",
        storyboard.localized.get("QuitGame") or "Quit the race?",
        { storyboard.localized.get("Cancel") or "Cancel",
          storyboard.localized.get("Quit") or "Quit" },
        function(e)
          if e.action == "clicked" and e.index == 2 then
            isGameActive = false
            isGameRunning = false
            physics.stop()
            if storyboard.gameType == 1 then
              storyboard.gotoScene("scenes.postLobbySingle")
            else
              storyboard.gotoScene("scenes.postLobby")
            end
            storyboard.purgeScene("scenes.gamePlay")
          end
        end)
    end
    return true
  end
  homeButton:addEventListener("tap", onHomeTap)

  ---------------------------------------------------------------------------
  -- Key listener (Android back)
  ---------------------------------------------------------------------------
  keyListener = function(event)
    if event.keyName == "back" and event.phase == "up" then
      onHomeTap(event)
      return true
    end
  end
  Runtime:addEventListener("key", keyListener)
end

---------------------------------------------------------------------------------
-- ENTER SCENE
---------------------------------------------------------------------------------
function scene:enterScene(event)
  isGameActive = true
  isGameRunning = false
  playerFinished = false
  finishOrder = {}

  -- Resume physics (was started+paused in createScene)
  physics.setVelocityIterations(2)
  physics.setPositionIterations(4)
  physics.start()   -- unpause
  physics.setGravity(0, GRAVITY)

  -- All players start as static until "Go!"
  if player and player.setLinearVelocity then
    player.bodyType = "static"
  end
  for _, bot in ipairs(bots) do
    if bot and bot.setLinearVelocity then
      bot.bodyType = "static"
    end
  end

  -----------------------------------------------------------------------
  -- Countdown sequence (3, 2, 1, Go!)
  -----------------------------------------------------------------------
  local countdownStep = 3
  statusText.text = ""

  -- Show countdown image
  local countdownImg = nil
  local function showCountdownImage(num)
    if countdownImg then
      countdownImg:removeSelf(); countdownImg = nil
    end
    local path
    if num > 0 then
      path = "images/game/countdown" .. num .. ".png"
    else
      path = "images/game/countdownGo.png"
    end
    countdownImg = display.newImageRect(path, 129, 70)
    if countdownImg then
      countdownImg.x = display.contentWidth * 0.5
      countdownImg.y = display.contentHeight * 0.3
      uiGroup:insert(countdownImg)
    end
  end

  showCountdownImage(3)

  countdownTimer = timer.performWithDelay(1000, function()
    countdownStep = countdownStep - 1
    if countdownStep > 0 then
      showCountdownImage(countdownStep)
    elseif countdownStep == 0 then
      -- "Go!"
      showCountdownImage(0)
      isGameRunning = true
      gameStartTime = system.getTimer()

      -- Make players dynamic
      if player then player.bodyType = "dynamic" end
      for _, bot in ipairs(bots) do
        bot.bodyType = "dynamic"
      end

      -- Fade out "Go!" after 500ms
      timer.performWithDelay(500, function()
        if countdownImg then
          transition.to(countdownImg, {
            alpha = 0,
            time = 300,
            onComplete = function()
              if countdownImg then
                countdownImg:removeSelf(); countdownImg = nil
              end
            end
          })
        end
      end)
    end
  end, 3)

  -----------------------------------------------------------------------
  -- enterFrame listener — camera, acceleration, goal check, bot AI
  -----------------------------------------------------------------------
  enterFrameListener = function()
    if not isGameActive then return end

    local dt = 16.67     -- approximate frame time at 60fps

    -- Update timer
    if isGameRunning and timerText then
      local elapsed = (system.getTimer() - gameStartTime) / 1000
      timerText.text = string.format("%.1f", elapsed)
    end

    -- Accelerate player
    if isGameRunning and player and player.removeSelf and player.goalTime < 0 then
      acceleratePlayer(player, dt)
    end

    -- Bot AI
    if isGameRunning then
      for _, bot in ipairs(bots) do
        if bot and bot.removeSelf and bot.goalTime < 0 then
          acceleratePlayer(bot, dt)

          -- Bots jump at gaps or randomly
          local botAheadX = bot.x + (bot.botJumpAhead or 200)
          local botCol = math.floor(botAheadX / CELL_W)
          -- Simple gap detection: check if ground exists ahead
          local shouldJump = false
          if math.random() < (bot.botJumpChance or 0.03) then
            shouldJump = true
          end

          -- Always jump near gap positions
          local gapCols = { 15, 16, 25, 26, 40, 41, 42, 55, 56, 70, 71, 85, 86, 87, 100, 101 }
          for _, gc in ipairs(gapCols) do
            if botCol >= gc - 3 and botCol <= gc - 1 then
              shouldJump = true
              break
            end
          end

          if shouldJump and bot.onGround then
            jumpPlayer(bot)
          end
        end
      end
    end

    -- Camera follow player
    if player and player.removeSelf then
      local targetX = -player.x + CAM_OFFSET_X
      local targetY = -player.y + CAM_OFFSET_Y

      -- Clamp camera
      targetY = math.min(targetY, 50)
      targetY = math.max(targetY, -(GROUND_ROW * CELL_H) + 100)

      gameGroup.x = targetX
      gameGroup.y = targetY
      foregroundGroup.x = targetX
      foregroundGroup.y = targetY
      playerGroup.x = targetX
      playerGroup.y = targetY
      effectGroup.x = targetX
      effectGroup.y = targetY

      -- Parallax backgrounds
      backgroundGroup.x = -player.x * 0.3
      backgroundGroup.y = targetY * 0.3

      -- Self arrow follows player (in world coords)
      if selfArrow then
        selfArrow.x = display.contentWidth * 0.5 + (player.x + targetX - CAM_OFFSET_X) * 0
        selfArrow.x = CAM_OFFSET_X
        selfArrow.y = player.y + targetY - 25
      end

      -- Respawn if fell off
      if player.y > (GROUND_ROW + 4) * CELL_H then
        player.x = player.x - 200
        player.y = (GROUND_ROW - 1) * CELL_H
        player:setLinearVelocity(0, 0)
        player.onGround = false
      end
    end

    -- Respawn bots if they fall
    for _, bot in ipairs(bots) do
      if bot and bot.removeSelf and bot.y > (GROUND_ROW + 4) * CELL_H then
        bot.x = bot.x - 200
        bot.y = (GROUND_ROW - 1) * CELL_H
        bot:setLinearVelocity(0, 0)
        bot.onGround = false
      end
    end

    -- Goal check
    if isGameRunning then
      -- Check player
      if player and player.removeSelf and player.goalTime < 0 and player.x >= GOAL_X then
        player.goalTime = system.getTimer() - gameStartTime
        player:setLinearVelocity(0, 0)
        player.bodyType = "static"
        finishOrder[#finishOrder + 1] = player
        playerFinished = true

        local pos = #finishOrder
        statusText.text = positionLabels[pos] or tostring(pos)

        -- Go to results after 2 seconds
        timer.performWithDelay(2000, function()
          if isGameActive then
            isGameActive = false
            isGameRunning = false

            local coinsWon = 0
            if pos == 1 then
              coinsWon = 500
            elseif pos == 2 then
              coinsWon = 250
            elseif pos == 3 then
              coinsWon = 100
            else
              coinsWon = 50
            end

            storyboard.gameDataTable.gameStats = {
              position = pos,
              time = player.goalTime / 1000,
              coinsGained = coinsWon,
              xpGained = coinsWon,
            }
            storyboard.database.increaseMoney(coinsWon)

            -- Set player names for result screen
            storyboard.gameDataTable.playerListNames = {
              { username = player.username },
              { username = bots[1] and bots[1].username or "Bot 1" },
              { username = bots[2] and bots[2].username or "Bot 2" },
              { username = bots[3] and bots[3].username or "Bot 3" },
            }

            physics.stop()
            storyboard.gotoScene("scenes.postLobbySingle")
            storyboard.purgeScene("scenes.gamePlay")
          end
        end)
      end

      -- Check bots
      for _, bot in ipairs(bots) do
        if bot and bot.removeSelf and bot.goalTime < 0 and bot.x >= GOAL_X then
          bot.goalTime = system.getTimer() - gameStartTime
          bot:setLinearVelocity(0, 0)
          bot.bodyType = "static"
          finishOrder[#finishOrder + 1] = bot
        end
      end
    end
  end

  Runtime:addEventListener("enterFrame", enterFrameListener)
end

---------------------------------------------------------------------------------
-- EXIT SCENE
---------------------------------------------------------------------------------
function scene:exitScene(event)
  isGameActive = false
  isGameRunning = false

  if countdownTimer then
    timer.cancel(countdownTimer); countdownTimer = nil
  end
  if gameTimer then
    timer.cancel(gameTimer); gameTimer = nil
  end

  if enterFrameListener then
    Runtime:removeEventListener("enterFrame", enterFrameListener)
    enterFrameListener = nil
  end

  Runtime:removeEventListener("key", keyListener)

  pcall(function() physics.stop() end)
end

---------------------------------------------------------------------------------
-- DESTROY SCENE
---------------------------------------------------------------------------------
function scene:destroyScene(event)
  backgroundGroup = nil
  gameGroup = nil
  foregroundGroup = nil
  playerGroup = nil
  effectGroup = nil
  uiGroup = nil
  statusText = nil
  selfArrow = nil
  ninjaArrow = nil
  homeButton = nil
  timerText = nil
  jumpButton = nil
  powerupButton = nil
  player = nil
  bots = {}
  groundTiles = {}
  mountainImages = nil
  cloudImages = nil
  enterFrameListener = nil
  keyListener = nil
  gameTimer = nil
  countdownTimer = nil
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
