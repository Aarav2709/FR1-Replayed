-- tcpSocial.lua — Social TCP client stub (offline)
-- Original social servers are offline. Provides expected API surface.

local json = require("json")
local storyboard = require("modules.storyboard")

local tcpSocial = {}

local connected = false
local receiveFunction = nil

function tcpSocial.closeTCP()
    connected = false
    print("[tcpSocial] closeTCP (offline stub)")
end

function tcpSocial.isConnected()
    return connected
end

function tcpSocial.startTCP(...)
    print("[tcpSocial] startTCP (offline stub)")
    connected = false  -- Can't actually connect to offline servers
end

function tcpSocial.setReceiveInterval(n)
    -- No-op in offline mode
end

function tcpSocial.setReceiveFunction(fn)
    receiveFunction = fn
end

function tcpSocial.sendPacket(data)
    print("[tcpSocial] sendPacket (offline stub): " .. tostring(data and data.m or "nil"))
end

return tcpSocial
