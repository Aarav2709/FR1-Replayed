-- magnet.

local magnet = {}

function magnet.new(userId, localUsername, players)
  for i = 1, #players do
    if players[i].id ~= userId then
      players[i].onCollisionPowerUp(userId, 7)
    end
  end
  return { x = 1, y = 1 }
end

return magnet
