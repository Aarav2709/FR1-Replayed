-- tutorial race prompts.

local storyboard = require("modules.storyboard")

local tutorialModule = {}

local group
local firstJumpShown, powerUpShown
local finished
local showPowerUpButton
local showJumpButtons
local jumpButtonPending, powerUpButtonPending
local lastJumpTime
local secondJumpCount
local overlay, arrow
local waitingFor
local physics
local paused
local arrowTransition, endTimer

local bounceArrowDown

local function bounceArrowUp()
  arrowTransition = transition.to(arrow, { y = 220, time = 500, onComplete = bounceArrowDown })
end

function bounceArrowDown()
  arrowTransition = transition.to(arrow, { y = 240, time = 500, onComplete = bounceArrowUp })
end

local function returnToMenu()
  storyboard.gotoScene("scenes.playMenu")
  storyboard.purgeScene("scenes.gamePlay")
end

local function finish()
  if finished and endTimer == nil then
    finished = false
    paused = true
    endTimer = timer.performWithDelay(1500, returnToMenu, 1)
  end
end

local function resume()
  waitingFor = 0
  overlay.alpha = 0
  physics.start()
  paused = false
  if arrowTransition then
    transition.cancel(arrowTransition)
    arrowTransition = nil
  end
end

local function pauseFor(racer)
  overlay.alpha = 0.4
  physics.pause()
  racer.tutorialPause(true)
  paused = true
  bounceArrowDown()
end

local function powerUpPressed()
  if arrow then
    arrow.alpha = 0
    resume()
  end
end

local function showPowerUpHint(racer)
  if powerUpShown == 0 then
    powerUpShown = 1
    waitingFor = 3
    arrow.anchorX, arrow.anchorY = 0, 1
    arrow.x, arrow.y = 10, 220
    arrow.alpha = 1
    pauseFor(racer)
    group:insert(arrow)
  end
end

local function firstJumpPressed()
  if arrow then
    arrow.alpha = 0
    resume()
  end
end

local function showFirstJumpHint(racer)
  if firstJumpShown == 0 then
    firstJumpShown = 1
    waitingFor = 1
    arrow.y = 220
    arrow.alpha = 1
    pauseFor(racer)
    group:insert(arrow)
  end
end

local function secondJumpPressed()
  if arrow then
    arrow.alpha = 0
    lastJumpTime = system.getTimer()
    resume()
  end
end

local function showSecondJumpHint(racer)
  if secondJumpCount < 2 and waitingFor == 0 and lastJumpTime + 300 < system.getTimer() then
    secondJumpCount = secondJumpCount + 1
    waitingFor = 2
    arrow.y = 220
    arrow.alpha = 1
    pauseFor(racer)
    group:insert(arrow)
  end
end

local function createGraphics()
  overlay = display.newImageRect("images/game/black.png", display.contentWidth, 320)
  overlay.anchorX, overlay.anchorY = 0, 0
  overlay.x, overlay.y = 0, 0
  overlay.alpha = 0
  group:insert(overlay)
  arrow = display.newImageRect("images/game/arrow.png", 70, 105)
  arrow.anchorX, arrow.anchorY = 1, 1
  arrow.x, arrow.y = 475, 220
  arrow.alpha = 0
  group:insert(arrow)
end

function tutorialModule.update(racer)
  local x = racer.x
  if x > 600 and jumpButtonPending then
    jumpButtonPending = false
    showJumpButtons()
  end
  if x > 3500 and powerUpButtonPending then
    powerUpButtonPending = false
    showPowerUpButton()
  end
  if not paused then
    racer.tutorialPause(false)
  end
  if x > 740 and x < 800 then
    showFirstJumpHint(racer)
  elseif x > 2260 and x < 2290 then
    showSecondJumpHint(racer)
  elseif x > 3650 and x < 3800 then
    showPowerUpHint(racer)
  elseif x > 4300 then
    finish()
  end
end

function tutorialModule.clean()
  if arrowTransition then
    transition.cancel(arrowTransition)
    arrowTransition = nil
  end
  if endTimer then
    timer.cancel(endTimer)
    endTimer = nil
  end
end

function tutorialModule.jumpButtonClicked()
  if waitingFor == 1 then
    firstJumpPressed()
    return true
  elseif waitingFor == 2 then
    secondJumpPressed()
    return true
  end
  return false
end

function tutorialModule.puButtonClicked()
  if waitingFor == 3 then
    powerUpPressed()
    return true
  end
  return false
end

function tutorialModule.physicsIsPaused()
  return paused
end

function tutorialModule.setFunctions(onShowJumpButtons, onShowPowerUpButton)
  showJumpButtons = onShowJumpButtons
  showPowerUpButton = onShowPowerUpButton
end

function tutorialModule.init(sceneGroup, physicsModule)
  group = sceneGroup
  firstJumpShown = 0
  powerUpShown = 0
  secondJumpCount = 0
  waitingFor = 0
  physics = physicsModule
  paused = false
  jumpButtonPending = true
  powerUpButtonPending = true
  finished = true
  lastJumpTime = 0
  createGraphics()
end

return tutorialModule
