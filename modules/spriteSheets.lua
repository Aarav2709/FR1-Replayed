-- sprite sheets.

local spriteSheets = {}

local function groupFor(name)
  local animal = name:match("^(%l[%w]-)hat%d+Sprite$") or name:match("^(%l[%w]-)HeadSprite$")
  if animal then
    return "hats_" .. animal
  end
  if name:match("BodySprite$") or name:match("EffectSprite$") or name:match("Feet$") then
    return "avatars"
  end
  if name:match("^boots%d+Sprite$") then
    return "boots"
  end
  if name:match("^item%d+Sprite$") then
    return "items"
  end
  return "effects"
end

function spriteSheets.get(name)
  local group = require("data.sprites." .. groupFor(name))
  local frames = group[name]
  if not frames then
    error("spriteSheets.get(): unknown sprite sheet '" .. tostring(name) .. "'", 2)
  end
  return frames
end

return spriteSheets
