-- simulated quick play server.

local storyboard = require("modules.storyboard")
local serverData = require("modules.offline.serverData")
local population = require("modules.offline.population")

local gameServer = {}

local MAX_PLAYERS = 4
local QUICK_PLAY_COUNTDOWN = 10
local FULL_LOBBY_COUNTDOWN = 5

local MAP_IDS = {}
for id = 1, 37 do
  MAP_IDS[#MAP_IDS + 1] = id
end

local session
local send

local function later(delay, fn)
  local current = session
  local handle = timer.performWithDelay(delay, function()
    if session == current and not current.closed then
      fn()
    end
  end, 1)
  current.timers[#current.timers + 1] = handle
  return handle
end

local function playerList()
  local list = {}
  for i, p in ipairs(session.players) do
    list[i] = { n = p.name, a = p.avatar, v = p.vote }
  end
  return list
end

local function sendLobby()
  send({ players = playerList(), maps = session.maps, t = session.countdown or 99 })
end

local function addBot(bot, vote)
  if #session.players >= MAX_PLAYERS then
    return false
  end
  for _, p in ipairs(session.players) do
    if p.botId == bot.id then
      return false
    end
  end
  session.players[#session.players + 1] = {
    name = bot.name,
    avatar = { bot.avatar[1], bot.avatar[2], bot.avatar[3], bot.avatar[4] },
    vote = vote or 0,
    botId = bot.id,
    rating = bot.rating,
  }
  return true
end

local function localPlayer()
  local acc = serverData.getAccount()
  local profile = serverData.getProfile()
  return {
    name = acc.username,
    avatar = { profile.avatar[1], profile.avatar[2], profile.avatar[3], profile.avatar[4] },
    vote = 0,
    isPlayer = true,
    rating = profile.rating,
  }
end

local function chooseMap()
  local votes = {}
  for _, p in ipairs(session.players) do
    if p.vote and p.vote > 0 then
      votes[p.vote] = (votes[p.vote] or 0) + 1
    end
  end
  local best, bestCount = {}, 0
  for mapId, count in pairs(votes) do
    if count > bestCount then
      best, bestCount = { mapId }, count
    elseif count == bestCount then
      best[#best + 1] = mapId
    end
  end
  if #best == 0 then
    if session.maps then
      return session.maps[math.random(#session.maps)]
    end
    return MAP_IDS[math.random(#MAP_IDS)]
  end
  return best[math.random(#best)]
end

local function startRace(mapId)
  if session.started then
    return
  end
  session.started = true
  session.mapId = mapId
  send({ mI = mapId })
end

local function quickPlayTick()
  if session.started then
    return
  end
  if session.countdown then
    session.countdown = session.countdown - 1
    if session.countdown <= 0 then
      startRace(chooseMap())
      return
    end
    sendLobby()
  end
  later(1000, quickPlayTick)
end

local function quickPlayJoin(queue)
  if session.started or #queue == 0 then
    return
  end
  local bot = table.remove(queue, 1)
  if addBot(bot, 0) then
    local joined = session.players[#session.players]
    later(math.random(600, 3000), function()
      joined.vote = session.maps[math.random(2)]
      sendLobby()
    end)
    if #session.players >= 2 and not session.countdown then
      session.countdown = QUICK_PLAY_COUNTDOWN
    end
    if #session.players == MAX_PLAYERS and session.countdown > FULL_LOBBY_COUNTDOWN then
      session.countdown = FULL_LOBBY_COUNTDOWN
    end
    sendLobby()
  end
  later(math.random(700, 3500), function() quickPlayJoin(queue) end)
end

local function startQuickPlay()
  local maps = {}
  local pool = {}
  for i = 1, #MAP_IDS do
    pool[i] = MAP_IDS[i]
  end
  maps[1] = table.remove(pool, math.random(#pool))
  maps[2] = table.remove(pool, math.random(#pool))
  session.maps = maps

  local me = session.players[1]
  local opponents = population.pickOpponents(MAX_PLAYERS - 1, me.rating)
  later(math.random(300, 900), function()
    sendLobby()
    later(math.random(500, 2500), function() quickPlayJoin(opponents) end)
    later(1000, quickPlayTick)
  end)
end

function gameServer.connect(info, sendFunction)
  gameServer.disconnect()
  send = sendFunction
  session = { players = { localPlayer() }, timers = {} }
  startQuickPlay()
end

function gameServer.disconnect()
  if session then
    session.closed = true
    for _, handle in ipairs(session.timers) do
      timer.cancel(handle)
    end
  end
end

function gameServer.receive(packet)
  if not session or session.closed then
    return
  end
  local me
  for _, p in ipairs(session.players) do
    if p.isPlayer then
      me = p
    end
  end
  if packet.m == "e" and me then
    me.vote = tonumber(packet.v) or 0
    sendLobby()
  end
end

function gameServer.getRacers()
  return session and session.players or {}
end

local COINS_BY_PLACE = { 40, 25, 15, 10 }
local RATING_K = 16

function gameServer.finishRace(result)
  local socialServer = require("modules.offline.socialServer")
  local profile = serverData.getProfile()
  local isQuickPlay = storyboard.gameType == 2

  local coins = COINS_BY_PLACE[result.position] or 5
  if #result.racers < MAX_PLAYERS then
    coins = math.floor(coins * #result.racers / MAX_PLAYERS)
  end
  if result.quit then
    coins = 0
  end

  local ratingChange = 0
  if isQuickPlay then
    for _, racer in ipairs(result.racers) do
      if not racer.isPlayer then
        local bot = racer.botId and population.getById(racer.botId)
        local opponentRating = bot and bot.rating or profile.rating
        local expected = 1 / (1 + 10 ^ ((opponentRating - profile.rating) / 400))
        local score = result.position < racer.place and 1 or 0
        local delta = RATING_K * (score - expected)
        ratingChange = ratingChange + delta
        if bot then
          bot.rating = math.max(0, math.floor(bot.rating - delta + 0.5))
          bot.games = bot.games + 1
          if racer.place == 1 then
            bot.wins = bot.wins + 1
          end
        end
      end
    end
    ratingChange = math.floor(ratingChange + 0.5)
  end

  result.coins = coins
  result.rating = isQuickPlay and ratingChange or nil
  local ratingBefore = profile.rating
  local updated = socialServer.recordRace(result)
  ratingChange = updated.rating - ratingBefore

  return {
    m = "l",
    i = 1,
    r = updated.rating,
    dr = ratingChange,
    c = updated.coins,
    dc = coins,
    b = 0,
  }
end

return gameServer
