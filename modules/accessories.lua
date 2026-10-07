-- avatar items.

local accessories = {}

accessories.productList = require("data.products")
accessories.avatarList = {}

local AVATARS, HATS, ITEMS, BOOTS = 1, 2, 3, 4

function accessories.getAvatarList()
  return accessories.productList[AVATARS]
end

function accessories.isOldAvtar(avatarIndex)
  local avatar = accessories.productList[AVATARS][avatarIndex]
  return avatar[#avatar] == true
end

function accessories.getAvatarName(avatarIndex)
  return accessories.productList[AVATARS][avatarIndex][4]
end

function accessories.useSpecialY(category, index)
  local entry = accessories.productList[category][index]
  return entry[#entry] == true
end

local function listForAvatar(category, avatarIndex, avatarSpriteField)
  if avatarIndex > #accessories.productList[AVATARS] then
    avatarIndex = 1
  end
  local list = accessories.productList[category]
  list[1][4] = accessories.productList[AVATARS][avatarIndex][avatarSpriteField]
  return list
end

function accessories.getHatList(avatarIndex)
  return listForAvatar(HATS, avatarIndex, 5)
end

function accessories.getItemList(avatarIndex)
  return listForAvatar(ITEMS, avatarIndex, 6)
end

function accessories.getBootsList(avatarIndex)
  return listForAvatar(BOOTS, avatarIndex, 7)
end

function accessories.getItem(itemId)
  for category = 1, #accessories.productList do
    local list = accessories.productList[category]
    for index = 1, #list do
      if itemId == list[index][2] then
        return { category = category, price = list[index][3], item = index }
      end
    end
  end
  local category
  if itemId < 200 then
    category = AVATARS
  elseif itemId < 300 then
    category = HATS
  elseif itemId < 400 then
    category = ITEMS
  else
    category = BOOTS
  end
  return { category = category, price = 0, item = 1 }
end

function accessories.getItemId(category, index)
  local list = accessories.productList[category]
  if index > #list then
    return list[1][2]
  end
  return list[index][2]
end

function accessories.getTableIndex(itemId)
  for category = 1, #accessories.productList do
    local list = accessories.productList[category]
    for index = 1, #list do
      if itemId == list[index][2] then
        return index
      end
    end
  end
  return 1
end

return accessories
