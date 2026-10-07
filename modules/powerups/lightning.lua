-- lightning.

local lightning = {}

local REACH_BEHIND = 480

function lightning.new(userId, localUsername, players)
  for i = 1, #players do
    if players[i].getUsername() == localUsername then
      players[i].showCloud()
    end
  end

  timer.performWithDelay(500, function()
    for i = 1, #players do
      local racer = players[i]
      if racer.id ~= userId then
        if racer.x == nil then
          return
        end
        if racer.x + REACH_BEHIND > players[userId].x then
          racer.onCollisionPowerUp(userId, 3)
        end
      end
    end
  end, 1)

  return { x = 1, y = 1 }
end

return lightning
