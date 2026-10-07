-- social server connection.

local storyboard = require("modules.storyboard")
local socialServer = require("modules.offline.socialServer")

local tcpSocial = {}

local DEFAULT_INTERVAL = 1000
local interval = DEFAULT_INTERVAL
local pollTimer
local receive
local inbox = {}
local connected = false

local function poll()
  if #inbox == 0 or not receive then
    return
  end
  local packets = inbox
  inbox = {}
  for _, packet in ipairs(packets) do
    if receive then
      receive(packet)
    end
  end
end

local function deliver(packet)
  inbox[#inbox + 1] = packet
end

socialServer.setPushFunction(function(packet)
  if connected then
    deliver(packet)
  end
end)

local function startPolling()
  if pollTimer then
    timer.cancel(pollTimer)
  end
  pollTimer = timer.performWithDelay(interval, poll, 0)
end

function tcpSocial.startTCP(receiveFunction)
  if connected then
    return
  end
  connected = true
  receive = receiveFunction
  inbox = {}
  startPolling()
  local info = storyboard.playerInfo
  socialServer.handle({ m = "l", u = info.username, p = info.playerId, t = info.token, v = storyboard.gameDataTable.version },
    deliver)
end

function tcpSocial.closeTCP()
  connected = false
  if pollTimer then
    timer.cancel(pollTimer)
    pollTimer = nil
  end
  inbox = {}
end

function tcpSocial.isConnected()
  return connected
end

function tcpSocial.setReceiveInterval(ms)
  if pollTimer then
    interval = ms or DEFAULT_INTERVAL
    startPolling()
  end
end

function tcpSocial.setReceiveFunction(fn)
  if pollTimer then
    receive = fn
    startPolling()
  end
end

function tcpSocial.sendPacket(packet)
  if connected then
    socialServer.handle(packet, deliver)
  else
  end
end

return tcpSocial
