-- map names and ids.

local mapInfo = {}

mapInfo.mapList = {
  {
    { "Random", "Random", 0, 25 },
    { "Tutorial", "Random", 38, 999 },
  },
  {
    { "Sunset Valley", "SunsetValley", 1, 24 },
    { "Green Hills", "GreenHills", 2, 24 },
    { "Cliff Climber", "CliffClimber", 3, 24 },
    { "Cloud Road", "CloudRoad", 4, 24 },
    { "Broken Bridge", "BrokenBridge", 5, 24 },
    { "Mountain View", "MountainView", 6, 24 },
    { "Bridgetown", "Bridgetown", 13, 24 },
    { "Forest Jump", "ForestJump", 14, 24 },
    { "High Peak", "HighPeak", 15, 24 },
    { "Twig Peaks", "TwigPeaks", 16, 24 },
    { "Jumping Bluffs", "JumpingBluffs", 17, 24 },
    { "Hidden Caves", "HiddenCaves", 18, 24 },
    { "Bridge Pass", "BridgePass", 19, 24 },
  },
  {
    { "Sugar Slope", "SugarSlope", 7, 24 },
    { "Jelly Cave", "JellyCave", 8, 24 },
    { "Candy Shop", "CandyShop", 9, 24 },
    { "Chocolate Tops", "ChocolateTops", 10, 24 },
    { "Frosting Fields", "FrostingFields", 11, 25 },
    { "Lollipop Road", "LollipopRoad", 12, 24 },
  },
  {
    { "Sand Castle", "SandCastle", 20, 25 },
    { "Treacherous Pits", "TreacherousPits", 21, 25 },
    { "Sand Storm", "SandStorm", 22, 25 },
    { "Beach Part-A", "BeachPartA", 23, 26 },
    { "Buried Treasure", "BuriedTreasure", 24, 27 },
    { "Sliding Beaches", "SlidingBeaches", 25, 28 },
  },
  {
    { "Cloud Mountain", "CloudMountain", 26, 29 },
    { "Autumn Trails", "AutumnTrails", 27, 29 },
    { "Critter Fall", "CritterFall", 28, 29 },
    { "Leafy Path", "LeafyPath", 29, 30 },
    { "Windy Peak", "WindyPeak", 30, 31 },
    { "Leaf Storm", "LeafStorm", 31, 31 },
  },
  {
    { "Snowset Valley", "SnowsetValley", 32, 31 },
    { "White Hills", "WhiteHills", 33, 31 },
    { "Glacier Climb", "GlacierClimb", 34, 31 },
    { "Powder Bridge", "PowderBridge", 35, 31 },
    { "Slush Cave", "SlushCave", 36, 31 },
    { "Avalanche Medley", "AvalancheMedley", 37, 31 },
  },
}

mapInfo.postLobbyImages = { "postLobby", "postLobby", "postLobby2", "postLobby3", "postLobby4", "postLobby5" }
mapInfo.mapElementTheme = { "forest", "forest", "candy", "beach", "fall", "snow" }

local NAME, ICON, ID, MIN_VERSION = 1, 2, 3, 4

local function findMap(fn)
  for group = 1, #mapInfo.mapList do
    for _, entry in ipairs(mapInfo.mapList[group]) do
      local result = fn(group, entry)
      if result ~= nil then
        return result
      end
    end
  end
end

function mapInfo.getPostLobbyImage(mapId)
  local image = findMap(function(group, entry)
    if entry[ID] == mapId then return mapInfo.postLobbyImages[group] end
  end)
  if image then
    return image
  end
  return mapInfo.postLobbyImages[1]
end

function mapInfo.getMapElementTheme(mapId)
  local theme = findMap(function(group, entry)
    if entry[ID] == mapId then return mapInfo.mapElementTheme[group] end
  end)
  if theme then
    return theme
  end
  return mapInfo.postLobbyImages[1]
end

function mapInfo.getMapId(iconName)
  local id = findMap(function(_, entry)
    if entry[ICON] == iconName then return entry[ID] end
  end)
  if id == nil then
    return 1
  end
  return id
end

function mapInfo.getMapIcon(mapId)
  local icon = findMap(function(_, entry)
    if entry[ID] == mapId then return entry[ICON] end
  end)
  if icon == nil then
    return "SunsetValley"
  end
  return icon
end

function mapInfo.getMapName(mapId)
  local name = findMap(function(_, entry)
    if entry[ID] == mapId then return entry[NAME] end
  end)
  if name == nil then
    return "Sunset Valley"
  end
  return name
end

function mapInfo.getAllMapImageNames(serverVersion)
  local names = {}
  findMap(function(_, entry)
    if serverVersion >= entry[MIN_VERSION] then
      names[#names + 1] = entry[ICON]
    end
  end)
  return names
end

function mapInfo.getAllMapImageNamesForPracticeMode()
  local names = {}
  findMap(function(_, entry)
    if entry[ICON] ~= "BridgePass" and entry[ICON] ~= "Random" then
      names[#names + 1] = entry[ICON]
    end
  end)
  return names
end

function mapInfo.isMapCommingSoon(serverVersion, iconName)
  local soon = findMap(function(_, entry)
    if iconName == entry[ICON] and serverVersion < entry[MIN_VERSION] then return true end
  end)
  return soon == true
end

return mapInfo
