-- saved account and server data.

local json = require("json")

local serverData = {}

serverData.START_COINS = 0

local FILE = "offline_server.json"
local PREVIOUS = FILE .. ".previous"
local TEMP = FILE .. ".tmp"
local SAVE_VERSION = 2
local data

-- steps that upgrade an older save. key is the version a step upgrades to.
local MIGRATIONS = {}

local function pathOf(name)
  return system.pathForFile(name, system.DocumentsDirectory)
end

local function exists(name)
  local file = io.open(pathOf(name), "rb")
  if file then
    file:close()
    return true
  end
  return false
end

local function readSave(name)
  local file = io.open(pathOf(name), "rb")
  if not file then
    return nil
  end
  local text = file:read("*a")
  file:close()
  local ok, decoded = pcall(json.decode, text)
  if ok and type(decoded) == "table" and type(decoded.accounts) == "table" then
    return decoded
  end
end

local function defaults()
  return {
    version = SAVE_VERSION,
    seed = os.time(),
    nextPlayerId = 2000000,
    accounts = {},
    current = nil,
    bots = nil,
    botsUpdated = os.time(),
    weekStart = nil,
  }
end

local function newProfile()
  return {
    coins = serverData.START_COINS,
    items = { {}, {}, {}, {} },
    avatar = { 100, 200, 300, 400 },
    rating = 0,
    weeklyRating = 0,
    games = 0,
    wins = 0,
    kills = 0,
    deaths = 0,
    suicides = 0,
    earnCoins = {},
    dailyChallenges = nil,
  }
end

function serverData.load()
  if data then
    return data
  end
  data = readSave(FILE) or readSave(PREVIOUS) or readSave(TEMP)
  if not data then
    if exists(FILE) then
      os.rename(pathOf(FILE), pathOf(FILE .. ".damaged-" .. os.time()))
    end
    data = defaults()
  end
  local version = tonumber(data.version) or 1
  if version < SAVE_VERSION then
    for target = version + 1, SAVE_VERSION do
      if MIGRATIONS[target] then
        MIGRATIONS[target](data)
      end
    end
  end
  for key, value in pairs(defaults()) do
    if data[key] == nil then
      data[key] = value
    end
  end
  if version < SAVE_VERSION then
    data.version = SAVE_VERSION
  end
  return data
end

function serverData.save()
  if not data then
    return
  end
  local text = json.encode(data)
  local file = io.open(pathOf(TEMP), "wb")
  if not file then
    return
  end
  local written = file:write(text)
  file:close()
  if not written or not readSave(TEMP) then
    return
  end
  if exists(FILE) then
    os.remove(pathOf(PREVIOUS))
    os.rename(pathOf(FILE), pathOf(PREVIOUS))
  end
  if not os.rename(pathOf(TEMP), pathOf(FILE)) then
    os.rename(pathOf(PREVIOUS), pathOf(FILE))
  end
end

function serverData.get()
  return serverData.load()
end

function serverData.current()
  local d = serverData.load()
  if d.current then
    return d.accounts[tostring(d.current)]
  end
end

function serverData.createAccount(username)
  local d = serverData.load()
  local id = d.nextPlayerId
  d.nextPlayerId = id + 1
  local entry = {
    account = {
      playerId = id,
      username = username,
      token = string.format("%08x%08x", math.random(0, 0x7fffffff), os.time()),
    },
    profile = newProfile(),
    friends = {},
    friendRequests = {},
  }
  d.accounts[tostring(id)] = entry
  d.current = id
  serverData.save()
  return entry.account
end

function serverData.findAccount(username)
  local d = serverData.load()
  for _, entry in pairs(d.accounts) do
    if entry.account.username:lower() == tostring(username):lower() then
      return entry
    end
  end
end

function serverData.renameAccount(username)
  local acc = serverData.getAccount()
  if not acc then
    return "Error"
  end
  local other = serverData.findAccount(username)
  if other and other.account ~= acc then
    return "This username is already taken."
  end
  acc.username = username
  serverData.save()
end

function serverData.setCurrent(playerId)
  serverData.load().current = playerId
  serverData.save()
end

function serverData.getAccount()
  local entry = serverData.current()
  return entry and entry.account
end

function serverData.getProfile()
  local entry = serverData.current()
  return entry and entry.profile
end

return serverData
