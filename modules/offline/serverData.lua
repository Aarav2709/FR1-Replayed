-- saved account and server data.

local json = require("json")

local serverData = {}

serverData.START_COINS = 0

local FILE = "offline_server.json"
local data

local function defaults()
  return {
    version = 2,
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
  local path = system.pathForFile(FILE, system.DocumentsDirectory)
  local file = io.open(path, "r")
  if file then
    local ok, decoded = pcall(json.decode, file:read("*a"))
    file:close()
    if ok and type(decoded) == "table" then
      data = decoded
    end
  end
  if not data then
    data = defaults()
  end
  for key, value in pairs(defaults()) do
    if data[key] == nil then
      data[key] = value
    end
  end
  return data
end

function serverData.save()
  if not data then
    return
  end
  local path = system.pathForFile(FILE, system.DocumentsDirectory)
  local file = io.open(path, "w")
  if file then
    file:write(json.encode(data))
    file:close()
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
