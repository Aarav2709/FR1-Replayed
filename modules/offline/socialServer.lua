-- simulated social server.

local storyboard = require("modules.storyboard")
local serverData = require("modules.offline.serverData")
local population = require("modules.offline.population")
local challenges = require("modules.offline.challenges")
local accessories = require("modules.accessories")

local socialServer = {}

local push

local MESSAGE_OF_THE_DAY = ""
local WEEKLY_PRIZES = { { t = 1 }, { t = 2, v = 20000 }, { t = 2, v = 10000 } }
local DIAMOND_DOE = 198

local function profile()
  return serverData.getProfile()
end

local function account()
  return serverData.getAccount()
end

local function ownedItems()
  local items = profile().items
  local copy = {}
  for category = 1, 4 do
    copy[category] = {}
    for i, id in ipairs(items[category] or {}) do
      copy[category][i] = id
    end
  end
  return copy
end

local function ownsItem(itemId)
  if itemId == 100 or itemId == 200 or itemId == 300 or itemId == 400 then
    return true
  end
  local category = accessories.getItem(itemId).category
  for _, id in ipairs(profile().items[category] or {}) do
    if id == itemId then
      return true
    end
  end
  return false
end

local function selfEntry(weekly)
  local p = profile()
  return {
    u = account().username,
    r = weekly and p.weeklyRating or p.rating,
    a = { p.avatar[1], p.avatar[2], p.avatar[3], p.avatar[4] },
    s = { p.wins, p.games, p.kills, p.deaths, p.suicides },
  }
end

local WEEK = 7 * 24 * 3600

local function currentWeekStart()
  local now = os.time()
  local t = os.date("*t", now)
  local daysSinceMonday = (t.wday + 5) % 7
  return os.time({ year = t.year, month = t.month, day = t.day - daysSinceMonday, hour = 0, min = 0, sec = 0 })
end

