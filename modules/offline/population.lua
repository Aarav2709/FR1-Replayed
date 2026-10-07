-- simulated players.

local serverData = require("modules.offline.serverData")
local accessories = require("modules.accessories")

local population = {}

local POPULATION_SIZE = 300
local FIRST_BOT_ID = 100000

local function newRandom(seed)
  local state = seed % 2147483647
  if state <= 0 then
    state = state + 2147483646
  end
  return function(a, b)
    state = (state * 16807) % 2147483647
    local r = (state - 1) / 2147483646
    if a == nil then
      return r
    end
    if b == nil then
      a, b = 1, a
    end
    return a + math.floor(r * (b - a + 1))
  end
end

local PREFIXES = {
  "Speedy", "Crazy", "Little", "Super", "Mega", "Turbo", "Happy", "Sneaky", "Lucky", "Silent",
  "Dark", "Golden", "Tiny", "Big", "Mad", "Jumpy", "Wild", "Cool", "Funny", "Ninja",
  "Dizzy", "Fluffy", "Rapid", "Brave", "Epic", "Hyper", "Sly", "Lazy", "Rocket", "Shadow",
}
local NOUNS = {
  "Fox", "Bear", "Panda", "Runner", "Racer", "Bunny", "Tiger", "Wolf", "Turtle", "Ninja",
  "Gamer", "Dash", "Jumper", "Skunk", "Lion", "Kitty", "Doggy", "Eagle", "Shark", "Dragon",
  "Monkey", "Penguin", "Beaver", "Hippo", "Rhino", "Gecko", "Mouse", "Parrot", "Squirrel", "Bolt",
}
local NAMES = {
  "alex", "emma", "lucas", "mia", "noah", "sofia", "liam", "olivia", "max", "nora",
  "jonas", "ella", "oscar", "ida", "henrik", "sara", "magnus", "ingrid", "kevin", "lisa",
  "tom", "anna", "jake", "lily", "ryan", "zoe", "sam", "chloe", "leo", "maya",
}

