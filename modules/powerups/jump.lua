-- jump.

local jump = {}

function jump.new(userId, players)
  local racer = players[userId]
  if racer then
    racer.playPowerUpJumpEffect()
    local _, vy = racer:getLinearVelocity()
    if vy < -140 then
      racer:applyForce(100 * FORCE_SCALE, -250 * FORCE_SCALE, racer.x, racer.y)
    elseif vy > 100 then
      racer:applyForce(100 * FORCE_SCALE, -400 * FORCE_SCALE, racer.x, racer.y)
    else
      racer:applyForce(100 * FORCE_SCALE, -300 * FORCE_SCALE, racer.x, racer.y)
    end
  end
  return { x = 1, y = 1 }
end

return jump