local function weeklyRanking()
  local list = {}
  for _, bot in ipairs(population.all()) do
    if bot.weeklyRating > 0 then
      list[#list + 1] = { name = bot.name, rating = bot.weeklyRating, bot = bot }
    end
  end
  list[#list + 1] = { name = account().username, rating = profile().weeklyRating, self = true }
  table.sort(list, function(a, b) return a.rating > b.rating end)
  return list
end

local function checkWeekRollover()
  local data = serverData.get()
  local weekStart = currentWeekStart()
  if not data.weekStart then
    data.weekStart = weekStart
    serverData.save()
    return
  end
  if data.weekStart < weekStart then
    local ranking = weeklyRanking()
    for place = 1, 3 do
      if ranking[place] and ranking[place].self and profile().weeklyRating > 0 then
        local prize = WEEKLY_PRIZES[place]
        if prize.t == 1 then
          if not ownsItem(DIAMOND_DOE) then
            table.insert(profile().items[1], DIAMOND_DOE)
          end
        else
          profile().coins = profile().coins + prize.v
        end
      end
    end
    profile().weeklyRating = 0
    population.resetWeek()
    data.weekStart = weekStart
    serverData.save()
  end
end

local handlers = {}

handlers.l = function(packet, reply)
  local acc = account()
  if not acc or tostring(acc.playerId) ~= tostring(packet.p) then
    reply({ m = "l", a = 4 })
    return
  end
  checkWeekRollover()
  local p = profile()
  reply({
    m = "l",
    a = 1,
    t = MESSAGE_OF_THE_DAY,
    b = storyboard.config.serverVersion,
    d = { p.avatar[1], p.avatar[2], p.avatar[3], p.avatar[4] },
    e = p.games,
    i = p.coins,
  })
end

handlers.m = function(_, reply)
  reply({ m = "m" })
end

handlers.a = function(_, reply)
  reply({ m = "a", a = "offline" })
end

handlers.h = function(_, reply)
  local list = {}
  for _, bot in ipairs(population.all()) do
    list[#list + 1] = bot
  end
  table.sort(list, function(a, b) return a.rating > b.rating end)
  local top = {}
  for i = 1, math.min(50, #list) do
    top[i] = population.rankingEntry(list[i])
  end

  local me = selfEntry(false)
  for i = 1, #top do
    if me.r > top[i].r then
      table.insert(top, i, me)
      top[51] = nil
      break
    end
  end
  reply({ m = "h", l = top, s = me })
end

handlers.u = function(_, reply)
  checkWeekRollover()
  local ranking = weeklyRanking()
  local top = {}
  for i = 1, math.min(50, #ranking) do
    local entry = ranking[i]
    if entry.self then
      top[i] = selfEntry(true)
    else
      top[i] = population.rankingEntry(entry.bot, true)
    end
  end
  local minutesLeft = math.floor((serverData.get().weekStart + WEEK - os.time()) / 60)
  reply({ m = "u", l = top, s = selfEntry(true), a = WEEKLY_PRIZES, t = minutesLeft })
end

handlers.r = function(_, reply)
  local list, minutesLeft = challenges.getList()
  reply({ m = "r", l = list, t = minutesLeft, c = profile().coins })
end

handlers.n = function(_, reply)
  reply({ m = "n", p = ownedItems(), c = profile().coins })
end

handlers.o = function(packet, reply)
  local itemId = tonumber(packet.i)
  local item = accessories.getItem(itemId)
  local p = profile()
  if ownsItem(itemId) then
    reply({ m = "o", a = 3 })
  elseif item.price < 0 or item.price >= 999999999 then
    reply({ m = "o", a = 4 })
  elseif p.coins < item.price then
    reply({ m = "o", a = 2 })
  else
    p.coins = p.coins - item.price
    table.insert(p.items[item.category], itemId)
    serverData.save()
    reply({ m = "o", a = 1, i = itemId, c = p.coins })
  end
end

handlers.p = function(packet, reply)
  local p = profile()
  local d = packet.d or {}
  for i = 1, 4 do
    local id = tonumber(d[i])
    if id and ownsItem(id) then
      p.avatar[i] = id
    end
  end
  serverData.save()
  reply({ m = "p", a = 1, d = { p.avatar[1], p.avatar[2], p.avatar[3], p.avatar[4] } })
end

handlers.w = function() end

handlers.y = function(_, reply)
  reply({ m = "y", a = {} })
end

handlers.z = function(_, reply)
  reply({ m = "z", a = profile().earnCoins })
end

local COIN_PACKS = { 4000, 20000, 50000, 200000 }
handlers.coins = function(packet, reply)
  local amount = COIN_PACKS[tonumber(packet.v) or 0]
  if not amount then
    reply({ m = "coins", a = 2 })
    return
  end
  local p = profile()
  p.coins = p.coins + amount
  serverData.save()
  reply({ m = "coins", a = 1, c = p.coins, d = amount })
end

local STARTER_OFFER_COINS = 200

handlers.A = function(packet, reply)
  local p = profile()
  local offerId = tonumber(packet.b) or 1
  for _, entry in ipairs(p.earnCoins) do
    if entry.i == offerId then
      reply({ m = "A", a = 2 })
      return
    end
  end
  table.insert(p.earnCoins, { i = offerId, c = 1 })
  p.coins = p.coins + STARTER_OFFER_COINS
  serverData.save()
  reply({ m = "A", c = p.earnCoins, d = STARTER_OFFER_COINS })
end

function socialServer.setPushFunction(fn)
  push = fn
end

function socialServer.handle(packet, reply)
  local handler = handlers[packet.m]
  if handler then
    handler(packet, reply)
  end
end

function socialServer.recordRace(result)
  local p = profile()
  p.games = p.games + 1
  if result.position == 1 then
    p.wins = p.wins + 1
  end
  p.kills = p.kills + (result.kills or 0)
  p.deaths = p.deaths + (result.deaths or 0)
  p.suicides = p.suicides + (result.suicides or 0)
  p.coins = p.coins + (result.coins or 0)
  if result.rating then
    p.rating = math.max(0, p.rating + result.rating)
    p.weeklyRating = math.max(0, p.weeklyRating + math.max(0, result.rating))
  end
  serverData.save()
  local completed = challenges.recordRace(result)
  for _, challenge in ipairs(completed) do
    p.coins = p.coins + challenge.c
    serverData.save()
    push({ m = "s", c = challenge.c, h = challenge.h })
  end
  return p
end

return socialServer
