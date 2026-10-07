-- avatar sprites.

local storyboard = require("modules.storyboard")
local accessories = require("modules.accessories")
local sprite = require("modules.sprite")
local spriteSheets = require("modules.spriteSheets")

local createSprite = {}

local currentAvatar = 1

local function selectAvatar(avatarIndex)
  local avatars = accessories and accessories.getAvatarList()
  if avatars then
    if avatarIndex > #avatars then
      avatarIndex = 1
    end
  else
    avatarIndex = 1
  end
  currentAvatar = avatarIndex
end

local function toIndexes(avatarData)
  if avatarData[1] >= 100 then
    local indexes = {}
    for i = 1, #avatarData do
      indexes[i] = accessories.getTableIndex(avatarData[i])
    end
    return indexes
  end
  return avatarData
end

local function toIndex(value)
  if value >= 100 then
    return accessories.getTableIndex(value)
  end
  return value
end

local function loadSheet(part, slot, sheetName, imagePath)
  local animations = storyboard.gameDataTable.animations
  local cached = animations[part][slot]
  if cached then
    if cached[2] == sheetName then
      return cached
    end
    cached[1]:dispose()
  end
  local sheet = sprite.newSpriteSheetFromData(imagePath, spriteSheets.get(sheetName))
  animations[part][slot] = { sheet, sheetName }
  return animations[part][slot]
end

local function hatSheetName(avatarKey, hatIndex, hatSprite)
  if avatarKey == "goldfox" then
    return "goldfoxHeadSprite"
  end
  if hatIndex > 1 then
    return avatarKey .. hatSprite
  end
  return hatSprite
end

function createSprite.updateAvatar(avatarData)
  local indexes = toIndexes(avatarData)
  selectAvatar(indexes[1])
  local avatars = accessories.getAvatarList()
  local hats = accessories.getHatList(currentAvatar)
  local items = accessories.getItemList(currentAvatar)
  local boots = accessories.getBootsList(currentAvatar)
  local animations = storyboard.gameDataTable.animations
  local slot = 0

  local avatarIndex = indexes[1] > #avatars and 1 or indexes[1]
  local bodySheet = avatars[avatarIndex][6]
  if animations.avatar[slot] then
    animations.avatar[slot][1]:dispose()
  end
  animations.avatar[slot] = {
    sprite.newSpriteSheetFromData("images/game/avatar/" .. bodySheet .. ".png", spriteSheets.get(bodySheet)),
    bodySheet,
  }

  local hatIndex = indexes[2] > #hats and 1 or indexes[2]
  local avatarKey = avatars[currentAvatar][4]
  local hatSheet = hatSheetName(avatarKey, hatIndex, hats[hatIndex][4])
  if animations.hat[slot] then
    animations.hat[slot][1]:dispose()
  end
  animations.hat[slot] = {
    sprite.newSpriteSheetFromData("images/game/accessory/hat/" .. avatarKey .. "/" .. hatSheet .. ".png",
      spriteSheets.get(hatSheet)),
    hatSheet,
  }

  local itemIndex = indexes[3] > #items and 1 or indexes[3]
  if itemIndex > 1 then
    local itemSheet = items[itemIndex][4]
    if animations.item[slot] then
      animations.item[slot][1]:dispose()
    end
    animations.item[slot] = {
      sprite.newSpriteSheetFromData("images/game/accessory/item/" .. itemSheet .. ".png", spriteSheets.get(itemSheet)),
      itemSheet,
    }
    animations.item[slot].itemIndex = itemIndex
  else
    animations.item[slot] = nil
  end

  local bootsIndex = indexes[4] > #boots and 1 or indexes[4]
  local bootsSheet = boots[bootsIndex][4]
  if animations.boots[slot] then
    animations.boots[slot][1]:dispose()
  end
  animations.boots[slot] = {
    sprite.newSpriteSheetFromData("images/game/accessory/boots/" .. bootsSheet .. ".png", spriteSheets.get(bootsSheet)),
    bootsSheet,
  }
end

local SEVEN_FRAME_BODIES = {
  foxBodySprite = true, bearBodySprite = true, turtleBodySprite = true,
  bunnyBodySprite = true, doeBodySprite = true, goldfoxBodySprite = true,
}

