-- bot that drives a racer.

local botModule = {}

local THINK_INTERVAL = 200
local NO_JUMP_HEIGHT = 999999

function botModule.new(racer)
  local bot = {}
  local thinkTimer
  local waitingAfterFailedJump = false
  local lastBlockedJumpY = NO_JUMP_HEIGHT
  local xHistory = {}
  local ticksSinceJump = 0
  local sendMessage
  local raceStartTime
  local RACE_NOT_STARTED, RACING, FINISHED = 0, 1, 2
  local raceState = RACE_NOT_STARTED
  local powerUpTicks = 0

  local function checkStuck()
    if #xHistory > 10 then
      local first = xHistory[1]
      for i = 2, #xHistory do
        if math.abs(first - xHistory[i]) > 30 then
          return
        end
      end
      racer:applyForce(-400 * FORCE_SCALE, -200 * FORCE_SCALE, racer.x, racer.y)
    end
  end

  local function resetJump()
    waitingAfterFailedJump = false
    lastBlockedJumpY = NO_JUMP_HEIGHT
  end

  local function tryJump(blocked)
    if racer.canJump() then
      if racer.y > lastBlockedJumpY - 20 then

        waitingAfterFailedJump = true
        timer.performWithDelay(1800, resetJump, 1)
      else
        racer.jump()
        if blocked then
          lastBlockedJumpY = racer.y
        end
      end
    end
  end

  local function sendPowerUp(powerUpId)
    if sendMessage then
      sendMessage({
        m = "h",
        i = racer.id,
        p = { t = powerUpId, x = racer.x, y = racer.y },
        s = { x = racer.x },
      })
    end
  end

  local function usePowerUp()
    local powerUp = racer.getPowerUp()
    if powerUp > 0 then
      if powerUp > 50 then
        sendPowerUp(powerUp)
        timer.performWithDelay(200, function() return sendPowerUp(powerUp - 50) end, 1)
      else
        sendPowerUp(powerUp)
      end
      racer.usedPowerUp()
    end
  end

  local function think(event)
    if not racer then
      timer.cancel(event.source)
      return
    end
    local vx = racer:getLinearVelocity()
    if vx > 0 and raceState == RACE_NOT_STARTED then
      raceState = RACING
    end

    local racing = raceState == RACING and not waitingAfterFailedJump
    if vx < 80 and racing then
      tryJump(true)
      ticksSinceJump = 0
    elseif math.random() > 0.95 and racing then
      tryJump()
      ticksSinceJump = 0
    else
      ticksSinceJump = ticksSinceJump + 1
    end
    if ticksSinceJump == 3 then
      lastBlockedJumpY = NO_JUMP_HEIGHT
    end

    if #xHistory > 12 then
      table.remove(xHistory)
    end
    if raceState == RACING and powerUpTicks > 5 then
      if racer.canJump() then
        table.insert(xHistory, 1, racer.x)
      end
      powerUpTicks = 0
      usePowerUp()
    end
    powerUpTicks = powerUpTicks + 1
    checkStuck()
  end

  function bot.setGameFunction(sendMessageFn, startTime)
    sendMessage = sendMessageFn
    raceStartTime = startTime
  end

  function bot.botDied()
    resetJump()
  end

  function bot.cleanBot()
    if thinkTimer then
      timer.cancel(thinkTimer)
      thinkTimer = nil
    end
  end

  function bot.inGoal()
    if sendMessage and racer and raceState == RACING then
      sendMessage({
        m = "j",
        i = racer.id,
        s = { x = racer.x, s = system.getTimer() - raceStartTime },
      })
    end
    raceState = FINISHED
    bot.cleanBot()
  end

  thinkTimer = timer.performWithDelay(THINK_INTERVAL, think, 0)
  return bot
end

return botModule