local function makeName(rnd, used)
  for _ = 1, 20 do
    local style = rnd(1, 4)
    local name
    if style == 1 then
      name = PREFIXES[rnd(#PREFIXES)] .. NOUNS[rnd(#NOUNS)]
    elseif style == 2 then
      name = PREFIXES[rnd(#PREFIXES)] .. NOUNS[rnd(#NOUNS)] .. rnd(1, 99)
    elseif style == 3 then
      name = NAMES[rnd(#NAMES)] .. rnd(1, 2005)
    else
      name = NOUNS[rnd(#NOUNS)] .. NAMES[rnd(#NAMES)]
    end
    if #name <= 15 and not used[name:lower()] then
      used[name:lower()] = true
      return name
    end
  end
  local name = "player" .. rnd(10000, 99999)
  used[name] = true
  return name
end

local function pickItem(rnd, list, wealth, chanceNothing)
  if rnd() < chanceNothing then
    return list[1][2]
  end
  local affordable = {}
  for i = 2, #list do
    local price = list[i][3]
    if price >= 0 and price <= wealth then
      affordable[#affordable + 1] = list[i][2]
    end
  end
  if #affordable == 0 then
    return list[1][2]
  end
  return affordable[rnd(#affordable)]
end

local function makeBot(rnd, index, used)
  local skill = rnd() ^ 1.6
  local games = math.floor(20 + skill * 4000 * rnd() + rnd(0, 150))
  local winRate = 0.12 + skill * 0.45
  local wins = math.floor(games * winRate)
  local kills = math.floor(games * (0.3 + skill * 1.4))
  local deaths = math.floor(games * (0.9 - skill * 0.4))
  local suicides = math.floor(games * (0.02 + rnd() * 0.08))
  local rating = math.max(0, math.floor((winRate - 0.25) * games * 3 + rnd(0, 120)))
  local wealth = math.floor(300 + skill * 120000 * rnd())

  local avatars = accessories.productList[1]
  local avatarId = pickItem(rnd, avatars, wealth, 0.25)
  local hatId = pickItem(rnd, accessories.productList[2], wealth, 0.3)
  local itemId = pickItem(rnd, accessories.productList[3], wealth, 0.5)
  local bootsId = pickItem(rnd, accessories.productList[4], wealth, 0.4)

  return {
    id = FIRST_BOT_ID + index,
    name = makeName(rnd, used),
    skill = skill,
    rating = rating,
    weeklyRating = 0,
    games = games,
    wins = wins,
    kills = kills,
    deaths = deaths,
    suicides = suicides,
    avatar = { avatarId, hatId, itemId, bootsId },
    chatty = rnd() < 0.4,
  }
end

local bots
local byId
local byName

local function index()
  byId, byName = {}, {}
  for _, bot in ipairs(bots) do
    byId[bot.id] = bot
    byName[bot.name:lower()] = bot
  end
end

local function simulateElapsedTime()
  local data = serverData.get()
  local now = os.time()
  local elapsed = now - (data.botsUpdated or now)
  if elapsed < 60 then
    return
  end
  data.botsUpdated = now
  local rnd = newRandom(data.seed + now)
  local hours = math.min(elapsed / 3600, 24 * 7)
  for _, bot in ipairs(bots) do
    local races = math.floor(hours * (0.5 + bot.skill * 3) * rnd())
    if races > 0 then
      local winRate = 0.12 + bot.skill * 0.45
      local won = math.floor(races * winRate + rnd() * 0.5)
      bot.games = bot.games + races
      bot.wins = bot.wins + won
      bot.kills = bot.kills + math.floor(races * (0.3 + bot.skill * 1.4))
      bot.deaths = bot.deaths + math.floor(races * (0.9 - bot.skill * 0.4))
      local delta = math.floor((won * 4 - (races - won)) * (0.5 + bot.skill))
      bot.rating = math.max(0, bot.rating + delta)
      bot.weeklyRating = math.max(0, bot.weeklyRating + delta)
    end
  end
  serverData.save()
end

function population.load()
  if bots then
    simulateElapsedTime()
    return bots
  end
  local data = serverData.get()
  if not data.bots or #data.bots == 0 then
    local rnd = newRandom(data.seed)
    local used = {}
    data.bots = {}
    for i = 1, POPULATION_SIZE do
      data.bots[i] = makeBot(rnd, i, used)
    end
    data.botsUpdated = os.time()
    serverData.save()
  end
  bots = data.bots
  index()
  simulateElapsedTime()
  return bots
end

function population.all()
  return population.load()
end

function population.getById(id)
  population.load()
  return byId[tonumber(id)]
end

function population.getByName(name)
  population.load()
  return byName[tostring(name):lower()]
end

function population.pickOpponents(count, rating, excluded)
  local list = population.load()
  excluded = excluded or {}
  local candidates = {}
  for _, bot in ipairs(list) do
    if not excluded[bot.id] then
      candidates[#candidates + 1] = bot
    end
  end

  table.sort(candidates, function(a, b)
    return math.abs(a.rating - rating) < math.abs(b.rating - rating)
  end)
  local pool = math.min(#candidates, math.max(count * 6, 30))
  local picked = {}
  for _ = 1, count do
    if pool < 1 then
      break
    end
    local i = math.random(1, pool)
    picked[#picked + 1] = candidates[i]
    table.remove(candidates, i)
    pool = pool - 1
  end
  return picked
end

function population.isOnline(bot)
  local slot = math.floor(os.time() / 300)
  local rnd = newRandom(bot.id * 7919 + slot)
  return rnd() < 0.35 + bot.skill * 0.3
end

function population.rankingEntry(bot, weekly)
  return {
    u = bot.name,
    r = weekly and bot.weeklyRating or bot.rating,
    a = { bot.avatar[1], bot.avatar[2], bot.avatar[3], bot.avatar[4] },
    s = { bot.wins, bot.games, bot.kills, bot.deaths, bot.suicides },
    i = bot.id,
  }
end

function population.resetWeek()
  for _, bot in ipairs(population.load()) do
    bot.weeklyRating = 0
  end
end

population.newRandom = newRandom

return population
