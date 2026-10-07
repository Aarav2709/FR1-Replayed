-- racer corpses.

local physics = require("physics")
local sprite = require("modules.sprite")

local playerCorpses = {}

function playerCorpses.newCorpsParts(group, racer)
  local corpse = {}
  local skulls, heads, brains = {}, {}, {}
  local cleaning = false
  local HEAD_FORCE = 30
  local skullSet, headSet, brainSet

  function corpse.addSpriteSet(skullSpriteSet, headSpriteSet, brainSpriteSet)
    skullSet = skullSpriteSet
    headSet = headSpriteSet
    brainSet = brainSpriteSet
  end

  function corpse.startedCleanNow()
    cleaning = true
    for _, list in ipairs({ skulls, heads, brains }) do
      for i = 1, #list do
        display.remove(list[i])
      end
    end
  end

  local function readyPart(list, set, radius)
    if cleaning then
      return
    end
    local part = sprite.newSprite(set)
    part.xScale, part.yScale = 0.24, 0.24
    part:prepare("head")
    physics.addBody(part, { density = 0.6, friction = 1, radius = radius, bounce = 0.2, filter = powerUpFilter })
    part.x, part.y = racer.x, racer.y
    part.alpha = 0
    group:insert(part)
    list[#list + 1] = part
  end

  function corpse.readySkull()
    readyPart(skulls, skullSet, 10)
  end

  function corpse.readyHead()
    readyPart(heads, headSet, 9)
  end

  function corpse.readyBrain()
    readyPart(brains, brainSet, 6)
  end

  function corpse.dropSkull()
    if not cleaning then
      local skull = skulls[#skulls]
      skull.x, skull.y = racer.x, racer.y
      skull.alpha = 1
    end
  end

  function corpse.dropHead()
    if not cleaning then
      local head = heads[#heads]
      head.x, head.y = racer.x, racer.y - 15
      head.alpha = 1
      head:applyForce(math.random(-HEAD_FORCE * 0.5, HEAD_FORCE * 0.5) * FORCE_SCALE,
        math.random(-HEAD_FORCE * 2, -15) * FORCE_SCALE, head.x, head.y)
    end
  end

  function corpse.dropBrain()
    if not cleaning then
      local brain = brains[#brains]
      brain.x, brain.y = racer.x + 8, racer.y - 15
      brain.alpha = 1
    end
  end

  return corpse
end

return playerCorpses
