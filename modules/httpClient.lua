-- local account store.

local serverData = require("modules.offline.serverData")
local population = require("modules.offline.population")

local httpClient = {}

local receive

function httpClient.initWithReceiveFunction(fn)
  receive = fn
end

function httpClient.createUser(username)
  local taken = population.getByName(username) ~= nil or serverData.findAccount(username) ~= nil
  local packet
  if taken then
    packet = { m = "a", e = "This username is already taken.", s = username .. math.random(10, 99) }
  else
    local acc = serverData.createAccount(username)
    packet = { m = "a", a = 1, playerId = acc.playerId, token = acc.token }
  end
  timer.performWithDelay(300, function()
    if receive then
      receive(packet)
    end
  end, 1)
end

return httpClient
