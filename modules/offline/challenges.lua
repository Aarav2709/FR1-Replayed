-- daily challenges.

local serverData = require("modules.offline.serverData")
local population = require("modules.offline.population")

local challenges = {}

local CHALLENGES_PER_DAY = 3

local TEMPLATES = {
  { kind = "races", title = "Racer", text = "Play %d races", goals = { 3, 5, 8 }, coins = { 50, 80, 120 } },
  { kind = "wins", title = "Winner", text = "Win %d races", goals = { 1, 2, 3 }, coins = { 60, 100, 150 } },
  { kind = "podium", title = "Podium", text = "Finish in the top 2 %d times", goals = { 2, 3, 5 }, coins = { 60, 90, 130 } },
  { kind = "kills", title = "Hunter", text = "Kill %d racers", goals = { 5, 10, 15 }, coins = { 60, 100, 150 } },
  { kind = "blade", title = "Sharp", text = "Kill %d racers with blades", goals = { 2, 3, 5 }, coins = { 70, 100, 140 } },
  { kind = "trap", title = "Trapper", text = "Kill %d racers with traps", goals = { 2, 3, 5 }, coins = { 70, 100, 140 } },
  { kind = "lightning", title = "Thunder", text = "Kill %d racers with lightning", goals = { 2, 4, 6 }, coins = { 60, 90, 120 } },
  { kind = "pickups", title = "Collector", text = "Pick up %d power-ups", goals = { 10, 20, 30 }, coins = { 50, 80, 120 } },
  { kind = "clean", title = "Survivor", text = "Finish %d races without dying", goals = { 1, 2, 3 }, coins = { 70, 110, 160 } },
}

local function today()
  return os.date("%Y-%m-%d")
end

local function minutesUntilMidnight()
  local t = os.date("*t")
  return (23 - t.hour) * 60 + (59 - t.min)
end

local function generate()
  local data = serverData.get()
  local t = os.date("*t")
  local rnd = population.newRandom(data.seed + t.year * 1000 + t.yday)
  local pool = {}
  for i = 1, #TEMPLATES do
    pool[i] = TEMPLATES[i]
  end
  local list = {}
  for n = 1, CHALLENGES_PER_DAY do
    local template = table.remove(pool, rnd(#pool))
    local level = rnd(3)
    local goal = template.goals[level]
    list[n] = {
      i = 2,
      kind = template.kind,
      h = template.title,
      b = string.format(template.text, goal),
      c = template.coins[level],
      p = 0,
      g = goal,
    }
  end
  return { day = today(), list = list }
end

local function current()
  local profile = serverData.getProfile()
  if not profile.dailyChallenges or profile.dailyChallenges.day ~= today() then
    profile.dailyChallenges = generate()
    serverData.save()
  end
  return profile.dailyChallenges
end

function challenges.getList()
  local list = {}
  for i, challenge in ipairs(current().list) do
    list[i] = { i = challenge.i, h = challenge.h, b = challenge.b, c = challenge.c, p = challenge.p, g = challenge.g }
  end
  return list, minutesUntilMidnight()
end

local function progressFor(kind, result)
  if kind == "races" then
    return 1
  elseif kind == "wins" then
    return result.position == 1 and 1 or 0
  elseif kind == "podium" then
    return result.position <= 2 and 1 or 0
  elseif kind == "kills" then
    return result.kills or 0
  elseif kind == "blade" or kind == "trap" or kind == "lightning" then
    return (result.killsBy and result.killsBy[kind]) or 0
  elseif kind == "pickups" then
    return result.pickups or 0
  elseif kind == "clean" then
    return (result.deaths or 0) == 0 and 1 or 0
  end
  return 0
end

function challenges.recordRace(result)
  local completed = {}
  for _, challenge in ipairs(current().list) do
    if challenge.p < challenge.g then
      challenge.p = math.min(challenge.g, challenge.p + progressFor(challenge.kind, result))
      if challenge.p >= challenge.g then
        completed[#completed + 1] = challenge
      end
    end
  end
  serverData.save()
  return completed
end

return challenges
