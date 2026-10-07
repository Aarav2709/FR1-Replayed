-- game server connection.

local storyboard = require("modules.storyboard")
local gameServer = require("modules.offline.gameServer")

local tcpClient = {}

local RECEIVE_INTERVAL = 50
local receive
local connected = false

local function deliver(packet)
  timer.performWithDelay(RECEIVE_INTERVAL, function()
    if connected and receive then
      receive(packet)
    end
  end, 1)
end

function tcpClient.setGameServerAddress() end

function tcpClient.startTCPClient(info, receiveFunction)
  tcpClient.stopTCPClient()
  connected = true
  receive = receiveFunction
  gameServer.connect(info, deliver)
end

function tcpClient.stopTCPClient()
  if connected then
    gameServer.disconnect()
  end
  connected = false
end

function tcpClient.changeReceiveInfo(fn)
  if connected then
    receive = fn
  end
end

function tcpClient.sendPacketLobby(packet)
  if connected then
    gameServer.receive({ m = packet.m, v = packet.v })
  end
end

function tcpClient.reportRaceResult(result)
  return gameServer.finishRace(result)
end

function tcpClient.getRacers()
  return gameServer.getRacers()
end

function tcpClient.sendPacket() end
function tcpClient.sendPacketHit() end
function tcpClient.sendPacketFinish() end
function tcpClient.sendPacketGotPU() end
function tcpClient.sendPacketReportPlayer() end
function tcpClient.sendPacketUDPConfirm() end

return tcpClient