function createSprite.changeSpriteAvatar(avatarIndex, group, slot)
  avatarIndex = toIndex(avatarIndex)
  selectAvatar(avatarIndex)
  local avatars = accessories.getAvatarList()
  if avatarIndex > #avatars then
    avatarIndex = 1
  end
  local sheetName = avatars[avatarIndex][6]
  local cached = loadSheet("avatar", slot, sheetName, "images/game/avatar/" .. sheetName .. ".png")

  local set
  if SEVEN_FRAME_BODIES[sheetName] then
    set = sprite.newSpriteSet(cached[1], 1, 7)
    sprite.add(set, "normal", 1, 7, 200, 0)
  else
    set = sprite.newSpriteSet(cached[1], 1, 14)
    sprite.add(set, "normal", 1, 14, 400, 0)
  end
  local body = sprite.newSprite(set)
  if group then
    group:insert(body)
  end
  body:prepare("normal")
  return body
end

function createSprite.changeSpriteBoots(bootsIndex, group, slot)
  bootsIndex = toIndex(bootsIndex)
  local boots = accessories.getBootsList(currentAvatar)
  if bootsIndex > #boots then
    bootsIndex = 1
  end
  local sheetName = boots[bootsIndex][4]
  local cached = loadSheet("boots", slot, sheetName, "images/game/accessory/boots/" .. sheetName .. ".png")

  local set = sprite.newSpriteSet(cached[1], 1, 7)
  sprite.add(set, "normal", 1, 7, 200, 0)
  local feet = sprite.newSprite(set)
  if group then
    group:insert(feet)
  end
  feet:prepare("normal")
  return feet
end

function createSprite.changeSpriteItem(itemIndex, group, slot)
  itemIndex = toIndex(itemIndex)
  local items = accessories.getItemList(currentAvatar)
  if itemIndex > #items then
    itemIndex = 1
  end
  if itemIndex <= 1 then
    return nil
  end
  local sheetName = items[itemIndex][4]
  local cached = loadSheet("item", slot, sheetName, "images/game/accessory/item/" .. sheetName .. ".png")
  cached.itemIndex = itemIndex

  local set = sprite.newSpriteSet(cached[1], 1, 5)
  sprite.add(set, "normal", 1, 5, 200, 1)
  local item = sprite.newSprite(set)
  if group then
    group:insert(item)
  end
  item:prepare("normal")
  return item
end

function createSprite.getSpriteItemSet(slot)
  local cached = storyboard.gameDataTable.animations.item[slot]
  if not cached then
    return nil
  end
  local set = sprite.newSpriteSet(cached[1], 1, 5)
  sprite.add(set, "normal", 1, 5, 200, 1)
  return set
end

function createSprite.changeSpriteHat(hatIndex, group, slot)
  hatIndex = toIndex(hatIndex)
  local hats = accessories.getHatList(currentAvatar)
  local avatarKey = accessories.getAvatarList()[currentAvatar][4]
  if hatIndex > #hats then
    hatIndex = 1
  end
  local sheetName = hatSheetName(avatarKey, hatIndex, hats[hatIndex][4])
  local cached = loadSheet("hat", slot, sheetName,
    "images/game/accessory/hat/" .. avatarKey .. "/" .. sheetName .. ".png")

  local set
  if avatarKey == "lion" then
    set = sprite.newSpriteSet(cached[1], 1, 14)
    sprite.add(set, "normal", 1, 14, 400, 0)
  else
    set = sprite.newSpriteSet(cached[1], 1, 7)
    sprite.add(set, "normal", 1, 7, 200, 0)
  end
  local hat = sprite.newSprite(set)
  if group then
    group:insert(hat)
  end
  hat:prepare("normal")
  hat.type = avatarKey
  return hat
end

function createSprite.cleanSuperfluousSprites()
  local animations = storyboard.gameDataTable.animations
  for slot = 1, 4 do
    for _, part in ipairs({ "avatar", "item", "boots", "hat" }) do
      if animations[part][slot] then
        animations[part][slot][1]:dispose()
        animations[part][slot] = nil
      end
    end
  end
end

return createSprite
