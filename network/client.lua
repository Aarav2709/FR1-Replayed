-- network/client.lua
-- Network Client for Multiplayer

local M = {}

local json = require("json")
local socket = require("socket")

-- Client state
M.isConnected = false
M.socket = nil
M.callbacks = {}

-- Connect to server
function M.connect(url, port)
    M.socket = socket.tcp()
    M.socket:settimeout(0) -- Non-blocking
    
    local result, err = M.socket:connect(url, port)
    if result then
        M.isConnected = true
        print("Connected to server")
        return true
    else
        print("Failed to connect:", err)
        return false
    end
end

-- Disconnect from server
function M.disconnect()
    if M.socket then
        M.socket:close()
        M.socket = nil
        M.isConnected = false
        print("Disconnected from server")
    end
end

-- Send message to server
function M.send(messageType, data)
    if not M.isConnected then
        return false
    end
    
    local message = {
        type = messageType,
        data = data,
        timestamp = system.getTimer()
    }
    
    local jsonMessage = json.encode(message) .. "\n"
    local result, err = M.socket:send(jsonMessage)
    
    if err then
        print("Send error:", err)
        return false
    end
    
    return true
end

-- Receive messages from server
function M.receive()
    if not M.isConnected then
        return
    end
    
    local data, err = M.socket:receive("*l")
    if data then
        local message = json.decode(data)
        if message and M.callbacks[message.type] then
            M.callbacks[message.type](message.data)
        end
    elseif err ~= "timeout" then
        print("Receive error:", err)
        M.disconnect()
    end
end

-- Set callback for message type
function M.setCallback(messageType, callback)
    M.callbacks[messageType] = callback
end

-- Game-specific messages
function M.joinRoom(roomId, playerName)
    return M.send("join_room", {
        roomId = roomId,
        playerName = playerName
    })
end

function M.leaveRoom()
    return M.send("leave_room", {})
end

function M.sendPlayerUpdate(playerData)
    return M.send("player_update", playerData)
end

function M.sendPowerUpUsed(powerUpType, targetPlayerId)
    return M.send("powerup_used", {
        type = powerUpType,
        target = targetPlayerId
    })
end

-- Network update loop
function M.update()
    if M.isConnected then
        M.receive()
    end
end

return M
