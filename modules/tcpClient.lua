-- tcpClient.lua — Game TCP client stub (offline)
-- Original game servers are offline. Provides expected API surface.

local json = require("json")
local storyboard = require("modules.storyboard")

local tcpClient = {}

local gameServerAddress = nil
local connected = false

function tcpClient.setGameServerAddress(addr)
    gameServerAddress = addr
    print("[tcpClient] setGameServerAddress: " .. tostring(addr))
end

function tcpClient.stopTCPClient()
    connected = false
    print("[tcpClient] stopTCPClient (offline stub)")
end

function tcpClient.startTCPClient(params)
    print("[tcpClient] startTCPClient (offline stub)")
    connected = true
    -- In offline mode, we don't actually connect
end

function tcpClient.changeReceiveInfo(...)
    -- No-op in offline mode
end

function tcpClient.sendPacket(data)
    print("[tcpClient] sendPacket (offline stub)")
end

function tcpClient.sendPacketHit(data)
    print("[tcpClient] sendPacketHit (offline stub)")
end

function tcpClient.sendPacketFinish(data)
    print("[tcpClient] sendPacketFinish (offline stub)")
end

function tcpClient.sendPacketGotPU(data)
    print("[tcpClient] sendPacketGotPU (offline stub)")
end

function tcpClient.sendPacketReportPlayer(data)
    print("[tcpClient] sendPacketReportPlayer (offline stub)")
end

function tcpClient.sendPacketLobby(data)
    print("[tcpClient] sendPacketLobby (offline stub)")
end

function tcpClient.sendPacketChat(data)
    print("[tcpClient] sendPacketChat (offline stub)")
end

function tcpClient.sendPacketUDPConfirm(data)
    print("[tcpClient] sendPacketUDPConfirm (offline stub)")
end

return tcpClient
