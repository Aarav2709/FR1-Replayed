-- ninja.

local ninja = {}

function ninja.new(userId, localUsername, players)
  if players[userId].getUsername() == localUsername then
    for i = 1, #players do
      if players[i].ninjaMark then
        players[i].onCollisionPowerUp(userId, 9)
      end
    end
  else
    players[math.random(1, #players)].onCollisionPowerUp(userId, 9)
  end
  return { x = 1, y = 1 }
end

return ninja
