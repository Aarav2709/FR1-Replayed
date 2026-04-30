-- createSprite.lua — Sprite creation helper module
-- Provides utility functions for creating animated sprites from the
-- pre-loaded sprite factories in storyboard.gameDataTable.sprites

local storyboard = require("modules.storyboard")
local accessories = require("modules.accessories")

local createSprite = {}

local avatarIdToKey = {}
local hatIdToSprite = {}
local itemIdToSprite = {}
local bootsIdToSprite = {}

for _, item in ipairs(accessories.getAvatarList()) do
  avatarIdToKey[item.id] = item.image
end

for _, item in ipairs(accessories.getHatList()) do
  hatIdToSprite[item.id] = item.sprite
end

for _, item in ipairs(accessories.getItemList()) do
  itemIdToSprite[item.id] = item.sprite
end

for _, item in ipairs(accessories.getBootsList()) do
  bootsIdToSprite[item.id] = item.sprite
end

local function getAvatarKey(avatarId)
  return avatarIdToKey[avatarId] or "fox"
end

local function addImage(group, path, x, y)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  f:close()
  local img = display.newImage(path)
  if not img then
    return nil
  end
  img.x = x or 0
  img.y = y or 0
  group:insert(img)
  return img
end

--------------------------------------------------------------------------------
-- createFromFactory(factoryName, x, y, group)
-- Creates a sprite instance from a named factory in gameDataTable.sprites
--------------------------------------------------------------------------------
function createSprite.createFromFactory(factoryName, x, y, group)
  local sprites = storyboard.gameDataTable and storyboard.gameDataTable.sprites
  if not sprites then
    print("createSprite: gameDataTable.sprites not initialized")
    return nil
  end

  local factory = sprites[factoryName]
  if not factory then
    print("createSprite: factory not found — " .. tostring(factoryName))
    return nil
  end

  local instance = factory.newInstance()
  if instance then
    instance.x = x or display.contentCenterX
    instance.y = y or display.contentCenterY
    if group then
      group:insert(instance)
    end
  end
  return instance
end

--------------------------------------------------------------------------------
-- createAvatarSprite(avatarData, x, y, scale, group)
-- Creates a character/avatar display group from animation data
--------------------------------------------------------------------------------
function createSprite.createAvatarSprite(avatarData, x, y, scale, group)
  local avatarGroup = display.newGroup()
  avatarGroup.x = x or display.contentCenterX
  avatarGroup.y = y or display.contentCenterY

  local data = avatarData or { 100, 200, 300, 400 }
  local avatarKey = getAvatarKey(data[1])
  local hatSprite = hatIdToSprite[data[2]] or 0
  local itemSprite = itemIdToSprite[data[3]] or 0
  local bootsSprite = bootsIdToSprite[data[4]] or 0

  if itemSprite > 0 then
    addImage(avatarGroup, "images/game/accessory/item/item" .. itemSprite .. "Sprite.png", 0, -8)
  end

  addImage(avatarGroup, "images/game/avatar/" .. avatarKey .. "BodySprite.png", 0, 0)
  addImage(avatarGroup, "images/game/avatar/" .. avatarKey .. "EffectSprite.png", 0, 0)
  addImage(avatarGroup, "images/game/accessory/boots/" .. avatarKey .. "Feet.png", 0, 18)

  if bootsSprite > 0 then
    addImage(avatarGroup, "images/game/accessory/boots/boots" .. bootsSprite .. "Sprite.png", 0, 18)
  end

  addImage(avatarGroup, "images/game/accessory/hat/" .. avatarKey .. "/" .. avatarKey .. "HeadSprite.png", 0, -16)

  if hatSprite > 0 then
    addImage(avatarGroup,
      "images/game/accessory/hat/" .. avatarKey .. "/" .. avatarKey .. "hat" .. hatSprite .. "Sprite.png", 0, -26)
  end

  if scale then
    avatarGroup:scale(scale, scale)
  end

  if group then
    group:insert(avatarGroup)
  end

  return avatarGroup
end

--------------------------------------------------------------------------------
-- createSimpleSprite(imagePath, width, height, x, y, group)
-- Creates a simple static image sprite
--------------------------------------------------------------------------------
function createSprite.createSimpleSprite(imagePath, width, height, x, y, group)
  local img = display.newImageRect(imagePath, width or 64, height or 64)
  if img then
    img.x = x or display.contentCenterX
    img.y = y or display.contentCenterY
    if group then
      group:insert(img)
    end
  end
  return img
end

--------------------------------------------------------------------------------
-- updateAvatar(avatarData, options)
-- Updates the current avatar display using static sprite assets.
-- avatarData is { avatar, hat, item, boots } indices or nil
-- options: { parent = displayGroup, x = number, y = number, scale = number }
--------------------------------------------------------------------------------
function createSprite.updateAvatar(avatarData)
  createSprite._currentAvatarData = avatarData
end

function createSprite.renderAvatar(avatarData, options)
  local opts = options or {}
  createSprite._currentAvatarData = avatarData
  print("createSprite.renderAvatar called", tostring(avatarData and avatarData[1]),
  tostring(avatarData and avatarData[2]), tostring(avatarData and avatarData[3]),
    tostring(avatarData and avatarData[4]))
  if createSprite._avatarGroup and createSprite._avatarGroup.removeSelf then
    createSprite._avatarGroup:removeSelf()
    createSprite._avatarGroup = nil
  end

  local avatarGroup = createSprite.createAvatarSprite(
    avatarData,
    opts.x,
    opts.y,
    opts.scale,
    opts.parent
  )
  createSprite._avatarGroup = avatarGroup
  return avatarGroup
end

return createSprite
